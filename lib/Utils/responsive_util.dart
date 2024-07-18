import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Utils/route_util.dart';
import 'package:restart_app/restart_app.dart';
import 'package:window_manager/window_manager.dart';

import '../Providers/provider_manager.dart';
import '../Screens/main_screen.dart';

class ResponsiveUtil {
  static Future<void> restartApp(BuildContext context) async {
    if (ResponsiveUtil.isDesktop()) {
    } else {
      Restart.restartApp();
    }
  }

  static Future<void> returnToMainScreen(BuildContext context) async {
    if (ResponsiveUtil.isDesktop()) {
      ProviderManager.globalProvider.desktopCanpop = false;
      ProviderManager.desktopNavigatorKey = GlobalKey<NavigatorState>();
      ProviderManager.globalNavigatorKey.currentState?.pushAndRemoveUntil(
        RouteUtil.getFadeRoute(const MainScreen(), duration: Duration.zero),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => const MainScreen()),
          (route) => false);
    }
  }

  static Future<void> maximizeOrRestore() async {
    if (await windowManager.isMaximized()) {
      windowManager.restore();
    } else {
      windowManager.maximize();
    }
  }

  static bool isAndroid() {
    return Platform.isAndroid;
  }

  static bool isIOS() {
    return Platform.isIOS;
  }

  static bool isWindows() {
    return Platform.isWindows;
  }

  static bool isMacOS() {
    return Platform.isMacOS;
  }

  static bool isWeb() {
    return kIsWeb;
  }

  static bool isMobile() {
    return !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  }

  static bool isDesktop() {
    return !kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
  }

  static checkSizeCondition() {
    double shortestThreshold = 600;
    double longestThreshold = 900;
    double longestSide =
        MediaQuery.sizeOf(RouteUtil.getRootContext()).longestSide;
    double shortestSide =
        MediaQuery.sizeOf(RouteUtil.getRootContext()).shortestSide;
    bool sizeCondition =
        longestSide >= longestThreshold && shortestSide >= shortestThreshold;
    if (!sizeCondition) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  static bool isTablet() {
    double shortestThreshold = 600;
    double longestThreshold = 900;
    double longestSide =
        MediaQuery.sizeOf(RouteUtil.getRootContext()).longestSide;
    double shortestSide =
        MediaQuery.sizeOf(RouteUtil.getRootContext()).shortestSide;
    Orientation orientation =
        MediaQuery.of(RouteUtil.getRootContext()).orientation;
    bool sizeCondition =
        longestSide >= longestThreshold && shortestSide >= shortestThreshold;
    return !kIsWeb &&
        (Platform.isIOS || Platform.isAndroid) &&
        sizeCondition &&
        orientation == Orientation.portrait;
  }

  static bool isLandscape() {
    return isWeb() || isDesktop() || isTablet();
  }
}
