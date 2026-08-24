import 'dart:io';

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

Widget _host({
  MediaQueryData mediaQuery = const MediaQueryData(size: Size(320, 640)),
  Brightness brightness = Brightness.light,
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
    theme: ThemeData(colorScheme: colorScheme, brightness: brightness),
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
      ),
      isTrue,
    );
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(
        normal,
        enabled: true,
        isWeb: true,
      ),
      isFalse,
    );
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(normal, enabled: false),
      isFalse,
    );
    expect(
      LoftifyGlassNavigationBar.shouldUseBlur(
        const MediaQueryData(accessibleNavigation: true),
        enabled: true,
      ),
      isFalse,
    );
  });

  test('phone panel extends content behind the reusable glass navigation', () {
    final source = File('lib/Screens/panel_screen.dart').readAsStringSync();

    expect(source, contains('extendBody: true'));
    expect(source, contains('portrait: _buildBottomNavigationBar()'));
    expect(source, contains('child: LoftifyGlassNavigationBar('));
    expect(source, isNot(contains('MyBottomNavigationBar(')));
  });
}
