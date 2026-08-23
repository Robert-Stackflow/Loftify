import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class AppBarWrapper extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final bool centerTitle;
  final IconData? leadingIcon;
  final Widget? leadingWidget;
  final Color? leadingColor;
  final VoidCallback? onLeadingTap;
  final Color? backgroundColor;
  final double leftSpacing;
  final double rightSpacing;
  final double titleLeftMargin;
  final double titleRightMargin;
  final List<Widget>? actions;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool primary;

  const AppBarWrapper({
    super.key,
    this.title,
    this.centerTitle = false,
    this.leadingIcon,
    this.leadingWidget,
    this.leadingColor,
    this.onLeadingTap,
    this.backgroundColor,
    this.leftSpacing = 8,
    this.rightSpacing = 8,
    this.titleLeftMargin = 5,
    this.titleRightMargin = 0,
    this.actions,
    this.systemOverlayStyle,
    this.primary = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    bool showLeading = (leadingIcon != null || leadingWidget != null);
    final effectiveBackgroundColor = backgroundColor ??
        Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;
    final effectiveSystemOverlayStyle = systemOverlayStyle ??
        systemUiOverlayStyleForColor(context, effectiveBackgroundColor);

    var finalTitleWidget = Container(
      margin: EdgeInsets.only(
        left: titleLeftMargin,
        right: titleRightMargin,
      ),
      child: title,
    );

    var finalLeadingWidget = Container(
      margin: EdgeInsets.only(left: leftSpacing),
      child: leadingWidget ??
          CircleIconButton(
            icon:
                Icon(leadingIcon, color: leadingColor ?? ChewieTheme.iconColor),
            onTap: onLeadingTap,
          ),
    );

    return MyAppBar(
      backgroundColor: effectiveBackgroundColor,
      elevation: 0,
      centerTitle: centerTitle,
      systemOverlayStyle: effectiveSystemOverlayStyle,
      primary: primary,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: showLeading ? 56.0 : 0.0,
      leading: showLeading ? finalLeadingWidget : null,
      title: centerTitle ? Center(child: finalTitleWidget) : finalTitleWidget,
      actions: [
        ...?actions,
        if (rightSpacing > 0) SizedBox(width: rightSpacing),
      ],
    );
  }

  static SystemUiOverlayStyle systemUiOverlayStyleForColor(
    BuildContext context,
    Color backgroundColor, {
    bool includeNavigationBar = false,
  }) {
    final opaqueBackground = Color.alphaBlend(
      backgroundColor,
      Theme.of(context).scaffoldBackgroundColor,
    );
    return systemUiOverlayStyleForBrightness(
      ThemeData.estimateBrightnessForColor(opaqueBackground),
      includeNavigationBar: includeNavigationBar,
    );
  }

  static SystemUiOverlayStyle systemUiOverlayStyleForBrightness(
    Brightness backgroundBrightness, {
    bool includeNavigationBar = false,
  }) {
    final preset = backgroundBrightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: preset.statusBarBrightness,
      statusBarIconBrightness: preset.statusBarIconBrightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor:
          includeNavigationBar ? Colors.transparent : null,
      systemNavigationBarDividerColor:
          includeNavigationBar ? Colors.transparent : null,
      systemNavigationBarIconBrightness:
          includeNavigationBar ? preset.statusBarIconBrightness : null,
      systemNavigationBarContrastEnforced: includeNavigationBar ? false : null,
    );
  }

  static PreferredSizeWidget simple({
    String title = "",
    Key? key,
    IconData leadingIcon = Icons.arrow_back_rounded,
    List<Widget>? actions,
    required BuildContext context,
    bool transparent = false,
    double leftSpacing = 10,
    double? titleSpacing,
    double titleLeftMargin = 10,
    double titleRightMargin = 0,
    bool centerTitle = false,
    bool showLeading = true,
  }) {
    return AppBarWrapper(
      key: key,
      title: Text(
        title,
        style: ChewieTheme.titleMedium.apply(fontWeightDelta: 2),
      ),
      leadingIcon: showLeading ? leadingIcon : null,
      onLeadingTap: () {
        Navigator.pop(context);
      },
      actions: actions,
      backgroundColor: transparent ? ChewieTheme.background : null,
      leftSpacing: leftSpacing,
      titleLeftMargin: titleLeftMargin,
      titleRightMargin: titleRightMargin,
      centerTitle: centerTitle,
    );
  }
}
