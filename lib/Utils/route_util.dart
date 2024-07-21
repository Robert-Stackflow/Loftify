import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/responsive_util.dart';

class RouteUtil {
  static pushMaterialRoute(BuildContext context, Widget page) {
    return Navigator.push(
        context, MaterialPageRoute(builder: (context) => page));
  }

  static pushCupertinoRoute(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onThen,
  }) {
    appProvider.canPopByProvider = true;
    if (ResponsiveUtil.isLandscape()) {
      return pushFadeRoute(context, page, onThen: onThen);
    } else {
      return Navigator.push(
              context, CupertinoPageRoute(builder: (context) => page))
          .then(onThen ?? (_) => {});
    }
  }

  static pushDesktopFadeRoute(
    Widget page, {
    bool removeUtil = false,
  }) async {
    if (removeUtil) {
      appProvider.canPopByProvider = false;
      return await desktopNavigatorKey.currentState?.pushAndRemoveUntil(
        getFadeRoute(page),
        (route) => false,
      );
    } else {
      appProvider.canPopByProvider = true;
      return await desktopNavigatorKey.currentState?.push(
        getFadeRoute(page),
      );
    }
  }

  static getFadeRoute(Widget page, {Duration? duration}) {
    return PageRouteBuilder(
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
  }) {
    return Navigator.push(
      context,
      getFadeRoute(page),
    ).then(onThen ?? (_) => {});
  }
}
