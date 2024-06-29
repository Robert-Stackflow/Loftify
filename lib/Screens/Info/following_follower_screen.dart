import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Resources/colors.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/enums.dart';
import '../../Models/user_response.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import 'user_detail_screen.dart';

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
        IToast.showTop(context,
            text: value['meta']['desc'] ?? value['meta']['msg']);
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
          return IndicatorResult.noMore;
        } else {
          return IndicatorResult.success;
        }
      }
    } catch (e) {
      if (mounted) IToast.showTop(context, text: "加载失败");
      return IndicatorResult.fail;
    } finally {
      if (mounted) setState(() {});
      _loading = false;
    }
  }

  _fetchList({bool refresh = false}) async {
    if (_loading) return;
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
      backgroundColor: AppTheme.getBackground(context),
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
    return ListView(
      physics: physics,
      children: List.generate(_followingList.length, (index) {
        return _buildItem(index, _followingList[index]);
      }),
    );
  }

  _buildItem(int index, FollowingUserItem item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushCupertinoRoute(
          context,
          UserDetailScreen(
            blogId: item.blogInfo.blogId,
            blogName: item.blogInfo.blogName,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            ItemBuilder.buildAvatar(
              context: context,
              size: 40,
              imageUrl: item.blogInfo.bigAvaImg,
              tagPrefix: "$index",
              showDetailMode: ShowDetailMode.not,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.blogInfo.blogNickName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (item.blogInfo.selfIntro.isNotEmpty)
                    const SizedBox(height: 5),
                  if (item.blogInfo.selfIntro.isNotEmpty)
                    Text(
                      item.blogInfo.selfIntro,
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (item.follower)
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.star_rate_rounded,
                  size: 22,
                  color: MyColors.getHotTagTextColor(context),
                ),
              ),
            ItemBuilder.buildFramedButton(
              context: context,
              isFollowed: item.following,
              positiveText: item.follower ? "相互关注" : "已关注",
              onTap: () {
                UserApi.followOrUnfollow(
                  isFollow: !item.following,
                  blogId: item.blogId,
                  blogName: item.blogInfo.blogName,
                ).then((value) {
                  if (value['meta']['status'] != 200) {
                    IToast.showTop(context,
                        text: value['meta']['desc'] ?? value['meta']['msg']);
                  } else {
                    item.following = !item.following;
                    total += item.following ? 1 : -1;
                    setState(() {});
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      leading: Icons.arrow_back_rounded,
      backgroundColor: AppTheme.getBackground(context),
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: Text(
        "${widget.followingMode == FollowingMode.follower ? "粉丝列表" : "关注列表"}（$total）",
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
