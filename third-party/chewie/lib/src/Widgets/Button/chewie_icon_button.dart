import 'package:flutter/material.dart';

import '../../Resources/icon_theme.dart';
import '../General/chewie_icon.dart';

enum ChewieIconButtonStyle {
  plain,
  soft,
  outlined,
}

/// The shared Lucide button primitive used by app bars, menus and inline tools.
class ChewieIconButton extends StatelessWidget {
  const ChewieIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.onLongPress,
    this.tooltip,
    this.semanticLabel,
    this.selected = false,
    this.style = ChewieIconButtonStyle.plain,
    this.iconSize,
    this.tapTargetSize,
    this.foregroundColor,
    this.selectedColor,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.cornerRadius,
    this.opticalOffset = Offset.zero,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final String? semanticLabel;
  final bool selected;
  final ChewieIconButtonStyle style;
  final double? iconSize;
  final double? tapTargetSize;
  final Color? foregroundColor;
  final Color? selectedColor;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final Color? borderColor;
  final double? cornerRadius;
  final Offset opticalOffset;

  @override
  Widget build(BuildContext context) {
    final specification = ChewieIconThemeData.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highContrast = MediaQuery.highContrastOf(context);
    final disabledOpacity = highContrast && specification.disabledOpacity < 0.5
        ? 0.5
        : specification.disabledOpacity;
    final effectiveTarget =
        (tapTargetSize ?? specification.minimumTapTarget).clamp(
      specification.minimumTapTarget,
      double.infinity,
    );
    final baseForeground = foregroundColor ??
        IconTheme.of(context).color ??
        colorScheme.onSurfaceVariant;
    final activeForeground = selectedColor ?? colorScheme.primary;
    final effectiveBackground = _background(
      context,
      specification,
      selected,
      highContrast,
    );
    final effectiveBorder = style == ChewieIconButtonStyle.outlined
        ? borderColor ?? colorScheme.outlineVariant
        : highContrast && selected
            ? activeForeground
            : Colors.transparent;

    final button = IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      isSelected: selected,
      iconSize: iconSize ?? specification.regularSize,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: effectiveTarget,
        height: effectiveTarget,
      ),
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return baseForeground.withValues(
              alpha: baseForeground.a * disabledOpacity,
            );
          }
          return selected ? activeForeground : baseForeground;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return effectiveBackground.withValues(
              alpha: effectiveBackground.a * disabledOpacity,
            );
          }
          return effectiveBackground;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          final overlayBase = selected ? activeForeground : baseForeground;
          if (states.contains(WidgetState.pressed)) {
            return overlayBase.withValues(alpha: specification.pressedOpacity);
          }
          if (states.contains(WidgetState.focused)) {
            return overlayBase.withValues(alpha: specification.focusOpacity);
          }
          if (states.contains(WidgetState.hovered)) {
            return overlayBase.withValues(alpha: specification.hoverOpacity);
          }
          return Colors.transparent;
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: effectiveBorder, width: highContrast ? 1.2 : 0.8),
        ),
        shape: WidgetStatePropertyAll(
          cornerRadius == null
              ? const CircleBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cornerRadius!),
                ),
        ),
      ),
      icon: ChewieIcon(
        icon,
        size: iconSize ?? specification.regularSize,
        color: selected ? activeForeground : baseForeground,
        enabled: onPressed != null,
        opticalOffset: opticalOffset,
      ),
      selectedIcon: ChewieIcon(
        icon,
        size: iconSize ?? specification.regularSize,
        color: activeForeground,
        enabled: onPressed != null,
        opticalOffset: opticalOffset,
      ),
    );

    final label = semanticLabel ?? tooltip;
    final accessibleButton = label == null
        ? button
        : Semantics(
            container: true,
            button: true,
            enabled: onPressed != null,
            selected: selected,
            label: label,
            onTap: onPressed,
            onLongPress: onLongPress,
            excludeSemantics: true,
            child: button,
          );
    if (onLongPress == null) return accessibleButton;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: onLongPress,
      child: accessibleButton,
    );
  }

  Color _background(
    BuildContext context,
    ChewieIconThemeData specification,
    bool isSelected,
    bool highContrast,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isSelected) {
      return selectedBackgroundColor ??
          colorScheme.primary.withValues(
            alpha: highContrast && specification.selectedContainerOpacity < 0.2
                ? 0.2
                : specification.selectedContainerOpacity,
          );
    }
    if (backgroundColor != null) return backgroundColor!;
    return switch (style) {
      ChewieIconButtonStyle.plain => Colors.transparent,
      ChewieIconButtonStyle.soft =>
        colorScheme.surfaceContainerHighest.withValues(
          alpha: highContrast ? 0.72 : 0.58,
        ),
      ChewieIconButtonStyle.outlined => Colors.transparent,
    };
  }
}
