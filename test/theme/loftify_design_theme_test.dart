import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/loftify_design_theme',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  group('LoftifyTheme', () {
    test('derives the frozen light and dark semantic surfaces', () {
      final light = LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      );
      final dark = LoftifyTheme.build(
        ChewieThemeColorData.defaultDarkThemes.first,
      );
      final lightDesign = light.extension<LoftifyDesignThemeData>()!;
      final darkDesign = dark.extension<LoftifyDesignThemeData>()!;

      expect(lightDesign.colors.page, const Color(0xFFFFFFFF));
      expect(lightDesign.colors.surface, const Color(0xFFF7F8F7));
      expect(lightDesign.colors.textPrimary, const Color(0xFF202522));
      expect(darkDesign.colors.page, const Color(0xFF121412));
      expect(darkDesign.colors.surface, const Color(0xFF191C1A));
      expect(darkDesign.colors.textPrimary, const Color(0xFFF2F5F3));
      expect(light.scaffoldBackgroundColor, Colors.white);
      expect(light.navigationBarTheme.backgroundColor, Colors.white);
      expect(
        light.cardColor,
        ChewieThemeColorData.defaultLightThemes.first.cardColor,
      );
      expect(light.cardColor, isNot(Colors.white));
      expect(light.appBarTheme.scrolledUnderElevation, 0);
      expect(light.appBarTheme.shadowColor, Colors.transparent);
    });

    test('preserves user-selected accents and independent status hues', () {
      const accent = Color(0xFFE91E63);
      final source = ChewieThemeColorData.defaultLightThemes.first.copyWith(
        primaryColor: accent,
      );
      final theme = LoftifyTheme.build(source);
      final design = theme.extension<LoftifyDesignThemeData>()!;

      expect(design.colors.accent, accent);
      expect(theme.colorScheme.primary, accent);
      expect(
        HSLColor.fromColor(design.colors.success).hue,
        closeTo(HSLColor.fromColor(source.successColor).hue, 2),
      );
      expect(
        HSLColor.fromColor(design.colors.warning).hue,
        closeTo(HSLColor.fromColor(source.warningColor).hue, 2),
      );
      expect(
        HSLColor.fromColor(design.colors.danger).hue,
        closeTo(HSLColor.fromColor(source.errorColor).hue, 2),
      );
      expect(design.colors.danger, isNot(accent));
    });

    test('defines the frozen typography, geometry and motion ladders', () {
      final design = LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      ).extension<LoftifyDesignThemeData>()!;

      expect(design.typography.pageTitle.fontSize, 20);
      expect(design.typography.body.fontSize, 15);
      expect(design.typography.body.height, 1.6);
      expect(design.typography.readingBody.fontSize, 17);
      expect(design.typography.readingBody.height, 1.8);
      expect(design.typography.pageTitle.decoration, TextDecoration.none);
      expect(
        <double>[
          design.spacing.xxs,
          design.spacing.xs,
          design.spacing.sm,
          design.spacing.md,
          design.spacing.lg,
          design.spacing.xl,
          design.spacing.xxl,
          design.spacing.xxxl,
          design.spacing.huge,
          design.spacing.hero,
        ],
        <double>[2, 4, 6, 8, 12, 16, 20, 24, 32, 40],
      );
      expect(design.radii.card, 14);
      expect(design.radii.panel, 20);
      expect(design.icons.minimumTapTarget, 48);
      expect(design.motion.press, const Duration(milliseconds: 90));
      expect(design.motion.panel, const Duration(milliseconds: 260));

      // Design roles are opt-in. Legacy Material roles keep the original app
      // scale so screens that apply local font deltas are not enlarged twice.
      final theme = LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      );
      expect(theme.textTheme.titleLarge!.fontSize, 18);
      expect(theme.textTheme.titleMedium!.fontSize, 16);
      expect(theme.textTheme.titleSmall!.fontSize, 14);
      expect(theme.textTheme.bodyLarge!.fontSize, 16);
      expect(theme.textTheme.bodyMedium!.fontSize, 14);
    });

    test('supports copyWith and interpolates theme changes', () {
      final light = LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      ).extension<LoftifyDesignThemeData>()!;
      final dark = LoftifyTheme.build(
        ChewieThemeColorData.defaultDarkThemes.first,
      ).extension<LoftifyDesignThemeData>()!;
      final replaced = light.copyWith(
        colors: light.colors.copyWith(accent: Colors.purple),
      );
      final middle = light.lerp(dark, 0.5);

      expect(replaced.colors.accent, Colors.purple);
      expect(replaced.spacing.xl, light.spacing.xl);
      expect(
        middle.colors.page,
        Color.lerp(light.colors.page, dark.colors.page, 0.5),
      );
      expect(middle.radii.card, 14);
    });

    testWidgets('components can resolve a safe token fallback during reload', (
      tester,
    ) async {
      late LoftifyDesignThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              resolved = LoftifyDesignThemeData.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.colors.page, Colors.white);
      expect(resolved.icons.minimumTapTarget, 48);
      expect(tester.takeException(), isNull);
    });

    test('every semantic text level meets AA contrast on neutral surfaces', () {
      final failures = <String>[];
      for (final source in <ChewieThemeColorData>[
        ChewieThemeColorData.defaultLightThemes.first,
        ChewieThemeColorData.defaultDarkThemes.first,
      ]) {
        final colors = LoftifyTheme.build(
          source,
        ).extension<LoftifyDesignThemeData>()!.colors;
        for (final background in <Color>[
          colors.page,
          colors.surface,
          colors.surfaceRaised,
          colors.surfaceMuted,
        ]) {
          for (final foreground in <Color>[
            colors.textPrimary,
            colors.textSecondary,
            colors.textMuted,
          ]) {
            final ratio = _contrastRatio(foreground, background);
            if (ratio < 4.5) {
              failures.add(
                '${source.id}: $foreground on $background is '
                '${ratio.toStringAsFixed(3)}:1',
              );
            }
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('accent foreground meets AA contrast across built-in themes', () {
      for (final source in <ChewieThemeColorData>[
        ...ChewieThemeColorData.defaultLightThemes,
        ...ChewieThemeColorData.defaultDarkThemes,
      ]) {
        final colors = LoftifyTheme.build(
          source,
        ).extension<LoftifyDesignThemeData>()!.colors;
        expect(
          _contrastRatio(colors.onAccent, colors.accent),
          greaterThanOrEqualTo(4.5),
          reason: '${source.id} needs a readable foreground on its accent',
        );
      }
    });

    test('custom bright accents choose a readable foreground', () {
      for (final accent in <Color>[
        const Color(0xFF14C2BB),
        const Color(0xFFFF9800),
        const Color(0xFF4CAF50),
      ]) {
        final source = ChewieThemeColorData.defaultLightThemes.first.copyWith(
          primaryColor: accent,
        );
        final colors = LoftifyTheme.build(
          source,
        ).extension<LoftifyDesignThemeData>()!.colors;
        expect(
          _contrastRatio(colors.onAccent, colors.accent),
          greaterThanOrEqualTo(4.5),
          reason: '$accent needs a readable foreground',
        );
      }
    });

    test('accent container content meets AA contrast in every theme', () {
      final sources = <ChewieThemeColorData>[
        ...ChewieThemeColorData.defaultLightThemes,
        ...ChewieThemeColorData.defaultDarkThemes,
        for (final accent in <Color>[
          const Color(0xFF14C2BB),
          const Color(0xFFFF9800),
          const Color(0xFF4CAF50),
        ])
          ChewieThemeColorData.defaultLightThemes.first.copyWith(
            id: 'Custom-$accent',
            primaryColor: accent,
          ),
      ];
      for (final source in sources) {
        final colors = LoftifyTheme.build(
          source,
        ).extension<LoftifyDesignThemeData>()!.colors;
        expect(
          _contrastRatio(colors.onAccentContainer, colors.accentContainer),
          greaterThanOrEqualTo(4.5),
          reason: '${source.id} needs readable tonal content',
        );
      }
    });

    test('semantic status colors remain readable on page and tinted surfaces',
        () {
      for (final source in <ChewieThemeColorData>[
        ...ChewieThemeColorData.defaultLightThemes,
        ...ChewieThemeColorData.defaultDarkThemes,
      ]) {
        final colors = LoftifyTheme.build(
          source,
        ).extension<LoftifyDesignThemeData>()!.colors;
        for (final status in <Color>[
          colors.success,
          colors.warning,
          colors.danger,
        ]) {
          final tintedPage = Color.alphaBlend(
            status.withValues(alpha: 0.10),
            colors.page,
          );
          final tintedRaised = Color.alphaBlend(
            status.withValues(alpha: 0.10),
            colors.surfaceRaised,
          );
          for (final background in <Color>[
            colors.page,
            colors.surfaceRaised,
            tintedPage,
            tintedRaised,
          ]) {
            expect(
              _contrastRatio(status, background),
              greaterThanOrEqualTo(4.5),
              reason: '${source.id} status color needs readable contrast',
            );
          }
        }
      }
    });
  });

  group('LoftifyGridTokens', () {
    const grid = LoftifyGridTokens();

    test('uses width rather than device labels for responsive classes', () {
      expect(grid.windowClassFor(599), LoftifyWindowClass.compact);
      expect(grid.windowClassFor(600), LoftifyWindowClass.medium);
      expect(grid.windowClassFor(840), LoftifyWindowClass.expanded);
      expect(grid.windowClassFor(1200), LoftifyWindowClass.large);
      expect(grid.pagePaddingFor(320), 12);
      expect(grid.pagePaddingFor(390), 16);
      expect(grid.pagePaddingFor(700), 24);
      expect(grid.denseFeedPagePaddingFor(320), 8);
      expect(grid.denseFeedPagePaddingFor(390), 10);
      expect(grid.denseFeedPagePaddingFor(700), 24);
    });

    test('keeps card grids bounded from narrow phone to large desktop', () {
      expect(grid.contentColumnCount(320), 1);
      expect(grid.contentColumnCount(390), 2);
      expect(grid.contentColumnCount(700), 3);
      expect(grid.contentColumnCount(2560), 6);
      expect(grid.maximumDenseCardExtent, 300);
      expect(grid.maximumReadingWidth, 720);
    });
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
