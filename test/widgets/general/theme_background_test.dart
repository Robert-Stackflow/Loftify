import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/theme_background',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  test('every light theme keeps full-page and navigation surfaces white', () {
    for (final themeData in ChewieThemeColorData.defaultLightThemes) {
      final theme = themeData.toThemeData();

      expect(
        theme.scaffoldBackgroundColor,
        Colors.white,
        reason: '${themeData.id} scaffold must stay white',
      );
      expect(
        theme.bottomNavigationBarTheme.backgroundColor,
        Colors.white,
        reason: '${themeData.id} bottom navigation must stay white',
      );
      expect(
        theme.navigationBarTheme.backgroundColor,
        Colors.white,
        reason: '${themeData.id} Material 3 navigation must stay white',
      );
      expect(theme.canvasColor, themeData.canvasColor);
      expect(theme.cardColor, themeData.cardColor);
    }
  });

  test('custom light colors cannot reintroduce a grey page surface', () {
    final customTheme = ChewieThemeColorData.defaultLightThemes.first.copyWith(
      id: 'custom-light',
      scaffoldBackgroundColor: const Color(0xFFE0E0E0),
      canvasColor: const Color(0xFFF2F3F4),
    );
    final theme = customTheme.toThemeData();

    expect(customTheme.effectivePageBackgroundColor, Colors.white);
    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(theme.bottomNavigationBarTheme.backgroundColor, Colors.white);
    expect(theme.canvasColor, const Color(0xFFF2F3F4));
  });

  test('dark themes preserve their configured page and navigation colors', () {
    for (final themeData in ChewieThemeColorData.defaultDarkThemes) {
      final theme = themeData.toThemeData();

      expect(theme.scaffoldBackgroundColor, themeData.scaffoldBackgroundColor);
      expect(
        theme.bottomNavigationBarTheme.backgroundColor,
        themeData.scaffoldBackgroundColor,
      );
      expect(
        theme.navigationBarTheme.backgroundColor,
        themeData.scaffoldBackgroundColor,
      );
    }
  });

  test('pure themes keep the original Loftify accent across Material themes',
      () {
    const originalAccent = Color(0xFF14C2BB);
    final pureWhite = ChewieThemeColorData.defaultLightThemes.first;
    final pureBlack = ChewieThemeColorData.defaultDarkThemes.first;

    for (final themeData in [pureWhite, pureBlack]) {
      final theme = themeData.toThemeData();
      expect(themeData.primaryColor, originalAccent);
      expect(theme.primaryColor, originalAccent);
      expect(theme.colorScheme.primary, originalAccent);
      expect(theme.colorScheme.secondary, originalAccent);
      expect(theme.progressIndicatorTheme.color, originalAccent);
      expect(theme.colorScheme.surface, theme.scaffoldBackgroundColor);
    }
  });

  test('custom accent updates primary Material component colors together', () {
    const accent = Color(0xFFE91E63);
    final theme = ChewieThemeColorData.defaultLightThemes.first
        .copyWith(primaryColor: accent)
        .toThemeData();

    expect(theme.primaryColor, accent);
    expect(theme.colorScheme.primary, accent);
    expect(theme.colorScheme.secondary, accent);
    expect(theme.progressIndicatorTheme.color, accent);
  });

  test('switching themes reloads persisted accents and reset restores defaults',
      () {
    const accent = Color(0xFFFF5722);
    addTearDown(() {
      ChewieHiveUtil.setCustomLightPrimaryColor(null);
      ChewieHiveUtil.setCustomDarkPrimaryColor(null);
      ChewieHiveUtil.setLightTheme(0);
      ChewieHiveUtil.setDarkTheme(0);
      ChewieHiveUtil.setLightThemePrimaryColorIndex(0);
      ChewieHiveUtil.setDarkThemePrimaryColorIndex(0);
    });

    ChewieHiveUtil.setCustomLightPrimaryColor(accent);
    ChewieHiveUtil.setCustomDarkPrimaryColor(accent);
    ChewieHiveUtil.setLightTheme(1);
    ChewieHiveUtil.setDarkTheme(1);
    expect(ChewieHiveUtil.getLightTheme().toThemeData().colorScheme.primary,
        accent);
    expect(ChewieHiveUtil.getDarkTheme().toThemeData().colorScheme.primary,
        accent);

    ChewieHiveUtil.put(
      ChewieHiveUtil.customLightThemePrimaryColorKey,
      '#01010000',
    );
    ChewieHiveUtil.setLightThemePrimaryColorIndex(1);
    expect(
      ChewieHiveUtil.getLightTheme().toThemeData().colorScheme.primary,
      ChewieThemeColorData.defaultLightThemes[1].primaryColor,
    );
    expect(ChewieHiveUtil.getLightThemePrimaryColorIndex(), 0);

    ChewieHiveUtil.setCustomLightPrimaryColor(null);
    ChewieHiveUtil.setCustomDarkPrimaryColor(null);
    ChewieHiveUtil.setLightTheme(0);
    ChewieHiveUtil.setDarkTheme(0);
    expect(
      ChewieHiveUtil.getLightTheme().toThemeData().colorScheme.primary,
      const Color(0xFF14C2BB),
    );
    expect(
      ChewieHiveUtil.getDarkTheme().toThemeData().colorScheme.primary,
      const Color(0xFF14C2BB),
    );
  });

  testWidgets('custom bottom navigation inherits the white light surface',
      (tester) async {
    final theme = ChewieThemeColorData.defaultLightThemes[1].toThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          bottomNavigationBar: MyBottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );

    final materials = tester.widgetList<Material>(
      find.descendant(
        of: find.byType(MyBottomNavigationBar),
        matching: find.byType(Material),
      ),
    );
    expect(materials.first.color, Colors.white);
    expect(tester.takeException(), isNull);
  });
}
