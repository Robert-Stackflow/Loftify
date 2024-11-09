import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Models/user_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../generated/l10n.dart';

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

class _FollowingFollowerScreenState extends State<FollowingFollowerScreen>
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
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
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
      if (mounted) IToast.showTop(S.current.loadFailed);
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
      backgroundColor: MyTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: EasyRefresh.builder(
        refreshOnStart: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoad: _onLoad,
        triggerAxis: Axis.vertical,
        childBuilder: (context, physics) {
          return _buildBody(physics);
        },
      ),
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    return ItemBuilder.buildLoadMoreNotification(
      noMore: _noMore,
      onLoad: _onLoad,
      child: WaterfallFlow.extent(
        maxCrossAxisExtent: 600,
        physics: physics,
        children: List.generate(_followingList.length, (index) {
          return LoftifyItemBuilder.buildFollowerOrFollowingItem(
              context, index, _followingList[index], onFollowOrUnFollow: () {
            total += _followingList[index].following ? 1 : -1;
            setState(() {});
          });
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildResponsiveAppBar(
      context: context,
      showBack: true,
      title:
          "${widget.followingMode == FollowingMode.follower ? S.current.followerList : S.current.followingList}（$total）",
    );
  }
}
