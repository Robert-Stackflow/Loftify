import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../Theme/loftify_design_theme.dart';

enum LoftifyLottieLayout { icon, effect }

enum LoftifyLottieTintRole { none, accent, foreground, danger }

enum LoftifyLottieColorRole {
  accent,
  accentSecondary,
  foreground,
  surfaceMuted,
  danger,
}

enum LoftifyLottieColorProperty { fill, stroke }

@immutable
class LoftifyLottieColorBinding {
  const LoftifyLottieColorBinding({
    required this.keyPath,
    required this.role,
    required this.property,
  });

  final List<String> keyPath;
  final LoftifyLottieColorRole role;
  final LoftifyLottieColorProperty property;
}

@immutable
class LoftifyLottieSpec {
  const LoftifyLottieSpec({
    required this.asset,
    required this.sourceSize,
    this.contentBounds,
    this.layout = LoftifyLottieLayout.icon,
    this.tintRole = LoftifyLottieTintRole.none,
    this.colorBindings = const [],
    this.opticalFill = 0.86,
    this.repeat = false,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  }) : assert(opticalFill > 0 && opticalFill <= 1);

  final String asset;
  final Size sourceSize;

  /// The animated content's stable optical viewport in source coordinates.
  ///
  /// This is deliberately independent from the JSON canvas. Several legacy
  /// assets reserve space for labels or effects, so fitting the raw canvas
  /// makes visually identical icons render at unrelated sizes.
  final Rect? contentBounds;
  final LoftifyLottieLayout layout;
  final LoftifyLottieTintRole tintRole;
  final List<LoftifyLottieColorBinding> colorBindings;
  final double opticalFill;
  final bool repeat;
  final BoxFit fit;
  final Alignment alignment;

  Rect get effectiveContentBounds => contentBounds ?? Offset.zero & sourceSize;
}

/// A stable square viewport for icon-like Lottie assets.
///
/// Source compositions and keyframes are left untouched. [LoftifyLottieSpec]
/// maps their meaningful content into one optical canvas so callers can size
/// them exactly like a normal icon. Scene/effect animations retain their
/// original aspect ratio and fitting behaviour.
class LoftifyLottie extends StatelessWidget {
  const LoftifyLottie({
    super.key,
    required this.spec,
    required this.size,
    this.controller,
    this.animate = true,
    this.repeat,
    this.tint,
    this.onLoaded,
  });

  final LoftifyLottieSpec spec;
  final double size;
  final AnimationController? controller;
  final bool animate;
  final bool? repeat;
  final Color? tint;
  final ValueChanged<LottieComposition>? onLoaded;

  static bool shouldReduceMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final platformReduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.reduceMotion;
    return platformReduceMotion ||
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
  }

  Color? _resolveTint(BuildContext context) {
    if (tint != null) return tint;
    final colors = LoftifyDesignThemeData.of(context).colors;
    return switch (spec.tintRole) {
      LoftifyLottieTintRole.none => null,
      LoftifyLottieTintRole.accent => colors.accent,
      LoftifyLottieTintRole.foreground => colors.textPrimary,
      LoftifyLottieTintRole.danger => colors.danger,
    };
  }

  Color _resolveColorRole(
    BuildContext context,
    LoftifyLottieColorRole role,
  ) {
    final colors = LoftifyDesignThemeData.of(context).colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (role) {
      LoftifyLottieColorRole.accent => colors.accent,
      LoftifyLottieColorRole.accentSecondary => Color.lerp(
          colors.accent,
          colors.page,
          isDark ? 0.28 : 0.42,
        )!,
      LoftifyLottieColorRole.foreground => colors.textPrimary,
      LoftifyLottieColorRole.surfaceMuted => colors.surfaceMuted,
      LoftifyLottieColorRole.danger => colors.danger,
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = shouldReduceMotion(context);
    final resolvedTint = _resolveTint(context);
    final colorDelegates = <ValueDelegate>[];
    if (resolvedTint != null) {
      colorDelegates.add(
        ValueDelegate.colorFilter(
          const ['**'],
          value: ColorFilter.mode(resolvedTint, BlendMode.srcIn),
        ),
      );
    } else {
      for (final binding in spec.colorBindings) {
        final color = _resolveColorRole(context, binding.role);
        colorDelegates.add(
          switch (binding.property) {
            LoftifyLottieColorProperty.fill =>
              ValueDelegate.color(binding.keyPath, value: color),
            LoftifyLottieColorProperty.stroke =>
              ValueDelegate.strokeColor(binding.keyPath, value: color),
          },
        );
      }
    }
    final delegates =
        colorDelegates.isEmpty ? null : LottieDelegates(values: colorDelegates);
    final animation = Lottie.asset(
      spec.asset,
      controller: controller,
      animate: animate && !reduceMotion,
      repeat: (repeat ?? spec.repeat) && !reduceMotion,
      fit: spec.fit,
      alignment: spec.alignment,
      delegates: delegates,
      addRepaintBoundary: true,
      onLoaded: (composition) {
        if (controller != null) controller!.duration = composition.duration;
        onLoaded?.call(composition);
      },
    );

    if (spec.layout == LoftifyLottieLayout.effect) {
      return Align(
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox.square(
          key: ValueKey('loftify-lottie-effect-${spec.asset}'),
          dimension: size,
          child: animation,
        ),
      );
    }

    final bounds = spec.effectiveContentBounds;
    final scale = size *
        spec.opticalFill /
        (bounds.width > bounds.height ? bounds.width : bounds.height);
    final compositionWidth = spec.sourceSize.width * scale;
    final compositionHeight = spec.sourceSize.height * scale;
    final left = size / 2 - bounds.center.dx * scale;
    final top = size / 2 - bounds.center.dy * scale;

    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox.square(
        key: ValueKey('loftify-lottie-icon-${spec.asset}'),
        dimension: size,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: left,
                top: top,
                width: compositionWidth,
                height: compositionHeight,
                child: animation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
