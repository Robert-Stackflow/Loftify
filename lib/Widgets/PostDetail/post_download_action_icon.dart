import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../loftify_icons.dart';

/// Compact, determinate download feedback for a post AppBar action.
///
/// Loading intentionally uses a progress ring instead of the application's
/// generic Lottie loading animation: this state represents transferred bytes,
/// not an indeterminate page load.
class PostDownloadActionIcon extends StatelessWidget {
  const PostDownloadActionIcon({
    super.key,
    required this.state,
    required this.semanticLabel,
    this.progress = 0,
  });

  static const double visualSize = 20;
  static const double iconSize = 18;
  static const double progressStrokeWidth = 2;

  final DownloadState state;
  final String semanticLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final semanticsValue = state == DownloadState.loading
        ? '${(normalizedProgress * 100).round()}%'
        : null;

    return Semantics(
      key: const ValueKey('post-download-semantics'),
      label: semanticLabel,
      value: semanticsValue,
      liveRegion:
          state == DownloadState.succeed || state == DownloadState.failed,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: visualSize,
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: switch (state) {
              DownloadState.none => ChewieIcon(
                  LoftifyIcons.download,
                  key: const ValueKey('post-download-idle'),
                  size: iconSize,
                  color: design.colors.textPrimary,
                ),
              DownloadState.loading => TweenAnimationBuilder<double>(
                  key: const ValueKey('post-download-progress'),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: normalizedProgress),
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: progressStrokeWidth,
                          strokeCap: StrokeCap.round,
                          color: design.colors.accentForeground,
                          backgroundColor: design.colors.outline.withValues(
                            alpha:
                                MediaQuery.highContrastOf(context) ? 0.72 : 0.4,
                          ),
                        ),
                        ChewieIcon(
                          LoftifyIcons.download,
                          size: 10,
                          color: design.colors.textPrimary,
                        ),
                      ],
                    );
                  },
                ),
              DownloadState.succeed => ChewieIcon(
                  LoftifyIcons.check,
                  key: const ValueKey('post-download-success'),
                  size: iconSize,
                  color: design.colors.success,
                ),
              DownloadState.failed => ChewieIcon(
                  LoftifyIcons.warning,
                  key: const ValueKey('post-download-failed'),
                  size: iconSize,
                  color: design.colors.danger,
                ),
            },
          ),
        ),
      ),
    );
  }
}
