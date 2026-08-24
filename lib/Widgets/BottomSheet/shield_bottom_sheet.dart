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
    return LoftifyPanel(
      title: appLocalizations.reduceRecommend,
      body: _buildButtons(),
      footer: _buildFooter(),
    );
  }

  Widget _buildButtons() {
    final design = context.design;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: design.spacing.xl,
        vertical: design.spacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: design.spacing.md,
            runSpacing: design.spacing.sm,
            children: [
              for (final tag in tags)
                LoftifyTag(
                  label: tag,
                  leading: LoftifyIcons.tag,
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
        LoftifyButton(
          label: appLocalizations.uninterestedInContent,
          icon: LoftifyIcons.block,
          variant: LoftifyButtonVariant.secondary,
          onPressed: widget.onShieldContent,
          expand: true,
        ),
        SizedBox(height: design.spacing.md),
        LoftifyButton(
          label: appLocalizations.uninterestedInUser,
          icon: LoftifyIcons.unfollow,
          variant: LoftifyButtonVariant.danger,
          onPressed: widget.onShieldUser,
          expand: true,
        ),
      ],
    );
  }
}
