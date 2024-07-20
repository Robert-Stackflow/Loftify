import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/message_api.dart';
import 'package:loftify/Models/message_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/route_util.dart';

import '../../Utils/constant.dart';
import '../../Utils/itoast.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Custom/custom_tab_indicator.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';

class SystemNoticeScreen extends StatefulWidget {
  const SystemNoticeScreen({super.key});

  static const String routeName = "/info/message/system";

  @override
  State<SystemNoticeScreen> createState() => _SystemNoticeScreenState();
}

class _SystemNoticeScreenState extends State<SystemNoticeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<MessageItem> _allMessages = [];
  final List<MessageItem> _likeMessages = [];
  final List<MessageItem> _recommendMessages = [];
  final List<MessageItem> _giftMessages = [];
  final List<MessageItem> _atMessages = [];
  final List<MessageItem> _subscribeMessages = [];
  final List<MessageItem> _collectionMessages = [];
  final List<MessageItem> _otherMessages = [];
  bool _loading = false;
  final EasyRefreshController _allRefreshController = EasyRefreshController();
  final EasyRefreshController _likeRefreshController = EasyRefreshController();
  final EasyRefreshController _recommendRefreshController =
      EasyRefreshController();
  final EasyRefreshController _giftRefreshController = EasyRefreshController();
  final EasyRefreshController _atRefreshController = EasyRefreshController();
  final EasyRefreshController _subscribeRefreshController =
      EasyRefreshController();
  final EasyRefreshController _collectionRefreshController =
      EasyRefreshController();
  final EasyRefreshController _otherRefreshController = EasyRefreshController();
  final ScrollController _allScrollController = ScrollController();
  final ScrollController _likeScrollController = ScrollController();
  final ScrollController _recommendScrollController = ScrollController();
  final ScrollController _giftScrollController = ScrollController();
  final ScrollController _atScrollController = ScrollController();
  final ScrollController _subscribeScrollController = ScrollController();
  final ScrollController _collectionScrollController = ScrollController();
  final ScrollController _otherScrollController = ScrollController();
  bool _allNoMore = false;
  bool _likeNoMore = false;
  bool _recommendNoMore = false;
  bool _giftNoMore = false;
  bool _atNoMore = false;
  bool _subscribeNoMore = false;
  bool _collectionNoMore = false;
  bool _otherNoMore = false;
  final List<String> _tabLabelList = [
    "全部",
    "喜欢",
    "推荐",
    "礼物",
    "@我",
    "订阅",
    "收藏",
    "其他"
  ];
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
    initScrollController();
    initTab();
  }

  initScrollController() {
    _allScrollController.addListener(() {
      if (!_allNoMore &&
          _allScrollController.position.pixels >
              _allScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchSystemNotices(MessageType.all, _allMessages,
            resetNoMore: () => _allNoMore = false,
            onNoMore: () => _allNoMore = true);
      }
    });
    _likeScrollController.addListener(() {
      if (!_likeNoMore &&
          _likeScrollController.position.pixels >
              _likeScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchLikeMessages();
      }
    });
    _recommendScrollController.addListener(() {
      if (!_recommendNoMore &&
          _recommendScrollController.position.pixels >
              _recommendScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchSystemNotices(MessageType.recommend, _recommendMessages,
            resetNoMore: () => _recommendNoMore = false,
            onNoMore: () => _recommendNoMore = true);
      }
    });
    _giftScrollController.addListener(() {
      if (!_giftNoMore &&
          _giftScrollController.position.pixels >
              _giftScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchSystemNotices(MessageType.gift, _giftMessages,
            resetNoMore: () => _giftNoMore = false,
            onNoMore: () => _giftNoMore = true);
      }
    });
    _atScrollController.addListener(() {
      if (!_atNoMore &&
          _atScrollController.position.pixels >
              _atScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchSystemNotices(MessageType.at, _atMessages,
            resetNoMore: () => _atNoMore = false,
            onNoMore: () => _atNoMore = true);
      }
    });
    _subscribeScrollController.addListener(() {
      if (!_subscribeNoMore &&
          _subscribeScrollController.position.pixels >
              _subscribeScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchSystemNotices(MessageType.subscribe, _subscribeMessages,
            resetNoMore: () => _subscribeNoMore = false,
            onNoMore: () => _subscribeNoMore = true);
      }
    });
    _collectionScrollController.addListener(() {
      if (!_collectionNoMore &&
          _collectionScrollController.position.pixels >
              _collectionScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchSystemNotices(MessageType.collection, _collectionMessages,
            resetNoMore: () => _collectionNoMore = false,
            onNoMore: () => _collectionNoMore = true);
      }
    });
    _otherScrollController.addListener(() {
      if (!_otherNoMore &&
          _otherScrollController.position.pixels >
              _otherScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchSystemNotices(MessageType.other, _otherMessages,
            resetNoMore: () => _otherNoMore = false,
            onNoMore: () => _otherNoMore = true);
      }
    });
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

  _fetchLikeMessages({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _likeNoMore = false;
    _loading = true;
    int offset = refresh ? 0 : _likeMessages.length;
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      return await MessageApi.getLikeMessages(
              blogId: blogInfo!.blogId, offset: offset)
          .then((value) {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            return IndicatorResult.fail;
          } else {
            List<MessageItem> t = [];
            t = (value['response'] as List)
                .map((e) => MessageItem.fromJson(e))
                .toList();
            if (refresh) _likeMessages.clear();
            _likeMessages.addAll(t);
            if (mounted) setState(() {});
            if (t.isEmpty && !refresh) {
              _likeNoMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e) {
          if (mounted) IToast.showTop("加载失败");
          return IndicatorResult.fail;
        } finally {
          if (mounted) setState(() {});
          _loading = false;
        }
      });
    });
  }

  _fetchSystemNotices(
    MessageType type,
    List list, {
    bool refresh = false,
    Function()? resetNoMore,
    Function()? onNoMore,
  }) async {
    if (_loading) return;
    if (refresh) resetNoMore?.call();
    _loading = true;
    int offset = refresh ? 0 : _allMessages.length;
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      return await MessageApi.getSystemNoticeList(
        blogId: blogInfo!.blogId,
        type: type,
        offset: offset,
      ).then((value) {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            return IndicatorResult.fail;
          } else {
            List<MessageItem> t = [];
            t = (value['response'] as List)
                .map((e) => MessageItem.fromJson(e))
                .toList();
            if (refresh) list.clear();
            list.addAll(t);
            if (mounted) setState(() {});
            if (t.isEmpty && !refresh) {
              onNoMore?.call();
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e) {
          if (mounted) IToast.showTop("加载失败");
          return IndicatorResult.fail;
        } finally {
          if (mounted) setState(() {});
          _loading = false;
        }
      });
    });
  }

  Widget _buildTabView() {
    List<Widget> children = [];
    children.add(_buildAllTab());
    children.add(_buildLikeTab());
    children.add(_buildRecommendTab());
    children.add(_buildGiftTab());
    children.add(_buildAtTab());
    children.add(_buildSubscribeTab());
    children.add(_buildCollectionTab());
    children.add(_buildOtherTab());
    return TabBarView(
      controller: _tabController,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MyTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: _buildTabView(),
    );
  }

  _buildAllTab() {
    return EasyRefresh(
      controller: _allRefreshController,
      onRefresh: () async {
        return await _fetchSystemNotices(
          MessageType.all,
          _allMessages,
          refresh: true,
          resetNoMore: () => _allNoMore = false,
          onNoMore: () => _allNoMore = true,
        );
      },
      refreshOnStart: true,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.all,
          _allMessages,
          resetNoMore: () => _allNoMore = false,
          onNoMore: () => _allNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: ListView.builder(
        controller: _allScrollController,
        padding: const EdgeInsets.only(top: 10),
        itemBuilder: (context, index) => _buildItem(_allMessages[index]),
        itemCount: _allMessages.length,
      ),
    );
  }

  _buildLikeTab() {
    return EasyRefresh(
      controller: _likeRefreshController,
      onRefresh: () async {
        return await _fetchLikeMessages(refresh: true);
      },
      refreshOnStart: true,
      onLoad: () async {
        return await _fetchLikeMessages();
      },
      triggerAxis: Axis.vertical,
      child: ListView.builder(
        controller: _likeScrollController,
        padding: const EdgeInsets.only(top: 10),
        itemBuilder: (context, index) => _buildItem(_likeMessages[index]),
        itemCount: _likeMessages.length,
      ),
    );
  }

  _buildRecommendTab() {
    return EasyRefresh(
      controller: _recommendRefreshController,
      onRefresh: () async {
        return await _fetchSystemNotices(
          MessageType.recommend,
          _recommendMessages,
          refresh: true,
          resetNoMore: () => _recommendNoMore = false,
          onNoMore: () => _recommendNoMore = true,
        );
      },
      refreshOnStart: true,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.recommend,
          _recommendMessages,
          resetNoMore: () => _recommendNoMore = false,
          onNoMore: () => _recommendNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: ListView.builder(
        controller: _recommendScrollController,
        padding: const EdgeInsets.only(top: 10),
        itemBuilder: (context, index) => _buildItem(_recommendMessages[index]),
        itemCount: _recommendMessages.length,
      ),
    );
  }

  _buildGiftTab() {
    return EasyRefresh(
      controller: _giftRefreshController,
      onRefresh: () async {
        return await _fetchSystemNotices(
          MessageType.gift,
          _giftMessages,
          refresh: true,
          resetNoMore: () => _giftNoMore = false,
          onNoMore: () => _giftNoMore = true,
        );
      },
      refreshOnStart: true,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.gift,
          _giftMessages,
          resetNoMore: () => _giftNoMore = false,
          onNoMore: () => _giftNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: ListView.builder(
        controller: _giftScrollController,
        padding: const EdgeInsets.only(top: 10),
        itemBuilder: (context, index) => _buildItem(_giftMessages[index]),
        itemCount: _giftMessages.length,
      ),
    );
  }

  _buildAtTab() {
    return EasyRefresh(
      controller: _atRefreshController,
      onRefresh: () async {
        return await _fetchSystemNotices(
          MessageType.at,
          _atMessages,
          refresh: true,
          resetNoMore: () => _atNoMore = false,
          onNoMore: () => _atNoMore = true,
        );
      },
      refreshOnStart: true,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.at,
          _atMessages,
          resetNoMore: () => _atNoMore = false,
          onNoMore: () => _atNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: ListView.builder(
        controller: _atScrollController,
        padding: const EdgeInsets.only(top: 10),
        itemBuilder: (context, index) => _buildItem(_atMessages[index]),
        itemCount: _atMessages.length,
      ),
    );
  }

  _buildSubscribeTab() {
    return EasyRefresh(
      controller: _subscribeRefreshController,
      onRefresh: () async {
        return await _fetchSystemNotices(
          MessageType.subscribe,
          _subscribeMessages,
          refresh: true,
          resetNoMore: () => _subscribeNoMore = false,
          onNoMore: () => _subscribeNoMore = true,
        );
      },
      refreshOnStart: true,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.subscribe,
          _subscribeMessages,
          resetNoMore: () => _subscribeNoMore = false,
          onNoMore: () => _subscribeNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: ListView.builder(
        controller: _subscribeScrollController,
        padding: const EdgeInsets.only(top: 10),
        itemBuilder: (context, index) => _buildItem(_subscribeMessages[index]),
        itemCount: _subscribeMessages.length,
      ),
    );
  }

  _buildCollectionTab() {
    return EasyRefresh(
      controller: _collectionRefreshController,
      onRefresh: () async {
        return await _fetchSystemNotices(
          MessageType.collection,
          _collectionMessages,
          refresh: true,
          resetNoMore: () => _collectionNoMore = false,
          onNoMore: () => _collectionNoMore = true,
        );
      },
      refreshOnStart: true,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.collection,
          _collectionMessages,
          resetNoMore: () => _collectionNoMore = false,
          onNoMore: () => _collectionNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: ListView.builder(
        controller: _collectionScrollController,
        padding: const EdgeInsets.only(top: 10),
        itemBuilder: (context, index) => _buildItem(_collectionMessages[index]),
        itemCount: _collectionMessages.length,
      ),
    );
  }

  _buildOtherTab() {
    return EasyRefresh(
      controller: _otherRefreshController,
      onRefresh: () async {
        return await _fetchSystemNotices(
          MessageType.other,
          _otherMessages,
          refresh: true,
          resetNoMore: () => _otherNoMore = false,
          onNoMore: () => _otherNoMore = true,
        );
      },
      refreshOnStart: true,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.other,
          _otherMessages,
          resetNoMore: () => _otherNoMore = false,
          onNoMore: () => _otherNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: ListView.builder(
        controller: _otherScrollController,
        padding: const EdgeInsets.only(top: 10),
        itemBuilder: (context, index) => _buildItem(_otherMessages[index]),
        itemCount: _otherMessages.length,
      ),
    );
  }

  _buildItem(MessageItem item) {
    return ItemBuilder.buildClickItem(
      GestureDetector(
        onTap: () {
          RouteUtil.pushCupertinoRoute(
            context,
            PostDetailScreen(
              simpleMessagePost: item.simplePost,
              isArticle: item.type == 1,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 10),
              GestureDetector(
                child: ItemBuilder.buildAvatar(
                  context: context,
                  size: 50,
                  imageUrl: item.actUserBlogInfo.bigAvaImg,
                ),
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                    context,
                    UserDetailScreen(
                      blogId: item.actUserId,
                      blogName: item.actUserBlogInfo.blogName,
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: item.actUserBlogInfo.blogNickName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.apply(
                                          fontSizeDelta: 1,
                                        ),
                                  ),
                                  TextSpan(
                                    text: item.defString.replaceFirst(
                                        item.actUserBlogInfo.blogNickName, ""),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.apply(
                                          fontSizeDelta: 1,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              Utils.formatTimestamp(item.publishTime),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.apply(
                                    fontSizeDelta: 1,
                                  ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ItemBuilder.buildCachedImage(
                          imageUrl: item.thumbnail,
                          context: context,
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                          showLoading: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      leading: Icons.arrow_back_rounded,
      backgroundColor: MyTheme.getBackground(context),
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: TabBar(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        controller: _tabController,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: _tabLabelList
            .asMap()
            .entries
            .map(
              (entry) => ItemBuilder.buildAnimatedTab(context,
                  selected: entry.key == _currentTabIndex,
                  text: entry.value,
                  normalUserBold: true,
                  sameFontSize: true),
            )
            .toList(),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.only(right: 16),
        enableFeedback: true,
        dividerHeight: 0,
        physics: const BouncingScrollPhysics(),
        labelStyle: Theme.of(context).textTheme.titleLarge,
        unselectedLabelStyle:
            Theme.of(context).textTheme.titleLarge?.apply(color: Colors.grey),
        indicator:
            CustomTabIndicator(borderColor: Theme.of(context).primaryColor),
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}
