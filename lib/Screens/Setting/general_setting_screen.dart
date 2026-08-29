import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

class GeneralSettingScreen extends BaseSettingScreen {
  const GeneralSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/general";

  @override
  State<GeneralSettingScreen> createState() => GeneralSettingScreenState();
}

class GeneralSettingScreenState extends BaseDynamicState<GeneralSettingScreen>
    with TickerProviderStateMixin {
  String _cacheSize = "";
  bool inAppBrowser = ChewieHiveUtil.getBool(HiveUtil.inappWebviewKey);
  String currentVersion = "";
  String latestVersion = "";
  ReleaseItem? latestReleaseItem;
  bool autoCheckUpdate = ChewieHiveUtil.getBool(HiveUtil.autoCheckUpdateKey);
  bool enableMinimizeToTray =
      ChewieHiveUtil.getBool(HiveUtil.enableCloseToTrayKey);
  bool recordWindowState =
      ChewieHiveUtil.getBool(HiveUtil.recordWindowStateKey);
  bool enableCloseNotice =
      ChewieHiveUtil.getBool(HiveUtil.enableCloseNoticeKey);
  int doubleTapAction = ChewieUtils.patchEnum(
      ChewieHiveUtil.getInt(HiveUtil.doubleTapActionKey, defaultValue: 1),
      DoubleTapAction.values.length);
  int downloadSuccessAction = ChewieUtils.patchEnum(
      ChewieHiveUtil.getInt(HiveUtil.downloadSuccessActionKey),
      DownloadSuccessAction.values.length);
  String _logSize = "";
  bool launchAtStartup = ChewieHiveUtil.getBool(HiveUtil.launchAtStartupKey);
  bool showTray = ChewieHiveUtil.getBool(HiveUtil.showTrayKey);

  Future<void> getLogSize() async {
    double size = await FileOutput.getLogsSize();
    if (!mounted) return;
    setState(() {
      _logSize = CacheUtil.renderSize(size);
    });
  }

  void refreshLauchAtStartup() {
    if (!mounted) return;
    setState(() {
      launchAtStartup = ChewieHiveUtil.getBool(HiveUtil.launchAtStartupKey);
    });
  }

  @override
  void initState() {
    super.initState();
    getLogSize();
    if (ResponsiveUtil.isMobile()) getCacheSize();
    fetchReleases(false);
  }

  void getCacheSize() {
    CacheUtil.loadCache().then((value) {
      if (!mounted) return;
      setState(() {
        _cacheSize = value;
      });
    });
  }

  List<SelectionItemModel<Locale?>> get _supportedLocaleItems {
    return AppLocalizations.supportedLocales
        .map(LocaleUtil.getSelectionItemModel)
        .whereType<SelectionItemModel<Locale?>>()
        .toList()
      ..insert(
        0,
        SelectionItemModel(appLocalizations.followSystem, null),
      );
  }

  Future<void> fetchReleases(bool showTip) async {
    setState(() {});
    ChewieUtils.getReleases(
      context: context,
      showLoading: showTip,
      showUpdateDialog: showTip,
      showFailedToast: showTip,
      showLatestToast: showTip,
      onGetCurrentVersion: (currentVersion) {
        if (!mounted) return;
        setState(() {
          this.currentVersion = currentVersion;
        });
      },
      onGetLatestRelease: (latestVersion, latestReleaseItem) {
        if (!mounted) return;
        setState(() {
          this.latestVersion = latestVersion;
          this.latestReleaseItem = latestReleaseItem;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.generalSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        CaptionItem(
          context: context,
          title: appLocalizations.language,
          children: [
            Selector<AppProvider, Locale?>(
              selector: (context, globalProvider) => globalProvider.locale,
              builder: (context, locale, child) =>
                  InlineSelectionItem<SelectionItemModel<Locale?>>(
                title: appLocalizations.language,
                items: _supportedLocaleItems,
                initItem: SelectionItemModel(
                  locale == null
                      ? appLocalizations.followSystem
                      : LocaleUtil.getLabel(locale) ?? locale.toLanguageTag(),
                  locale,
                ),
                hint: appLocalizations.chooseLanguage,
                onChanged: (item) {
                  if (item != null) appProvider.locale = item.value;
                },
              ),
            ),
          ],
        ),
        CaptionItem(
          context: context,
          title: appLocalizations.operationSetting,
          children: [
            InlineSelectionItem<SelectionItemModel<DoubleTapAction>>(
              title: appLocalizations.doubleTapInDetailPage,
              items: DoubleTapAction.values
                  .map((action) => SelectionItemModel(action.label, action))
                  .toList(),
              initItem: SelectionItemModel(
                DoubleTapAction.values[doubleTapAction].label,
                DoubleTapAction.values[doubleTapAction],
              ),
              hint: appLocalizations.chooseDoubleTapInDetailPage,
              onChanged: (item) {
                if (item == null) return;
                setState(() {
                  doubleTapAction = item.value.index;
                  ChewieHiveUtil.put(
                      HiveUtil.doubleTapActionKey, doubleTapAction);
                });
              },
            ),
            InlineSelectionItem<SelectionItemModel<DownloadSuccessAction>>(
              title: appLocalizations.afterDownloadSuccess,
              description: appLocalizations.afterDownloadSuccessDescription,
              items: DownloadSuccessAction.values
                  .map((action) => SelectionItemModel(action.label, action))
                  .toList(),
              initItem: SelectionItemModel(
                DownloadSuccessAction.values[downloadSuccessAction].label,
                DownloadSuccessAction.values[downloadSuccessAction],
              ),
              hint: appLocalizations.chooseAfterDownloadSuccess,
              onChanged: (item) {
                if (item == null) return;
                setState(() {
                  downloadSuccessAction = item.value.index;
                  ChewieHiveUtil.put(
                      HiveUtil.downloadSuccessActionKey, downloadSuccessAction);
                });
              },
            ),
          ],
        ),
        if (ResponsiveUtil.isDesktop()) ..._desktopSetting(),
        if (ResponsiveUtil.isMobile()) ..._mobileSetting(),
        CaptionItem(
          context: context,
          title: appLocalizations.checkUpdates,
          children: [
            CheckboxItem(
              value: autoCheckUpdate,
              context: context,
              title: appLocalizations.autoCheckUpdates,
              onTap: () {
                setState(() {
                  autoCheckUpdate = !autoCheckUpdate;
                  ChewieHiveUtil.put(
                      HiveUtil.autoCheckUpdateKey, autoCheckUpdate);
                });
              },
            ),
            EntryItem(
              context: context,
              title: appLocalizations.checkUpdates,
              description:
                  ChewieUtils.compareVersion(latestVersion, currentVersion) > 0
                      ? appLocalizations.newVersion(latestVersion)
                      : appLocalizations.alreadyLatestVersion,
              descriptionColor:
                  ChewieUtils.compareVersion(latestVersion, currentVersion) > 0
                      ? context.design.colors.warning
                      : null,
              tip: currentVersion,
              onTap: () {
                fetchReleases(true);
              },
            ),
          ],
        ),
        ..._logSetting(),
      ],
    );
  }

  List<Widget> _mobileSetting() {
    return [
      CaptionItem(
        context: context,
        title: appLocalizations.mobileSetting,
        children: [
          CheckboxItem(
            value: inAppBrowser,
            context: context,
            title: appLocalizations.inAppBrowser,
            onTap: () {
              setState(() {
                inAppBrowser = !inAppBrowser;
                ChewieHiveUtil.put(HiveUtil.inappWebviewKey, inAppBrowser);
              });
            },
          ),
          EntryItem(
            context: context,
            title: appLocalizations.clearCache,
            tip: _cacheSize,
            onTap: () {
              CustomLoadingDialog.showLoading(
                  title: appLocalizations.clearingCache);
              getTemporaryDirectory().then((tempDir) {
                CacheUtil.delDir(tempDir).then((value) {
                  CacheUtil.loadCache().then((value) {
                    if (!mounted) {
                      CustomLoadingDialog.dismissLoading();
                      return;
                    }
                    setState(() {
                      _cacheSize = value;
                      CustomLoadingDialog.dismissLoading();
                      IToast.showTop(appLocalizations.clearCacheSuccess);
                    });
                  });
                });
              });
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _logSetting() {
    return [
      CaptionItem(
        context: context,
        title: appLocalizations.other,
        children: [
          EntryItem(
            context: context,
            title: appLocalizations.exportLog,
            description: appLocalizations.exportLogHint,
            onTap: () {
              FileUtil.exportLogs();
            },
          ),
          EntryItem(
            context: context,
            title: appLocalizations.clearLog,
            tip: _logSize,
            onTap: () async {
              DialogBuilder.showConfirmDialog(
                context,
                title: appLocalizations.clearLogTitle,
                message: appLocalizations.clearLogHint,
                onTapConfirm: () async {
                  CustomLoadingDialog.showLoading(
                      title: appLocalizations.clearingLog);
                  try {
                    await FileOutput.clearLogs();
                    await getLogSize();
                    IToast.showTop(appLocalizations.clearLogSuccess);
                  } catch (e, t) {
                    ILogger.error("Failed to clear logs", e, t);
                    IToast.showTop(appLocalizations.clearLogFailed);
                  } finally {
                    CustomLoadingDialog.dismissLoading();
                  }
                },
              );
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _desktopSetting() {
    return [
      CaptionItem(
        context: context,
        title: appLocalizations.desktopSetting,
        children: [
          CheckboxItem(
            context: context,
            title: appLocalizations.launchAtStartup,
            value: launchAtStartup,
            onTap: () async {
              setState(() {
                launchAtStartup = !launchAtStartup;
                ChewieHiveUtil.put(
                    HiveUtil.launchAtStartupKey, launchAtStartup);
              });
              if (launchAtStartup) {
                await LaunchAtStartup.instance.enable();
              } else {
                await LaunchAtStartup.instance.disable();
              }
              Utils.initTray();
            },
          ),
          CheckboxItem(
            context: context,
            title: appLocalizations.showTray,
            value: showTray,
            onTap: () async {
              setState(() {
                showTray = !showTray;
                ChewieHiveUtil.put(HiveUtil.showTrayKey, showTray);
                if (showTray) {
                  Utils.initTray();
                } else {
                  Utils.removeTray();
                }
              });
            },
          ),
          Visibility(
            visible: showTray,
            child: InlineSelectionItem<SelectionItemModel<bool>>(
              title: appLocalizations.closeWindowOption,
              items: [
                SelectionItemModel(appLocalizations.minimizeToTray, true),
                SelectionItemModel(appLocalizations.exitApp, false),
              ],
              initItem: SelectionItemModel(
                enableMinimizeToTray
                    ? appLocalizations.minimizeToTray
                    : appLocalizations.exitApp,
                enableMinimizeToTray,
              ),
              hint: appLocalizations.chooseCloseWindowOption,
              onChanged: (item) {
                if (item == null) return;
                setState(() {
                  enableMinimizeToTray = item.value;
                  ChewieHiveUtil.put(
                    HiveUtil.enableCloseToTrayKey,
                    enableMinimizeToTray,
                  );
                });
              },
            ),
          ),
          CheckboxItem(
            context: context,
            title: appLocalizations.autoMemoryWindowPositionAndSize,
            value: recordWindowState,
            description: appLocalizations.autoMemoryWindowPositionAndSizeTip,
            onTap: () async {
              setState(() {
                recordWindowState = !recordWindowState;
                ChewieHiveUtil.put(
                    HiveUtil.recordWindowStateKey, recordWindowState);
              });
              HiveUtil.setWindowSize(await windowManager.getSize());
              HiveUtil.setWindowPosition(await windowManager.getPosition());
            },
          ),
        ],
      ),
    ];
  }
}
