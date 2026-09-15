import 'package:flutter/material.dart';

import '../../Resources/chewie_icons.dart';

/// A visual-only selection marker for cards whose whole surface is tappable.
///
/// Selection semantics and gestures belong on the parent card so this marker
/// never creates a second, smaller interaction target.
class ChewieSelectionIndicator extends StatelessWidget {
  const ChewieSelectionIndicator({
    super.key,
    required this.selected,
    this.selectedColor,
    this.unselectedColor,
    this.size = 24,
  });

  final bool selected;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = selectedColor ?? colorScheme.primary;
    final inactiveColor = unselectedColor ?? colorScheme.outlineVariant;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 160);

    return IgnorePointer(
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? activeColor : Colors.transparent,
          border: Border.all(
            color: selected ? activeColor : inactiveColor,
          ),
        ),
        child: AnimatedSwitcher(
          duration: duration,
          child: selected
              ? Icon(
                  ChewieIcons.check,
                  key: const ValueKey('selected'),
                  size: size * 0.62,
                  color: colorScheme.onPrimary,
                )
              : const SizedBox.shrink(key: ValueKey('unselected')),
        ),
      ),
    );
  }
}
