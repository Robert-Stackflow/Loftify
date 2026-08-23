import 'dart:async';
import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/search_api.dart';
import 'package:loftify/Models/collection_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/search_response.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/grain_detail_screen.dart';
import 'package:loftify/Screens/Post/tag_detail_screen.dart';
import 'package:loftify/Widgets/PostItem/search_post_flow_item_builder.dart';

import '../../Utils/utils.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/paged_data_controller.dart';
import '../../Utils/tab_state_util.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';
import '../../l10n/l10n.dart';
import 'collection_detail_screen.dart';

class _AllSearchMetadata {
  const _AllSearchMetadata({required this.tags, this.tagRank});

  final List<TagInfo> tags;
  final TagInfo? tagRank;
}

class _AllSearchView {
  const _AllSearchView({
    required this.tags,
    required this.posts,
    this.tagRank,
  });

  final List<TagInfo> tags;
  final List<PostListItem> posts;
  final TagInfo? tagRank;
}

class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({super.key, required this.searchKey});

  static const String routeName = "/search/result";

  final String searchKey;

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends BaseDynamicState<SearchResultScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<SearchSuggestItem> _sugList = [];
  int _currentTabIndex = 0;
  late TabController _tabController;
  late final LazyTabLoadState _tabLoadState;
  TextEditingController? _searchController;
  int _searchIntent = 0;
  int _suggestIntent = 0;
  final EasyRefreshController _allResultRefreshController =
      EasyRefreshController();
  final EasyRefreshController _tagResultRefreshController =
      EasyRefreshController();
  final EasyRefreshController _collectionResultRefreshController =
      EasyRefreshController();
  final EasyRefreshController _postResultRefreshController =
      EasyRefreshController();
  final EasyRefreshController _grainResultRefreshController =
      EasyRefreshController();
  final EasyRefreshController _userResultRefreshController =
      EasyRefreshController();

  final List<String> _tabLabelList = [
    appLocalizations.comprehensive,
    appLocalizations.tag,
    appLocalizations.collection,
    appLocalizations.grain,
    appLocalizations.article,
    appLocalizations.user
  ];
  static const List<String> _tabIdList = [
    'all',
    'tag',
    'collection',
    'grain',
    'article',
    'user',
  ];
  late final PagedDataController<PostListItem, int, int, _AllSearchMetadata>
      _allPagingController;
  late final PagedDataController<TagInfo, String, int, TagInfo>
      _tagPagingController;
  late final PagedDataController<Collection, int, int, void>
      _collectionPagingController;
  late final PagedDataController<SearchPost, int, int, void>
      _postPagingController;
  late final PagedDataController<GrainInfo, int, int, void>
      _grainPagingController;
  late final PagedDataController<SearchBlogData, int, int, void>
      _userPagingController;

  List<PagedDataController<dynamic, dynamic, int, dynamic>>
      get _pagingControllers => [
            _allPagingController,
            _tagPagingController,
            _collectionPagingController,
            _postPagingController,
            _grainPagingController,
            _userPagingController,
          ];

  _AllSearchView? get _allResult {
    final metadata = _allPagingController.metadata;
    if (metadata == null) return null;
    return _AllSearchView(
      tags: metadata.tags,
      tagRank: metadata.tagRank,
      posts: _allPagingController.items,
    );
  }

  TagInfo? get _tagRank => _tagPagingController.metadata;
  List<TagInfo> get _tagList => _tagPagingController.items;
  List<Collection> get _collectionList => _collectionPagingController.items;
  List<SearchPost> get _postList => _postPagingController.items;
  List<GrainInfo> get _grainList => _grainPagingController.items;
  List<SearchBlogData> get _userList => _userPagingController.items;

  bool get _allResultNoMore => _allPagingController.noMore;
  bool get _tagResultNoMore => _tagPagingController.noMore;
  bool get _collectionResultNoMore => _collectionPagingController.noMore;
  bool get _postResultNoMore => _postPagingController.noMore;
  bool get _grainResultNoMore => _grainPagingController.noMore;
  bool get _userResultNoMore => _userPagingController.noMore;

  @override
  void initState() {
    super.initState();
    final restored = PersistentTabState.restore(
      idKey: HiveUtil.searchResultTabIdKey,
      legacyIndexKey: HiveUtil.searchResultTabIndexKey,
      itemIds: _tabIdList,
    );
    _tabLoadState = LazyTabLoadState(
      itemIds: _tabIdList,
      savedId: restored.id,
    );
    _currentTabIndex = _tabLoadState.currentIndex;
    _initPagingControllers();
    initTab();
    _performSearch(widget.searchKey, init: true);
  }

  @override
  void dispose() {
    _searchController
      ?..removeListener(_bindSuggest)
      ..dispose();
    _tabController.dispose();
    _allResultRefreshController.dispose();
    _tagResultRefreshController.dispose();
    _collectionResultRefreshController.dispose();
    _postResultRefreshController.dispose();
    _grainResultRefreshController.dispose();
    _userResultRefreshController.dispose();
    for (final controller in _pagingControllers) {
      controller
        ..removeListener(_handlePagingChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _initPagingControllers() {
    _allPagingController = PagedDataController(
      initialCursor: 0,
      keyOf: (item) => item.postData?.postView.id ?? item.itemId,
      loader: _loadAllResultPage,
      onError: _handlePagingError,
    );
    _tagPagingController = PagedDataController(
      initialCursor: 0,
      keyOf: (item) => item.tagName,
      loader: _loadTagResultPage,
      onError: _handlePagingError,
    );
    _collectionPagingController = PagedDataController(
      initialCursor: 0,
      keyOf: (item) => item.id,
      loader: _loadCollectionResultPage,
      onError: _handlePagingError,
    );
    _postPagingController = PagedDataController(
      initialCursor: 0,
      keyOf: (item) => item.id,
      loader: _loadPostResultPage,
      onError: _handlePagingError,
    );
    _grainPagingController = PagedDataController(
      initialCursor: 0,
      keyOf: (item) => item.id,
      loader: _loadGrainResultPage,
      onError: _handlePagingError,
    );
    _userPagingController = PagedDataController(
      initialCursor: 0,
      keyOf: (item) => item.blogInfo.blogId,
      loader: _loadUserResultPage,
      onError: _handlePagingError,
    );
    for (final controller in _pagingControllers) {
      controller.addListener(_handlePagingChanged);
    }
  }

  void _handlePagingChanged() {
    if (mounted) setState(() {});
  }

  void _handlePagingError(Object error, StackTrace stackTrace) {
    ILogger.error('Failed to load search result', error, stackTrace);
    if (!mounted) return;
    IToast.showTop(
      error is PagedDataException && StringUtil.isNotEmpty(error.message)
          ? error.message
          : appLocalizations.loadFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: ResponsiveAppBar(
        showBack: true,
        titleLeftMargin: 0,
        titleWidget: _buildSearchBar(),
        bottomHeight: 56,
        bottomWidget: TabBarWrapper(
          tabController: _tabController,
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
                ),
              )
              .toList(),
          showBorder: true,
          width: MediaQuery.sizeOf(context).width,
          isScrollable: false,
          onTap: (index) {
            _setCurrentTab(index);
          },
        ),
      ),
      body: Stack(
        children: [
          _buildTabView(),
          if (_sugList.isNotEmpty) _buildSuggestList(),
        ],
      ),
    );
  }

  void initTab() {
    _tabController = TabController(
      length: _tabLabelList.length,
      initialIndex: _currentTabIndex,
      vsync: this,
    );
    _tabController.addListener(() {
      final preloadIndex = _tabController.indexIsChanging
          ? _tabController.index
          : _tabController.offset > 0.001
              ? _tabController.index + 1
              : _tabController.offset < -0.001
                  ? _tabController.index - 1
                  : _tabController.index;
      if (preloadIndex >= 0 && preloadIndex < _tabLabelList.length) {
        unawaited(_ensureTabLoaded(preloadIndex));
      }
      final index =
          (_tabController.animation?.value ?? _tabController.index).round();
      if (index != _currentTabIndex) _setCurrentTab(index);
    });
  }

  void _setCurrentTab(int index, {bool persist = true}) {
    final safeIndex = TabStatePreference.restoreIndex(
      index,
      _tabLabelList.length,
    );
    if (safeIndex != _currentTabIndex) {
      setState(() => _currentTabIndex = safeIndex);
    }
    if (persist) {
      PersistentTabState.save(
        idKey: HiveUtil.searchResultTabIdKey,
        legacyIndexKey: HiveUtil.searchResultTabIndexKey,
        itemIds: _tabIdList,
        index: safeIndex,
      );
    }
    unawaited(_ensureTabLoaded(safeIndex));
  }

  Future<void> _ensureTabLoaded(int index) async {
    if (_searchController == null ||
        !_tabLoadState.selectAndShouldLoad(index)) {
      return;
    }
    final started = await _refreshTabWithAnimation(index);
    if (!started) {
      _tabLoadState.markLoadFailed(index);
    }
  }

  EasyRefreshController _refreshControllerFor(int index) => switch (index) {
        0 => _allResultRefreshController,
        1 => _tagResultRefreshController,
        2 => _collectionResultRefreshController,
        3 => _grainResultRefreshController,
        4 => _postResultRefreshController,
        _ => _userResultRefreshController,
      };

  Future<bool> _refreshTabWithAnimation(int index) async {
    final controller = _refreshControllerFor(index);
    for (var attempt = 0; attempt < 12; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return false;
      if (controller.headerState == null) continue;
      await controller.callRefresh(
        overOffset: 8,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
      return true;
    }
    return false;
  }

  _bindSuggest() {
    if (_searchController!.text.isEmpty) {
      _sugList.clear();
      if (mounted) setState(() {});
    } else {
      _performSuggest(_searchController!.text);
    }
  }

  Future<PagedDataPage<PostListItem, int, _AllSearchMetadata>>
      _loadAllResultPage(int cursor, bool refresh) async {
    final value = refresh
        ? await SearchApi.getAllSearchResult(key: _searchController!.text)
        : await SearchApi.getAllSearchPostResult(
            key: _searchController!.text,
            offset: cursor,
          );
    final data = _requireSearchData(value);
    final rawPosts = data['posts'];
    final posts = parsePagedDataItems<PostListItem>(
      rawPosts,
      PostListItem.fromJson,
      onMalformed: (error, stackTrace) =>
          _logMalformedSearchItem('comprehensive post', error, stackTrace),
    );
    final nextOffset = (data['offset'] as num?)?.toInt() ?? cursor;
    _AllSearchMetadata? metadata;
    if (refresh) {
      final tags = parsePagedDataItems<TagInfo>(
        data['tags'],
        TagInfo.fromJson,
        onMalformed: (error, stackTrace) =>
            _logMalformedSearchItem('related tag', error, stackTrace),
      );
      TagInfo? tagRank;
      if (data['tagRank'] is Map) {
        try {
          tagRank = TagInfo.fromJson(
            Map<String, dynamic>.from(data['tagRank'] as Map),
          );
        } catch (error, stackTrace) {
          _logMalformedSearchItem('rank tag', error, stackTrace);
        }
      }
      metadata = _AllSearchMetadata(tags: tags, tagRank: tagRank);
    }
    return PagedDataPage(
      items: posts,
      nextCursor: nextOffset,
      hasMore: rawPosts is List && rawPosts.isNotEmpty,
      metadata: metadata,
    );
  }

  Future<IndicatorResult> _fetchAllResult() => _allPagingController.refresh();

  Future<IndicatorResult> _fetchAllPostResult() => _allPagingController.load();

  Future<PagedDataPage<TagInfo, int, TagInfo>> _loadTagResultPage(
    int cursor,
    bool refresh,
  ) async {
    final value = await SearchApi.getTagSearchResult(
      key: _searchController!.text,
      offset: refresh ? 0 : cursor,
    );
    final data = _requireSearchData(value);
    final rawTags = data['tags'];
    final tags = parsePagedDataItems<TagInfo>(
      rawTags,
      TagInfo.fromJson,
      onMalformed: (error, stackTrace) =>
          _logMalformedSearchItem('tag', error, stackTrace),
    );
    TagInfo? tagRank;
    if (data['tagRank'] is Map) {
      try {
        tagRank = TagInfo.fromJson(
          Map<String, dynamic>.from(data['tagRank'] as Map),
        );
      } catch (error, stackTrace) {
        _logMalformedSearchItem('rank tag', error, stackTrace);
      }
    }
    return PagedDataPage(
      items: tags,
      nextCursor: (data['offset'] as num?)?.toInt() ?? cursor,
      hasMore: rawTags is List && rawTags.isNotEmpty,
      metadata: tagRank,
    );
  }

  Future<IndicatorResult> _fetchTagResult({bool refresh = false}) =>
      refresh ? _tagPagingController.refresh() : _tagPagingController.load();

  Future<PagedDataPage<Collection, int, void>> _loadCollectionResultPage(
    int cursor,
    bool refresh,
  ) async {
    final value = await SearchApi.getCollectionSearchResult(
      key: _searchController!.text,
      offset: refresh ? 0 : cursor,
    );
    final data = _requireSearchData(value);
    final rawItems = data['collections'];
    return PagedDataPage(
      items: parsePagedDataItems<Collection>(
        rawItems,
        Collection.fromJson,
        onMalformed: (error, stackTrace) =>
            _logMalformedSearchItem('collection', error, stackTrace),
      ),
      nextCursor: (data['offset'] as num?)?.toInt() ?? cursor,
      hasMore: rawItems is List && rawItems.isNotEmpty,
    );
  }

  Future<IndicatorResult> _fetchCollectionResult({bool refresh = false}) =>
      refresh
          ? _collectionPagingController.refresh()
          : _collectionPagingController.load();

  Future<PagedDataPage<SearchPost, int, void>> _loadPostResultPage(
    int cursor,
    bool refresh,
  ) async {
    final value = await SearchApi.getPostSearchResult(
      key: _searchController!.text,
      offset: refresh ? 0 : cursor,
    );
    final data = _requireSearchData(value);
    final rawItems = data['posts'];
    return PagedDataPage(
      items: parsePagedDataItems<SearchPost>(
        rawItems,
        SearchPost.fromJson,
        onMalformed: (error, stackTrace) =>
            _logMalformedSearchItem('post', error, stackTrace),
      ),
      nextCursor: (data['offset'] as num?)?.toInt() ?? cursor,
      hasMore: rawItems is List && rawItems.isNotEmpty,
    );
  }

  Future<IndicatorResult> _fetchPostResult({bool refresh = false}) =>
      refresh ? _postPagingController.refresh() : _postPagingController.load();

  Future<PagedDataPage<GrainInfo, int, void>> _loadGrainResultPage(
    int cursor,
    bool refresh,
  ) async {
    final value = await SearchApi.getGrainSearchResult(
      key: _searchController!.text,
      offset: refresh ? 0 : cursor,
    );
    final data = _requireSearchData(value);
    final rawItems = data['grainList'];
    return PagedDataPage(
      items: parsePagedDataItems<GrainInfo>(
        rawItems,
        GrainInfo.fromJson,
        onMalformed: (error, stackTrace) =>
            _logMalformedSearchItem('grain', error, stackTrace),
      ),
      nextCursor: (data['offset'] as num?)?.toInt() ?? cursor,
      hasMore: rawItems is List && rawItems.isNotEmpty,
    );
  }

  Future<IndicatorResult> _fetchGrainResult({bool refresh = false}) => refresh
      ? _grainPagingController.refresh()
      : _grainPagingController.load();

  Future<PagedDataPage<SearchBlogData, int, void>> _loadUserResultPage(
    int cursor,
    bool refresh,
  ) async {
    final value = await SearchApi.getUserSearchResult(
      key: _searchController!.text,
      offset: refresh ? 0 : cursor,
    );
    final data = _requireSearchData(value);
    final rawItems = data['blogs'];
    return PagedDataPage(
      items: parsePagedDataItems<SearchBlogData>(
        rawItems,
        SearchBlogData.fromJson,
        onMalformed: (error, stackTrace) =>
            _logMalformedSearchItem('user', error, stackTrace),
      ),
      nextCursor: (data['offset'] as num?)?.toInt() ?? cursor,
      hasMore: rawItems is List && rawItems.isNotEmpty,
    );
  }

  Future<IndicatorResult> _fetchUserResult({bool refresh = false}) =>
      refresh ? _userPagingController.refresh() : _userPagingController.load();

  Map<String, dynamic> _requireSearchData(dynamic value) {
    final code = value is Map ? (value['code'] as num?)?.toInt() : null;
    if (code != 0) {
      throw PagedDataException(
        value is Map ? value['msg']?.toString() ?? '' : '',
      );
    }
    final data = value['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  void _logMalformedSearchItem(
    String kind,
    Object error,
    StackTrace stackTrace,
  ) {
    ILogger.error('Skipped malformed search $kind', error, stackTrace);
  }

  _performSearch(String str, {bool init = false}) async {
    final searchIntent = ++_searchIntent;
    bool processed = await UriUtil.processUrl(context, str, quiet: true);
    if (!mounted || searchIntent != _searchIntent) return;
    if (!processed) {
      _searchController?.removeListener(_bindSuggest);
      _searchController ??= TextEditingController();
      _searchController!.text = str;
      _sugList.clear();
      final targetTab = init ? _currentTabIndex : 0;
      _tabLoadState.reset(index: targetTab);
      if (!init) {
        _currentTabIndex = 0;
        PersistentTabState.save(
          idKey: HiveUtil.searchResultTabIdKey,
          legacyIndexKey: HiveUtil.searchResultTabIndexKey,
          itemIds: _tabIdList,
          index: 0,
        );
      }
      for (final controller in _pagingControllers) {
        controller.reset(notify: false);
      }
      setState(() {});
      Utils.addSearchHistory(str);
      if (!init) {
        FocusScope.of(context).unfocus();
        _tabController.animateTo(0);
      }
      _searchController!.addListener(_bindSuggest);
      unawaited(_ensureTabLoaded(targetTab));
    }
  }

  _jumpToTag(String tag) {
    RouteUtil.pushPanelCupertinoRoute(context, TagDetailScreen(tag: tag));
  }

  _performSuggest(String str) {
    final suggestIntent = ++_suggestIntent;
    SearchApi.getSuggestList(key: str).then((value) {
      if (!mounted ||
          suggestIntent != _suggestIntent ||
          _searchController?.text != str) {
        return;
      }
      if (value['code'] != 0) {
        IToast.showTop(value['msg']);
      } else {
        if (value['data']['items'] != null &&
            _searchController!.text.isNotEmpty) {
          _sugList = (value['data']['items'] as List)
              .map((e) => SearchSuggestItem.fromJson(e))
              .toList();
        }
        setState(() {});
      }
    });
  }

  _buildSuggestList() {
    return Container(
      color: ChewieTheme.getBackground(context),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        itemCount: _sugList.length,
        itemBuilder: (context, index) {
          return _buildSuggestItem(index, _sugList[index]);
        },
      ),
    );
  }

  _buildSuggestItem(int index, SearchSuggestItem item) {
    switch (item.type) {
      case 0:
        if (index == 0) {
          return LoftifyItemBuilder.buildRankTagRow(context, item.tagInfo!,
              onTap: () {
            Utils.addSearchHistory(_searchController!.text);
            _jumpToTag(item.tagInfo!.tagName);
          });
        } else {
          return LoftifyItemBuilder.buildTagRow(context, item.tagInfo!,
              onTap: () {
            Utils.addSearchHistory(_searchController!.text);
            _jumpToTag(item.tagInfo!.tagName);
          });
        }
      case 1:
        return LoftifyItemBuilder.buildTagRow(context, item.tagInfo!,
            onTap: () {
          Utils.addSearchHistory(_searchController!.text);
          _performSearch(item.tagInfo!.tagName);
        });
      case 2:
        return LoftifyItemBuilder.buildUserRow(context, item.blogData!,
            onTap: () {
          Utils.addSearchHistory(_searchController!.text);
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

  Widget _buildTabView() {
    List<Widget> children = [];
    children.add(_buildAllResultTab());
    children.add(_buildTagResultTab());
    children.add(_buildCollectionResultTab());
    children.add(_buildGrainResultTab());
    children.add(_buildPostResultTab());
    children.add(_buildUserResultTab());
    return TabBarView(
      controller: _tabController,
      children: children,
    );
  }

  _buildDivider() {
    return Container(height: 3, color: Theme.of(context).dividerColor);
  }

  Widget _buildAllResultTab() {
    return EasyRefresh.builder(
      controller: _allResultRefreshController,
      onRefresh: () async {
        return await _fetchAllResult();
      },
      onLoad: _allResultNoMore
          ? null
          : () async {
              return await _fetchAllPostResult();
            },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => _allResult != null
          ? CustomScrollView(
              key: const PageStorageKey('search-all-results'),
              physics: physics,
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      const SizedBox(height: 10),
                      if (_allResult!.tags.isEmpty &&
                          _allResult!.tagRank == null &&
                          _allResult!.posts.isEmpty)
                        Container(
                          height: 160,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: EmptyPlaceholder(
                            text: appLocalizations.noSearchResult,
                          ),
                        ),
                      if (_allResult!.tagRank != null)
                        LoftifyItemBuilder.buildRankTagRow(
                          context,
                          _allResult!.tagRank!,
                          useBackground: false,
                          onTap: () {
                            _jumpToTag(_allResult!.tagRank!.tagName);
                          },
                        ),
                      if (_allResult!.tagRank != null) _buildDivider(),
                      if (_allResult!.tags.isNotEmpty)
                        ItemBuilder.buildTitle(
                          context,
                          title: appLocalizations.relatedTag,
                          suffixText: appLocalizations.viewAll,
                          topMargin: 16,
                          bottomMargin: 8,
                          onTap: () {
                            _tabController.animateTo(1);
                          },
                        ),
                      if (_allResult!.tags.isNotEmpty)
                        ...List<Widget>.generate(
                            min(_allResult!.tags.length, 2), (index) {
                          return LoftifyItemBuilder.buildTagRow(
                            context,
                            _allResult!.tags[index],
                            verticalPadding: 8,
                            onTap: () {
                              if (_allResult!.tags[index].joinCount != -1) {
                                _jumpToTag(_allResult!.tags[index].tagName);
                              } else {
                                _performSearch(_allResult!.tags[index].tagName);
                              }
                            },
                          );
                        }),
                      if (_allResult!.tags.isNotEmpty)
                        const SizedBox(height: 8),
                      if (_allResult!.tags.isNotEmpty) _buildDivider(),
                      if (_allResult!.posts.isNotEmpty)
                        ItemBuilder.buildTitle(
                          context,
                          title: appLocalizations.relatedPost,
                          suffixText: appLocalizations.viewAll,
                          topMargin: 16,
                          bottomMargin: 8,
                          onTap: () {
                            _tabController.animateTo(4);
                          },
                        ),
                    ],
                  ),
                ),
                if (_allResult!.posts.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
                    sliver: SliverWaterfallFlow(
                      gridDelegate:
                          const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        maxCrossAxisExtent: 300,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return GestureDetector(
                            child: RecommendFlowItemBuilder
                                .buildWaterfallFlowPostItem(
                              context,
                              _allResult!.posts[index],
                            ),
                          );
                        },
                        childCount: _allResult!.posts.length,
                      ),
                    ),
                  ),
              ],
            )
          : LoadingWidget(
              background: ChewieTheme.getBackground(context),
            ),
    );
  }

  Widget _buildTagResultTab() {
    return EasyRefresh.builder(
      controller: _tagResultRefreshController,
      onRefresh: () async {
        return await _fetchTagResult(refresh: true);
      },
      onLoad: _tagResultNoMore
          ? null
          : () async {
              return await _fetchTagResult();
            },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        key: const PageStorageKey('search-tag-results'),
        physics: physics,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                if (_tagList.isEmpty && _tagRank == null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: EmptyPlaceholder(
                      text: appLocalizations.noTag,
                    ),
                  ),
                if (_tagRank != null)
                  LoftifyItemBuilder.buildRankTagRow(
                    context,
                    _tagRank!,
                    useBackground: false,
                    onTap: () {
                      _jumpToTag(_tagRank!.tagName);
                    },
                  ),
                if (_tagRank != null && _tagList.isNotEmpty) _buildDivider(),
                if (_tagList.isNotEmpty)
                  ...List<Widget>.generate(_tagList.length, (index) {
                    return LoftifyItemBuilder.buildTagRow(
                      context,
                      _tagList[index],
                      verticalPadding: 8,
                      onTap: () {
                        if (_tagList[index].joinCount != -1) {
                          _jumpToTag(_tagList[index].tagName);
                        } else {
                          _performSearch(_tagList[index].tagName);
                        }
                      },
                    );
                  }),
                if (_tagList.isNotEmpty) const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionResultTab() {
    return EasyRefresh.builder(
      controller: _collectionResultRefreshController,
      onRefresh: () async {
        return await _fetchCollectionResult(refresh: true);
      },
      onLoad: _collectionResultNoMore
          ? null
          : () async {
              return await _fetchCollectionResult();
            },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        key: const PageStorageKey('search-collection-results'),
        physics: physics,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                if (_collectionList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: EmptyPlaceholder(
                      text: appLocalizations.noCollection,
                    ),
                  ),
              ],
            ),
          ),
          SliverWaterfallFlow(
            gridDelegate:
                const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
              mainAxisSpacing: 0,
              crossAxisSpacing: 6,
              maxCrossAxisExtent: 600,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return LoftifyItemBuilder.buildCollectionRow(
                    context, _collectionList[index], verticalPadding: 8,
                    onTap: () {
                  RouteUtil.pushPanelCupertinoRoute(
                    context,
                    CollectionDetailScreen(
                      collectionId: _collectionList[index].id,
                      blogId: _collectionList[index].blogId,
                      blogName: _collectionList[index].blogName,
                      postId: 0,
                    ),
                  );
                });
              },
              childCount: _collectionList.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostResultTab() {
    return EasyRefresh.builder(
      controller: _postResultRefreshController,
      onRefresh: () async {
        return await _fetchPostResult(refresh: true);
      },
      onLoad: _postResultNoMore
          ? null
          : () async {
              return await _fetchPostResult();
            },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        key: const PageStorageKey('search-post-results'),
        physics: physics,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                if (_postList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: EmptyPlaceholder(
                      text: appLocalizations.noArticle,
                    ),
                  ),
              ],
            ),
          ),
          if (_postList.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
              sliver: SliverWaterfallFlow(
                gridDelegate:
                    const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  maxCrossAxisExtent: 300,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return GestureDetector(
                      child:
                          SearchPostFlowItemBuilder.buildWaterfallFlowPostItem(
                        context,
                        _postList[index],
                      ),
                    );
                  },
                  childCount: _postList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrainResultTab() {
    return EasyRefresh.builder(
      controller: _grainResultRefreshController,
      onRefresh: () async {
        return await _fetchGrainResult(refresh: true);
      },
      onLoad: _grainResultNoMore
          ? null
          : () async {
              return await _fetchGrainResult();
            },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        key: const PageStorageKey('search-grain-results'),
        physics: physics,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                if (_grainList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: EmptyPlaceholder(
                      text: appLocalizations.noGrain,
                    ),
                  ),
              ],
            ),
          ),
          SliverWaterfallFlow(
            gridDelegate:
                const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
              mainAxisSpacing: 0,
              crossAxisSpacing: 6,
              maxCrossAxisExtent: 600,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return LoftifyItemBuilder.buildGrainRow(
                  context,
                  _grainList[index],
                  verticalPadding: 8,
                  onTap: () {
                    RouteUtil.pushPanelCupertinoRoute(
                      context,
                      GrainDetailScreen(
                          grainId: _grainList[index].id,
                          blogId: _grainList[index].userId),
                    );
                  },
                );
              },
              childCount: _grainList.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserResultTab() {
    return EasyRefresh.builder(
      controller: _userResultRefreshController,
      onRefresh: () async {
        return await _fetchUserResult(refresh: true);
      },
      onLoad: _userResultNoMore
          ? null
          : () async {
              return await _fetchUserResult();
            },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        key: const PageStorageKey('search-user-results'),
        physics: physics,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                if (_userList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: EmptyPlaceholder(
                      text: appLocalizations.noUser,
                    ),
                  ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
            sliver: SliverWaterfallFlow(
              gridDelegate:
                  const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                maxCrossAxisExtent: 440,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return LoftifyItemBuilder.buildUserRow(
                    context,
                    _userList[index],
                    onTap: () {
                      RouteUtil.pushPanelCupertinoRoute(
                        context,
                        UserDetailScreen(
                          blogId: _userList[index].blogInfo.blogId,
                          blogName: _userList[index].blogInfo.blogName,
                        ),
                      );
                    },
                  );
                },
                childCount: _userList.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    double width = ResponsiveUtil.isLandscapeLayout()
        ? searchBarWidth - 100
        : min(MediaQuery.of(context).size.width, searchBarWidth);
    return Container(
      margin: const EdgeInsets.all(10),
      constraints:
          BoxConstraints(maxWidth: width, minWidth: width, maxHeight: 56),
      child: ItemBuilder.buildSearchBar(
        context: context,
        borderRadius: 8,
        bottomMargin: 18,
        hintFontSizeDelta: 1,
        // focusNode: _focusNode,
        controller: _searchController,
        hintText: appLocalizations.searchHint,
        onSubmitted: (text) async {
          _performSearch(text);
        },
      ),
    );
  }
}
