import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/collection_api.dart';
import 'package:loftify/Api/grain_api.dart';
import 'package:loftify/Api/recommend_api.dart';
import 'package:loftify/Models/dynamic_response.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/collection_detail_screen.dart';
import 'package:loftify/Screens/Post/grain_detail_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Screens/Post/tag_detail_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/enums.dart';

import '../../Api/tag_api.dart';
import '../../Models/grain_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/paged_data_controller.dart';
import '../../Utils/tab_state_util.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../Widgets/PostItem/grain_post_item_builder.dart';
import '../../l10n/l10n.dart';
import 'home_screen.dart';

typedef _TimelineCursor = ({int show, int publish, int share});

Map<String, dynamic> _requireDynamicData(dynamic value) {
  final code = value is Map ? (value['code'] as num?)?.toInt() : null;
  if (code != 0) {
    throw PagedDataException(
      value is Map ? value['msg']?.toString() ?? '' : '',
    );
  }
  final data = value['data'];
  return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
}

class DynamicScreen extends StatefulWidget {
  const DynamicScreen({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  static const String routeName = "/nav/dynamic";

  @override
  State<DynamicScreen> createState() => DynamicScreenState();
}

class DynamicScreenState extends BaseDynamicState<DynamicScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScrollToHideMixin,
        BottomNavgationMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;
  late final LazyTabLoadState _tabLoadState;
  int _currentTabIndex = 0;
  final List<String> _tabLabelList = [
    appLocalizations.follow,
    appLocalizations.tag,
    appLocalizations.collection,
    appLocalizations.grain
  ];
  static const List<String> _tabIdList = [
    'follow',
    'tag',
    'collection',
    'grain',
  ];
  int lastRefreshTime = 0;
  final GlobalKey _tagTabKey = GlobalKey();
  final GlobalKey _collectionTabKey = GlobalKey();
  final GlobalKey _grainTabKey = GlobalKey();
  final GlobalKey _followTabKey = GlobalKey();
  final ScrollController _tagScrollController = ScrollController();
  final ScrollController _collectionScrollController = ScrollController();
  final ScrollController _grainScrollController = ScrollController();
  final ScrollController _followScrollController = ScrollController();

  late AnimationController _refreshRotationController;
  final ScrollToHideController _scrollToHideController =
      ScrollToHideController();

  @override
  List<ScrollController> getScrollControllers() {
    return [
      _tagScrollController,
      _collectionScrollController,
      _grainScrollController,
      _followScrollController,
    ];
  }

  @override
  FutureOr onTapBottomNavigation() {
    scrollToTopOrRefresh();
  }

  void scrollToTopAndRefresh() {
    if (appProvider.token.isEmpty) return;
    int nowTime = DateTime.now().millisecondsSinceEpoch;
    if (lastRefreshTime == 0 || (nowTime - lastRefreshTime) > krefreshTimeout) {
      lastRefreshTime = nowTime;
      refresh();
    }
  }

  void scrollToTopOrRefresh() {
    ScrollController controller = getCurrentController();
    if (controller.hasClients && controller.offset > 30) {
      controller.animateTo(0,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      refresh();
    }
  }

  ScrollController getCurrentController() {
    late ScrollController controller;
    switch (_currentTabIndex) {
      case 1:
        controller = _tagScrollController;
        break;
      case 2:
        controller = _collectionScrollController;
        break;
      case 3:
        controller = _grainScrollController;
        break;
      case 0:
        controller = _followScrollController;
        break;
    }
    return controller;
  }

  Function getCurrentCallRefresh() {
    late Function callRefresh;
    switch (_currentTabIndex) {
      case 1:
        callRefresh =
            (_tagTabKey.currentState as SubscribeTagTabState).callRefresh;
        break;
      case 2:
        callRefresh =
            (_collectionTabKey.currentState as SubscribeCollectionTabState)
                .callRefresh;
        break;
      case 3:
        callRefresh =
            (_grainTabKey.currentState as SubscribeGrainTabState).callRefresh;
        break;
      case 0:
        callRefresh =
            (_followTabKey.currentState as FollowTabState).callRefresh;
        break;
    }
    return callRefresh;
  }

  void refresh() {
    getCurrentCallRefresh()();
  }

  void scrollToTop() {
    getCurrentController().animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  void initState() {
    _refreshRotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    super.initState();
    initTab();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      panelScreenState?.refreshScrollControllers();
      _ensureTabLoaded(_currentTabIndex);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshRotationController.dispose();
    _tagScrollController.dispose();
    _collectionScrollController.dispose();
    _grainScrollController.dispose();
    _followScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: appProvider.token.isNotEmpty ? _buildAppBar() : null,
      body: appProvider.token.isNotEmpty
          ? Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [
                    FollowTab(
                      key: _followTabKey,
                      scrollController: _followScrollController,
                    ),
                    SubscribeTagTab(
                      key: _tagTabKey,
                      scrollController: _tagScrollController,
                    ),
                    SubscribeCollectionTab(
                      key: _collectionTabKey,
                      scrollController: _collectionScrollController,
                    ),
                    SubscribeGrainTab(
                      key: _grainTabKey,
                      scrollController: _grainScrollController,
                    ),
                  ],
                ),
                Positioned(
                  right: ResponsiveUtil.isLandscapeLayout() ? 16 : 12,
                  bottom: ResponsiveUtil.isLandscapeLayout() ? 16 : 76,
                  child: ScrollToHide.multi(
                    controller: _scrollToHideController,
                    scrollControllers: getScrollControllers(),
                    hideDirection: Axis.vertical,
                    child: _buildFloatingButtons(),
                  ),
                ),
              ],
            )
          : LoftifyItemBuilder.buildUnLoginMainBody(context),
    );
  }

  _buildFloatingButtons() {
    return ResponsiveUtil.isLandscapeLayout()
        ? Column(
            children: [
              ShadowIconButton(
                icon: RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0)
                      .animate(_refreshRotationController),
                  child: const Icon(Icons.refresh_rounded),
                ),
                onTap: () async {
                  refresh();
                },
              ),
              const SizedBox(height: 10),
              ShadowIconButton(
                icon: const Icon(Icons.arrow_upward_rounded),
                onTap: () {
                  scrollToTop();
                },
              ),
            ],
          )
        : emptyWidget;
  }

  void initTab() {
    final restored = PersistentTabState.restore(
      idKey: HiveUtil.dynamicTabIdKey,
      legacyIndexKey: HiveUtil.dynamicTabIndexKey,
      itemIds: _tabIdList,
    );
    _tabLoadState = LazyTabLoadState(
      itemIds: _tabIdList,
      savedId: restored.id,
    );
    _currentTabIndex = _tabLoadState.currentIndex;
    _tabController = TabController(
      length: _tabLabelList.length,
      initialIndex: _currentTabIndex,
      vsync: this,
    );
    _tabController.addListener(() {
      final offset = _tabController.offset;
      final preloadIndex = _tabController.indexIsChanging
          ? _tabController.index
          : offset > 0.001
              ? _tabController.index + 1
              : offset < -0.001
                  ? _tabController.index - 1
                  : _tabController.index;
      if (preloadIndex >= 0 && preloadIndex < _tabLabelList.length) {
        _ensureTabLoaded(preloadIndex);
      }
      final index =
          (_tabController.animation?.value ?? _tabController.index).round();
      if (index != _currentTabIndex) _setCurrentTab(index);
    });
  }

  void _setCurrentTab(int index) {
    final safeIndex = TabStatePreference.restoreIndex(
      index,
      _tabLabelList.length,
    );
    if (safeIndex != _currentTabIndex) {
      setState(() => _currentTabIndex = safeIndex);
    }
    PersistentTabState.save(
      idKey: HiveUtil.dynamicTabIdKey,
      legacyIndexKey: HiveUtil.dynamicTabIndexKey,
      itemIds: _tabIdList,
      index: safeIndex,
    );
    _ensureTabLoaded(safeIndex);
  }

  void _ensureTabLoaded(int index) {
    if (!_tabLoadState.selectAndShouldLoad(index)) return;
    unawaited(_startTabRefreshWhenMounted(index));
  }

  Future<void> _startTabRefreshWhenMounted(int index) async {
    for (var attempt = 0; attempt < 60; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final state = switch (index) {
        0 => _followTabKey.currentState,
        1 => _tagTabKey.currentState,
        2 => _collectionTabKey.currentState,
        3 => _grainTabKey.currentState,
        _ => null,
      };
      final refreshReady = switch (state) {
        FollowTabState state => state.refreshReady,
        SubscribeTagTabState state => state.refreshReady,
        SubscribeCollectionTabState state => state.refreshReady,
        SubscribeGrainTabState state => state.refreshReady,
        _ => false,
      };
      if (state != null && refreshReady) {
        switch (index) {
          case 0:
            (state as FollowTabState).callRefresh();
            break;
          case 1:
            (state as SubscribeTagTabState).callRefresh();
            break;
          case 2:
            (state as SubscribeCollectionTabState).callRefresh();
            break;
          case 3:
            (state as SubscribeGrainTabState).callRefresh();
            break;
        }
        return;
      }
    }
    _tabLoadState.markLoadFailed(index);
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      titleLeftMargin: 15,
      titleWidget: TabBar(
        controller: _tabController,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        labelPadding: const EdgeInsets.only(right: 32),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerHeight: 0,
        physics: const BouncingScrollPhysics(),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: UnderlinedTabIndicator(
          borderColor: Theme.of(context).primaryColor,
        ),
        tabs: _tabLabelList
            .asMap()
            .entries
            .map((entry) => ItemBuilder.buildAnimatedTab(context,
                selected: entry.key == _currentTabIndex,
                text: entry.value,
                controller: _tabController,
                tabIndex: entry.key))
            .toList(),
        onTap: (index) {
          _setCurrentTab(index);
        },
      ),
    );
  }
}

