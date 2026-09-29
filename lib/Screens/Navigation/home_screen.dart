import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/recommend_api.dart';
import 'package:loftify/Widgets/PostItem/recommend_flow_item_builder.dart';
import 'package:provider/provider.dart';

import '../../Models/recommend_response.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/lottie_files.dart';
import '../../Utils/paged_data_controller.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'search_screen.dart';

int krefreshTimeout = 300;

typedef _ExploreCursor = ({int offset, int page, int feed});

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  static const String routeName = "/nav/home";

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends BaseDynamicState<HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScrollToHideMixin,
        BottomNavgationMixin {
  @override
  bool get wantKeepAlive => true;
  int lastRefreshTime = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  late final ScrollController _scrollController =
      widget.scrollController ?? ScrollController();
  final ScrollController _nestedScrollController = ScrollController();
  ScrollController? _nestedInnerScrollController;
  late final PagedDataController<PostListItem, int, _ExploreCursor, void>
      _pagingController;
  late AnimationController _refreshRotationController;
  final ScrollToHideController _scrollToHideController =
      ScrollToHideController();
  Future<void> refresh() async {
    await _scrollHomeToTop();
    if (mounted) await _triggerRefresh();
  }

  @override
  void initState() {
    super.initState();
    _refreshRotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pagingController = PagedDataController(
      initialCursor: (offset: 0, page: 0, feed: 0),
      keyOf: (item) => item.postData?.postView.id ?? item.itemId,
      loader: _loadExplorePage,
      onError: (error, stackTrace) {
        ILogger.error(
            'Failed to load explore recommendations', error, stackTrace);
        if (!mounted) return;
        IToast.showTop(
          error is PagedDataException && StringUtil.isNotEmpty(error.message)
              ? error.message
              : appLocalizations.loadFailed,
        );
      },
    )..addListener(_handlePagingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) panelScreenState?.refreshScrollControllers();
    });
  }

  Future<PagedDataPage<PostListItem, _ExploreCursor, void>> _loadExplorePage(
    _ExploreCursor cursor,
    bool refresh,
  ) async {
    final page = refresh ? 1 : cursor.page + 1;
    final feed = refresh ? 0 : cursor.feed + 1;
    final value = await RecommendApi.getExploreRecomend(
      offset: refresh ? 0 : cursor.offset,
      page: page,
      feed: feed,
    );
    final code = (value['code'] as num?)?.toInt();
    if (code == 4009) {
      return PagedDataPage(
        items: const [],
        nextCursor: cursor,
        hasMore: false,
      );
    }
    if (code != 0) {
      throw PagedDataException(value['msg']?.toString() ?? '');
    }

    final data = value['data'];
    if (data is! Map) {
      throw const PagedDataException('');
    }
    final rawItems = data['list'] is List
        ? List<dynamic>.from(data['list'] as List)
        : const <dynamic>[];
    final items = <PostListItem>[];
    for (final rawItem in rawItems) {
      try {
        if (rawItem is Map) {
          items.add(PostListItem.fromJson(
            Map<String, dynamic>.from(rawItem),
          ));
        }
      } catch (error, stackTrace) {
        ILogger.error('Skipped malformed explore card', error, stackTrace);
      }
    }
    final nextOffset = (data['offset'] as num?)?.toInt() ?? cursor.offset;
    return PagedDataPage(
      items: items,
      nextCursor: (offset: nextOffset, page: page, feed: feed),
      hasMore: rawItems.isNotEmpty,
    );
  }

  void _handlePagingChanged() {
    if (mounted) setState(() {});
  }

  Future<IndicatorResult> _onRefresh() => _pagingController.refresh();

  Future<IndicatorResult> _onLoad() => _pagingController.load();

  @override
  void dispose() {
    _pagingController
      ..removeListener(_handlePagingChanged)
      ..dispose();
    _refreshController.dispose();
    _refreshRotationController.dispose();
    _nestedScrollController.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final design = context.design;
    final hideAppBar = context.select<AppProvider, bool>(
      (provider) => provider.hideHomeAppBarOnScroll,
    );
    final showSearchAction = context.select<AppProvider, bool>(
      (provider) => provider.hideSearchNavigation,
    );
    return Scaffold(
      backgroundColor: design.colors.page,
      appBar: hideAppBar ? null : _buildHomeAppBar(showSearchAction),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final centeredInset =
              ((viewportWidth - design.grid.maximumContentWidth) / 2)
                  .clamp(0.0, double.infinity);
          final pageInset = design.grid.denseFeedPagePaddingFor(viewportWidth);
          final horizontalInset = centeredInset + pageInset;
          final gutter = design.grid.gutterFor(viewportWidth);

          if (!hideAppBar) {
            return _buildFeed(
              design: design,
              horizontalInset: horizontalInset,
              gutter: gutter,
              scrollController: _scrollController,
              hideAppBar: false,
            );
          }

          // Keep the toolbar in the outer scroll view, as in CloudOTP. The
          // refresh header belongs to the inner list, so it opens below the
          // visible toolbar while the list can scroll under the status bar.
          return ExtendedNestedScrollView(
            controller: _nestedScrollController,
            floatHeaderSlivers: true,
            onlyOneScrollInBody: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                key: const ValueKey('home-floating-app-bar'),
                floating: true,
                snap: true,
                pinned: false,
                toolbarHeight: 48,
                titleSpacing: 15,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                backgroundColor: design.colors.page,
                title: Text(
                  appLocalizations.home,
                  style: ChewieTheme.titleMedium.apply(fontWeightDelta: 2),
                ),
                actions: showSearchAction ? [_buildSearchAction()] : const [],
              ),
            ],
            body: Builder(
              builder: (context) {
                final innerController = PrimaryScrollController.of(context);
                if (!identical(_nestedInnerScrollController, innerController)) {
                  _nestedInnerScrollController = innerController;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) panelScreenState?.refreshScrollControllers();
                  });
                }
                return _buildFeed(
                  design: design,
                  horizontalInset: horizontalInset,
                  gutter: gutter,
                  scrollController: innerController,
                  hideAppBar: true,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeed({
    required LoftifyDesignThemeData design,
    required double horizontalInset,
    required double gutter,
    required ScrollController scrollController,
    required bool hideAppBar,
  }) {
    return Stack(
      children: [
        EasyRefresh.builder(
          refreshOnStart: true,
          controller: _refreshController,
          scrollController: scrollController,
          header: hideAppBar
              ? LottieCupertinoHeader(
                  backgroundColor: Colors.transparent,
                  indicator: LottieFiles.buildLoadingAnimation(40, false),
                  safeArea: false,
                  clamping: true,
                  hapticFeedback: true,
                  triggerOffset: 56,
                  maxOverOffset: 84,
                  radius: 20,
                )
              : null,
          onRefresh: _onRefresh,
          onLoad: _pagingController.noMore ? null : _onLoad,
          childBuilder: (context, physics) => CustomScrollView(
            controller: scrollController,
            physics: physics,
            cacheExtent: MediaQuery.sizeOf(context).height,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  top: 8,
                  left: horizontalInset,
                  right: horizontalInset,
                ),
                sliver: SliverWaterfallFlow(
                  gridDelegate:
                      SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                    mainAxisSpacing: gutter,
                    crossAxisSpacing: gutter,
                    maxCrossAxisExtent: design.grid.maximumDenseCardExtent,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final item = _pagingController.items[index];
                      return KeyedSubtree(
                        key: ValueKey(
                          'explore-${item.postData?.postView.id ?? item.itemId}',
                        ),
                        child:
                            RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
                          context,
                          item,
                          showMoreButton: true,
                        ),
                      );
                    },
                    childCount: _pagingController.items.length,
                    addAutomaticKeepAlives: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: horizontalInset,
          bottom: ResponsiveUtil.isLandscapeLayout() ? design.spacing.xl : 76,
          child: ScrollToHide.multi(
            controller: _scrollToHideController,
            scrollControllers: hideAppBar
                ? [_nestedScrollController, scrollController]
                : [scrollController],
            hideDirection: Axis.vertical,
            child: _buildFloatingButtons(),
          ),
        ),
      ],
    );
  }

  ResponsiveAppBar _buildHomeAppBar(bool showSearchAction) {
    return ResponsiveAppBar(
      title: appLocalizations.home,
      titleLeftMargin: 15,
      actions: showSearchAction ? [_buildSearchAction()] : const [],
      landscapeActions: showSearchAction ? [_buildSearchAction()] : const [],
    );
  }

  Widget _buildSearchAction() {
    return ChewieIconButton(
      icon: LoftifyIcons.search,
      tooltip: appLocalizations.search,
      onPressed: () => RouteUtil.pushPanelCupertinoRoute(
        context,
        const SearchScreen(showBack: true),
      ),
    );
  }

  Future<void> _refreshFromHomeNavigation() async {
    final distanceFromTop = _homeDistanceFromTop;
    final shouldRefreshAfterScroll =
        distanceFromTop <= MediaQuery.sizeOf(context).height / 2;
    if (distanceFromTop > 1) {
      await _scrollHomeToTop();
      if (!mounted || !shouldRefreshAfterScroll) {
        return;
      }
    }
    await _triggerRefresh();
  }

  double get _homeDistanceFromTop {
    final feed = _feedScrollController;
    final feedDistance = feed.hasClients && feed.offset > 0 ? feed.offset : 0.0;
    final appBarDistance = appProvider.hideHomeAppBarOnScroll &&
            _nestedScrollController.hasClients &&
            !identical(feed, _nestedScrollController)
        ? (_nestedScrollController.offset > 0
            ? _nestedScrollController.offset
            : 0.0)
        : 0.0;
    return feedDistance + appBarDistance;
  }

  Future<void> _triggerRefresh() async {
    final feed = _feedScrollController;
    if (!mounted || !feed.hasClients || _pagingController.loading) return;
    final nowTime = DateTime.now().millisecondsSinceEpoch;
    if (lastRefreshTime != 0 && nowTime - lastRefreshTime <= krefreshTimeout) {
      return;
    }
    lastRefreshTime = nowTime;
    await _refreshController.callRefresh(
      scrollController: feed,
      jumpToEdge: !appProvider.hideHomeAppBarOnScroll,
    );
  }

  void scrollToTopAndRefresh() => unawaited(refresh());

  Widget _buildFloatingButtons() {
    return ResponsiveUtil.isLandscapeLayout()
        ? Column(
            children: [
              ShadowIconButton(
                icon: RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0)
                      .animate(_refreshRotationController),
                  child: const ChewieIcon(LoftifyIcons.refresh),
                ),
                onTap: () async {
                  refresh();
                },
              ),
              const SizedBox(height: 10),
              ShadowIconButton(
                icon: const ChewieIcon(LoftifyIcons.scrollTop),
                onTap: () {
                  scrollToTop();
                },
              ),
            ],
          )
        : emptyWidget;
  }

  ScrollController get _feedScrollController =>
      appProvider.hideHomeAppBarOnScroll
          ? _nestedInnerScrollController ?? _nestedScrollController
          : _scrollController;

  Future<void> _scrollHomeToTop() async {
    final feed = _feedScrollController;
    if (feed.hasClients && feed.offset > 0) {
      await feed.animateTo(0,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
    if (appProvider.hideHomeAppBarOnScroll &&
        _nestedScrollController.hasClients &&
        _nestedScrollController.offset > 0) {
      await _nestedScrollController.animateTo(0,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  void scrollToTop() => unawaited(_scrollHomeToTop());

  void scrollToTopOrRefresh() {
    unawaited(_refreshFromHomeNavigation());
  }

  @override
  List<ScrollController> getScrollControllers() {
    if (!appProvider.hideHomeAppBarOnScroll) return [_scrollController];
    final inner = _nestedInnerScrollController;
    return [
      _nestedScrollController,
      if (inner != null && !identical(inner, _nestedScrollController)) inner,
    ];
  }

  @override
  FutureOr onTapBottomNavigation() {
    return _refreshFromHomeNavigation();
  }
}
