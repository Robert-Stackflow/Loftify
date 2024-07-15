import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/account_response.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Resources/theme_color_data.dart';
import 'package:loftify/Utils/utils.dart';
import 'package:path_provider/path_provider.dart';

import '../Models/nav_entry.dart';
import '../Providers/global_provider.dart';

class HiveUtil {
  //Database
  static const String database = "Loftify";

  //HiveBox
  static const String settingsBox = "settings";

  //Auth
  static const String userIdKey = "userId";
  static const String userInfoKey = "userInfo";
  static const String deviceIdKey = "deviceId";
  static const String tokenKey = "token";
  static const String tokenTypeKey = "tokenType";
  static const String cookieKey = "cookieKey";
  static const String customAvatarBoxKey = "customAvatarBox";
  static const String searchHistoryKey = "searchHistory";

  //General
  static const String localeKey = "locale";
  static const String enableCloseToTrayKey = "enableCloseToTray";
  static const String enableCloseNoticeKey = "enableCloseNotice";
  static const String autoCheckUpdateKey = "autoCheckUpdate";
  static const String inappWebviewKey = "inappWebview";

  //Appearance
  static const String fontFamilyKey = "fontFamily";
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
  static const String navItemsKey = "navItems";

  //Layout
  static const String showRecommendVideoKey = "hideRecommendVideo";
  static const String showRecommendArticleKey = "hideRecommendArticle";
  static const String showSearchHistoryKey = "showSearchHistory";
  static const String showSearchGuessKey = "showSearchGuess";
  static const String showSearchConfigKey = "showSearchConfig";
  static const String showSearchRankKey = "showSearchRank";
  static const String showCollectionPreNextKey = "showCollectionPreNext";

  //image
  static const String followMainColorKey = "followMainColor";
  static const String savePathKey = "savePaths";
  static const String waterfallFlowImageQualityKey =
      "waterfallFlowImageQuality";
  static const String postDetailImageQualityKey = "postDetailImageQuality";
  static const String imageDetailImageQualityKey = "imageDetailImageQuality";
  static const String tapLinkButtonImageQualityKey =
      "tapLinkButtonImageQuality";
  static const String longPressLinkButtonImageQualityKey =
      "longPressLinkButtonImageQuality";

  //Privacy
  static const String enableGuesturePasswdKey = "enableGuesturePasswd";
  static const String guesturePasswdKey = "guesturePasswd";
  static const String enableBiometricKey = "enableBiometric";
  static const String autoLockKey = "autoLock";
  static const String autoLockTimeKey = "autoLockTime";
  static const String enableSafeModeKey = "enableSafeMode";

  //System
  static const String firstLoginKey = "firstLogin";

  static initConfig() async {
    HiveUtil.put(key: HiveUtil.showRecommendVideoKey, value: false);
    HiveUtil.put(key: HiveUtil.showRecommendArticleKey, value: true);
    HiveUtil.put(key: HiveUtil.showSearchHistoryKey, value: true);
    HiveUtil.put(key: HiveUtil.showSearchGuessKey, value: true);
    HiveUtil.put(key: HiveUtil.showSearchConfigKey, value: false);
    HiveUtil.put(key: HiveUtil.showSearchRankKey, value: true);
    HiveUtil.put(key: HiveUtil.showCollectionPreNextKey, value: true);
    HiveUtil.put(
        key: HiveUtil.waterfallFlowImageQualityKey,
        value: ImageQuality.medium.index);
    HiveUtil.put(
        key: HiveUtil.postDetailImageQualityKey,
        value: ImageQuality.origin.index);
    HiveUtil.put(
        key: HiveUtil.imageDetailImageQualityKey,
        value: ImageQuality.raw.index);
    HiveUtil.put(
        key: HiveUtil.tapLinkButtonImageQualityKey,
        value: ImageQuality.raw.index);
    HiveUtil.put(
        key: HiveUtil.longPressLinkButtonImageQualityKey,
        value: ImageQuality.raw.index);
    HiveUtil.put(key: HiveUtil.followMainColorKey, value: true);
    HiveUtil.put(key: HiveUtil.inappWebviewKey, value: true);
  }

  static bool isFirstLogin() {
    if (getBool(key: firstLoginKey, defaultValue: true) == true) return true;
    return false;
  }

  static void setFirstLogin() {
    HiveUtil.put(key: firstLoginKey, value: false);
  }

  static Future? setUserInfo(FullBlogInfo? blogInfo) {
    if (blogInfo != null) {
      return HiveUtil.put(key: HiveUtil.userInfoKey, value: blogInfo.toJson());
    }
    return Future(() => null);
  }

