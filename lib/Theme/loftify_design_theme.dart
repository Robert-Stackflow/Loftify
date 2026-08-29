import 'dart:ui' show lerpDouble;

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

/// Responsive width classes used by the Loftify design system.
enum LoftifyWindowClass { compact, medium, expanded, large }

/// Semantic density roles. Density describes information rhythm rather than
/// shrinking accessibility targets.
enum LoftifyDensityRole {
  contentDense,
  contentComfortable,
  controlComfortable,
}

@immutable
class LoftifyColorTokens {
  const LoftifyColorTokens({
    required this.page,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.outline,
    required this.outlineStrong,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.success,
    required this.warning,
    required this.danger,
    required this.scrim,
  });

  final Color page;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color outline;
  final Color outlineStrong;
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color success;
  final Color warning;
  final Color danger;
  final Color scrim;

  LoftifyColorTokens copyWith({
    Color? page,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? outline,
    Color? outlineStrong,
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? success,
    Color? warning,
    Color? danger,
    Color? scrim,
  }) {
    return LoftifyColorTokens(
      page: page ?? this.page,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      scrim: scrim ?? this.scrim,
    );
  }

  static LoftifyColorTokens lerp(
    LoftifyColorTokens a,
    LoftifyColorTokens b,
    double t,
  ) {
    return LoftifyColorTokens(
      page: Color.lerp(a.page, b.page, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      surfaceRaised: Color.lerp(a.surfaceRaised, b.surfaceRaised, t)!,
      surfaceMuted: Color.lerp(a.surfaceMuted, b.surfaceMuted, t)!,
      textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      textMuted: Color.lerp(a.textMuted, b.textMuted, t)!,
      outline: Color.lerp(a.outline, b.outline, t)!,
      outlineStrong: Color.lerp(a.outlineStrong, b.outlineStrong, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
      accentContainer: Color.lerp(
        a.accentContainer,
        b.accentContainer,
        t,
      )!,
      onAccentContainer: Color.lerp(
        a.onAccentContainer,
        b.onAccentContainer,
        t,
      )!,
      success: Color.lerp(a.success, b.success, t)!,
      warning: Color.lerp(a.warning, b.warning, t)!,
      danger: Color.lerp(a.danger, b.danger, t)!,
      scrim: Color.lerp(a.scrim, b.scrim, t)!,
    );
  }
}

@immutable
class LoftifyTypographyTokens {
  const LoftifyTypographyTokens({
    required this.display,
    required this.pageTitle,
    required this.sectionTitle,
    required this.cardTitle,
    required this.body,
    required this.readingBody,
    required this.metadata,
    required this.label,
  });

  final TextStyle display;
  final TextStyle pageTitle;
  final TextStyle sectionTitle;
  final TextStyle cardTitle;
  final TextStyle body;
  final TextStyle readingBody;
  final TextStyle metadata;
  final TextStyle label;

  LoftifyTypographyTokens copyWith({
    TextStyle? display,
    TextStyle? pageTitle,
    TextStyle? sectionTitle,
    TextStyle? cardTitle,
    TextStyle? body,
    TextStyle? readingBody,
    TextStyle? metadata,
    TextStyle? label,
  }) {
    return LoftifyTypographyTokens(
      display: display ?? this.display,
      pageTitle: pageTitle ?? this.pageTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      body: body ?? this.body,
      readingBody: readingBody ?? this.readingBody,
      metadata: metadata ?? this.metadata,
      label: label ?? this.label,
    );
  }

  static LoftifyTypographyTokens lerp(
    LoftifyTypographyTokens a,
    LoftifyTypographyTokens b,
    double t,
  ) {
    return LoftifyTypographyTokens(
      display: TextStyle.lerp(a.display, b.display, t)!,
      pageTitle: TextStyle.lerp(a.pageTitle, b.pageTitle, t)!,
      sectionTitle: TextStyle.lerp(a.sectionTitle, b.sectionTitle, t)!,
      cardTitle: TextStyle.lerp(a.cardTitle, b.cardTitle, t)!,
      body: TextStyle.lerp(a.body, b.body, t)!,
      readingBody: TextStyle.lerp(a.readingBody, b.readingBody, t)!,
      metadata: TextStyle.lerp(a.metadata, b.metadata, t)!,
      label: TextStyle.lerp(a.label, b.label, t)!,
    );
  }
}

@immutable
class LoftifySpacingTokens {
  const LoftifySpacingTokens({
    this.xxs = 2,
    this.xs = 4,
    this.sm = 6,
    this.md = 8,
    this.lg = 12,
    this.xl = 16,
    this.xxl = 20,
    this.xxxl = 24,
    this.huge = 32,
    this.hero = 40,
    this.sectionTop = 10,
  });

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double huge;
  final double hero;

  /// Product requirement: each Caption-style setting group starts 10 px
  /// below the preceding content. Kept semantic because it is intentionally
  /// outside the general spacing ladder.
  final double sectionTop;

  static LoftifySpacingTokens lerp(
    LoftifySpacingTokens a,
    LoftifySpacingTokens b,
    double t,
  ) {
    return LoftifySpacingTokens(
      xxs: lerpDouble(a.xxs, b.xxs, t)!,
      xs: lerpDouble(a.xs, b.xs, t)!,
      sm: lerpDouble(a.sm, b.sm, t)!,
      md: lerpDouble(a.md, b.md, t)!,
      lg: lerpDouble(a.lg, b.lg, t)!,
      xl: lerpDouble(a.xl, b.xl, t)!,
      xxl: lerpDouble(a.xxl, b.xxl, t)!,
      xxxl: lerpDouble(a.xxxl, b.xxxl, t)!,
      huge: lerpDouble(a.huge, b.huge, t)!,
      hero: lerpDouble(a.hero, b.hero, t)!,
      sectionTop: lerpDouble(a.sectionTop, b.sectionTop, t)!,
    );
  }
}

@immutable
class LoftifyRadiusTokens {
  const LoftifyRadiusTokens({
    this.small = 6,
    this.control = 10,
    this.card = 14,
    this.panel = 20,
    this.dialog = 24,
    this.full = 999,
  });

  final double small;
  final double control;
  final double card;
  final double panel;
  final double dialog;
  final double full;

  static LoftifyRadiusTokens lerp(
    LoftifyRadiusTokens a,
    LoftifyRadiusTokens b,
    double t,
  ) {
    return LoftifyRadiusTokens(
      small: lerpDouble(a.small, b.small, t)!,
      control: lerpDouble(a.control, b.control, t)!,
      card: lerpDouble(a.card, b.card, t)!,
      panel: lerpDouble(a.panel, b.panel, t)!,
      dialog: lerpDouble(a.dialog, b.dialog, t)!,
      full: lerpDouble(a.full, b.full, t)!,
    );
  }
}

@immutable
class LoftifyBorderTokens {
  const LoftifyBorderTokens({
    this.hairline = 0.6,
    this.regular = 1,
    this.focus = 2,
  });

  final double hairline;
  final double regular;
  final double focus;

  static LoftifyBorderTokens lerp(
    LoftifyBorderTokens a,
    LoftifyBorderTokens b,
    double t,
  ) {
    return LoftifyBorderTokens(
      hairline: lerpDouble(a.hairline, b.hairline, t)!,
      regular: lerpDouble(a.regular, b.regular, t)!,
      focus: lerpDouble(a.focus, b.focus, t)!,
    );
  }
}

@immutable
class LoftifyShadowTokens {
  const LoftifyShadowTokens({
    required this.floating,
    required this.overlay,
  });

  final List<BoxShadow> floating;
  final List<BoxShadow> overlay;

  static LoftifyShadowTokens lerp(
    LoftifyShadowTokens a,
    LoftifyShadowTokens b,
    double t,
  ) {
    return LoftifyShadowTokens(
      floating: BoxShadow.lerpList(a.floating, b.floating, t)!,
      overlay: BoxShadow.lerpList(a.overlay, b.overlay, t)!,
    );
  }
}

@immutable
class LoftifyIconStateTokens {
  const LoftifyIconStateTokens({
    this.small = 16,
    this.regular = 20,
    this.large = 24,
    this.minimumTapTarget = 48,
    this.disabledOpacity = 0.38,
    this.hoverOpacity = 0.08,
    this.focusOpacity = 0.10,
    this.pressedOpacity = 0.12,
    this.selectedContainerOpacity = 0.12,
  });

  final double small;
  final double regular;
  final double large;
  final double minimumTapTarget;
  final double disabledOpacity;
  final double hoverOpacity;
  final double focusOpacity;
  final double pressedOpacity;
  final double selectedContainerOpacity;

  static LoftifyIconStateTokens lerp(
    LoftifyIconStateTokens a,
    LoftifyIconStateTokens b,
    double t,
  ) {
    return LoftifyIconStateTokens(
      small: lerpDouble(a.small, b.small, t)!,
      regular: lerpDouble(a.regular, b.regular, t)!,
      large: lerpDouble(a.large, b.large, t)!,
      minimumTapTarget: lerpDouble(a.minimumTapTarget, b.minimumTapTarget, t)!,
      disabledOpacity: lerpDouble(a.disabledOpacity, b.disabledOpacity, t)!,
      hoverOpacity: lerpDouble(a.hoverOpacity, b.hoverOpacity, t)!,
      focusOpacity: lerpDouble(a.focusOpacity, b.focusOpacity, t)!,
      pressedOpacity: lerpDouble(a.pressedOpacity, b.pressedOpacity, t)!,
      selectedContainerOpacity: lerpDouble(
        a.selectedContainerOpacity,
        b.selectedContainerOpacity,
        t,
      )!,
    );
  }
}

@immutable
class LoftifyDensityTokens {
  const LoftifyDensityTokens({
    this.contentDenseMinHeight = 48,
    this.contentComfortableMinHeight = 56,
    this.controlComfortableMinHeight = 56,
    this.contentDenseVerticalPadding = 10,
    this.contentComfortableVerticalPadding = 12,
    this.controlComfortableVerticalPadding = 14,
  });

  final double contentDenseMinHeight;
  final double contentComfortableMinHeight;
  final double controlComfortableMinHeight;
  final double contentDenseVerticalPadding;
  final double contentComfortableVerticalPadding;
  final double controlComfortableVerticalPadding;

  double minimumHeight(LoftifyDensityRole role) => switch (role) {
        LoftifyDensityRole.contentDense => contentDenseMinHeight,
        LoftifyDensityRole.contentComfortable => contentComfortableMinHeight,
        LoftifyDensityRole.controlComfortable => controlComfortableMinHeight,
      };

  double verticalPadding(LoftifyDensityRole role) => switch (role) {
        LoftifyDensityRole.contentDense => contentDenseVerticalPadding,
        LoftifyDensityRole.contentComfortable =>
          contentComfortableVerticalPadding,
        LoftifyDensityRole.controlComfortable =>
          controlComfortableVerticalPadding,
      };

  static LoftifyDensityTokens lerp(
    LoftifyDensityTokens a,
    LoftifyDensityTokens b,
    double t,
  ) {
    return LoftifyDensityTokens(
      contentDenseMinHeight: lerpDouble(
        a.contentDenseMinHeight,
        b.contentDenseMinHeight,
        t,
      )!,
      contentComfortableMinHeight: lerpDouble(
        a.contentComfortableMinHeight,
        b.contentComfortableMinHeight,
        t,
      )!,
      controlComfortableMinHeight: lerpDouble(
        a.controlComfortableMinHeight,
        b.controlComfortableMinHeight,
        t,
      )!,
      contentDenseVerticalPadding: lerpDouble(
        a.contentDenseVerticalPadding,
        b.contentDenseVerticalPadding,
        t,
      )!,
      contentComfortableVerticalPadding: lerpDouble(
        a.contentComfortableVerticalPadding,
        b.contentComfortableVerticalPadding,
        t,
      )!,
      controlComfortableVerticalPadding: lerpDouble(
        a.controlComfortableVerticalPadding,
        b.controlComfortableVerticalPadding,
        t,
      )!,
    );
  }
}

@immutable
class LoftifyMotionTokens {
  const LoftifyMotionTokens({
    this.press = const Duration(milliseconds: 90),
    this.state = const Duration(milliseconds: 180),
    this.page = const Duration(milliseconds: 220),
    this.panel = const Duration(milliseconds: 260),
    this.content = const Duration(milliseconds: 280),
    this.enterCurve = Curves.easeOutCubic,
    this.exitCurve = Curves.easeInCubic,
  });

  final Duration press;
  final Duration state;
  final Duration page;
  final Duration panel;
  final Duration content;
  final Curve enterCurve;
  final Curve exitCurve;

  Duration effective(BuildContext context, Duration duration) {
    return MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero
        : duration;
  }

  static LoftifyMotionTokens lerp(
    LoftifyMotionTokens a,
    LoftifyMotionTokens b,
    double t,
  ) {
    Duration lerpDuration(Duration start, Duration end) => Duration(
          microseconds: lerpDouble(
            start.inMicroseconds.toDouble(),
            end.inMicroseconds.toDouble(),
            t,
          )!
              .round(),
        );
    return LoftifyMotionTokens(
      press: lerpDuration(a.press, b.press),
      state: lerpDuration(a.state, b.state),
      page: lerpDuration(a.page, b.page),
      panel: lerpDuration(a.panel, b.panel),
      content: lerpDuration(a.content, b.content),
      enterCurve: t < 0.5 ? a.enterCurve : b.enterCurve,
      exitCurve: t < 0.5 ? a.exitCurve : b.exitCurve,
    );
  }
}

@immutable
class LoftifyGridTokens {
  const LoftifyGridTokens({
    this.compactBreakpoint = 600,
    this.mediumBreakpoint = 840,
    this.expandedBreakpoint = 1200,
    this.compactPagePadding = 12,
    this.phonePagePadding = 16,
    this.widePagePadding = 24,
    this.compactGutter = 10,
    this.mediumGutter = 12,
    this.wideGutter = 16,
    this.minimumCardWidth = 168,
    this.maximumDenseCardExtent = 300,
    this.maximumContentWidth = 1440,
    this.maximumReadingWidth = 720,
  });

  final double compactBreakpoint;
  final double mediumBreakpoint;
  final double expandedBreakpoint;
  final double compactPagePadding;
  final double phonePagePadding;
  final double widePagePadding;
  final double compactGutter;
  final double mediumGutter;
  final double wideGutter;
  final double minimumCardWidth;
  final double maximumDenseCardExtent;
  final double maximumContentWidth;
  final double maximumReadingWidth;

  LoftifyWindowClass windowClassFor(double width) {
    if (width < compactBreakpoint) return LoftifyWindowClass.compact;
    if (width < mediumBreakpoint) return LoftifyWindowClass.medium;
    if (width < expandedBreakpoint) return LoftifyWindowClass.expanded;
    return LoftifyWindowClass.large;
  }

  double pagePaddingFor(double width) => switch (windowClassFor(width)) {
        LoftifyWindowClass.compact =>
          width < 360 ? compactPagePadding : phonePagePadding,
        LoftifyWindowClass.medium ||
        LoftifyWindowClass.expanded ||
        LoftifyWindowClass.large =>
          widePagePadding,
      };

  /// Denser edge rhythm for image-led waterfall feeds on phones. Reading
  /// surfaces and discovery pages keep [pagePaddingFor] for calmer line
  /// lengths, while the home feed gives artwork more of the viewport.
  double denseFeedPagePaddingFor(double width) =>
      switch (windowClassFor(width)) {
        LoftifyWindowClass.compact => width < 360 ? 8 : 10,
        LoftifyWindowClass.medium ||
        LoftifyWindowClass.expanded ||
        LoftifyWindowClass.large =>
          widePagePadding,
      };

  double gutterFor(double width) => switch (windowClassFor(width)) {
        LoftifyWindowClass.compact => compactGutter,
        LoftifyWindowClass.medium => mediumGutter,
        LoftifyWindowClass.expanded || LoftifyWindowClass.large => wideGutter,
      };

  int contentColumnCount(double width) {
    final available =
        width.clamp(0, maximumContentWidth) - pagePaddingFor(width) * 2;
    final columns =
        ((available + gutterFor(width)) / (minimumCardWidth + gutterFor(width)))
            .floor();
    return columns.clamp(1, 6);
  }

  static LoftifyGridTokens lerp(
    LoftifyGridTokens a,
    LoftifyGridTokens b,
    double t,
  ) {
    return LoftifyGridTokens(
      compactBreakpoint:
          lerpDouble(a.compactBreakpoint, b.compactBreakpoint, t)!,
      mediumBreakpoint: lerpDouble(a.mediumBreakpoint, b.mediumBreakpoint, t)!,
      expandedBreakpoint:
          lerpDouble(a.expandedBreakpoint, b.expandedBreakpoint, t)!,
      compactPagePadding:
          lerpDouble(a.compactPagePadding, b.compactPagePadding, t)!,
      phonePagePadding: lerpDouble(a.phonePagePadding, b.phonePagePadding, t)!,
      widePagePadding: lerpDouble(a.widePagePadding, b.widePagePadding, t)!,
      compactGutter: lerpDouble(a.compactGutter, b.compactGutter, t)!,
      mediumGutter: lerpDouble(a.mediumGutter, b.mediumGutter, t)!,
      wideGutter: lerpDouble(a.wideGutter, b.wideGutter, t)!,
      minimumCardWidth: lerpDouble(a.minimumCardWidth, b.minimumCardWidth, t)!,
      maximumDenseCardExtent: lerpDouble(
        a.maximumDenseCardExtent,
        b.maximumDenseCardExtent,
        t,
      )!,
      maximumContentWidth:
          lerpDouble(a.maximumContentWidth, b.maximumContentWidth, t)!,
      maximumReadingWidth:
          lerpDouble(a.maximumReadingWidth, b.maximumReadingWidth, t)!,
    );
  }
}

/// Product-level theme contract for the "Quiet Content Atelier" direction.
@immutable
class LoftifyDesignThemeData extends ThemeExtension<LoftifyDesignThemeData> {
  const LoftifyDesignThemeData({
    required this.colors,
    required this.typography,
    this.spacing = const LoftifySpacingTokens(),
    this.radii = const LoftifyRadiusTokens(),
    this.borders = const LoftifyBorderTokens(),
    required this.shadows,
    this.icons = const LoftifyIconStateTokens(),
    this.density = const LoftifyDensityTokens(),
    this.motion = const LoftifyMotionTokens(),
    this.grid = const LoftifyGridTokens(),
  });

  final LoftifyColorTokens colors;
  final LoftifyTypographyTokens typography;
  final LoftifySpacingTokens spacing;
  final LoftifyRadiusTokens radii;
  final LoftifyBorderTokens borders;
  final LoftifyShadowTokens shadows;
  final LoftifyIconStateTokens icons;
  final LoftifyDensityTokens density;
  final LoftifyMotionTokens motion;
  final LoftifyGridTokens grid;

  static LoftifyDesignThemeData of(BuildContext context) {
    final extension = Theme.of(context).extension<LoftifyDesignThemeData>();
    return extension ?? LoftifyTheme._fallbackDesign(Theme.of(context));
  }

  @override
  LoftifyDesignThemeData copyWith({
    LoftifyColorTokens? colors,
    LoftifyTypographyTokens? typography,
    LoftifySpacingTokens? spacing,
    LoftifyRadiusTokens? radii,
    LoftifyBorderTokens? borders,
    LoftifyShadowTokens? shadows,
    LoftifyIconStateTokens? icons,
    LoftifyDensityTokens? density,
    LoftifyMotionTokens? motion,
    LoftifyGridTokens? grid,
  }) {
    return LoftifyDesignThemeData(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      borders: borders ?? this.borders,
      shadows: shadows ?? this.shadows,
      icons: icons ?? this.icons,
      density: density ?? this.density,
      motion: motion ?? this.motion,
      grid: grid ?? this.grid,
    );
  }

  @override
  LoftifyDesignThemeData lerp(
    covariant LoftifyDesignThemeData? other,
    double t,
  ) {
    if (other == null) return this;
    return LoftifyDesignThemeData(
      colors: LoftifyColorTokens.lerp(colors, other.colors, t),
      typography: LoftifyTypographyTokens.lerp(typography, other.typography, t),
      spacing: LoftifySpacingTokens.lerp(spacing, other.spacing, t),
      radii: LoftifyRadiusTokens.lerp(radii, other.radii, t),
      borders: LoftifyBorderTokens.lerp(borders, other.borders, t),
      shadows: LoftifyShadowTokens.lerp(shadows, other.shadows, t),
      icons: LoftifyIconStateTokens.lerp(icons, other.icons, t),
      density: LoftifyDensityTokens.lerp(density, other.density, t),
      motion: LoftifyMotionTokens.lerp(motion, other.motion, t),
      grid: LoftifyGridTokens.lerp(grid, other.grid, t),
    );
  }
}

/// Builds the app ThemeData and keeps legacy Chewie colors and custom accent
/// themes as the authoritative user preference source.
abstract final class LoftifyTheme {
  static ThemeData build(ChewieThemeColorData source) {
    final base = source.toThemeData();
    final isDark = source.isDarkMode;
    final colors = _colors(source, isDark: isDark);
    final typography = _typography(base, colors);
    final materialTextTheme = _materialTextTheme(base.textTheme, typography);
    final shadows = _shadows(isDark: isDark);
    final design = LoftifyDesignThemeData(
      colors: colors,
      typography: typography,
      shadows: shadows,
    );
    final radii = design.radii;
    final borders = design.borders;
    final icons = design.icons;
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.control),
      borderSide: BorderSide(
        color: colors.outline,
        width: borders.regular,
      ),
    );
    final iconTheme =
        (base.extension<ChewieIconThemeData>() ?? ChewieIconThemeData.standard)
            .copyWith(
      smallSize: icons.small,
      regularSize: icons.regular,
      largeSize: icons.large,
      minimumTapTarget: icons.minimumTapTarget,
      cornerRadius: radii.control,
      disabledOpacity: icons.disabledOpacity,
      hoverOpacity: icons.hoverOpacity,
      focusOpacity: icons.focusOpacity,
      pressedOpacity: icons.pressedOpacity,
      selectedContainerOpacity: icons.selectedContainerOpacity,
    );
    final extensions = base.extensions.values
        .where(
          (extension) =>
              extension is! LoftifyDesignThemeData &&
              extension is! ChewieIconThemeData,
        )
        .toList(growable: true)
      ..add(iconTheme)
      ..add(design);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: colors.accent,
        onPrimary: colors.onAccent,
        primaryContainer: colors.accentContainer,
        onPrimaryContainer: colors.onAccentContainer,
        surface: colors.page,
        onSurface: colors.textPrimary,
        onSurfaceVariant: colors.textSecondary,
        outline: colors.outline,
        outlineVariant: colors.outlineStrong,
        error: colors.danger,
      ),
      scaffoldBackgroundColor: colors.page,
      canvasColor: source.canvasColor,
      // Legacy content controls intentionally use the theme card color as a
      // soft grey information surface. Mapping this role to raised white made
      // post-detail collection, grain and tag controls disappear on the white
      // page background.
      cardColor: source.cardColor,
      dividerColor: colors.outline,
      textTheme: materialTextTheme,
      iconTheme: IconThemeData(color: colors.textSecondary, size: icons.large),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: colors.page,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: materialTextTheme.titleLarge,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: colors.page,
        elevation: 0,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textSecondary,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: colors.page,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colors.accentContainer,
      ),
      cardTheme: CardThemeData(
        color: source.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.card),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outline,
        thickness: borders.hairline,
        space: borders.hairline,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: colors.surface,
        hintStyle: typography.body.copyWith(color: colors.textMuted),
        labelStyle: typography.label.copyWith(color: colors.textSecondary),
        errorStyle: typography.metadata.copyWith(color: colors.danger),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(
            color: colors.accent,
            width: borders.focus,
          ),
        ),
        errorBorder: outline.copyWith(
          borderSide: BorderSide(
            color: colors.danger,
            width: borders.regular,
          ),
        ),
        focusedErrorBorder: outline.copyWith(
          borderSide: BorderSide(
            color: colors.danger,
            width: borders.focus,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, icons.minimumTapTarget),
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          textStyle: typography.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.control),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, icons.minimumTapTarget),
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.outlineStrong),
          textStyle: typography.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.control),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(0, icons.minimumTapTarget),
          foregroundColor: colors.accent,
          textStyle: typography.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.control),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.dialog),
          side: BorderSide(color: colors.outline, width: borders.hairline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surfaceRaised,
        modalBarrierColor: colors.scrim,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radii.panel),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: typography.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.control),
          side: BorderSide(color: colors.outline, width: borders.hairline),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.surface,
        selectedColor: colors.accentContainer,
        disabledColor: colors.surfaceMuted,
        labelStyle: typography.label,
        secondaryLabelStyle: typography.label.copyWith(
          color: colors.onAccentContainer,
        ),
        side: BorderSide(color: colors.outline, width: borders.hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.full),
        ),
      ),
      extensions: extensions,
    );
  }

  static LoftifyColorTokens _colors(
    ChewieThemeColorData source, {
    required bool isDark,
  }) {
    return _semanticColors(
      accent: source.primaryColor,
      success: source.successColor,
      warning: source.warningColor,
      danger: source.errorColor,
      isDark: isDark,
    );
  }

  static LoftifyDesignThemeData _fallbackDesign(ThemeData base) {
    final isDark = base.brightness == Brightness.dark;
    final colors = _semanticColors(
      accent: base.colorScheme.primary,
      success: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
      warning: isDark ? const Color(0xFFFFB74D) : const Color(0xFF9A6700),
      danger: base.colorScheme.error,
      isDark: isDark,
    );
    return LoftifyDesignThemeData(
      colors: colors,
      typography: _typography(base, colors),
      shadows: _shadows(isDark: isDark),
    );
  }

  static LoftifyColorTokens _semanticColors({
    required Color accent,
    required Color success,
    required Color warning,
    required Color danger,
    required bool isDark,
  }) {
    final page = isDark ? const Color(0xFF121412) : const Color(0xFFFFFFFF);
    final surface = isDark ? const Color(0xFF191C1A) : const Color(0xFFF7F8F7);
    final surfaceRaised =
        isDark ? const Color(0xFF202421) : const Color(0xFFFFFFFF);
    final textPrimary =
        isDark ? const Color(0xFFF2F5F3) : const Color(0xFF202522);
    final accentContainer = Color.alphaBlend(
      accent.withAlpha(isDark ? 52 : 28),
      surfaceRaised,
    );
    final tonalCandidate = isDark
        ? Color.lerp(accent, Colors.white, 0.30)!
        : Color.lerp(accent, const Color(0xFF10201B), 0.38)!;
    final onAccentContainer = _contrastRatio(
              tonalCandidate,
              accentContainer,
            ) >=
            4.5
        ? tonalCandidate
        : _contrastRatio(accent, accentContainer) >= 4.5
            ? accent
            : textPrimary;
    final readableSuccess = _readableStatusColor(
      success,
      backgrounds: [page, surfaceRaised],
      isDark: isDark,
    );
    final readableWarning = _readableStatusColor(
      warning,
      backgrounds: [page, surfaceRaised],
      isDark: isDark,
    );
    final readableDanger = _readableStatusColor(
      danger,
      backgrounds: [page, surfaceRaised],
      isDark: isDark,
    );
    return LoftifyColorTokens(
      page: page,
      surface: surface,
      surfaceRaised: surfaceRaised,
      surfaceMuted: isDark ? const Color(0xFF252A27) : const Color(0xFFF0F3F1),
      textPrimary: textPrimary,
      textSecondary: isDark ? const Color(0xFFAEB8B2) : const Color(0xFF66706B),
      textMuted: isDark ? const Color(0xFF839089) : const Color(0xFF8D9791),
      outline: isDark ? const Color(0xFF303630) : const Color(0xFFE5E9E6),
      outlineStrong: isDark ? const Color(0xFF485049) : const Color(0xFFCDD4CF),
      accent: accent,
      onAccent: ColorUtil.getContrastColor(accent),
      accentContainer: accentContainer,
      onAccentContainer: onAccentContainer,
      success: readableSuccess,
      warning: readableWarning,
      danger: readableDanger,
      scrim: Colors.black.withAlpha(isDark ? 156 : 104),
    );
  }

  static double _contrastRatio(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color _readableStatusColor(
    Color source, {
    required List<Color> backgrounds,
    required bool isDark,
  }) {
    bool isReadable(Color candidate) {
      for (final background in backgrounds) {
        final tinted = Color.alphaBlend(
          candidate.withValues(alpha: 0.10),
          background,
        );
        if (_contrastRatio(candidate, background) < 4.5 ||
            _contrastRatio(candidate, tinted) < 4.5) {
          return false;
        }
      }
      return true;
    }

    if (isReadable(source)) return source;
    final target = isDark ? Colors.white : Colors.black;
    for (var step = 1; step <= 100; step++) {
      final candidate = Color.lerp(source, target, step / 100)!;
      if (isReadable(candidate)) return candidate;
    }
    return target;
  }

  static LoftifyTypographyTokens _typography(
    ThemeData base,
    LoftifyColorTokens colors,
  ) {
    TextStyle role({
      required double size,
      required double height,
      required FontWeight weight,
      required Color color,
      double letterSpacing = 0,
    }) {
      return TextStyle(
        inherit: true,
        fontFamily: base.textTheme.bodyMedium?.fontFamily,
        fontFamilyFallback: base.textTheme.bodyMedium?.fontFamilyFallback,
        fontSize: size,
        height: height,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        decoration: TextDecoration.none,
      );
    }

    return LoftifyTypographyTokens(
      display: role(
        size: 28,
        height: 1.25,
        weight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      pageTitle: role(
        size: 20,
        height: 1.30,
        weight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      sectionTitle: role(
        size: 16,
        height: 1.35,
        weight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      cardTitle: role(
        size: 15,
        height: 1.40,
        weight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      body: role(
        size: 15,
        height: 1.60,
        weight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      readingBody: role(
        size: 17,
        height: 1.80,
        weight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      metadata: role(
        size: 12,
        height: 1.45,
        weight: FontWeight.w400,
        color: colors.textSecondary,
        letterSpacing: 0.1,
      ),
      label: role(
        size: 13,
        height: 1.30,
        weight: FontWeight.w600,
        color: colors.textPrimary,
        letterSpacing: 0.1,
      ),
    );
  }

  static LoftifyShadowTokens _shadows({required bool isDark}) {
    if (isDark) {
      return const LoftifyShadowTokens(
        floating: <BoxShadow>[
          BoxShadow(
            color: Color(0x52000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        overlay: <BoxShadow>[
          BoxShadow(
            color: Color(0x70000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      );
    }
    return const LoftifyShadowTokens(
      floating: <BoxShadow>[
        BoxShadow(
          color: Color(0x140D1F18),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
      overlay: <BoxShadow>[
        BoxShadow(
          color: Color(0x1F0D1F18),
          blurRadius: 32,
          offset: Offset(0, 12),
        ),
      ],
    );
  }

  static TextTheme _materialTextTheme(
    TextTheme base,
    LoftifyTypographyTokens type,
  ) {
    TextStyle? primary(TextStyle? style) =>
        style?.copyWith(color: type.body.color);
    TextStyle? secondary(TextStyle? style) =>
        style?.copyWith(color: type.metadata.color);

    // Preserve the original app scale for legacy pages. Many of those pages
    // intentionally apply small local font deltas; remapping the Material
    // roles to larger design-token sizes compounded those deltas and made only
    // some controls unexpectedly oversized. New components opt into [type]
    // directly, while existing screens retain their established hierarchy.
    return base.copyWith(
      displayLarge: primary(base.displayLarge),
      displayMedium: primary(base.displayMedium),
      displaySmall: primary(base.displaySmall),
      headlineLarge: primary(base.headlineLarge),
      headlineMedium: primary(base.headlineMedium),
      headlineSmall: primary(base.headlineSmall),
      titleLarge: primary(base.titleLarge),
      titleMedium: primary(base.titleMedium),
      titleSmall: primary(base.titleSmall),
      bodyLarge: primary(base.bodyLarge),
      bodyMedium: primary(base.bodyMedium),
      bodySmall: secondary(base.bodySmall),
      labelLarge: secondary(base.labelLarge),
      labelMedium: secondary(base.labelMedium),
      labelSmall: secondary(base.labelSmall),
    );
  }
}

extension LoftifyThemeContext on BuildContext {
  LoftifyDesignThemeData get design => LoftifyDesignThemeData.of(this);

  LoftifyWindowClass get windowClass =>
      design.grid.windowClassFor(MediaQuery.sizeOf(this).width);

  double get pageHorizontalPadding =>
      design.grid.pagePaddingFor(MediaQuery.sizeOf(this).width);
}
