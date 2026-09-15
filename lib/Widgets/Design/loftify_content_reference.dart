import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../loftify_icons.dart';
import 'loftify_surfaces.dart';

@immutable
class LoftifyContentReferenceAction {
  const LoftifyContentReferenceAction({
    required this.label,
    required this.onPressed,
    this.onDisabledPressed,
    this.icon,
    this.enabled = true,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onDisabledPressed;
  final IconData? icon;
  final bool enabled;
  final bool emphasized;
}

/// A low-noise content relationship used for collections, grains and other
/// containers a post belongs to.
///
/// The component grows with localized labels and dynamic text. Its quiet
/// filled surface restores the compact relationship treatment used by post
/// details without competing with the work itself.
class LoftifyContentReferenceCard extends StatelessWidget {
  const LoftifyContentReferenceCard({
    super.key,
    required this.icon,
    required this.title,
    this.eyebrow,
    this.onTap,
    this.trailing,
    this.actions = const <LoftifyContentReferenceAction>[],
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String? eyebrow;
  final VoidCallback? onTap;
  final Widget? trailing;
  final List<LoftifyContentReferenceAction> actions;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return LoftifyCard(
      key: const ValueKey('loftify-content-reference-card'),
      variant: LoftifyCardVariant.muted,
      onTap: onTap,
      semanticLabel: semanticLabel ?? title,
      radius: design.radii.control,
      padding: EdgeInsets.symmetric(
        horizontal: design.spacing.md,
        vertical: design.spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale =
                  MediaQuery.textScalerOf(context).scale(1).clamp(1, 3);
              final stackTrailing = trailing != null &&
                  (constraints.maxWidth < 300 || textScale > 1.35);
              if (!stackTrailing) {
                return _buildHeaderRow(context, includeTrailing: true);
              }
              return Column(
                key: const ValueKey('content-reference-header-stacked'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderRow(context, includeTrailing: false),
                  SizedBox(height: design.spacing.xs),
                  Align(alignment: Alignment.centerRight, child: trailing!),
                ],
              );
            },
          ),
          if (actions.isNotEmpty) ...[
            SizedBox(height: design.spacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale =
                    MediaQuery.textScalerOf(context).scale(1).clamp(1, 3);
                final stackActions =
                    constraints.maxWidth < 300 || textScale > 1.35;
                final children = actions
                    .map((action) => _ContentReferenceActionButton(action))
                    .toList(growable: false);
                if (stackActions) {
                  return Column(
                    key: const ValueKey('content-reference-actions-stacked'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < children.length; index++) ...[
                        children[index],
                        if (index != children.length - 1)
                          SizedBox(height: design.spacing.sm),
                      ],
                    ],
                  );
                }
                return Row(
                  key: const ValueKey('content-reference-actions-inline'),
                  children: [
                    for (var index = 0; index < children.length; index++) ...[
                      Expanded(child: children[index]),
                      if (index != children.length - 1)
                        SizedBox(width: design.spacing.sm),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context, {
    required bool includeTrailing,
  }) {
    final design = context.design;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          key: const ValueKey('loftify-content-reference-icon'),
          icon,
          size: design.icons.small,
          color: eyebrow?.isNotEmpty == true
              ? design.colors.accentForeground
              : design.colors.textSecondary,
        ),
        SizedBox(width: design.spacing.sm),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale =
                  MediaQuery.textScalerOf(context).scale(1).clamp(1, 3);
              final stackText = textScale > 1.35 || constraints.maxWidth < 220;
              final titleWidget = Text(
                title,
                maxLines: stackText ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: design.typography.label.copyWith(
                  color: design.colors.textPrimary,
                ),
              );
              if (eyebrow?.isNotEmpty != true) return titleWidget;
              final eyebrowWidget = Text(
                eyebrow!,
                maxLines: stackText ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: design.typography.metadata.copyWith(
                  color: design.colors.accentForeground,
                  fontWeight: FontWeight.w600,
                ),
              );
              if (stackText) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    eyebrowWidget,
                    SizedBox(height: design.spacing.xxs),
                    titleWidget,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(child: eyebrowWidget),
                  SizedBox(width: design.spacing.sm),
                  Expanded(child: titleWidget),
                ],
              );
            },
          ),
        ),
        if (includeTrailing && trailing != null) ...[
          SizedBox(width: design.spacing.md),
          trailing!,
        ] else if (includeTrailing && onTap != null) ...[
          SizedBox(width: design.spacing.md),
          Icon(
            LoftifyIcons.next,
            size: design.icons.small,
            color: design.colors.textMuted,
          ),
        ],
      ],
    );
  }
}

