import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../loftify_icons.dart';

enum LoftifyCardVariant { flat, outlined, raised, muted }

enum LoftifySurfaceStatus {
  normal,
  selected,
  success,
  warning,
  error,
  disabled
}

/// Token-driven content surface shared by cards across product families.
///
/// It deliberately has no fixed height. Localized copy, large text and dense
/// metadata can grow without weakening the minimum interaction target.
class LoftifyCard extends StatelessWidget {
  const LoftifyCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.variant = LoftifyCardVariant.flat,
    this.status = LoftifySurfaceStatus.normal,
    this.backgroundColor,
    this.radius,
    this.semanticLabel,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final LoftifyCardVariant variant;
  final LoftifySurfaceStatus status;
  final Color? backgroundColor;
  final double? radius;
  final String? semanticLabel;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final colors = design.colors;
    final highContrast = MediaQuery.highContrastOf(context);
    final enabled = status != LoftifySurfaceStatus.disabled;
    final interactive = enabled && (onTap != null || onLongPress != null);
    final stateColor = switch (status) {
      LoftifySurfaceStatus.selected => colors.accentForeground,
      LoftifySurfaceStatus.success => colors.success,
      LoftifySurfaceStatus.warning => colors.warning,
      LoftifySurfaceStatus.error => colors.danger,
      LoftifySurfaceStatus.normal || LoftifySurfaceStatus.disabled => null,
    };
    final baseColor = backgroundColor ??
        switch (status) {
          LoftifySurfaceStatus.selected => colors.accentContainer,
          LoftifySurfaceStatus.success =>
            colors.success.withValues(alpha: 0.08),
          LoftifySurfaceStatus.warning =>
            colors.warning.withValues(alpha: 0.08),
          LoftifySurfaceStatus.error => colors.danger.withValues(alpha: 0.08),
          LoftifySurfaceStatus.normal ||
          LoftifySurfaceStatus.disabled =>
            switch (variant) {
              LoftifyCardVariant.muted => colors.surfaceMuted,
              LoftifyCardVariant.flat ||
              LoftifyCardVariant.outlined ||
              LoftifyCardVariant.raised =>
                colors.surface,
            },
        };
    final showBorder = highContrast ||
        variant == LoftifyCardVariant.outlined ||
        status != LoftifySurfaceStatus.normal;
    final borderColor =
        stateColor ?? (highContrast ? colors.outlineStrong : colors.outline);
    final effectiveRadius = radius ?? design.radii.card;

    return Semantics(
      button: interactive,
      enabled: enabled,
      selected: status == LoftifySurfaceStatus.selected,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled
            ? 1
            : highContrast
                ? 0.56
                : design.icons.disabledOpacity,
        child: AnimatedContainer(
          duration: design.motion.effective(context, design.motion.state),
          curve: design.motion.enterCurve,
          margin: margin,
          clipBehavior: clipBehavior,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(effectiveRadius),
            border: showBorder
                ? Border.all(
                    color: borderColor,
                    width: highContrast || stateColor != null
                        ? design.borders.focus
                        : design.borders.hairline,
                  )
                : null,
            boxShadow: variant == LoftifyCardVariant.raised
                ? design.shadows.floating
                : const <BoxShadow>[],
          ),
          child: interactive
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    onLongPress: onLongPress,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return colors.accent.withValues(
                          alpha: design.icons.pressedOpacity,
                        );
                      }
                      if (states.contains(WidgetState.focused)) {
                        return colors.accent.withValues(
                          alpha: design.icons.focusOpacity,
                        );
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return colors.accent.withValues(
                          alpha: design.icons.hoverOpacity,
                        );
                      }
                      return Colors.transparent;
                    }),
                    child: Padding(padding: padding, child: child),
                  ),
                )
              : Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

enum LoftifyMenuStatus { normal, success, warning, danger }

/// One menu row for both inline lists and bottom/desktop panels.
class LoftifyMenuItem extends StatelessWidget {
  const LoftifyMenuItem({
    super.key,
    required this.label,
    this.description,
    this.icon,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.showTrailing = true,
    this.status = LoftifyMenuStatus.normal,
    this.semanticLabel,
  });

  final String label;
  final String? description;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;
  final bool showTrailing;
  final LoftifyMenuStatus status;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final colors = design.colors;
    final highContrast = MediaQuery.highContrastOf(context);
    final effectiveEnabled = enabled && onTap != null;
    final statusColor = switch (status) {
      LoftifyMenuStatus.success => colors.success,
      LoftifyMenuStatus.warning => colors.warning,
      LoftifyMenuStatus.danger => colors.danger,
      LoftifyMenuStatus.normal =>
        selected ? colors.accentForeground : colors.textPrimary,
    };

