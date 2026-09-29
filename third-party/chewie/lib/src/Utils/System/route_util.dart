import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class RouteUtil {
  static void pushRootPage(Widget page) {
    Navigator.of(chewieProvider.globalNavigatorContext)
        .pushAndRemoveUntil(RouteUtil.getFadeRoute(page), (_) => false);
  }

  static pushMaterialRoute(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onThen,
    bool popAll = false,
  }) {
    final route = MaterialPageRoute(builder: (context) => page);
    final future = popAll
        ? Navigator.pushAndRemoveUntil(context, route, (_) => false)
        : Navigator.push(context, route);
    return future.then(onThen ?? (_) => {});
  }

  static pushCupertinoRoute(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onThen,
    bool popAll = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ResponsiveUtil.isLandscapeLayout()) {
        pushFadeRoute(context, page, onThen: onThen);
      } else {
        if (popAll) {
          Navigator.pushAndRemoveUntil(
              context,
              CustomCupertinoPageRoute(builder: (context) => page),
              (_) => false).then(onThen ?? (_) => {});
        } else {
          Navigator.push(
                  context, CustomCupertinoPageRoute(builder: (context) => page))
              .then(onThen ?? (_) => {});
        }
      }
    });
  }

  static pushPanelCupertinoRoute(BuildContext context, Widget page) {
    final panelScreenState = chewieProvider.panelScreenState;
    if (panelScreenState != null) {
      return panelScreenState.pushPage(page);
    }
    return pushCupertinoRoute(context, page);
  }

  static getFadeRoute(
    Widget page, {
    Duration? duration,
    bool opaque = true,
  }) {
    return PageRouteBuilder(
      opaque: opaque,
      barrierColor: opaque ? null : Colors.transparent,
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation secondaryAnimation) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: page,
        );
      },
    );
  }

  static pushFadeRoute(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onThen,
    bool popAll = false,
    bool opaque = true,
  }) {
    final route = getFadeRoute(page, opaque: opaque);
    final future = popAll
        ? Navigator.pushAndRemoveUntil(context, route, (_) => false)
        : Navigator.push(context, route);
    return future.then(onThen ?? (_) => {});
  }

  static pushDialogRoute(
    BuildContext context,
    Widget page, {
    bool barrierDismissible = true,
    bool showClose = true,
    bool fullScreen = false,
    double? preferMinWidth,
    double? preferMinHeight,
    Function(dynamic)? onThen,
    bool useFade = false,
    bool popAll = false,
    bool animation = true,
    bool opaque = true,
  }) {
    if (ResponsiveUtil.isLandscapeLayout()) {
      if (DialogNavigatorHelper.isMounted()) {
        DialogNavigatorHelper.pushPage(page);
      } else {
        DialogBuilder.showPageDialog(
          context,
          child: page,
          barrierDismissible: barrierDismissible,
          showCloseButton: showClose,
          fullScreen: fullScreen,
          onThen: onThen,
          preferMinWidth: preferMinWidth,
          preferMinHeight: preferMinHeight,
          useAnimation: animation,
        );
      }
    } else {
      if (useFade) {
        pushFadeRoute(
          context,
          page,
          onThen: onThen,
          popAll: popAll,
          opaque: opaque,
        );
      } else {
        pushCupertinoRoute(context, page, onThen: onThen, popAll: popAll);
      }
    }
  }
}
