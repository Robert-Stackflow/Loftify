import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../Design/loftify_surfaces.dart';
import '../loftify_icons.dart';

/// Responsive folder card shared by the favorite-folder management page.
///
/// A compact folder row; only large-text layouts move the actions below it.
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
        final stackedActions = constraints.maxWidth < 310 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.35;
        final actions = _buildActions(context);
        final summary = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(design.radii.control),
              child: SizedBox.square(
                dimension: 64,
                child: cover,
              ),
            ),
            SizedBox(width: design.spacing.lg),
            Expanded(child: _buildText(context)),
            if (!stackedActions) ...[
              SizedBox(width: design.spacing.xs),
              actions,
            ],
          ],
        );
        return LoftifyCard(
          variant: LoftifyCardVariant.outlined,
          padding: EdgeInsets.symmetric(
            horizontal: design.spacing.md,
            vertical: design.spacing.md,
          ),
          semanticLabel: title,
          onTap: onTap,
          child: stackedActions
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summary,
                    SizedBox(height: design.spacing.xs),
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
        SizedBox(height: design.spacing.xs),
        if (MediaQuery.textScalerOf(context).scale(1) > 1.35) ...[
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
          Text(
            postCountLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: design.typography.metadata.copyWith(
              color: design.colors.textSecondary,
            ),
          ),
        ] else
          Row(
            children: [
              Flexible(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: onCopyFolderId,
                  child: Text(
                    folderIdLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: design.typography.metadata.copyWith(
                      color: design.colors.textMuted,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: design.spacing.xs),
                child: Text('·',
                    style: design.typography.metadata.copyWith(
                      color: design.colors.textMuted,
                    )),
              ),
              Text(
                postCountLabel,
                maxLines: 1,
                style: design.typography.metadata.copyWith(
                  color: design.colors.textSecondary,
                ),
              ),
            ],
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