class FollowTab extends StatefulWidget {
  const FollowTab({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  State<StatefulWidget> createState() => FollowTabState();
}

class FollowTabState extends BaseDynamicState<FollowTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final EasyRefreshController _refreshController = EasyRefreshController();
  late final PagedDataController<GrainPostItem, int, _TimelineCursor,
      List<TimelineBlog>> _pagingController;
  late final ScrollController _scrollController =
      widget.scrollController ?? ScrollController();

  List<GrainPostItem> get _postList => _pagingController.items;
  List<TimelineBlog> get _timelineBlogList =>
      _pagingController.metadata ?? const <TimelineBlog>[];
  bool get refreshReady => _refreshController.headerState != null;

  callRefresh() {
    if (_scrollController.hasClients &&
        _scrollController.offset > MediaQuery.sizeOf(context).height) {
      _scrollController
          .animateTo(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut)
          .then((_) {
        _refreshController.callRefresh();
      });
    } else {
      _refreshController.callRefresh();
    }
  }

  Future<PagedDataPage<GrainPostItem, _TimelineCursor, List<TimelineBlog>>>
      _loadPage(_TimelineCursor cursor, bool refresh) async {
    final value = await RecommendApi.getTimeline(
      showOffset: refresh ? 0 : cursor.show,
      publishOffset: refresh ? 0 : cursor.publish,
      shareOffset: refresh ? 0 : cursor.share,
    );
    final data = _requireDynamicData(value);
    final rawItems = data['items'];
    final posts = parsePagedDataItems<GrainPostItem>(
      rawItems,
      GrainPostItem.fromJson,
      onMalformed: (error, stackTrace) =>
          ILogger.error('Skipped malformed timeline post', error, stackTrace),
    );
    final timelineBlogs = parsePagedDataItems<TimelineBlog>(
      data['timelineBlogList'],
      TimelineBlog.fromJson,
      onMalformed: (error, stackTrace) =>
          ILogger.error('Skipped malformed timeline blog', error, stackTrace),
    );
    return PagedDataPage(
      items: posts,
      nextCursor: (
        show: (data['showOffset'] as num?)?.toInt() ?? cursor.show,
        publish: (data['publishOffset'] as num?)?.toInt() ?? cursor.publish,
        share: (data['shareOffset'] as num?)?.toInt() ?? cursor.share,
      ),
      hasMore: rawItems is List && rawItems.isNotEmpty,
      metadata: refresh ? timelineBlogs : null,
    );
  }

  Future<IndicatorResult> _fetchResult({bool refresh = false}) =>
      refresh ? _pagingController.refresh() : _pagingController.load();

  @override
  void initState() {
    super.initState();
    _pagingController = PagedDataController(
      initialCursor: (show: 0, publish: 0, share: 0),
      keyOf: (item) => item.postData.postView.id,
      loader: _loadPage,
      onError: (error, stackTrace) {
        ILogger.error('Failed to load follow dynamics', error, stackTrace);
        if (mounted) {
          IToast.showTop(
            error is PagedDataException && StringUtil.isNotEmpty(error.message)
                ? error.message
                : appLocalizations.loadFailed,
          );
        }
      },
    )..addListener(_handlePagingChanged);
  }

  void _handlePagingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pagingController
      ..removeListener(_handlePagingChanged)
      ..dispose();
    _refreshController.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildEasyRefresh(
      (context, physics) => CustomScrollView(
        controller: _scrollController,
        physics: physics,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (_timelineBlogList.isNotEmpty) ...[
                  ItemBuilder.buildTitle(
                    context,
                    title: appLocalizations.updateRecently,
                    topMargin: 10,
                    bottomMargin: 10,
                  ),
                  _buildTimelineBlog(),
                  const MyDivider(
                    margin: EdgeInsets.only(top: 16),
                  ),
                ],
                if (_postList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: EmptyPlaceholder(
                      text: appLocalizations.noDynamic,
                    ),
                  ),
              ],
            ),
          ),
          _buildPostList(),
        ],
      ),
    );
  }

  _buildTimelineBlog() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _timelineBlogList.length,
        itemBuilder: (context, index) {
          return ClickableWrapper(
              child: _buildTimelineBlogItem(_timelineBlogList[index]));
        },
      ),
    );
  }

  _buildTimelineBlogItem(TimelineBlog item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
            context,
            UserDetailScreen(
                blogId: item.blogInfo.blogId,
                blogName: item.blogInfo.blogName));
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 8),
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              child: ChewieItemBuilder.buildCachedImage(
                imageUrl: item.blogInfo.bigAvaImg,
                context: context,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                showLoading: false,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.blogInfo.blogNickName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  _buildEasyRefresh(ERChildBuilder builder) {
    return EasyRefresh.builder(
      refreshOnStart: false,
      controller: _refreshController,
      scrollController: _scrollController,
      onRefresh: () async {
        return await _fetchResult(refresh: true);
      },
      onLoad: _pagingController.noMore
          ? null
          : () async {
              return await _fetchResult();
            },
      triggerAxis: Axis.vertical,
      childBuilder: builder,
    );
  }

  _buildPostList() {
    return SliverWaterfallFlow(
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 600,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _postList[index];
          return KeyedSubtree(
            key: ValueKey('dynamic-follow-${item.postData.postView.id}'),
            child: ClickableWrapper(
              child: GrainPostItemBuilder.buildTilePostItem(
                context,
                item,
                isFirst: ResponsiveUtil.isLandscapeLayout() && index == 0,
              ),
            ),
          );
        },
        childCount: _postList.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }
}

