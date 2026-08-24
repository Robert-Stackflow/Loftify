import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Setting/base_setting_screen.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/setting_section',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('caption follows shared section rhythm and divider policy',
      (tester) async {
    await tester.pumpWidget(
      _buildHost(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            CaptionItem(
              title: 'General',
              children: [
                EntryItem(title: 'Language'),
                EntryItem(title: 'Appearance'),
              ],
            ),
            CaptionItem(
              title: 'Without dividers',
              showDivider: false,
              children: [EntryItem(title: 'Single entry')],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final captions = find.byType(CaptionItem);
    final firstSurface = find
        .descendant(of: captions.first, matching: find.byType(Material))
        .first;
    final firstMaterial = tester.widget<Material>(firstSurface);
    final firstTitle = tester.widget<Text>(find.text('General'));

    expect(
      tester.getTopLeft(firstSurface).dy,
      BaseSettingScreen.sectionTopMargin,
    );
    expect(firstMaterial.borderRadius, BorderRadius.circular(14));
    expect(firstTitle.style?.fontSize, 16);
    expect(firstTitle.style?.fontWeight, FontWeight.w600);
    expect(
      find.descendant(
        of: captions.first,
        matching: find.byType(Divider),
      ),
      findsNWidgets(2),
    );
    expect(
      find.descendant(
        of: captions.at(1),
        matching: find.byType(Divider),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline selection stacks for narrow large-text layouts',
      (tester) async {
    await tester.pumpWidget(
      _buildHost(
        size: const Size(320, 640),
        textScaler: const TextScaler.linear(2),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            CaptionItem(
              title: 'Language',
              children: [
                InlineSelectionItem<SelectionItemModel<String>>(
                  title: 'Interface language',
                  description: 'Choose the language used throughout Loftify',
                  items: [
                    SelectionItemModel('Simplified Chinese', 'zh-CN'),
                    SelectionItemModel('English', 'en'),
                  ],
                  initItem: SelectionItemModel(
                    'Simplified Chinese',
                    'zh-CN',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inlineItem = find.byType(
      InlineSelectionItem<SelectionItemModel<String>>,
    );
    final title = find.descendant(
      of: inlineItem,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText() == 'Interface language',
      ),
    );
    final dropdown = find.descendant(
      of: inlineItem,
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString().startsWith('CustomDropdown'),
      ),
    );

    expect(title, findsOneWidget);
    expect(dropdown, findsOneWidget);
    expect(
      tester.getTopLeft(dropdown).dy,
      greaterThan(tester.getBottomLeft(title).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('setting scaffold defaults to a divider-free app bar',
      (tester) async {
    await tester.pumpWidget(
      _buildHost(
        child: Builder(
          builder: (context) => ChewieItemBuilder.buildSettingScreen(
            context: context,
            title: 'Settings',
            showTitleBar: true,
            padding: BaseSettingScreen.defaultPagePadding,
            overrideBody: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();

    final appBar = tester.widget<ResponsiveAppBar>(
      find.byType(ResponsiveAppBar),
    );
    expect(appBar.showBorder, isFalse);
    expect(tester.takeException(), isNull);
  });
}

Widget _buildHost({
  required Widget child,
  Size size = const Size(390, 844),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: LoftifyTheme.build(
      ChewieThemeColorData.defaultLightThemes.first,
    ),
    home: MediaQuery(
      data: MediaQueryData(size: size, textScaler: textScaler),
      child: Builder(
        builder: (context) {
          chewieProvider.setRootContext(context);
          return Scaffold(body: child);
        },
      ),
    ),
  );
}
