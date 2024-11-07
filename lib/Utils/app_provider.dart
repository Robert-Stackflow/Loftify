import 'package:flutter/material.dart';
import 'package:loftify/Screens/Setting/general_setting_screen.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:tuple/tuple.dart';

import '../Resources/fonts.dart';
import '../Resources/theme_color_data.dart';
import '../Screens/Navigation/home_screen.dart';
import '../Screens/Navigation/search_screen.dart';
import '../Screens/main_screen.dart';
import '../Screens/panel_screen.dart';
import '../Widgets/Custom/keyboard_handler.dart';
import '../generated/l10n.dart';
import 'enums.dart';
import 'hive_util.dart';

GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

NavigatorState? get globalNavigatorState => globalNavigatorKey.currentState;

BuildContext get rootContext => globalNavigatorState!.context;

GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

MainScreenState? get mainScreenState => mainScreenKey.currentState;

GlobalKey<PanelScreenState> panelScreenKey = GlobalKey<PanelScreenState>();

PanelScreenState? get panelScreenState => panelScreenKey.currentState;

GlobalKey<SearchScreenState> searchScreenKey = GlobalKey<SearchScreenState>();

SearchScreenState? get searchScreenState => searchScreenKey.currentState;

GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

HomeScreenState? get homeScreenState => homeScreenKey.currentState;

GlobalKey<GeneralSettingScreenState> generalSettingScreenKey =
    GlobalKey<GeneralSettingScreenState>();

GeneralSettingScreenState? get generalSettingScreenState =>
    generalSettingScreenKey.currentState;

GlobalKey<DialogWrapperWidgetState> dialogNavigatorKey =
    GlobalKey<DialogWrapperWidgetState>();

DialogWrapperWidgetState? get dialogNavigatorState =>
    dialogNavigatorKey.currentState;

GlobalKey<KeyboardHandlerState> keyboardHandlerKey =
    GlobalKey<KeyboardHandlerState>();

KeyboardHandlerState? get keyboardHandlerState =>
    keyboardHandlerKey.currentState;

RouteObserver<PageRoute> routeObserver = RouteObserver();

AppProvider appProvider = AppProvider();

class AppProvider with ChangeNotifier {
  Size windowSize = const Size(0, 0);

  String latestVersion = "";

  bool shownShortcutHelp = false;

  String _captchaToken = "";

  String get captchaToken => _captchaToken;

  set captchaToken(String value) {
    _captchaToken = value;
    notifyListeners();
  }

  Map<Type, Action<Intent>> _dynamicShortcuts =
      KeyboardHandlerState.mainScreenShortcuts;

  Map<Type, Action<Intent>> get dynamicShortcuts => _dynamicShortcuts;

  set dynamicShortcuts(Map<Type, Action<Intent>> value) {
    _dynamicShortcuts = value;
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

  SideBarChoice _sidebarChoice = SideBarChoice.fromString(
      HiveUtil.getString(HiveUtil.sidebarChoiceKey) ?? "");

  SideBarChoice get sidebarChoice => _sidebarChoice;

  set sidebarChoice(SideBarChoice value) {
    _sidebarChoice = value;
    HiveUtil.put(HiveUtil.sidebarChoiceKey, value.key);
    notifyListeners();
    panelScreenState?.jumpToPage(_sidebarChoice.index);
  }

  bool _showNavigator = false;

  bool get showPanelNavigator => _showNavigator;

  set showPanelNavigator(bool value) {
    _showNavigator = value;
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

  int _autoLockSeconds = HiveUtil.getInt(HiveUtil.autoLockSecondsKey);

  int get autoLockSeconds => _autoLockSeconds;

  set autoLockSeconds(int value) {
    if (value != _autoLockSeconds) {
      _autoLockSeconds = value;
      notifyListeners();
      HiveUtil.put(HiveUtil.autoLockSecondsKey, value);
    }
  }

  static String getAutoLockOptionLabel(int time) {
    var tuples = getAutoLockOptions();
    for (var tuple in tuples) {
      if (tuple.item2 == time) {
        return tuple.item1;
      }
    }
    return S.current.immediatelyLock;
  }

  static List<Tuple2<String, int>> getAutoLockOptions() {
    return [
      Tuple2(S.current.immediatelyLock, 0),
      Tuple2(S.current.after30SecondsLock, 30),
      Tuple2(S.current.after1MinuteLock, 60),
      Tuple2(S.current.after3MinutesLock, 3 * 60),
      Tuple2(S.current.after5MinutesLock, 5 * 60),
      Tuple2(S.current.after10MinutesLock, 10 * 60),
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
