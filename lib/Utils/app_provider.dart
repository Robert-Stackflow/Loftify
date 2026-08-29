import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loftify/Screens/Setting/general_setting_screen.dart';
import 'package:tuple/tuple.dart';

import '../Screens/Navigation/home_screen.dart';
import '../Screens/Navigation/search_screen.dart';
import '../Screens/main_screen.dart';
import '../Screens/panel_screen.dart';
import '../l10n/l10n.dart';
import 'enums.dart';
import 'hive_util.dart';

NavigatorState? get globalNavigatorState => chewieProvider.globalNavigatorState;

BuildContext get rootContext => globalNavigatorState!.context;

GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

MainScreenState? get mainScreenState => mainScreenKey.currentState;

GlobalKey<BasePanelScreenState> panelScreenKey = chewieProvider.panelScreenKey;

PanelScreenState? get panelScreenState =>
    panelScreenKey.currentState as PanelScreenState?;

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

RouteObserver<PageRoute> routeObserver = RouteObserver();

AppProvider appProvider = AppProvider();

class AppProvider with ChangeNotifier {
  AppProvider() {
    Intl.defaultLocale = (_locale ?? resolveSystemAppLocale()).toString();
  }

  bool _pinSettled = HiveUtil.hasGuesturePasswd();

  bool get pinSettled => _pinSettled;

  set pinSettled(bool value) {
    _pinSettled = value;
    notifyListeners();
  }

  Size windowSize = const Size(0, 0);

  String latestVersion = "";

  bool shownShortcutHelp = false;

  String _captchaToken = "";

  String get captchaToken => _captchaToken;

  set captchaToken(String value) {
    _captchaToken = value;
    notifyListeners();
  }

  final FocusNode shortcutFocusNode = FocusNode();

  Map<Type, Action<Intent>> _dynamicShortcuts = {};

  Map<Type, Action<Intent>> get dynamicShortcuts => _dynamicShortcuts;

  set dynamicShortcuts(Map<Type, Action<Intent>> value) {
    _dynamicShortcuts = value;
    notifyListeners();
  }

  bool _enableLandscapeInTablet =
      ChewieHiveUtil.getBool(HiveUtil.enableLandscapeInTabletKey);

  bool get enableLandscapeInTablet => _enableLandscapeInTablet;

  set enableLandscapeInTablet(bool value) {
    _enableLandscapeInTablet = value;
    ChewieHiveUtil.put(HiveUtil.enableLandscapeInTabletKey, value);
    notifyListeners();
  }

  SideBarChoice _sidebarChoice = SideBarChoice.fromString(
      ChewieHiveUtil.getString(HiveUtil.sidebarChoiceKey) ?? "");

  SideBarChoice get sidebarChoice => _sidebarChoice;

  set sidebarChoice(SideBarChoice value) {
    _sidebarChoice = value;
    ChewieHiveUtil.put(HiveUtil.sidebarChoiceKey, value.key);
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
    if (value != _currentFont) {
      _currentFont = value;
      notifyListeners();
    }
  }

  ChewieThemeColorData _lightTheme = HiveUtil.getLightTheme();

  ChewieThemeColorData get lightTheme => _lightTheme;

  set lightTheme(ChewieThemeColorData value) {
    _lightTheme = value;
    chewieProvider.lightTheme = value;
    notifyListeners();
  }

  void setLightTheme(int index) {
    HiveUtil.setLightTheme(index);
    _lightTheme = HiveUtil.getLightTheme();
    chewieProvider.lightTheme = _lightTheme;
    notifyListeners();
  }

  ChewieThemeColorData _darkTheme = HiveUtil.getDarkTheme();

  ChewieThemeColorData get darkTheme => _darkTheme;

  set darkTheme(ChewieThemeColorData value) {
    _darkTheme = value;
    chewieProvider.darkTheme = value;
    notifyListeners();
  }

  void setDarkTheme(int index) {
    HiveUtil.setDarkTheme(index);
    _darkTheme = HiveUtil.getDarkTheme();
    chewieProvider.darkTheme = _darkTheme;
    notifyListeners();
  }

  final List<ChewieThemeColorData> _customLightThemes =
      ChewieHiveUtil.getCustomLightThemes();

  List<ChewieThemeColorData> get customLightThemes => _customLightThemes;

  final List<ChewieThemeColorData> _customDarkThemes =
      ChewieHiveUtil.getCustomDarkThemes();

