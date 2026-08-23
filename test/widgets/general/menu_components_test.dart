import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:awesome_chewie/src/Widgets/Module/FlutterContextMenu/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/menu_components',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  test('inline multi-select copy keeps mode, search and interaction style', () {
    final first = StringDropdownItem('first');
    final original = InlineSelectionItem<StringDropdownItem>.multiSelect(
      title: 'Mode',
      items: [first, StringDropdownItem('second')],
      selectedItems: [first],
      searchText: 'old',
      ink: true,
    );

    final copy = original.copyWith(searchText: 'new')
        as InlineSelectionItem<StringDropdownItem>;

    expect(copy.isMultiSelect, isTrue);
    expect(copy.selectedItems, [first]);
    expect(copy.searchText, 'new');
    expect(copy.ink, isTrue);
  });

  test('selection models match by stable value across translated labels', () {
    final systemLabel = SelectionItemModel<String?>('Follow system', null);
    final translatedLabel = SelectionItemModel<String?>('跟随系统', null);

    expect(systemLabel, translatedLabel);
    expect(systemLabel.hashCode, translatedLabel.hashCode);
    expect([systemLabel].contains(translatedLabel), isTrue);
  });

  testWidgets('inline dropdown stacks on narrow screens without overflow',
      (tester) async {
    await tester.pumpWidget(
      _buildHost(
        SizedBox(
          width: 300,
          child: InlineSelectionItem<StringDropdownItem>(
            title: 'A long setting title',
            description: 'A useful description',
            items: [StringDropdownItem('First'), StringDropdownItem('Second')],
            initItem: StringDropdownItem('First'),
            roundTop: true,
            roundBottom: true,
          ),
        ),
      ),
    );
    await tester.pump();

    final dropdown = find.byWidgetPredicate(
      (widget) => widget is CustomDropdown<StringDropdownItem>,
    );
    expect(dropdown, findsOneWidget);
    expect(tester.getSize(dropdown).width, greaterThan(250));
    expect(
      find.descendant(of: dropdown, matching: find.byType(InkWell)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown refreshes an equivalent item with its current label',
      (tester) async {
    var languageLabel = 'Follow system';
    var selectionChanges = 0;
    late StateSetter rebuildHost;

    await tester.pumpWidget(
      _buildHost(
        StatefulBuilder(
          builder: (context, setState) {
            rebuildHost = setState;
            return InlineSelectionItem<SelectionItemModel<String?>>(
              title: 'Language',
              items: [SelectionItemModel<String?>(languageLabel, null)],
              initItem: SelectionItemModel<String?>(languageLabel, null),
              onChanged: (_) => selectionChanges++,
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Follow system'), findsOneWidget);

    rebuildHost(() => languageLabel = '跟随系统');
    await tester.pump();
    await tester.pump();

    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('Follow system'), findsNothing);
    expect(selectionChanges, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long mobile context menus become scrollable', (tester) async {
    final entries = <ContextMenuEntry>[
      const MenuHeader(text: 'Actions'),
      const MenuDivider(),
      ...List.generate(
        20,
        (index) => FlutterContextMenuItem(
          'Action $index',
          iconData: Icons.circle_outlined,
        ),
      ),
    ];

    await tester.pumpWidget(
      _buildHost(
        SizedBox(
          width: 320,
          height: 500,
          child: ContextMenuBottomSheet(
            menu: FlutterContextMenu(entries: entries),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('ACTIONS'), findsOneWidget);
    expect(tester.getSize(find.byType(ContextMenuBottomSheet)).height,
        lessThanOrEqualTo(500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom menu divider keeps its inset and subtle thickness',
      (tester) async {
    await tester.pumpWidget(
      _buildHost(
        SizedBox(
          width: 320,
          child: ContextMenuBottomSheet(
            menu: FlutterContextMenu(
              entries: const [
                MenuDivider(thickness: 0.6, indent: 46, endIndent: 8),
              ],
            ),
          ),
        ),
      ),
    );

    final dividerLines =
        tester.widgetList<Container>(find.byType(Container)).where(
              (container) => container.constraints?.minHeight == 0.6,
            );
    expect(dividerLines, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom sheet wrapper clips every panel to rounded top corners',
      (tester) async {
    await tester.pumpWidget(
      _buildHost(
        const BottomSheetWrapperWidget(
          child: SizedBox(width: 320, height: 180),
        ),
      ),
    );

    final clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(BottomSheetWrapperWidget),
        matching: find.byType(ClipRRect),
      ),
    );
    final radius = clip.borderRadius.resolve(TextDirection.ltr);
    expect(radius.topLeft, ChewieDimens.defaultRadius);
    expect(radius.topRight, ChewieDimens.defaultRadius);
  });

  testWidgets('desktop context menus stay inside safe screen bounds',
      (tester) async {
    late BuildContext menuContext;
    const mediaQuery = MediaQueryData(
      size: Size(320, 640),
      padding: EdgeInsets.only(top: 24, bottom: 34),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: mediaQuery,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 300,
                top: 620,
                child: Builder(
                  builder: (context) {
                    menuContext = context;
                    return const SizedBox(width: 160, height: 100);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final result = calculateContextMenuBoundaries(
      menuContext,
      FlutterContextMenu(entries: const []),
      null,
      AlignmentDirectional.topEnd,
      false,
    );

    expect(result.pos.dx, greaterThanOrEqualTo(8));
    expect(result.pos.dx + 160, lessThanOrEqualTo(312));
    expect(result.pos.dy, greaterThanOrEqualTo(32));
    expect(result.pos.dy + 100, lessThanOrEqualTo(598));
  });

  testWidgets('disabled context menu regions expose no menu gestures',
      (tester) async {
    await tester.pumpWidget(
      _buildHost(
        ContextMenuRegion(
          key: const ValueKey('disabled-region'),
          enable: false,
          showOnClicked: true,
          contextMenu: FlutterContextMenu(entries: const []),
          child: const Text('Disabled'),
        ),
      ),
    );

    final gesture = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byKey(const ValueKey('disabled-region')),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(gesture.onTap, isNull);
    expect(gesture.onLongPress, isNull);
    expect(gesture.onSecondaryTap, isNull);
  });

  test('menu style copy preserves and overrides the correct fields', () {
    const iconColor = Color(0xFF123456);
    const style = MenuItemStyle(
      normalIconColor: iconColor,
      radius: 12,
      disabledOpacity: 0.4,
    );

    final preserved = style.copyWith();
    expect(preserved.normalIconColor, iconColor);
    expect(preserved.radius, 12);
    expect(preserved.disabledOpacity, 0.4);

    const overrideColor = Color(0xFF654321);
    final overridden = style.copyWith(normalIconColor: overrideColor);
    expect(overridden.normalIconColor, overrideColor);
  });
}

Widget _buildHost(Widget child) {
  return MaterialApp(
    navigatorKey: chewieProvider.globalNavigatorKey,
    theme: ThemeData.light(),
    home: Builder(
      builder: (context) {
        chewieProvider.setRootContext(context);
        return Scaffold(body: child);
      },
    ),
  );
}
