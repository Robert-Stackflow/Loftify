import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/account_response.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/request_util.dart';

import '../l10n/l10n.dart';
import 'app_provider.dart';

class HiveUtil {
  //Database
  static const String database = "Loftify";

  //HiveBox
  static const String settingsBox = "settings";

  //Auth
  static const String userIdKey = "userId";
  static const String phoneKey = "phone";
  static const String userInfoKey = "userInfo";
  static const String deviceIdKey = "deviceId";
  static const String tokenKey = "token";
  static const String tokenTypeKey = "tokenType";
  static const String cookieKey = "cookieKey";
  static const String customAvatarBoxKey = "customAvatarBox";
  static const String searchHistoryKey = "searchHistory";

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
  static const String doubleTapActionKey = "doubleTapAction";
  static const String downloadSuccessActionKey = "downloadSuccessAction";
  static const String videoContinuousPlaybackKey = "videoContinuousPlayback";
  static const String videoDanmakuEnabledKey = "videoDanmakuEnabled";
  static const String downloadTasksKey = "downloadTasks";

  //Appearance
  static const String enableLandscapeInTabletKey = "enableLandscapeInTablet";
  static const String fontFamilyKey = "fontFamily";
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
  static const String reduceTransparencyKey = "reduceTransparency";
  static const String navigationBarDisplayStyleKey =
      "navigationBarDisplayStyle";
  static const String navItemsKey = "navItems";
  static const String tagDetailPostLayoutTypeKey = "tagDetailPostLayoutType";
  static const String showPostDetailFloatingOperationBarKey =
      "showPostDetailFloatingOperationBar";
  static const String showPostDetailFloatingOperationBarOnlyInArticleKey =
      "showPostDetailFloatingOperationBarOnlyInArticle";

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
  static const String autoLockSecondsKey = "autoLockSeconds";
  static const String enableSafeModeKey = "enableSafeMode";

  //System
  static const String firstLoginKey = "firstLogin";
  static const String refreshRateKey = "refreshRate";
  static const String refreshRateModeKey = "refreshRateMode";
  static const String dynamicTabIndexKey = "dynamicTabIndex";
  static const String dynamicTabIdKey = "dynamicTabId";
  static const String searchRankTabIndexKey = "searchRankTabIndex";
  static const String searchRankTabIdKey = "searchRankTabId";
  static const String searchResultTabIndexKey = "searchResultTabIndex";
  static const String searchResultTabIdKey = "searchResultTabId";
  static const String tagDetailTabIndexKey = "tagDetailTabIndex";
  static const String tagDetailTabIdKey = "tagDetailTabId";
  static const String systemNoticeTabIndexKey = "systemNoticeTabIndex";
  static const String systemNoticeTabIdKey = "systemNoticeTabId";
  static const String tagCollectionGrainTabIndexKey =
      "tagCollectionGrainTabIndex";
  static const String tagCollectionGrainTabIdKey = "tagCollectionGrainTabId";
  static const String userDetailTabIndexKey = "userDetailTabIndex";
  static const String userDetailTabIdKey = "userDetailTabId";
  static const String suitTabIndexKey = "suitTabIndex";
  static const String suitTabIdKey = "suitTabId";
  static const String suitCustomPageIndexKey = "suitCustomPageIndex";
  static const String suitCustomPageIdKey = "suitCustomPageId";
  static const String tagNewestFilterKey = "tagNewestFilter";
  static const String tagHottestFilterKey = "tagHottestFilter";
  static const String haveShownQQGroupDialogKey = "haveShownQQGroupDialog";
  static const String overrideCloudControlKey = "overrideCloudControl";

  static void confirmLogout(BuildContext context) {
    DialogBuilder.showConfirmDialog(
      context,
      title: "退出登录",
      message: "确认退出登录？退出后本地的设置项不会被删除",
      confirmButtonText: appLocalizations.confirm,
      cancelButtonText: appLocalizations.cancel,
      onTapConfirm: () async {
        appProvider.token = "";
        await ChewieHiveUtil.delete(HiveUtil.userIdKey);
        await ChewieHiveUtil.delete(HiveUtil.tokenKey);
        await ChewieHiveUtil.delete(HiveUtil.deviceIdKey);
        await RequestUtil.clearCookie();
        ChewieHiveUtil.delete(HiveUtil.tokenTypeKey).then((value) {
          IToast.showTop("退出成功");
          mainScreenState?.logout();
        });
      },
      onTapCancel: () {},
    );
  }

