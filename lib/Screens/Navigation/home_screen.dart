import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/recommend_api.dart';
import 'package:loftify/Widgets/PostItem/recommend_flow_item_builder.dart';
import 'package:provider/provider.dart';

import '../../Models/recommend_response.dart';
import '../../Screens/Info/system_notice_screen.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Utils/paged_data_controller.dart';
import '../../Widgets/Navigation/loftify_floating_navigation_header.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

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
  late final PagedDataController<PostListItem, int, _ExploreCursor, void>
      _pagingController;
  late AnimationController _refreshRotationController;
  final ScrollToHideController _scrollToHideController =
      ScrollToHideController();

  refresh() {
    _refreshController.callRefresh();
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
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final design = context.design;
    return Scaffold(
      backgroundColor: design.colors.page,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final centeredInset =
              ((viewportWidth - design.grid.maximumContentWidth) / 2)
                  .clamp(0.0, double.infinity);
          final pageInset = design.grid.pagePaddingFor(viewportWidth);
          final horizontalInset = centeredInset + pageInset;
          final gutter = design.grid.gutterFor(viewportWidth);

          return Stack(
            children: [
              EasyRefresh(
                header: buildFloatingNavigationRefreshHeader(),
                refreshOnStart: true,
                controller: _refreshController,
                onRefresh: _onRefresh,
                onLoad: _pagingController.noMore ? null : _onLoad,
                child: WaterfallFlow.builder(
                  controller: _scrollController,
                  cacheExtent: MediaQuery.sizeOf(context).height,
                  padding: EdgeInsets.only(
                    top: LoftifyFloatingNavigationHeader.contentTopInset(
                      context,
                    ),
                    left: horizontalInset,
                    right: horizontalInset,
                  ),
                  gridDelegate:
                      SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                    mainAxisSpacing: gutter,
                    crossAxisSpacing: gutter,
                    maxCrossAxisExtent: design.grid.maximumDenseCardExtent,
                  ),
                  itemBuilder: (BuildContext context, int index) {
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
                  itemCount: _pagingController.items.length,
                ),
              ),
              Positioned(
                right: horizontalInset,
                bottom:
                    ResponsiveUtil.isLandscapeLayout() ? design.spacing.xl : 76,
                child: ScrollToHide.multi(
                  controller: _scrollToHideController,
                  scrollControllers: [_scrollController],
                  hideDirection: Axis.vertical,
                  child: _buildFloatingButtons(),
                ),
              ),
              LoftifyFloatingNavigationHeader(
                child: Selector<AppProvider, bool>(
                  selector: (_, provider) => provider.reduceTransparency,
                  builder: (context, reduceTransparency, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LoftifyNavigationAvatarButton(
                        key: const ValueKey('home-navigation-avatar'),
                        semanticLabel: appLocalizations.mine,
                        enableBlur: !reduceTransparency,
                        onPressed: _openMine,
                      ),
                      LoftifyFloatingHeaderTitle(
                        key: const ValueKey('home-navigation-title'),
                        title: appLocalizations.appName,
                        enableBlur: !reduceTransparency,
                      ),
                      LoftifyFloatingHeaderAction(
                        key: const ValueKey('home-navigation-notice'),
                        icon: LoftifyIcons.notifications,
                        tooltip: appLocalizations.notice,
                        enableBlur: !reduceTransparency,
                        onPressed: () {
                          RouteUtil.pushPanelCupertinoRoute(
                            context,
                            const SystemNoticeScreen(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openMine() {
    appProvider.sidebarChoice = SideBarChoice.Mine;
    panelScreenState?.popAll(false);
  }

  void scrollToTopAndRefresh() {
    int nowTime = DateTime.now().millisecondsSinceEpoch;
    if (lastRefreshTime == 0 || (nowTime - lastRefreshTime) > krefreshTimeout) {
      lastRefreshTime = nowTime;
      if (_scrollController.offset > MediaQuery.sizeOf(context).height) {
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
  }

  _buildFloatingButtons() {
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

  void scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void scrollToTopOrRefresh() {
    if (_scrollController.offset > 30) {
      scrollToTop();
    } else {
      _refreshController.callRefresh();
    }
  }

  @override
  List<ScrollController> getScrollControllers() {
    return [_scrollController];
  }

  @override
  FutureOr onTapBottomNavigation() {
    scrollToTopOrRefresh();
  }
}
