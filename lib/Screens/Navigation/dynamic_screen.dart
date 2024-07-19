import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/collection_api.dart';
import 'package:loftify/Api/grain_api.dart';
import 'package:loftify/Models/dynamic_response.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/collection_detail_screen.dart';
import 'package:loftify/Screens/Post/grain_detail_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Screens/Post/tag_detail_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/iprint.dart';
import 'package:loftify/Utils/route_util.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Api/tag_api.dart';
import '../../Providers/provider_manager.dart';
import '../../Resources/colors.dart';
import '../../Resources/theme.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Custom/custom_tab_indicator.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import 'home_screen.dart';

class DynamicScreen extends StatefulWidget {
  const DynamicScreen({super.key});

  static const String routeName = "/nav/dynamic";

  @override
  State<DynamicScreen> createState() => DynamicScreenState();
}

class DynamicScreenState extends State<DynamicScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;
  int _currentTabIndex = 0;
  final List<String> _tabLabelList = ["标签", "合集", "粮单"];
  int lastRefreshTime = 0;
  final GlobalKey _tagTabKey = GlobalKey();
  final GlobalKey _collectionTabKey = GlobalKey();
  final GlobalKey _grainTabKey = GlobalKey();

  void scrollToTopAndRefresh() {
    if (ProviderManager.globalProvider.token.isEmpty) return;
    int nowTime = DateTime.now().millisecondsSinceEpoch;
    if (lastRefreshTime == 0 || (nowTime - lastRefreshTime) > krefreshTimeout) {
      lastRefreshTime = nowTime;
      switch (_currentTabIndex) {
        case 0:
          (_tagTabKey.currentState as SubscribeTagTabState).callRefresh();
          break;
        case 1:
          (_collectionTabKey.currentState as SubscribeCollectionTabState)
              .callRefresh();
          break;
        case 2:
          (_grainTabKey.currentState as SubscribeGrainTabState).callRefresh();
          break;
      }
    }
  }

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
    initTab();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: ProviderManager.globalProvider.token.isNotEmpty
          ? _buildAppBar()
          : ResponsiveUtil.isDesktop()
              ? null
              : ItemBuilder.buildAppBar(
                  context: context,
                  backgroundColor: AppTheme.getBackground(context)),
      body: ProviderManager.globalProvider.token.isNotEmpty
          ? TabBarView(
              controller: _tabController,
              children: [
                SubscribeTagTab(key: _tagTabKey),
                SubscribeCollectionTab(key: _collectionTabKey),
                SubscribeGrainTab(key: _grainTabKey),
              ],
            )
          : ItemBuilder.buildUnLoginMainBody(context),
    );
  }

  initTab() {
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

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      backgroundColor: AppTheme.getBackground(context),
      context: context,
      title: TabBar(
        padding: EdgeInsets.zero,
        controller: _tabController,
        tabs: _tabLabelList
            .asMap()
            .entries
            .map((entry) => ItemBuilder.buildAnimatedTab(context,
                selected: entry.key == _currentTabIndex, text: entry.value))
            .toList(),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelPadding: const EdgeInsets.only(right: 32),
        enableFeedback: true,
        dividerHeight: 0,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        physics: const BouncingScrollPhysics(),
        indicator:
            CustomTabIndicator(borderColor: Theme.of(context).primaryColor),
        onTap: (index) {
          if (_currentTabIndex == index) {
            return;
          }
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}

class SubscribeTagTab extends StatefulWidget {
  const SubscribeTagTab({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SubscribeTagTabState();
}

class SubscribeTagTabState extends State<SubscribeTagTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<FullSubscribeTagItem> _subscribeList = [];
  final List<FullSubscribeTagItem> _recentVisitList = [];
  final EasyRefreshController _refreshController = EasyRefreshController();
  int _offset = 0;
  bool _loading = false;
  final ScrollController _scrollController = ScrollController();
  bool _noMore = false;

  callRefresh() {
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

  _fetchResult({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    return await TagApi.getFullSubscribdTagList(
      offset: refresh ? 0 : _offset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
        } else {
          List<FullSubscribeTagItem> tmp = [];
          if (value['data'] != null) {
            if (value['data']['offset'] != null) {
              _offset = value['data']['offset'];
            }
            if (value['data']['favoriteTags'] != null) {
              tmp = (value['data']['favoriteTags'] as List)
                  .map((e) => FullSubscribeTagItem.fromJson(e))
                  .toList();
              if (refresh) _subscribeList.clear();
              for (var exist in _subscribeList) {
                tmp.removeWhere((element) => element.name == exist.name);
              }
              _subscribeList.addAll(tmp);
            }
            if (value['data']['recentVisitTags'] != null) {
              if (refresh) _recentVisitList.clear();
              _recentVisitList.addAll((value['data']['recentVisitTags'] as List)
                  .map((e) => FullSubscribeTagItem.fromJson(e))
                  .toList());
            }
          }
          if (mounted) setState(() {});
          if (tmp.isEmpty && !refresh) {
            _noMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (_) {
        IToast.showTop("加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  @override
  initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_noMore &&
          _scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - kLoadExtentOffset) {
        _fetchResult();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh.builder(
      refreshOnStart: true,
      controller: _refreshController,
      onRefresh: () async {
        return await _fetchResult(refresh: true);
      },
      onLoad: () async {
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
                    title: "最常访问",
                    topMargin: 10,
                    bottomMargin: 10,
                  ),
                if (_recentVisitList.isNotEmpty) _buildRecentVisitTagList(),
                if (_recentVisitList.isNotEmpty)
                  ItemBuilder.buildDivider(
                    context,
                    horizontal: 0,
                    vertical: 16,
                  ),
                if (_recentVisitList.isEmpty) const SizedBox(height: 10),
                if (_subscribeList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: ItemBuilder.buildEmptyPlaceholder(
                      context: context,
                      text: "暂无订阅的标签",
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
          return ItemBuilder.buildClickItem(_buildRecentVisitTagItem(_recentVisitList[index]));
        },
      ),
    );
  }

  _buildRecentVisitTagItem(FullSubscribeTagItem item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushCupertinoRoute(context, TagDetailScreen(tag: item.name));
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
                  child: ItemBuilder.buildCachedImage(
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
    return SliverWaterfallFlow.extent(
      maxCrossAxisExtent: 600,
      mainAxisSpacing: 12,
      crossAxisSpacing: 6,
      children: List.generate(_subscribeList.length, (int index) {
        return ItemBuilder.buildClickItem(_buildSubscribeTagItem(_subscribeList[index]));
      }),
    );
  }

  _buildSubscribeTagItem(FullSubscribeTagItem item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushCupertinoRoute(context, TagDetailScreen(tag: item.name));
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
                if (Utils.isNotEmpty(item.tagRankName))
                  const SizedBox(width: 8),
                if (Utils.isNotEmpty(item.tagRankName))
                  ItemBuilder.buildTagItem(
                    context,
                    item.tagRankName,
                    TagType.normal,
                    backgroundColor:
                        Theme.of(context).primaryColor.withAlpha(30),
                    color: MyColors.likeButtonColor,
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
                  RouteUtil.pushCupertinoRoute(
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
                  RouteUtil.pushCupertinoRoute(
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
                  RouteUtil.pushCupertinoRoute(
                    context,
                    UserDetailScreen(
                      blogId: item.cardInfo!.blogCard!.blogInfo.blogId,
                      blogName: item.cardInfo!.blogCard!.blogInfo.blogNickName,
                    ),
                  );
                } else {
                  RouteUtil.pushCupertinoRoute(
                      context, TagDetailScreen(tag: item.name));
                }
              },
              child: _buildInfo(item),
            ),
            ItemBuilder.buildDivider(
              context,
              horizontal: 0,
              vertical: 12,
            ),
          ],
        ),
      ),
    );
  }

  _buildInfo(FullSubscribeTagItem item) {
    if (item.cardInfo != null && item.cardInfo!.type == 0) {
      String title = Utils.clearBlank(item.cardInfo!.postCard!.postInfo.title);
      String digest = Utils.clearBlank(
          Utils.extractTextFromHtml(item.cardInfo!.postCard!.postInfo.digest));
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
                  if (Utils.isNotEmpty(title))
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.apply(
                            fontSizeDelta: -1,
                          ),
                    ),
                  if (Utils.isNotEmpty(digest))
                    Text(
                      digest,
                      style: Theme.of(context).textTheme.labelMedium?.apply(
                            color: Colors.grey,
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
                      Text(
                        "${Utils.formatCount(item.cardInfo!.postCard!.postHot)}热度",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  )
                ],
              ),
            ),
            if (Utils.isNotEmpty(item.cardInfo!.postCard!.postInfo.image))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ItemBuilder.buildCachedImage(
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
                        "${Utils.formatCount(item.cardInfo!.collectionCard!.collectionInfo.subscribedCount)}订阅 ${Utils.formatCount(item.cardInfo!.collectionCard!.collectionInfo.viewCount)}浏览",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  )
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ItemBuilder.buildCachedImage(
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
                        "圈层作品${Utils.formatCount(item.cardInfo!.blogCard!.circleHot)}热度",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  )
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: ItemBuilder.buildCachedImage(
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
    return Container();
  }
}

class SubscribeCollectionTab extends StatefulWidget {
  const SubscribeCollectionTab({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SubscribeCollectionTabState();
}

class SubscribeCollectionTabState extends State<SubscribeCollectionTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<TimelineCollection> _subscribeList = [];
  final List<TimelineGuessCollection> _guessLikeList = [];
  final EasyRefreshController _refreshController = EasyRefreshController();
  int _total = 0;
  bool _loading = false;
  final ScrollController _scrollController = ScrollController();
  bool _noMore = false;
  bool _noMoreSubscribeItem = false;

  callRefresh() {
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

  @override
  initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_noMore &&
          _scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - kLoadExtentOffset) {
        _fetchResult();
      }
    });
  }

  _fetchResult({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _noMore = false;
      _noMoreSubscribeItem = false;
    }
    _loading = true;
    return await CollectionApi.getSubscribdCollectionList(
      offset: refresh ? 0 : _subscribeList.length,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
        } else {
          if (refresh) _guessLikeList.clear();
          List<TimelineCollection> tmp = [];
          List<TimelineCollection> uniqueSubscribeList = [];
          if (value['data'] != null) {
            if (value['data']['total'] != null) {
              _total = value['data']['subscribeCollectionCount'];
            }
            if (value['data']['collections'] != null) {
              tmp = (value['data']['collections'] as List)
                  .map((e) => TimelineCollection.fromJson(e))
                  .toList();
              if (refresh) _subscribeList.clear();
              for (var exist in _subscribeList) {
                tmp.removeWhere(
                    (element) => element.collectionId == exist.collectionId);
              }
              _subscribeList.addAll(tmp);
            }
            if (tmp.isEmpty) {
              _noMoreSubscribeItem = true;
            }
            Set<int> seenIds = {};
            for (var item in _subscribeList) {
              if (!seenIds.contains(item.collectionId)) {
                seenIds.add(item.collectionId);
                uniqueSubscribeList.add(item);
              }
            }
            _subscribeList.clear();
            _subscribeList.addAll(uniqueSubscribeList);
            if (_noMoreSubscribeItem &&
                value['data']['guessLikeList'] != null) {
              List<TimelineGuessCollection> tmp =
                  (value['data']['guessLikeList'] as List)
                      .map((e) => TimelineGuessCollection.fromJson(e))
                      .toList();
              tmp.removeWhere((e) => _guessLikeList
                  .any((element) => element.collectionId == e.collectionId));
              _guessLikeList.addAll(tmp);
            }
          }
          if (mounted) setState(() {});
          if ((tmp.isEmpty) && !refresh) {
            _noMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (_) {
        IToast.showTop("加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh.builder(
      refreshOnStart: true,
      controller: _refreshController,
      onRefresh: () async {
        return await _fetchResult(refresh: true);
      },
      onLoad: () async {
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
                    child: ItemBuilder.buildEmptyPlaceholder(
                      context: context,
                      text: "暂无订阅的合集",
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
                  ItemBuilder.buildDivider(
                    context,
                    horizontal: 16,
                    vertical: 8,
                  ),
                if (_guessLikeList.isNotEmpty)
                  ItemBuilder.buildTitle(
                    context,
                    title: "猜你喜欢",
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
    return SliverWaterfallFlow.extent(
      maxCrossAxisExtent: 560,
      children: List.generate(_subscribeList.length, (index) {
        return ItemBuilder.buildClickItem(_buildSubscribeCollectionItem(_subscribeList[index]));
      }),
    );
  }

  _buildSubscribeCollectionItem(TimelineCollection item) {
    bool hasLastRead = item.lastReadBlogId != 0 && item.lastReadPostId != 0;
    return GestureDetector(
      onTap: () {
        RouteUtil.pushCupertinoRoute(
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
                    child: ItemBuilder.buildCachedImage(
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
                    child: ItemBuilder.buildTransparentTag(
                      context,
                      text: "最近看过",
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
                          "${item.unreadCount > 100 ? 99 : item.unreadCount}篇更新",
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
                        text: hasLastRead ? "继续阅读" : "开始阅读",
                        color: Theme.of(context).primaryColor,
                        fontWeightDelta: 2,
                        onTap: !hasLastRead
                            ? null
                            : () {
                                RouteUtil.pushCupertinoRoute(
                                  context,
                                  PostDetailScreen(
                                    meta: {
                                      "postId":
                                          Utils.intToHex(item.lastReadPostId),
                                      "blogId":
                                          Utils.intToHex(item.lastReadBlogId),
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
    return SliverWaterfallFlow.extent(
      maxCrossAxisExtent: 560,
      children: List.generate(_guessLikeList.length, (index) {
        return ItemBuilder.buildClickItem(_buildGuessLikeCollectionItem(_guessLikeList[index]));
      }),
    );
  }

  _buildGuessLikeCollectionItem(TimelineGuessCollection item) {
    List<String> tags = [];
    tags = item.tags.split(",");
    return GestureDetector(
      onTap: () {
        RouteUtil.pushCupertinoRoute(
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
                    child: ItemBuilder.buildCachedImage(
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
                          if (Utils.isNotEmpty(item.reason))
                            ItemBuilder.buildRoundButton(
                              context,
                              text: item.reason,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 2),
                              radius: 3,
                              color: MyColors.likeButtonColor,
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
                        "${item.postCount}篇 · ${Utils.formatCount(item.subscribeCount)}订阅",
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
                        text: item.subscribed ? "取消订阅" : "订阅",
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
  });

  @override
  State<StatefulWidget> createState() => SubscribeGrainTabState();
}

class SubscribeGrainTabState extends State<SubscribeGrainTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<SubscribeGrainItem> _subscribeList = [];
  final EasyRefreshController _refreshController = EasyRefreshController();
  int _total = 0;
  bool _loading = false;
  final ScrollController _scrollController = ScrollController();
  bool _noMore = false;

  @override
  initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_noMore &&
          _scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - kLoadExtentOffset) {
        _fetchResult();
      }
    });
  }

  callRefresh() {
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

  _fetchResult({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    return await GrainApi.listSubscribdGrainList(
      offset: refresh ? 0 : _subscribeList.length,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
        } else {
          List<SubscribeGrainItem> tmp = [];
          if (value['data'] != null) {
            if (value['data']['total'] != null) {
              _total = value['data']['grainCount'];
            }
            if (value['data']['grains'] != null) {
              tmp = (value['data']['grains'] as List)
                  .map((e) => SubscribeGrainItem.fromJson(e))
                  .toList();
              if (refresh) _subscribeList.clear();
              for (var exist in _subscribeList) {
                tmp.removeWhere(
                    (element) => element.grain.id == exist.grain.id);
              }
              _subscribeList.addAll(tmp);
            }
          }
          if (mounted) setState(() {});
          if ((tmp.isEmpty || _subscribeList.length >= _total) && !refresh) {
            _noMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (_) {
        IToast.showTop("加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh.builder(
      refreshOnStart: true,
      controller: _refreshController,
      onRefresh: () async {
        return await _fetchResult(refresh: true);
      },
      onLoad: () async {
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
                    child: ItemBuilder.buildEmptyPlaceholder(
                      context: context,
                      text: "暂无订阅的粮单",
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
    return SliverWaterfallFlow.extent(
      maxCrossAxisExtent: 560,
      children: List.generate(_subscribeList.length, (index) {
        return ItemBuilder.buildClickItem(_buildSubscribeGrainItem(_subscribeList[index]));
      }),
    );
  }

  _buildSubscribeGrainItem(SubscribeGrainItem item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushCupertinoRoute(
          context,
          GrainDetailScreen(
            grainId: item.grain.id,
            blogId: item.blogInfo.blogId,
          ),
        );
      },
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.transparent,
        child: Row(
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
                child: ItemBuilder.buildCachedImage(
                  imageUrl: item.grain.coverUrl,
                  context: context,
                  width: 80,
                  height: 80,
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
                  Text(
                    Utils.isNotEmpty(item.latestPost.title)
                        ? item.latestPost.title
                        : item.latestPost.digest,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
