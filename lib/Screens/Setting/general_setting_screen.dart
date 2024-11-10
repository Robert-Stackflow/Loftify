import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:loftify/Models/github_response.dart';
import 'package:loftify/Utils/cache_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:window_manager/window_manager.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Utils/file_util.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/locale_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/dialog_builder.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class GeneralSettingScreen extends StatefulWidget {
  const GeneralSettingScreen({super.key});

  static const String routeName = "/setting/general";

  @override
  State<GeneralSettingScreen> createState() => GeneralSettingScreenState();
}

class GeneralSettingScreenState extends State<GeneralSettingScreen>
    with TickerProviderStateMixin {
  String _cacheSize = "";
  List<Tuple2<String, Locale?>> _supportedLocaleTuples = [];
  bool inAppBrowser = HiveUtil.getBool(HiveUtil.inappWebviewKey);
  String currentVersion = "";
  String latestVersion = "";
  ReleaseItem? latestReleaseItem;
  bool autoCheckUpdate = HiveUtil.getBool(HiveUtil.autoCheckUpdateKey);
  bool enableMinimizeToTray = HiveUtil.getBool(HiveUtil.enableCloseToTrayKey);
  bool recordWindowState = HiveUtil.getBool(HiveUtil.recordWindowStateKey);
  bool enableCloseNotice = HiveUtil.getBool(HiveUtil.enableCloseNoticeKey);
  int doubleTapAction = Utils.patchEnum(
      HiveUtil.getInt(HiveUtil.doubleTapActionKey, defaultValue: 1),
      DoubleTapAction.values.length);
  int downloadSuccessAction = Utils.patchEnum(
      HiveUtil.getInt(HiveUtil.downloadSuccessActionKey),
      DownloadSuccessAction.values.length);
  String _logSize = "";
  bool launchAtStartup = HiveUtil.getBool(HiveUtil.launchAtStartupKey);
  bool showTray = HiveUtil.getBool(HiveUtil.showTrayKey);

  Future<void> getLogSize() async {
    double size = await FileOutput.getLogsSize();
    setState(() {
      _logSize = CacheUtil.renderSize(size);
    });
  }

  refreshLauchAtStartup() {
    setState(() {
      launchAtStartup = HiveUtil.getBool(HiveUtil.launchAtStartupKey);
    });
  }

  @override
  void initState() {
    super.initState();
    getLogSize();
    filterLocale();
    if (ResponsiveUtil.isMobile()) getCacheSize();
    fetchReleases(false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void getCacheSize() {
    CacheUtil.loadCache().then((value) {
      setState(() {
        _cacheSize = value;
      });
    });
  }

  void filterLocale() {
    _supportedLocaleTuples = [];
    List<Locale> locales = S.delegate.supportedLocales;
    _supportedLocaleTuples.add(Tuple2(S.current.followSystem, null));
    for (Locale locale in locales) {
      dynamic tuple = LocaleUtil.getTuple(locale);
      if (tuple != null) {
        _supportedLocaleTuples.add(tuple);
      }
    }
  }

  Future<void> fetchReleases(bool showTip) async {
    setState(() {});
    Utils.getReleases(
      context: context,
      showLoading: showTip,
      showUpdateDialog: showTip,
      showFailedToast: showTip,
      showLatestToast: showTip,
      onGetCurrentVersion: (currentVersion) {
        setState(() {
          this.currentVersion = currentVersion;
        });
      },
      onGetLatestRelease: (latestVersion, latestReleaseItem) {
        setState(() {
          this.latestVersion = latestVersion;
          this.latestReleaseItem = latestReleaseItem;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildResponsiveAppBar(
          showBack: true,
          title: S.current.generalSetting,
            context: context,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              if (ResponsiveUtil.isLandscape()) const SizedBox(height: 10),
              Selector<AppProvider, Locale?>(
                selector: (context, globalProvider) => globalProvider.locale,
                builder: (context, locale, child) => ItemBuilder.buildEntryItem(
                  context: context,
                  title: S.current.language,
                  tip: LocaleUtil.getLabel(locale)!,
                  roundTop: true,
                  roundBottom: true,
                  onTap: () {
                    filterLocale();
                    BottomSheetBuilder.showListBottomSheet(
                      context,
                      (context) => TileList.fromOptions(
                        _supportedLocaleTuples,
                        (item2) {
                          appProvider.locale = item2;
                          Navigator.pop(context);
                        },
                        selected: locale,
                        context: context,
                        title: S.current.chooseLanguage,
                        onCloseTap: () => Navigator.pop(context),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.operationSetting),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.doubleTapInDetailPage,
                tip: DoubleTapAction.values[doubleTapAction].label,
                onTap: () {
                  BottomSheetBuilder.showListBottomSheet(
                    context,
                    (sheetContext) => TileList.fromOptions(
                      DoubleTapAction.like.tuples,
                      (newAction) {
                        Navigator.pop(sheetContext);
                        setState(() {
                          doubleTapAction = newAction.index;
                          HiveUtil.put(
                              HiveUtil.doubleTapActionKey, doubleTapAction);
                        });
                      },
                      selected: DoubleTapAction.values[doubleTapAction],
                      title: S.current.chooseDoubleTapInDetailPage,
                      context: context,
                      onCloseTap: () => Navigator.pop(sheetContext),
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                  );
                },
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.afterDownloadSuccess,
                description: S.current.afterDownloadSuccessDescription,
                roundBottom: true,
                tip: DownloadSuccessAction.values[downloadSuccessAction].label,
                onTap: () {
                  BottomSheetBuilder.showListBottomSheet(
                    context,
                    (sheetContext) => TileList.fromOptions(
                      DownloadSuccessAction.unlike.tuples,
                      (newAction) {
                        Navigator.pop(sheetContext);
                        setState(() {
                          downloadSuccessAction = newAction.index;
                          HiveUtil.put(HiveUtil.downloadSuccessActionKey,
                              downloadSuccessAction);
                        });
                      },
                      selected:
                          DownloadSuccessAction.values[downloadSuccessAction],
                      title: S.current.chooseAfterDownloadSuccess,
                      context: context,
                      onCloseTap: () => Navigator.pop(sheetContext),
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                  );
                },
              ),
              if (ResponsiveUtil.isDesktop()) ..._desktopSetting(),
              if (ResponsiveUtil.isMobile()) ..._mobileSetting(),
              const SizedBox(height: 10),
              ItemBuilder.buildRadioItem(
                value: autoCheckUpdate,
                roundTop: true,
                context: context,
                title: S.current.autoCheckUpdates,
                onTap: () {
                  setState(() {
                    autoCheckUpdate = !autoCheckUpdate;
                    HiveUtil.put(HiveUtil.autoCheckUpdateKey, autoCheckUpdate);
                  });
                },
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.checkUpdates,
                roundBottom: true,
                description:
                    Utils.compareVersion(latestVersion, currentVersion) > 0
                        ? S.current.newVersion(latestVersion)
                        : S.current.alreadyLatestVersion,
                descriptionColor:
                    Utils.compareVersion(latestVersion, currentVersion) > 0
                        ? Colors.redAccent
                        : null,
                tip: currentVersion,
                onTap: () {
                  fetchReleases(true);
                },
              ),
              ..._logSetting(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  _mobileSetting() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        value: inAppBrowser,
        context: context,
        title: S.current.inAppBrowser,
        roundTop: true,
        onTap: () {
          setState(() {
            inAppBrowser = !inAppBrowser;
            HiveUtil.put(HiveUtil.inappWebviewKey, inAppBrowser);
          });
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.clearCache,
        roundBottom: true,
        tip: _cacheSize,
        onTap: () {
          CustomLoadingDialog.showLoading(title: S.current.clearingCache);
          getTemporaryDirectory().then((tempDir) {
            CacheUtil.delDir(tempDir).then((value) {
              CacheUtil.loadCache().then((value) {
                setState(() {
                  _cacheSize = value;
                  CustomLoadingDialog.dismissLoading();
                  IToast.showTop(S.current.clearCacheSuccess);
                });
              });
            });
          });
        },
      ),
    ];
  }

  _logSetting() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.exportLog,
        description: S.current.exportLogHint,
        roundTop: true,
        onTap: () {
          FileUtil.exportLogs();
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.clearLog,
        roundBottom: true,
        tip: _logSize,
        onTap: () async {
          DialogBuilder.showConfirmDialog(
            context,
            title: S.current.clearLogTitle,
            message: S.current.clearLogHint,
            onTapConfirm: () async {
              CustomLoadingDialog.showLoading(title: S.current.clearingLog);
              try {
                await FileOutput.clearLogs();
                await getLogSize();
                IToast.showTop(S.current.clearLogSuccess);
              } catch (e, t) {
                ILogger.error("Failed to clear logs", e, t);
                IToast.showTop(S.current.clearLogFailed);
              } finally {
                CustomLoadingDialog.dismissLoading();
              }
            },
          );
        },
      ),
    ];
  }

  _desktopSetting() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.desktopSetting),
      ItemBuilder.buildRadioItem(
        context: context,
        title: S.current.launchAtStartup,
        value: launchAtStartup,
        onTap: () async {
          setState(() {
            launchAtStartup = !launchAtStartup;
            HiveUtil.put(HiveUtil.launchAtStartupKey, launchAtStartup);
          });
          if (launchAtStartup) {
            await LaunchAtStartup.instance.enable();
          } else {
            await LaunchAtStartup.instance.disable();
          }
          Utils.initTray();
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        title: S.current.showTray,
        value: showTray,
        onTap: () async {
          setState(() {
            showTray = !showTray;
            HiveUtil.put(HiveUtil.showTrayKey, showTray);
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
        child: ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.closeWindowOption,
          tip: enableMinimizeToTray
              ? S.current.minimizeToTray
              : S.current.exitApp,
          onTap: () {
            List<Tuple2<String, dynamic>> options = [
              Tuple2(S.current.minimizeToTray, 0),
              Tuple2(S.current.exitApp, 1),
            ];
            BottomSheetBuilder.showListBottomSheet(
              context,
              (sheetContext) => TileList.fromOptions(
                options,
                (idx) {
                  Navigator.pop(sheetContext);
                  if (idx == 0) {
                    setState(() {
                      enableMinimizeToTray = true;
                      HiveUtil.put(
                          HiveUtil.enableCloseToTrayKey, enableMinimizeToTray);
                    });
                  } else if (idx == 1) {
                    setState(() {
                      enableMinimizeToTray = false;
                      HiveUtil.put(
                          HiveUtil.enableCloseToTrayKey, enableMinimizeToTray);
                    });
                  }
                },
                selected: enableMinimizeToTray ? 0 : 1,
                title: S.current.chooseCloseWindowOption,
                context: context,
                onCloseTap: () => Navigator.pop(sheetContext),
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            );
          },
        ),
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        title: S.current.autoMemoryWindowPositionAndSize,
        value: recordWindowState,
        description: S.current.autoMemoryWindowPositionAndSizeTip,
        roundBottom: true,
        onTap: () async {
          setState(() {
            recordWindowState = !recordWindowState;
            HiveUtil.put(HiveUtil.recordWindowStateKey, recordWindowState);
          });
          HiveUtil.setWindowSize(await windowManager.getSize());
          HiveUtil.setWindowPosition(await windowManager.getPosition());
        },
      ),
    ];
  }
}
