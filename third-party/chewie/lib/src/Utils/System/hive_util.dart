import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class ChewieHiveUtil {
  //HiveBox
  static const String settingsBox = "settings";

  //General
  static const String localeKey = "locale";
  static const String sidebarChoiceKey = "sidebarChoice";
  static const String recordWindowStateKey = "recordWindowState";
  static const String windowSizeKey = "windowSize";
  static const String windowPositionKey = "windowPosition";
  static const String showTrayKey = "showTray";
  static const String launchAtStartupKey = "launchAtStartup";
  static const String enableCloseToTrayKey = "enableCloseToTray";
  static const String enableCloseNoticeKey = "enableCloseNotice";
  static const String autoCheckUpdateKey = "autoCheckUpdate";
  static const String inappWebviewKey = "inappWebview";

  //Appearance
  static const String enableLandscapeInTabletKey = "enableLandscapeInTablet";
  static const String fontFamilyKey = "fontFamily";
  static const String fontSizeKey = "fontSize";
  static const String customFontsKey = "customFonts";
  static const String lightThemeIndexKey = "lightThemeIndex";
  static const String darkThemeIndexKey = "darkThemeIndex";
  static const String lightThemePrimaryColorIndexKey =
      "lightThemePrimaryColorIndex";
  static const String darkThemePrimaryColorIndexKey =
      "darkThemePrimaryColorIndex";
  static const String customLightThemePrimaryColorKey =
      "customLightThemePrimaryColor";
  static const String customDarkThemePrimaryColorKey =
      "customDarkThemePrimaryColor";
  static const String customLightThemeListKey = "customLightThemeList";
  static const String customDarkThemeListKey = "customDarkThemeListKey";
  static const String themeModeKey = "themeMode";

  //image
  static const String followMainColorKey = "followMainColor";
  static const String savePathKey = "savePaths";

  static const String enableSafeModeKey = "enableSafeMode";

  //System
  static const String firstLoginKey = "firstLogin";
  static const String refreshRateKey = "refreshRate";
  static const String haveShownQQGroupDialogKey = "haveShownQQGroupDialog";
  static const String proxyConfigKey = "proxyConfig";

  static const String haveMigratedToSupportDirectoryKey =
      "haveMigratedToSupportDirectory";

  static initConfig() async {
    await ChewieHiveUtil.put(
        ChewieHiveUtil.enableSafeModeKey, defaultEnableSafeMode);
    ChewieHiveUtil.put(ChewieHiveUtil.followMainColorKey, true);
    ChewieHiveUtil.put(ChewieHiveUtil.inappWebviewKey, true);
    ChewieHiveUtil.put(ChewieHiveUtil.recordWindowStateKey, true);
  }

  static initBox() async {
    await Hive.openBox(
      ChewieHiveUtil.settingsBox,
      path: await FileUtil.getApplicationDir(),
    );
  }

  static void setWindowSize(Size size) {
    ChewieHiveUtil.put(
        ChewieHiveUtil.windowSizeKey, "${size.width},${size.height}");
  }

  static Size getWindowSize() {
    if (!ChewieHiveUtil.getBool(ChewieHiveUtil.recordWindowStateKey)) {
      return ChewieProvider.defaultWindowSize;
    }
    String? size = ChewieHiveUtil.getString(ChewieHiveUtil.windowSizeKey);
    if (size == null || size.isEmpty) {
      return ChewieProvider.defaultWindowSize;
    }
    try {
      List<String> list = size.split(",");
      return Size(double.parse(list[0]), double.parse(list[1]));
    } catch (e, t) {
      ILogger.error("Failed to get window size", e, t);
      return ChewieProvider.defaultWindowSize;
    }
  }

  static void setWindowPosition(Offset offset) {
    ChewieHiveUtil.put(
        ChewieHiveUtil.windowPositionKey, "${offset.dx},${offset.dy}");
  }

  static Offset getWindowPosition() {
    if (!ChewieHiveUtil.getBool(ChewieHiveUtil.recordWindowStateKey)) {
      return Offset.zero;
    }
    String? position =
        ChewieHiveUtil.getString(ChewieHiveUtil.windowPositionKey);
    if (position == null || position.isEmpty) {
      return Offset.zero;
    }
    try {
      List<String> list = position.split(",");
      return Offset(double.parse(list[0]), double.parse(list[1]));
    } catch (e, t) {
      ILogger.error("Failed to get window position", e, t);
      return Offset.zero;
    }
  }

  static void setCustomFonts(List<CustomFont> fonts) {
    ChewieHiveUtil.put(ChewieHiveUtil.customFontsKey,
        jsonEncode(fonts.map((e) => e.toJson()).toList()));
  }

  static List<CustomFont> getCustomFonts() {
    String? json = ChewieHiveUtil.getString(ChewieHiveUtil.customFontsKey);
    if (json == null || json.isEmpty) {
      return [];
    } else {
      List<dynamic> list = jsonDecode(json);
      return list.map((e) => CustomFont.fromJson(e)).toList();
    }
  }

  static bool isFirstLogin() {
    if (getBool(firstLoginKey, defaultValue: true) == true) return true;
    return false;
  }

  static void setFirstLogin() {
    ChewieHiveUtil.put(firstLoginKey, false);
  }

  static Locale? stringToLocale(String? localeString) {
    if (localeString == null || localeString.isEmpty) {
      return null;
    }
    var splitted = localeString.split('_');
    if (splitted.length > 1) {
      return Locale(splitted[0], splitted[1]);
    } else {
      return Locale(localeString);
    }
  }

  static Locale? getLocale() {
    return stringToLocale(ChewieHiveUtil.getString(ChewieHiveUtil.localeKey));
  }

  static void setLocale(Locale? locale) {
    if (locale == null) {
      ChewieHiveUtil.delete(ChewieHiveUtil.localeKey);
    } else {
      ChewieHiveUtil.put(ChewieHiveUtil.localeKey, locale.toString());
    }
  }

  static int getFontSize() {
    return ChewieHiveUtil.getInt(ChewieHiveUtil.fontSizeKey, defaultValue: 2);
  }

  static void setFontSize(int fontSize) {
    ChewieHiveUtil.put(ChewieHiveUtil.fontSizeKey, fontSize);
  }

  static ActiveThemeMode getThemeMode() {
    return ActiveThemeMode
        .values[ChewieHiveUtil.getInt(ChewieHiveUtil.themeModeKey)];
  }

  static void setThemeMode(ActiveThemeMode themeMode) {
    ChewieHiveUtil.put(ChewieHiveUtil.themeModeKey, themeMode.index);
  }

  static int getLightThemeIndex() {
    int index = ChewieHiveUtil.getInt(ChewieHiveUtil.lightThemeIndexKey,
        defaultValue: 0);
    if (index >= ChewieThemeColorData.defaultLightThemes.length) {
      String? json =
          ChewieHiveUtil.getString(ChewieHiveUtil.customLightThemeListKey);
      if (json == null || json.isEmpty) {
        setLightTheme(0);
        return 0;
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index >=
            ChewieThemeColorData.defaultLightThemes.length + list.length) {
          setLightTheme(0);
          return 0;
        } else {
          return index;
        }
      }
    } else {
      return ChewieUtils.patchEnum(
          index, ChewieThemeColorData.defaultLightThemes.length);
    }
  }

  static int getDarkThemeIndex() {
    int index = ChewieHiveUtil.getInt(ChewieHiveUtil.darkThemeIndexKey,
        defaultValue: 0);
    if (index >= ChewieThemeColorData.defaultDarkThemes.length) {
      String? json =
          ChewieHiveUtil.getString(ChewieHiveUtil.customDarkThemeListKey);
      if (json == null || json.isEmpty) {
        setDarkTheme(0);
        return 0;
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index >=
            ChewieThemeColorData.defaultDarkThemes.length + list.length) {
          setDarkTheme(0);
          return 0;
        } else {
          return index;
        }
      }
    } else {
      return ChewieUtils.patchEnum(
          index, ChewieThemeColorData.defaultDarkThemes.length);
    }
  }

  static ChewieThemeColorData _applyPrimaryColorOverride(
      ChewieThemeColorData theme, bool isDark) {
    final key = isDark
        ? customDarkThemePrimaryColorKey
        : customLightThemePrimaryColorKey;
    String? hex = ChewieHiveUtil.getString(key, autoCreate: false);
    if (hex == null || hex.isEmpty) return theme;
    final color = HexColor.fromHex(hex);
    // Flutter's normalized Color channels previously got serialized with
    // `toInt()`, producing values such as #01010000. Those legacy values are
    // unrecoverable, so discard the broken override and restore the selected
    // theme's own accent instead of rendering an almost transparent UI.
    if ((color.toARGB32() >>> 24) <= 1) {
      ChewieHiveUtil.delete(key);
      if (isDark) {
        setDarkThemePrimaryColorIndex(0);
      } else {
        setLightThemePrimaryColorIndex(0);
      }
      return theme;
    }
    return theme.copyWith(
      primaryColor: color,
      indicatorColor: color,
      cursorColor: color,
      textSelectionColor: color.withAlpha(70),
      textSelectionHandleColor: color,
      buttonPrimaryColor: color,
    );
  }

  static ChewieThemeColorData getLightTheme() {
    int index = ChewieHiveUtil.getInt(ChewieHiveUtil.lightThemeIndexKey,
        defaultValue: 0);
    ChewieThemeColorData theme;
    if (index >= ChewieThemeColorData.defaultLightThemes.length) {
      String? json =
          ChewieHiveUtil.getString(ChewieHiveUtil.customLightThemeListKey);
      if (json == null || json.isEmpty) {
        setLightTheme(0);
        theme = ChewieThemeColorData.defaultLightThemes[0];
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index >=
            ChewieThemeColorData.defaultLightThemes.length + list.length) {
          setLightTheme(0);
          theme = ChewieThemeColorData.defaultLightThemes[0];
        } else {
          theme = ChewieThemeColorData.fromJson(
              list[index - ChewieThemeColorData.defaultLightThemes.length]);
        }
      }
    } else {
      theme = ChewieThemeColorData.defaultLightThemes[ChewieUtils.patchEnum(
          index, ChewieThemeColorData.defaultLightThemes.length)];
    }
    return _applyPrimaryColorOverride(theme, false);
  }

  static ChewieThemeColorData getDarkTheme() {
    int index = ChewieHiveUtil.getInt(ChewieHiveUtil.darkThemeIndexKey,
        defaultValue: 0);
    ChewieThemeColorData theme;
    if (index >= ChewieThemeColorData.defaultDarkThemes.length) {
      String? json =
          ChewieHiveUtil.getString(ChewieHiveUtil.customDarkThemeListKey);
      if (json == null || json.isEmpty) {
        setDarkTheme(0);
        theme = ChewieThemeColorData.defaultDarkThemes[0];
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index >=
            ChewieThemeColorData.defaultDarkThemes.length + list.length) {
          setDarkTheme(0);
          theme = ChewieThemeColorData.defaultDarkThemes[0];
        } else {
          theme = ChewieThemeColorData.fromJson(
              list[index - ChewieThemeColorData.defaultDarkThemes.length]);
        }
      }
    } else {
      theme = ChewieThemeColorData.defaultDarkThemes[ChewieUtils.patchEnum(
          index, ChewieThemeColorData.defaultDarkThemes.length)];
    }
    return _applyPrimaryColorOverride(theme, true);
  }

  static void setLightTheme(int index) =>
      ChewieHiveUtil.put(ChewieHiveUtil.lightThemeIndexKey, index);

  static void setDarkTheme(int index) =>
      ChewieHiveUtil.put(ChewieHiveUtil.darkThemeIndexKey, index);

  static List<ChewieThemeColorData> getCustomLightThemes() {
    String? json =
        ChewieHiveUtil.getString(ChewieHiveUtil.customLightThemeListKey);
    if (json == null || json.isEmpty) return [];
    List<dynamic> list = jsonDecode(json);
    return list.map((e) => ChewieThemeColorData.fromJson(e)).toList();
  }

  static List<ChewieThemeColorData> getCustomDarkThemes() {
    String? json =
        ChewieHiveUtil.getString(ChewieHiveUtil.customDarkThemeListKey);
    if (json == null || json.isEmpty) return [];
    List<dynamic> list = jsonDecode(json);
    return list.map((e) => ChewieThemeColorData.fromJson(e)).toList();
  }

  static void setCustomLightThemes(List<ChewieThemeColorData> themes) {
    ChewieHiveUtil.put(ChewieHiveUtil.customLightThemeListKey,
        jsonEncode(themes.map((e) => e.toJson()).toList()));
  }

  static void setCustomDarkThemes(List<ChewieThemeColorData> themes) {
    ChewieHiveUtil.put(ChewieHiveUtil.customDarkThemeListKey,
        jsonEncode(themes.map((e) => e.toJson()).toList()));
  }

  static Color? getCustomLightPrimaryColor() {
    String? hex = ChewieHiveUtil.getString(
        ChewieHiveUtil.customLightThemePrimaryColorKey,
        autoCreate: false);
    if (hex == null || hex.isEmpty) return null;
    return HexColor.fromHex(hex);
  }

  static void setCustomLightPrimaryColor(Color? color) {
    if (color == null) {
      ChewieHiveUtil.delete(ChewieHiveUtil.customLightThemePrimaryColorKey);
    } else {
      ChewieHiveUtil.put(
          ChewieHiveUtil.customLightThemePrimaryColorKey, color.toHex());
    }
  }

  static Color? getCustomDarkPrimaryColor() {
    String? hex = ChewieHiveUtil.getString(
        ChewieHiveUtil.customDarkThemePrimaryColorKey,
        autoCreate: false);
    if (hex == null || hex.isEmpty) return null;
    return HexColor.fromHex(hex);
  }

  static void setCustomDarkPrimaryColor(Color? color) {
    if (color == null) {
      ChewieHiveUtil.delete(ChewieHiveUtil.customDarkThemePrimaryColorKey);
    } else {
      ChewieHiveUtil.put(
          ChewieHiveUtil.customDarkThemePrimaryColorKey, color.toHex());
    }
  }

  static int getLightThemePrimaryColorIndex() {
    return ChewieHiveUtil.getInt(ChewieHiveUtil.lightThemePrimaryColorIndexKey,
        defaultValue: 0);
  }

  static void setLightThemePrimaryColorIndex(int index) {
    ChewieHiveUtil.put(ChewieHiveUtil.lightThemePrimaryColorIndexKey, index);
  }

  static int getDarkThemePrimaryColorIndex() {
    return ChewieHiveUtil.getInt(ChewieHiveUtil.darkThemePrimaryColorIndexKey,
        defaultValue: 0);
  }

  static void setDarkThemePrimaryColorIndex(int index) {
    ChewieHiveUtil.put(ChewieHiveUtil.darkThemePrimaryColorIndexKey, index);
  }

  static List<SortableItem> getSortableItems(
    String key,
    List<SortableItem> defaultValue,
  ) {
    String? json = ChewieHiveUtil.getString(key);
    if (json == null || json.isEmpty) {
      return defaultValue;
    } else {
      List<dynamic> list = jsonDecode(json);
      return List<SortableItem>.from(
          list.map((item) => SortableItem.fromJson(item)).toList());
    }
  }

  static void setSortableItems(String key, List<SortableItem> items) =>
      ChewieHiveUtil.put(key, jsonEncode(items));

  static dynamic get(
    String key, {
    String boxName = ChewieHiveUtil.settingsBox,
    int defaultValue = 0,
  }) {
    final Box box = Hive.box(boxName);
    if (!box.containsKey(key)) {
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static int getInt(
    String key, {
    String boxName = ChewieHiveUtil.settingsBox,
    int defaultValue = 0,
  }) {
    final Box box = Hive.box(boxName);
    if (!box.containsKey(key)) {
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static bool getBool(
    String key, {
    String boxName = ChewieHiveUtil.settingsBox,
    bool defaultValue = true,
  }) {
    final Box box = Hive.box(boxName);
    if (!box.containsKey(key)) {
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static String? getString(
    String key, {
    String boxName = ChewieHiveUtil.settingsBox,
    bool autoCreate = true,
    String? defaultValue,
  }) {
    final Box box = Hive.box(boxName);
    if (!box.containsKey(key)) {
      if (!autoCreate) {
        return null;
      }
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static Map<String, dynamic> getMap(
    String key, {
    String boxName = ChewieHiveUtil.settingsBox,
  }) {
    final Box box = Hive.box(boxName);
    Map<String, dynamic> res = {};
    if (box.get(key) != null) {
      res = Map<String, dynamic>.from(box.get(key));
    }
    return res;
  }

  static List<dynamic>? getList(
    String key, {
    String boxName = ChewieHiveUtil.settingsBox,
    bool autoCreate = true,
    List<dynamic> defaultValue = const [],
  }) {
    final Box box = Hive.box(boxName);
    if (!box.containsKey(key)) {
      if (!autoCreate) {
        return null;
      }
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static List<String>? getStringList(
    String key, {
    String boxName = ChewieHiveUtil.settingsBox,
    bool autoCreate = true,
    List<dynamic> defaultValue = const [],
  }) {
    return getList(
      key,
      boxName: boxName,
      autoCreate: autoCreate,
      defaultValue: defaultValue,
    )!
        .map((e) => e.toString())
        .toList();
  }

  static Future<void> put(
    String key,
    dynamic value, {
    String boxName = ChewieHiveUtil.settingsBox,
  }) async {
    final Box box = Hive.box(boxName);
    return box.put(key, value);
  }

  static Future<void> delete(
    String key, {
    String boxName = ChewieHiveUtil.settingsBox,
  }) async {
    final Box box = Hive.box(boxName);
    box.delete(key);
  }

  static bool contains(
    String key, {
    String boxName = ChewieHiveUtil.settingsBox,
  }) {
    final Box box = Hive.box(boxName);
    return box.containsKey(key);
  }
}
