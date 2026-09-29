import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../Utils/enums.dart';
import '../Item/item_builder.dart';
import '../loftify_icons.dart';

/// A supporter keeps the same quiet, full-width rhythm as the relationship
/// lists while giving the contribution score its own compact visual anchor.
class LoftifySupporterListItem extends StatelessWidget {
  const LoftifySupporterListItem({
    super.key,
    required this.blogId,
    required this.avatarUrl,
    required this.name,
    required this.blogName,
    required this.intro,
    required this.score,
    required this.onTap,
  });

  final int blogId;
  final String avatarUrl;
  final String name;
  final String blogName;
  final String? intro;
  final int score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final summary = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ItemBuilder.buildAvatar(
          context: context,
          size: 48,
          imageUrl: avatarUrl,
          tagPrefix: 'supporter-$blogId',
          showDetailMode: ShowDetailMode.not,
        ),
        SizedBox(width: design.spacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: design.typography.cardTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: design.spacing.xs),
              Text(
                'ID: $blogName',
                style: design.typography.metadata.copyWith(
                  color: design.colors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (intro?.trim().isNotEmpty == true) ...[
                SizedBox(height: design.spacing.xs),
                Text(
                  intro!.trim(),
                  style: design.typography.metadata.copyWith(
                    color: design.colors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
    final scoreBadge = DecoratedBox(
      decoration: BoxDecoration(
        color: design.colors.accentContainer,
        borderRadius: BorderRadius.circular(design.radii.full),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: design.spacing.md,
          vertical: design.spacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChewieIcon(
              LoftifyIcons.premium,
              size: 16,
              color: design.colors.accent,
            ),
            SizedBox(width: design.spacing.xs),
            Text(
              score.toString(),
              style: design.typography.metadata.copyWith(
                color: design.colors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final stacked = constraints.maxWidth < 320 ||
          (constraints.maxWidth < 520 && scale > 1.4);
      return Semantics(
        key: ValueKey('loftify-supporter-row-$blogId'),
        button: true,
        label: name,
        explicitChildNodes: true,
        child: Material(
          color: design.colors.page,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return design.colors.textPrimary.withValues(alpha: 0.045);
              }
              if (states.contains(WidgetState.focused)) {
                return design.colors.accent.withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.hovered)) {
                return design.colors.textPrimary.withValues(alpha: 0.025);
              }
              return Colors.transparent;
            }),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: design.spacing.lg,
                vertical: design.spacing.md,
              ),
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        summary,
                        SizedBox(height: design.spacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: scoreBadge,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: summary),
                        SizedBox(width: design.spacing.md),
                        scoreBadge,
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }
}
