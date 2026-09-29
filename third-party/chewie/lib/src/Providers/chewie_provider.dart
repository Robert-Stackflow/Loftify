import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

ChewieProvider chewieProvider = ChewieProvider();

bool haveMigratedToSupportDirectory = false;

enum ChewieStateViewType { loading, empty, error }

@immutable
class ChewieStateViewConfig {
  const ChewieStateViewConfig({
    required this.type,
    required this.text,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.size = 30,
    this.showText = true,
    this.forceDark = false,
    this.background,
    this.physics,
    this.shrinkWrap = true,
    this.scrollController,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  final ChewieStateViewType type;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final double size;
  final bool showText;
  final bool forceDark;
  final Color? background;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? scrollController;
  final double topPadding;
  final double bottomPadding;
}

typedef ChewieStateWidgetBuilder = Widget Function(
  BuildContext context,
  ChewieStateViewConfig config,
);

class ChewieProvider with ChangeNotifier {
  static const Size defaultWindowSize = Size(1280, 720);
  static const Size minimumWindowSize = Size(800, 640);

  RouteObserver routeObserver = RouteObserver();

  GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey();

  NavigatorState? get globalNavigatorState => globalNavigatorKey.currentState;

  BuildContext get globalNavigatorContext => globalNavigatorKey.currentContext!;

  BuildContext navigatorContextOf(BuildContext context) {
    if (Navigator.maybeOf(context) != null) return context;
    return globalNavigatorState?.context ?? context;
  }

  late BuildContext _rootContext;

  BuildContext get rootContext => _rootContext;

  bool initedRootContext = false;

  void setRootContext(BuildContext context) {
    _rootContext = context;
  }

  void resetRootContext() {
    _rootContext = globalNavigatorContext;
  }

  void initRootContext(BuildContext context) {
    if (!initedRootContext) {
      _rootContext = context;
      initedRootContext = true;
    }
  }

  GlobalKey<BasePanelScreenState> panelScreenKey =
      GlobalKey<BasePanelScreenState>();

  BasePanelScreenState? get panelScreenState => panelScreenKey.currentState;

  String latestVersion = "";

  Size _windowSize = ChewieHiveUtil.getWindowSize();

  Size get windowSize => _windowSize;

  set windowSize(Size value) {
    _windowSize = value;
    ChewieHiveUtil.setWindowSize(value);
    notifyListeners();
  }

  Offset _mousePosition = ChewieHiveUtil.getWindowPosition();

  Offset get mousePosition => _mousePosition;

  set mousePosition(Offset value) {
    _mousePosition = value;
    notifyListeners();
  }

  Offset _windowPosition = Offset.zero;

  Offset get windowPosition => _windowPosition;

  set windowPosition(Offset value) {
    _windowPosition = value;
    ChewieHiveUtil.setWindowPosition(value);
    notifyListeners();
  }

  Widget Function(double size, bool forceDark) loadingWidgetBuilder =
      (size, forceDark) => const Center(child: CircularProgressIndicator());

  /// Optional product-level state renderer.
  ///
  /// The component package retains its standalone fallbacks, while host apps
  /// can provide one semantic visual language for loading, empty and error
  /// states without replacing every call site.
  ChewieStateWidgetBuilder? stateWidgetBuilder;

  bool _enableLandscapeInTablet =
      ChewieHiveUtil.getBool(ChewieHiveUtil.enableLandscapeInTabletKey);

  bool get enableLandscapeInTablet => _enableLandscapeInTablet;

  set enableLandscapeInTablet(bool value) {
    _enableLandscapeInTablet = value;
    ChewieHiveUtil.put(ChewieHiveUtil.enableLandscapeInTabletKey, value);
    notifyListeners();
  }

  ChewieThemeColorData _lightTheme = ChewieHiveUtil.getLightTheme();

  ChewieThemeColorData get lightTheme => _lightTheme;

  set lightTheme(ChewieThemeColorData value) {
    _lightTheme = value;
    notifyListeners();
  }

  ChewieThemeColorData _darkTheme = ChewieHiveUtil.getDarkTheme();

  ChewieThemeColorData get darkTheme => _darkTheme;

  set darkTheme(ChewieThemeColorData value) {
    _darkTheme = value;
    notifyListeners();
  }

  static List<SelectionItemModel<ActiveThemeMode>> getSupportedThemeMode() {
    return [
      SelectionItemModel(
          chewieLocalizations.followSystem, ActiveThemeMode.system),
      SelectionItemModel(chewieLocalizations.lightTheme, ActiveThemeMode.light),
      SelectionItemModel(chewieLocalizations.darkTheme, ActiveThemeMode.dark),
    ];
  }

  int _fontSize = ChewieHiveUtil.getFontSize();

  int get fontSize => _fontSize;

  set fontSize(int value) {
    if (value != _fontSize) {
      _fontSize = value;
      notifyListeners();
      ChewieHiveUtil.setFontSize(value);
    }
  }

  ActiveThemeMode _themeMode = ChewieHiveUtil.getThemeMode();

  ActiveThemeMode get themeMode => _themeMode;

  set themeMode(ActiveThemeMode value) {
    if (value != _themeMode) {
      _themeMode = value;
      notifyListeners();
      ChewieHiveUtil.setThemeMode(value);
    }
  }

  static String getThemeModeLabel(ActiveThemeMode themeMode) {
    switch (themeMode) {
      case ActiveThemeMode.system:
        return chewieLocalizations.followSystem;
      case ActiveThemeMode.light:
        return chewieLocalizations.lightTheme;
      case ActiveThemeMode.dark:
        return chewieLocalizations.darkTheme;
    }
  }

  Brightness? getBrightness() {
    if (_themeMode == ActiveThemeMode.system) {
      return null;
    } else {
      return _themeMode == ActiveThemeMode.light
          ? Brightness.light
          : Brightness.dark;
    }
  }
}

abstract class BasePanelScreenState<T extends StatefulWidget>
    extends BaseDynamicState<T> {
  FutureOr pushPage(Widget page);

  FutureOr popPage();

  void updateStatusBar();

  void refreshScrollControllers();

  void showBottomNavigationBar();

  FutureOr popAll([bool initPage = true]);

  void jumpToPage(int index);
}
