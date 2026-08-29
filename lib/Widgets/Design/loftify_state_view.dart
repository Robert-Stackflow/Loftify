import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../Utils/lottie_files.dart';
import '../loftify_icons.dart';
import 'loftify_controls.dart';

enum LoftifyStateVisual { loading, empty, error, success, warning }

/// Unified low-noise feedback for page, card and panel states.
class LoftifyStateView extends StatelessWidget {
  const LoftifyStateView({
    super.key,
    required this.visual,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.indicatorSize = 30,
    this.showTitle = true,
    this.forceDark = false,
    this.background,
    this.padding,
    this.scrollWhenConstrained = true,
  });

  final LoftifyStateVisual visual;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final double indicatorSize;
  final bool showTitle;
  final bool forceDark;
  final Color? background;
  final EdgeInsetsGeometry? padding;
  final bool scrollWhenConstrained;

  static Widget fromChewie(
    BuildContext context,
    ChewieStateViewConfig config,
  ) {
    final visual = switch (config.type) {
      ChewieStateViewType.loading => LoftifyStateVisual.loading,
      ChewieStateViewType.empty => LoftifyStateVisual.empty,
      ChewieStateViewType.error => LoftifyStateVisual.error,
    };
    final view = LoftifyStateView(
      visual: visual,
      title: config.text,
      actionLabel: config.actionLabel ??
          (config.onAction != null ? chewieLocalizations.retry : null),
      onAction: config.onAction,
      icon: config.icon,
      indicatorSize: config.size,
      showTitle: config.showText,
      forceDark: config.forceDark,
      background: config.background,
      scrollWhenConstrained: config.type != ChewieStateViewType.empty,
      padding: config.type == ChewieStateViewType.empty
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
          : EdgeInsets.only(
              top: config.topPadding,
              bottom: config.bottomPadding,
            ),
    );
    if (config.type != ChewieStateViewType.empty) return view;
    return _LoftifyScrollableEmptyState(config: config, child: view);
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final colors = design.colors;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;
    final foreground = forceDark ? Colors.white : colors.textPrimary;
    final secondary = forceDark ? Colors.white70 : colors.textSecondary;
    final stateColor = switch (visual) {
      LoftifyStateVisual.loading => colors.accent,
      LoftifyStateVisual.empty => forceDark ? Colors.white70 : colors.textMuted,
      LoftifyStateVisual.error => colors.danger,
      LoftifyStateVisual.success => colors.success,
      LoftifyStateVisual.warning => colors.warning,
    };
    final semanticsLabel = [
      if (showTitle) title,
      if (message?.isNotEmpty == true) message,
    ].join(', ');
    final stateContent = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: padding ?? EdgeInsets.all(design.spacing.xxl),
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : design.motion.state,
          switchInCurve: design.motion.enterCurve,
          switchOutCurve: design.motion.exitCurve,
          child: Column(
            key: ValueKey(visual),
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: _buildVisual(context, stateColor)),
              if (showTitle) ...[
                SizedBox(height: design.spacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: design.typography.cardTitle.copyWith(
                    color: foreground,
                  ),
                ),
              ],
              if (message?.isNotEmpty == true) ...[
                SizedBox(height: design.spacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: design.typography.body.copyWith(
                    color: secondary,
                  ),
                ),
              ],
              if (onAction != null && actionLabel?.isNotEmpty == true) ...[
                SizedBox(height: design.spacing.xl),
                LoftifyButton(
                  label: actionLabel!,
                  icon: LoftifyIcons.retry,
                  variant: LoftifyButtonVariant.secondary,
                  size: LoftifyButtonSize.compact,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final stateBody = scrollWhenConstrained
        ? LayoutBuilder(
            builder: (context, constraints) {
              if (!constraints.hasBoundedHeight ||
                  !constraints.maxHeight.isFinite) {
                return Center(child: stateContent);
              }
              return SingleChildScrollView(
                key: const ValueKey('loftify-state-scroll-view'),
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(child: stateContent),
                ),
              );
            },
          )
        : Center(child: stateContent);

    return Semantics(
      container: true,
      liveRegion: visual != LoftifyStateVisual.empty,
      label: semanticsLabel,
      child: ColoredBox(
        color: background ?? Colors.transparent,
        child: stateBody,
      ),
    );
  }

  Widget _buildVisual(BuildContext context, Color stateColor) {
    final design = context.design;
    if (visual == LoftifyStateVisual.loading) {
      return SizedBox.square(
        dimension: indicatorSize,
        child: LottieFiles.buildLoadingAnimation(indicatorSize, forceDark),
      );
    }
    final effectiveIcon = icon ??
        switch (visual) {
          LoftifyStateVisual.empty => LoftifyIcons.empty,
          LoftifyStateVisual.error => LoftifyIcons.error,
          LoftifyStateVisual.success => LoftifyIcons.check,
          LoftifyStateVisual.warning => LoftifyIcons.warning,
          LoftifyStateVisual.loading => LoftifyIcons.info,
        };
    final visualSize =
        (indicatorSize + design.spacing.xxl).clamp(48.0, 64.0).toDouble();
    return Container(
      width: visualSize,
      height: visualSize,
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: forceDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(design.radii.control),
        border: Border.all(
          color: stateColor.withValues(alpha: 0.24),
          width: design.borders.hairline,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        effectiveIcon,
        size: indicatorSize.clamp(20.0, 32.0).toDouble(),
        color: stateColor,
      ),
    );
  }
}

class _LoftifyScrollableEmptyState extends StatelessWidget {
  const _LoftifyScrollableEmptyState({
    required this.config,
    required this.child,
  });

  final ChewieStateViewConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (config.shrinkWrap) {
      return ListView(
        physics: config.physics,
        shrinkWrap: true,
        controller: config.scrollController,
        padding: EdgeInsets.only(
          top: config.topPadding,
          bottom: config.bottomPadding,
        ),
        children: [child],
      );
    }
    return CustomScrollView(
      physics: config.physics,
      controller: config.scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            top: config.topPadding,
            bottom: config.bottomPadding,
          ),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            fillOverscroll: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
