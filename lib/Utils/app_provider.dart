import 'package:flutter/material.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:tuple/tuple.dart';

import '../Models/nav_entry.dart';
import '../Resources/fonts.dart';
import '../Resources/theme_color_data.dart';
import '../generated/l10n.dart';
import 'enums.dart';
import 'hive_util.dart';

GlobalKey<NavigatorState> desktopNavigatorKey = GlobalKey<NavigatorState>();

GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

NavigatorState? get desktopNavigatorState => desktopNavigatorKey.currentState;

NavigatorState? get globalNavigatorState => globalNavigatorKey.currentState;

GlobalKey<DialogWrapperWidgetState> dialogNavigatorKey =
    GlobalKey<DialogWrapperWidgetState>();

DialogWrapperWidgetState? get dialogNavigatorState =>
    dialogNavigatorKey.currentState;

BuildContext get rootContext => globalNavigatorState!.context;

bool get canPopByKey =>
    desktopNavigatorState != null && desktopNavigatorState!.canPop();

RouteObserver<PageRoute> routeObserver = RouteObserver();

AppProvider appProvider = AppProvider();

class AppProvider with ChangeNotifier {
  String _captchaToken = "";

  String get captchaToken => _captchaToken;

  set captchaToken(String value) {
    _captchaToken = value;
    notifyListeners();
  }

  bool _enableLandscapeInTablet =
      HiveUtil.getBool(HiveUtil.enableLandscapeInTabletKey);

  bool get enableLandscapeInTablet => _enableLandscapeInTablet;

  set enableLandscapeInTablet(bool value) {
    _enableLandscapeInTablet = value;
    HiveUtil.put(HiveUtil.enableLandscapeInTabletKey, value).then((value) {
      ResponsiveUtil.restartApp(rootContext);
    });
    notifyListeners();
  }

  bool _canPopByProvider = false;

  bool get canPopByProvider => _canPopByProvider;

  set canPopByProvider(bool value) {
    _canPopByProvider = value;
    notifyListeners();
  }

  CustomFont _currentFont = CustomFont.getCurrentFont();

  CustomFont get currentFont => _currentFont;

  set currentFont(CustomFont value) {
    _currentFont = value;
    notifyListeners();
  }

  ThemeColorData _lightTheme = HiveUtil.getLightTheme();

  ThemeColorData get lightTheme => _lightTheme;

  set lightTheme(ThemeColorData value) {
    _lightTheme = value;
    notifyListeners();
  }

  setLightTheme(int index) {
    HiveUtil.setLightTheme(index);
    _lightTheme = HiveUtil.getLightTheme();
    notifyListeners();
  }

  ThemeColorData _darkTheme = HiveUtil.getDarkTheme();

  ThemeColorData get darkTheme => _darkTheme;

  set darkTheme(ThemeColorData value) {
    _darkTheme = value;
    notifyListeners();
  }

  setDarkTheme(int index) {
    HiveUtil.setDarkTheme(index);
    _darkTheme = HiveUtil.getDarkTheme();
    notifyListeners();
  }

  List<SortableItem> _navItems = HiveUtil.getSortableItems(
      HiveUtil.navItemsKey, SortableItemList.defaultNavItems);

  List<SortableItem> get navItems => _navItems;

  set navItems(List<SortableItem> value) {
    if (value != _navItems) {
      _navItems = value;
      notifyListeners();
      HiveUtil.setSortableItems(HiveUtil.navItemsKey, value);
    }
  }

  Locale? _locale = HiveUtil.getLocale();

  Locale? get locale => _locale;

  set locale(Locale? value) {
    if (value != _locale) {
      _locale = value;
      notifyListeners();
      HiveUtil.setLocale(value);
    }
  }

  int? _fontSize = HiveUtil.getFontSize();

  int? get fontSize => _fontSize;

  set fontSize(int? value) {
    if (value != _fontSize) {
      _fontSize = value;
      notifyListeners();
      HiveUtil.setFontSize(value);
    }
  }

  ActiveThemeMode _themeMode = HiveUtil.getThemeMode();

  ActiveThemeMode get themeMode => _themeMode;

  set themeMode(ActiveThemeMode value) {
    if (value != _themeMode) {
      _themeMode = value;
      notifyListeners();
      HiveUtil.setThemeMode(value);
    }
  }

  List<String> _searchHistoryList =
      HiveUtil.getStringList(HiveUtil.searchHistoryKey)!;

  List<String> get searchHistoryList => _searchHistoryList;

  set searchHistoryList(List<String> value) {
    if (value != _searchHistoryList) {
      _searchHistoryList = value;
      notifyListeners();
      HiveUtil.put(HiveUtil.searchHistoryKey, value);
    }
  }

  static String getThemeModeLabel(ActiveThemeMode themeMode) {
    switch (themeMode) {
      case ActiveThemeMode.system:
        return S.current.followSystem;
      case ActiveThemeMode.light:
        return S.current.lightTheme;
      case ActiveThemeMode.dark:
        return S.current.darkTheme;
    }
  }

  static List<Tuple2<String, ActiveThemeMode>> getSupportedThemeMode() {
    return [
      Tuple2(S.current.followSystem, ActiveThemeMode.system),
      Tuple2(S.current.lightTheme, ActiveThemeMode.light),
      Tuple2(S.current.darkTheme, ActiveThemeMode.dark),
    ];
  }

  int _autoLockTime = HiveUtil.getInt(HiveUtil.autoLockTimeKey);

  int get autoLockTime => _autoLockTime;

  set autoLockTime(int value) {
    if (value != _autoLockTime) {
      _autoLockTime = value;
      notifyListeners();
      HiveUtil.put(HiveUtil.autoLockTimeKey, value);
    }
  }

  static String getAutoLockOptionLabel(int time) {
    if (time == 0)
      return "立即锁定";
    else
      return "处于后台$time分钟后锁定";
  }

  static List<Tuple2<String, int>> getAutoLockOptions() {
    return [
      Tuple2("立即锁定", 0),
      Tuple2("处于后台1分钟后锁定", 1),
      Tuple2("处于后台5分钟后锁定", 5),
      Tuple2("处于后台10分钟后锁定", 10),
    ];
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

  String _token = HiveUtil.getString(HiveUtil.tokenKey) ?? "";

  String get token => _token;

  set token(String value) {
    if (value != _token) {
      HiveUtil.put(HiveUtil.tokenKey, value);
      _token = value;
      notifyListeners();
    }
  }
}
