import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Setting/select_theme_screen.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/select_theme_screen',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('accent colors keep accessible targets on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
        navigatorKey: chewieProvider.globalNavigatorKey,
        localizationsDelegates: const [
          ChewieLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return const MediaQuery(
              data: MediaQueryData(
                size: Size(280, 480),
                textScaler: TextScaler.linear(2),
              ),
              child: SelectThemeScreen(showTitleBar: false),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final reset = find.byKey(
      const ValueKey('theme-accent-light-reset'),
    );
    expect(reset, findsOneWidget);
    expect(tester.getSize(reset), const Size(48, 48));
    expect(
      tester.getSize(find.byType(ThemeItem).first).height,
      greaterThan(166.4),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('theme and add cards expose one full-card action',
      (tester) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final themeData = ChewieThemeColorData.defaultLightThemes.first;
    int? selectedIndex;
    var longPresses = 0;
    var addTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: themeData.toThemeData(),
        navigatorKey: chewieProvider.globalNavigatorKey,
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
                body: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ThemeItem(
                      themeColorData: themeData,
                      index: 0,
                      groupIndex: 0,
                      onChanged: (index) => selectedIndex = index,
                      onLongPress: () => longPresses++,
                    ),
                    EmptyThemeItem(onTap: () => addTaps++),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChewieSelectionIndicator), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
    expect(
      tester.getSemantics(find.byType(ThemeItem)),
      matchesSemantics(
        label: themeData.i18nName,
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );

    final themeRect = tester.getRect(find.byType(ThemeItem));
    await tester.tapAt(Offset(themeRect.center.dx, themeRect.bottom - 4));
    await tester.longPress(find.byType(ThemeItem));
    final addRect = tester.getRect(find.byType(EmptyThemeItem));
    await tester.tapAt(Offset(addRect.center.dx, addRect.bottom - 4));
    await tester.pump();

    expect(selectedIndex, 0);
    expect(longPresses, 1);
    expect(addTaps, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