  static Future<void> initConfig() async {
    ChewieHiveUtil.put(HiveUtil.doubleTapActionKey, 1);
    ChewieHiveUtil.put(HiveUtil.showRecommendVideoKey, false);
    ChewieHiveUtil.put(HiveUtil.showRecommendArticleKey, true);
    ChewieHiveUtil.put(HiveUtil.showSearchHistoryKey, true);
    ChewieHiveUtil.put(HiveUtil.showSearchGuessKey, true);
    ChewieHiveUtil.put(HiveUtil.showSearchConfigKey, false);
    ChewieHiveUtil.put(HiveUtil.showSearchRankKey, true);
    ChewieHiveUtil.put(HiveUtil.showCollectionPreNextKey, true);
    ChewieHiveUtil.put(
        HiveUtil.waterfallFlowImageQualityKey, ImageQuality.medium.index);
    ChewieHiveUtil.put(
        HiveUtil.postDetailImageQualityKey, ImageQuality.origin.index);
    ChewieHiveUtil.put(
        HiveUtil.imageDetailImageQualityKey, ImageQuality.raw.index);
    ChewieHiveUtil.put(
        HiveUtil.tapLinkButtonImageQualityKey, ImageQuality.raw.index);
    ChewieHiveUtil.put(
        HiveUtil.longPressLinkButtonImageQualityKey, ImageQuality.raw.index);
    ChewieHiveUtil.put(HiveUtil.followMainColorKey, true);
    ChewieHiveUtil.put(HiveUtil.inappWebviewKey, true);
  }

  static Future<void> initBox() async {
    await Hive.openBox(HiveUtil.settingsBox,
        path: await FileUtil.getApplicationDir());
  }

  static void setWindowSize(Size size) => ChewieHiveUtil.setWindowSize(size);

  static void setWindowPosition(Offset offset) =>
      ChewieHiveUtil.setWindowPosition(offset);

  static void setCustomFonts(List<CustomFont> fonts) =>
      ChewieHiveUtil.setCustomFonts(fonts);

  static List<CustomFont> getCustomFonts() => ChewieHiveUtil.getCustomFonts();

  static Locale? getLocale() => ChewieHiveUtil.getLocale();

  static void setLocale(Locale? locale) => ChewieHiveUtil.setLocale(locale);

  static int getFontSize() => ChewieHiveUtil.getFontSize();

  static void setFontSize(int fontSize) => ChewieHiveUtil.setFontSize(fontSize);

  static ActiveThemeMode getThemeMode() => ChewieHiveUtil.getThemeMode();

  static void setThemeMode(ActiveThemeMode themeMode) =>
      ChewieHiveUtil.setThemeMode(themeMode);

  static int getLightThemeIndex() => ChewieHiveUtil.getLightThemeIndex();

  static int getDarkThemeIndex() => ChewieHiveUtil.getDarkThemeIndex();

  static ChewieThemeColorData getLightTheme() => ChewieHiveUtil.getLightTheme();

  static ChewieThemeColorData getDarkTheme() => ChewieHiveUtil.getDarkTheme();

  static void setLightTheme(int index) => ChewieHiveUtil.setLightTheme(index);

  static void setDarkTheme(int index) => ChewieHiveUtil.setDarkTheme(index);

  static Future? setUserInfo(FullBlogInfo? blogInfo) {
    if (blogInfo != null) {
      return ChewieHiveUtil.put(HiveUtil.userInfoKey, blogInfo.toJson());
    }
    return Future(() => null);
  }

  static Future<void> setUserId(int userId) async {
    await ChewieHiveUtil.put(HiveUtil.userIdKey, userId);
  }

  static Future<int> getUserId() async {
    try {
      return ChewieHiveUtil.getInt(HiveUtil.userIdKey);
    } catch (e) {
      FullBlogInfo? blogInfo = await HiveUtil.getUserInfo();
      return blogInfo?.blogId ?? 0;
    }
  }

  static Future<FullBlogInfo?> getUserInfo({
    Function()? onEmpty,
  }) async {
    Map<String, dynamic>? json = ChewieHiveUtil.getMap(HiveUtil.userInfoKey);
    if (json.isEmpty) {
      onEmpty?.call();
      return Future(() => null);
    } else {
      return FullBlogInfo.fromJson(json);
    }
  }

  static ImageQuality getImageQuality(String key) {
    return ImageQuality.values[ChewieUtils.patchEnum(
        ChewieHiveUtil.getInt(key), ImageQuality.values.length,
        defaultValue: ImageQuality.medium.index)];
  }

  static bool shouldAutoLock() =>
      canLock() && ChewieHiveUtil.getBool(HiveUtil.autoLockKey);

  static bool canLock() =>
      ChewieHiveUtil.getBool(HiveUtil.enableGuesturePasswdKey) &&
      hasGuesturePasswd();

  static bool hasGuesturePasswd() =>
      ChewieHiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
      ChewieHiveUtil.getString(HiveUtil.guesturePasswdKey)!.isNotEmpty;

  static Map<String, String> getCookie() {
    Map<String, String> map = {};
    String str = ChewieHiveUtil.getString(cookieKey) ?? "";
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
}
