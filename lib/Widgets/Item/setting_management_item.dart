import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

class SettingManagementItem extends StatelessWidget {
  const SettingManagementItem({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.description = '',
    this.leading,
    this.leadingIcon,
    this.onTap,
  });

  final String title;
  final String description;
  final Widget? leading;
  final IconData? leadingIcon;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return EntryItem(
      title: title,
      description: description,
      crossAxisAlignment: CrossAxisAlignment.start,
      showLeading: leading != null || leadingIcon != null,
      leadingWidget: leading,
      leading: leadingIcon ?? Icons.settings_rounded,
      showTrailing: false,
      onTap: onTap,
      tipWidget: RoundIconTextButton(
        text: actionLabel,
        height: 32,
        minHeight: 32,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        background: primary.withAlpha(22),
        color: primary,
        border: Border.all(color: primary.withAlpha(72)),
        onPressed: onAction,
      ),
    );
  }
}
