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