  static Future<FullBlogInfo?> getUserInfo({Function()? onEmpty}) async {
    Map<String, dynamic>? json = HiveUtil.getMap(key: HiveUtil.userInfoKey);
    if (json == null || json.isEmpty) {
      onEmpty?.call();
      return Future(() => null);
    } else {
      return FullBlogInfo.fromJson(json);
    }
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
    return stringToLocale(HiveUtil.getString(key: HiveUtil.localeKey));
  }

  static void setLocale(Locale? locale) {
    if (locale == null) {
      HiveUtil.delete(key: HiveUtil.localeKey);
    } else {
      HiveUtil.put(key: HiveUtil.localeKey, value: locale.toString());
    }
  }

  static ImageQuality getImageQuality(String key) {
    return ImageQuality.values[Utils.patchEnum(
        HiveUtil.getInt(key: key), ImageQuality.values.length,
        defaultValue: ImageQuality.medium.index)];
  }

  static int? getFontSize() {
    return 2;
    // return HiveUtil.getInt(key: HiveUtil.fontSizeKey,defaultValue: 2);
  }

  static void setFontSize(int? fontSize) {
    HiveUtil.put(key: HiveUtil.fontFamilyKey, value: fontSize);
  }

  static ActiveThemeMode getThemeMode() {
    return ActiveThemeMode.values[HiveUtil.getInt(key: HiveUtil.themeModeKey)];
  }

  static void setThemeMode(ActiveThemeMode themeMode) {
    HiveUtil.put(key: HiveUtil.themeModeKey, value: themeMode.index);
  }

