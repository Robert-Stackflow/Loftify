import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Providers/provider_manager.dart';
import 'package:loftify/Utils/iprint.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Utils/utils.dart';

class RouteUtil {
  static getRootContext(){
    return ProviderManager.globalNavigatorKey.currentState?.context;
  }

  static pushMaterialRoute(BuildContext context, Widget page) {
    return Navigator.push(
        context, MaterialPageRoute(builder: (context) => page));
  }

  static pushCupertinoRoute(BuildContext context, Widget page) {
    ProviderManager.globalProvider.desktopCanpop = true;
    if (ResponsiveUtil.isLandscape()) {
      return pushFadeRoute(context, page);
    } else {
      return Navigator.push(
          context, CupertinoPageRoute(builder: (context) => page));
    }
  }

  static pushDesktopFadeRoute(
    Widget page, {
    bool removeUtil = false,
  }) async {
    if (removeUtil) {
      ProviderManager.globalProvider.desktopCanpop = false;
      return await ProviderManager.desktopNavigatorKey.currentState
          ?.pushAndRemoveUntil(
        getFadeRoute(page),
        (route) {
          if (Utils.isNotEmpty(route.settings.name) &&
              route.settings.name!.startsWith("/nav")) {
            IPrint.debug("text");
            return true;
          }
          return false;
        },
      );
    } else {
      ProviderManager.globalProvider.desktopCanpop = true;
      return await ProviderManager.desktopNavigatorKey.currentState?.push(
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

  static pushFadeRoute(BuildContext context, Widget page) {
    return Navigator.push(
      context,
      getFadeRoute(page),
    );
  }
}
