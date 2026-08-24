import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/account_response.dart';
import 'package:loftify/Screens/Download/download_management_screen.dart';
import 'package:loftify/Screens/Info/collection_screen.dart';
import 'package:loftify/Screens/Info/favorite_folder_list_screen.dart';
import 'package:loftify/Screens/Info/grain_screen.dart';
import 'package:loftify/Screens/Info/history_screen.dart';
import 'package:loftify/Screens/Info/like_screen.dart';
import 'package:loftify/Screens/Info/post_screen.dart';
import 'package:loftify/Screens/Info/share_screen.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../Models/user_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/cloud_control_provider.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import '../Info/following_follower_screen.dart';
import '../Info/system_notice_screen.dart';
import '../Setting/setting_screen.dart';
import '../Suit/suit_screen.dart';

class MineScreen extends StatefulWidget {
  const MineScreen({super.key});

  static const String routeName = "/nav/mine";

  @override
  State<MineScreen> createState() => _MineScreenState();
}

class _MineScreenState extends BaseDynamicState<MineScreen>
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
        LottieFiles.sunLight,
        size: 25,
        autoForward: !ColorUtil.isDark(context),
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

  Future<IndicatorResult> _fetchUserInfo() async {
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
                IToast.showTop(appLocalizations.loadFailed);
                ILogger.error("Failed to load me info", e, t);
                return IndicatorResult.fail;
              }
            });
          }
        } catch (e, t) {
          IToast.showTop(appLocalizations.loadFailed);
          ILogger.error("Failed to load user info", e, t);
          return IndicatorResult.fail;
        }
      });
    }
    return IndicatorResult.success;
  }

  Future<IndicatorResult> _onRefresh() async {
    return await _fetchUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: appProvider.token.isNotEmpty
          ? Theme.of(context).scaffoldBackgroundColor
          : ChewieTheme.getBackground(context),
      appBar: ResponsiveUtil.isLandscapeLayout()
          ? appProvider.token.isNotEmpty
              ? ResponsiveAppBar(
                  title: appLocalizations.mine,
                  titleLeftMargin: ResponsiveUtil.isLandscapeLayout() ? 15 : 10,
                )
              : null
          : _buildAppBar(),
      body: _buildMainBody(),
    );
  }

  Widget _buildMainBody() {
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

  Widget _buildMobileMainBody() {
    return EasyRefresh(
      controller: _refreshController,
      onRefresh: _onRefresh,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: ListView(
          cacheExtent: MediaQuery.sizeOf(context).height,
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

  Widget _buildTabletMainBody() {
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
                cacheExtent: MediaQuery.sizeOf(context).height,
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
                cacheExtent: MediaQuery.sizeOf(context).height,
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

  IndicatorResult _processResult(
    dynamic value,
    FollowingMode followingMode, {
    bool refresh = false,
  }) {
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
      IToast.showTop(appLocalizations.loadFailed);
      ILogger.error("Failed to load $followingMode result", e, t);
      return IndicatorResult.fail;
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<IndicatorResult> _fetchFollowingOrFolllowerList(
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
    return ContainerItem(
      backgroundColor: Theme.of(context).canvasColor,
      child: Column(
        children: [
          ItemBuilder.buildTitle(
            context,
            title: appLocalizations
                .myFollowingWithCount(meInfoData!.blogInfo.attentionCount),
            icon: LoftifyIcons.next,
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
    return ContainerItem(
      backgroundColor: Theme.of(context).canvasColor,
      child: Column(
        children: [
          ItemBuilder.buildTitle(
            context,
            title: appLocalizations
                .myFollowerWithCount(meInfoData!.blogInfo.followerCount),
            icon: LoftifyIcons.next,
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

  String getAvatarBoxImage() {
    String url = ChewieHiveUtil.getString(HiveUtil.customAvatarBoxKey) ?? "";
    return url.isNotEmpty ? url : blogInfo?.avatarBoxImage ?? "";
  }

  Widget _buildUserCard() {
    return ClickableWrapper(
      child: GestureDetector(
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
                    toastText: appLocalizations.haveCopiedNickName,
                    text: blogInfo != null ? blogInfo!.blogNickName : "",
                    copyable: blogInfo != null,
                    child: Text(
                      blogInfo != null
                          ? blogInfo!.blogNickName
                          : appLocalizations.login,
                      style: Theme.of(context).textTheme.titleLarge?.apply(
                            fontSizeDelta: 2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  ItemBuilder.buildCopyable(
                    context,
                    toastText: appLocalizations.haveCopiedLofterID,
                    text: blogInfo != null ? blogInfo!.blogName : "",
                    copyable: blogInfo != null,
                    child: Text(
                      blogInfo != null
                          ? appLocalizations.lofterId(blogInfo!.blogName)
                          : appLocalizations.loginToGetPersonalizedService,
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
                        ? appLocalizations.userMeta(
                            "${meInfoData!.blogInfo.postCount}",
                            "${meInfoData!.collectionCount}")
                        : appLocalizations.userMeta("-", "-"),
                    style: Theme.of(context).textTheme.titleSmall?.apply(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSizeDelta: 0,
                          fontWeightDelta: 2,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              ChewieIcon(
                LoftifyIcons.next,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsticRow() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ItemBuilder.buildStatisticItem(
            context,
            title: appLocalizations.hotCount,
            count: meInfoData?.blogInfo.hot.hotCount,
            onTap: () {},
            labelFontWeightDelta: 2,
            countColor: Theme.of(context).textTheme.titleLarge?.color,
            labelColor: Theme.of(context).textTheme.labelSmall?.color,
          ),
          ItemBuilder.buildStatisticItem(
            context,
            title: appLocalizations.follower,
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
            title: appLocalizations.following,
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
      CaptionItem(
        title: appLocalizations.contentCenter,
        children: [
          EntryItem(
            title: appLocalizations.myLikes,
            showLeading: true,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                LikeScreen(),
              );
            },
            leading: LoftifyIcons.favorite,
          ),
          EntryItem(
            title: appLocalizations.myRecommends,
            showLeading: true,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                ShareScreen(),
              );
            },
            leading: LoftifyIcons.recommend,
          ),
          EntryItem(
            title: appLocalizations.myFavorites,
            showLeading: true,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                const FavoriteFolderListScreen(),
              );
            },
            leading: LoftifyIcons.bookmark,
          ),
          EntryItem(
            title: appLocalizations.myHistory,
            showLeading: true,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                const HistoryScreen(),
              );
            },
            leading: LoftifyIcons.history,
          ),
          EntryItem(
            title: appLocalizations.downloadManagement,
            showLeading: true,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                const DownloadManagementScreen(),
              );
            },
            roundBottom: true,
            leading: LoftifyIcons.download,
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildCreation() {
    return [
      CaptionItem(
        title: appLocalizations.myCreative,
        children: [
          EntryItem(
            title: appLocalizations.myPosts,
            showLeading: true,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                PostScreen(),
              );
            },
            leading: LoftifyIcons.article,
          ),
          EntryItem(
            title: appLocalizations.myCollections,
            showLeading: true,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                CollectionScreen(),
              );
            },
            leading: LoftifyIcons.collection,
          ),
          EntryItem(
            title: appLocalizations.myGrains,
            showLeading: true,
            roundBottom: true,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                GrainScreen(),
              );
            },
            leading: LoftifyIcons.grain,
          ),
        ],
      ),
    ];
  }

  void changeMode() {
    if (ColorUtil.isDark(context)) {
      appProvider.themeMode = ActiveThemeMode.light;
      darkModeController.forward();
    } else {
      appProvider.themeMode = ActiveThemeMode.dark;
      darkModeController.reverse();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      backgroundColor: Colors.transparent,
      actions: [
        if (appProvider.token.isNotEmpty)
          ChewieIconButton(
            icon: LoftifyIcons.logout,
            tooltip: appLocalizations.logout,
            foregroundColor: Theme.of(context).iconTheme.color,
            onPressed: () {
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
                  if (ColorUtil.isDark(context)) {
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
                        ChewieIconButton(
                          icon: LoftifyIcons.dress,
                          tooltip: appLocalizations.dress,
                          foregroundColor: Theme.of(context).iconTheme.color,
                          onPressed: () {
                            RouteUtil.pushPanelCupertinoRoute(
                              context,
                              const SuitScreen(),
                            );
                          },
                        ),
                        const SizedBox(width: 5),
                      ],
                    )
                  : emptyWidget,
        ),
        ChewieIconButton(
          icon: LoftifyIcons.notifications,
          tooltip: appLocalizations.notice,
          foregroundColor: Theme.of(context).iconTheme.color,
          onPressed: () {
            RouteUtil.pushPanelCupertinoRoute(
              context,
              const SystemNoticeScreen(),
            );
          },
        ),
        const SizedBox(width: 5),
        ChewieIconButton(
          icon: LoftifyIcons.settings,
          tooltip: appLocalizations.setting,
          foregroundColor: Theme.of(context).iconTheme.color,
          onPressed: () {
            RouteUtil.pushPanelCupertinoRoute(context, const SettingScreen());
          },
        ),
      ],
    );
  }

  @override
  List<ScrollController> getScrollControllers() {
    return [_scrollController];
  }
}
