import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/recommend_api.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/refresh_interface.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Widgets/PostItem/recommend_flow_item_builder.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Api/post_api.dart';
import '../../Models/recommend_response.dart';
import '../../Utils/constant.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/responsive_util.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Hidable/scroll_to_hide.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

int krefreshTimeout = 300;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = "/nav/home";

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScrollToHideMixin,
        BottomNavgationMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostListItem> _recommendPosts = [];
  bool _loading = false;
  int lastRefreshTime = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  int _currentOffset = 0;
  int _currentFeed = 0;
  late AnimationController _refreshRotationController;
  final ScrollToHideController _scrollToHideController =
      ScrollToHideController();

  refresh() {
    _refreshController.callRefresh();
  }

  @override
  void initState() {
    _refreshRotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - kLoadExtentOffset) {
        _onLoad();
      }
    });
  }

  _fetchData({bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    if (!refresh) {
      _currentFeed++;
    } else {
      _currentFeed = 0;
      _currentOffset = 0;
    }
    _currentPage++;
    return await RecommendApi.getExploreRecomend(
      offset: _currentOffset,
      page: _currentPage,
      feed: _currentFeed,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          if (value['code'] != 4009) {
            IToast.showTop(value['msg']);
          }
          return IndicatorResult.fail;
        } else {
          _currentOffset = value['data']['offset'];
          List<dynamic> tmp = value['data']['list'];
          if (refresh) _recommendPosts.clear();
          _recommendPosts
              .addAll(tmp.map((e) => PostListItem.fromJson(e)).toList());
          return IndicatorResult.success;
        }
      } catch (e, t) {
        IToast.showTop("加载失败");
        ILogger.error("Failed to load data", e, t);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  _onRefresh() async {
    return await _fetchData(refresh: true);
  }

  _onLoad() async {
    return await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MyTheme.getBackground(context),
      appBar: ItemBuilder.buildDesktopAppBar(
        context: context,
        title: S.current.home,
        spacing: ResponsiveUtil.isLandscape() ? 15 : 10,
      ),
      body: Stack(
        children: [
          EasyRefresh(
            refreshOnStart: true,
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoad: _onLoad,
            child: WaterfallFlow.builder(
              controller: _scrollController,
              cacheExtent: 9999,
              padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
              gridDelegate:
                  const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                maxCrossAxisExtent: 300,
              ),
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  child: RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
                    context,
                    _recommendPosts[index],
                    showMoreButton: true,
                    onLikeTap: () async {
                      var item = _recommendPosts[index];
                      HapticFeedback.mediumImpact();
                      return await PostApi.likeOrUnLike(
                              isLike: !item.favorite,
                              postId: item.itemId,
                              blogId: item.blogInfo!.blogId)
                          .then((value) {
                        setState(() {
                          if (value['meta']['status'] != 200) {
                            IToast.showTop(
                                value['meta']['desc'] ?? value['meta']['msg']);
                          } else {
                            item.favorite = !item.favorite;
                            item.postData!.postCount!.favoriteCount +=
                                item.favorite ? 1 : -1;
                          }
                        });
                        return value['meta']['status'];
                      });
                    },
                    onShieldContent: () {
                      _recommendPosts.remove(_recommendPosts[index]);
                      setState(() {});
                    },
                    onShieldTag: (tag) {
                      _recommendPosts.remove(_recommendPosts[index]);
                      setState(() {});
                    },
                    onShieldUser: () {
                      _recommendPosts.remove(_recommendPosts[index]);
                      setState(() {});
                    },
                  ),
                );
              },
              itemCount: _recommendPosts.length,
            ),
          ),
          Positioned(
            right: ResponsiveUtil.isLandscape() ? 16 : 12,
            bottom: ResponsiveUtil.isLandscape() ? 16 : 76,
            child: ScrollToHide(
              controller: _scrollToHideController,
              scrollControllers: [_scrollController],
              hideDirection: AxisDirection.down,
              child: _buildFloatingButtons(),
            ),
          ),
        ],
      ),
    );
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
    return ResponsiveUtil.isLandscape()
        ? Column(
            children: [
              ItemBuilder.buildShadowIconButton(
                context: context,
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
              ItemBuilder.buildShadowIconButton(
                context: context,
                icon: const Icon(Icons.arrow_upward_rounded),
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
