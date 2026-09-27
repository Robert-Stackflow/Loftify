import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/Profile/profile_more_action_sheet.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/profile_more_action_sheet',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  List<FlutterContextMenuItem> actions() => [
        for (var index = 0; index < 7; index++)
          FlutterContextMenuItem(
            'Action $index',
            iconData: LoftifyIcons.share,
          ),
      ];

  List<FlutterContextMenuItem> privacyActions() => const [
        FlutterContextMenuItem(
          'Block account',
          iconData: LoftifyIcons.block,
          status: MenuItemStatus.error,
        ),
        FlutterContextMenuItem(
          'Hide recommendations',
          iconData: LoftifyIcons.block,
          status: MenuItemStatus.error,
        ),
        FlutterContextMenuItem(
          '不看TA的动态内容',
          iconData: LoftifyIcons.block,
          status: MenuItemStatus.error,
        ),
      ];

  Future<void> mount(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double textScale = 1,
    bool dark = false,
    ValueChanged<FlutterContextMenuItem>? onSelected,
    VoidCallback? onCancel,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: LoftifyTheme.build(
        dark
            ? ChewieThemeColorData.defaultDarkThemes.first
            : ChewieThemeColorData.defaultLightThemes.first,
      ),
      home: Builder(builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: LoftifyProfileMoreActionSheet(
                privacyTitle: 'Privacy',
                cancelLabel: 'Cancel',
                actions: actions(),
                privacyActions: privacyActions(),
                onSelected: onSelected ?? (_) {},
                onCancel: onCancel ?? () {},
              ),
            ),
          ),
        );
      }),
    ));
    await tester.pump();
  }

  testWidgets('phone action grid is compact and keeps privacy separate',
      (tester) async {
    await mount(tester);

    final sheet = find.byType(LoftifyProfileMoreActionSheet);
    expect(tester.getSize(sheet).height, lessThan(520));
    expect(find.text('More actions'), findsNothing);
    expect(find.byKey(const ValueKey('profile-more-handle')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-more-cancel')), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('profile-more-Action 0'))).dy,
      tester.getTopLeft(find.byKey(const ValueKey('profile-more-Action 3'))).dy,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('profile-more-Action 4'))).dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('profile-more-Action 0')))
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('profile-more-Block account')))
          .dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('profile-more-Action 4')))
            .dy,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow large-text sheet scrolls to every action',
      (tester) async {
    await mount(tester, width: 280, height: 480, textScale: 2, dark: true);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -550));
    await tester.pumpAndSettle();
    expect(find.text('不看TA的动态内容'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two-line privacy label is visible without reserved blank space',
      (tester) async {
    await mount(tester);
    final label = find.text('不看TA的动态内容');
    final tile = find.byKey(const ValueKey('profile-more-不看TA的动态内容'));
    final cancel = find.byKey(const ValueKey('profile-more-cancel'));
    expect(tester.getBottomLeft(label).dy,
        lessThan(tester.getBottomLeft(tile).dy));
    expect(
      tester.getTopLeft(cancel).dy - tester.getBottomLeft(tile).dy,
      lessThan(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tile preserves its action and has no splash', (tester) async {
    FlutterContextMenuItem? selected;
    await mount(tester, onSelected: (item) => selected = item);
    final tile = find.byKey(const ValueKey('profile-more-Action 0'));
    final ink = tester.widget<InkWell>(tile);
    expect(ink.splashFactory, NoSplash.splashFactory);
    await tester.tap(tile);
    expect(selected?.label, 'Action 0');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel is a separate reachable action', (tester) async {
    var dismissed = false;
    await mount(tester, onCancel: () => dismissed = true);
    await tester.tap(find.byKey(const ValueKey('profile-more-cancel')));
    expect(dismissed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom sheet wrapper honors the custom top radius',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return const Scaffold(
          body: BottomSheetWrapperWidget(
            topRadius: Radius.circular(28),
            child: SizedBox(height: 200),
          ),
        );
      }),
    ));
    final clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(BottomSheetWrapperWidget),
        matching: find.byType(ClipRRect),
      ),
    );
    final radius = clip.borderRadius as BorderRadius;
    expect(radius.topLeft, const Radius.circular(28));
    expect(radius.topRight, const Radius.circular(28));
  });
}
