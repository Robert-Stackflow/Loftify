import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/account_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/collection_screen.dart';
import 'package:loftify/Screens/Info/favorite_folder_list_screen.dart';
import 'package:loftify/Screens/Info/grain_screen.dart';
import 'package:loftify/Screens/Info/history_screen.dart';
import 'package:loftify/Screens/Info/like_screen.dart';
import 'package:loftify/Screens/Info/post_screen.dart';
import 'package:loftify/Screens/Info/share_screen.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/constant.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/lottie_util.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../Models/user_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/cloud_control_provider.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../generated/l10n.dart';
import '../Info/following_follower_screen.dart';
import '../Info/system_notice_screen.dart';
import '../Setting/setting_screen.dart';
import '../Suit/suit_screen.dart';
import '../refresh_interface.dart';

class MineScreen extends StatefulWidget {
  const MineScreen({super.key});

  static const String routeName = "/nav/mine";

  @override
  State<MineScreen> createState() => _MineScreenState();
}

class _MineScreenState extends State<MineScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScrollToHideMixin {
  @override
  bool get wantKeepAlive => true;
  FullBlogInfo? blogInfo;
  MeInfoData? meInfoData;
  final EasyRefreshController _refreshController = EasyRefreshController();
  final List<FollowingUserItem> _followingList = [];
  final List<FollowingUserItem> _followerList = [];

  final ScrollController _scrollController = ScrollController();

  late AnimationController darkModeController;
  Widget? darkModeWidget;