  static int getLightThemeIndex() {
    int index =
        HiveUtil.getInt(key: HiveUtil.lightThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultLightThemes.length) {
      String? json = HiveUtil.getString(key: HiveUtil.customLightThemeListKey);
      if (json == null || json.isEmpty) {
        setLightTheme(0);
        return 0;
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index > ThemeColorData.defaultLightThemes.length + list.length) {
          setLightTheme(0);
          return 0;
        } else {
          return index;
        }
      }
    } else {
      return index;
    }
  }

  static int getDarkThemeIndex() {
    int index =
        HiveUtil.getInt(key: HiveUtil.darkThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultDarkThemes.length) {
      String? json = HiveUtil.getString(key: HiveUtil.customDarkThemeListKey);
      if (json == null || json.isEmpty) {
        setDarkTheme(0);
        return 0;
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index > ThemeColorData.defaultDarkThemes.length + list.length) {
          setDarkTheme(0);
          return 0;
        } else {
          return index;
        }
      }
    } else {
      return index;
    }
  }

  static ThemeColorData getLightTheme() {
    int index =
        HiveUtil.getInt(key: HiveUtil.lightThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultLightThemes.length) {
      String? json = HiveUtil.getString(key: HiveUtil.customLightThemeListKey);
      if (json == null || json.isEmpty) {
        setLightTheme(0);
        return ThemeColorData.defaultLightThemes[0];
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index > ThemeColorData.defaultLightThemes.length + list.length) {
          setLightTheme(0);
          return ThemeColorData.defaultLightThemes[0];
        } else {
          return ThemeColorData.fromJson(
              list[index - ThemeColorData.defaultLightThemes.length]);
        }
      }
    } else {
      return ThemeColorData.defaultLightThemes[index];
    }
  }

  static ThemeColorData getDarkTheme() {
    int index =
        HiveUtil.getInt(key: HiveUtil.darkThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultDarkThemes.length) {
      String? json = HiveUtil.getString(key: HiveUtil.customDarkThemeListKey);
      if (json == null || json.isEmpty) {
        setDarkTheme(0);
        return ThemeColorData.defaultDarkThemes[0];
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index > ThemeColorData.defaultDarkThemes.length + list.length) {
          setDarkTheme(0);
          return ThemeColorData.defaultDarkThemes[0];
        } else {
          return ThemeColorData.fromJson(
              list[index - ThemeColorData.defaultDarkThemes.length]);
        }
      }
    } else {
      return ThemeColorData.defaultDarkThemes[index];
    }
  }

  static void setLightTheme(int index) =>
      HiveUtil.put(key: HiveUtil.lightThemeIndexKey, value: index);

  static void setDarkTheme(int index) =>
      HiveUtil.put(key: HiveUtil.darkThemeIndexKey, value: index);

  static bool shouldAutoLock() =>
      HiveUtil.getBool(key: HiveUtil.enableGuesturePasswdKey) &&
      HiveUtil.getString(key: HiveUtil.guesturePasswdKey) != null &&
      HiveUtil.getString(key: HiveUtil.guesturePasswdKey)!.isNotEmpty &&
      HiveUtil.getBool(key: HiveUtil.autoLockKey);

  static List<SortableItem> getSortableItems(
      String key, List<SortableItem> defaultValue) {
    String? json = HiveUtil.getString(key: key);
    if (json == null || json.isEmpty) {
      return defaultValue;
    } else {
      List<dynamic> list = jsonDecode(json);
      return List<SortableItem>.from(
          list.map((item) => SortableItem.fromJson(item)).toList());
    }
  }

  static void setSortableItems(String key, List<SortableItem> items) =>
      HiveUtil.put(key: key, value: jsonEncode(items));

  static int getInt(
      {String boxName = HiveUtil.settingsBox,
      required String key,
      bool autoCreate = true,
      int defaultValue = 0}) {
    final Box box = Hive.box(boxName);
    if (!box.containsKey(key)) {
      put(boxName: boxName, key: key, value: defaultValue);
    }
    return box.get(key);
  }

  static bool getBool(
      {String boxName = HiveUtil.settingsBox,
      required String key,
      bool autoCreate = true,
      bool defaultValue = true}) {
    final Box box = Hive.box(boxName);
    if (!box.containsKey(key)) {
      put(boxName: boxName, key: key, value: defaultValue);
    }
    return box.get(key);
  }

  static Map<String, String> getCookie() {
    Map<String, String> map = {};
    String str = getString(key: cookieKey) ?? "";
    if (str.isNotEmpty) {
      List<String> list = str.split("; ");
      for (String item in list) {
        int equalIndex = item.indexOf("=");
        if (equalIndex != -1) {
          map[item.substring(0, equalIndex)] = item.substring(equalIndex + 1);
        }
      }
    }
    return map;
  }

  static String? getString(
      {String boxName = HiveUtil.settingsBox,
      required String key,
      bool autoCreate = true,
      String? defaultValue}) {
    final Box box = Hive.box(boxName);
    if (!box.containsKey(key)) {
      if (!autoCreate) {
        return null;
      }
      put(boxName: boxName, key: key, value: defaultValue);
    }
    return box.get(key);
  }

  static Map<String, dynamic>? getMap({
    String boxName = HiveUtil.settingsBox,
    required String key,
  }) {
    final Box box = Hive.box(boxName);
    Map<String, dynamic>? res;
    if (box.get(key) != null) {
      res = Map<String, dynamic>.from(box.get(key));
    }
    return res;
  }

  static List<dynamic>? getList(
      {String boxName = HiveUtil.settingsBox,
      required String key,
      bool autoCreate = true,
      List<dynamic>? defaultValue}) {
    final Box box = Hive.box(boxName);
    if (!box.containsKey(key)) {
      if (!autoCreate) {
        return null;
      }
      put(boxName: boxName, key: key, value: defaultValue);
    }
    return box.get(key);
  }

  static List<String>? getStringList(
      {String boxName = HiveUtil.settingsBox,
      required String key,
      bool autoCreate = true,
      List<dynamic>? defaultValue}) {
    return getList(
      key: key,
      boxName: boxName,
      autoCreate: autoCreate,
      defaultValue: defaultValue,
    )!
        .map((e) => e.toString())
        .toList();
  }

  static Future<void> put(
      {String boxName = HiveUtil.settingsBox,
      required String key,
      required dynamic value}) async {
    final Box box = Hive.box(boxName);
    return box.put(key, value);
  }

  static Future<void> delete(
      {String boxName = HiveUtil.settingsBox, required String key}) async {
    final Box box = Hive.box(boxName);
    await box.delete(key);
  }

  static bool contains(
      {String boxName = HiveUtil.settingsBox, required String key}) {
    final Box box = Hive.box(boxName);
    return box.containsKey(key);
  }

  static Future<void> openHiveBox(String boxName, {bool limit = false}) async {
    final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
      final Directory dir = await getApplicationDocumentsDirectory();
      final String dirPath = dir.path;
      File dbFile = File('$dirPath/$boxName.hive');
      File lockFile = File('$dirPath/$boxName.lock');
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        dbFile = File('$dirPath/${HiveUtil.database}/$boxName.hive');
        lockFile = File('$dirPath/${HiveUtil.database}/$boxName.lock');
      }
      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox(boxName);
      throw 'Failed to open $boxName Box\nError: $error';
    });
    if (limit && box.length > 500) {
      box.clear();
    }
  }
}
