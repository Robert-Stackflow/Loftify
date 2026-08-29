import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../Design/loftify_surfaces.dart';
import '../loftify_icons.dart';

/// Responsive folder card shared by the favorite-folder management page.
///
/// It keeps the cover prominent while allowing localized metadata to grow.
/// On narrow or large-text layouts the actions move below the summary rather
/// than squeezing the title into an unusable column.
class LoftifyFavoriteFolderCard extends StatelessWidget {
  const LoftifyFavoriteFolderCard({
    super.key,
    required this.title,
    required this.folderIdLabel,
    required this.postCountLabel,
    required this.cover,
    required this.onTap,
    required this.onEdit,
    this.onDelete,
    this.onCopyTitle,
    this.onCopyFolderId,
    this.editLabel,
    this.deleteLabel,
  });

  final String title;
  final String folderIdLabel;
  final String postCountLabel;
  final Widget cover;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopyTitle;
  final VoidCallback? onCopyFolderId;
  final String? editLabel;
  final String? deleteLabel;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.35;
        final actions = _buildActions(context);
        final summary = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(design.radii.control),
              child: SizedBox.square(
                dimension: compact ? 72 : 80,
                child: cover,
              ),
            ),
            SizedBox(width: design.spacing.lg),
            Expanded(child: _buildText(context)),
            if (!compact) ...[
              SizedBox(width: design.spacing.md),
              actions,
            ],
          ],
        );
        return LoftifyCard(
          variant: LoftifyCardVariant.outlined,
          padding: EdgeInsets.all(design.spacing.lg),
          semanticLabel: title,
          onTap: onTap,
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summary,
                    SizedBox(height: design.spacing.md),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                )
              : summary,
        );
      },
    );
  }

  Widget _buildText(BuildContext context) {
    final design = context.design;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onCopyTitle,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: design.typography.cardTitle.copyWith(
              color: design.colors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: design.spacing.md),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onCopyFolderId,
          child: Text(
            folderIdLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: design.typography.metadata.copyWith(
              color: design.colors.textMuted,
            ),
          ),
        ),
        SizedBox(height: design.spacing.xs),
        Text(
          postCountLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: design.typography.metadata.copyWith(
            color: design.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChewieIconButton(
          icon: LoftifyIcons.edit,
          tooltip: editLabel,
          onPressed: onEdit,
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 4),
          ChewieIconButton(
            icon: LoftifyIcons.delete,
            tooltip: deleteLabel,
            foregroundColor: context.design.colors.danger,
            onPressed: onDelete,
          ),
        ],
      ],
    );
  }
}
