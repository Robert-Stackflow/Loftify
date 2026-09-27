import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/user_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Widgets/Design/loftify_state_view.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../l10n/l10n.dart';

class FollowingFollowerScreen extends StatefulWidget {
  FollowingFollowerScreen({
    super.key,
    this.blogId,
    this.blogName,
    this.infoMode = InfoMode.me,
    this.followingMode = FollowingMode.following,
    required this.total,
  }) {
    if (infoMode == InfoMode.other) {
      assert(blogName != null);
    }
  }

  final FollowingMode followingMode;
  final InfoMode infoMode;
  final int? blogId;
  final int total;
  final String? blogName;

  static const String routeName = "/info/followingOrFollower";

  @override
  State<FollowingFollowerScreen> createState() =>
      _FollowingFollowerScreenState();
}

class _FollowingFollowerScreenState
    extends BaseDynamicState<FollowingFollowerScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<FollowingUserItem> _followingList = [];
  bool _loading = false;
  bool _loadingRefresh = false;
  String? _loadingToken;
  String? _dataToken;
  int _requestEpoch = 0;
  int _nextOffset = 0;
  int total = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  InitPhase _initPhase = InitPhase.connecting;

  @override
  void initState() {
    total = widget.total;
    super.initState();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<IndicatorResult> _fetchList({bool refresh = false}) async {
    if (!mounted) return IndicatorResult.none;
    final token = appProvider.token;
    if (_loading && _loadingToken == token && (!refresh || _loadingRefresh)) {
      return IndicatorResult.none;
    }
    if (_dataToken != null && _dataToken != token) {
      _followingList.clear();
      _nextOffset = 0;
      _noMore = false;
      _initPhase = InitPhase.connecting;
    }
    final epoch = ++_requestEpoch;
    bool isCurrentRequest() =>
        mounted && appProvider.token == token && epoch == _requestEpoch;
    _loading = true;
    _loadingRefresh = refresh;
    _loadingToken = token;
    final offset = refresh ? 0 : _nextOffset;
    if (_followingList.isEmpty) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    try {
      final blogInfo = widget.infoMode == InfoMode.me && widget.blogName == null
          ? await HiveUtil.getUserInfo()
          : null;
      if (!isCurrentRequest()) return IndicatorResult.none;
      final blogName = widget.blogName ?? blogInfo?.blogName;
      if (blogName == null || blogName.isEmpty) {
        if (_followingList.isEmpty) _initPhase = InitPhase.failed;
        return IndicatorResult.fail;
      }
      final value = widget.followingMode == FollowingMode.timeline
          ? await UserApi.getFollowingTimeline(
              blogName: blogName,
              offset: offset,
            )
          : await UserApi.getFollowingList(
              blogName: blogName,
              offset: offset,
              followingMode: widget.followingMode,
            );
      if (!isCurrentRequest()) return IndicatorResult.none;
      if (value['meta']['status'] != 200) {
        if (_followingList.isEmpty) _initPhase = InitPhase.failed;
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return IndicatorResult.fail;
      }
      final rawItems = value['response'] as List;
      final page = rawItems
          .whereType<Map>()
          .map((item) =>
              FollowingUserItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      final users = refresh ? <FollowingUserItem>[] : [..._followingList];
      final seen = users.map((user) => user.blogInfo.blogId).toSet();
      for (final user in page) {
        if (seen.add(user.blogInfo.blogId)) users.add(user);
      }
      _followingList
        ..clear()
        ..addAll(users);
      _nextOffset = offset + rawItems.length;
      _noMore = rawItems.isEmpty || (total > 0 && _nextOffset >= total);
      _initPhase = InitPhase.successful;
      _dataToken = token;
      return !refresh && _noMore
          ? IndicatorResult.noMore
          : IndicatorResult.success;
    } catch (error, stackTrace) {
      if (!isCurrentRequest()) return IndicatorResult.none;
      if (_followingList.isEmpty) _initPhase = InitPhase.failed;
      ILogger.error('Failed to load following or follower', error, stackTrace);
      IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      if (epoch == _requestEpoch && mounted) {
        setState(() {
          if (appProvider.token != token) {
            _followingList.clear();
            _nextOffset = 0;
            _noMore = false;
            _initPhase = InitPhase.failed;
            _dataToken = null;
          }
        });
      }
      if (epoch == _requestEpoch) {
        _loading = false;
        _loadingRefresh = false;
        _loadingToken = null;
      }
    }
  }

  Future<IndicatorResult> _onRefresh() async {
    return await _fetchList(refresh: true);
  }

  Future<IndicatorResult> _onLoad() async {
    return await _fetchList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: EasyRefresh.builder(
        refreshOnStart: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoad: _noMore ? null : _onLoad,
        triggerAxis: Axis.vertical,
        childBuilder: (context, physics) {
          return _buildBody(physics);
        },
      ),
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    if (_initPhase != InitPhase.successful) {
      final loading = _initPhase == InitPhase.connecting;
      return CustomScrollView(
        physics: physics,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: LoftifyStateView(
              visual: loading
                  ? LoftifyStateVisual.loading
                  : LoftifyStateVisual.error,
              title: loading
                  ? appLocalizations.loading
                  : appLocalizations.loadFailed,
              scrollWhenConstrained: false,
              actionLabel: loading ? null : chewieLocalizations.retry,
              onAction: loading ? null : () => _refreshController.callRefresh(),
            ),
          ),
        ],
      );
    }
    if (_followingList.isEmpty) {
      return EmptyPlaceholder(
        text: appLocalizations.noUser,
        physics: physics,
        shrinkWrap: false,
      );
    }
    return WaterfallFlow.builder(
      physics: physics,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 560,
        mainAxisSpacing: 0,
        crossAxisSpacing: 8,
      ),
      itemCount: _followingList.length,
      itemBuilder: (context, index) {
        final user = _followingList[index];
        return LoftifyItemBuilder.buildFollowerOrFollowingItem(
            context, index, user, onFollowOrUnFollow: () {
          if (!mounted || !_followingList.contains(user)) return;
          total = (total + (user.following ? 1 : -1)).clamp(0, 0x7fffffff);
          setState(() {});
        });
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title:
          "${widget.followingMode == FollowingMode.follower ? appLocalizations.followerList : appLocalizations.followingList}（$total）",
    );
  }
}
