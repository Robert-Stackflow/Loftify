import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

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
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: ChewieTheme.canvasColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.65),
              width: 0.6,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: previewHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary.withValues(alpha: 0.12),
                            colors.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                    Padding(padding: previewPadding, child: preview),
                    if (badge?.isNotEmpty == true)
                      PositionedDirectional(
                        start: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  colors.outlineVariant.withValues(alpha: 0.65),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            badge!,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.25,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.11),
                          shape: BoxShape.circle,
                        ),
                        child: ChewieIcon(
                          LoftifyIcons.next,
                          size: 17,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: footer!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
