import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';

class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    super.key,
    required this.children,
    this.horizontalPadding = 10,
    this.spacing = 4,
  });

  final List<Widget> children;
  final double horizontalPadding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: Container(
          height: 64,
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                Expanded(child: children[index]),
                if (index != children.length - 1) SizedBox(width: spacing),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DetailActionSlot extends StatelessWidget {
  const DetailActionSlot({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(design.radii.control),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(design.radii.control),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? design.colors.accent.withValues(
                    alpha: design.icons.pressedOpacity,
                  )
                : Colors.transparent,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class DetailActionButton extends StatelessWidget {
  const DetailActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.foregroundColor,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final color = foregroundColor ?? design.colors.textPrimary;
    return DetailActionSlot(
      semanticLabel: label,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: design.spacing.xxs,
          vertical: design.spacing.xxs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconTheme.of(context).copyWith(color: color, size: 24),
              child: icon,
            ),
            SizedBox(height: design.spacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: design.typography.metadata.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Token-driven vertical action rail used by reading and image detail pages.
class DetailFloatingActionRail extends StatelessWidget {
  const DetailFloatingActionRail({
    super.key,
    required this.children,
    this.slotWidth = 54,
    this.slotHeight = 52,
  });

  final List<Widget> children;
  final double slotWidth;
  final double slotHeight;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        key: const ValueKey('detail-floating-action-rail'),
        decoration: BoxDecoration(
          color: design.colors.surfaceRaised,
          borderRadius: BorderRadius.circular(design.radii.panel),
          border: Border.all(
            color: design.colors.outline,
            width: design.borders.hairline,
          ),
          boxShadow: design.shadows.floating,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(design.radii.panel),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: design.spacing.xs,
              vertical: design.spacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final child in children)
                  SizedBox(
                    width: slotWidth,
                    height: slotHeight,
                    child: child,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
