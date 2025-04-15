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
  bool _showPostDetailFloatingOperationBar =
      HiveUtil.getBool(HiveUtil.showPostDetailFloatingOperationBarKey);
  bool _showPostDetailFloatingOperationBarOnlyInArticle = HiveUtil.getBool(
      HiveUtil.showPostDetailFloatingOperationBarOnlyInArticleKey,
      defaultValue: false);

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
        appBar: ItemBuilder.buildResponsiveAppBar(
          showBack: true,
          title: S.current.appearanceSetting,
          context: context,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  roundBottom: true,
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
                  title: S.current.useDesktopLayoutWhenLandscape,
                  roundTop: true,
                  roundBottom: true,
                  onTap: () {
                    setState(() {
                      _enableLandscapeInTablet = !_enableLandscapeInTablet;
                      appProvider.enableLandscapeInTablet =
                          _enableLandscapeInTablet;
                    });
                  },
                ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.home),
              ItemBuilder.buildRadioItem(
                value: _showRecommendArticle,
                context: context,
                title: S.current.showArticleInRecommendFlow,
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
                title: S.current.showVideoInRecommendFlow,
                roundBottom: true,
                onTap: () {
                  setState(() {
                    _showRecommendVideo = !_showRecommendVideo;
                    HiveUtil.put(
                        HiveUtil.showRecommendVideoKey, _showRecommendVideo);
                  });
                },
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.searchResultPage),
              ItemBuilder.buildRadioItem(
                value: _showSearchHistory,
                context: context,
                title: S.current.recordSearchHistory,
                description: S.current.recordSearchHistoryDescription,
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
                title: S.current.guessYouLike,
                description: S.current.guessYouLikeDescription,
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
                title: S.current.externalLinkCards,
                description: S.current.externalLinkCardsDescription,
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
                title: S.current.hotRank,
                description: S.current.hotRankDescription,
                roundBottom: true,
                onTap: () {
                  setState(() {
                    _showSearchRank = !_showSearchRank;
                    HiveUtil.put(HiveUtil.showSearchRankKey, _showSearchRank);
                  });
                },
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.postDetailPage),
              ItemBuilder.buildRadioItem(
                value: _showCollectionPreNext,
                context: context,
                title: S.current.showCollectionPreNext,
                description: S.current.showCollectionPreNextDescription,
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
                title: S.current.showDownloadButton,
                description: S.current.showDownloadButtonDescription,
                onTap: () {
                  setState(() {
                    _showDownload = !_showDownload;
                    HiveUtil.put(HiveUtil.showDownloadKey, _showDownload);
                  });
                },
              ),
              ItemBuilder.buildRadioItem(
                value: _showPostDetailFloatingOperationBar,
                context: context,
                title: S.current.showPostDetailFloatingOperationBar,
                description:
                    S.current.showPostDetailFloatingOperationBarDescription,
                roundBottom: !_showPostDetailFloatingOperationBar,
                onTap: () {
                  setState(() {
                    _showPostDetailFloatingOperationBar =
                        !_showPostDetailFloatingOperationBar;
                    HiveUtil.put(HiveUtil.showPostDetailFloatingOperationBarKey,
                        _showPostDetailFloatingOperationBar);
                  });
                },
              ),
              if (_showPostDetailFloatingOperationBar)
                ItemBuilder.buildRadioItem(
                  value: _showPostDetailFloatingOperationBarOnlyInArticle,
                  context: context,
                  title:
                      S.current.showPostDetailFloatingOperationBarOnlyInArticle,
                  roundBottom: true,
                  onTap: () {
                    setState(() {
                      _showPostDetailFloatingOperationBarOnlyInArticle =
                          !_showPostDetailFloatingOperationBarOnlyInArticle;
                      HiveUtil.put(
                          HiveUtil
                              .showPostDetailFloatingOperationBarOnlyInArticleKey,
                          _showPostDetailFloatingOperationBarOnlyInArticle);
                    });
                  },
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
