import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/font_item_accessibility',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('font cards keep selection and delete targets accessible',
      (tester) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    CustomFont? selected;
    CustomFont? deleted;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [ChewieLocalizations.delegate],
        supportedLocales: ChewieLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return MediaQuery(
              data: const MediaQueryData(
                size: Size(280, 480),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: Center(
                  child: FontItem(
                    font: CustomFont.Default,
                    currentFont: CustomFont.MiSans,
                    showDelete: true,
                    onChanged: (font) => selected = font,
                    onDelete: (font) => deleted = font,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final delete = find.byKey(const ValueKey('font-delete-'));
    expect(delete, findsOneWidget);
    expect(tester.getSize(delete), const Size(48, 48));
    expect(find.byType(ChewieSelectionIndicator), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(FontItem));
    expect(selected, CustomFont.Default);
    selected = null;
    await tester.tap(delete);
    expect(deleted, CustomFont.Default);
    expect(selected, isNull);
  });

  testWidgets('the complete add-font card remains one large action',
      (tester) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [ChewieLocalizations.delegate],
        supportedLocales: ChewieLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return MediaQuery(
              data: const MediaQueryData(
                size: Size(280, 480),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: Center(child: EmptyFontItem(onTap: () => taps++)),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final card = find.byType(EmptyFontItem);
    final rect = tester.getRect(card);
    await tester.tapAt(Offset(rect.center.dx, rect.bottom - 4));
    await tester.pump();

    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
