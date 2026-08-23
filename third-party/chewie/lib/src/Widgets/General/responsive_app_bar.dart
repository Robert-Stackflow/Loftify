import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final bool showBack;
  final IconData leadingIcon;
  final Function()? onTapBack;
  final bool? showBorder;
  final Widget? bottomWidget;
  final double? bottomHeight;
  final Color? backgroundColor;
  final bool centerTitle;
  final double titleLeftMargin;
  final double rightSpacing;
  final List<Widget> actions;
  final List<Widget> landscapeActions;
  @Deprecated('Use landscapeActions instead.')
  final List<Widget> desktopActions;
  final double height;
  final double? borderWidth;
  final BuildContext? context;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const ResponsiveAppBar({
    super.key,
    this.context,
    this.title = "",
    this.titleWidget,
    this.showBack = false,
    this.leadingIcon = Icons.arrow_back_rounded,
    this.onTapBack,
    this.showBorder,
    this.bottomWidget,
    this.bottomHeight,
    this.backgroundColor,
    this.centerTitle = false,
    this.titleLeftMargin = 5,
    this.rightSpacing = 8,
    this.landscapeActions = const [],
    this.desktopActions = const [],
    this.actions = const [],
    this.height = 48,
    this.borderWidth,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = ResponsiveUtil.isLandscapeLayout();
    void handleBack() {
      if (onTapBack != null) {
        onTapBack!();
        return;
      }
      final panelScreenState = chewieProvider.panelScreenState;
      if (panelScreenState != null) {
        panelScreenState.popPage();
        return;
      }
      final navigator = Navigator.maybeOf(context);
      if (navigator?.canPop() ?? false) {
        navigator!.pop();
      }
    }

    final Widget titleContent = Container(
      margin: EdgeInsets.only(left: titleLeftMargin),
      child: titleWidget ?? Text(title, style: ChewieTheme.titleLarge),
    );

    final PreferredSize topWidget = PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Container(
        key: const ValueKey('responsive-app-bar-surface'),
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? ChewieTheme.appBarBackgroundColor,
        ),
        child: isLandscape
            ? Stack(
                children: [
                  ResponsiveUtil.selectByPlatform(
                      desktop: const WindowMoveHandle()),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (showBack)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: ToolButton(
                              context: context,
                              onPressed: handleBack,
                              buttonSize: const Size(32, 32),
                              iconBuilder: (_) => Icon(
                                leadingIcon == Icons.arrow_back_rounded
                                    ? LucideIcons.arrowLeft
                                    : leadingIcon,
                                size: 20,
                              ),
                            ),
                          ),
                        titleContent,
                        const Spacer(),
                        ...[
                          ...desktopActions,
                          ...landscapeActions,
                          const SizedBox(width: 44),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            : AppBarWrapper(
                primary: false,
                centerTitle: centerTitle,
                leadingIcon: showBack ? leadingIcon : null,
                onLeadingTap: handleBack,
                backgroundColor:
                    backgroundColor ?? ChewieTheme.scaffoldBackgroundColor,
                systemOverlayStyle: systemOverlayStyle,
                titleLeftMargin: titleLeftMargin,
                rightSpacing: rightSpacing,
                title: titleWidget != null
                    ? Container(
                        constraints: const BoxConstraints(maxHeight: 60),
                        child: titleWidget,
                      )
                    : Text(
                        title,
                        style:
                            ChewieTheme.titleMedium.apply(fontWeightDelta: 2),
                      ),
                actions: actions,
              ),
      ),
    );

    final effectiveBackgroundColor = backgroundColor ??
        (isLandscape
            ? ChewieTheme.appBarBackgroundColor
            : ChewieTheme.scaffoldBackgroundColor);
    final effectiveSystemOverlayStyle = systemOverlayStyle ??
        AppBarWrapper.systemUiOverlayStyleForColor(
          context,
          effectiveBackgroundColor,
        );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: effectiveSystemOverlayStyle,
      child: ColoredBox(
        color: effectiveBackgroundColor,
        child: SafeArea(
          top: ResponsiveUtil.isMobile(),
          child: bottomWidget != null && bottomHeight != null
              ? PreferredSize(
                  preferredSize: Size.fromHeight(height + bottomHeight!),
                  child: Column(
                    children: [
                      topWidget,
                      bottomWidget!,
                    ],
                  ),
                )
              : topWidget,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => bottomWidget != null && bottomHeight != null
      ? Size.fromHeight(height + bottomHeight!)
      : Size.fromHeight(height);
}
