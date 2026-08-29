import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import 'loftify_controls.dart';

/// A regular Loftify action button with real transfer progress at its edge.
///
/// This intentionally uses a determinate progress track rather than the app's
/// Lottie loading language: downloads represent measurable byte transfer, not
/// an indeterminate page state.
class LoftifyDownloadProgressButton extends StatelessWidget {
  const LoftifyDownloadProgressButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.progress,
    this.variant = LoftifyButtonVariant.secondary,
    this.expand = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double? progress;
  final LoftifyButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final normalized = progress?.clamp(0.0, 1.0).toDouble();
    final percent = normalized == null ? null : (normalized * 100).round();
    final semanticValue = percent == null ? null : '$percent%';
    return Semantics(
      button: true,
      liveRegion: normalized != null,
      label: label,
      value: semanticValue,
      enabled: normalized == null && onPressed != null,
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            LoftifyButton(
              label: percent == null ? label : '$label $percent%',
              icon: icon,
              variant: variant,
              expand: expand,
              onPressed: normalized == null ? onPressed : null,
            ),
            if (normalized != null)
              Positioned(
                left: design.spacing.sm,
                right: design.spacing.sm,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(design.radii.full),
                  child: LinearProgressIndicator(
                    key: const ValueKey('loftify-download-progress-track'),
                    value: normalized,
                    minHeight: 3,
                    color: design.colors.accentForeground,
                    backgroundColor: design.colors.outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
