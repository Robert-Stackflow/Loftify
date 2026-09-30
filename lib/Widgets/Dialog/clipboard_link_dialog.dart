import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../generated/app_localizations.dart';

/// Content only: the shared confirmation dialog owns its surface and route.
class ClipboardLinkDialog extends StatelessWidget {
  const ClipboardLinkDialog({super.key, required this.url});

  final String url;

  static Future<bool> show(BuildContext context, String url) async {
    final strings = AppLocalizations.of(context)!;
    var accepted = false;
    await DialogBuilder.showConfirmDialog(
      context,
      messageChild: ClipboardLinkDialog(url: url),
      confirmButtonText: strings.clipboardLinkOpen,
      cancelButtonText: strings.clipboardLinkDismiss,
      onTapConfirm: () => accepted = true,
    );
    return accepted;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.design.colors;
    final strings = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: colors.accentContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(LucideIcons.link, size: 22, color: colors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(strings.clipboardLinkTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(strings.clipboardLinkMessage,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.textSecondary, height: 1.5)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.globe, size: 15, color: colors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(uri?.host ?? 'LOFTER',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium)),
                ],
              ),
              const SizedBox(height: 6),
              Text(url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.textMuted, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
