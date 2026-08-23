import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SliverAppBarWrapper extends StatelessWidget {
  final BuildContext context;
  final Widget? backgroundWidget;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final Widget? title;
  final bool centerTitle;
  final double expandedHeight;
  final double titleLeftMargin;
  final double? collapsedHeight;
  final double leftSpacing;
  final double rightSpacing;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final VoidCallback? onBack;

  const SliverAppBarWrapper({
    super.key,
    required this.context,
    this.backgroundWidget,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.title,
    this.centerTitle = false,
    this.expandedHeight = 320,
    this.titleLeftMargin = 0,
    this.collapsedHeight,
    this.leftSpacing = 8,
    this.rightSpacing = 8,
    this.systemOverlayStyle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    bool showLeading = !ResponsiveUtil.isLandscapeLayout();
    final backgroundColor = Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;
    final effectiveSystemOverlayStyle = systemOverlayStyle ??
        (backgroundWidget != null
            ? AppBarWrapper.systemUiOverlayStyleForBrightness(Brightness.dark)
            : AppBarWrapper.systemUiOverlayStyleForColor(
                context,
                backgroundColor,
              ));
    final leadingColor = backgroundWidget != null
        ? Colors.white
        : Theme.of(context).iconTheme.color;
    var finalTitleWidget = Container(
      margin: EdgeInsets.only(left: titleLeftMargin),
      child: title,
    );
    var leading = Container(
      margin: EdgeInsets.only(left: leftSpacing),
      child: ChewieIconButton(
        icon: LucideIcons.arrowLeft,
        foregroundColor: leadingColor,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
    );

    return MySliverAppBar(
      systemOverlayStyle: effectiveSystemOverlayStyle,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight ??
          max(100, kToolbarHeight + MediaQuery.of(context).padding.top),
      pinned: true,
      leadingWidth: showLeading ? 56 : 0,
      leading: showLeading ? leading : null,
      automaticallyImplyLeading: false,
      backgroundWidget: backgroundWidget,
      title: centerTitle ? Center(child: finalTitleWidget) : finalTitleWidget,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      actions: [
        if (actions != null) ...?actions,
        SizedBox(width: rightSpacing),
      ],
    );
  }
}
