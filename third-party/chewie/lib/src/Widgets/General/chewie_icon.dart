import 'package:flutter/material.dart';

import '../../Resources/icon_theme.dart';

/// A theme-aware interface icon with one optical size and disabled-state rule.
class ChewieIcon extends StatelessWidget {
  const ChewieIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.enabled = true,
    this.semanticLabel,
    this.textDirection,
    this.shadows,
    this.opticalOffset = Offset.zero,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final bool enabled;
  final String? semanticLabel;
  final TextDirection? textDirection;
  final List<Shadow>? shadows;

  /// Allows a rare glyph-specific optical correction without changing layout.
  final Offset opticalOffset;

  @override
  Widget build(BuildContext context) {
    final specification = ChewieIconThemeData.of(context);
    final iconTheme = IconTheme.of(context);
    final baseColor =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    final disabledOpacity = MediaQuery.highContrastOf(context) &&
            specification.disabledOpacity < 0.5
        ? 0.5
        : specification.disabledOpacity;
    final effectiveColor = enabled
        ? baseColor
        : baseColor.withValues(
            alpha: baseColor.a * disabledOpacity,
          );
    final effectiveSize = size ?? specification.regularSize;
    final child = Icon(
      icon,
      size: effectiveSize,
      color: effectiveColor,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
      shadows: shadows,
    );
    if (opticalOffset == Offset.zero) return child;
    return Transform.translate(offset: opticalOffset, child: child);
  }
}
