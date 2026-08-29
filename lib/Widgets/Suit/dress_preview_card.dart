import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../Design/loftify_surfaces.dart';
import '../loftify_icons.dart';

class DressPreviewCard extends StatelessWidget {
  const DressPreviewCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.preview,
    this.onTap,
    this.badge,
    this.previewHeight = 210,
    this.previewPadding = const EdgeInsets.all(16),
    this.footer,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final Widget preview;
  final VoidCallback? onTap;
  final double previewHeight;
  final EdgeInsets previewPadding;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return LoftifyCard(
      variant: LoftifyCardVariant.outlined,
      onTap: onTap,
      semanticLabel: '$title, $subtitle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: previewHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: design.colors.surfaceMuted),
                Padding(padding: previewPadding, child: preview),
                if (badge?.isNotEmpty == true)
                  PositionedDirectional(
                    start: design.spacing.lg,
                    top: design.spacing.lg,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: design.spacing.lg,
                        vertical: design.spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: design.colors.surfaceRaised,
                        borderRadius: BorderRadius.circular(
                          design.radii.control,
                        ),
                        border: Border.all(
                          color: design.colors.outline,
                          width: design.borders.hairline,
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: design.typography.metadata,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              design.spacing.xl,
              design.spacing.xl,
              design.spacing.lg,
              design.spacing.xl,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: design.typography.cardTitle,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        SizedBox(height: design.spacing.sm),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: design.typography.metadata.copyWith(
                            color: design.colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  SizedBox(width: design.spacing.lg),
                  Icon(
                    LoftifyIcons.next,
                    size: design.icons.small,
                    color: design.colors.accentForeground,
                  ),
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                design.spacing.xl,
                0,
                design.spacing.xl,
                design.spacing.xl,
              ),
              child: footer!,
            ),
        ],
      ),
    );
  }
}
