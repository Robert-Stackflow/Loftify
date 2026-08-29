import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../Design/loftify_controls.dart';
import '../Design/loftify_surfaces.dart';
import '../loftify_icons.dart';

@immutable
class LoftifyTagMetric {
  const LoftifyTagMetric(this.label, {this.emphasized = false});

  final String label;
  final bool emphasized;
}

/// Content-first tag heading shared by the tag-detail page across phone and
/// wide layouts. It deliberately avoids a full card background so the tag and
/// its works remain the visual focus.
class LoftifyTagHero extends StatelessWidget {
  const LoftifyTagHero({
    super.key,
    required this.tag,
    required this.metrics,
    required this.subscribed,
    required this.subscribeLabel,
    required this.subscribedLabel,
    required this.onSubscriptionPressed,
    this.trailing = const <Widget>[],
  });

  final String tag;
  final List<LoftifyTagMetric> metrics;
  final bool subscribed;
  final String subscribeLabel;
  final String subscribedLabel;
  final VoidCallback onSubscriptionPressed;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return Padding(
      key: const ValueKey('loftify-tag-hero'),
      padding: EdgeInsets.only(
        top: design.spacing.sectionTop,
        bottom: design.spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context)
                      .scale(design.typography.label.fontSize ?? 13) /
                  (design.typography.label.fontSize ?? 13);
              final stackActions = constraints.maxWidth < 360 ||
                  textScale > 1.3 ||
                  trailing.length > 1;
              if (stackActions) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTitle(context),
                    SizedBox(height: design.spacing.md),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: design.spacing.sm,
                      runSpacing: design.spacing.sm,
                      children: [_buildSubscriptionButton(), ...trailing],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildTitle(context)),
                  SizedBox(width: design.spacing.lg),
                  _buildSubscriptionButton(),
                  if (trailing.isNotEmpty) ...[
                    SizedBox(width: design.spacing.sm),
                    ...trailing,
                  ],
                ],
              );
            },
          ),
          if (metrics.isNotEmpty) ...[
            SizedBox(height: design.spacing.lg),
            Wrap(
              spacing: design.spacing.md,
              runSpacing: design.spacing.sm,
              children: [
                for (final metric in metrics) _TagMetricChip(metric: metric),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final design = context.design;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: design.colors.accentContainer,
            borderRadius: BorderRadius.circular(design.radii.control),
          ),
          alignment: Alignment.center,
          child: Icon(
            LoftifyIcons.tag,
            size: design.icons.regular,
            color: design.colors.onAccentContainer,
          ),
        ),
        SizedBox(width: design.spacing.lg),
        Expanded(
          child: Text(
            tag,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: design.typography.pageTitle,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionButton() {
    return LoftifyButton(
      label: subscribed ? subscribedLabel : subscribeLabel,
      variant: subscribed
          ? LoftifyButtonVariant.secondary
          : LoftifyButtonVariant.tonal,
      size: LoftifyButtonSize.compact,
      onPressed: onSubscriptionPressed,
    );
  }
}

class _TagMetricChip extends StatelessWidget {
  const _TagMetricChip({required this.metric});

  final LoftifyTagMetric metric;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final foreground = metric.emphasized
        ? design.colors.onAccentContainer
        : design.colors.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: metric.emphasized
            ? design.colors.accentContainer
            : design.colors.surface,
        borderRadius: BorderRadius.circular(design.radii.full),
        border: Border.all(
          color: metric.emphasized
              ? design.colors.accent.withValues(alpha: 0.35)
              : design.colors.outline,
          width: design.borders.hairline,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: design.spacing.lg,
          vertical: design.spacing.sm,
        ),
        child: Text(
          metric.label,
          style: design.typography.metadata.copyWith(color: foreground),
        ),
      ),
    );
  }
}

/// A compact discovery entrance for collections, related tags and dress.
/// The supplied illustration remains decorative and never competes with text.
class LoftifyTagDiscoveryCard extends StatelessWidget {
  const LoftifyTagDiscoveryCard({
    super.key,
    required this.title,
    required this.description,
    required this.illustration,
    required this.onTap,
  });

  final String title;
  final String description;
  final Widget illustration;
  final VoidCallback onTap;

  static const double illustrationAspectRatio = 170 / 65;
  static const double minimumHeight = 70;
  static const double maximumTextScale = 1.5;

  static double preferredHeight(BuildContext context) {
    final design = context.design;
    final scaler = MediaQuery.textScalerOf(context);
    final metadataSize = design.typography.metadata.fontSize ?? 12;
    final cardTitleSize = design.typography.cardTitle.fontSize ?? 15;
    final scale = math.min(
      maximumTextScale,
      scaler.scale(metadataSize) / metadataSize,
    );
    final titleHeight =
        metadataSize * scale * (design.typography.metadata.height ?? 1);
    final descriptionHeight =
        cardTitleSize * scale * (design.typography.cardTitle.height ?? 1);
    return math.max(
      minimumHeight,
      design.spacing.md * 2 +
          titleHeight +
          design.spacing.xs +
          descriptionHeight +
          2,
    );
  }

  static double preferredWidth(BuildContext context) =>
      preferredHeight(context) * illustrationAspectRatio;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final height = preferredHeight(context);
    return SizedBox(
      key: ValueKey('loftify-tag-discovery-card-$title'),
      width: preferredWidth(context),
      height: height,
      child: LoftifyCard(
        variant: LoftifyCardVariant.flat,
        backgroundColor: Colors.transparent,
        radius: design.radii.control,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            illustration,
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: design.spacing.lg,
                vertical: design.spacing.md,
              ),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: maximumTextScale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: design.typography.metadata.copyWith(
                        color: design.colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: design.spacing.xs),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: design.typography.cardTitle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
