import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/message_api.dart';
import 'package:loftify/Models/message_response.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Utils/tab_state_util.dart';
import '../../Widgets/Design/loftify_state_view.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../l10n/l10n.dart';

/// Full-viewport placeholder used by every notification tab.
///
/// Keeping this scrollable even when empty preserves pull-to-refresh while the
/// content is loading or when the server returns no messages.
class SystemNoticeTabPlaceholder extends StatelessWidget {
  const SystemNoticeTabPlaceholder({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return EmptyPlaceholder(
      text: text,
      physics: const AlwaysScrollableScrollPhysics(),
      shrinkWrap: false,
      topPadding: 0,
    );
  }
}

class SystemNoticeMessageTile extends StatelessWidget {
  const SystemNoticeMessageTile({
    super.key,
    required this.nickname,
    required this.message,
    required this.timestamp,
    required this.avatarUrl,
    required this.thumbnailUrl,
    required this.onTap,
    required this.onAvatarTap,
  });

  final String nickname;
  final String message;
  final int timestamp;
  final String avatarUrl;
  final String thumbnailUrl;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360 || textScale > 1.35;
        final avatarSize = compact ? 44.0 : 50.0;
        final avatarTapSize = compact ? 48.0 : 50.0;
        final messageText = Text.rich(
          key: const Key('system-notice-message'),
          TextSpan(
            children: [
              TextSpan(
                text: nickname,
                style: Theme.of(context).textTheme.titleSmall?.apply(
                      fontSizeDelta: 1,
                    ),
              ),
              TextSpan(
                text: message.replaceFirst(nickname, ''),
                style: Theme.of(context).textTheme.titleSmall?.apply(
                      fontSizeDelta: 1,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
            ],
          ),
        );
        final timeText = Text(
          TimeUtil.formatTimestamp(timestamp),
          style: Theme.of(context).textTheme.labelMedium?.apply(
                fontSizeDelta: 1,
              ),
        );
        final thumbnail = ClipRRect(
          key: const Key('system-notice-thumbnail'),
          borderRadius: BorderRadius.circular(8),
          child: ChewieItemBuilder.buildCachedImage(
            imageUrl: thumbnailUrl,
            context: context,
            height: 50,
            width: 50,
            fit: BoxFit.cover,
            showLoading: false,
          ),
        );
        final content = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  messageText,
                  const SizedBox(height: 8),
                  timeText,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: thumbnail),
                  const SizedBox(height: 10),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        messageText,
                        const SizedBox(height: 10),
                        timeText,
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  thumbnail,
                ],
              );
        return ClickableGestureDetector(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 15,
              compact ? 8 : 5,
              compact ? 12 : 15,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  key: const Key('system-notice-avatar-action'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onAvatarTap,
                  child: Semantics(
                    button: true,
                    label: nickname,
                    child: SizedBox(
                      width: avatarTapSize,
                      height: avatarTapSize,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ExcludeSemantics(
                          child: ItemBuilder.buildAvatar(
                            context: context,
                            size: avatarSize,
                            imageUrl: avatarUrl,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 4 : 10),
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
                    child: content,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SystemNoticeScreen extends StatefulWidget {
  const SystemNoticeScreen({super.key});

  static const String routeName = "/info/message/system";

  @override
  State<SystemNoticeScreen> createState() => _SystemNoticeScreenState();
}

class _SystemNoticeScreenState extends BaseDynamicState<SystemNoticeScreen>
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
  final Set<String> _loadingTabs = <String>{};
  final Set<String> _completedTabs = <String>{};
  final Set<String> _failedTabs = <String>{};

  IndicatorResult _noticeFailure(String key) {
    _failedTabs.add(key);
    return IndicatorResult.fail;
  }

  Widget _buildPlaceholder(int index) {
    final key = _tabIdList[index];
    final loading = _loadingTabs.contains(key) || !_completedTabs.contains(key);
    if (!loading && !_failedTabs.contains(key)) {
      return SystemNoticeTabPlaceholder(text: appLocalizations.noNotice);
    }
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: LoftifyStateView(
            visual:
                loading ? LoftifyStateVisual.loading : LoftifyStateVisual.error,
            title: loading
                ? appLocalizations.loading
                : appLocalizations.loadFailed,
            scrollWhenConstrained: false,
            actionLabel: loading ? null : chewieLocalizations.retry,
            onAction:
                loading ? null : () => _refreshControllers[index].callRefresh(),
          ),
        ),
      ],
    );
  }

  // A refresh supersedes in-flight pagination; only its own request may update
  // the list or release the tab's loading lock.
  final Map<String, int> _requestVersions = <String, int>{};

  bool _isCurrentRequest(String key, int version) =>
      mounted && _requestVersions[key] == version;
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
  bool _allNoMore = false;
  bool _likeNoMore = false;
  bool _recommendNoMore = false;
  bool _giftNoMore = false;
  bool _atNoMore = false;
  bool _subscribeNoMore = false;
  bool _collectionNoMore = false;
  bool _otherNoMore = false;
  List<String> get _tabLabelList {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.all,
      localizations.like,
      localizations.recommend,
      localizations.gift,
      localizations.atMe,
      localizations.subscribe,
      localizations.favorite,
      localizations.other,
    ];
  }

  late TabController _tabController;
  late final LazyTabLoadState _tabLoadState;
  int _currentTabIndex = 0;
  static const List<String> _tabIdList = [
    'all',
    'like',
    'recommend',
    'gift',
    'at',
    'subscribe',
    'collection',
    'other',
  ];

  List<EasyRefreshController> get _refreshControllers => [
        _allRefreshController,
        _likeRefreshController,
        _recommendRefreshController,
        _giftRefreshController,
        _atRefreshController,
        _subscribeRefreshController,
        _collectionRefreshController,
        _otherRefreshController,
      ];

  @override
  void initState() {
    super.initState();
    initTab();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureTabLoaded(_currentTabIndex);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _refreshControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void initTab() {
    final restored = PersistentTabState.restore(
      idKey: HiveUtil.systemNoticeTabIdKey,
      legacyIndexKey: HiveUtil.systemNoticeTabIndexKey,
      itemIds: _tabIdList,
    );
    _tabLoadState = LazyTabLoadState(
      itemIds: _tabIdList,
      savedId: restored.id,
    );
    _currentTabIndex = _tabLoadState.currentIndex;
    _tabController = TabController(
      length: _tabIdList.length,
      initialIndex: _currentTabIndex,
      vsync: this,
    );
    _tabController.addListener(() {
      final index =
          (_tabController.animation?.value ?? _tabController.index).round();
      if (index != _currentTabIndex) _setCurrentTab(index);
    });
  }

  void _setCurrentTab(int index) {
    final safeIndex = TabStatePreference.restoreIndex(index, _tabIdList.length);
    if (safeIndex != _currentTabIndex && mounted) {
      setState(() => _currentTabIndex = safeIndex);
    }
    PersistentTabState.save(
      idKey: HiveUtil.systemNoticeTabIdKey,
      legacyIndexKey: HiveUtil.systemNoticeTabIndexKey,
      itemIds: _tabIdList,
      index: safeIndex,
    );
    _ensureTabLoaded(safeIndex);
  }

  void _ensureTabLoaded(int index) {
    if (!_tabLoadState.selectAndShouldLoad(index)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _refreshControllers.length) return;
      _refreshControllers[index].callRefresh();
    });
  }

