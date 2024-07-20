import 'package:blur/blur.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart' hide AnimatedSlide;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Models/show_case_response.dart';
import 'package:loftify/Screens/Info/collection_screen.dart';
import 'package:loftify/Screens/Info/following_follower_screen.dart';
import 'package:loftify/Screens/Info/grain_screen.dart';
import 'package:loftify/Screens/Info/like_screen.dart';
import 'package:loftify/Screens/Info/post_screen.dart';
import 'package:loftify/Screens/Info/share_screen.dart';
import 'package:loftify/Screens/Info/supporter_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Widgets/BottomSheet/input_bottom_sheet.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:tuple/tuple.dart';

import '../../Api/user_api.dart';
import '../../Models/user_response.dart';
import '../../Resources/colors.dart';
import '../../Resources/theme.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/Custom/custom_tab_indicator.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/dialog_builder.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../generated/l10n.dart';
import '../Post/collection_detail_screen.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({
    super.key,
    required this.blogId,
    required this.blogName,
  });

  final int blogId;
  final String blogName;

  static const String routeName = "/user/detail";

  @override
  UserDetailScreenState createState() => UserDetailScreenState();
}

class UserDetailScreenState extends State<UserDetailScreen>
    with TickerProviderStateMixin {
  final EasyRefreshController _refreshController = EasyRefreshController();

  TotalBlogData? _fullBlogData;
  bool? isMe = false;
  late TabController _tabController;
  List<Tab> tabList = [];
  List<ShowCaseItem> showCases = [];
  String _followButtonText = "关注";
  Color? _followButtonColor;

  InfoMode get infoMode => isMe == true ? InfoMode.me : InfoMode.other;

  _fetchData() {
    UserApi.getUserDetail(blogId: widget.blogId, blogName: widget.blogName)
        .then((value) {
      try {
        if (value['meta']['status'] != 200) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        } else {
          _fullBlogData = TotalBlogData.fromJson(value['response']);
          isMe = _fullBlogData!.blogInfo.blogId ==
              HiveUtil.getInt(key: HiveUtil.userIdKey);
          initTab();
          updateFollowStatus();
          _fetchShowCases();
          setState(() {});
        }
      } catch (e) {
        if (mounted) IToast.showTop("加载失败");
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  initTab() {
    tabList.clear();
    tabList.add(const Tab(text: '文章'));
    if (_fullBlogData!.showLike == 1) {
      tabList.add(const Tab(text: '喜欢'));
    }
    if (_fullBlogData!.showShare == 1) {
      tabList.add(const Tab(text: '推荐'));
    }
    tabList.add(const Tab(text: '合集'));
    if (_fullBlogData!.showFoods == 1) {
      tabList.add(const Tab(text: '粮单'));
    }
    _tabController = TabController(length: tabList.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.getBackground(context),
      resizeToAvoidBottomInset: false,
      body: _fullBlogData != null
          ? ExtendedNestedScrollView(
              headerSliverBuilder: (_, __) => _buildHeaderSlivers(),
              body: _buildTabView())
          : ItemBuilder.buildLoadingDialog(
              context,
              background: MyTheme.getBackground(context),
            ),
    );
  }

  _buildHeaderSlivers() {
    double calculatedExpanedHeight = infoMode == InfoMode.me ? 475 : 630;
    if (showCases.isNotEmpty) {
      calculatedExpanedHeight += 170;
    }
    if (Utils.isNotEmpty(getAvatarBoxImage())) {
      calculatedExpanedHeight += 40;
    }
    return <Widget>[
      ItemBuilder.buildSliverAppBar(
        context: context,
        expandedHeight: calculatedExpanedHeight,
        collapsedHeight: 56,
        backgroundWidget: _buildBackground(true),
        actions: _appBarActions(),
        center: true,
        title: Text(
          "个人主页",
          style: Theme.of(context).textTheme.titleMedium?.apply(
                color: Colors.white,
                fontWeightDelta: 2,
              ),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(
            children: [
              _buildBackground(false),
              Column(
                children: [
                  const SizedBox(height: 220),
                  _buildInfo(),
                ],
              )
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            decoration: BoxDecoration(
              color: MyTheme.getBackground(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: tabList,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              dividerHeight: 0,
              physics: const BouncingScrollPhysics(),
              labelStyle: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.apply(fontWeightDelta: 2),
              unselectedLabelStyle: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.apply(color: Colors.grey),
              indicator: CustomTabIndicator(
                borderColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  _appBarActions() {
    return [
      ItemBuilder.buildIconButton(
        context: context,
        onTap: () {
          List<Tuple2<String, dynamic>> options = [
            const Tuple2("复制主页链接", 0),
            const Tuple2("在浏览器打开", 1),
            const Tuple2("分享到其他应用", 2),
          ];
          if (infoMode == InfoMode.me) {
            options.addAll([
              const Tuple2("编辑个人资料", -1),
            ]);
          } else if (infoMode == InfoMode.other) {
            if (Utils.isNotEmpty(_fullBlogData!.blogInfo.avatarBoxImage)) {
              options.add(
                Tuple2(
                    HiveUtil.getString(
                                key: HiveUtil.customAvatarBoxKey,
                                defaultValue: null) ==
                            _fullBlogData!.blogInfo.avatarBoxImage
                        ? "取消佩戴头像框"
                        : "佩戴头像框",
                    3),
              );
            }
            options.addAll([
              const Tuple2("设置备注", 4),
              Tuple2(_fullBlogData!.isBlackBlog ? "解除黑名单" : "加入黑名单", 5),
            ]);
            if (_fullBlogData!.following) {
              options.addAll([
                Tuple2(
                    _fullBlogData!.isShieldRecom == 1
                        ? "恢复查看TA推荐的内容"
                        : "不看TA推荐的内容",
                    6),
                Tuple2(
                    _fullBlogData!.shieldUserTimeline ? "恢复查看TA的动态" : "不看TA的动态",
                    7),
              ]);
            }
          }
          BottomSheetBuilder.showListBottomSheet(
            context,
            (sheetContext) => TileList.fromOptions(
              options,
              (idx) async {
                Navigator.pop(sheetContext);
                if (idx == -1) {
                } else if (idx == 0) {
                  Utils.copy(context, _fullBlogData!.blogInfo.homePageUrl);
                } else if (idx == 1) {
                  UriUtil.openExternal(_fullBlogData!.blogInfo.homePageUrl);
                } else if (idx == 2) {
                  UriUtil.share(
                    context,
                    _fullBlogData!.blogInfo.homePageUrl,
                  );
                } else if (idx == 3) {
                  String? currentAvatarImg = HiveUtil.getString(
                      key: HiveUtil.customAvatarBoxKey, defaultValue: null);
                  if (currentAvatarImg ==
                      _fullBlogData!.blogInfo.avatarBoxImage) {
                    await HiveUtil.put(
                        key: HiveUtil.customAvatarBoxKey, value: "");
                    currentAvatarImg = "";
                    setState(() {});
                    IToast.showTop("取消佩戴成功");
                  } else {
                    await HiveUtil.put(
                        key: HiveUtil.customAvatarBoxKey,
                        value: _fullBlogData!.blogInfo.avatarBoxImage);
                    currentAvatarImg = _fullBlogData!.blogInfo.avatarBoxImage;
                    setState(() {});
                    IToast.showTop("佩戴成功");
                  }
                } else if (idx == 4) {
                  showMaterialModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    builder: (sheetContext) => InputBottomSheet(
                      buttonText: "确认",
                      title: "设置「${_fullBlogData!.blogInfo.blogNickName}」的备注",
                      text: _fullBlogData!.blogInfo.remarkName.trim(),
                      onConfirm: (text) {
                        UserApi.setRemark(
                          blogId: _fullBlogData!.blogInfo.blogId,
                          remark: text,
                        ).then((value) {
                          if (value['meta']['status'] != 200) {
                            IToast.showTop(
                                value['meta']['desc'] ?? value['meta']['msg']);
                          } else {
                            _fullBlogData!.blogInfo.remarkName = text;
                            setState(() {});
                            IToast.showTop("设置备注成功");
                          }
                        });
                      },
                    ),
                  );
                } else if (idx == 5) {
                  _doBlockUser(
                      isBlock: !_fullBlogData!.isBlackBlog,
                      onSuccess: () {
                        if (_fullBlogData!.isBlackBlog) {
                          IToast.showTop("拉黑成功");
                        } else {
                          IToast.showTop("解除拉黑成功");
                        }
                        setState(() {});
                        updateFollowStatus();
                      });
                } else if (idx == 6) {
                  UserApi.shieldRecommendOrUnShield(
                    blogId: _fullBlogData!.blogInfo.blogId,
                    isShield: !(_fullBlogData!.isShieldRecom == 1),
                  ).then((value) {
                    if (value['meta']['status'] != 200) {
                      IToast.showTop(
                          value['meta']['desc'] ?? value['meta']['msg']);
                    } else {
                      _fullBlogData!.isShieldRecom =
                          _fullBlogData!.isShieldRecom == 1 ? 0 : 1;
                      setState(() {});
                    }
                  });
                } else if (idx == 7) {
                  UserApi.shieldBlogOrUnShield(
                    blogId: _fullBlogData!.blogInfo.blogId,
                    isShield: !_fullBlogData!.shieldUserTimeline,
                  ).then((value) {
                    if (value['code'] != 0) {
                      IToast.showTop(value['msg']);
                    } else {
                      _fullBlogData!.shieldUserTimeline =
                          !_fullBlogData!.shieldUserTimeline;
                      setState(() {});
                    }
                  });
                }
              },
              redOptions: const [5, 6, 7],
              showCancel: true,
              context: context,
              showTitle: false,
              onCloseTap: () => Navigator.pop(sheetContext),
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          );
        },
        icon: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 5),
    ];
  }

  _fetchShowCases() {
    UserApi.getShowCases(
            blogId: _fullBlogData!.blogInfo.blogId,
            blogName: _fullBlogData!.blogInfo.blogName)
        .then((value) {
      if (value['code'] != 200) {
        IToast.showTop(value['msg']);
      } else if (value['data']['showCaseList'] != null) {
        showCases = (value['data']['showCaseList'] as List)
            .map((e) => ShowCaseItem.fromJson(e))
            .toList();
        updateFollowStatus();
        setState(() {});
      }
    });
  }

  getAvatarBoxImage() {
    if (infoMode == InfoMode.me) {
      String url = HiveUtil.getString(
              key: HiveUtil.customAvatarBoxKey, defaultValue: null) ??
          "";
      return url.isNotEmpty ? url : _fullBlogData!.blogInfo.avatarBoxImage;
    } else {
      return _fullBlogData!.blogInfo.avatarBoxImage;
    }
  }

  Widget _buildInfo() {
    bool hasRemarkName = Utils.isNotEmpty(_fullBlogData!.blogInfo.remarkName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: MyTheme.getBackground(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      width: MediaQuery.sizeOf(context).width,
      child: Column(
        children: [
          const SizedBox(height: 10),
          ItemBuilder.buildAvatar(
            context: context,
            size: 80,
            showBorder: false,
            showDetailMode: ShowDetailMode.avatar,
            imageUrl: Utils.removeImageParam(_fullBlogData!.blogInfo.bigAvaImg),
            avatarBoxImageUrl: getAvatarBoxImage(),
            title: "个人头像",
            caption: "「${_fullBlogData!.blogInfo.blogNickName}」",
            tagPrefix: Utils.getRandomString(),
          ),
          const SizedBox(height: 12),
          ItemBuilder.buildCopyItem(
            context,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _fullBlogData!.blogInfo.blogNickName,
                style: Theme.of(context).textTheme.titleLarge?.apply(
                      fontSizeDelta: 2,
                    ),
              ),
            ),
            copyText: _fullBlogData!.blogInfo.blogNickName,
            toastText: "已复制昵称",
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ItemBuilder.buildCopyItem(
                context,
                child: Text(
                  textAlign: TextAlign.center,
                  'ID: ${_fullBlogData!.blogInfo.blogName}',
                  style: Theme.of(context).textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                copyText: _fullBlogData!.blogInfo.blogName,
                toastText: "已复制LofterID",
              ),
              if (hasRemarkName)
                ItemBuilder.buildCopyItem(
                  context,
                  child: Text(
                    textAlign: TextAlign.center,
                    ' | 备注: ${_fullBlogData!.blogInfo.remarkName}',
                    style: Theme.of(context).textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  copyText: _fullBlogData!.blogInfo.remarkName,
                  toastText: "已复制备注",
                ),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              textAlign: TextAlign.center,
              '性别：${_fullBlogData!.blogInfo.gendar == 1 ? "男" : _fullBlogData!.blogInfo.gendar == 2 ? "女" : "保密"}  |  IP属地: ${_fullBlogData!.blogInfo.ipLocation}${Utils.clearBlank(_fullBlogData!.blogInfo.selfIntro).isNotEmpty ? "  |  简介: ${Utils.clearBlank(_fullBlogData!.blogInfo.selfIntro)}" : ""}',
              style: Theme.of(context).textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ItemBuilder.buildStatisticItem(
                context,
                title: '关注',
                count: _fullBlogData!.blogInfo.blogStat.followingCount,
                onTap: () {
                  if (_fullBlogData!.showFollow == 1 ||
                      infoMode == InfoMode.me) {
                    RouteUtil.pushCupertinoRoute(
                      context,
                      FollowingFollowerScreen(
                        infoMode: infoMode,
                        followingMode: infoMode == InfoMode.me
                            ? FollowingMode.following
                            : FollowingMode.timeline,
                        blogId: _fullBlogData!.blogInfo.blogId,
                        blogName: _fullBlogData!.blogInfo.blogName,
                        total: _fullBlogData!.blogInfo.blogStat.followingCount,
                      ),
                    );
                  } else {
                    IToast.showTop("无法查看关注列表");
                  }
                },
              ),
              ItemBuilder.buildStatisticItem(
                context,
                title: '粉丝',
                count: _fullBlogData!.blogInfo.blogStat.followedCount,
                onTap: () {
                  if (_fullBlogData!.showFans == 1 || infoMode == InfoMode.me) {
                    RouteUtil.pushCupertinoRoute(
                      context,
                      FollowingFollowerScreen(
                        infoMode: infoMode,
                        followingMode: FollowingMode.follower,
                        blogId: _fullBlogData!.blogInfo.blogId,
                        blogName: _fullBlogData!.blogInfo.blogName,
                        total: _fullBlogData!.blogInfo.blogStat.followedCount,
                      ),
                    );
                  } else {
                    IToast.showTop("无法查看粉丝列表");
                  }
                },
              ),
              ItemBuilder.buildStatisticItem(
                context,
                title: '热度',
                count: _fullBlogData!.blogInfo.hot.hotCount,
                onTap: () {
                  DialogBuilder.showInfoDialog(
                    context,
                    title: "总热度${_fullBlogData!.blogInfo.hot.hotCount}",
                    messageChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHotItem(
                          icon: Icons.favorite_rounded,
                          title: "文章获得喜欢",
                          count: _fullBlogData!.blogInfo.hot.favoriteCount,
                        ),
                        _buildHotItem(
                          icon: Icons.thumb_up_rounded,
                          title: "累计获得推荐",
                          count: _fullBlogData!.blogInfo.hot.shareCount,
                        ),
                        _buildHotItem(
                          icon: Icons.bookmark_rounded,
                          title: "累计获得收藏",
                          count: _fullBlogData!.blogInfo.hot.subscribeCount,
                        ),
                        _buildHotItem(
                          icon: Icons.mode_comment_rounded,
                          title: "讨论获得喜欢",
                          count:
                              _fullBlogData!.blogInfo.hot.tagChatFavoriteCount,
                        ),
                      ],
                    ),
                    buttonText: "加油哦",
                    onTapDismiss: () {},
                    customDialogType: CustomDialogType.custom,
                  );
                },
              ),
              ItemBuilder.buildStatisticItem(
                context,
                title: '支持者',
                count: _fullBlogData!.blogInfo.blogStat.supporterCount,
                onTap: () {
                  if (_fullBlogData!.showSupport == 1 ||
                      infoMode == InfoMode.me) {
                    RouteUtil.pushCupertinoRoute(
                      context,
                      SupporterScreen(
                        infoMode: infoMode,
                        blogId: _fullBlogData!.blogInfo.blogId,
                      ),
                    );
                  } else {
                    IToast.showTop("无法查看支持者列表");
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (infoMode == InfoMode.other)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ItemBuilder.buildRoundButton(
                      context,
                      onTap: _processFollow,
                      text: _followButtonText,
                      background: _followButtonColor,
                      fontSizeDelta: 2,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ItemBuilder.buildRoundButton(
                      context,
                      onTap: () {
                        IToast.showTop("暂不支持聊天");
                      },
                      text: "聊天",
                      fontSizeDelta: 2,
                    ),
                  ),
                ],
              ),
            ),
          if (infoMode == InfoMode.other) const SizedBox(height: 12),
          if (showCases.isNotEmpty) _buildShowCases(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  updateFollowStatus() {
    if (_fullBlogData!.following) {
      _followButtonText = _fullBlogData!.specialfollowing ? "已特别关注" : "已关注";
      _followButtonColor = null;
    } else {
      _followButtonText = "关注";
      _followButtonColor = Theme.of(context).primaryColor;
    }
    if (_fullBlogData!.isBlackBlog) {
      _followButtonText = "已拉黑";
      _followButtonColor = null;
    }
    setState(() {});
  }

  _buildHotItem({
    Color? color,
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Container(
      width: 180,
      margin: const EdgeInsets.all(3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color ?? MyColors.getHotTagTextColor(context),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  _doFollow({required bool isFollow}) {
    UserApi.followOrUnfollow(
      isFollow: isFollow,
      blogId: _fullBlogData!.blogInfo.blogId,
      blogName: _fullBlogData!.blogInfo.blogName,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
      } else {
        _fullBlogData!.following = !_fullBlogData!.following;
        setState(() {});
        updateFollowStatus();
      }
    });
  }

  void _doBlockUser({
    required bool isBlock,
    Function()? onSuccess,
  }) {
    UserApi.blockOrUnBlock(
      isBlock: isBlock,
      blogId: _fullBlogData!.blogInfo.blogId,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
      } else {
        _fullBlogData!.isBlackBlog = !_fullBlogData!.isBlackBlog;
        if (_fullBlogData!.isBlackBlog) {
          _fullBlogData!.following = false;
          _fullBlogData!.specialfollowing = false;
        }
        onSuccess?.call();
      }
    });
  }

  _doSpecialFollow({required bool isSpecialFollow}) {
    UserApi.specialFollowOrSpecialUnfollow(
      isSpecialFollow: isSpecialFollow,
      blogId: _fullBlogData!.blogInfo.blogId,
      blogName: _fullBlogData!.blogInfo.blogName,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
      } else {
        _fullBlogData!.specialfollowing = !_fullBlogData!.specialfollowing;
        setState(() {});
        updateFollowStatus();
      }
    });
  }

  _processFollow() {
    if (_fullBlogData!.isBlackBlog) {
      DialogBuilder.showConfirmDialog(
        context,
        title: "解除黑名单",
        message: "确认解除「${_fullBlogData!.blogInfo.blogNickName}」的黑名单？",
        confirmButtonText: S.current.confirm,
        cancelButtonText: S.current.cancel,
        onTapConfirm: () async {
          _doBlockUser(
              isBlock: !_fullBlogData!.isBlackBlog,
              onSuccess: () {
                setState(() {});
                updateFollowStatus();
              });
        },
        onTapCancel: () {},
        customDialogType: CustomDialogType.custom,
      );
    } else {
      if (!_fullBlogData!.following) {
        HapticFeedback.mediumImpact();
        _doFollow(isFollow: !_fullBlogData!.following);
      } else {
        BottomSheetBuilder.showListBottomSheet(
          context,
          (sheetContext) => TileList.fromOptions(
            [
              Tuple2(_fullBlogData!.specialfollowing ? "取消特别关注" : "特别关注", 2),
              const Tuple2("取消关注", 0),
            ],
            (idx) {
              if (idx == 0) {
                _doFollow(isFollow: !_fullBlogData!.following);
              } else {
                _doSpecialFollow(
                    isSpecialFollow: !_fullBlogData!.specialfollowing);
              }
              Navigator.pop(sheetContext);
            },
            context: context,
            showCancel: true,
            showTitle: false,
            onCloseTap: () => Navigator.pop(sheetContext),
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
        );
      }
    }
  }

  _buildTabView() {
    ScrollController controller = ScrollController();
    List<Widget> children = [];
    children.add(
      PostScreen(
        scrollController: controller,
        infoMode: InfoMode.other,
        blogId: _fullBlogData!.blogInfo.blogId,
        blogName: _fullBlogData!.blogInfo.blogName,
      ),
    );
    if (_fullBlogData!.showLike == 1) {
      children.add(
        LikeScreen(
          scrollController: controller,
          infoMode: InfoMode.other,
          blogId: _fullBlogData!.blogInfo.blogId,
          blogName: _fullBlogData!.blogInfo.blogName,
        ),
      );
    }
    if (_fullBlogData!.showShare == 1) {
      children.add(
        ShareScreen(
          scrollController: controller,
          infoMode: InfoMode.other,
          blogId: _fullBlogData!.blogInfo.blogId,
          blogName: _fullBlogData!.blogInfo.blogName,
        ),
      );
    }
    children.add(
      CollectionScreen(
        scrollController: controller,
        infoMode: InfoMode.other,
        blogId: _fullBlogData!.blogInfo.blogId,
        blogName: _fullBlogData!.blogInfo.blogName,
        collectionCount: _fullBlogData!.collectionCount,
      ),
    );
    if (_fullBlogData!.showFoods == 1) {
      children.add(
        GrainScreen(
          scrollController: controller,
          infoMode: InfoMode.other,
          blogId: _fullBlogData!.blogInfo.blogId,
          blogName: _fullBlogData!.blogInfo.blogName,
        ),
      );
    }
    return Container(
      color: MyTheme.getBackground(context),
      child: TabBarView(
        controller: _tabController,
        children: children,
      ),
    );
  }

  _buildShowCases() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 16,
                color: MyColors.getHotTagTextColor(context),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  "TA的代表作",
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.apply(fontSizeDelta: -1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: showCases.length,
              itemBuilder: (context, index) {
                return _buildShowCaseItem(showCases[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  _buildShowCaseItem(ShowCaseItem item) {
    late String title;
    late String backgroundUrl;
    late String hotCount;
    late Function() onTap;
    if (item.postSimpleData != null) {
      title = item.postSimpleData!.postView.title;
      backgroundUrl = item.postSimpleData!.postView.firstImage.orign;
      hotCount = item.postSimpleData!.postCountView.hotCount.toString();
      if (title.isEmpty) {
        title = Utils.extractTextFromHtml(item.postSimpleData!.postView.digest);
      }
      onTap = () {
        item.postSimpleData!.postView.blogName =
            _fullBlogData!.blogInfo.blogName;
        RouteUtil.pushCupertinoRoute(
          context,
          PostDetailScreen(
            showCaseItem: item,
            isArticle: Utils.isEmpty(backgroundUrl),
          ),
        );
      };
    } else {
      title = item.postCollection!.name;
      backgroundUrl = item.postCollection!.coverUrl;
      hotCount = item.postCollection!.postCollectionHot.toString();
      onTap = () {
        RouteUtil.pushCupertinoRoute(
          context,
          CollectionDetailScreen(
            blogId: widget.blogId,
            blogName: widget.blogName,
            collectionId: item.postCollection!.id,
            postId: item.postCollection!.id,
          ),
        );
      };
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Utils.isNotEmpty(backgroundUrl)
                  ? ItemBuilder.buildCachedImage(
                      context: context,
                      imageUrl: backgroundUrl,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      showLoading: false,
                      placeholderBackground: Colors.transparent,
                    )
                  : AssetUtil.loadDouble(
                      context,
                      AssetUtil.lofterDarkIllust,
                      AssetUtil.lofterDarkIllust,
                      size: 100,
                      fit: BoxFit.cover,
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Spacer(),
                  Center(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.apply(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          hotCount,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.apply(fontSizeDelta: -1, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -4,
              right: -6,
              child: ItemBuilder.buildCachedImage(
                context: context,
                imageUrl: item.icon,
                width: 40,
                height: 40,
                showLoading: false,
                placeholderBackground: Colors.transparent,
              ),
            ),
            if (item.postCollection != null)
              Positioned(
                top: 6,
                left: 6,
                child: AssetUtil.load(
                  AssetUtil.collectionWhiteIcon,
                  size: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(bool blur, {double? height}) {
    String backgroudUrl = _fullBlogData!.blogcover.customBlogCover ??
        _fullBlogData!.blogcover.url;
    if (blur) {
      return Blur(
        blur: 10,
        blurColor: Colors.black12,
        child: ItemBuilder.buildCachedImage(
          context: context,
          imageUrl: Utils.removeImageParam(backgroudUrl),
          fit: BoxFit.cover,
          width: MediaQuery.sizeOf(context).width * 2,
          height: height ?? 300,
          placeholderBackground: Theme.of(context).textTheme.labelSmall?.color,
          bottomPadding: 50,
          showLoading: false,
        ),
      );
    } else {
      return ItemBuilder.buildHeroCachedImage(
        context: context,
        imageUrl: Utils.removeImageParam(backgroudUrl),
        fit: BoxFit.cover,
        width: MediaQuery.sizeOf(context).width * 2,
        height: 300,
        placeholderBackground: Theme.of(context).textTheme.labelSmall?.color,
        bottomPadding: 50,
        showLoading: false,
        title: "主题背景",
        tagPrefix: Utils.getRandomString(),
        caption: "「${_fullBlogData!.blogInfo.blogNickName}」",
      );
    }
  }
}
