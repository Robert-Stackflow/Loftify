import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/search_api.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Models/search_response.dart';
import 'package:loftify/Providers/provider_manager.dart';
import 'package:loftify/Resources/gaps.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/collection_detail_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Screens/Post/search_result_screen.dart';
import 'package:loftify/Screens/Post/tag_detail_screen.dart';
import 'package:loftify/Screens/Post/video_detail_screen.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Utils/route_util.dart';
import 'package:provider/provider.dart';

import '../../Providers/global_provider.dart';
import '../../Resources/colors.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Custom/custom_tab_indicator.dart';
import '../../Widgets/Custom/sliver_appbar_delegate.dart';
import '../../Widgets/Item/item_builder.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const String routeName = "/search";

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<GuessKeyword> _guessList = [];
  List<RankListItem> _rankList = [];
  List<ConfigListItem> _configList = [];
  List<SearchSuggestItem> _sugList = [];
  late TabController _tabController;
  final SwiperController _swiperController = SwiperController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _tabLabelList = [];
  int _currentTabIndex = 0;
  final FocusNode _focusNode = FocusNode();

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
    Future.delayed(const Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  initTab() {
    _tabLabelList.clear();
    for (var e in _rankList) {
      _tabLabelList.add(e.listName);
    }
    _tabController = TabController(length: _tabLabelList.length, vsync: this);
    _tabController.animation?.addListener(() {
      int indexChange =
          _tabController.offset.abs() > 0.8 ? _tabController.offset.round() : 0;
      int index = _tabController.index + indexChange;
      if (index != _currentTabIndex) {
        setState(() => _currentTabIndex = index);
      }
    });
  }

  fetchGuessList() {
    SearchApi.getGuessList().then((value) {
      if (value['code'] != 0) {
        IToast.showTop( value['msg']);
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
        IToast.showTop( value['msg']);
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
      backgroundColor: AppTheme.getBackground(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildSearchBar(),
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
      ),
    );
  }

  _performSearch(String str) async {
    Utils.addSearchHistory(str);
    bool processed = await UriUtil.processUrl(context, str, quiet: true);
    if (!processed) {
      RouteUtil.pushFadeRoute(context, SearchResultScreen(searchKey: str));
    }
  }

  _jumpToTag(String tag) {
    Utils.addSearchHistory(tag);
    RouteUtil.pushCupertinoRoute(context, TagDetailScreen(tag: tag));
  }

  _performSuggest(String str) {
    SearchApi.getSuggestList(key: str).then((value) {
      if (value['code'] != 0) {
        IToast.showTop( value['msg']);
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
      color: AppTheme.getBackground(context),
      padding: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        itemCount: _sugList.length,
        itemBuilder: (context, index) {
          return ItemBuilder.buildClickItem(
              _buildSuggestItem(index, _sugList[index]));
        },
      ),
    );
  }

  _buildSuggestItem(int index, SearchSuggestItem item) {
    switch (item.type) {
      case 0:
        return ItemBuilder.buildRankTagRow(context, item.tagInfo!, onTap: () {
          _jumpToTag(item.tagInfo!.tagName);
        });
      case 1:
        return ItemBuilder.buildTagRow(context, item.tagInfo!, onTap: () {
          _performSearch(item.tagInfo!.tagName);
        });
      case 2:
        return ItemBuilder.buildUserRow(context, item.blogData!, onTap: () {
          Utils.addSearchHistory(_searchController.text);
          RouteUtil.pushCupertinoRoute(
            context,
            UserDetailScreen(
              blogId: item.blogData!.blogInfo.blogId,
              blogName: item.blogData!.blogInfo.blogName,
            ),
          );
        });
      default:
        return Container();
    }
  }

  _buildMainBody() {
    bool showSearchHistory = HiveUtil.getBool(
        key: HiveUtil.showSearchHistoryKey, defaultValue: false);
    bool showSearchGuess =
        HiveUtil.getBool(key: HiveUtil.showSearchGuessKey, defaultValue: false);
    bool showSearchConfig =
        HiveUtil.getBool(key: HiveUtil.showSearchConfigKey, defaultValue: true);
    bool showSearchRank =
        HiveUtil.getBool(key: HiveUtil.showSearchRankKey, defaultValue: false);
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (showSearchHistory)
                Selector<GlobalProvider, List<String>>(
                  selector: (context, globalProvider) =>
                      globalProvider.searchHistoryList,
                  builder: (context, searchHistoryList, child) =>
                      searchHistoryList.isNotEmpty
                          ? ItemBuilder.buildTitle(
                              context,
                              title: "最近搜索",
                              icon: Icons.delete_outline_rounded,
                              onTap: () {
                                ProviderManager
                                    .globalProvider.searchHistoryList = [];
                              },
                            )
                          : MyGaps.empty,
                ),
              if (showSearchHistory)
                Selector<GlobalProvider, List<String>>(
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
                  title: "猜你想搜",
                  icon: Icons.refresh_rounded,
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
            key: ValueKey(Utils.getRandomString()),
            pinned: true,
            delegate: SliverAppBarDelegate(
              radius: 0,
              background: AppTheme.getBackground(context),
              tabBar: TabBar(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                controller: _tabController,
                tabs: _tabLabelList
                    .asMap()
                    .entries
                    .map(
                      (entry) => ItemBuilder.buildAnimatedTab(
                        context,
                        selected: entry.key == _currentTabIndex,
                        text: entry.value,
                        fontSizeDelta: -2,
                        normalUserBold: true,
                      ),
                    )
                    .toList(),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                enableFeedback: true,
                dividerHeight: 0,
                physics: const BouncingScrollPhysics(),
                labelStyle: Theme.of(context).textTheme.titleLarge,
                unselectedLabelStyle: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.apply(color: Colors.grey),
                indicator: const CustomTabIndicator(
                  borderColor: Colors.transparent,
                ),
                onTap: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
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
        loop: false,
        control: null,
        viewportFraction: 0.93,
        scrollDirection: Axis.horizontal,
        itemCount: _rankList.length,
        itemBuilder: (context, index) {
          return _buildRankListItem(index, _rankList[index]);
        },
        onIndexChanged: (index) {
          _tabController.animateTo(index);
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
            return ItemBuilder.buildClickItem(_buildRankItem(
                index, item.rankListType, item.hotLists[index]));
          },
        ),
      ),
    );
  }

  Widget _buildRankItem(int index, RankListType type, RankItem item) {
    bool showImage = ((type == RankListType.post && item.postType != 1) ||
            (type == RankListType.collection)) &&
        Utils.isNotEmpty(item.img);
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
            if (UriUtil.isPostUrl(item.url)) {
              Map<String, String> map = UriUtil.extractPostInfo(item.url);
              RouteUtil.pushCupertinoRoute(
                context,
                PostDetailScreen(
                  meta: map,
                  isArticle: showText,
                ),
              );
            } else if (UriUtil.isVideoUrl(item.url)) {
              Map<String, String> map = UriUtil.extractVideoInfo(item.url);
              RouteUtil.pushCupertinoRoute(
                context,
                VideoDetailScreen(
                  meta: map,
                ),
              );
            }
            break;
          case RankListType.collection:
            if (UriUtil.isCollectionUrl(item.url)) {
              int collectionId = UriUtil.extractCollectionId(item.url);
              if (collectionId != 0) {
                RouteUtil.pushCupertinoRoute(
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
                child: ItemBuilder.buildCachedImage(
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
                        color:
                            index > 2 ? Colors.grey : MyColors.likeButtonColor,
                      ),
                ),
              ),
            const SizedBox(width: 8),
            if (showImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ItemBuilder.buildCachedImage(
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
                  Utils.clearBlank(
                      Utils.extractTextFromHtml(item.postDigest ?? "")),
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
                    ? "${Utils.formatCount(item.pv)}人在搜"
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
              const Icon(
                Icons.arrow_upward_rounded,
                color: MyColors.likeButtonColor,
                size: 12,
              ),
            if (item.trend == 2)
              const Icon(
                Icons.arrow_downward_rounded,
                color: MyColors.likeButtonColor,
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
              child: ItemBuilder.buildCachedImage(
                imageUrl: Utils.isDark(context) ? images[0] : images[1],
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

  Widget _buildSearchBar() {
    return Hero(
      tag: "searchBar",
      child: Container(
        height: 35,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ItemBuilder.buildSearchBar(
                context: context,
                focusNode: _focusNode,
                hintText: "搜标签、合集、文章、讨论、粮单、用户",
                onSubmitted: (value) {
                  _performSearch(value);
                },
                controller: _searchController,
              ),
            ),
            if (!ResponsiveUtil.isLandscape()) const SizedBox(width: 16),
            if (!ResponsiveUtil.isLandscape())
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "取消",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
