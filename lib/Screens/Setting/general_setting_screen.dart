import 'package:flutter/material.dart';
import 'package:loftify/Models/github_response.dart';
import 'package:loftify/Utils/cache_util.dart';
import 'package:loftify/Utils/file_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../Api/github_api.dart';
import '../../Providers/global_provider.dart';
import '../../Providers/provider_manager.dart';
import '../../Utils/hive_util.dart';
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
  State<GeneralSettingScreen> createState() => _GeneralSettingScreenState();
}

class _GeneralSettingScreenState extends State<GeneralSettingScreen>
    with TickerProviderStateMixin {
  String _cacheSize = "";
  List<Tuple2<String, Locale?>> _supportedLocaleTuples = [];
  bool inAppBrowser = HiveUtil.getBool(key: HiveUtil.inappWebviewKey);
  String currentVersion = "";
  String latestVersion = "";
  ReleaseItem? latestReleaseItem;
  bool autoCheckUpdate = HiveUtil.getBool(key: HiveUtil.autoCheckUpdateKey);
  bool enableCloseToTray = HiveUtil.getBool(key: HiveUtil.enableCloseToTrayKey);
  bool enableCloseNotice = HiveUtil.getBool(key: HiveUtil.enableCloseNoticeKey);

  @override
  void initState() {
    super.initState();
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
    if (showTip) {
      CustomLoadingDialog.showLoading(context, title: "检查更新中...");
    }
    await PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        currentVersion = packageInfo.version;
      });
    });
    GithubApi.getReleases("Robert-Stackflow", "Loftify").then((releases) async {
      for (var release in releases) {
        String tagName = release.tagName;
        tagName = tagName.replaceAll(RegExp(r'[a-zA-Z]'), '');
        setState(() {
          if (latestVersion.compareTo(tagName) < 0) {
            latestVersion = tagName;
            latestReleaseItem = release;
          }
        });
      }
      if (showTip) {
        CustomLoadingDialog.dismissLoading(context);
        if (latestVersion.compareTo(currentVersion) > 0 &&
            latestReleaseItem != null) {
          DialogBuilder.showConfirmDialog(
            context,
            title: "发现新版本$latestVersion",
            message:
                "是否立即更新？${Utils.isNotEmpty(latestReleaseItem!.body) ? "更新日志如下：\n${latestReleaseItem!.body}" : ""}",
            confirmButtonText: "立即下载",
            cancelButtonText: "暂不更新",
            onTapConfirm: () {
              FileUtil.downloadAndUpdate(
                context,
                latestReleaseItem!.assets.isNotEmpty
                    ? latestReleaseItem!.assets[0].browserDownloadUrl
                    : "",
                latestReleaseItem!.htmlUrl,
                version: latestVersion,
              );
            },
            onTapCancel: () {},
            customDialogType: CustomDialogType.normal,
          );
        } else {
          IToast.showTop(context, text: S.current.checkUpdatesAlreadyLatest);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildSimpleAppBar(
            title: S.current.generalSetting,
            context: context,
            transparent: true),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              const SizedBox(height: 10),
              Selector<GlobalProvider, Locale?>(
                selector: (context, globalProvider) => globalProvider.locale,
                builder: (context, locale, child) => ItemBuilder.buildEntryItem(
                  context: context,
                  title: S.current.language,
                  tip: LocaleUtil.getLabel(locale)!,
                  topRadius: true,
                  bottomRadius: true,
                  onTap: () {
                    filterLocale();
                    BottomSheetBuilder.showListBottomSheet(
                      context,
                      (context) => TileList.fromOptions(
                        _supportedLocaleTuples,
                        (item2) {
                          ProviderManager.globalProvider.locale = item2;
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
              if (ResponsiveUtil.isMobile()) const SizedBox(height: 10),
              if (ResponsiveUtil.isMobile())
                ItemBuilder.buildRadioItem(
                  value: inAppBrowser,
                  context: context,
                  title: "内置浏览器",
                  topRadius: true,
                  bottomRadius: true,
                  onTap: () {
                    setState(() {
                      inAppBrowser = !inAppBrowser;
                      HiveUtil.put(
                          key: HiveUtil.inappWebviewKey, value: inAppBrowser);
                    });
                  },
                ),
              ..._traySetting(),
              const SizedBox(height: 10),
              ItemBuilder.buildRadioItem(
                value: autoCheckUpdate,
                topRadius: true,
                context: context,
                title: "自动检查更新",
                onTap: () {
                  setState(() {
                    autoCheckUpdate = !autoCheckUpdate;
                    HiveUtil.put(
                        key: HiveUtil.autoCheckUpdateKey,
                        value: autoCheckUpdate);
                  });
                },
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.checkUpdates,
                bottomRadius: true,
                description: latestVersion.compareTo(currentVersion) > 0
                    ? "新版本：$latestVersion"
                    : S.current.checkUpdatesAlreadyLatest,
                descriptionColor: latestVersion.compareTo(currentVersion) > 0
                    ? Colors.redAccent
                    : null,
                tip: currentVersion,
                onTap: () {
                  fetchReleases(true);
                },
              ),
              const SizedBox(height: 10),
              if (ResponsiveUtil.isMobile())
                ItemBuilder.buildEntryItem(
                  context: context,
                  title: S.current.clearCache,
                  topRadius: true,
                  bottomRadius: true,
                  tip: _cacheSize,
                  onTap: () {
                    CustomLoadingDialog.showLoading(context, title: "清除缓存中...");
                    getTemporaryDirectory().then((tempDir) {
                      CacheUtil.delDir(tempDir).then((value) {
                        CacheUtil.loadCache().then((value) {
                          setState(() {
                            _cacheSize = value;
                            CustomLoadingDialog.dismissLoading(context);
                            IToast.showTop(context,
                                text: S.current.clearCacheSuccess);
                          });
                        });
                      });
                    });
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  _traySetting() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "关闭主界面时",
        tip: enableCloseToTray ? "最小化到系统托盘" : "退出Loftify",
        topRadius: true,
        bottomRadius: true,
        onTap: () {
          List<Tuple2<String, dynamic>> options = [
            const Tuple2("最小化到系统托盘", 0),
            const Tuple2("退出Loftify", 1),
          ];
          BottomSheetBuilder.showListBottomSheet(
            context,
            (sheetContext) => TileList.fromOptions(
              options,
              (idx) {
                Navigator.pop(sheetContext);
                if (idx == 0) {
                  setState(() {
                    enableCloseToTray = true;
                    HiveUtil.put(
                        key: HiveUtil.enableCloseToTrayKey,
                        value: enableCloseToTray);
                  });
                } else if (idx == 1) {
                  setState(() {
                    enableCloseToTray = false;
                    HiveUtil.put(
                        key: HiveUtil.enableCloseToTrayKey,
                        value: enableCloseToTray);
                  });
                }
              },
              selected: enableCloseToTray ? 0 : 1,
              title: "关闭主界面时",
              context: context,
              onCloseTap: () => Navigator.pop(sheetContext),
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          );
        },
      ),
    ];
  }
}