  Future<IndicatorResult> _fetchLikeMessages({bool refresh = false}) async {
    const loadingKey = 'like';
    if (!refresh && _loadingTabs.contains(loadingKey)) {
      return IndicatorResult.none;
    }
    _loadingTabs.add(loadingKey);
    _failedTabs.remove(loadingKey);
    if (mounted) setState(() {});
    final version = (_requestVersions[loadingKey] ?? 0) + 1;
    _requestVersions[loadingKey] = version;
    if (refresh) _likeNoMore = false;
    int offset = refresh ? 0 : _likeMessages.length;
    try {
      final blogInfo = await HiveUtil.getUserInfo();
      if (!_isCurrentRequest(loadingKey, version)) return IndicatorResult.none;
      if (blogInfo == null) return _noticeFailure(loadingKey);
      final value = await MessageApi.getLikeMessages(
          blogId: blogInfo.blogId, offset: offset);
      if (!_isCurrentRequest(loadingKey, version)) return IndicatorResult.none;
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return _noticeFailure(loadingKey);
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
    } catch (e, t) {
      if (!_isCurrentRequest(loadingKey, version)) return IndicatorResult.none;
      ILogger.error("Failed to load system notice list", e, t);
      if (mounted) IToast.showTop(appLocalizations.loadFailed);
      return _noticeFailure(loadingKey);
    } finally {
      if (_requestVersions[loadingKey] == version) {
        _loadingTabs.remove(loadingKey);
        _completedTabs.add(loadingKey);
        if (mounted) setState(() {});
      }
    }
  }

