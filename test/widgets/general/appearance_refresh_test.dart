import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/l10n/l10n.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/appearance_refresh',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
    await Hive.box(ChewieHiveUtil.settingsBox).clear();
  });

  tearDown(() async {
    appProvider.locale = null;
    appProvider.themeMode = ActiveThemeMode.system;
    await ChewieHiveUtil.put(
      ChewieHiveUtil.fontFamilyKey,
      CustomFont.Default.fontFamily,
    );
    appProvider.currentFont = CustomFont.Default;
  });

  test('locale resolver prefers exact region and then language', () {
    expect(
        resolveAppLocale(const Locale('zh', 'TW')), const Locale('zh', 'TW'));
    expect(resolveAppLocale(const Locale('zh', 'HK')), const Locale('zh'));
    expect(resolveAppLocale(const Locale('en', 'GB')), const Locale('en'));
    expect(resolveAppLocale(const Locale('ja')), const Locale('en'));
  });

  test('custom font selection can be restored from persisted metadata',
      () async {
    const customFont = CustomFont(
      fontName: 'Local Test Font',
      fontFamily: 'LocalTestFont',
      fontUrl: 'local-test-font.ttf',
    );
    ChewieHiveUtil.setCustomFonts(<CustomFont>[customFont]);
    await ChewieHiveUtil.put(
      ChewieHiveUtil.fontFamilyKey,
      customFont.fontFamily,
    );

    expect(CustomFont.getCurrentFont(), customFont);

    ChewieHiveUtil.setCustomFonts(<CustomFont>[]);
  });

  testWidgets('system locale refresh updates intl and notifies listeners',
      (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(
      tester.binding.platformDispatcher.clearLocaleTestValue,
    );
    appProvider.locale = null;
    var notifications = 0;
    void listener() => notifications++;
    appProvider.addListener(listener);
    addTearDown(() => appProvider.removeListener(listener));

    tester.binding.platformDispatcher.localeTestValue =
        const Locale('zh', 'TW');
    appProvider.refreshSystemLocale();

    expect(Intl.defaultLocale, 'zh_TW');
    expect(notifications, greaterThan(0));
  });

  test('persisted locale refresh keeps intl aligned after cold start', () {
    appProvider.locale = const Locale('zh', 'TW');
    Intl.defaultLocale = 'en';

    appProvider.refreshSystemLocale();

    expect(Intl.defaultLocale, 'zh_TW');
  });

  test('theme and font changes notify and produce a fresh root theme',
      () async {
    var notifications = 0;
    void listener() => notifications++;
    appProvider.addListener(listener);
    addTearDown(() => appProvider.removeListener(listener));
    appProvider.themeMode = ActiveThemeMode.dark;
    expect(appProvider.getBrightness(), Brightness.dark);

    await ChewieHiveUtil.put(
      ChewieHiveUtil.fontFamilyKey,
      CustomFont.MiSans.fontFamily,
    );
    appProvider.currentFont = CustomFont.MiSans;
    final theme = appProvider.darkTheme.toThemeData();
    expect(theme.textTheme.bodyMedium?.fontFamily, 'MiSans');
    expect(CustomFont.getCurrentFont(), CustomFont.MiSans);
    expect(notifications, greaterThanOrEqualTo(2));
  });

  testWidgets('localized archive month follows the active locale',
      (tester) async {
    const timestamp = 1730592000000; // 2024-11-03 UTC
    late String formattedMonth;

    Future<void> pumpFor(Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              chewieProvider.setRootContext(context);
              formattedMonth = formatLocalizedYearMonth(timestamp);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
    }

    await pumpFor(const Locale('en'));
    expect(formattedMonth, '2024-11');

    await pumpFor(const Locale('zh', 'TW'));
    expect(formattedMonth, '2024年11月');
  });
}
