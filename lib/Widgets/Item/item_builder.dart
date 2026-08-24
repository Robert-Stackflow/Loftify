import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Screens/Post/tag_detail_screen.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Utils/utils.dart';
import '../loftify_icons.dart';

enum TailingType { none, clear, password, icon, text, widget }

class ItemBuilder {
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
    IconData leading = LoftifyIcons.home,
    required String title,
    String tip = "",
    String description = "",
    Function()? onTap,
    double padding = 18,
    double trailingLeftMargin = 5,
    bool dividerPadding = true,
    IconData trailing = LoftifyIcons.next,
  }) {
    return EntryItem(
      context: context,
      radius: radius,
      roundTop: roundTop,
      roundBottom: roundBottom,
      showLeading: showLeading,
      showTrailing: showTrailing,
      backgroundColor: backgroundColor,
      titleColor: titleColor,
      descriptionColor: descriptionColor,
      crossAxisAlignment: crossAxisAlignment,
      leading: leading,
      title: title,
      tip: tip,
      description: description,
      onTap: onTap,
      paddingVertical: padding,
      trailingLeftMargin: trailingLeftMargin,
      dividerPadding: dividerPadding,
      trailing: trailing,
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
    return ContainerItem(
      radius: radius,
      roundTop: topRadius,
      roundBottom: bottomRadius,
      backgroundColor: backgroundColor,
      border: border,
      child: child,
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
    return FontItem(
      font: font,
      currentFont: currentFont,
      onChanged: onChanged,
      onDelete: onDelete,
      showDelete: showDelete,
      width: width,
      height: height,
    );
  }

  static Widget buildEmptyFontItem({
    required BuildContext context,
    required Function()? onTap,
    double width = 110,
    double height = 160,
  }) {
    return EmptyFontItem(onTap: onTap, width: width, height: height);
  }

  static Widget buildThemeItem({
    required ChewieThemeColorData themeColorData,
    required int index,
    required int groupIndex,
    required BuildContext context,
    required Function(int?)? onChanged,
  }) {
    return ThemeItem(
      themeColorData: themeColorData,
      index: index,
      groupIndex: groupIndex,
      onChanged: onChanged,
    );
  }

  static Widget buildEmptyThemeItem({
    required BuildContext context,
    required Function()? onTap,
  }) {
    return EmptyThemeItem(onTap: onTap);
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

  static Tab buildAnimatedTab(
    BuildContext context, {
    required bool selected,
    required String text,
    TabController? controller,
    int? tabIndex,
    bool normalUserBold = false,
    bool sameFontSize = false,
    double fontSizeDelta = 0,
  }) {
    TextStyle normalStyle = Theme.of(context).textTheme.titleLarge!.apply(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSizeDelta: fontSizeDelta - (sameFontSize ? 0 : 1),
          fontWeightDelta: normalUserBold ? 0 : -2,
        );
    TextStyle selectedStyle = Theme.of(context).textTheme.titleLarge!.apply(
          fontSizeDelta: fontSizeDelta + (sameFontSize ? 0 : 1),
        );
    Widget buildLabel() => Container(
          alignment: Alignment.center,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            textAlign: TextAlign.center,
          ),
        );
    final animation = controller?.animation;
    return Tab(
      child: animation != null && tabIndex != null
          ? AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final proximity =
                    (1 - (animation.value - tabIndex).abs()).clamp(0.0, 1.0);
                final progress = Curves.easeOutCubic.transform(proximity);
                return DefaultTextStyle(
                  style: TextStyle.lerp(
                    normalStyle,
                    selectedStyle,
                    progress,
                  )!,
                  child: buildLabel(),
                );
              },
            )
          : AnimatedDefaultTextStyle(
              style: selected ? selectedStyle : normalStyle,
              duration: const Duration(milliseconds: 100),
              child: buildLabel(),
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
        return CircleIconButton(icon: icon, onTap: onTap);
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
          onPressed: onTap,
          padding: const EdgeInsets.all(7),
        );
      },
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
          if (icon != null && StringUtil.isNotEmpty(text))
            const SizedBox(width: 3),
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
    return ClickableGestureDetector(
      onTap: onTap,
      onLongPress: copyable
          ? () => ChewieUtils.copy(context, text, toastText: toastText)
          : null,
      child: child,
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
    bool hasAvatarBox = StringUtil.isNotEmpty(avatarBoxImageUrl);
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
            ? StringUtil.getRandomString()
            : heroTag;
    String avatarBoxTag =
        hasAvatarBox && showDetailMode == ShowDetailMode.avatarBox
            ? heroTag
            : StringUtil.getRandomString();
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
          : ClickableGestureDetector(
              clickable: clickable,
              onTap: showDetailMode != ShowDetailMode.not
                  ? () {
                      RouteUtil.pushDialogRoute(
                        context,
                        showClose: false,
                        fullScreen: true,
                        useFade: true,
                        opaque: false,
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
                              child: ChewieItemBuilder.buildCachedImage(
                                context: context,
                                imageUrl: imageUrl,
                                width: size,
                                showLoading: showLoading,
                                height: size,
                                fit: BoxFit.cover,
                                simpleError: true,
                              ),
                            ),
                          ),
                        ),
                        Hero(
                          tag: avatarBoxTag,
                          child: ChewieItemBuilder.buildCachedImage(
                            context: context,
                            imageUrl: avatarBoxImageUrl!,
                            width: size + avatarBoxDeltaSize,
                            showLoading: false,
                            placeholderBackground: Colors.transparent,
                            topPadding: 0,
                            bottomPadding: 0,
                            height: size + avatarBoxDeltaSize,
                            fit: BoxFit.contain,
                            simpleError: true,
                          ),
                        ),
                      ],
                    )
                  : ClipOval(
                      child: ChewieItemBuilder.buildCachedImage(
                        context: context,
                        imageUrl: tagUrl,
                        width: size,
                        showLoading: showLoading,
                        height: size,
                        fit: BoxFit.cover,
                        simpleError: true,
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
    String str = StringUtil.isNotEmpty(shownTag) ? shownTag! : tag;
    return GestureDetector(
      onTap: () {
        if (!tagType.preventJump && jumpToTag) {
          panelScreenState?.pushPage(TagDetailScreen(tag: tag));
        }
        onTap?.call();
      },
      child: ClickableWrapper(
        clickable: (!tagType.preventJump && jumpToTag) || onTap != null,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tagType != TagType.normal
                ? ChewieColors.getHotTagBackground(context)
                : backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tagType == TagType.hot && showIcon)
                ChewieIcon(
                  LoftifyIcons.hot,
                  size: 14,
                  color: ChewieColors.getHotTagTextColor(context),
                ),
              if (tagType == TagType.hot && showIcon) const SizedBox(width: 2),
              if (tagType == TagType.egg && showIcon)
                ChewieIcon(
                  LoftifyIcons.egg,
                  size: 15,
                  color: ChewieColors.getHotTagTextColor(context),
                ),
              if (tagType == TagType.catutu && showIcon)
                Container(
                  margin: const EdgeInsets.only(right: 2),
                  child: ChewieIcon(
                    LoftifyIcons.magic,
                    size: 15,
                    color: ChewieColors.getHotTagTextColor(context),
                  ),
                ),
              Text(
                ((tagType == TagType.normal || !showIcon) && showTagLabel)
                    ? "#$str"
                    : str,
                style: tagType != TagType.normal
                    ? Theme.of(context).textTheme.labelMedium?.apply(
                          color: color ?? ChewieColors.hotTagTextColor,
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
                ChewieIcon(
                  LoftifyIcons.next,
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
                      ChewieItemBuilder.editTextContextMenuBuilder(
                          contextMenuContext, details,
                          context: context),
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  style: Theme.of(context).textTheme.titleSmall?.apply(
                        fontSizeDelta: hintFontSizeDelta,
                      ),
                  decoration: InputDecoration(
                    filled: false,
                    contentPadding: const EdgeInsets.only(left: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
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
          ChewieIconButton(
            icon: LoftifyIcons.search,
            tooltip: hintText.toString(),
            onPressed: () => onSubmitted(controller?.text),
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
        right: StringUtil.isNotEmpty(suffixText) ? 8 : 16,
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
            ChewieIconButton(
              icon: icon,
              iconSize: 18,
              foregroundColor: Theme.of(context).textTheme.labelSmall?.color,
              onPressed: onTap,
            ),
          if (StringUtil.isNotEmpty(suffixText))
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Text(
                    suffixText!,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  ChewieIcon(
                    LoftifyIcons.next,
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
    Map countWithScale = NumberUtil.formatCountToMap(count ?? 0);
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
    return ClickableWrapper(
      clickable: onTap != null,
      child: GestureDetector(
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
}
