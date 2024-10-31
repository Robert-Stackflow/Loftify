import 'package:flutter/material.dart';
import 'package:loftify/Resources/fonts.dart';
import 'package:loftify/Screens/Setting/select_font_screen.dart';
import 'package:loftify/Screens/Setting/select_theme_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:provider/provider.dart';

import '../../Resources/theme_color_data.dart';
import '../../Utils/enums.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class AppearanceSettingScreen extends StatefulWidget {
  const AppearanceSettingScreen({super.key});

  static const String routeName = "/setting/apperance";

  @override
  State<AppearanceSettingScreen> createState() =>
      _AppearanceSettingScreenState();
}

class _AppearanceSettingScreenState extends State<AppearanceSettingScreen>
    with TickerProviderStateMixin {
  bool _enableLandscapeInTablet =
      HiveUtil.getBool(HiveUtil.enableLandscapeInTabletKey, defaultValue: true);
  bool _showRecommendVideo =
      HiveUtil.getBool(HiveUtil.showRecommendVideoKey, defaultValue: false);
  bool _showRecommendArticle =
      HiveUtil.getBool(HiveUtil.showRecommendArticleKey, defaultValue: false);
  bool _showSearchHistory =
      HiveUtil.getBool(HiveUtil.showSearchHistoryKey, defaultValue: true);
  bool _showSearchGuess =
      HiveUtil.getBool(HiveUtil.showSearchGuessKey, defaultValue: true);
  bool _showSearchConfig =
      HiveUtil.getBool(HiveUtil.showSearchConfigKey, defaultValue: false);
  bool _showSearchRank =
      HiveUtil.getBool(HiveUtil.showSearchRankKey, defaultValue: true);
  bool _showCollectionPreNext =
      HiveUtil.getBool(HiveUtil.showCollectionPreNextKey, defaultValue: true);
  bool _showDownload =
      HiveUtil.getBool(HiveUtil.showDownloadKey, defaultValue: true);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildDesktopAppBar(
          transparent: true,
          showBack: true,
          title: S.current.appearanceSetting,
          context: context,
          background: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              if (ResponsiveUtil.isLandscape()) const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.themeSetting),
              Selector<AppProvider, ActiveThemeMode>(
                selector: (context, globalProvider) => globalProvider.themeMode,
                builder: (context, themeMode, child) =>
                    ItemBuilder.buildEntryItem(
                  context: context,
                  title: S.current.themeMode,
                  tip: AppProvider.getThemeModeLabel(themeMode),
                  onTap: () {
                    BottomSheetBuilder.showListBottomSheet(
                      context,
                      (context) => TileList.fromOptions(
                        AppProvider.getSupportedThemeMode(),
                        (item2) {
                          appProvider.themeMode = item2;
                          Navigator.pop(context);
                        },
                        selected: themeMode,
                        context: context,
                        title: S.current.chooseThemeMode,
                        onCloseTap: () => Navigator.pop(context),
                      ),
                    );
                  },
                ),
              ),
              Selector<AppProvider, ThemeColorData>(
                selector: (context, appProvider) => appProvider.lightTheme,
                builder: (context, lightTheme, child) =>
                    Selector<AppProvider, ThemeColorData>(
                  selector: (context, appProvider) => appProvider.darkTheme,
                  builder: (context, darkTheme, child) =>
                      ItemBuilder.buildEntryItem(
                    context: context,
                    title: S.current.selectTheme,
                    tip: "${lightTheme.name}/${darkTheme.name}",
                    onTap: () {
                      RouteUtil.pushPanelCupertinoRoute(
                          context, const SelectThemeScreen());
                    },
                  ),
                ),
              ),
              Selector<AppProvider, CustomFont>(
                selector: (context, appProvider) => appProvider.currentFont,
                builder: (context, currentFont, child) =>
                    ItemBuilder.buildEntryItem(
                  context: context,
                  title: S.current.chooseFontFamily,
                  tip: currentFont.intlFontName,
                  bottomRadius: true,
                  onTap: () {
                    RouteUtil.pushPanelCupertinoRoute(
                        context, const SelectFontScreen());
                  },
                ),
              ),
              if (ResponsiveUtil.isTablet()) const SizedBox(height: 10),
              if (ResponsiveUtil.isTablet())
                ItemBuilder.buildRadioItem(
                  value: _enableLandscapeInTablet,
                  context: context,
                  title: "横屏时启用桌面端布局",
                  description: "更改后需要重启",
                  topRadius: true,
                  bottomRadius: true,
                  onTap: () {
                    setState(() {
                      _enableLandscapeInTablet = !_enableLandscapeInTablet;
                      appProvider.enableLandscapeInTablet =
                          _enableLandscapeInTablet;
                    });
                  },
                ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(context: context, title: "首页"),
              ItemBuilder.buildRadioItem(
                value: _showRecommendArticle,
                context: context,
                title: "推荐流显示文章",
                onTap: () {
                  setState(() {
                    _showRecommendArticle = !_showRecommendArticle;
                    HiveUtil.put(HiveUtil.showRecommendArticleKey,
                        _showRecommendArticle);
                  });
                },
              ),
              ItemBuilder.buildRadioItem(
                value: _showRecommendVideo,
                context: context,
                title: "推荐流显示视频",
                bottomRadius: true,
                onTap: () {
                  setState(() {
                    _showRecommendVideo = !_showRecommendVideo;
                    HiveUtil.put(
                        HiveUtil.showRecommendVideoKey, _showRecommendVideo);
                  });
                },
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(context: context, title: "搜索结果页"),
              ItemBuilder.buildRadioItem(
                value: _showSearchHistory,
                context: context,
                title: "搜索历史",
                description: "取消勾选将清空并不再记录搜索历史",
                onTap: () {
                  setState(() {
                    _showSearchHistory = !_showSearchHistory;
                    HiveUtil.put(
                        HiveUtil.showSearchHistoryKey, _showSearchHistory);
                    appProvider.searchHistoryList = [];
                  });
                },
              ),
              ItemBuilder.buildRadioItem(
                value: _showSearchGuess,
                context: context,
                title: "猜你想搜",
                description: "搜索结果页显示猜你想搜",
                onTap: () {
                  setState(() {
                    _showSearchGuess = !_showSearchGuess;
                    HiveUtil.put(HiveUtil.showSearchGuessKey, _showSearchGuess);
                  });
                },
              ),
              ItemBuilder.buildRadioItem(
                value: _showSearchConfig,
                context: context,
                title: "外链卡片",
                description: "搜索结果页显示外链卡片",
                onTap: () {
                  setState(() {
                    _showSearchConfig = !_showSearchConfig;
                    HiveUtil.put(
                        HiveUtil.showSearchConfigKey, _showSearchConfig);
                  });
                },
              ),
              ItemBuilder.buildRadioItem(
                value: _showSearchRank,
                context: context,
                title: "热门榜单",
                description: "搜索结果页显示热门榜单",
                bottomRadius: true,
                onTap: () {
                  setState(() {
                    _showSearchRank = !_showSearchRank;
                    HiveUtil.put(HiveUtil.showSearchRankKey, _showSearchRank);
                  });
                },
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(context: context, title: "详情页"),
              ItemBuilder.buildRadioItem(
                value: _showCollectionPreNext,
                context: context,
                title: "上下篇",
                description: "取消勾选将不显示上一篇、下一篇等入口",
                onTap: () {
                  setState(() {
                    _showCollectionPreNext = !_showCollectionPreNext;
                    HiveUtil.put(HiveUtil.showCollectionPreNextKey,
                        _showCollectionPreNext);
                  });
                },
              ),
              ItemBuilder.buildRadioItem(
                value: _showDownload,
                context: context,
                title: "下载按钮",
                description: "取消勾选将不显示下载全部图片按钮",
                bottomRadius: true,
                onTap: () {
                  setState(() {
                    _showDownload = !_showDownload;
                    HiveUtil.put(HiveUtil.showDownloadKey, _showDownload);
                  });
                },
              ),
              // ItemBuilder.buildEntryItem(
              //   context: context,
              //   title: "推荐流样式",
              //   tip: "瀑布流",
              //   onTap: () {},
              // ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
