import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:loftify/Models/illust.dart';
import 'package:loftify/Screens/Setting/experiment_setting_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/shortcuts_util.dart';
import 'package:loftify/Widgets/BottomSheet/slide_captcha_bottom_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../Screens/Setting/about_setting_screen.dart';
import '../Screens/Setting/setting_screen.dart';
import '../Widgets/Shortcuts/keyboard_widget.dart';
import '../l10n/l10n.dart';
import 'app_provider.dart';

class Utils {
  static int parseToInt(dynamic value) => NumberUtil.parseToInt(value);

  static List<dynamic> parseJsonList(String json) =>
      StringUtil.parseJsonList(json);

  static String formatDuration(int seconds) =>
      TimeUtil.formatDuration(Duration(seconds: seconds));

  static void copy(
    BuildContext context,
    dynamic data, {
    String? toastText,
  }) =>
      ChewieUtils.copy(context, data, toastText: toastText);

  static String getHeroTag({
    String? tagPrefix,
    String? tagSuffix,
    String? url,
  }) {
    return "${StringUtil.processEmpty(tagPrefix)}-${Utils.removeImageParam(StringUtil.processEmpty(url))}-${StringUtil.processEmpty(tagSuffix)}";
  }

  static getIndexOfImage(String image, List<Illust> illusts) {
    return illusts.indexWhere((element) =>
        Utils.removeImageParam(element.url) == Utils.removeImageParam(image));
  }

  static String removeWatermark(String str) {
    return str.split("watermark")[0];
  }

  static String removeImageParam(String str) {
    return str.split("?imageView")[0];
  }

  static bool isGIF(String str) {
    return str.contains(".gif");
  }

  static String getUrlByQuality(
    String url,
    ImageQuality quality, {
    bool removeWatermark = true,
    bool smallest = false,
  }) {
    String qualitiedUrl = url;
    String rawUrl = removeImageParam(url);
    if (rawUrl.endsWith(".gif")) return rawUrl;
    switch (quality) {
      case ImageQuality.raw:
        qualitiedUrl = removeImageParam(url);
        break;
      case ImageQuality.origin:
        qualitiedUrl =
            "${removeImageParam(url)}?imageView&thumbnail=1680x0&quality=96";
        break;
      case ImageQuality.medium:
        qualitiedUrl =
            "${removeImageParam(url)}?imageView&thumbnail=500x0&quality=96";
        break;
      case ImageQuality.small:
        qualitiedUrl = smallest
            ? "${removeImageParam(url)}?imageView&thumbnail=64y64&quality=40"
            : "${removeImageParam(url)}?imageView&thumbnail=164y164&enlarge=1&quality=90";
        break;
    }
    return removeWatermark ? Utils.removeWatermark(qualitiedUrl) : qualitiedUrl;
  }

  static String getBlogDomain(String? blogName) {
    return StringUtil.isNotEmpty(blogName) ? "$blogName.lofter.com" : "";
  }

  static addSearchHistory(String str) {
    if (ChewieHiveUtil.getBool(HiveUtil.showSearchHistoryKey,
        defaultValue: true)) {
      while (appProvider.searchHistoryList.contains(str)) {
        appProvider.searchHistoryList.remove(str);
      }
      List<String> tmp = ChewieUtils.deepCopy(appProvider.searchHistoryList);
      tmp.insert(0, str);
      appProvider.searchHistoryList = tmp;
    }
  }

