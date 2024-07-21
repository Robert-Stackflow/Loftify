import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/account_response.dart';
import 'package:loftify/Resources/theme_color_data.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/utils.dart';

import '../Models/nav_entry.dart';

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
  static const String doubleTapActionKey = "doubleTapAction";
  static const String downloadSuccessActionKey = "downloadSuccessAction";

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
  static const String showDownloadKey = "showDownload";

  //image
  static const String followMainColorKey = "followMainColor";
  static const String savePathKey = "savePaths";
  static const String filenameFormatKey = "filenameFormat";
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
    HiveUtil.put(HiveUtil.doubleTapActionKey, 1);
    HiveUtil.put(HiveUtil.showRecommendVideoKey, false);
    HiveUtil.put(HiveUtil.showRecommendArticleKey, true);
    HiveUtil.put(HiveUtil.showSearchHistoryKey, true);
    HiveUtil.put(HiveUtil.showSearchGuessKey, true);
    HiveUtil.put(HiveUtil.showSearchConfigKey, false);
    HiveUtil.put(HiveUtil.showSearchRankKey, true);
    HiveUtil.put(HiveUtil.showCollectionPreNextKey, true);
    HiveUtil.put(
        HiveUtil.waterfallFlowImageQualityKey, ImageQuality.medium.index);
    HiveUtil.put(HiveUtil.postDetailImageQualityKey, ImageQuality.origin.index);
    HiveUtil.put(HiveUtil.imageDetailImageQualityKey, ImageQuality.raw.index);
    HiveUtil.put(HiveUtil.tapLinkButtonImageQualityKey, ImageQuality.raw.index);
    HiveUtil.put(
        HiveUtil.longPressLinkButtonImageQualityKey, ImageQuality.raw.index);
    HiveUtil.put(HiveUtil.followMainColorKey, true);
    HiveUtil.put(HiveUtil.inappWebviewKey, true);
  }

  static bool isFirstLogin() {
    if (getBool(firstLoginKey, defaultValue: true) == true) return true;
    return false;
  }

  static void setFirstLogin() {
    HiveUtil.put(firstLoginKey, false);
  }

  static Future? setUserInfo(FullBlogInfo? blogInfo) {
    if (blogInfo != null) {
      return HiveUtil.put(HiveUtil.userInfoKey, blogInfo.toJson());
    }
    return Future(() => null);
  }

  static Future<FullBlogInfo?> getUserInfo({
    Function()? onEmpty,
  }) async {
    Map<String, dynamic>? json = HiveUtil.getMap(HiveUtil.userInfoKey);
    if (json.isEmpty) {
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
    return stringToLocale(HiveUtil.getString(HiveUtil.localeKey));
  }

  static void setLocale(Locale? locale) {
    if (locale == null) {
      HiveUtil.delete(HiveUtil.localeKey);
    } else {
      HiveUtil.put(HiveUtil.localeKey, locale.toString());
    }
  }

  static ImageQuality getImageQuality(String key) {
    return ImageQuality.values[Utils.patchEnum(
        HiveUtil.getInt(key), ImageQuality.values.length,
        defaultValue: ImageQuality.medium.index)];
  }

  static int? getFontSize() {
    return 2;
    // return HiveUtil.getInt( HiveUtil.fontSizeKey,defaultValue: 2);
  }

  static void setFontSize(int? fontSize) {
    HiveUtil.put(HiveUtil.fontFamilyKey, fontSize);
  }

  static ActiveThemeMode getThemeMode() {
    return ActiveThemeMode.values[HiveUtil.getInt(HiveUtil.themeModeKey)];
  }

  static void setThemeMode(ActiveThemeMode themeMode) {
    HiveUtil.put(HiveUtil.themeModeKey, themeMode.index);
  }

  static int getLightThemeIndex() {
    int index = HiveUtil.getInt(HiveUtil.lightThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultLightThemes.length) {
      String? json = HiveUtil.getString(HiveUtil.customLightThemeListKey);
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
      return Utils.patchEnum(index, ThemeColorData.defaultLightThemes.length);
    }
  }

  static int getDarkThemeIndex() {
    int index = HiveUtil.getInt(HiveUtil.darkThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultDarkThemes.length) {
      String? json = HiveUtil.getString(HiveUtil.customDarkThemeListKey);
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
      return Utils.patchEnum(index, ThemeColorData.defaultDarkThemes.length);
    }
  }

  static ThemeColorData getLightTheme() {
    int index = HiveUtil.getInt(HiveUtil.lightThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultLightThemes.length) {
      String? json = HiveUtil.getString(HiveUtil.customLightThemeListKey);
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
      return ThemeColorData.defaultLightThemes[
          Utils.patchEnum(index, ThemeColorData.defaultLightThemes.length)];
    }
  }

  static ThemeColorData getDarkTheme() {
    int index = HiveUtil.getInt(HiveUtil.darkThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultDarkThemes.length) {
      String? json = HiveUtil.getString(HiveUtil.customDarkThemeListKey);
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
      return ThemeColorData.defaultDarkThemes[
          Utils.patchEnum(index, ThemeColorData.defaultDarkThemes.length)];
    }
  }

  static void setLightTheme(int index) =>
      HiveUtil.put(HiveUtil.lightThemeIndexKey, index);

  static void setDarkTheme(int index) =>
      HiveUtil.put(HiveUtil.darkThemeIndexKey, index);

  static bool shouldAutoLock() =>
      HiveUtil.getBool(HiveUtil.enableGuesturePasswdKey) &&
      HiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
      HiveUtil.getString(HiveUtil.guesturePasswdKey)!.isNotEmpty &&
      HiveUtil.getBool(HiveUtil.autoLockKey);

  static List<SortableItem> getSortableItems(
    String key,
    List<SortableItem> defaultValue,
  ) {
    String? json = HiveUtil.getString(key);
    if (json == null || json.isEmpty) {
      return defaultValue;
    } else {
      List<dynamic> list = jsonDecode(json);
      return List<SortableItem>.from(
          list.map((item) => SortableItem.fromJson(item)).toList());
    }
  }

  static void setSortableItems(String key, List<SortableItem> items) =>
      HiveUtil.put(key, jsonEncode(items));

  static Map<String, String> getCookie() {
    Map<String, String> map = {};
    String str = getString(cookieKey) ?? "";
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

  static int getInt(
    String key, {
    String boxName = HiveUtil.settingsBox,
    int defaultValue = 0,
  }) {
    final Box box = Hive.box(name: boxName);
    if (!box.containsKey(key)) {
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static bool getBool(
    String key, {
    String boxName = HiveUtil.settingsBox,
    bool defaultValue = true,
  }) {
    final Box box = Hive.box(name: boxName);
    if (!box.containsKey(key)) {
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static String? getString(
    String key, {
    String boxName = HiveUtil.settingsBox,
    bool autoCreate = true,
    String? defaultValue,
  }) {
    final Box box = Hive.box(name: boxName);
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
    String boxName = HiveUtil.settingsBox,
  }) {
    final Box box = Hive.box(name: boxName);
    Map<String, dynamic> res = {};
    if (box.get(key) != null) {
      res = Map<String, dynamic>.from(box.get(key));
    }
    return res;
  }

  static List<dynamic>? getList(
    String key, {
    String boxName = HiveUtil.settingsBox,
    bool autoCreate = true,
    List<dynamic> defaultValue = const [],
  }) {
    final Box box = Hive.box(name: boxName);
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
    String boxName = HiveUtil.settingsBox,
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
    String boxName = HiveUtil.settingsBox,
  }) async {
    final Box box = Hive.box(name: boxName);
    return box.put(key, value);
  }

  static Future<void> delete(
    String key, {
    String boxName = HiveUtil.settingsBox,
  }) async {
    final Box box = Hive.box(name: boxName);
    box.delete(key);
  }

  static bool contains(
    String key, {
    String boxName = HiveUtil.settingsBox,
  }) {
    final Box box = Hive.box(name: boxName);
    return box.containsKey(key);
  }
}
