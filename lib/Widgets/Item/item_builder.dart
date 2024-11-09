import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:group_button/group_button.dart';
import 'package:loftify/Resources/theme_color_data.dart';
import 'package:loftify/Utils/lottie_util.dart';
import 'package:loftify/Widgets/Selectable/my_context_menu_item.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../Models/illust.dart';
import '../../Resources/colors.dart';
import '../../Resources/fonts.dart';
import '../../Resources/theme.dart';
import '../../Screens/Post/search_result_screen.dart';
import '../../Screens/Post/tag_detail_screen.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/constant.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';
import '../Custom/custom_tab_indicator.dart';
import '../Custom/hero_photo_view_screen.dart';
import '../Scaffold/my_appbar.dart';
import '../Selectable/my_selection_area.dart';
import '../Selectable/my_selection_toolbar.dart';
import '../Selectable/selection_transformer.dart';
import '../Window/window_button.dart';
import '../Window/window_caption.dart';
import 'my_cached_network_image.dart';

enum TailingType { none, clear, password, icon, text, widget }

class ItemBuilder {
  static PreferredSize buildPreferredSize(
      {double height = kToolbarHeight, required Widget child}) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: child,
    );
  }

  static PreferredSize buildResponsiveAppBar({
    required BuildContext context,
    String title = "",
    Widget? titleWidget,
    bool showBack = false,
    Function()? onTapBack,
    double spacing = 10,
    bool? showBorder,
    Widget? bottomWidget,
    double? bottomHeight,
    bool transparent = true,
    Color? background,
    double? titleSpacing,
    bool centerInMobile = false,
    List<Widget> actions = const [],
  }) {
    late PreferredSize topWidget;
    if (ResponsiveUtil.isLandscape()) {
      var finalTitle = titleWidget ??
          Text(title, style: Theme.of(context).textTheme.titleLarge);
      topWidget = buildPreferredSize(
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: MyTheme.canvasColor,
            border: showBorder ?? true ? MyTheme.bottomBorder : null,
          ),
          child: Stack(
            children: [
              ResponsiveUtil.buildDesktopWidget(
                  desktop: const WindowMoveHandle()),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (showBack)
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: ToolButton(
                          context: context,
                          onTap: onTapBack ?? () => panelScreenState?.popPage(),
                          iconBuilder: (_) =>
                              const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    if (showBack || titleWidget == null)
                      SizedBox(width: spacing),
                    finalTitle,
                    ResponsiveUtil.buildDesktopWidget(
                        desktop: const SizedBox(width: 173)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      topWidget = buildPreferredSize(
        child: Container(
          decoration: BoxDecoration(
            border: showBorder ?? false ? MyTheme.bottomBorder : null,
          ),
          child: ItemBuilder.buildAppBar(
            context: context,
            center: centerInMobile,
            leading: showBack ? Icons.arrow_back_rounded : null,
            onLeadingTap: onTapBack ?? () => panelScreenState?.popPage(),
            backgroundColor: background ??
                (transparent
                    ? MyTheme.getBackground(context)
                    : MyTheme.canvasColor),
            leftSpacing: showBack ? 8 : 0,
            leadingTitleSpacing: showBack ? 5 : 0,
            actions: actions,
            titleSpacing: titleSpacing,
            title: titleWidget != null
                ? Container(
                    constraints: const BoxConstraints(maxHeight: 60),
                    child: titleWidget,
                  )
                : Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontWeightDelta: 2,
                        ),
                  ),
          ),
        ),
      );
    }
    return bottomWidget != null && bottomHeight != null
        ? buildPreferredSize(
            height: 56 + bottomHeight,
            child: SafeArea(
              child: Column(
                children: [
                  topWidget,
                  bottomWidget,
                ],
              ),
            ),
          )
        : buildPreferredSize(
            child: SafeArea(child: topWidget),
          );
  }

  static buildTabBar(
    BuildContext context,
    TabController tabController,
    List<Widget> tabs, {
    double? height = 56,
    EdgeInsetsGeometry? padding,
    ValueChanged<int>? onTap,
    bool showBorder = false,
    Color? background,
    double? width,
    bool forceUnscrollable = false,
  }) {
    padding ??= ResponsiveUtil.isLandscape()
        ? const EdgeInsets.symmetric(horizontal: 0)
        : const EdgeInsets.symmetric(horizontal: 10);
    bool scrollable = false;
    if (ResponsiveUtil.isLandscape()) {
      scrollable = true;
    } else {
      if (tabs.length <= 1 || tabs.length > 3) {
        scrollable = true;
      } else {
        scrollable = false;
      }
    }
    scrollable = forceUnscrollable ? false : scrollable;
    return buildPreferredSize(
      height: height ?? 56,
      child: Container(
        height: 56,
        width: width,
        decoration: BoxDecoration(
          color: background,
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: ResponsiveUtil.isLandscape() ? 1 : 1),
                )
              : null,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: TabBar(
            controller: tabController,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: tabs,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            padding: padding,
            isScrollable: scrollable,
            tabAlignment: scrollable ? TabAlignment.start : null,
            physics: const BouncingScrollPhysics(),
            labelStyle: Theme.of(context).textTheme.titleLarge,
            unselectedLabelStyle: Theme.of(context)
                .textTheme
                .titleLarge
                ?.apply(color: Colors.grey),
            indicator:
                CustomTabIndicator(borderColor: Theme.of(context).primaryColor),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  static PreferredSizeWidget buildSimpleAppBar({
    String title = "",
    Key? key,
    IconData leading = Icons.arrow_back_rounded,
    List<Widget>? actions,
    required BuildContext context,
    bool transparent = false,
  }) {
    bool showLeading = !ResponsiveUtil.isLandscape();
    return MyAppBar(
      key: key,
      backgroundColor: transparent
          ? Theme.of(context).scaffoldBackgroundColor
          : Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: showLeading ? 56.0 : 0.0,
      automaticallyImplyLeading: false,
      leading: showLeading
          ? Container(
              margin: const EdgeInsets.only(left: 5),
              child: buildIconButton(
                context: context,
                icon: Icon(leading, color: Theme.of(context).iconTheme.color),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      title: title.isNotEmpty
          ? Container(
              margin: EdgeInsets.only(left: showLeading ? 5 : 20),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.apply(
                      fontWeightDelta: 2,
                    ),
              ),
            )
          : emptyWidget,
      actions: actions,
    );
  }

  static buildAppBar({
    Widget? title,
    Key? key,
    bool center = false,
    IconData? leading,
    Widget? leadingWidget,
    Color? leadingColor,
    Function()? onLeadingTap,
    Color? backgroundColor,
    List<Widget>? actions,
    required BuildContext context,
    bool transparent = false,
    double leftSpacing = 10,
    double leadingTitleSpacing = 10,
    double? titleSpacing,
    bool forceShowClose = false,
  }) {
    bool showLeading =
        leading != null && (!ResponsiveUtil.isLandscape() || forceShowClose);
    // center = ResponsiveUtil.isDesktop() ? false : center;
    return MyAppBar(
      key: key,
      primary: !ResponsiveUtil.isWideLandscape(),
      backgroundColor: transparent
          ? Colors.transparent
          : backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor!,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: showLeading ? 56.0 : 0.0,
      leading: showLeading
          ? Container(
              margin: EdgeInsets.only(left: leftSpacing),
              child: leadingWidget ??
                  ItemBuilder.buildIconButton(
                    context: context,
                    icon: Icon(leading,
                        color:
                            leadingColor ?? Theme.of(context).iconTheme.color),
                    onTap: onLeadingTap,
                  ),
            )
          : null,
      title: center
          ? Center(
              child: Container(
                  margin: EdgeInsets.only(
                      left: center
                          ? 0
                          : (showLeading
                              ? leadingTitleSpacing
                              : titleSpacing ?? 20)),
                  child: title))
          : Container(
              margin: EdgeInsets.only(
                  left: center
                      ? 0
                      : (showLeading
                          ? leadingTitleSpacing
                          : titleSpacing ?? 20)),
              child: title,
            ),
      actions: actions,
    );
  }

  static buildSliverAppBar({
    required BuildContext context,
    Widget? backgroundWidget,
    List<Widget>? actions,
    Widget? flexibleSpace,
    PreferredSizeWidget? bottom,
    Widget? title,
    bool center = false,
    double expandedHeight = 320,
    double? collapsedHeight,
    SystemUiOverlayStyle? systemOverlayStyle,
  }) {
    bool showLeading = !ResponsiveUtil.isLandscape();
    center = ResponsiveUtil.isLandscape() ? false : center;
    return MySliverAppBar(
      systemOverlayStyle: systemOverlayStyle,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight ??
          max(100, kToolbarHeight + MediaQuery.of(context).padding.top),
      pinned: true,
      leadingWidth: showLeading ? 56 : 0,
      leading: showLeading
          ? Container(
              margin: const EdgeInsets.only(left: 5),
              child: ItemBuilder.buildIconButton(
                context: context,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      automaticallyImplyLeading: false,
      backgroundWidget: backgroundWidget,
      actions: actions,
      title: showLeading
          ? center
              ? Center(child: title)
              : title ?? emptyWidget
          : center
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.only(left: 20),
                    child: title,
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: title,
                ),
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
    );
  }

  static buildInk({
    required Widget child,
    Function()? onTap,
    Function()? onLongPress,
    BorderRadius? borderRadius,
    Clip clipBehavior = Clip.none,
    ShapeBorder? shape,
    Color? color,
  }) {
    borderRadius ??= BorderRadius.circular(10);
    return Material(
      color: color,
      clipBehavior: clipBehavior,
      shape: shape,
      borderRadius: shape != null ? null : borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  static buildContextMenuOverlay(Widget child) {
    return ContextMenuOverlay(
      cardBuilder: (context, widgets) => Container(
        constraints: const BoxConstraints(minWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: MyTheme.defaultDecoration,
        child: Column(children: widgets),
      ),
      dividerBuilder: (context) => ItemBuilder.buildDivider(
        context,
        width: 1.5,
        vertical: 6,
        horizontal: 4,
      ),
      buttonBuilder: (context, config, [_]) {
        bool isCheckbox = config.type == ContextMenuButtonConfigType.checkbox;
        bool showCheck = isCheckbox && config.checked;
        Widget checkIcon = Row(
          children: [
            Opacity(
              opacity: showCheck ? 1 : 0,
              child: Icon(Icons.check_rounded,
                  size: ResponsiveUtil.isMobile() ? null : 16),
            ),
            SizedBox(width: showCheck ? 8 : 4),
          ],
        );
        return buildInk(
          onTap: config.onPressed,
          child: Container(
            padding: EdgeInsets.only(
                left: showCheck ? 8 : 12, right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                if (isCheckbox) checkIcon,
                if (config.icon != null)
                  Transform.scale(
                    scale: 0.83,
                    child: config.icon!,
                  ),
                if (config.icon != null) const SizedBox(width: 10),
                Text(
                  config.label,
                  style: Theme.of(context).textTheme.bodyMedium?.apply(
                        fontSizeDelta: ResponsiveUtil.isMobile() ? 2 : 0,
                        color: config.textColor,
                      ),
                ),
              ],
            ),
          ),
        );
      },
      child: child,
    );
  }

  static buildLoadMoreNotification({
    Function()? onLoad,
    required Widget child,
    required bool noMore,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth != 0) {
          return false;
        }
        if (!noMore &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - kLoadExtentOffset) {
          onLoad?.call();
        }
        return false;
      },
      child: child,
    );
  }

  static Widget buildBlankIconButton(BuildContext context) {
    return Visibility(
      visible: false,
      maintainAnimation: true,
      maintainState: true,
      maintainSize: true,
      child: ItemBuilder.buildIconButton(
          context: context,
          icon: Icon(Icons.more_vert_rounded,
              color: Theme.of(context).iconTheme.color),
          onTap: () {}),
    );
  }

  static Widget buildShadowIconButton({
    required BuildContext context,
    required dynamic icon,
    required Function()? onTap,
    Function()? onLongPress,
    double radius = 8,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.8),
        borderRadius: BorderRadius.circular(radius + 1),
        boxShadow: MyTheme.defaultBoxShadow,
      ),
      child: buildInk(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: padding ?? const EdgeInsets.all(10),
          child: icon ?? emptyWidget,
        ),
      ),
    );
  }

  static Widget buildIconButton({
    required BuildContext context,
    required dynamic icon,
    required Function()? onTap,
    Function()? onLongPress,
    EdgeInsets? padding,
  }) {
    return buildInk(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: padding ?? const EdgeInsets.all(8),
        child: icon ?? emptyWidget,
      ),
    );
  }

  static Widget buildRoundIconButton({
    required BuildContext context,
    required dynamic icon,
    required Function()? onTap,
    Function()? onLongPress,
    Color? normalBackground,
    double radius = 8,
    EdgeInsets? padding,
    bool disabled = false,
  }) {
    return buildInk(
      color: disabled
          ? Colors.transparent
          : normalBackground ?? Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.hardEdge,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: padding ?? const EdgeInsets.all(10),
        child: icon ?? emptyWidget,
      ),
    );
  }

  static Widget buildDynamicIconButton({
    required BuildContext context,
    required dynamic icon,
    required Function()? onTap,
    Function(BuildContext context, dynamic value, Widget? child)? onChangemode,
  }) {
    return Selector<AppProvider, ActiveThemeMode>(
      selector: (context, globalProvider) => globalProvider.themeMode,
      builder: (context, themeMode, child) {
        onChangemode?.call(context, themeMode, child);
        return buildIconButton(context: context, icon: icon, onTap: onTap);
      },
    );
  }

  static Widget buildDynamicToolButton({
    required BuildContext context,
    required WindowButtonIconBuilder iconBuilder,
    required VoidCallback onTap,
    Function(BuildContext context, dynamic value, Widget? child)? onChangemode,
  }) {
    return Selector<AppProvider, ActiveThemeMode>(
      selector: (context, appProvider) => appProvider.themeMode,
      builder: (context, themeMode, child) {
        onChangemode?.call(context, themeMode, child);
        return ToolButton(
          context: context,
          iconBuilder: iconBuilder,
          onTap: onTap,
          padding: const EdgeInsets.all(7),
        );
      },
    );
  }

  static Widget buildRadioItem({
    double radius = 10,
    bool roundTop = false,
    bool roundBottom = false,
    required bool value,
    Color? titleColor,
    bool showLeading = false,
    IconData leading = Icons.check_box_outline_blank,
    required String title,
    String description = "",
    Function()? onTap,
    double trailingLeftMargin = 5,
    double padding = 15,
    required BuildContext context,
    bool disabled = false,
  }) {
    assert(padding > 5);
    return buildInk(
      borderRadius: BorderRadius.vertical(
          top: roundTop ? Radius.circular(radius) : const Radius.circular(0),
          bottom:
              roundBottom ? Radius.circular(radius) : const Radius.circular(0)),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: description.isNotEmpty ? padding : padding - 5,
              horizontal: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Visibility(
                  visible: showLeading,
                  child: Icon(leading, size: 20),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      description.isNotEmpty
                          ? Text(description,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.apply(fontSizeDelta: 1))
                          : emptyWidget,
                    ],
                  ),
                ),
                SizedBox(width: trailingLeftMargin),
                Opacity(
                  opacity: disabled ? 0.2 : 1,
                  child: Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: value,
                      onChanged: disabled
                          ? null
                          : (_) {
                              HapticFeedback.lightImpact();
                              if (onTap != null) onTap();
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!ThemeColorData.isImmersive(context))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: roundBottom ? null : MyTheme.bottomBorder,
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildEntryItem({
    required BuildContext context,
    double radius = 10,
    bool roundTop = false,
    bool roundBottom = false,
    bool showLeading = false,
    bool showTrailing = true,
    bool isCaption = false,
    Color? backgroundColor,
    Color? titleColor,
    Color? descriptionColor,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    IconData leading = Icons.home_filled,
    required String title,
    String tip = "",
    String description = "",
    Function()? onTap,
    double padding = 18,
    double trailingLeftMargin = 5,
    bool dividerPadding = true,
    IconData trailing = Icons.keyboard_arrow_right_rounded,
  }) {
    return buildInk(
      borderRadius: BorderRadius.vertical(
        top: roundTop ? Radius.circular(radius) : const Radius.circular(0),
        bottom:
            roundBottom ? Radius.circular(radius) : const Radius.circular(0),
      ),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: padding, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Visibility(
                  visible: showLeading,
                  child: Icon(leading, size: 20),
                ),
                showLeading
                    ? const SizedBox(width: 10)
                    : const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: crossAxisAlignment,
                    children: [
                      Text(
                        title,
                        style: isCaption
                            ? Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.apply(fontSizeDelta: 1)
                            : Theme.of(context).textTheme.titleMedium?.apply(
                                  color: titleColor,
                                ),
                      ),
                      description.isNotEmpty
                          ? Text(
                              description,
                              style:
                                  Theme.of(context).textTheme.labelSmall?.apply(
                                        fontSizeDelta: 1,
                                        color: descriptionColor,
                                      ),
                            )
                          : emptyWidget,
                    ],
                  ),
                ),
                isCaption || tip.isEmpty
                    ? Container()
                    : const SizedBox(width: 50),
                Text(
                  tip,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.apply(fontSizeDelta: 1),
                ),
                SizedBox(width: showTrailing ? trailingLeftMargin : 0),
                Visibility(
                  visible: showTrailing,
                  child: Icon(
                    trailing,
                    size: 20,
                    color: Theme.of(context).iconTheme.color?.withAlpha(127),
                  ),
                ),
              ],
            ),
          ),
          if (!ThemeColorData.isImmersive(context))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: roundBottom ? null : MyTheme.bottomBorder,
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildCaptionItem({
    required BuildContext context,
    double radius = 10,
    bool topRadius = true,
    bool bottomRadius = false,
    bool showLeading = false,
    bool showTrailing = true,
    IconData leading = Icons.home_filled,
    required String title,
    IconData trailing = Icons.keyboard_arrow_right_rounded,
  }) {
    return buildEntryItem(
      context: context,
      title: title,
      radius: radius,
      roundTop: topRadius,
      roundBottom: bottomRadius,
      showTrailing: false,
      showLeading: showLeading,
      onTap: null,
      leading: leading,
      trailing: trailing,
      padding: 10,
      isCaption: true,
      dividerPadding: false,
    );
  }

  static Widget buildContainerItem({
    double radius = 10,
    bool topRadius = false,
    bool bottomRadius = false,
    required Widget child,
    required BuildContext context,
    Color? backgroundColor,
    Border? border,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).canvasColor,
        borderRadius: BorderRadius.vertical(
          top: topRadius ? Radius.circular(radius) : const Radius.circular(0),
          bottom:
              bottomRadius ? Radius.circular(radius) : const Radius.circular(0),
        ),
        border: border,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.05,
              style: bottomRadius ? BorderStyle.none : BorderStyle.solid,
            ),
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.05,
              style: topRadius ? BorderStyle.none : BorderStyle.solid,
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  static Widget buildFontItem({
    required CustomFont font,
    required CustomFont currentFont,
    required BuildContext context,
    required Function(CustomFont?)? onChanged,
    Function(CustomFont?)? onDelete,
    bool showDelete = false,
    double width = 110,
    double height = 160,
  }) {
    bool exist = true;
    TextTheme textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            width: width,
            height: height,
            padding:
                const EdgeInsets.only(top: 10, bottom: 5, left: 10, right: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: height - 65,
                  child: FutureBuilder(
                    future: Future<CustomFont>.sync(() async {
                      exist = await CustomFont.isFontFileExist(font);
                      return font;
                    }),
                    builder: (context, snapshot) {
                      return exist
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  "AaBbCcDd",
                                  style: textTheme.titleMedium?.apply(
                                    fontFamily: font.fontFamily,
                                    letterSpacingDelta: 1,
                                  ),
                                  maxLines: 1,
                                ),
                                AutoSizeText(
                                  "AaBbCcDd",
                                  style: textTheme.titleLarge?.apply(
                                    fontFamily: font.fontFamily,
                                    letterSpacingDelta: 1,
                                  ),
                                  maxLines: 1,
                                ),
                                AutoSizeText(
                                  "你好世界",
                                  style: textTheme.titleMedium?.apply(
                                    fontFamily: font.fontFamily,
                                    letterSpacingDelta: 1,
                                  ),
                                  maxLines: 1,
                                ),
                                AutoSizeText(
                                  "你好世界",
                                  style: textTheme.titleLarge?.apply(
                                    fontFamily: font.fontFamily,
                                    letterSpacingDelta: 1,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            )
                          : Text(
                              S.current.fontFileNotExist,
                              style: textTheme.titleLarge?.apply(
                                fontFamily: font.fontFamily,
                                fontWeightDelta: 0,
                              ),
                            );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio(
                      value: font,
                      groupValue: currentFont,
                      onChanged: onChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context).primaryColor;
                        } else {
                          return Theme.of(context).textTheme.bodySmall?.color;
                        }
                      }),
                    ),
                    if (showDelete) const SizedBox(width: 5),
                    if (showDelete)
                      ItemBuilder.buildIconButton(
                        context: context,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 21,
                        ),
                        padding: const EdgeInsets.all(10),
                        onTap: () {
                          onDelete?.call(font);
                        },
                      ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            font.intlFontName,
            style: Theme.of(context).textTheme.bodySmall?.apply(
                  fontFamily: font.fontFamily,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget buildEmptyFontItem({
    required BuildContext context,
    required Function()? onTap,
    double width = 110,
    double height = 160,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          ItemBuilder.buildClickable(
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: width,
                height: height,
                padding: const EdgeInsets.only(
                    top: 5, bottom: 5, left: 10, right: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 40,
                  color: Theme.of(context).textTheme.labelSmall?.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.current.loadFontFamily,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget buildThemeItem({
    required ThemeColorData themeColorData,
    required int index,
    required int groupIndex,
    required BuildContext context,
    required Function(int?)? onChanged,
  }) {
    return Container(
      width: 107.3,
      height: 166.4,
      margin: EdgeInsets.only(left: index == 0 ? 10 : 0, right: 10),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(top: 10, bottom: 0, left: 8, right: 8),
            decoration: BoxDecoration(
              color: themeColorData.background,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: MyTheme.border,
            ),
            child: Column(
              children: [
                _buildCardRow(themeColorData),
                const SizedBox(height: 5),
                _buildCardRow(themeColorData),
                const SizedBox(height: 15),
                Radio(
                  value: index,
                  groupValue: groupIndex,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return themeColorData.primaryColor;
                    } else {
                      return themeColorData.textGrayColor;
                    }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            themeColorData.name,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static Widget buildEmptyThemeItem({
    required BuildContext context,
    required Function()? onTap,
  }) {
    return Container(
      width: 107.3,
      height: 166.4,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Container(
            width: 107.3,
            height: 141.7,
            padding: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: MyTheme.border,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 30,
                  color: Theme.of(context).textTheme.titleSmall?.color,
                ),
                const SizedBox(height: 6),
                Text(S.current.newTheme,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static Widget _buildCardRow(ThemeColorData themeColorData) {
    return Container(
      height: 35,
      width: 90,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: themeColorData.canvasBackground,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 22,
            width: 22,
            decoration: BoxDecoration(
              color: themeColorData.splashColor,
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 5,
                width: 45,
                decoration: BoxDecoration(
                  color: themeColorData.textColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 5,
                width: 35,
                decoration: BoxDecoration(
                  color: themeColorData.textGrayColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildInputItem({
    required BuildContext context,
    TextInputAction? textInputAction,
    IconData? leadingIcon,
    String? hint,
    TextEditingController? controller,
    bool obscureText = false,
    TailingType tailingType = TailingType.none,
    String? tailingText,
    bool tailingEnable = true,
    IconData? tailingIcon,
    Function()? onTailingTap,
    Function(String)? onSubmitted,
    Widget? tailingWidget,
    Color? backgroundColor,
    TextInputType? keyboardType,
    FocusNode? focusNode,
  }) {
    Widget? tailing;
    Function()? defaultTapFunction;
    if (tailingType == TailingType.clear) {
      tailing = Icon(Icons.clear_rounded,
          color: Theme.of(context).iconTheme.color?.withAlpha(120));
      defaultTapFunction = () {
        controller?.clear();
      };
    }
    if (tailingType == TailingType.password) {
      tailing = Icon(Icons.remove_red_eye_outlined,
          color: Theme.of(context).iconTheme.color?.withAlpha(120));
      defaultTapFunction = () {
        obscureText = !obscureText;
      };
    }
    if (tailingType == TailingType.icon && tailingIcon != null) {
      tailing = Icon(tailingIcon, color: Theme.of(context).iconTheme.color);
    }
    if (tailingType == TailingType.text && tailingText != null) {
      tailing = Text(
        tailingText,
        style: Theme.of(context).textTheme.titleSmall?.apply(
              color: tailingEnable
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.labelSmall?.color,
              fontWeightDelta: 2,
            ),
      );
    }
    if (tailingType == TailingType.widget && tailingWidget != null) {
      tailing = tailingWidget;
    }
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).canvasColor,
        shape: BoxShape.rectangle,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              textInputAction: textInputAction,
              keyboardType: keyboardType,
              obscureText: obscureText,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                contentPadding: EdgeInsets.only(
                    top: leadingIcon != null ? 13.0 : 0,
                    left: leadingIcon != null ? 0 : 10),
                hintStyle: Theme.of(context).textTheme.titleSmall,
                prefixIcon: leadingIcon != null
                    ? Icon(leadingIcon,
                        color: Theme.of(context).iconTheme.color)
                    : null,
              ),
              contextMenuBuilder: (contextMenuContext, details) =>
                  ItemBuilder.editTextContextMenuBuilder(
                      contextMenuContext, details,
                      context: context),
              onSubmitted: onSubmitted,
            ),
          ),
          if (tailing != null)
            GestureDetector(
              onTap: () {
                if (tailingEnable) {
                  onTailingTap?.call();
                  defaultTapFunction?.call();
                }
              },
              child:
                  MouseRegion(cursor: SystemMouseCursors.click, child: tailing),
            ),
        ],
      ),
    );
  }

  static Widget buildSmallIcon({
    required BuildContext context,
    required IconData icon,
    Function()? onTap,
    Color? backgroundColor,
  }) {
    return buildInk(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Icon(icon),
      ),
    );
  }

  static Widget buildTextDivider({
    required BuildContext context,
    required String text,
    double horizontalMargin = 15,
    double width = 300,
  }) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: horizontalMargin),
              height: 1,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
              ),
            ),
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: horizontalMargin),
              height: 1,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildEmptyPlaceholder({
    required BuildContext context,
    required String text,
    double size = 30,
    bool showButton = false,
    String? buttonText,
    ScrollController? scrollController,
    Function()? onTap,
    ScrollPhysics? physics,
    double topPadding = 50,
    bool shrinkWrap = true,
  }) {
    return ListView(
      physics: physics,
      shrinkWrap: shrinkWrap,
      controller: scrollController,
      children: [
        SizedBox(height: topPadding),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Icon(
                    Icons.inbox_rounded,
                    size: size,
                    color: Theme.of(context).textTheme.labelLarge?.color,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  if (showButton) const SizedBox(height: 10),
                  if (showButton)
                    ItemBuilder.buildRoundButton(
                      context,
                      text: buttonText,
                      background: Theme.of(context).primaryColor,
                      onTap: onTap,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildTranslucentTag(
    BuildContext context, {
    required String text,
    bool isCircle = false,
    int? width,
    int? height,
    double opacity = 0.4,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    double? fontSizeDelta,
    dynamic icon,
  }) {
    return Container(
      padding: isCircle
          ? padding ?? const EdgeInsets.all(5)
          : padding ?? const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        color: Colors.black.withOpacity(opacity),
        borderRadius: isCircle
            ? null
            : BorderRadius.all(Radius.circular(borderRadius ?? 50)),
      ),
      child: Row(
        children: [
          if (icon != null) icon,
          if (icon != null && Utils.isNotEmpty(text)) const SizedBox(width: 3),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.apply(
                  color: Colors.white,
                  fontSizeDelta: fontSizeDelta ?? -1,
                ),
          ),
        ],
      ),
    );
  }

  static Widget buildCopyable(
    BuildContext context, {
    required Widget child,
    Function()? onTap,
    required String? text,
    String? toastText,
    bool copyable = true,
  }) {
    return ItemBuilder.buildClickableGestureDetector(
      onTap: onTap,
      onLongPress: copyable
          ? () => Utils.copy(context, text, toastText: toastText)
          : null,
      child: child,
    );
  }

  static Widget buildLoadingWidget(
    BuildContext context, {
    double size = 50,
    bool showText = true,
    double topPadding = 0,
    double bottomPadding = 100,
    String? text,
    bool forceDark = false,
    Color? background,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        color: background ?? Theme.of(context).cardColor.withAlpha(127),
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieUtil.load(
              LottieUtil.getLoadingPath(context, forceDark: forceDark),
              size: size,
            ),
            if (showText) const SizedBox(height: 10),
            if (showText)
              Text(text ?? S.current.loading,
                  style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }

  static buildErrorWidget({
    required BuildContext context,
    String? text,
    String? buttonText,
    Function()? onTap,
  }) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text ?? S.current.loadFailed,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          ItemBuilder.buildRoundButton(context,
              text: buttonText ?? S.current.retry, onTap: onTap),
        ],
      ),
    );
  }

  static MyCachedNetworkImage buildCachedImage({
    required String imageUrl,
    required BuildContext context,
    BoxFit? fit,
    bool showLoading = true,
    double? width,
    double? height,
    double? placeholderHeight,
    Color? placeholderBackground,
    double topPadding = 0,
    double bottomPadding = 0,
    bool simpleError = false,
  }) {
    return MyCachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      simpleError: simpleError,
      height: height,
      placeholderHeight: placeholderHeight,
      placeholderBackground: placeholderBackground,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      showLoading: showLoading,
    );
  }

  static buildAvatar({
    required BuildContext context,
    required String imageUrl,
    String? avatarBoxImageUrl,
    double size = 32,
    bool showLoading = false,
    bool useDefaultAvatar = false,
    bool showBorder = true,
    ShowDetailMode showDetailMode = ShowDetailMode.not,
    String? title,
    String? caption,
    String? tagPrefix,
    String? tagSuffix,
    bool clickable = true,
  }) {
    double avatarBoxDeltaSize = size / 2;
    bool hasAvatarBox = Utils.isNotEmpty(avatarBoxImageUrl);
    String tagUrl = hasAvatarBox && showDetailMode == ShowDetailMode.avatarBox
        ? avatarBoxImageUrl!
        : imageUrl;
    String heroTag = Utils.getHeroTag(
      tagPrefix: tagPrefix,
      tagSuffix: tagSuffix,
      url: tagUrl,
    );
    String avatarTag =
        hasAvatarBox && showDetailMode == ShowDetailMode.avatarBox
            ? Utils.getRandomString()
            : heroTag;
    String avatarBoxTag =
        hasAvatarBox && showDetailMode == ShowDetailMode.avatarBox
            ? heroTag
            : Utils.getRandomString();
    return Container(
      decoration: BoxDecoration(
        border: showBorder && !hasAvatarBox
            ? Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              )
            : const Border.fromBorderSide(BorderSide.none),
        shape: BoxShape.circle,
      ),
      child: useDefaultAvatar || tagUrl.isEmpty
          ? ClipOval(
              child: Image.asset(
                "assets/avatar.png",
                width: size,
                height: size,
              ),
            )
          : ItemBuilder.buildClickable(
              clickable: clickable,
              GestureDetector(
                onTap: showDetailMode != ShowDetailMode.not
                    ? () {
                        RouteUtil.pushDialogRoute(
                          context,
                          showClose: false,
                          fullScreen: true,
                          useFade: true,
                          HeroPhotoViewScreen(
                            tagPrefix: tagPrefix,
                            tagSuffix: tagSuffix,
                            imageUrls: [tagUrl],
                            useMainColor: false,
                            title: title,
                            captions: [caption ?? ""],
                          ),
                        );
                      }
                    : null,
                child: hasAvatarBox
                    ? Stack(
                        children: [
                          Positioned(
                            top: avatarBoxDeltaSize / 2,
                            left: avatarBoxDeltaSize / 2,
                            child: Hero(
                              tag: avatarTag,
                              child: ClipOval(
                                child: ItemBuilder.buildCachedImage(
                                  context: context,
                                  imageUrl: imageUrl,
                                  width: size,
                                  showLoading: showLoading,
                                  height: size,
                                  simpleError: true,
                                ),
                              ),
                            ),
                          ),
                          Hero(
                            tag: avatarBoxTag,
                            child: ItemBuilder.buildCachedImage(
                              context: context,
                              imageUrl: avatarBoxImageUrl!,
                              width: size + avatarBoxDeltaSize,
                              showLoading: false,
                              placeholderBackground: Colors.transparent,
                              topPadding: 0,
                              bottomPadding: 0,
                              height: size + avatarBoxDeltaSize,
                              simpleError: true,
                            ),
                          ),
                        ],
                      )
                    : ClipOval(
                        child: ItemBuilder.buildCachedImage(
                          context: context,
                          imageUrl: tagUrl,
                          width: size,
                          showLoading: showLoading,
                          height: size,
                          simpleError: true,
                        ),
                      ),
              ),
            ),
    );
  }

  static buildHeroCachedImage({
    required String imageUrl,
    required BuildContext context,
    BoxFit? fit = BoxFit.cover,
    bool showLoading = true,
    double? width,
    double? height,
    Color? placeholderBackground,
    double topPadding = 0,
    double bottomPadding = 0,
    String? title,
    String? caption,
    String? tagPrefix,
    String? tagSuffix,
  }) {
    return ItemBuilder.buildClickable(
      GestureDetector(
        onTap: () {
          RouteUtil.pushDialogRoute(
            context,
            showClose: false,
            fullScreen: true,
            useFade: true,
            HeroPhotoViewScreen(
              tagPrefix: tagPrefix,
              tagSuffix: tagSuffix,
              imageUrls: [imageUrl],
              useMainColor: false,
              title: title,
              captions: [caption ?? ""],
            ),
          );
        },
        child: Hero(
          tag: Utils.getHeroTag(
              tagSuffix: tagSuffix, tagPrefix: tagPrefix, url: imageUrl),
          child: ItemBuilder.buildCachedImage(
            context: context,
            imageUrl: imageUrl,
            width: width,
            height: height,
            showLoading: showLoading,
            bottomPadding: bottomPadding,
            topPadding: topPadding,
            placeholderBackground: placeholderBackground,
            fit: fit,
          ),
        ),
      ),
    );
  }

  static Widget buildRoundButton(
    BuildContext context, {
    String? text,
    Function()? onTap,
    Color? background,
    Icon? icon,
    EdgeInsets? padding,
    double radius = 50,
    Color? color,
    double fontSizeDelta = 0,
    TextStyle? textStyle,
    double? width,
  }) {
    return Material(
      color: background ?? Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: ItemBuilder.buildClickable(
          clickable: onTap != null,
          Container(
            width: width,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) icon,
                Text(
                  text ?? "",
                  style: textStyle ??
                      Theme.of(context).textTheme.titleSmall?.apply(
                            color: color ??
                                (background != null
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.color),
                            fontWeightDelta: 2,
                            fontSizeDelta: fontSizeDelta,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildFramedButton(
    BuildContext context, {
    String? text,
    Function()? onTap,
    Color? outline,
    Icon? icon,
    EdgeInsets? padding,
    double radius = 50,
    Color? color,
    double fontSizeDelta = 0,
    TextStyle? textStyle,
    double? width,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: ItemBuilder.buildClickable(
          clickable: onTap != null,
          Container(
            width: width,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                  color: outline ?? Theme.of(context).primaryColor, width: 1),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) icon,
                Text(
                  text ?? "",
                  style: textStyle ??
                      Theme.of(context).textTheme.titleSmall?.apply(
                            color: color ?? Theme.of(context).primaryColor,
                            fontWeightDelta: 2,
                            fontSizeDelta: fontSizeDelta,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildTagItem(
    BuildContext context,
    String tag,
    TagType tagType, {
    String? shownTag,
    Function()? onTap,
    Color? backgroundColor,
    Color? color,
    bool showIcon = true,
    bool showRightIcon = false,
    bool showTagLabel = true,
    bool jumpToTag = true,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    double fontSizeDelta = 0,
    int fontWeightDelta = 0,
  }) {
    String str = Utils.isNotEmpty(shownTag) ? shownTag! : tag;
    return GestureDetector(
      onTap: () {
        if (!tagType.preventJump && jumpToTag) {
          panelScreenState?.pushPage(TagDetailScreen(tag: tag));
        }
        onTap?.call();
      },
      child: ItemBuilder.buildClickable(
        clickable: (!tagType.preventJump && jumpToTag) || onTap != null,
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tagType != TagType.normal
                ? MyColors.getHotTagBackground(context)
                : backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // if (tagType == TagType.normal && showIcon)
              //   AssetUtil.load(
              //     AssetUtil.tagDarkIcon,
              //     size: 15,
              //   ),
              if (tagType == TagType.hot && showIcon)
                AssetUtil.load(AssetUtil.hotIcon, size: 12),
              if (tagType == TagType.hot && showIcon) const SizedBox(width: 2),
              // Icon(Icons.local_fire_department_rounded,
              //     size: 15, color: MyColors.getHotTagTextColor(context)),
              if (tagType == TagType.egg && showIcon)
                Icon(Icons.egg_rounded,
                    size: 15, color: MyColors.getHotTagTextColor(context)),
              if (tagType == TagType.catutu && showIcon)
                Container(
                  margin: const EdgeInsets.only(right: 2),
                  child: Icon(Icons.auto_fix_high_outlined,
                      size: 15, color: MyColors.getHotTagTextColor(context)),
                ),
              Text(
                ((tagType == TagType.normal || !showIcon) && showTagLabel)
                    ? "#$str"
                    : str,
                style: tagType != TagType.normal
                    ? Theme.of(context).textTheme.labelMedium?.apply(
                          color: color ?? MyColors.hotTagTextColor,
                          fontSizeDelta: fontSizeDelta,
                          fontWeightDelta: fontWeightDelta,
                        )
                    : Theme.of(context).textTheme.labelMedium?.apply(
                          color: color,
                          fontSizeDelta: fontSizeDelta,
                          fontWeightDelta: fontWeightDelta,
                        ),
              ),
              if (showRightIcon)
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  size: 16,
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildSmallTagItem(
    BuildContext context,
    String tag, {
    Function()? onTap,
    Color? backgroundColor,
    bool showIcon = true,
  }) {
    return GestureDetector(
      onTap: () {
        panelScreenState?.pushPage(TagDetailScreen(tag: tag));
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          "#$tag",
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }

  static Widget buildSearchBar({
    required BuildContext context,
    required hintText,
    required Function(dynamic value) onSubmitted,
    TextEditingController? controller,
    FocusNode? focusNode,
    Color? background,
    double borderRadius = 50,
    double? bottomMargin,
    double hintFontSizeDelta = 0,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  focusNode: focusNode,
                  contextMenuBuilder: (contextMenuContext, details) =>
                      ItemBuilder.editTextContextMenuBuilder(
                          contextMenuContext, details,
                          context: context),
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  style: Theme.of(context).textTheme.titleSmall?.apply(
                        fontSizeDelta: hintFontSizeDelta,
                      ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 8),
                    border:
                        const OutlineInputBorder(borderSide: BorderSide.none),
                    hintText: hintText,
                    hintStyle: Theme.of(context).textTheme.titleSmall?.apply(
                          color: Theme.of(context).textTheme.labelSmall?.color,
                          fontSizeDelta: hintFontSizeDelta,
                        ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              onSubmitted(controller?.text);
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AssetUtil.loadDouble(
                context,
                AssetUtil.searchLightIcon,
                AssetUtil.searchDarkIcon,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTitle(
    BuildContext context, {
    String? title,
    IconData? icon,
    String? suffixText,
    Function()? onTap,
    double topMargin = 8,
    double bottomMargin = 4,
    double left = 16,
    TextStyle? textStyle,
  }) {
    return Container(
      margin: EdgeInsets.only(
        left: left,
        right: Utils.isNotEmpty(suffixText) ? 8 : 16,
        top: topMargin,
        bottom: bottomMargin,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title ?? "",
              style: textStyle ??
                  Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.apply(fontWeightDelta: 2, fontSizeDelta: 1),
            ),
          ),
          if (icon != null)
            ItemBuilder.buildIconButton(
              context: context,
              icon: Icon(
                icon,
                size: 18,
                color: Theme.of(context).textTheme.labelSmall?.color,
              ),
              onTap: onTap,
            ),
          if (Utils.isNotEmpty(suffixText))
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Text(
                    suffixText!,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    size: 18,
                    color: Theme.of(context).textTheme.labelSmall?.color,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static buildDivider(
    BuildContext context, {
    double vertical = 8,
    double horizontal = 16,
    double? width,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin ??
          EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
      height: width ?? 0.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).dividerColor,
      ),
    );
  }

  static buildStatisticItem(
    BuildContext context, {
    Color? labelColor,
    Color? countColor,
    int labelFontWeightDelta = 0,
    int countFontWeightDelta = 0,
    required String title,
    required int? count,
    Function()? onTap,
  }) {
    Map countWithScale = Utils.formatCountToMap(count ?? 0);
    return MouseRegion(
      cursor:
          onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: Column(
            children: [
              count != null
                  ? Row(
                      children: [
                        Text(
                          countWithScale['count'],
                          style: Theme.of(context).textTheme.titleLarge?.apply(
                              color: countColor,
                              fontWeightDelta: countFontWeightDelta),
                        ),
                        if (countWithScale.containsKey("scale"))
                          const SizedBox(width: 2),
                        if (countWithScale.containsKey("scale"))
                          Text(
                            countWithScale['scale'],
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.apply(
                                    fontSizeDelta: -2,
                                    color: countColor,
                                    fontWeightDelta: countFontWeightDelta),
                          ),
                      ],
                    )
                  : Text(
                      "-",
                      style: Theme.of(context).textTheme.titleLarge?.apply(
                          color: countColor,
                          fontWeightDelta: countFontWeightDelta),
                    ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.apply(
                      fontSizeDelta: -1,
                      color: labelColor,
                      fontWeightDelta: labelFontWeightDelta,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static buildIconTextButton(
    BuildContext context, {
    Axis direction = Axis.horizontal,
    double spacing = 2,
    Widget? icon,
    required String text,
    double fontSizeDelta = 0,
    int fontWeightDelta = 0,
    bool showIcon = true,
    Function()? onTap,
    Color? color,
    int quarterTurns = 0,
    bool start = false,
    TextStyle? style,
  }) {
    return ItemBuilder.buildClickable(
      clickable: onTap != null,
      GestureDetector(
        onTap: onTap,
        child: direction == Axis.horizontal
            ? Row(
                mainAxisAlignment:
                    start ? MainAxisAlignment.start : MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null && showIcon)
                    RotatedBox(quarterTurns: quarterTurns, child: icon),
                  if (icon != null && showIcon) SizedBox(width: spacing),
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: style ??
                          Theme.of(context).textTheme.titleSmall?.apply(
                                fontSizeDelta: fontSizeDelta,
                                color: color,
                                fontWeightDelta: fontWeightDelta,
                              ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null && showIcon)
                    RotatedBox(quarterTurns: quarterTurns, child: icon),
                  if (icon != null && showIcon) SizedBox(height: spacing),
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: style ??
                          Theme.of(context).textTheme.titleSmall?.apply(
                                fontSizeDelta: fontSizeDelta,
                                color: color,
                                fontWeightDelta: fontWeightDelta,
                              ),
                    ),
                ],
              ),
      ),
    );
  }

  static buildGroupButtons({
    required List<String> buttons,
    GroupButtonController? controller,
    bool enableDeselect = false,
    Function(dynamic value, int index, bool isSelected)? onSelected,
  }) {
    return GroupButton(
      isRadio: true,
      enableDeselect: enableDeselect,
      options: const GroupButtonOptions(
        mainGroupAlignment: MainGroupAlignment.start,
      ),
      onSelected: onSelected,
      maxSelected: 1,
      controller: controller,
      buttons: buttons,
      buttonBuilder: (selected, label, context, _, __) {
        return SizedBox(
          width: 80,
          child: ItemBuilder.buildRoundButton(
            context,
            text: label,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            background: selected ? Theme.of(context).primaryColor : null,
            textStyle: Theme.of(context).textTheme.titleSmall?.apply(
                fontWeightDelta: 1, color: selected ? Colors.white : null),
          ),
        );
      },
    );
  }

  static Widget buildWrapTagList(
    BuildContext context,
    List<String> list, {
    Function(String)? onTap,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.start,
        children: List.generate(list.length, (index) {
          return buildWrapTagItem(context, list[index], onTap: onTap);
        }),
      ),
    );
  }

  static Widget buildWrapTagItem(
    BuildContext context,
    String str, {
    Function(String)? onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          onTap?.call(str);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Text(
            str,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  static Tab buildAnimatedTab(
    BuildContext context, {
    required bool selected,
    required String text,
    bool normalUserBold = false,
    bool sameFontSize = false,
    double fontSizeDelta = 0,
  }) {
    TextStyle normalStyle = Theme.of(context).textTheme.titleLarge!.apply(
          color: Colors.grey,
          fontSizeDelta: fontSizeDelta - (sameFontSize ? 0 : 1),
          fontWeightDelta: normalUserBold ? 0 : -2,
        );
    TextStyle selectedStyle = Theme.of(context).textTheme.titleLarge!.apply(
          fontSizeDelta: fontSizeDelta + (sameFontSize ? 0 : 1),
        );
    return Tab(
      child: AnimatedDefaultTextStyle(
        style: selected ? selectedStyle : normalStyle,
        duration: const Duration(milliseconds: 100),
        child: Container(
          alignment: Alignment.center,
          child: Text(text),
        ),
      ),
    );
  }

  static buildSelectableArea({
    required BuildContext context,
    required Widget child,
  }) {
    return MySelectionArea(
      contextMenuBuilder: (contextMenuContext, details) {
        Map<ContextMenuButtonType, String> typeToString = {
          ContextMenuButtonType.copy: S.current.copy,
          ContextMenuButtonType.cut: S.current.cut,
          ContextMenuButtonType.paste: S.current.paste,
          ContextMenuButtonType.selectAll: S.current.selectAll,
          ContextMenuButtonType.searchWeb: S.current.search,
          ContextMenuButtonType.share: S.current.share,
          ContextMenuButtonType.lookUp: S.current.search,
          ContextMenuButtonType.delete: S.current.delete,
          ContextMenuButtonType.liveTextInput: S.current.input,
          ContextMenuButtonType.custom: S.current.custom,
        };
        List<MyContextMenuItem> items = [];
        for (var e in details.contextMenuButtonItems) {
          if (e.type != ContextMenuButtonType.custom) {
            items.add(
              MyContextMenuItem(
                label: typeToString[e.type] ?? "",
                type: e.type,
                onPressed: () {
                  e.onPressed?.call();
                  if (e.type == ContextMenuButtonType.copy) {
                    IToast.showTop(S.current.copySuccess);
                  }
                },
              ),
            );
          }
        }
        if (Utils.isNotEmpty(details.selectedText)) {
          items.add(
            MyContextMenuItem(
              label: S.current.searchInApp,
              type: ContextMenuButtonType.custom,
              onPressed: () {
                if (Utils.isNotEmpty(details.selectedText)) {
                  panelScreenState?.pushPage(
                    SearchResultScreen(
                      searchKey: details.selectedText!,
                    ),
                  );
                }
                details.hideToolbar();
              },
            ),
          );
        }
        if (ResponsiveUtil.isMobile()) {
          return MyMobileTextSelectionToolbar.items(
            anchorAbove: details.contextMenuAnchors.primaryAnchor,
            anchorBelow: details.contextMenuAnchors.primaryAnchor,
            backgroundColor: Theme.of(context).canvasColor,
            dividerColor: Theme.of(context).dividerColor,
            items: items,
            itemBuilder: (MyContextMenuItem item) {
              return Text(
                item.label ?? "",
                style: Theme.of(context).textTheme.titleMedium,
              );
            },
          );
        } else {
          return MyDesktopTextSelectionToolbar(
            anchor: details.contextMenuAnchors.primaryAnchor,
            backgroundColor: Theme.of(context).canvasColor,
            dividerColor: Theme.of(context).dividerColor,
            items: items,
          );
        }
      },
      child: SelectionTransformer.separated(
        child: child,
      ),
    );
  }

  static Widget editTextContextMenuBuilder(
    contextMenuContext,
    EditableTextState details, {
    required BuildContext context,
  }) {
    Map<ContextMenuButtonType, String> typeToString = {
      ContextMenuButtonType.copy: S.current.copy,
      ContextMenuButtonType.cut: S.current.cut,
      ContextMenuButtonType.paste: S.current.paste,
      ContextMenuButtonType.selectAll: S.current.selectAll,
      ContextMenuButtonType.searchWeb: S.current.search,
      ContextMenuButtonType.share: S.current.share,
      ContextMenuButtonType.lookUp: S.current.search,
      ContextMenuButtonType.delete: S.current.delete,
      ContextMenuButtonType.liveTextInput: S.current.input,
      ContextMenuButtonType.custom: S.current.custom,
    };
    List<MyContextMenuItem> items = [];
    int start = details.textEditingValue.selection.start <= -1
        ? 0
        : details.textEditingValue.selection.start;
    int end = details.textEditingValue.selection.end
        .clamp(0, details.textEditingValue.text.length);
    String selectedText = details.textEditingValue.text.substring(start, end);
    for (var e in details.contextMenuButtonItems) {
      if (e.type != ContextMenuButtonType.custom) {
        items.add(
          MyContextMenuItem(
            label: typeToString[e.type] ?? "",
            type: e.type,
            onPressed: () {
              e.onPressed?.call();
              if (e.type == ContextMenuButtonType.copy) {
                IToast.showTop(S.current.copySuccess);
              }
            },
          ),
        );
      }
    }
    if (Utils.isNotEmpty(selectedText)) {
      items.add(
        MyContextMenuItem(
          label: S.current.searchInApp,
          type: ContextMenuButtonType.custom,
          onPressed: () {
            if (Utils.isNotEmpty(selectedText)) {
              panelScreenState?.pushPage(
                SearchResultScreen(searchKey: selectedText),
              );
            }
            details.hideToolbar();
          },
        ),
      );
    }
    if (ResponsiveUtil.isMobile()) {
      return MyMobileTextSelectionToolbar.items(
        anchorAbove: details.contextMenuAnchors.primaryAnchor,
        anchorBelow: details.contextMenuAnchors.primaryAnchor,
        backgroundColor: Theme.of(contextMenuContext).canvasColor,
        dividerColor: Theme.of(contextMenuContext).dividerColor,
        items: items,
        itemBuilder: (MyContextMenuItem item) {
          return Text(
            item.label ?? "",
            style: Theme.of(contextMenuContext).textTheme.titleMedium,
          );
        },
      );
    } else {
      return MyDesktopTextSelectionToolbar(
        anchor: details.contextMenuAnchors.primaryAnchor,
        backgroundColor: Theme.of(contextMenuContext).canvasColor,
        dividerColor: Theme.of(contextMenuContext).dividerColor,
        items: items,
      );
    }
  }

  static buildHtmlWidget(
    BuildContext context,
    String content, {
    TextStyle? textStyle,
    List<Illust>? illusts,
    bool enableImageDetail = true,
    bool parseImage = true,
    bool showLoading = true,
    Function()? onDownloadSuccess,
    bool linkBold = true,
    bool selectable = true,
  }) {
    var htmlWidget = HtmlWidget(
      content,
      enableCaching: true,
      renderMode: RenderMode.column,
      textStyle: textStyle ??
          Theme.of(context)
              .textTheme
              .bodyMedium
              ?.apply(fontSizeDelta: 3, heightDelta: 0.3),
      factoryBuilder: () {
        return CustomImageFactory();
      },
      customStylesBuilder: (e) {
        if (e.attributes.containsKey('href')) {
          return {
            'color':
                '#${MyColors.getLinkColor(context).value.toRadixString(16).substring(2, 8)}',
            'font-weight': linkBold ? '700' : '500',
            'text-decoration-line': 'none',
          };
        } else if (e.id == "title") {
          return {
            'font-weight': '700',
            'font-size': 'larger',
          };
        } else if (e.id == "title-medium") {
          return {
            'font-weight': '700',
          };
        }
        return null;
      },
      customWidgetBuilder: (element) {
        if (element.localName == 'img' && parseImage) {
          String imageUrl = Utils.getUrlByQuality(
              element.attributes['src'] ?? "",
              HiveUtil.getImageQuality(HiveUtil.postDetailImageQualityKey));
          return enableImageDetail
              ? ItemBuilder.buildClickable(
                  GestureDetector(
                    onTap: () {
                      if (imageUrl.isNotEmpty) {
                        RouteUtil.pushDialogRoute(
                          context,
                          showClose: false,
                          fullScreen: true,
                          useFade: true,
                          HeroPhotoViewScreen(
                            imageUrls: illusts ?? [imageUrl],
                            useMainColor: true,
                            initIndex: Utils.getIndexOfImage(
                              imageUrl,
                              illusts ?? [],
                            ),
                            onDownloadSuccess: onDownloadSuccess,
                          ),
                        );
                      }
                    },
                    child: Hero(
                      tag: Utils.getHeroTag(url: imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ItemBuilder.buildCachedImage(
                          context: context,
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholderHeight: 300,
                        ),
                      ),
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ItemBuilder.buildCachedImage(
                    context: context,
                    showLoading: false,
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                );
        }
        return null;
      },
      onTapUrl: (url) async {
        UriUtil.processUrl(context, url);
        return true;
      },
      onLoadingBuilder: showLoading
          ? (context, _, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ItemBuilder.buildLoadingWidget(
                  context,
                  text: S.current.loadingArticle,
                  size: 40,
                  bottomPadding: 30,
                  topPadding: 30,
                ),
              );
            }
          : null,
    );
    if (selectable) {
      return ItemBuilder.buildSelectableArea(
          context: context, child: htmlWidget);
    } else {
      return htmlWidget;
    }
  }

  static Widget buildToolTip(
    BuildContext context,
    String message,
    Widget child,
  ) {
    return Tooltip(
      message: message,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        boxShadow: [
          BoxShadow(blurRadius: 2, color: Colors.black.withOpacity(.2))
        ],
      ),
      preferBelow: true,
      verticalOffset: -15,
      margin: const EdgeInsets.only(left: 40),
      textStyle: const TextStyle(color: Colors.black),
      child: child,
    );
  }

  static buildClickable(
    Widget child, {
    bool clickable = true,
  }) {
    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: child,
    );
  }

  static buildClickableGestureDetector({
    required Widget child,
    Function()? onTap,
    Function()? onLongPress,
    bool clickable = true,
  }) {
    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: child,
      ),
    );
  }

  static buildWindowTitle(
    BuildContext context, {
    Color? backgroundColor,
    List<Widget> leftWidgets = const [],
    List<Widget> rightButtons = const [],
    required bool isStayOnTop,
    required bool isMaximized,
    required Function() onStayOnTopTap,
    bool forceClose = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        // border: Border(
        //   left: BorderSide(
        //     color: Theme.of(context).dividerColor,
        //     width: 0.5
        //   ),
        // ),
      ),
      child: WindowTitleBar(
        hasMoveHandle: ResponsiveUtil.isDesktop(),
        titleBarHeightDelta: 26,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ...leftWidgets,
            // const Spacer(),
            Row(
              children: [
                const SizedBox(width: 10),
                ...rightButtons,
                StayOnTopWindowButton(
                  context: context,
                  rotateAngle: isStayOnTop ? -pi / 4 : 0,
                  colors: isStayOnTop
                      ? MyColors.getStayOnTopButtonColors(context)
                      : MyColors.getNormalButtonColors(context),
                  borderRadius: BorderRadius.circular(8),
                  onPressed: onStayOnTopTap,
                ),
                const SizedBox(width: 3),
                MinimizeWindowButton(
                  colors: MyColors.getNormalButtonColors(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 3),
                isMaximized
                    ? RestoreWindowButton(
                        colors: MyColors.getNormalButtonColors(context),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: ResponsiveUtil.maximizeOrRestore,
                      )
                    : MaximizeWindowButton(
                        colors: MyColors.getNormalButtonColors(context),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: ResponsiveUtil.maximizeOrRestore,
                      ),
                const SizedBox(width: 3),
                CloseWindowButton(
                  colors: MyColors.getCloseButtonColors(context),
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () {
                    if (forceClose) {
                      windowManager.close();
                    } else {
                      if (HiveUtil.getBool(HiveUtil.showTrayKey) &&
                          HiveUtil.getBool(HiveUtil.enableCloseToTrayKey)) {
                        windowManager.hide();
                      } else {
                        windowManager.close();
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

class CustomImageFactory extends WidgetFactory {
  @override
  Widget? buildImageWidget(BuildTree meta, ImageSource src) {
    final url = src.url;
    if (url.startsWith('asset:') ||
        url.startsWith('data:image/') ||
        url.startsWith('file:')) {
      return super.buildImageWidget(meta, src);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.fill,
      placeholder: (_, __) => emptyWidget,
      errorWidget: (_, __, ___) => emptyWidget,
    );
  }
}