  static void validSlideCaptcha(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const SlideCaptchaBottomSheet();
      },
    );
  }

  static handleDownloadSuccessAction({
    Function()? onUnlike,
    Function()? onUnrecommend,
  }) {
    DownloadSuccessAction action = DownloadSuccessAction.values[
        ChewieUtils.patchEnum(
            ChewieHiveUtil.getInt(HiveUtil.downloadSuccessActionKey),
            DownloadSuccessAction.values.length)];
    switch (action) {
      case DownloadSuccessAction.none:
        break;
      case DownloadSuccessAction.unlike:
        onUnlike?.call();
        break;
      case DownloadSuccessAction.unrecommend:
        onUnrecommend?.call();
        break;
    }
  }

  static Future<void> removeTray() async {
    await trayManager.destroy();
  }

  static Future<void> initTray() async {
    if (!ResponsiveUtil.isDesktop()) return;
    await trayManager.destroy();
    if (!ChewieHiveUtil.getBool(HiveUtil.showTrayKey)) {
      await trayManager.destroy();
      return;
    }

    // Ensure tray icon display in linux sandboxed environments
    if (Platform.environment.containsKey('FLATPAK_ID') ||
        Platform.environment.containsKey('SNAP')) {
      await trayManager.setIcon('com.cloudchewie.loftify');
    } else if (ResponsiveUtil.isWindows()) {
      await trayManager.setIcon('assets/logo-transparent-big.ico');
    } else {
      await trayManager.setIcon('assets/logo-transparent-big.png');
    }

    var packageInfo = await PackageInfo.fromPlatform();
    bool lauchAtStartup = await LaunchAtStartup.instance.isEnabled();
    if (!ResponsiveUtil.isLinux()) {
      await trayManager.setToolTip(packageInfo.appName);
    }
    Menu menu = Menu(
      items: [
        MenuItem(
          key: TrayKey.checkUpdates.key,
          label: appProvider.latestVersion.isNotEmpty
              ? appLocalizations.getNewVersion(appProvider.latestVersion)
              : appLocalizations.checkUpdates,
        ),
        // MenuItem(
        //   key: TrayKey.shortcutHelp.key,
        //   label: appLocalizations.shortcutHelp,
        // ),
        MenuItem.separator(),
        MenuItem(
          key: TrayKey.displayApp.key,
          label: appLocalizations.displayAppTray,
        ),
        MenuItem(
          key: TrayKey.lockApp.key,
          label: appLocalizations.lockAppTray,
        ),
        MenuItem.separator(),
        MenuItem(
          key: TrayKey.setting.key,
          label: appLocalizations.setting,
        ),
        MenuItem(
          key: TrayKey.officialWebsite.key,
          label: appLocalizations.officialWebsiteTray,
        ),
        MenuItem(
          key: TrayKey.about.key,
          label: appLocalizations.about,
        ),
        MenuItem(
          key: TrayKey.githubRepository.key,
          label: appLocalizations.repoTray,
        ),
        MenuItem.separator(),
        MenuItem.checkbox(
          checked: lauchAtStartup,
          key: TrayKey.launchAtStartup.key,
          label: appLocalizations.launchAtStartup,
        ),
        MenuItem.separator(),
        MenuItem(
          key: TrayKey.exitApp.key,
          label: appLocalizations.exitAppTray,
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  static Future<void> initSimpleTray() async {
    if (!ResponsiveUtil.isDesktop()) return;
    await trayManager.destroy();
    if (!ChewieHiveUtil.getBool(HiveUtil.showTrayKey)) {
      await trayManager.destroy();
      return;
    }

    // Ensure tray icon display in linux sandboxed environments
    if (Platform.environment.containsKey('FLATPAK_ID') ||
        Platform.environment.containsKey('SNAP')) {
      await trayManager.setIcon('com.cloudchewie.loftify');
    } else if (ResponsiveUtil.isWindows()) {
      await trayManager.setIcon('assets/logo-transparent-big.ico');
    } else {
      await trayManager.setIcon('assets/logo-transparent-big.png');
    }

    var packageInfo = await PackageInfo.fromPlatform();
    bool lauchAtStartup = await LaunchAtStartup.instance.isEnabled();
    if (!ResponsiveUtil.isLinux()) {
      await trayManager.setToolTip(packageInfo.appName);
    }
    Menu menu = Menu(
      items: [
        MenuItem(
          key: TrayKey.displayApp.key,
          label: appLocalizations.displayAppTray,
        ),
        MenuItem.separator(),
        MenuItem(
          key: TrayKey.officialWebsite.key,
          label: appLocalizations.officialWebsiteTray,
        ),
        MenuItem(
          key: TrayKey.githubRepository.key,
          label: appLocalizations.repoTray,
        ),
        MenuItem.separator(),
        MenuItem.checkbox(
          checked: lauchAtStartup,
          key: TrayKey.launchAtStartup.key,
          label: appLocalizations.launchAtStartup,
        ),
        MenuItem.separator(),
        MenuItem(
          key: TrayKey.exitApp.key,
          label: appLocalizations.exitAppTray,
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  static showHelp(BuildContext context) {
    if (appProvider.shownShortcutHelp) return;
    appProvider.shownShortcutHelp = true;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return KeyboardWidget(
          bindings: ShortcutsUtil.shortcuts,
          callbackOnHide: () {
            appProvider.shownShortcutHelp = false;
            entry.remove();
          },
          title: Text(
            appLocalizations.shortcut,
            style: Theme.of(rootContext).textTheme.titleLarge,
          ),
        );
      },
    );
    Overlay.of(context).insert(entry);
    return null;
  }

  static processTrayMenuItemClick(
    BuildContext context,
    MenuItem menuItem, [
    bool isSimple = false,
  ]) async {
    ILogger.info("Tray menu item clicked: ${menuItem.key}: ${menuItem.label}");
    if (menuItem.key == TrayKey.displayApp.key) {
      ChewieUtils.displayApp();
    } else if (menuItem.key == TrayKey.shortcutHelp.key) {
      ChewieUtils.displayApp();
      Utils.showHelp(context);
    } else if (menuItem.key == TrayKey.lockApp.key) {
      if (HiveUtil.canLock()) {
        mainScreenState?.jumpToLock();
      } else {
        IToast.showDesktopNotification(
          appLocalizations.noGestureLock,
          body: appLocalizations.noGestureLockTip,
          actions: [
            appLocalizations.cancel,
            appLocalizations.goToSetGestureLock
          ],
          onClick: () {
            ChewieUtils.displayApp();
            RouteUtil.pushPanelCupertinoRoute(
                context, const ExperimentSettingScreen());
          },
          onClickAction: (index) {
            if (index == 1) {
              ChewieUtils.displayApp();
              RouteUtil.pushPanelCupertinoRoute(
                  context, const ExperimentSettingScreen());
            }
          },
        );
      }
    } else if (menuItem.key == TrayKey.setting.key) {
      ChewieUtils.displayApp();
      RouteUtil.pushPanelCupertinoRoute(context, const SettingScreen());
    } else if (menuItem.key == TrayKey.about.key) {
      ChewieUtils.displayApp();
      RouteUtil.pushPanelCupertinoRoute(context, const AboutSettingScreen());
    } else if (menuItem.key == TrayKey.officialWebsite.key) {
      UriUtil.launchUrlUri(context, officialWebsite);
    } else if (menuItem.key == TrayKey.githubRepository.key) {
      UriUtil.launchUrlUri(context, repoUrl);
    } else if (menuItem.key == TrayKey.checkUpdates.key) {
      ChewieUtils.getReleases(
        context: context,
        showLoading: false,
        showUpdateDialog: true,
        showFailedToast: false,
        showLatestToast: false,
        showDesktopNotification: true,
      );
    } else if (menuItem.key == TrayKey.launchAtStartup.key) {
      menuItem.checked = !(menuItem.checked == true);
      ChewieHiveUtil.put(HiveUtil.launchAtStartupKey, menuItem.checked);
      generalSettingScreenState?.refreshLauchAtStartup();
      if (menuItem.checked == true) {
        await LaunchAtStartup.instance.enable();
      } else {
        await LaunchAtStartup.instance.disable();
      }
      if (isSimple) {
        Utils.initSimpleTray();
      } else {
        Utils.initTray();
      }
    } else if (menuItem.key == TrayKey.exitApp.key) {
      windowManager.close();
    }
  }

  static localAuth({Function()? onAuthed}) async {
    LocalAuthentication localAuth = LocalAuthentication();
    try {
      await localAuth.authenticate(
        authMessages: [
          androidAuthMessages,
          androidAuthMessages,
          androidAuthMessages
        ],
        options: const AuthenticationOptions(
          useErrorDialogs: false,
          stickyAuth: true,
          biometricOnly: false,
        ),
        localizedReason: ' ',
      ).then((value) {
        if (value) {
          onAuthed?.call();
        }
      });
    } on PlatformException catch (e, t) {
      ILogger.error("Failed to local authenticate by PlatformException", e, t);
      if (e.code == auth_error.notAvailable) {
        IToast.showTop(appLocalizations.biometricNotAvailable);
      } else if (e.code == auth_error.notEnrolled) {
        IToast.showTop(appLocalizations.biometricNotEnrolled);
      } else if (e.code == auth_error.lockedOut) {
        IToast.showTop(appLocalizations.biometricLockout);
      } else if (e.code == auth_error.permanentlyLockedOut) {
        IToast.showTop(appLocalizations.biometricLockoutPermanent);
      } else {
        IToast.showTop(appLocalizations.biometricOtherReason(e));
      }
    } catch (e, t) {
      ILogger.error("Failed to local authenticate", e, t);
    }
  }
}
