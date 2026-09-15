import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Widgets/Item/setting_management_item.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/setting_management_item',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  for (final width in [280.0, 720.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        for (final label in ['No content available', '暂无内容', '暫無內容']) {
          testWidgets(
              'management empty state grows without nested scrolling $width $scale $dark $label',
              (tester) async {
            tester.view.physicalSize = Size(width, 320);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(MaterialApp(
              theme: (dark
                      ? ChewieThemeColorData.defaultDarkThemes.first
                      : ChewieThemeColorData.defaultLightThemes.first)
                  .toThemeData(),
              home: Builder(builder: (context) {
                chewieProvider.setRootContext(context);
                return Scaffold(
                    body: MediaQuery(
                  data: MediaQueryData(
                      size: Size(width, 320),
                      textScaler: TextScaler.linear(scale)),
                  child: ListView(children: [
                    CaptionItem(
                        title: 'Management',
                        children: [SettingManagementEmptyState(text: label)])
                  ]),
                ));
              }),
            ));
            await tester.pumpAndSettle();
            final stateRect =
                tester.getRect(find.byType(SettingManagementEmptyState));
            final textRect = tester.getRect(find.text(label));
            expect(stateRect.height, greaterThanOrEqualTo(140));
            expect(textRect.bottom, lessThanOrEqualTo(stateRect.bottom));
            expect(textRect.right, lessThanOrEqualTo(stateRect.right));
            expect(find.byType(Scrollable), findsOneWidget);
            await tester.ensureVisible(find.text(label));
            await tester.pumpAndSettle();
            expect(find.text(label).hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  testWidgets(
      'management items use caption spacing, dividers and theme actions',
      (tester) async {
    const accent = Color(0xFF14C2BB);
    var actionCount = 0;
    var rowTapCount = 0;
    final theme = ChewieThemeColorData.defaultLightThemes.first.toThemeData();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return Scaffold(
              body: ListView(
                padding: EdgeInsets.zero,
                children: [
                  CaptionItem(
                    title: '管理列表',
                    children: [
                      SettingManagementItem(
                        title: '用户 A',
                        leadingIcon: Icons.person_rounded,
                        actionLabel: '解除',
                        onTap: () => rowTapCount++,
                        onAction: () => actionCount++,
                      ),
                      SettingManagementItem(
                        title: '标签 B',
                        leadingIcon: Icons.tag_rounded,
                        actionLabel: '解除',
                        onAction: () => actionCount++,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final captionMaterial = find
        .descendant(
          of: find.byType(CaptionItem),
          matching: find.byType(Material),
        )
        .first;
    expect(tester.getTopLeft(captionMaterial).dy, 10);
    expect(find.byType(SettingManagementItem), findsNWidgets(2));
    expect(find.byType(EntryItem), findsNWidgets(2));

    final entries = tester.widgetList<EntryItem>(find.byType(EntryItem));
    final buttons = tester.widgetList<RoundIconTextButton>(
      find.byType(RoundIconTextButton),
    );
    expect(buttons, hasLength(2));
    expect(buttons.first.color, accent);
    expect(buttons.first.background, accent.withAlpha(22));
    expect(buttons.first.border?.top.color, accent.withAlpha(72));

    entries.first.onTap?.call();
    expect(rowTapCount, 1);

    buttons.first.onPressed?.call();
    expect(rowTapCount, 1);
    expect(actionCount, 1);
  });
}