class SubscribeTagTab extends StatefulWidget {
  const SubscribeTagTab({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  State<StatefulWidget> createState() => SubscribeTagTabState();
}

class SubscribeTagTabState extends BaseDynamicState<SubscribeTagTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final EasyRefreshController _refreshController = EasyRefreshController();
  late final PagedDataController<FullSubscribeTagItem, String, int,
      List<FullSubscribeTagItem>> _pagingController;
  late final ScrollController _scrollController =
      widget.scrollController ?? ScrollController();

  List<FullSubscribeTagItem> get _subscribeList => _pagingController.items;
  List<FullSubscribeTagItem> get _recentVisitList =>
      _pagingController.metadata ?? const <FullSubscribeTagItem>[];
  bool get refreshReady => _refreshController.headerState != null;

  callRefresh() {
    if (_scrollController.hasClients &&
        _scrollController.offset > MediaQuery.sizeOf(context).height) {
      _scrollController
          .animateTo(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut)
          .then((_) {
        _refreshController.callRefresh();
      });
    } else {
      _refreshController.callRefresh();
    }
  }

  Future<PagedDataPage<FullSubscribeTagItem, int, List<FullSubscribeTagItem>>>
      _loadPage(int cursor, bool refresh) async {
    final value = await TagApi.getFullSubscribdTagList(
      offset: refresh ? 0 : cursor,
    );
    final data = _requireDynamicData(value);
    final rawItems = data['favoriteTags'];
    final subscribed = parsePagedDataItems<FullSubscribeTagItem>(
      rawItems,
      FullSubscribeTagItem.fromJson,
      onMalformed: (error, stackTrace) => ILogger.error(
        'Skipped malformed subscribed tag',
        error,
        stackTrace,
      ),
    );
    final recent = parsePagedDataItems<FullSubscribeTagItem>(
      data['recentVisitTags'],
      FullSubscribeTagItem.fromJson,
      onMalformed: (error, stackTrace) => ILogger.error(
        'Skipped malformed recent tag',
        error,
        stackTrace,
      ),
    );
    return PagedDataPage(
      items: subscribed,
      nextCursor: (data['offset'] as num?)?.toInt() ?? cursor,
      hasMore: rawItems is List && rawItems.isNotEmpty,
      metadata: refresh ? recent : null,
    );
  }

  Future<IndicatorResult> _fetchResult({bool refresh = false}) =>
      refresh ? _pagingController.refresh() : _pagingController.load();

  @override
  void initState() {
    super.initState();
    _pagingController = PagedDataController(
      initialCursor: 0,
      keyOf: (item) => item.name,
      loader: _loadPage,
      onError: (error, stackTrace) {
        ILogger.error('Failed to load subscribed tags', error, stackTrace);
        if (mounted) {
          IToast.showTop(
            error is PagedDataException && StringUtil.isNotEmpty(error.message)
                ? error.message
                : appLocalizations.loadFailed,
          );
        }
      },
    )..addListener(_handlePagingChanged);
  }

  void _handlePagingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pagingController
      ..removeListener(_handlePagingChanged)
      ..dispose();
    _refreshController.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh.builder(
      refreshOnStart: false,
      controller: _refreshController,
      onRefresh: () async {
        return await _fetchResult(refresh: true);
      },
      onLoad: _pagingController.noMore
          ? null
          : () async {
              return await _fetchResult();
            },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        controller: _scrollController,
        physics: physics,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                if (_recentVisitList.isNotEmpty)
                  ItemBuilder.buildTitle(
                    context,
                    title: appLocalizations.visitFrequently,
                    topMargin: 10,
                    bottomMargin: 10,
                  ),
                if (_recentVisitList.isNotEmpty) _buildRecentVisitTagList(),
                if (_recentVisitList.isNotEmpty)
                  const MyDivider(horizontal: 0, vertical: 16),
                if (_recentVisitList.isEmpty) const SizedBox(height: 10),
                if (_subscribeList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: EmptyPlaceholder(
                      text: appLocalizations.noSubscribedTag,
                    ),
                  ),
              ],
            ),
          ),
          if (_subscribeList.isNotEmpty) _buildSubscribeTagList(physics),
        ],
      ),
    );
  }

  _buildRecentVisitTagList() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _recentVisitList.length,
        itemBuilder: (context, index) {
          return ClickableWrapper(
              child: _buildRecentVisitTagItem(_recentVisitList[index]));
        },
      ),
    );
  }

  _buildRecentVisitTagItem(FullSubscribeTagItem item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
            context, TagDetailScreen(tag: item.name));
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 8),
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipOval(
                  child: ChewieItemBuilder.buildCachedImage(
                    imageUrl: item.image ?? "",
                    context: context,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    showLoading: false,
                  ),
                ),
                if (item.unreadCount > 0)
                  Positioned(
                    right: -8,
                    top: 0,
                    child: ItemBuilder.buildTagItem(
                      context,
                      "+${item.unreadCount > 100 ? 99 : item.unreadCount}",
                      showTagLabel: false,
                      jumpToTag: false,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      TagType.normal,
                      fontSizeDelta: -2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "#${item.name}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  _buildSubscribeTagList(ScrollPhysics physics) {
    return SliverWaterfallFlow(
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 600,
        mainAxisSpacing: 12,
        crossAxisSpacing: 6,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _subscribeList[index];
          return KeyedSubtree(
            key: ValueKey('dynamic-tag-${item.name}'),
            child: ClickableWrapper(child: _buildSubscribeTagItem(item)),
          );
        },
        childCount: _subscribeList.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  _buildSubscribeTagItem(FullSubscribeTagItem item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
            context, TagDetailScreen(tag: item.name));
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16),
        color: Colors.transparent,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).iconTheme.color,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: AssetUtil.loadDouble(
                    context,
                    AssetUtil.tagWhiteIcon,
                    AssetUtil.tagLightIcon,
                    size: 10,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleLarge?.apply(
                        fontWeightDelta: 2,
                      ),
                ),
                if (StringUtil.isNotEmpty(item.tagRankName))
                  const SizedBox(width: 8),
                if (StringUtil.isNotEmpty(item.tagRankName))
                  ItemBuilder.buildTagItem(
                    context,
                    item.tagRankName,
                    TagType.normal,
                    backgroundColor:
                        Theme.of(context).primaryColor.withAlpha(30),
                    color: ChewieColors.likeButtonColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    showTagLabel: false,
                    jumpToTag: false,
                    fontSizeDelta: -1,
                  ),
                if (item.unreadCount > 0) const SizedBox(width: 8),
                if (item.unreadCount > 0)
                  ItemBuilder.buildTagItem(
                    context,
                    "+${item.unreadCount}",
                    TagType.normal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    showTagLabel: false,
                    jumpToTag: false,
                    fontSizeDelta: -1,
                  ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: Theme.of(context).textTheme.labelSmall?.color,
                  size: 16,
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                if (item.cardInfo != null && item.cardInfo!.type == 1) {
                  RouteUtil.pushPanelCupertinoRoute(
                    context,
                    CollectionDetailScreen(
                      collectionId:
                          item.cardInfo!.collectionCard!.collectionInfo.id,
                      postId: 0,
                      blogId:
                          item.cardInfo!.collectionCard!.collectionInfo.blogId,
                      blogName: "",
                    ),
                  );
                } else if (item.cardInfo != null &&
                    item.cardInfo!.type == 100) {
                  RouteUtil.pushPanelCupertinoRoute(
                    context,
                    PostDetailScreen(
                      meta: {
                        "postId":
                            item.cardInfo!.postCard!.postInfo.postId.toString(),
                        "blogId":
                            item.cardInfo!.postCard!.postInfo.blogId.toString(),
                        "blogName": "",
                      },
                      isArticle: false,
                    ),
                  );
                } else if (item.cardInfo != null && item.cardInfo!.type == 2) {
                  RouteUtil.pushPanelCupertinoRoute(
                    context,
                    UserDetailScreen(
                      blogId: item.cardInfo!.blogCard!.blogInfo.blogId,
                      blogName: item.cardInfo!.blogCard!.blogInfo.blogNickName,
                    ),
                  );
                } else {
                  RouteUtil.pushPanelCupertinoRoute(
                      context, TagDetailScreen(tag: item.name));
                }
              },
              child: _buildInfo(item),
            ),
            const MyDivider(horizontal: 0, vertical: 12),
          ],
        ),
      ),
    );
  }

  _buildInfo(FullSubscribeTagItem item) {
    if (item.cardInfo != null && item.cardInfo!.type == 0) {
      String title =
          StringUtil.clearBlank(item.cardInfo!.postCard!.postInfo.title);
      String digest = StringUtil.clearBlank(HtmlUtil.extractTextFromHtml(
          item.cardInfo!.postCard!.postInfo.digest));
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).cardColor,
        ),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (StringUtil.isNotEmpty(title))
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.apply(
                            fontSizeDelta: -1,
                          ),
                    ),
                  if (StringUtil.isNotEmpty(digest))
                    Text(
                      digest,
                      style: Theme.of(context).textTheme.labelMedium?.apply(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ItemBuilder.buildTagItem(
                        context,
                        item.cardInfo!.recommendMsg,
                        TagType.normal,
                        backgroundColor:
                            Theme.of(context).primaryColor.withAlpha(30),
                        color: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        showTagLabel: false,
                        fontSizeDelta: -2,
                        jumpToTag: false,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "${StringUtil.formatCount(item.cardInfo!.postCard!.postHot)}${appLocalizations.hotCount}",
                          style: Theme.of(context).textTheme.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            if (StringUtil.isNotEmpty(item.cardInfo!.postCard!.postInfo.image))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ChewieItemBuilder.buildCachedImage(
                  context: context,
                  imageUrl: item.cardInfo!.postCard!.postInfo.image,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  showLoading: false,
                ),
              ),
          ],
        ),
      );
    } else if (item.cardInfo != null && item.cardInfo!.type == 1) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).cardColor,
        ),
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.cardInfo!.collectionCard!.collectionInfo.name,
                    style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontSizeDelta: -1,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ItemBuilder.buildTagItem(
                        context,
                        item.cardInfo!.recommendMsg,
                        TagType.normal,
                        backgroundColor:
                            Theme.of(context).primaryColor.withAlpha(30),
                        color: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        showTagLabel: false,
                        fontSizeDelta: -2,
                        jumpToTag: false,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${StringUtil.formatCount(item.cardInfo!.collectionCard!.collectionInfo.subscribedCount)}${appLocalizations.subscribe} ${StringUtil.formatCount(item.cardInfo!.collectionCard!.collectionInfo.viewCount)}${appLocalizations.viewCount}",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  )
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ChewieItemBuilder.buildCachedImage(
                context: context,
                imageUrl:
                    item.cardInfo!.collectionCard!.collectionInfo.coverUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                showLoading: false,
              ),
            ),
          ],
        ),
      );
    } else if (item.cardInfo != null &&
        item.cardInfo!.type == 2 &&
        item.cardInfo!.blogCard != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).cardColor,
        ),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.cardInfo!.blogCard!.blogInfo.blogNickName,
                    style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontSizeDelta: -1,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ItemBuilder.buildTagItem(
                        context,
                        item.cardInfo!.recommendMsg,
                        TagType.normal,
                        backgroundColor:
                            Theme.of(context).primaryColor.withAlpha(30),
                        color: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        showTagLabel: false,
                        fontSizeDelta: -2,
                        jumpToTag: false,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${appLocalizations.circleWorks}${(StringUtil.formatCount(item.cardInfo!.blogCard!.circleHot))}${appLocalizations.hotCount}",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  )
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: ChewieItemBuilder.buildCachedImage(
                context: context,
                imageUrl: item.cardInfo!.blogCard!.blogInfo.bigAvaImg,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                showLoading: false,
              ),
            ),
          ],
        ),
      );
    }
    return emptyWidget;
  }
}

