import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/user_response.dart';
import '../../Utils/enums.dart';
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
  int total = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;

  @override
  void initState() {
    total = widget.total;
    super.initState();
  }

  _processResult(value, {bool refresh = false}) {
    try {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return IndicatorResult.fail;
      } else {
        List<dynamic> t = value['response'];
        if (refresh) _followingList.clear();
        List<FollowingUserItem> notExist = [];
        for (var e in t) {
          if (e != null) {
            if (_followingList.indexWhere((element) =>
                    element.blogInfo.blogId == e['blogInfo']['blogId']) ==
                -1) {
              notExist.add(FollowingUserItem.fromJson(e));
            }
          }
        }
        _followingList.addAll(notExist);
        if (mounted) setState(() {});
        if ((_followingList.length >= widget.total || notExist.isEmpty) &&
            !refresh) {
          _noMore = true;
          return IndicatorResult.noMore;
        } else {
          return IndicatorResult.success;
        }
      }
    } catch (e, t) {
      ILogger.error("Failed to load following or follower", e, t);
      if (mounted) IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      if (mounted) setState(() {});
      _loading = false;
    }
  }

  _fetchList({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _followingList.length;
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      if (widget.followingMode == FollowingMode.timeline) {
        String blogName = widget.blogName!;
        return await UserApi.getFollowingTimeline(
          blogName: blogName,
          offset: offset,
        ).then((value) {
          return _processResult(value, refresh: refresh);
        });
      } else {
        String blogName = widget.infoMode == InfoMode.me
            ? blogInfo!.blogName
            : widget.blogName!;
        return await UserApi.getFollowingList(
          blogName: blogName,
          offset: offset,
          followingMode: widget.followingMode,
        ).then((value) {
          return _processResult(value, refresh: refresh);
        });
      }
    });
  }

  _onRefresh() async {
    return await _fetchList(refresh: true);
  }

  _onLoad() async {
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
    if (_followingList.isEmpty) {
      return EmptyPlaceholder(
        text: appLocalizations.noUser,
        physics: physics,
        shrinkWrap: false,
      );
    }
    return WaterfallFlow.builder(
      physics: physics,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 560,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _followingList.length,
      itemBuilder: (context, index) {
        return LoftifyItemBuilder.buildFollowerOrFollowingItem(
            context, index, _followingList[index], onFollowOrUnFollow: () {
          total += _followingList[index].following ? 1 : -1;
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
