import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../Models/nav_entry.dart';
import '../Utils/hive_util.dart';
import '../generated/l10n.dart';

enum ActiveThemeMode {
  system,
  light,
  dark,
}

class GlobalProvider with ChangeNotifier {
  String _captchaToken = "";

  String get captchaToken => _captchaToken;

  set captchaToken(String value) {
    _captchaToken = value;
    notifyListeners();
  }

  ThemeData _lightTheme = HiveUtil.getLightTheme().toThemeData();

  ThemeData get lightTheme => _lightTheme;

  setLightTheme(int index) {
    HiveUtil.setLightTheme(index);
    _lightTheme = HiveUtil.getLightTheme().toThemeData();
    notifyListeners();
  }

  ThemeData _darkTheme = HiveUtil.getDarkTheme().toThemeData();

  ThemeData get darkTheme => _darkTheme;

  setDarkTheme(int index) {
    HiveUtil.setDarkTheme(index);
    _darkTheme = HiveUtil.getDarkTheme().toThemeData();
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
      HiveUtil.getStringList(key: HiveUtil.searchHistoryKey, defaultValue: [])!;

  List<String> get searchHistoryList => _searchHistoryList;

  set searchHistoryList(List<String> value) {
    if (value != _searchHistoryList) {
      _searchHistoryList = value;
      notifyListeners();
      HiveUtil.put(key: HiveUtil.searchHistoryKey, value: value);
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

  int _autoLockTime = HiveUtil.getInt(key: HiveUtil.autoLockTimeKey);

  int get autoLockTime => _autoLockTime;

  set autoLockTime(int value) {
    if (value != _autoLockTime) {
      _autoLockTime = value;
      notifyListeners();
      HiveUtil.put(key: HiveUtil.autoLockTimeKey, value: value);
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

  String _token = HiveUtil.getString(key: HiveUtil.tokenKey) ?? "";

  String get token => _token;

  set token(String value) {
    if (value != _token) {
      HiveUtil.put(key: HiveUtil.tokenKey, value: value);
      _token = value;
      notifyListeners();
    }
  }
}