  List<ChewieThemeColorData> get customDarkThemes => _customDarkThemes;

  void addCustomLightTheme(ChewieThemeColorData theme) {
    _customLightThemes.add(theme);
    ChewieHiveUtil.setCustomLightThemes(_customLightThemes);
    notifyListeners();
  }

  void addCustomDarkTheme(ChewieThemeColorData theme) {
    _customDarkThemes.add(theme);
    ChewieHiveUtil.setCustomDarkThemes(_customDarkThemes);
    notifyListeners();
  }

  void updateCustomLightTheme(int index, ChewieThemeColorData theme) {
    if (index < 0 || index >= _customLightThemes.length) return;
    _customLightThemes[index] = theme;
    ChewieHiveUtil.setCustomLightThemes(_customLightThemes);
    final activeIndex = ChewieHiveUtil.getLightThemeIndex();
    final builtInCount = ChewieThemeColorData.defaultLightThemes.length;
    if (activeIndex == builtInCount + index) {
      lightTheme = ChewieHiveUtil.getLightTheme();
    } else {
      notifyListeners();
    }
  }

  void updateCustomDarkTheme(int index, ChewieThemeColorData theme) {
    if (index < 0 || index >= _customDarkThemes.length) return;
    _customDarkThemes[index] = theme;
    ChewieHiveUtil.setCustomDarkThemes(_customDarkThemes);
    final activeIndex = ChewieHiveUtil.getDarkThemeIndex();
    final builtInCount = ChewieThemeColorData.defaultDarkThemes.length;
    if (activeIndex == builtInCount + index) {
      darkTheme = ChewieHiveUtil.getDarkTheme();
    } else {
      notifyListeners();
    }
  }

  void deleteCustomLightTheme(int index) {
    if (index < 0 || index >= _customLightThemes.length) return;
    _customLightThemes.removeAt(index);
    ChewieHiveUtil.setCustomLightThemes(_customLightThemes);
    final activeIndex = ChewieHiveUtil.getLightThemeIndex();
    final builtInCount = ChewieThemeColorData.defaultLightThemes.length;
    final deletedIndex = builtInCount + index;
    if (activeIndex == deletedIndex) {
      setLightTheme(0);
    } else if (activeIndex > deletedIndex) {
      setLightTheme(activeIndex - 1);
    } else {
      notifyListeners();
    }
  }

  void deleteCustomDarkTheme(int index) {
    if (index < 0 || index >= _customDarkThemes.length) return;
    _customDarkThemes.removeAt(index);
    ChewieHiveUtil.setCustomDarkThemes(_customDarkThemes);
    final activeIndex = ChewieHiveUtil.getDarkThemeIndex();
    final builtInCount = ChewieThemeColorData.defaultDarkThemes.length;
    final deletedIndex = builtInCount + index;
    if (activeIndex == deletedIndex) {
      setDarkTheme(0);
    } else if (activeIndex > deletedIndex) {
      setDarkTheme(activeIndex - 1);
    } else {
      notifyListeners();
    }
  }

  void setLightPrimaryColorOverride(Color? color, int paletteIndex) {
    ChewieHiveUtil.setCustomLightPrimaryColor(color);
    ChewieHiveUtil.setLightThemePrimaryColorIndex(paletteIndex);
    lightTheme = ChewieHiveUtil.getLightTheme();
  }

  void setDarkPrimaryColorOverride(Color? color, int paletteIndex) {
    ChewieHiveUtil.setCustomDarkPrimaryColor(color);
    ChewieHiveUtil.setDarkThemePrimaryColorIndex(paletteIndex);
    darkTheme = ChewieHiveUtil.getDarkTheme();
  }

  Locale? _locale = HiveUtil.getLocale();

  Locale? get locale => _locale;

  set locale(Locale? value) {
    if (value != _locale) {
      _locale = value;
      HiveUtil.setLocale(value);
      Intl.defaultLocale = (value ?? resolveSystemAppLocale()).toString();
      notifyListeners();
    }
  }

  void refreshSystemLocale() {
    if (_locale == null) {
      Intl.defaultLocale = resolveSystemAppLocale().toString();
      notifyListeners();
    }
  }

  void refreshSystemTheme() {
    if (_themeMode == ActiveThemeMode.system) notifyListeners();
  }

  int _fontSize = HiveUtil.getFontSize();

