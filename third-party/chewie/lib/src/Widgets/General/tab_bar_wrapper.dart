import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

class TabBarWrapper extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final List<Widget> tabs;
  final double height;
  final EdgeInsetsGeometry containerPadding;
  final EdgeInsetsGeometry tabBarPadding;
  final EdgeInsetsGeometry labelPadding;
  final ValueChanged<int>? onTap;
  final bool showBorder;
  final Color? background;
  final double? width;
  final bool? isScrollable;

  const TabBarWrapper({
    super.key,
    required this.tabController,
    required this.tabs,
    this.height = 56,
    this.containerPadding = const EdgeInsets.symmetric(vertical: 4),
    this.tabBarPadding = const EdgeInsets.symmetric(horizontal: 10),
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 10),
    this.onTap,
    this.showBorder = false,
    this.background,
    this.width,
    this.isScrollable,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final scrollable = isScrollable ??
        tabs.length > 3 ||
            textScaler.scale(theme.textTheme.titleMedium?.fontSize ?? 14) > 18;
    final titleMedium = theme.textTheme.titleMedium ?? ChewieTheme.titleMedium;
    final selectedColor = titleMedium.color ?? theme.colorScheme.onSurface;
    final unselectedColor = theme.colorScheme.onSurfaceVariant;
    final primaryColor = theme.colorScheme.primary;

    return SizedBox(
      height: height,
      width: width,
      child: Material(
        color: background ?? theme.scaffoldBackgroundColor,
        child: Container(
          padding: containerPadding,
          child: TabBar(
            controller: tabController,
            tabs: tabs,
            labelPadding: labelPadding,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            padding: tabBarPadding,
            isScrollable: scrollable,
            tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
            physics: const BouncingScrollPhysics(),
            enableFeedback: true,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelColor: selectedColor,
            unselectedLabelColor: unselectedColor,
            labelStyle: titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: selectedColor,
            ),
            unselectedLabelStyle: titleMedium.copyWith(
              fontWeight: FontWeight.w400,
              color: unselectedColor,
            ),
            indicator: UnderlinedTabIndicator(
              borderColor: primaryColor,
              indicatorBottom: 4,
              indicatorWidth: 12,
              borderWidth: 3,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
