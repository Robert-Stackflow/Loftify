import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class EmptyPlaceholder extends StatelessWidget {
  final String text;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? scrollController;
  final Function()? onTap;
  final double size;
  final double topPadding;
  final double bottomPadding;
  final IconData? icon;

  const EmptyPlaceholder({
    super.key,
    required this.text,
    this.icon,
    this.physics,
    this.shrinkWrap = true,
    this.scrollController,
    this.onTap,
    this.size = 30,
    this.topPadding = 50,
    this.bottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final stateBuilder = chewieProvider.stateWidgetBuilder;
    if (stateBuilder != null) {
      return stateBuilder(
        context,
        ChewieStateViewConfig(
          type: ChewieStateViewType.empty,
          text: text,
          onAction: onTap,
          icon: icon,
          size: size,
          physics: physics,
          shrinkWrap: shrinkWrap,
          scrollController: scrollController,
          topPadding: topPadding,
          bottomPadding: bottomPadding,
        ),
      );
    }
    return ListView(
      physics: physics,
      shrinkWrap: shrinkWrap,
      controller: scrollController,
      children: [
        SizedBox(height: topPadding),
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Icon(
              icon ?? LucideIcons.inbox,
              size: size,
              color: ChewieTheme.labelLarge.color,
            ),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: ChewieTheme.labelLarge,
            ),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton(
                  onPressed: onTap,
                  child: Text(chewieLocalizations.retry),
                ),
              ),
          ],
        ),
        SizedBox(height: bottomPadding),
      ],
    );
  }
}

/// Empty state for a [CustomScrollView] that keeps a single scroll chain.
///
/// [EmptyPlaceholder] is backed by a [ListView], so placing it directly in a
/// non-scrolling [SliverFillRemaining] asks a viewport for intrinsic dimensions
/// and can break the complete sliver layout. This wrapper gives it a finite
/// viewport and disables the inner gesture handler.
class SliverEmptyPlaceholder extends StatelessWidget {
  final String text;
  final double height;
  final double topPadding;
  final double size;
  final IconData? icon;

  const SliverEmptyPlaceholder({
    super.key,
    required this.text,
    this.height = 220,
    this.topPadding = 64,
    this.size = 30,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: height,
        child: EmptyPlaceholder(
          text: text,
          icon: icon,
          size: size,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: false,
          topPadding: topPadding,
        ),
      ),
    );
  }
}