    return Semantics(
      button: true,
      selected: selected,
      enabled: effectiveEnabled,
      label: semanticLabel,
      child: Opacity(
        opacity: effectiveEnabled
            ? 1
            : highContrast
                ? 0.56
                : design.icons.disabledOpacity,
        child: AnimatedContainer(
          duration: design.motion.effective(context, design.motion.state),
          curve: design.motion.enterCurve,
          constraints: BoxConstraints(
            minHeight: design.icons.minimumTapTarget,
          ),
          color: selected ? colors.accentContainer : Colors.transparent,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: effectiveEnabled ? onTap : null,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return colors.accent.withValues(
                    alpha: design.icons.pressedOpacity,
                  );
                }
                if (states.contains(WidgetState.focused)) {
                  return colors.accent.withValues(
                    alpha: design.icons.focusOpacity,
                  );
                }
                if (states.contains(WidgetState.hovered)) {
                  return colors.accent.withValues(
                    alpha: design.icons.hoverOpacity,
                  );
                }
                return Colors.transparent;
              }),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: design.spacing.xl,
                  vertical: design.spacing.lg,
                ),
                child: Row(
                  crossAxisAlignment: description?.isNotEmpty == true
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(
                            design.radii.control,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          size: design.icons.small,
                          color: statusColor,
                        ),
                      ),
                      SizedBox(width: design.spacing.lg),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: design.typography.body.copyWith(
                              color: status == LoftifyMenuStatus.normal &&
                                      !selected
                                  ? colors.textPrimary
                                  : statusColor,
                            ),
                          ),
                          if (description?.isNotEmpty == true) ...[
                            SizedBox(height: design.spacing.xs),
                            Text(
                              description!,
                              style: design.typography.metadata.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null || selected || showTrailing) ...[
                      SizedBox(width: design.spacing.lg),
                      trailing ??
                          Icon(
                            selected ? LoftifyIcons.check : LoftifyIcons.next,
                            size: design.icons.small,
                            color: selected
                                ? colors.accentForeground
                                : colors.textMuted,
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared bottom/desktop panel shell with one handle, header, divider and
/// responsive corner policy.
class LoftifyPanel extends StatelessWidget {
  const LoftifyPanel({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.footer,
    this.bodyPadding,
    this.footerPadding,
    this.showHandle = true,
    this.expandBody = false,
    this.semanticLabel,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;
  final EdgeInsetsGeometry? bodyPadding;
  final EdgeInsetsGeometry? footerPadding;
  final bool showHandle;
  final bool expandBody;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final width = MediaQuery.sizeOf(context).width;
    final wide =
        design.grid.windowClassFor(width) != LoftifyWindowClass.compact;
    final borderRadius = BorderRadius.vertical(
      top: Radius.circular(design.radii.panel),
      bottom: wide ? Radius.circular(design.radii.panel) : Radius.zero,
    );
    final bodyWidget = bodyPadding == null
        ? body
        : Padding(padding: bodyPadding!, child: body);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel ?? title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: wide ? design.shadows.overlay : const <BoxShadow>[],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: design.colors.surfaceRaised,
              borderRadius: borderRadius,
              border: Border.all(
                color: design.colors.outline,
                width: design.borders.hairline,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHandle && !wide) _buildHandle(context),
                if (title != null ||
                    subtitle != null ||
                    leading != null ||
                    trailing != null)
                  _buildHeader(context),
                if (title != null ||
                    subtitle != null ||
                    leading != null ||
                    trailing != null)
                  _divider(context),
                if (expandBody) Flexible(child: bodyWidget) else bodyWidget,
                if (footer != null) ...[
                  _divider(context),
                  Padding(
                    padding: footerPadding ??
                        EdgeInsets.symmetric(
                          horizontal: design.spacing.xxl,
                          vertical: design.spacing.xl,
                        ),
                    child: footer!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    final design = context.design;
    return SizedBox(
      height: design.spacing.xxxl,
      child: Center(
        child: Container(
          key: const ValueKey('loftify-panel-handle'),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: design.colors.outlineStrong,
            borderRadius: BorderRadius.circular(design.radii.full),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final design = context.design;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: design.density.minimumHeight(
          LoftifyDensityRole.contentComfortable,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: design.spacing.xl,
          vertical: design.spacing.lg,
        ),
        child: Row(
          crossAxisAlignment: subtitle?.isNotEmpty == true
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: design.spacing.lg),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!, style: design.typography.pageTitle),
                  if (subtitle?.isNotEmpty == true) ...[
                    SizedBox(height: design.spacing.xs),
                    Text(
                      subtitle!,
                      style: design.typography.metadata.copyWith(
                        color: design.colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: design.spacing.lg),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final design = context.design;
    return Divider(
      height: design.borders.hairline,
      thickness: design.borders.hairline,
      color: design.colors.outline,
    );
  }
}
