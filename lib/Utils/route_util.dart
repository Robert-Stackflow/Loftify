import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/responsive_util.dart';

class RouteUtil {
  static getRootContext() {
    return globalNavigatorKey.currentState?.context;
  }

  static pushMaterialRoute(BuildContext context, Widget page) {
    return Navigator.push(
        context, MaterialPageRoute(builder: (context) => page));
  }

  static pushCupertinoRoute(BuildContext context, Widget page) {
    appProvider.desktopCanpop = true;
    if (ResponsiveUtil.isLandscape()) {
      return pushFadeRoute(context, page);
    } else {
      return Navigator.push(
          context, CupertinoPageRoute(builder: (context) => page));
    }
  }

  static pushDesktopFadeRoute(Widget page) async {
    appProvider.desktopCanpop = true;
    return await desktopNavigatorKey.currentState?.push(
      getFadeRoute(page),
    );
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

  static pushFadeRoute(BuildContext context, Widget page) {
    return Navigator.push(
      context,
      getFadeRoute(page),
    );
  }
}