  Future<IndicatorResult> _fetchSystemNotices(
    MessageType type,
    List<MessageItem> list, {
    bool refresh = false,
    Function()? resetNoMore,
    Function()? onNoMore,
  }) async {
    final loadingKey = type.name;
    if (!refresh && _loadingTabs.contains(loadingKey)) {
      return IndicatorResult.none;
    }
    _loadingTabs.add(loadingKey);
    _failedTabs.remove(loadingKey);
    if (mounted) setState(() {});
    final version = (_requestVersions[loadingKey] ?? 0) + 1;
    _requestVersions[loadingKey] = version;
    if (refresh) resetNoMore?.call();
    int offset = refresh ? 0 : list.length;
    try {
      final blogInfo = await HiveUtil.getUserInfo();
      if (!_isCurrentRequest(loadingKey, version)) return IndicatorResult.none;
      if (blogInfo == null) return _noticeFailure(loadingKey);
      final value = await MessageApi.getSystemNoticeList(
        blogId: blogInfo.blogId,
        type: type,
        offset: offset,
      );
      if (!_isCurrentRequest(loadingKey, version)) return IndicatorResult.none;
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return _noticeFailure(loadingKey);
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
    } catch (e, t) {
      if (!_isCurrentRequest(loadingKey, version)) return IndicatorResult.none;
      ILogger.error("Failed to load system notice list", e, t);
      if (mounted) IToast.showTop(appLocalizations.loadFailed);
      return _noticeFailure(loadingKey);
    } finally {
      if (_requestVersions[loadingKey] == version) {
        _loadingTabs.remove(loadingKey);
        _completedTabs.add(loadingKey);
        if (mounted) setState(() {});
      }
    }
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
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: _buildTabView(),
    );
  }

  Widget _buildAllTab() {
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
      refreshOnStart: false,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.all,
          _allMessages,
          resetNoMore: () => _allNoMore = false,
          onNoMore: () => _allNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: _allMessages.isEmpty
          ? _buildPlaceholder(0)
          : LoadMoreNotification(
              noMore: _allNoMore,
              onLoad: () {
                _fetchSystemNotices(MessageType.all, _allMessages,
                    resetNoMore: () => _allNoMore = false,
                    onNoMore: () => _allNoMore = true);
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemBuilder: (context, index) =>
                    _buildItem(_allMessages[index]),
                itemCount: _allMessages.length,
              ),
            ),
    );
  }

  Widget _buildLikeTab() {
    return EasyRefresh(
      controller: _likeRefreshController,
      onRefresh: () async {
        return await _fetchLikeMessages(refresh: true);
      },
      refreshOnStart: false,
      onLoad: () async {
        return await _fetchLikeMessages();
      },
      triggerAxis: Axis.vertical,
      child: _likeMessages.isEmpty
          ? _buildPlaceholder(1)
          : LoadMoreNotification(
              noMore: _likeNoMore,
              onLoad: () {
                _fetchLikeMessages();
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemBuilder: (context, index) =>
                    _buildItem(_likeMessages[index]),
                itemCount: _likeMessages.length,
              ),
            ),
    );
  }

  Widget _buildRecommendTab() {
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
      refreshOnStart: false,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.recommend,
          _recommendMessages,
          resetNoMore: () => _recommendNoMore = false,
          onNoMore: () => _recommendNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: _recommendMessages.isEmpty
          ? _buildPlaceholder(2)
          : LoadMoreNotification(
              noMore: _recommendNoMore,
              onLoad: () {
                _fetchSystemNotices(MessageType.recommend, _recommendMessages,
                    resetNoMore: () => _recommendNoMore = false,
                    onNoMore: () => _recommendNoMore = true);
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemBuilder: (context, index) =>
                    _buildItem(_recommendMessages[index]),
                itemCount: _recommendMessages.length,
              ),
            ),
    );
  }

  Widget _buildGiftTab() {
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
      refreshOnStart: false,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.gift,
          _giftMessages,
          resetNoMore: () => _giftNoMore = false,
          onNoMore: () => _giftNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: _giftMessages.isEmpty
          ? _buildPlaceholder(3)
          : LoadMoreNotification(
              noMore: _giftNoMore,
              onLoad: () {
                _fetchSystemNotices(MessageType.gift, _giftMessages,
                    resetNoMore: () => _giftNoMore = false,
                    onNoMore: () => _giftNoMore = true);
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemBuilder: (context, index) =>
                    _buildItem(_giftMessages[index]),
                itemCount: _giftMessages.length,
              ),
            ),
    );
  }

  Widget _buildAtTab() {
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
      refreshOnStart: false,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.at,
          _atMessages,
          resetNoMore: () => _atNoMore = false,
          onNoMore: () => _atNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: _atMessages.isEmpty
          ? _buildPlaceholder(4)
          : LoadMoreNotification(
              noMore: _atNoMore,
              onLoad: () {
                _fetchSystemNotices(MessageType.at, _atMessages,
                    resetNoMore: () => _atNoMore = false,
                    onNoMore: () => _atNoMore = true);
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemBuilder: (context, index) => _buildItem(_atMessages[index]),
                itemCount: _atMessages.length,
              ),
            ),
    );
  }

  Widget _buildSubscribeTab() {
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
      refreshOnStart: false,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.subscribe,
          _subscribeMessages,
          resetNoMore: () => _subscribeNoMore = false,
          onNoMore: () => _subscribeNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: _subscribeMessages.isEmpty
          ? _buildPlaceholder(5)
          : LoadMoreNotification(
              noMore: _subscribeNoMore,
              onLoad: () {
                _fetchSystemNotices(MessageType.subscribe, _subscribeMessages,
                    resetNoMore: () => _subscribeNoMore = false,
                    onNoMore: () => _subscribeNoMore = true);
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemBuilder: (context, index) =>
                    _buildItem(_subscribeMessages[index]),
                itemCount: _subscribeMessages.length,
              ),
            ),
    );
  }

  Widget _buildCollectionTab() {
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
      refreshOnStart: false,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.collection,
          _collectionMessages,
          resetNoMore: () => _collectionNoMore = false,
          onNoMore: () => _collectionNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: _collectionMessages.isEmpty
          ? _buildPlaceholder(6)
          : LoadMoreNotification(
              noMore: _collectionNoMore,
              onLoad: () {
                _fetchSystemNotices(MessageType.collection, _collectionMessages,
                    resetNoMore: () => _collectionNoMore = false,
                    onNoMore: () => _collectionNoMore = true);
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemBuilder: (context, index) =>
                    _buildItem(_collectionMessages[index]),
                itemCount: _collectionMessages.length,
              ),
            ),
    );
  }

  Widget _buildOtherTab() {
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
      refreshOnStart: false,
      onLoad: () async {
        return await _fetchSystemNotices(
          MessageType.other,
          _otherMessages,
          resetNoMore: () => _otherNoMore = false,
          onNoMore: () => _otherNoMore = true,
        );
      },
      triggerAxis: Axis.vertical,
      child: _otherMessages.isEmpty
          ? _buildPlaceholder(7)
          : LoadMoreNotification(
              noMore: _otherNoMore,
              onLoad: () {
                _fetchSystemNotices(MessageType.other, _otherMessages,
                    resetNoMore: () => _otherNoMore = false,
                    onNoMore: () => _otherNoMore = true);
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemBuilder: (context, index) =>
                    _buildItem(_otherMessages[index]),
                itemCount: _otherMessages.length,
              ),
            ),
    );
  }

  Widget _buildItem(MessageItem item) {
    return SystemNoticeMessageTile(
      nickname: item.actUserBlogInfo.blogNickName,
      message: item.defString,
      timestamp: item.publishTime,
      avatarUrl: item.actUserBlogInfo.bigAvaImg,
      thumbnailUrl: item.thumbnail,
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          PostDetailScreen(
            simpleMessagePost: item.simplePost,
            isArticle: item.type == 1,
          ),
        );
      },
      onAvatarTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          UserDetailScreen(
            blogId: item.actUserId,
            blogName: item.actUserBlogInfo.blogName,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.notice,
      bottomHeight: 56,
      bottomWidget: TabBarWrapper(
        tabController: _tabController,
        tabs: _tabLabelList
            .asMap()
            .entries
            .map(
              (entry) => ItemBuilder.buildAnimatedTab(context,
                  selected: entry.key == _currentTabIndex,
                  text: entry.value,
                  controller: _tabController,
                  tabIndex: entry.key,
                  normalUserBold: true,
                  sameFontSize: true),
            )
            .toList(),
        onTap: (index) {
          _setCurrentTab(index);
        },
        width: MediaQuery.sizeOf(context).width,
        background: ChewieTheme.getBackground(context),
        showBorder: ResponsiveUtil.isLandscapeLayout(),
      ),
    );
  }
}
