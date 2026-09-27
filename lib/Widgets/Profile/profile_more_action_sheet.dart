import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';

/// Compact, scrollable profile actions. The caller owns navigation and the
/// original action callbacks so opening this sheet never changes their meaning.
class LoftifyProfileMoreActionSheet extends StatelessWidget {
  const LoftifyProfileMoreActionSheet({
    super.key,
    required this.privacyTitle,
    required this.cancelLabel,
    required this.actions,
    required this.privacyActions,
    required this.onSelected,
    required this.onCancel,
  });

  final String privacyTitle;
  final String cancelLabel;
  final List<FlutterContextMenuItem> actions;
  final List<FlutterContextMenuItem> privacyActions;
  final ValueChanged<FlutterContextMenuItem> onSelected;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final screen = MediaQuery.sizeOf(context);
    final radius = Radius.circular(design.radii.dialog + 4);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screen.height * 0.76),
      child: Material(
        color: design.colors.surfaceRaised,
        borderRadius: BorderRadius.vertical(top: radius),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 30,
              child: Center(
                child: DecoratedBox(
                  key: const ValueKey('profile-more-handle'),
                  decoration: BoxDecoration(
                    color: design.colors.outlineStrong.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(design.radii.full),
                  ),
                  child: const SizedBox(width: 32, height: 4),
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    design.spacing.lg,
                    design.spacing.sm,
                    design.spacing.lg,
                    design.spacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _actionGrid(context, actions),
                      if (privacyActions.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            design.spacing.sm,
                            design.spacing.sm,
                            design.spacing.sm,
                            design.spacing.md,
                          ),
                          child: Row(
                            children: [
                              Text(
                                privacyTitle,
                                style: design.typography.metadata.copyWith(
                                  color: design.colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: design.spacing.lg),
                              Expanded(
                                child: Divider(color: design.colors.outline),
                              ),
                            ],
                          ),
                        ),
                        _actionGrid(context, privacyActions),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: design.colors.outline,
                    width: design.borders.hairline,
                  ),
                ),
              ),
              child: InkWell(
                key: const ValueKey('profile-more-cancel'),
                splashFactory: NoSplash.splashFactory,
                onTap: onCancel,
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      cancelLabel,
                      style: design.typography.body.copyWith(
                        color: design.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionGrid(
    BuildContext context,
    List<FlutterContextMenuItem> entries,
  ) {
    final design = context.design;
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth < 336 ? 3 : 4;
      final gap = design.spacing.xs;
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final entry in entries)
            SizedBox(
              width: width,
              child: _ProfileActionTile(
                action: entry,
                onTap: () => onSelected(entry),
              ),
            ),
        ],
      );
    });
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({required this.action, required this.onTap});

  final FlutterContextMenuItem action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final danger = action.status == MenuItemStatus.error;
    final foreground =
        danger ? design.colors.danger : design.colors.textPrimary;
    return Semantics(
      button: true,
      label: action.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(design.radii.control),
        child: InkWell(
          key: ValueKey('profile-more-${action.label}'),
          borderRadius: BorderRadius.circular(design.radii.control),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return foreground.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.focused)) {
              return foreground.withValues(alpha: 0.1);
            }
            return Colors.transparent;
          }),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: design.spacing.xs,
              vertical: design.spacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: danger
                        ? design.colors.danger.withValues(alpha: 0.1)
                        : design.colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(design.radii.control),
                  ),
                  child: Icon(action.iconData, size: 22, color: foreground),
                ),
                SizedBox(height: design.spacing.xs),
                Text(
                  action.label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: design.typography.metadata.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
