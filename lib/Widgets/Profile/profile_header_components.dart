import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../Design/loftify_surfaces.dart';
import '../Design/loftify_content_frame.dart';
import '../loftify_icons.dart';

const _coverTextShadows = <Shadow>[
  Shadow(
    color: Color(0x99000000),
    blurRadius: 5,
    offset: Offset(0, 1),
  ),
];

const double loftifyProfileMaxContentWidth = loftifyPageMaxContentWidth;

/// Align wide tabs and every tab's viewport to the profile heading.
class LoftifyProfileContentFrame extends StatelessWidget {
  const LoftifyProfileContentFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LoftifyContentFrame(child: child);
  }
}

/// Wide profiles size to their contents instead of stretching a follow action
/// and four statistics across the entire desktop window.
class LoftifyWideProfileSummary extends StatelessWidget {
  const LoftifyWideProfileSummary({
    super.key,
    required this.identity,
    required this.statistics,
    required this.action,
  });

  final Widget identity;
  final Widget statistics;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
      final compactAction = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: action,
      );
      final inline = constraints.maxWidth >= 600 && !largeText;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          identity,
          const SizedBox(height: 16),
          if (inline)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: statistics),
                const SizedBox(width: 16),
                compactAction,
              ],
            )
          else ...[
            statistics,
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: compactAction),
          ],
        ],
      );
    });
  }
}

/// Content-width and reflow contract for the complete profile heading.
class LoftifyProfileHeaderLayout extends StatelessWidget {
  const LoftifyProfileHeaderLayout({
    super.key,
    required this.summary,
    this.showcase,
    this.maxContentWidth = loftifyProfileMaxContentWidth,
    this.stackShowcase = false,
  });

  final Widget summary;
  final Widget? showcase;
  final double maxContentWidth;
  final bool stackShowcase;

  static bool usesSideBySide(
    BuildContext context, {
    required bool hasShowcase,
  }) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return hasShowcase &&
        MediaQuery.sizeOf(context).width >= 820 &&
        scale <= 1.35;
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = !stackShowcase &&
                showcase != null &&
                constraints.maxWidth >= 820 &&
                MediaQuery.textScalerOf(context).scale(14) / 14 <= 1.35;
            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: KeyedSubtree(
                      key: const ValueKey('loftify-profile-summary'),
                      child: summary,
                    ),
                  ),
                  SizedBox(width: design.spacing.xl),
                  Expanded(
                    flex: 2,
                    child: KeyedSubtree(
                      key: const ValueKey('loftify-profile-showcase'),
                      child: showcase!,
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                KeyedSubtree(
                  key: const ValueKey('loftify-profile-summary'),
                  child: summary,
                ),
                if (showcase != null) ...[
                  SizedBox(height: design.spacing.lg),
                  KeyedSubtree(
                    key: const ValueKey('loftify-profile-showcase'),
                    child: showcase!,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Responsive identity block used over the author's cover image.
///
/// The block intentionally owns no fixed height. Long identifiers, localized
/// metadata and accessibility text scaling can grow without colliding with the
/// avatar or the trailing action.
class LoftifyProfileIdentity extends StatelessWidget {
  const LoftifyProfileIdentity({
    super.key,
    required this.avatar,
    required this.displayName,
    required this.idLabel,
    required this.metadata,
    this.onDisplayNameLongPress,
    this.onIdLongPress,
    this.descriptionLabel,
    this.onDescriptionPressed,
    this.trailing,
    this.foregroundColor = Colors.white,
  });

  final Widget avatar;
  final String displayName;
  final String idLabel;
  final String metadata;
  final VoidCallback? onDisplayNameLongPress;
  final VoidCallback? onIdLongPress;
  final String? descriptionLabel;
  final VoidCallback? onDescriptionPressed;
  final Widget? trailing;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context)
                .scale(design.typography.label.fontSize ?? 13) /
            (design.typography.label.fontSize ?? 13);
        final moveTrailingBelow =
            trailing != null && (constraints.maxWidth < 380 || scale > 1.35);
        final identity = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            avatar,
            SizedBox(width: design.spacing.lg),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onLongPress: onDisplayNameLongPress,
                    child: Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: design.typography.pageTitle.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                        shadows: _coverTextShadows,
                      ),
                    ),
                  ),
                  SizedBox(height: design.spacing.xs),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onLongPress: onIdLongPress,
                    child: Text(
                      idLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: design.typography.metadata.copyWith(
                        color: foregroundColor.withValues(alpha: 0.88),
                        shadows: _coverTextShadows,
                      ),
                    ),
                  ),
                  SizedBox(height: design.spacing.xs),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: design.spacing.sm,
                    runSpacing: design.spacing.xs,
                    children: [
                      Text(
                        metadata,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: design.typography.metadata.copyWith(
                          color: foregroundColor.withValues(alpha: 0.88),
                          shadows: _coverTextShadows,
                        ),
                      ),
                      if (descriptionLabel != null &&
                          onDescriptionPressed != null)
                        _DescriptionAction(
                          label: descriptionLabel!,
                          onPressed: onDescriptionPressed!,
                          foregroundColor: foregroundColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null && !moveTrailingBelow) ...[
              SizedBox(width: design.spacing.sm),
              trailing!,
            ],
          ],
        );

        return Semantics(
          label: '$displayName, $idLabel, $metadata',
          child: moveTrailingBelow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    SizedBox(height: design.spacing.sm),
                    Align(alignment: Alignment.centerRight, child: trailing),
                  ],
                )
              : identity,
        );
      },
    );
  }
}

class _DescriptionAction extends StatelessWidget {
  const _DescriptionAction({
    required this.label,
    required this.onPressed,
    required this.foregroundColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: foregroundColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(design.radii.full),
        child: InkWell(
          onTap: onPressed,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return foregroundColor.withValues(alpha: 0.12);
            }
            return Colors.transparent;
          }),
          borderRadius: BorderRadius.circular(design.radii.full),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: design.spacing.md,
              vertical: design.spacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: design.typography.metadata.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: design.spacing.xs),
                Icon(
                  LoftifyIcons.expand,
                  size: design.icons.small,
                  color: foregroundColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Translucent profile-header action that remains legible over arbitrary
/// cover artwork while keeping its state visually quieter than content.
class LoftifyProfileAction extends StatelessWidget {
  const LoftifyProfileAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool emphasized;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final emphasizedForeground = LoftifyTheme.readableForegroundColor(
      design.colors.accent,
      backgrounds: const [Colors.white],
      brightness: Brightness.light,
    );
    final dangerForeground = LoftifyTheme.readableForegroundColor(
      design.colors.danger,
      backgrounds: const [Colors.white],
      brightness: Brightness.light,
    );
    final background = danger || emphasized
        ? Colors.white.withValues(alpha: 0.94)
        : Colors.black.withValues(alpha: 0.22);
    final foreground = danger
        ? dangerForeground
        : emphasized
            ? emphasizedForeground
            : Colors.white;
    return LoftifyCard(
      key: const ValueKey('loftify-profile-action'),
      onTap: onPressed,
      backgroundColor: background,
      variant: danger ? LoftifyCardVariant.outlined : LoftifyCardVariant.flat,
      radius: design.radii.control,
      semanticLabel: label,
      padding: EdgeInsets.symmetric(
        horizontal: design.spacing.xl,
        vertical: design.spacing.md,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 48 - design.spacing.md * 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: design.icons.regular, color: foreground),
            SizedBox(width: design.spacing.md),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: design.typography.label.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
