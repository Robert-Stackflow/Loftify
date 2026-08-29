import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/search_api.dart';
import 'package:loftify/Models/search_response.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/collection_detail_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Screens/Post/search_result_screen.dart';
import 'package:loftify/Screens/Post/tag_detail_screen.dart';
import 'package:loftify/Screens/Post/video_detail_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:provider/provider.dart';

import '../../Utils/hive_util.dart';
import '../../Utils/tab_state_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../Widgets/Navigation/loftify_floating_navigation_header.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const String routeName = "/search";

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends BaseDynamicState<SearchScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScrollToHideMixin,
        BottomNavgationMixin {
  @override
  bool get wantKeepAlive => true;

  List<GuessKeyword> _guessList = [];
  List<RankListItem> _rankList = [];
  List<ConfigListItem> _configList = [];
  List<SearchSuggestItem> _sugList = [];
  TabController? _tabController;
  final SwiperController _swiperController = SwiperController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _tabLabelList = [];
  final List<String> _tabIdList = [];
  int _currentTabIndex = 0;
  final FocusNode _focusNode = FocusNode();

  bool get hasSearchFocus => _focusNode.hasFocus;

  void focusSearch() => _focusSearch();

  @override
  FutureOr onTapBottomNavigation() {
    _focusSearch();
  }

  @override
  void initState() {
    super.initState();
    fetchGuessList();
    fetchRankList();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        _sugList.clear();
        if (mounted) setState(() {});
      } else {
        _performSuggest(_searchController.text);
      }
    });
    if (ResponsiveUtil.isDesktop()) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) FocusScope.of(context).requestFocus(_focusNode);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => panelScreenState?.refreshScrollControllers());
  }

  void initTab() {
    _tabLabelList.clear();
    _tabIdList.clear();
    for (var e in _rankList) {
      _tabLabelList.add(e.listName);
      _tabIdList.add('rank:${e.type}:${e.sortNo}');
    }
    _tabController?.dispose();
    _currentTabIndex = PersistentTabState.restore(
      idKey: HiveUtil.searchRankTabIdKey,
      legacyIndexKey: HiveUtil.searchRankTabIndexKey,
      itemIds: _tabIdList,
    ).index;
    _tabController = TabController(
      length: _tabLabelList.length,
      initialIndex: _currentTabIndex,
      vsync: this,
    );
    _tabController!.addListener(() {
      final index =
          (_tabController!.animation?.value ?? _tabController!.index).round();
      if (index != _currentTabIndex) _setCurrentTab(index);
    });
  }

  void _setCurrentTab(int index) {
    final safeIndex = TabStatePreference.restoreIndex(
      index,
      _tabLabelList.length,
    );
    if (safeIndex == _currentTabIndex) return;
    setState(() => _currentTabIndex = safeIndex);
    PersistentTabState.save(
      idKey: HiveUtil.searchRankTabIdKey,
      legacyIndexKey: HiveUtil.searchRankTabIndexKey,
      itemIds: _tabIdList,
      index: safeIndex,
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _swiperController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _focusSearch() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  fetchGuessList() {
    SearchApi.getGuessList().then((value) {
      if (value['code'] != 0) {
        IToast.showTop(value['msg']);
      } else {
        if (value['data']['guessKeywords'] != null) {
          _guessList = (value['data']['guessKeywords'] as List)
              .map((e) => GuessKeyword.fromJson(e))
              .toList();
        }
        if (mounted) setState(() {});
      }
    });
  }

  fetchRankList() {
    SearchApi.getRankList().then((value) {
      if (value['code'] != 0) {
        IToast.showTop(value['msg']);
      } else {
        if (value['data']['rankList'] != null) {
          _rankList = (value['data']['rankList'] as List)
              .map((e) => RankListItem.fromJson(e))
              .toList();
          initTab();
        }
        if (value['data']['configList'] != null) {
          _configList = (value['data']['configList'] as List)
              .map((e) => ConfigListItem.fromJson(e))
              .toList();
        }
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      body: Column(
        children: [
          _buildNavigationHeader(),
          Expanded(
            child: Stack(
              children: [
                _buildMainBody(),
                if (_sugList.isNotEmpty) _buildSuggestList(),
              ],
            ),
          ),
        ],
      ),
      extendBody: true,
    );
  }

  _performSearch(String str) async {
    if (str.isEmpty) return;
    Utils.addSearchHistory(str);
    bool processed = await UriUtil.processUrl(context, str, quiet: true);
    if (!processed) {
      RouteUtil.pushPanelCupertinoRoute(
          context, SearchResultScreen(searchKey: str));
    }
  }

  _jumpToTag(String tag) {
    Utils.addSearchHistory(tag);
    RouteUtil.pushPanelCupertinoRoute(context, TagDetailScreen(tag: tag));
  }

  _performSuggest(String str) {
    SearchApi.getSuggestList(key: str).then((value) {
      if (value['code'] != 0) {
        IToast.showTop(value['msg']);
      } else {
        if (value['data']['items'] != null &&
            _searchController.text.isNotEmpty) {
          _sugList = (value['data']['items'] as List)
              .map((e) => SearchSuggestItem.fromJson(e))
              .toList();
        }
        if (mounted) setState(() {});
      }
    });
  }

  _buildSuggestList() {
    return Container(
      color: ChewieTheme.getBackground(context),
      child: ListView.builder(
        itemCount: _sugList.length,
        itemBuilder: (context, index) {
          return ClickableWrapper(
              child: _buildSuggestItem(index, _sugList[index]));
        },
      ),
    );
  }

  _buildSuggestItem(int index, SearchSuggestItem item) {
    switch (item.type) {
      case 0:
        return LoftifyItemBuilder.buildRankTagRow(context, item.tagInfo!,
            onTap: () {
          _jumpToTag(item.tagInfo!.tagName);
        });
      case 1:
        return LoftifyItemBuilder.buildTagRow(context, item.tagInfo!,
            onTap: () {
          _performSearch(item.tagInfo!.tagName);
        });
      case 2:
        return LoftifyItemBuilder.buildUserRow(context, item.blogData!,
            onTap: () {
          Utils.addSearchHistory(_searchController.text);
          RouteUtil.pushPanelCupertinoRoute(
            context,
            UserDetailScreen(
              blogId: item.blogData!.blogInfo.blogId,
              blogName: item.blogData!.blogInfo.blogName,
            ),
          );
        });
      default:
        return emptyWidget;
    }
  }

  _buildMainBody() {
    bool showSearchHistory = ChewieHiveUtil.getBool(
        HiveUtil.showSearchHistoryKey,
        defaultValue: false);
    bool showSearchGuess = ChewieHiveUtil.getBool(HiveUtil.showSearchGuessKey,
        defaultValue: false);
    bool showSearchConfig = ChewieHiveUtil.getBool(HiveUtil.showSearchConfigKey,
        defaultValue: true);
    bool showSearchRank =
        ChewieHiveUtil.getBool(HiveUtil.showSearchRankKey, defaultValue: false);
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (showSearchHistory)
                Selector<AppProvider, List<String>>(
                  selector: (context, globalProvider) =>
                      globalProvider.searchHistoryList,
                  builder: (context, searchHistoryList, child) =>
                      searchHistoryList.isNotEmpty
                          ? ItemBuilder.buildTitle(
                              context,
                              title: appLocalizations.searchRecently,
                              icon: LoftifyIcons.delete,
                              onTap: () {
                                DialogBuilder.showConfirmDialog(
                                  context,
                                  title: appLocalizations.clearSearchHistory,
                                  message: appLocalizations
                                      .clearSearchHistoryMessage,
                                  onTapConfirm: () {
                                    appProvider.searchHistoryList = [];
                                  },
                                );
                              },
                            )
                          : emptyWidget,
                ),
              if (showSearchHistory)
                Selector<AppProvider, List<String>>(
                  selector: (context, globalProvider) =>
                      globalProvider.searchHistoryList,
                  builder: (context, searchHistoryList, child) =>
                      ItemBuilder.buildWrapTagList(context, searchHistoryList,
                          onTap: (str) {
                    _performSearch(str);
                  }),
                ),
              if (showSearchGuess && _guessList.isNotEmpty)
                ItemBuilder.buildTitle(
                  context,
                  title: appLocalizations.guessYouSearch,
                  icon: LoftifyIcons.refresh,
                  onTap: () {
                    fetchGuessList();
                  },
                ),
              if (showSearchGuess && _guessList.isNotEmpty)
                ItemBuilder.buildWrapTagList(
                    context, _guessList.map((e) => e.keyword).toList(),
                    onTap: (str) {
                  _performSearch(str);
                }),
              if (showSearchConfig && _configList.isNotEmpty)
                _buildConfigList(),
            ],
          ),
        ),
        if (showSearchRank && _tabLabelList.isNotEmpty)
          SliverPersistentHeader(
            key: ValueKey(StringUtil.getRandomString()),
            pinned: true,
            delegate: SliverAppBarDelegate(
              radius: 0,
              background: ChewieTheme.getBackground(context),
              tabBar: TabBarWrapper(
                tabController: _tabController!,
                tabs: _tabLabelList
                    .asMap()
                    .entries
                    .map(
                      (entry) => ItemBuilder.buildAnimatedTab(
                        context,
                        selected: entry.key == _currentTabIndex,
                        text: entry.value,
                        controller: _tabController,
                        tabIndex: entry.key,
                        fontSizeDelta: -2,
                        normalUserBold: true,
                      ),
                    )
                    .toList(),
                onTap: (index) {
                  _setCurrentTab(index);
                  _swiperController.move(index);
                },
              ),
            ),
          ),
        if (showSearchRank && _tabLabelList.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildRankList(),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20))
      ],
    );
  }

  _buildRankList() {
    return SizedBox(
      height: 945,
      child: Swiper(
        controller: _swiperController,
        index: _currentTabIndex,
        loop: false,
        control: null,
        viewportFraction: 0.93,
        scrollDirection: Axis.horizontal,
        itemCount: _rankList.length,
        itemBuilder: (context, index) {
          return _buildRankListItem(index, _rankList[index]);
        },
        onIndexChanged: (index) {
          _setCurrentTab(index);
          _tabController?.animateTo(index);
        },
      ),
    );
  }

  Widget _buildRankListItem(int rankIndex, RankListItem item) {
    item.hotLists.removeWhere((e) => e.pv == 0 && e.score == null);
    return Container(
      margin:
          EdgeInsets.only(right: rankIndex == _rankList.length - 1 ? 0 : 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).cardColor.withAlpha(200),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: item.hotLists.length,
          itemBuilder: (context, index) {
            return ClickableWrapper(
                child: _buildRankItem(
                    index, item.rankListType, item.hotLists[index]));
          },
        ),
      ),
    );
  }

  Widget _buildRankItem(int index, RankListType type, RankItem item) {
    bool showImage = ((type == RankListType.post && item.postType != 1) ||
            (type == RankListType.collection)) &&
        StringUtil.isNotEmpty(item.img);
    bool showText = type == RankListType.post && item.postType == 1;
    return GestureDetector(
      onTap: () async {
        switch (type) {
          case RankListType.tag:
            _performSearch(item.title);
            break;
          case RankListType.tagRank:
            _jumpToTag(item.title);
            break;
          case RankListType.unset:
            break;
          case RankListType.post:
            if (LoftifyUriUtil.isPostUrl(item.url)) {
              Map<String, String> map =
                  LoftifyUriUtil.extractPostInfo(item.url);
              RouteUtil.pushPanelCupertinoRoute(
                context,
                PostDetailScreen(
                  meta: map,
                  isArticle: showText,
                ),
              );
            } else if (LoftifyUriUtil.isVideoUrl(item.url)) {
              Map<String, String> map =
                  LoftifyUriUtil.extractVideoInfo(item.url);
              if (ResponsiveUtil.isDesktop()) {
                IToast.showTop(appLocalizations.unSupportVideoInDesktop);
              } else {
                RouteUtil.pushPanelCupertinoRoute(
                  context,
                  VideoDetailScreen(meta: map),
                );
              }
            }
            break;
          case RankListType.collection:
            if (LoftifyUriUtil.isCollectionUrl(item.url)) {
              int collectionId = LoftifyUriUtil.extractCollectionId(item.url);
              if (collectionId != 0) {
                RouteUtil.pushPanelCupertinoRoute(
                  context,
                  CollectionDetailScreen(
                    collectionId: collectionId,
                    blogId: 0,
                    blogName: "",
                    postId: 0,
                  ),
                );
              }
            }
            break;
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 30,
        child: Row(
          children: [
            if (item.icon.isNotEmpty)
              Container(
                width: 20,
                alignment: Alignment.center,
                child: ChewieItemBuilder.buildCachedImage(
                  imageUrl: item.icon,
                  context: context,
                  showLoading: false,
                  placeholderBackground: Colors.transparent,
                  width: 12,
                  height: 12,
                  fit: BoxFit.cover,
                ),
              ),
            if (item.icon.isEmpty)
              Container(
                width: 20,
                alignment: Alignment.center,
                child: Text(
                  "${index + 1}",
                  style: Theme.of(context).textTheme.labelLarge?.apply(
                        fontWeightDelta: 2,
                        color: index > 2
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : ChewieColors.likeButtonColor,
                      ),
                ),
              ),
            const SizedBox(width: 8),
            if (showImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ChewieItemBuilder.buildCachedImage(
                  imageUrl: item.img!,
                  context: context,
                  showLoading: false,
                  placeholderBackground: Colors.transparent,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            if (showText)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Theme.of(context).dividerColor, width: 2),
                ),
                child: Text(
                  StringUtil.clearBlank(
                      HtmlUtil.extractTextFromHtml(item.postDigest ?? "")),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.apply(fontSizeDelta: -9),
                ),
              ),
            if (showText || showImage) const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.apply(
                      fontWeightDelta: 2,
                      fontSizeDelta: -1,
                    ),
              ),
            ),
            const SizedBox(width: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                item.pv != 0
                    ? appLocalizations
                        .searchingCount(StringUtil.formatCount(item.pv))
                    : "${item.score}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.apply(
                      fontWeightDelta: 2,
                    ),
              ),
            ),
            const SizedBox(width: 3),
            if (item.trend == 1)
              const ChewieIcon(
                LoftifyIcons.trendUp,
                color: ChewieColors.likeButtonColor,
                size: 12,
              ),
            if (item.trend == 2)
              const ChewieIcon(
                LoftifyIcons.trendDown,
                color: ChewieColors.likeButtonColor,
                size: 12,
              ),
            if (item.trend == 0) const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigList() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: _configList.length,
        itemBuilder: (context, index) {
          return _buildConfigItem(_configList[index]);
        },
      ),
    );
  }

  Widget _buildConfigItem(ConfigListItem item) {
    List<String> images = item.imageUrl.split(",");
    return GestureDetector(
      onTap: () {
        if (item.linkUrl.isNotEmpty) {
          UriUtil.processUrl(
            context,
            item.linkUrl,
            pass: true,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ChewieItemBuilder.buildCachedImage(
                imageUrl: ColorUtil.isDark(context) ? images[0] : images[1],
                context: context,
                width: 130,
                height: 50,
                showLoading: false,
                placeholderBackground: Colors.transparent,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.apply(fontSizeDelta: -1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.apply(fontSizeDelta: -1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return LoftifyNavigationHeader(
      child: Selector<AppProvider, bool>(
        selector: (_, provider) => provider.reduceTransparency,
        builder: (context, reduceTransparency, _) => LayoutBuilder(
          builder: (context, _) {
            const gap = 8.0;
            return Row(
              children: [
                LoftifyNavigationAvatarButton(
                  key: const ValueKey('search-navigation-avatar'),
                  semanticLabel: appLocalizations.mine,
                  enableBlur: !reduceTransparency,
                  onPressed: _openMine,
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: LoftifyFloatingCapsule(
                    key: const ValueKey('expanded-search-capsule'),
                    enableBlur: !reduceTransparency,
                    padding: const EdgeInsets.only(left: 4),
                    child: _buildSearchBar(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openMine() {
    appProvider.sidebarChoice = SideBarChoice.Mine;
    panelScreenState?.popAll(false);
  }

  Widget _buildSearchBar() {
    return ItemBuilder.buildSearchBar(
      context: context,
      background: Colors.transparent,
      borderRadius: context.design.radii.full,
      hintFontSizeDelta: 0,
      focusNode: _focusNode,
      controller: _searchController,
      hintText: appLocalizations.searchHint,
      onSubmitted: (text) async {
        _performSearch(text);
      },
    );
  }

  @override
  List<ScrollController> getScrollControllers() {
    return [_scrollController];
  }
}
