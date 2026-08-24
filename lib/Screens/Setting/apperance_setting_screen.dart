import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Screens/Setting/select_font_screen.dart';
import 'package:loftify/Screens/Setting/select_theme_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

class AppearanceSettingScreen extends BaseSettingScreen {
  const AppearanceSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/apperance";

  @override
  State<AppearanceSettingScreen> createState() =>
      _AppearanceSettingScreenState();
}

class _AppearanceSettingScreenState
    extends BaseDynamicState<AppearanceSettingScreen>
    with TickerProviderStateMixin {
  bool _enableLandscapeInTablet = ChewieHiveUtil.getBool(
      HiveUtil.enableLandscapeInTabletKey,
      defaultValue: true);
  bool _showRecommendVideo = ChewieHiveUtil.getBool(
      HiveUtil.showRecommendVideoKey,
      defaultValue: false);
  bool _showRecommendArticle = ChewieHiveUtil.getBool(
      HiveUtil.showRecommendArticleKey,
      defaultValue: false);
  bool _showSearchHistory =
      ChewieHiveUtil.getBool(HiveUtil.showSearchHistoryKey, defaultValue: true);
  bool _showSearchGuess =
      ChewieHiveUtil.getBool(HiveUtil.showSearchGuessKey, defaultValue: true);
  bool _showSearchConfig =
      ChewieHiveUtil.getBool(HiveUtil.showSearchConfigKey, defaultValue: false);
  bool _showSearchRank =
      ChewieHiveUtil.getBool(HiveUtil.showSearchRankKey, defaultValue: true);
  bool _showCollectionPreNext = ChewieHiveUtil.getBool(
      HiveUtil.showCollectionPreNextKey,
      defaultValue: true);
  bool _showDownload =
      ChewieHiveUtil.getBool(HiveUtil.showDownloadKey, defaultValue: true);
  bool _showPostDetailFloatingOperationBar =
      ChewieHiveUtil.getBool(HiveUtil.showPostDetailFloatingOperationBarKey);
  bool _showPostDetailFloatingOperationBarOnlyInArticle =
      ChewieHiveUtil.getBool(
          HiveUtil.showPostDetailFloatingOperationBarOnlyInArticleKey,
          defaultValue: false);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.appearanceSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        CaptionItem(
          title: appLocalizations.themeSetting,
          children: [
            Selector<AppProvider, ActiveThemeMode>(
              selector: (context, globalProvider) => globalProvider.themeMode,
              builder: (context, themeMode, child) =>
                  InlineSelectionItem<SelectionItemModel<ActiveThemeMode>>(
                hint: appLocalizations.chooseThemeMode,
                title: appLocalizations.themeMode,
                items: ChewieProvider.getSupportedThemeMode(),
                initItem: SelectionItemModel(
                  ChewieProvider.getThemeModeLabel(themeMode),
                  themeMode,
                ),
                onChanged: (SelectionItemModel<ActiveThemeMode>? item) {
                  appProvider.themeMode = item!.value;
                },
              ),
            ),
            Selector<AppProvider, ChewieThemeColorData>(
              selector: (context, appProvider) => appProvider.lightTheme,
              builder: (context, lightTheme, child) =>
                  Selector<AppProvider, ChewieThemeColorData>(
                selector: (context, appProvider) => appProvider.darkTheme,
                builder: (context, darkTheme, child) => EntryItem(
                  tip: "${lightTheme.i18nName}/${darkTheme.i18nName}",
                  title: appLocalizations.selectTheme,
                  onTap: () {
                    RouteUtil.pushDialogRoute(
                        context, const SelectThemeScreen());
                  },
                ),
              ),
            ),
            Selector<AppProvider, CustomFont>(
              selector: (context, appProvider) => appProvider.currentFont,
              builder: (context, currentFont, child) => EntryItem(
                tip: currentFont.intlFontName,
                title: appLocalizations.chooseFontFamily,
                onTap: () {
                  RouteUtil.pushDialogRoute(context, const SelectFontScreen());
                },
              ),
            ),
          ],
        ),
        CaptionItem(
          title: appLocalizations.mobileSetting,
          children: [
            if (ResponsiveUtil.isTablet())
              CheckboxItem(
                value: _enableLandscapeInTablet,
                title: appLocalizations.useDesktopLayoutWhenLandscape,
                description: appLocalizations.haveToRestartWhenChange,
                onTap: () {
                  setState(() {
                    _enableLandscapeInTablet = !_enableLandscapeInTablet;
                    appProvider.enableLandscapeInTablet =
                        _enableLandscapeInTablet;
                  });
                },
              ),
            Selector<AppProvider, bool>(
              selector: (context, appProvider) =>
                  appProvider.reduceTransparency,
              builder: (context, reduceTransparency, child) => CheckboxItem(
                value: reduceTransparency,
                title: appLocalizations.reduceTransparency,
                description: appLocalizations.reduceTransparencyDescription,
                roundBottom: true,
                onTap: () {
                  appProvider.reduceTransparency = !reduceTransparency;
                },
              ),
            ),
          ],
        ),
        CaptionItem(
          title: appLocalizations.home,
          children: [
            CheckboxItem(
              value: _showRecommendArticle,
              title: appLocalizations.showArticleInRecommendFlow,
              onTap: () {
                setState(() {
                  _showRecommendArticle = !_showRecommendArticle;
                  ChewieHiveUtil.put(
                      HiveUtil.showRecommendArticleKey, _showRecommendArticle);
                });
              },
            ),
            CheckboxItem(
              value: _showRecommendVideo,
              title: appLocalizations.showVideoInRecommendFlow,
              roundBottom: true,
              onTap: () {
                setState(() {
                  _showRecommendVideo = !_showRecommendVideo;
                  ChewieHiveUtil.put(
                      HiveUtil.showRecommendVideoKey, _showRecommendVideo);
                });
              },
            ),
          ],
        ),
        CaptionItem(
          title: appLocalizations.searchResultPage,
          children: [
            CheckboxItem(
              value: _showSearchHistory,
              title: appLocalizations.recordSearchHistory,
              description: appLocalizations.recordSearchHistoryDescription,
              onTap: () {
                setState(() {
                  _showSearchHistory = !_showSearchHistory;
                  ChewieHiveUtil.put(
                      HiveUtil.showSearchHistoryKey, _showSearchHistory);
                  appProvider.searchHistoryList = [];
                });
              },
            ),
            CheckboxItem(
              value: _showSearchGuess,
              title: appLocalizations.guessYouLike,
              description: appLocalizations.guessYouLikeDescription,
              onTap: () {
                setState(() {
                  _showSearchGuess = !_showSearchGuess;
                  ChewieHiveUtil.put(
                      HiveUtil.showSearchGuessKey, _showSearchGuess);
                });
              },
            ),
            CheckboxItem(
              value: _showSearchConfig,
              title: appLocalizations.externalLinkCards,
              description: appLocalizations.externalLinkCardsDescription,
              onTap: () {
                setState(() {
                  _showSearchConfig = !_showSearchConfig;
                  ChewieHiveUtil.put(
                      HiveUtil.showSearchConfigKey, _showSearchConfig);
                });
              },
            ),
            CheckboxItem(
              value: _showSearchRank,
              title: appLocalizations.hotRank,
              description: appLocalizations.hotRankDescription,
              roundBottom: true,
              onTap: () {
                setState(() {
                  _showSearchRank = !_showSearchRank;
                  ChewieHiveUtil.put(
                      HiveUtil.showSearchRankKey, _showSearchRank);
                });
              },
            ),
          ],
        ),
        CaptionItem(
          title: appLocalizations.postDetailPage,
          children: [
            CheckboxItem(
              value: _showCollectionPreNext,
              title: appLocalizations.showCollectionPreNext,
              description: appLocalizations.showCollectionPreNextDescription,
              onTap: () {
                setState(() {
                  _showCollectionPreNext = !_showCollectionPreNext;
                  ChewieHiveUtil.put(HiveUtil.showCollectionPreNextKey,
                      _showCollectionPreNext);
                });
              },
            ),
            CheckboxItem(
              value: _showDownload,
              title: appLocalizations.showDownloadButton,
              description: appLocalizations.showDownloadButtonDescription,
              onTap: () {
                setState(() {
                  _showDownload = !_showDownload;
                  ChewieHiveUtil.put(HiveUtil.showDownloadKey, _showDownload);
                });
              },
            ),
            CheckboxItem(
              value: _showPostDetailFloatingOperationBar,
              title: appLocalizations.showPostDetailFloatingOperationBar,
              description: appLocalizations
                  .showPostDetailFloatingOperationBarDescription,
              roundBottom: !_showPostDetailFloatingOperationBar,
              onTap: () {
                setState(() {
                  _showPostDetailFloatingOperationBar =
                      !_showPostDetailFloatingOperationBar;
                  ChewieHiveUtil.put(
                      HiveUtil.showPostDetailFloatingOperationBarKey,
                      _showPostDetailFloatingOperationBar);
                });
              },
            ),
            if (_showPostDetailFloatingOperationBar)
              CheckboxItem(
                value: _showPostDetailFloatingOperationBarOnlyInArticle,
                title: appLocalizations
                    .showPostDetailFloatingOperationBarOnlyInArticle,
                roundBottom: true,
                onTap: () {
                  setState(() {
                    _showPostDetailFloatingOperationBarOnlyInArticle =
                        !_showPostDetailFloatingOperationBarOnlyInArticle;
                    ChewieHiveUtil.put(
                        HiveUtil
                            .showPostDetailFloatingOperationBarOnlyInArticleKey,
                        _showPostDetailFloatingOperationBarOnlyInArticle);
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