  @override
  void dispose() {
    darkModeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      darkModeWidget = LottieUtil.load(
        LottieUtil.sunLight,
        size: 25,
        autoForward: !Utils.isDark(context),
        controller: darkModeController,
      );
      panelScreenState?.refreshScrollControllers();
    });
    _fetchUserInfo();
    if (appProvider.token.isNotEmpty) {
      _fetchFollowingOrFolllowerList(FollowingMode.following, refresh: true);
      _fetchFollowingOrFolllowerList(FollowingMode.follower, refresh: true);
    }
  }

  _fetchUserInfo() async {
    if (appProvider.token.isNotEmpty) {
      return await UserApi.getUserInfo().then((value) async {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            return IndicatorResult.fail;
          } else {
            AccountResponse accountResponse =
                AccountResponse.fromJson(value['response']);
            await HiveUtil.setUserInfo(accountResponse.blogs[0].blogInfo);
            setState(() {
              blogInfo = accountResponse.blogs[0].blogInfo;
            });
            return await UserApi.getMeInfo(blogName: blogInfo!.blogName)
                .then((value) async {
              try {
                if (value['meta']['status'] != 200) {
                  IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
                  return IndicatorResult.fail;
                } else {
                  setState(() {
                    meInfoData = MeInfoData.fromJson(value['response']);
                  });
                  return IndicatorResult.success;
                }
              } catch (e, t) {
                IToast.showTop(S.current.loadFailed);
                ILogger.error("Failed to load me info", e, t);
                return IndicatorResult.fail;
              }
            });
          }
        } catch (e, t) {
          IToast.showTop(S.current.loadFailed);
          ILogger.error("Failed to load user info", e, t);
          return IndicatorResult.fail;
        }
      });
    }
    return IndicatorResult.success;
  }

  _onRefresh() async {
    return await _fetchUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: appProvider.token.isNotEmpty
          ? Theme.of(context).scaffoldBackgroundColor
          : MyTheme.getBackground(context),
      appBar: ResponsiveUtil.isLandscape()
          ? appProvider.token.isNotEmpty
              ? ItemBuilder.buildResponsiveAppBar(
                  context: context,
                  title: S.current.mine,
                  titleLeftMargin: ResponsiveUtil.isLandscape() ? 15 : 10,
                )
              : null
          : PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: SafeArea(child: _buildAppBar())),
      body: _buildMainBody(),
    );
  }

  _buildMainBody() {
    return appProvider.token.isNotEmpty
        ? ScreenTypeLayout.builder(
            breakpoints: const ScreenBreakpoints(
              desktop: 640,
              tablet: 640,
              watch: 200,
            ),
            mobile: (context) => _buildMobileMainBody(),
            tablet: (context) => _buildTabletMainBody(),
          )
        : LoftifyItemBuilder.buildUnLoginMainBody(context);
  }

  _buildMobileMainBody() {
    return EasyRefresh(
      controller: _refreshController,
      onRefresh: _onRefresh,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: ListView(
          cacheExtent: 9999,
          controller: _scrollController,
          children: [
            const SizedBox(height: 10),
            _buildUserCard(),
            _buildStatsticRow(),
            if (blogInfo != null) ..._buildContent(),
            // if (blogInfo != null) ..._buildMessage(),
            if (blogInfo != null) ..._buildCreation(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  _buildTabletMainBody() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: EasyRefresh(
            controller: _refreshController,
            onRefresh: _onRefresh,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView(
                cacheExtent: 9999,
                children: [
                  const SizedBox(height: 20),
                  _buildUserCard(),
                  if (blogInfo != null) ..._buildContent(),
                  // if (blogInfo != null) ..._buildMessage(),
                  if (blogInfo != null) ..._buildCreation(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          width: 1,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).dividerColor,
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView(
                cacheExtent: 9999,
                children: [
                  const SizedBox(height: 10),
                  if (meInfoData != null) _buildFollowingCard(),
                  const SizedBox(height: 10),
                  if (meInfoData != null) _buildFollowerCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  _processResult(value, FollowingMode followingMode, {bool refresh = false}) {
    try {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return IndicatorResult.fail;
      } else {
        List<dynamic> t = value['response'];
        if (followingMode == FollowingMode.following) {
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
        } else if (followingMode == FollowingMode.follower) {
          if (refresh) _followerList.clear();
          List<FollowingUserItem> notExist = [];
          for (var e in t) {
            if (e != null) {
              if (_followerList.indexWhere((element) =>
                      element.blogInfo.blogId == e['blogInfo']['blogId']) ==
                  -1) {
                notExist.add(FollowingUserItem.fromJson(e));
              }
            }
          }
          _followerList.addAll(notExist);
        }
        if (mounted) setState(() {});
        return IndicatorResult.success;
      }
    } catch (e, t) {
      IToast.showTop(S.current.loadFailed);
      ILogger.error("Failed to load $followingMode result", e, t);
      return IndicatorResult.fail;
    } finally {
      if (mounted) setState(() {});
    }
  }

  _fetchFollowingOrFolllowerList(
    FollowingMode followingMode, {
    bool refresh = false,
  }) async {
    int offset = refresh ? 0 : _followingList.length;
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      String blogName = blogInfo!.blogName;
      return await UserApi.getFollowingList(
        blogName: blogName,
        offset: offset,
        followingMode: followingMode,
      ).then((value) {
        return _processResult(value, followingMode, refresh: refresh);
      });
    });
  }

  Widget _buildFollowingCard() {
    return ItemBuilder.buildContainerItem(
      context: context,
      backgroundColor: Theme.of(context).canvasColor,
      bottomRadius: true,
      topRadius: true,
      child: Column(
        children: [
          ItemBuilder.buildTitle(
            context,
            title: S.current
                .myFollowingWithCount(meInfoData!.blogInfo.attentionCount),
            icon: Icons.keyboard_arrow_right_rounded,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                FollowingFollowerScreen(
                  infoMode: InfoMode.me,
                  followingMode: FollowingMode.following,
                  blogId: blogInfo!.blogId,
                  blogName: blogInfo!.blogName,
                  total: meInfoData!.blogInfo.attentionCount,
                ),
              );
            },
          ),
          ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(_followingList.length, (index) {
              return LoftifyItemBuilder.buildFollowerOrFollowingItem(
                  context, index, _followingList[index],
                  onFollowOrUnFollow: () {
                setState(() {
                  meInfoData!.blogInfo.attentionCount +=
                      _followingList[index].following ? 1 : -1;
                  setState(() {});
                });
              });
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerCard() {
    return ItemBuilder.buildContainerItem(
      context: context,
      backgroundColor: Theme.of(context).canvasColor,
      bottomRadius: true,
      topRadius: true,
      child: Column(
        children: [
          ItemBuilder.buildTitle(
            context,
            title: S.current
                .myFollowerWithCount(meInfoData!.blogInfo.followerCount),
            icon: Icons.keyboard_arrow_right_rounded,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                FollowingFollowerScreen(
                  infoMode: InfoMode.me,
                  followingMode: FollowingMode.follower,
                  blogId: blogInfo!.blogId,
                  blogName: blogInfo!.blogName,
                  total: meInfoData!.blogInfo.followerCount,
                ),
              );
            },
          ),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: List.generate(_followerList.length, (index) {
              return LoftifyItemBuilder.buildFollowerOrFollowingItem(
                context,
                index,
                _followerList[index],
                onFollowOrUnFollow: () {
                  setState(() {});
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  getAvatarBoxImage() {
    String url = HiveUtil.getString(HiveUtil.customAvatarBoxKey) ?? "";
    return url.isNotEmpty ? url : blogInfo?.avatarBoxImage ?? "";
  }

  Widget _buildUserCard() {
    return ItemBuilder.buildClickable(
      GestureDetector(
        onTap: () {
          if (blogInfo == null) {
            RouteUtil.pushPanelCupertinoRoute(
                context, const LoginByCaptchaScreen());
          } else {
            RouteUtil.pushPanelCupertinoRoute(
              context,
              UserDetailScreen(
                  blogId: blogInfo!.blogId, blogName: blogInfo!.blogName),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.only(left: 6, right: 6, bottom: 15),
          color: Colors.transparent,
          child: Row(
            children: [
              ItemBuilder.buildAvatar(
                showLoading: false,
                context: context,
                imageUrl: blogInfo?.bigAvaImg ?? "",
                useDefaultAvatar: blogInfo == null,
                avatarBoxImageUrl: getAvatarBoxImage(),
                size: getAvatarBoxImage().isNotEmpty ? 48 : 72,
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  ItemBuilder.buildCopyable(
                    context,
                    toastText: S.current.haveCopiedNickName,
                    text: blogInfo != null ? blogInfo!.blogNickName : "",
                    copyable: blogInfo != null,
                    child: Text(
                      blogInfo != null
                          ? blogInfo!.blogNickName
                          : S.current.login,
                      style: Theme.of(context).textTheme.titleLarge?.apply(
                            fontSizeDelta: 2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  ItemBuilder.buildCopyable(
                    context,
                    toastText: S.current.haveCopiedLofterID,
                    text: blogInfo != null ? blogInfo!.blogName : "",
                    copyable: blogInfo != null,
                    child: Text(
                      blogInfo != null
                          ? S.current.lofterId(blogInfo!.blogName)
                          : S.current.loginToGetPersonalizedService,
                      style: Theme.of(context).textTheme.titleSmall?.apply(
                            color:
                                Theme.of(context).textTheme.labelSmall?.color,
                            fontSizeDelta: -1,
                            fontWeightDelta: 2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    meInfoData != null
                        ? S.current.userMeta(
                            "${meInfoData!.blogInfo.postCount}",
                            "${meInfoData!.collectionCount}")
                        : S.current.userMeta("-", "-"),
                    style: Theme.of(context).textTheme.titleSmall?.apply(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSizeDelta: 0,
                          fontWeightDelta: 2,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.keyboard_arrow_right_rounded,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildStatsticRow() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ItemBuilder.buildStatisticItem(
            context,
            title: S.current.hotCount,
            count: meInfoData?.blogInfo.hot.hotCount,
            onTap: () {},
            labelFontWeightDelta: 2,
            countColor: Theme.of(context).textTheme.titleLarge?.color,
            labelColor: Theme.of(context).textTheme.labelSmall?.color,
          ),
          ItemBuilder.buildStatisticItem(
            context,
            title: S.current.follower,
            count: meInfoData?.blogInfo.followerCount,
            onTap: () {
              if (blogInfo != null && meInfoData != null) {
                RouteUtil.pushPanelCupertinoRoute(
                  context,
                  FollowingFollowerScreen(
                    infoMode: InfoMode.me,
                    followingMode: FollowingMode.follower,
                    blogId: blogInfo!.blogId,
                    blogName: blogInfo!.blogName,
                    total: meInfoData!.blogInfo.followerCount,
                  ),
                );
              }
            },
            countColor: Theme.of(context).textTheme.titleLarge?.color,
            labelColor: Theme.of(context).textTheme.labelSmall?.color,
            labelFontWeightDelta: 2,
          ),
          ItemBuilder.buildStatisticItem(
            context,
            title: S.current.following,
            count: meInfoData?.blogInfo.attentionCount,
            countColor: Theme.of(context).textTheme.titleLarge?.color,
            labelColor: Theme.of(context).textTheme.labelSmall?.color,
            labelFontWeightDelta: 2,
            onTap: () {
              if (blogInfo != null && meInfoData != null) {
                RouteUtil.pushPanelCupertinoRoute(
                  context,
                  FollowingFollowerScreen(
                    infoMode: InfoMode.me,
                    followingMode: FollowingMode.following,
                    blogId: blogInfo!.blogId,
                    blogName: blogInfo!.blogName,
                    total: meInfoData!.blogInfo.attentionCount,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.contentCenter),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.myLikes,
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            LikeScreen(),
          );
        },
        leading: Icons.favorite_border_rounded,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.myRecommends,
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            ShareScreen(),
          );
        },
        leading: Icons.thumb_up_off_alt,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.myFavorites,
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            const FavoriteFolderListScreen(),
          );
        },
        leading: Icons.bookmark_outline_rounded,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.myHistory,
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            const HistoryScreen(),
          );
        },
        roundBottom: true,
        leading: Icons.history_rounded,
      ),
    ];
  }

  List<Widget> _buildCreation() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.myCreative),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.myPosts,
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            PostScreen(),
          );
        },
        leading: Icons.article_outlined,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.myCollections,
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            CollectionScreen(),
          );
        },
        leading: Icons.bookmarks_outlined,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.myGrains,
        padding: 15,
        showLeading: true,
        roundBottom: true,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            GrainScreen(),
          );
        },
        leading: Icons.grain_rounded,
      ),
    ];
  }

  changeMode() {
    if (Utils.isDark(context)) {
      appProvider.themeMode = ActiveThemeMode.light;
      darkModeController.forward();
    } else {
      appProvider.themeMode = ActiveThemeMode.dark;
      darkModeController.reverse();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      backgroundColor: Colors.transparent,
      actions: [
        if (appProvider.token.isNotEmpty)
          ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(
              Icons.exit_to_app_rounded,
              size: 23,
              color: Theme.of(context).iconTheme.color,
            ),
            onTap: () {
              HiveUtil.confirmLogout(context);
            },
          ),
        const SizedBox(width: 5),
        ItemBuilder.buildDynamicIconButton(
            context: context,
            icon: darkModeWidget,
            onTap: changeMode,
            onChangemode: (context, themeMode, child) {
              if (darkModeController.duration != null) {
                if (themeMode == ActiveThemeMode.light) {
                  darkModeController.forward();
                } else if (themeMode == ActiveThemeMode.dark) {
                  darkModeController.reverse();
                } else {
                  if (Utils.isDark(context)) {
                    darkModeController.reverse();
                  } else {
                    darkModeController.forward();
                  }
                }
              }
            }),
        const SizedBox(width: 5),
        Consumer<LoftifyControlProvider>(
          builder: (_, cloudControlProvider, __) =>
              cloudControlProvider.globalControl.showDress
                  ? Row(
                      children: [
                        ItemBuilder.buildIconButton(
                            context: context,
                            icon: AssetUtil.loadDouble(
                              context,
                              AssetUtil.dressLightIcon,
                              AssetUtil.dressDarkIcon,
                            ),
                            onTap: () {
                              RouteUtil.pushPanelCupertinoRoute(
                                context,
                                const SuitScreen(),
                              );
                            }),
                        const SizedBox(width: 5),
                      ],
                    )
                  : emptyWidget,
        ),
        ItemBuilder.buildIconButton(
          context: context,
          icon: Icon(
            Icons.notifications_on_outlined,
            size: 23,
            color: Theme.of(context).iconTheme.color,
          ),
          onTap: () {
            RouteUtil.pushPanelCupertinoRoute(
              context,
              const SystemNoticeScreen(),
            );
          },
        ),
        const SizedBox(width: 5),
        ItemBuilder.buildDynamicIconButton(
            context: context,
            icon: AssetUtil.loadDouble(
              context,
              AssetUtil.settingLightIcon,
              AssetUtil.settingDarkIcon,
            ),
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(context, const SettingScreen());
            }),
      ],
    );
  }

  @override
  List<ScrollController> getScrollControllers() {
    return [_scrollController];
  }
}