class SubscribeCollectionTab extends StatefulWidget {
  const SubscribeCollectionTab({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  State<StatefulWidget> createState() => SubscribeCollectionTabState();
}

class SubscribeCollectionTabState
    extends BaseDynamicState<SubscribeCollectionTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final EasyRefreshController _refreshController = EasyRefreshController();
  late final PagedDataController<TimelineCollection, int, int,
      List<TimelineGuessCollection>> _pagingController;
  late final ScrollController _scrollController =
      widget.scrollController ?? ScrollController();

  List<TimelineCollection> get _subscribeList => _pagingController.items;
  List<TimelineGuessCollection> get _guessLikeList =>
      _pagingController.metadata ?? const <TimelineGuessCollection>[];
  bool get refreshReady => _refreshController.headerState != null;

  callRefresh() {
    if (_scrollController.hasClients &&
        _scrollController.offset > MediaQuery.sizeOf(context).height) {
      _scrollController
          .animateTo(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut)
          .then((_) {
        _refreshController.callRefresh();
      });
    } else {
      _refreshController.callRefresh();
    }
  }

  @override
  void dispose() {
    _pagingController
      ..removeListener(_handlePagingChanged)
      ..dispose();
    _refreshController.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  Future<PagedDataPage<TimelineCollection, int, List<TimelineGuessCollection>>>
      _loadPage(
    int cursor,
    bool refresh,
  ) async {
    final offset = refresh ? 0 : cursor;
    final value = await CollectionApi.getSubscribdCollectionList(
      offset: offset,
    );
    final data = _requireDynamicData(value);
    final rawItems = data['collections'];
    final collections = parsePagedDataItems<TimelineCollection>(
      rawItems,
      TimelineCollection.fromJson,
      onMalformed: (error, stackTrace) => ILogger.error(
        'Skipped malformed subscribed collection',
        error,
        stackTrace,
      ),
    );
    final guesses = rawItems is List && rawItems.isEmpty
        ? parsePagedDataItems<TimelineGuessCollection>(
            data['guessLikeList'],
            TimelineGuessCollection.fromJson,
            onMalformed: (error, stackTrace) => ILogger.error(
              'Skipped malformed guessed collection',
              error,
              stackTrace,
            ),
          )
        : <TimelineGuessCollection>[];
    return PagedDataPage(
      items: collections,
      nextCursor: offset + (rawItems is List ? rawItems.length : 0),
      hasMore: rawItems is List && rawItems.isNotEmpty,
      metadata: guesses,
    );
  }

  Future<IndicatorResult> _fetchResult({bool refresh = false}) =>
      refresh ? _pagingController.refresh() : _pagingController.load();

  @override
  void initState() {
    super.initState();
    _pagingController = PagedDataController(
      initialCursor: 0,
      keyOf: (item) => item.collectionId,
      loader: _loadPage,
      metadataMerger: (current, incoming, refresh) {
        final merged = <TimelineGuessCollection>[
          ...?current,
          ...?incoming,
        ];
        final seen = <int>{};
        merged.removeWhere((item) => !seen.add(item.collectionId));
        return merged;
      },
      onError: (error, stackTrace) {
        ILogger.error(
            'Failed to load subscribed collections', error, stackTrace);
        if (mounted) {
          IToast.showTop(
            error is PagedDataException && StringUtil.isNotEmpty(error.message)
                ? error.message
                : appLocalizations.loadFailed,
          );
        }
      },
    )..addListener(_handlePagingChanged);
  }

  void _handlePagingChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh.builder(
      refreshOnStart: false,
      controller: _refreshController,
      onRefresh: () async {
        return await _fetchResult(refresh: true);
      },
      onLoad: _pagingController.noMore
          ? null
          : () async {
              return await _fetchResult();
            },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        controller: _scrollController,
        physics: physics,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                if (_subscribeList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: EmptyPlaceholder(
                      text: appLocalizations.noSubscribedCollection,
                    ),
                  ),
              ],
            ),
          ),
          if (_subscribeList.isNotEmpty) _buildSubscribeCollectionList(physics),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                if (_guessLikeList.isNotEmpty)
                  const MyDivider(horizontal: 16, vertical: 8),
                if (_guessLikeList.isNotEmpty)
                  ItemBuilder.buildTitle(
                    context,
                    title: appLocalizations.guessYouLike,
                    topMargin: 10,
                    bottomMargin: 4,
                  ),
              ],
            ),
          ),
          if (_guessLikeList.isNotEmpty) _buildGuessLikeCollectionList(physics),
        ],
      ),
    );
  }

  _buildSubscribeCollectionList(ScrollPhysics physics) {
    return SliverWaterfallFlow(
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 560,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _subscribeList[index];
          return KeyedSubtree(
            key: ValueKey('dynamic-collection-${item.collectionId}'),
            child: ClickableWrapper(
              child: _buildSubscribeCollectionItem(item),
            ),
          );
        },
        childCount: _subscribeList.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  _buildSubscribeCollectionItem(TimelineCollection item) {
    bool hasLastRead = item.lastReadBlogId != 0 && item.lastReadPostId != 0;
    return GestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          CollectionDetailScreen(
            collectionId: item.collectionId,
            postId: 0,
            blogId: item.blogId,
            blogName: "",
          ),
        );
      },
      child: Container(
        height: 118,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ChewieItemBuilder.buildCachedImage(
                      imageUrl: item.coverUrl,
                      context: context,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      showLoading: false,
                    ),
                  ),
                ),
                if (item.recentlyRead == 1)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: ItemBuilder.buildTranslucentTag(
                      context,
                      text: appLocalizations.viewRecently,
                      fontSizeDelta: -2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.apply(fontWeightDelta: 2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.unreadCount > 0) const SizedBox(width: 3),
                      if (item.unreadCount > 0)
                        ItemBuilder.buildTagItem(
                          context,
                          appLocalizations.updateCount(
                              item.unreadCount > 100 ? 99 : item.unreadCount),
                          showTagLabel: false,
                          jumpToTag: false,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          TagType.normal,
                          fontSizeDelta: -2,
                          backgroundColor:
                              Theme.of(context).primaryColor.withAlpha(30),
                          color: Theme.of(context).primaryColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (item.latestPosts != null)
                    Text(
                      item.latestPosts!.join("\n"),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.apply(fontSizeDelta: 1),
                      maxLines: 3,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),
                      ItemBuilder.buildIconTextButton(
                        context,
                        text: hasLastRead
                            ? appLocalizations.continueRead
                            : appLocalizations.startRead,
                        color: Theme.of(context).primaryColor,
                        fontWeightDelta: 2,
                        onTap: !hasLastRead
                            ? null
                            : () {
                                RouteUtil.pushPanelCupertinoRoute(
                                  context,
                                  PostDetailScreen(
                                    meta: {
                                      "postId": NumberUtil.intToHex(
                                          item.lastReadPostId),
                                      "blogId": NumberUtil.intToHex(
                                          item.lastReadBlogId),
                                      "blogName": "",
                                    },
                                    isArticle: false,
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildGuessLikeCollectionList(ScrollPhysics physics) {
    return SliverWaterfallFlow(
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 560,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _guessLikeList[index];
          return KeyedSubtree(
            key: ValueKey('dynamic-guess-collection-${item.collectionId}'),
            child: ClickableWrapper(
              child: _buildGuessLikeCollectionItem(item),
            ),
          );
        },
        childCount: _guessLikeList.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  _buildGuessLikeCollectionItem(TimelineGuessCollection item) {
    List<String> tags = [];
    tags = item.tags.split(",");
    return GestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          CollectionDetailScreen(
            collectionId: item.collectionId,
            postId: 0,
            blogId: item.blogId,
            blogName: "",
          ),
        );
      },
      child: Container(
        height: 125,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ChewieItemBuilder.buildCachedImage(
                      imageUrl: item.coverUrl,
                      context: context,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      showLoading: false,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.apply(fontWeightDelta: 2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 3),
                          if (StringUtil.isNotEmpty(item.reason))
                            RoundIconTextButton(
                              text: item.reason,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 2),
                              radius: 3,
                              color: ChewieColors.likeButtonColor,
                              fontSizeDelta: -2,
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.latestPost,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 16,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...List.generate(
                          tags.length,
                          (index) => Container(
                            margin: const EdgeInsets.only(right: 5),
                            child: ItemBuilder.buildTagItem(
                              context,
                              tags[index],
                              TagType.normal,
                              showIcon: false,
                              fontSizeDelta: -3,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${item.postCount}${appLocalizations.chapter} · ${StringUtil.formatCount(item.subscribeCount)}${appLocalizations.subscribe}",
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.apply(fontSizeDelta: -1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      ItemBuilder.buildIconTextButton(
                        context,
                        text: item.subscribed
                            ? appLocalizations.unsubscribe
                            : appLocalizations.subscribe,
                        icon: Icon(
                          item.subscribed
                              ? Icons.bookmark_added_rounded
                              : Icons.bookmark_add_outlined,
                          size: 15,
                          color: Theme.of(context).primaryColor,
                        ),
                        color: Theme.of(context).primaryColor,
                        fontWeightDelta: 2,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          CollectionApi.subscribeOrUnSubscribe(
                            isSubscribe: !item.subscribed,
                            collectionId: item.collectionId,
                          ).then((value) {
                            if (value['meta']['status'] != 200) {
                              IToast.showTop(value['meta']['desc'] ??
                                  value['meta']['msg']);
                            } else {
                              item.subscribed = !item.subscribed;
                              setState(() {});
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscribeGrainTab extends StatefulWidget {
  const SubscribeGrainTab({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  State<StatefulWidget> createState() => SubscribeGrainTabState();
}

class SubscribeGrainTabState extends BaseDynamicState<SubscribeGrainTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final EasyRefreshController _refreshController = EasyRefreshController();
  late final PagedDataController<SubscribeGrainItem, int, int, void>
      _pagingController;
  late final ScrollController _scrollController =
      widget.scrollController ?? ScrollController();

  List<SubscribeGrainItem> get _subscribeList => _pagingController.items;
  bool get refreshReady => _refreshController.headerState != null;

  @override
  void dispose() {
    _pagingController
      ..removeListener(_handlePagingChanged)
      ..dispose();
    _refreshController.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  callRefresh() {
    if (_scrollController.hasClients &&
        _scrollController.offset > MediaQuery.sizeOf(context).height) {
      _scrollController
          .animateTo(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut)
          .then((_) {
        _refreshController.callRefresh();
      });
    } else {
      _refreshController.callRefresh();
    }
  }

  Future<PagedDataPage<SubscribeGrainItem, int, void>> _loadPage(
    int cursor,
    bool refresh,
  ) async {
    final offset = refresh ? 0 : cursor;
    final value = await GrainApi.listSubscribdGrainList(offset: offset);
    final data = _requireDynamicData(value);
    final rawItems = data['grains'];
    final items = parsePagedDataItems<SubscribeGrainItem>(
      rawItems,
      SubscribeGrainItem.fromJson,
      onMalformed: (error, stackTrace) => ILogger.error(
        'Skipped malformed subscribed grain',
        error,
        stackTrace,
      ),
    );
    final totalValue = data['grainCount'] ?? data['total'];
    final total = (totalValue as num?)?.toInt();
    final nextOffset = offset + (rawItems is List ? rawItems.length : 0);
    return PagedDataPage(
      items: items,
      nextCursor: nextOffset,
      hasMore: rawItems is List &&
          rawItems.isNotEmpty &&
          (total == null || nextOffset < total),
      total: total,
    );
  }

  Future<IndicatorResult> _fetchResult({bool refresh = false}) =>
      refresh ? _pagingController.refresh() : _pagingController.load();

  @override
  void initState() {
    super.initState();
    _pagingController = PagedDataController(
      initialCursor: 0,
      keyOf: (item) => item.grain.id,
      loader: _loadPage,
      onError: (error, stackTrace) {
        ILogger.error('Failed to load subscribed grains', error, stackTrace);
        if (mounted) {
          IToast.showTop(
            error is PagedDataException && StringUtil.isNotEmpty(error.message)
                ? error.message
                : appLocalizations.loadFailed,
          );
        }
      },
    )..addListener(_handlePagingChanged);
  }

  void _handlePagingChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh.builder(
      refreshOnStart: false,
      controller: _refreshController,
      onRefresh: () async {
        return await _fetchResult(refresh: true);
      },
      onLoad: _pagingController.noMore
          ? null
          : () async {
              return await _fetchResult();
            },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        controller: _scrollController,
        physics: physics,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                if (_subscribeList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: EmptyPlaceholder(
                      text: appLocalizations.noSubscribedGrain,
                    ),
                  ),
              ],
            ),
          ),
          if (_subscribeList.isNotEmpty) _buildSubscribeGrainList(physics),
        ],
      ),
    );
  }

  _buildSubscribeGrainList(ScrollPhysics physics) {
    return SliverWaterfallFlow(
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 560,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _subscribeList[index];
          return KeyedSubtree(
            key: ValueKey('dynamic-grain-${item.grain.id}'),
            child: ClickableWrapper(child: _buildSubscribeGrainItem(item)),
          );
        },
        childCount: _subscribeList.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  _buildSubscribeGrainItem(SubscribeGrainItem item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          GrainDetailScreen(
            grainId: item.grain.id,
            blogId: item.blogInfo.blogId,
          ),
        );
      },
      child: Container(
        height: 125,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 0.8,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ChewieItemBuilder.buildCachedImage(
                  imageUrl: item.grain.coverUrl,
                  context: context,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  showLoading: false,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.grain.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.apply(fontWeightDelta: 2),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      StringUtil.isNotEmpty(item.latestPost.title)
                          ? item.latestPost.title
                          : item.latestPost.digest,
                      style: Theme.of(context).textTheme.labelMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
