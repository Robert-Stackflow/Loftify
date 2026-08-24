import 'dart:convert';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Navigation/loftify_glass_navigation_bar.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

const _destinations = <LoftifyNavigationDestination>[
  LoftifyNavigationDestination(icon: LoftifyIcons.home, label: 'Home'),
  LoftifyNavigationDestination(icon: LoftifyIcons.search, label: 'Search'),
  LoftifyNavigationDestination(
    icon: LoftifyIcons.activity,
    label: 'Activity',
    badgeCount: 120,
  ),
  LoftifyNavigationDestination(icon: LoftifyIcons.profile, label: 'Mine'),
];

ThemeData _themeForVariant(ChewieThemeColorData variant) {
  final brightness = variant.isDarkMode ? Brightness.dark : Brightness.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: variant.primaryColor,
    brightness: brightness,
  ).copyWith(
    primary: variant.primaryColor,
    surface: variant.effectivePageBackgroundColor,
    onSurface: variant.textColor,
    error: variant.errorColor,
  );
  return ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    primaryColor: variant.primaryColor,
    dividerColor: variant.dividerColor,
    shadowColor: variant.shadowColor,
  );
}

Widget _host({
  MediaQueryData mediaQuery = const MediaQueryData(size: Size(320, 640)),
  Brightness brightness = Brightness.light,
  ThemeData? theme,
  bool enableBlur = true,
  int currentIndex = 0,
  ValueChanged<int>? onSelect,
  ValueChanged<int>? onDoubleTap,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF14C2BB),
    brightness: brightness,
  );
  return MaterialApp(
    theme: theme ?? ThemeData(colorScheme: colorScheme, brightness: brightness),
    home: MediaQuery(
      data: mediaQuery,
      child: Scaffold(
        extendBody: true,
        body: const ColoredBox(color: Color(0xFFB9DAD7)),
        bottomNavigationBar: LoftifyGlassNavigationBar(
          destinations: _destinations,
          currentIndex: currentIndex,
          enableBlur: enableBlur,
          onSelect: onSelect ?? (_) {},
          onDoubleTap: onDoubleTap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('uses a clipped translucent blur surface with safe-area inset', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        mediaQuery: const MediaQueryData(
          size: Size(320, 640),
          viewPadding: EdgeInsets.only(bottom: 24),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(LoftifyGlassNavigationBar)).height,
      LoftifyGlassNavigationBar.barHeight + 36,
    );

    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('loftify-glass-navigation-surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.color!.a, closeTo(0.72, 0.01));
    expect(decoration.borderRadius, BorderRadius.circular(24));
    expect(decoration.boxShadow, hasLength(1));
    expect(decoration.border, isNotNull);
  });

  testWidgets('uses an opaque fallback for accessibility and explicit opt-out',
      (
    tester,
  ) async {
    for (final configuration in <({MediaQueryData media, bool enabled})>[
      (
        media: const MediaQueryData(
          size: Size(320, 640),
          disableAnimations: true,
        ),
        enabled: true,
      ),
      (
        media: const MediaQueryData(
          size: Size(320, 640),
          highContrast: true,
        ),
        enabled: true,
      ),
      (
        media: const MediaQueryData(size: Size(320, 640)),
        enabled: false,
      ),
    ]) {
      await tester.pumpWidget(
        _host(
          mediaQuery: configuration.media,
          enableBlur: configuration.enabled,
        ),
      );

      expect(find.byType(BackdropFilter), findsNothing);
      final surface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('loftify-glass-navigation-surface')),
      );
      final decoration = surface.decoration as BoxDecoration;
      expect(decoration.color!.a, 1);
    }
  });

  testWidgets('adapts glass tint and selected color to every built-in theme', (
    tester,
  ) async {
    final variants = <ChewieThemeColorData>[
      ...ChewieThemeColorData.defaultLightThemes,
      ...ChewieThemeColorData.defaultDarkThemes,
    ];

    for (final variant in variants) {
      await tester.pumpWidget(_host(theme: _themeForVariant(variant)));
      await tester.pumpAndSettle();

      final surface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('loftify-glass-navigation-surface')),
      );
      final decoration = surface.decoration as BoxDecoration;
      expect(
        decoration.color!.withValues(alpha: 1),
        variant.effectivePageBackgroundColor,
        reason: variant.id,
      );
      expect(
        decoration.color!.a,
        closeTo(variant.isDarkMode ? 0.78 : 0.72, 0.01),
        reason: variant.id,
      );
      final selectedIcon = tester.widget<ChewieIcon>(
        find.byType(ChewieIcon).first,
      );
      expect(selectedIcon.color, variant.primaryColor, reason: variant.id);
      expect(tester.takeException(), isNull, reason: variant.id);
    }
  });

  testWidgets('keeps four labels bounded and exposes selected semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        mediaQuery: const MediaQueryData(
          size: Size(280, 600),
          textScaler: TextScaler.linear(1.4),
        ),
        currentIndex: 2,
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Activity')),
      matchesSemantics(
        label: 'Activity, 120',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('dispatches tap and double-tap without material ripple', (
    tester,
  ) async {
    var selected = -1;
    var doubleTapped = -1;
    await tester.pumpWidget(
      _host(
        onSelect: (index) => selected = index,
        onDoubleTap: (index) => doubleTapped = index,
      ),
    );

    expect(find.byType(InkWell), findsNothing);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(selected, 1);

    await tester.tap(find.text('Mine'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Mine'));
    await tester.pumpAndSettle();
    expect(doubleTapped, 3);
  });

  test('blur policy rejects web and all accessibility fallbacks', () {
    const normal = MediaQueryData();
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(
        normal,
        enabled: true,
        isWeb: false,
        platformReduceMotion: false,
      ),
      isTrue,
    );
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(
        normal,
        enabled: true,
        isWeb: true,
        platformReduceMotion: false,
      ),
      isFalse,
    );
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(
        normal,
        enabled: false,
        platformReduceMotion: false,
      ),
      isFalse,
    );
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(
        const MediaQueryData(accessibleNavigation: true),
        enabled: true,
        platformReduceMotion: false,
      ),
      isFalse,
    );
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(
        normal,
        enabled: true,
        platformReduceMotion: true,
      ),
      isFalse,
    );
  });

  test('phone panel extends content behind the reusable glass navigation', () {
    final source = File('lib/Screens/panel_screen.dart').readAsStringSync();

    expect(source, contains('extendBody: true'));
    expect(source, contains('portrait: _buildBottomNavigationBar()'));
    expect(source, contains('LoftifyGlassNavigationBar('));
    expect(source, contains('enableBlur: !reduceTransparency'));
    expect(source, isNot(contains('MyBottomNavigationBar(')));
  });

  test('reduce-transparency preference is persisted and localized', () {
    final hiveSource = File('lib/Utils/hive_util.dart').readAsStringSync();
    final providerSource = File(
      'lib/Utils/app_provider.dart',
    ).readAsStringSync();
    final appearanceSource = File(
      'lib/Screens/Setting/apperance_setting_screen.dart',
    ).readAsStringSync();

    expect(hiveSource, contains('reduceTransparencyKey'));
    expect(
      providerSource,
      allOf(
        contains('bool get reduceTransparency'),
        contains('HiveUtil.reduceTransparencyKey'),
        contains('notifyListeners()'),
      ),
    );
    expect(
      appearanceSource,
      allOf(
        contains('appProvider.reduceTransparency'),
        contains('appLocalizations.reduceTransparency'),
        contains('appLocalizations.reduceTransparencyDescription'),
      ),
    );

    for (final path in <String>[
      'lib/l10n/intl_en.arb',
      'lib/l10n/intl_zh.arb',
      'lib/l10n/intl_zh_CN.arb',
      'lib/l10n/intl_zh_TW.arb',
    ]) {
      final messages = jsonDecode(File(path).readAsStringSync()) as Map;
      expect(messages['reduceTransparency'], isNotEmpty, reason: path);
      expect(
        messages['reduceTransparencyDescription'],
        isNotEmpty,
        reason: path,
      );
    }
  });
}