  int get fontSize => _fontSize;

  set fontSize(int value) {
    if (value != _fontSize) {
      _fontSize = value;
      chewieProvider.fontSize = value;
      notifyListeners();
    }
  }

  ActiveThemeMode _themeMode = HiveUtil.getThemeMode();

  ActiveThemeMode get themeMode => _themeMode;

  set themeMode(ActiveThemeMode value) {
    if (value != _themeMode) {
      _themeMode = value;
      chewieProvider.themeMode = value;
      notifyListeners();
    }
  }

  bool _reduceTransparency = ChewieHiveUtil.getBool(
    HiveUtil.reduceTransparencyKey,
  );

  bool get reduceTransparency => _reduceTransparency;

  set reduceTransparency(bool value) {
    if (value == _reduceTransparency) return;
    _reduceTransparency = value;
    ChewieHiveUtil.put(HiveUtil.reduceTransparencyKey, value);
    notifyListeners();
  }

  NavigationBarDisplayStyle _navigationBarDisplayStyle =
      NavigationBarDisplayStyle.fromKey(
    ChewieHiveUtil.getString(
      HiveUtil.navigationBarDisplayStyleKey,
      defaultValue: NavigationBarDisplayStyle.iconOnly.key,
    ),
  );

  NavigationBarDisplayStyle get navigationBarDisplayStyle =>
      _navigationBarDisplayStyle;

  set navigationBarDisplayStyle(NavigationBarDisplayStyle value) {
    if (value == _navigationBarDisplayStyle) return;
    _navigationBarDisplayStyle = value;
    ChewieHiveUtil.put(HiveUtil.navigationBarDisplayStyleKey, value.key);
    notifyListeners();
  }

  List<String> _searchHistoryList =
      ChewieHiveUtil.getStringList(HiveUtil.searchHistoryKey)!;

  List<String> get searchHistoryList => _searchHistoryList;

  set searchHistoryList(List<String> value) {
    if (value != _searchHistoryList) {
      _searchHistoryList = value;
      notifyListeners();
      ChewieHiveUtil.put(HiveUtil.searchHistoryKey, value);
    }
  }

  static String getThemeModeLabel(ActiveThemeMode themeMode) {
    switch (themeMode) {
      case ActiveThemeMode.system:
        return appLocalizations.followSystem;
      case ActiveThemeMode.light:
        return appLocalizations.lightTheme;
      case ActiveThemeMode.dark:
        return appLocalizations.darkTheme;
    }
  }

  static List<Tuple2<String, ActiveThemeMode>> getSupportedThemeMode() {
    return [
      Tuple2(appLocalizations.followSystem, ActiveThemeMode.system),
      Tuple2(appLocalizations.lightTheme, ActiveThemeMode.light),
      Tuple2(appLocalizations.darkTheme, ActiveThemeMode.dark),
    ];
  }

  int _autoLockSeconds = ChewieHiveUtil.getInt(HiveUtil.autoLockSecondsKey);

  int get autoLockSeconds => _autoLockSeconds;

  set autoLockSeconds(int value) {
    if (value != _autoLockSeconds) {
      _autoLockSeconds = value;
      notifyListeners();
      ChewieHiveUtil.put(HiveUtil.autoLockSecondsKey, value);
    }
  }

  static String getAutoLockOptionLabel(int time) {
    var tuples = getAutoLockOptions();
    for (var tuple in tuples) {
      if (tuple.item2 == time) {
        return tuple.item1;
      }
    }
    return appLocalizations.immediatelyLock;
  }

  static List<Tuple2<String, int>> getAutoLockOptions() {
    return [
      Tuple2(appLocalizations.immediatelyLock, 0),
      Tuple2(appLocalizations.after30SecondsLock, 30),
      Tuple2(appLocalizations.after1MinuteLock, 60),
      Tuple2(appLocalizations.after3MinutesLock, 3 * 60),
      Tuple2(appLocalizations.after5MinutesLock, 5 * 60),
      Tuple2(appLocalizations.after10MinutesLock, 10 * 60),
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

  String _token = ChewieHiveUtil.getString(HiveUtil.tokenKey) ?? "";

  String get token => _token;

  set token(String value) {
    if (value != _token) {
      ChewieHiveUtil.put(HiveUtil.tokenKey, value);
      _token = value;
      notifyListeners();
    }
  }
}