class _ContentReferenceActionButton extends StatelessWidget {
  const _ContentReferenceActionButton(this.action);

  final LoftifyContentReferenceAction action;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final enabled = action.enabled;
    final foreground = action.emphasized
        ? design.colors.onAccentContainer
        : enabled
            ? design.colors.textPrimary
            : design.colors.textMuted;
    final background =
        action.emphasized ? design.colors.accentContainer : design.colors.page;
    return Semantics(
      button: true,
      enabled: enabled,
      label: action.label,
      child: Opacity(
        opacity: enabled ? 1 : design.icons.disabledOpacity,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: design.icons.minimumTapTarget,
          ),
          child: Center(
            child: Material(
              color: background,
              borderRadius: BorderRadius.circular(design.radii.small),
              child: InkWell(
                onTap: enabled ? action.onPressed : action.onDisabledPressed,
                splashFactory: NoSplash.splashFactory,
                borderRadius: BorderRadius.circular(design.radii.small),
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return design.colors.accent.withValues(
                      alpha: design.icons.pressedOpacity,
                    );
                  }
                  if (states.contains(WidgetState.focused)) {
                    return design.colors.accent.withValues(
                      alpha: design.icons.focusOpacity,
                    );
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return design.colors.accent.withValues(
                      alpha: design.icons.hoverOpacity,
                    );
                  }
                  return Colors.transparent;
                }),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: design.spacing.md,
                    vertical: design.spacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (action.icon != null) ...[
                        Icon(
                          action.icon,
                          size: design.icons.small,
                          color: foreground,
                        ),
                        SizedBox(width: design.spacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          action.label,
                          textAlign: TextAlign.center,
                          style: design.typography.metadata.copyWith(
                            color: foreground,
                            fontWeight: action.emphasized
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact contextual pill for an AppBar. Standalone navigation actions still
/// use circular icon buttons; this shape is reserved for a text relationship.
class LoftifyContextPill extends StatelessWidget {
  const LoftifyContextPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final textScale = mediaQuery.textScaler.scale(1).clamp(1, 3);
    final maxWidth = switch (screenWidth) {
      <= 360 => 96.0,
      <= 420 when textScale > 1.35 => 104.0,
      <= 420 => 128.0,
      _ => 180.0,
    };
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: Material(
        key: const ValueKey('loftify-context-pill'),
        color: design.colors.surfaceMuted,
        shape: StadiumBorder(
          side: BorderSide(
            color: design.colors.outline,
            width: design.borders.hairline,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return design.colors.accent.withValues(
                alpha: design.icons.pressedOpacity,
              );
            }
            if (states.contains(WidgetState.focused)) {
              return design.colors.accent.withValues(
                alpha: design.icons.focusOpacity,
              );
            }
            if (states.contains(WidgetState.hovered)) {
              return design.colors.accent.withValues(
                alpha: design.icons.hoverOpacity,
              );
            }
            return Colors.transparent;
          }),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 36, maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: design.spacing.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: design.icons.small,
                    color: design.colors.textSecondary,
                  ),
                  SizedBox(width: design.spacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: design.typography.label.copyWith(
                        color: design.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
