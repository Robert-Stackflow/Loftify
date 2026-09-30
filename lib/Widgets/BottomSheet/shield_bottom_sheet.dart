import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../l10n/l10n.dart';
import '../Design/loftify_controls.dart';
import '../Design/loftify_surfaces.dart';
import '../loftify_icons.dart';

class ShieldBottomSheet extends StatefulWidget {
  const ShieldBottomSheet({
    super.key,
    required this.tags,
    this.onShieldTag,
    this.onShieldContent,
    this.onShieldUser,
  });

  final Function(String tag)? onShieldTag;
  final Function()? onShieldContent;
  final Function()? onShieldUser;
  final List<String> tags;

  @override
  ShieldBottomSheetState createState() => ShieldBottomSheetState();
}

class ShieldBottomSheetState extends State<ShieldBottomSheet> {
  late List<String> tags;

  @override
  void initState() {
    super.initState();
    tags = widget.tags;
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return LoftifyPanel(
      title: appLocalizations.reduceRecommend,
      compactHeader: true,
      body: _buildButtons(),
      footer: _buildFooter(),
      footerPadding: EdgeInsets.fromLTRB(
        design.spacing.xl,
        design.spacing.sm,
        design.spacing.xl,
        design.spacing.xl,
      ),
    );
  }

  Widget _buildButtons() {
    final design = context.design;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        design.spacing.xl,
        design.spacing.md,
        design.spacing.xl,
        design.spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tags.isNotEmpty)
            Wrap(
              spacing: design.spacing.sm,
              runSpacing: design.spacing.sm,
              children: [
                for (final tag in tags)
                  LoftifyTag(
                    label: tag,
                    leading: LoftifyIcons.hash,
                    showSelectedIcon: false,
                    onPressed: () => widget.onShieldTag?.call(tag),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final design = context.design;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ShieldActionRow(
          label: appLocalizations.uninterestedInContent,
          icon: LoftifyIcons.block,
          onPressed: widget.onShieldContent,
        ),
        SizedBox(height: design.spacing.sm),
        _ShieldActionRow(
          label: appLocalizations.uninterestedInUser,
          icon: LoftifyIcons.unfollow,
          destructive: true,
          onPressed: widget.onShieldUser,
        ),
      ],
    );
  }
}

class _ShieldActionRow extends StatelessWidget {
  const _ShieldActionRow({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final foreground =
        destructive ? design.colors.danger : design.colors.textPrimary;
    final background = destructive
        ? Color.alphaBlend(
            design.colors.danger.withValues(alpha: 0.06),
            design.colors.surfaceRaised,
          )
        : design.colors.surfaceMuted;
    final radius = BorderRadius.circular(design.radii.control);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: Material(
        color: background,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return foreground.withValues(alpha: design.icons.pressedOpacity);
            }
            if (states.contains(WidgetState.focused)) {
              return foreground.withValues(alpha: design.icons.focusOpacity);
            }
            return Colors.transparent;
          }),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: design.spacing.lg),
              child: Row(
                children: [
                  Icon(icon, size: design.icons.regular, color: foreground),
                  SizedBox(width: design.spacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: design.typography.label.copyWith(
                        color: foreground,
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
