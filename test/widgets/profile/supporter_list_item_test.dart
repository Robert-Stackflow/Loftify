import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/Profile/supporter_list_item.dart';

void main() {
  setUpAll(() async {
    final directory = Directory('build/test_hive/supporter_list_item');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  Future<void> mount(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double textScale = 1,
    bool dark = false,
    VoidCallback? onTap,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: LoftifyTheme.build(dark
          ? ChewieThemeColorData.defaultDarkThemes.first
          : ChewieThemeColorData.defaultLightThemes.first),
      home: Builder(
          builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: Scaffold(
                  body: Column(
                    children: [
                      LoftifySupporterListItem(
                        blogId: 42,
                        avatarUrl: '',
                        name: '很长的支持者昵称，不应该把贡献数挤出屏幕',
                        blogName: 'supporter_42',
                        intro: '摄影、绘画和文字。这里是一段较长的个人介绍，应允许两行。',
                        score: 123456789,
                        onTap: onTap ?? () {},
                      ),
                    ],
                  ),
                ),
              )),
    ));
    await tester.pump();
  }

  testWidgets('phone row keeps identity and score together', (tester) async {
    await mount(tester);
    expect(find.text('ID: supporter_42'), findsOneWidget);
    expect(find.text('123456789'), findsOneWidget);
    final row = find.byKey(const ValueKey('loftify-supporter-row-42'));
    expect(tester.getSize(row).height, lessThan(180));
    final ink = tester.widget<InkWell>(find
        .descendant(
          of: row,
          matching: find.byType(InkWell),
        )
        .first);
    expect(ink.splashFactory, NoSplash.splashFactory);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow dark large-text row reflows without clipping',
      (tester) async {
    await mount(tester, width: 280, height: 480, textScale: 2, dark: true);
    final row = find.byKey(const ValueKey('loftify-supporter-row-42'));
    expect(tester.getTopRight(row).dx, lessThanOrEqualTo(280));
    expect(find.text('123456789'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('whole supporter item opens the author', (tester) async {
    var tapped = false;
    await mount(tester, onTap: () => tapped = true);
    await tester.tap(find.byKey(const ValueKey('loftify-supporter-row-42')));
    expect(tapped, isTrue);
  });
}
