import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/account_response.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Screens/Info/collection_screen.dart';
import 'package:loftify/Screens/Info/dress_screen.dart';
import 'package:loftify/Screens/Info/favorite_folder_list_screen.dart';
import 'package:loftify/Screens/Info/grain_screen.dart';
import 'package:loftify/Screens/Info/history_screen.dart';
import 'package:loftify/Screens/Info/like_screen.dart';
import 'package:loftify/Screens/Info/post_screen.dart';
import 'package:loftify/Screens/Info/share_screen.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/lottie_util.dart';

import '../../Providers/global_provider.dart';
import '../../Providers/provider_manager.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../Info/following_follower_screen.dart';
import '../Info/system_notice_screen.dart';
import '../Setting/setting_screen.dart';

class MineScreen extends StatefulWidget {
  const MineScreen({super.key});

  static const String routeName = "/nav/mine";

  @override
  State<MineScreen> createState() => _MineScreenState();
}

class _MineScreenState extends State<MineScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  FullBlogInfo? blogInfo;
  MeInfoData? meInfoData;
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();

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
    });
    _fetchUserInfo();
  }

  _fetchUserInfo() async {
    if (_loading) return;
    _loading = true;
    if (ProviderManager.globalProvider.token.isNotEmpty) {
      return await UserApi.getUserInfo().then((value) async {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(context,
                text: value['meta']['desc'] ?? value['meta']['msg']);
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
                  IToast.showTop(context,
                      text: value['meta']['desc'] ?? value['meta']['msg']);
                  return IndicatorResult.fail;
                } else {
                  setState(() {
                    meInfoData = MeInfoData.fromJson(value['response']);
                  });
                  return IndicatorResult.success;
                }
              } catch (_) {
                if (mounted) IToast.showTop(context, text: "加载失败");
                return IndicatorResult.fail;
              }
            });
          }
        } catch (_, t) {
          if (mounted) IToast.showTop(context, text: "加载失败");
          return IndicatorResult.fail;
        } finally {
          _loading = false;
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
      appBar: Utils.isDesktop() ? null : _buildAppBar(),
      body: EasyRefresh(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: ListView(
            cacheExtent: 9999,
            children: [
              const SizedBox(height: 10),
              _buildUserCard(),
              if (meInfoData != null) _buildStatsticRow(),
              if (blogInfo != null) ..._buildContent(),
              // if (blogInfo != null) ..._buildMessage(),
              if (blogInfo != null) ..._buildCreation(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  getAvatarBoxImage() {
    String url = HiveUtil.getString(
            key: HiveUtil.customAvatarBoxKey, defaultValue: null) ??
        "";
    return url.isNotEmpty ? url : blogInfo?.avatarBoxImage ?? "";
  }

  Widget _buildUserCard() {
    return ItemBuilder.buildContainerItem(
      context: context,
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          if (blogInfo == null) {
            RouteUtil.pushCupertinoRoute(context, const LoginByCaptchaScreen());
          } else {
            RouteUtil.pushCupertinoRoute(
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
                  ItemBuilder.buildCopyItem(
                    context,
                    toastText: "已复制昵称",
                    copyText: blogInfo != null ? blogInfo!.blogNickName : "",
                    condition: blogInfo != null,
                    child: Text(
                      blogInfo != null ? blogInfo!.blogNickName : "登录",
                      style: Theme.of(context).textTheme.titleLarge?.apply(
                            fontSizeDelta: 2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  ItemBuilder.buildCopyItem(
                    context,
                    toastText: "已复制LofterID",
                    copyText: blogInfo != null ? blogInfo!.blogName : "",
                    condition: blogInfo != null,
                    child: Text(
                      blogInfo != null
                          ? "ID：${blogInfo!.blogName}"
                          : "登录以获得个性化服务",
                      style: Theme.of(context).textTheme.titleSmall?.apply(
                            color:
                                Theme.of(context).textTheme.labelSmall?.color,
                            fontSizeDelta: -1,
                            fontWeightDelta: 2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (meInfoData != null)
                    Text(
                      "${meInfoData!.blogInfo.postCount}篇文章 · ${meInfoData!.collectionCount}个合集",
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
      topRadius: true,
      bottomRadius: true,
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
            title: '热度',
            count: meInfoData!.blogInfo.hot.hotCount,
            onTap: () {},
            labelFontWeightDelta: 2,
            countColor: Theme.of(context).textTheme.titleLarge?.color,
            labelColor: Theme.of(context).textTheme.labelSmall?.color,
          ),
          ItemBuilder.buildStatisticItem(
            context,
            title: '粉丝',
            count: meInfoData!.blogInfo.followerCount,
            onTap: () {
              RouteUtil.pushCupertinoRoute(
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
            countColor: Theme.of(context).textTheme.titleLarge?.color,
            labelColor: Theme.of(context).textTheme.labelSmall?.color,
            labelFontWeightDelta: 2,
          ),
          ItemBuilder.buildStatisticItem(
            context,
            title: '关注',
            count: meInfoData!.blogInfo.attentionCount,
            countColor: Theme.of(context).textTheme.titleLarge?.color,
            labelColor: Theme.of(context).textTheme.labelSmall?.color,
            labelFontWeightDelta: 2,
            onTap: () {
              RouteUtil.pushCupertinoRoute(
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
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(context: context, title: "内容中心"),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "我的喜欢",
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushCupertinoRoute(
            context,
            LikeScreen(),
          );
        },
        leading: Icons.favorite_border_rounded,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "我的推荐",
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushCupertinoRoute(
            context,
            ShareScreen(),
          );
        },
        leading: Icons.thumb_up_off_alt,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "我的收藏",
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushCupertinoRoute(
            context,
            const FavoriteFolderListScreen(),
          );
        },
        leading: Icons.bookmark_outline_rounded,
      ),
      // ItemBuilder.buildEntryItem(
      //   context: context,
      //   title: "我的订阅",
      //   padding: 15,
      //   showLeading: true,
      //   onTap: () {},
      //   leading: Icons.subscriptions_outlined,
      // ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "我的足迹",
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushCupertinoRoute(
            context,
            const HistoryScreen(),
          );
        },
        bottomRadius: true,
        leading: Icons.history_rounded,
      ),
    ];
  }

  List<Widget> _buildMessage() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(context: context, title: "我的消息"),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "评论回复",
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushCupertinoRoute(
            context,
            CollectionScreen(),
          );
        },
        leading: Icons.mode_comment_outlined,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "聊天消息",
        padding: 15,
        showLeading: true,
        bottomRadius: true,
        onTap: () {
          RouteUtil.pushCupertinoRoute(
            context,
            GrainScreen(),
          );
        },
        leading: Icons.chat_outlined,
      ),
    ];
  }

  List<Widget> _buildCreation() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(context: context, title: "我的创作"),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "我的作品",
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushCupertinoRoute(
            context,
            PostScreen(),
          );
        },
        leading: Icons.article_outlined,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "我的合集",
        padding: 15,
        showLeading: true,
        onTap: () {
          RouteUtil.pushCupertinoRoute(
            context,
            CollectionScreen(),
          );
        },
        leading: Icons.bookmarks_outlined,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: "我的粮单",
        padding: 15,
        showLeading: true,
        bottomRadius: true,
        onTap: () {
          RouteUtil.pushCupertinoRoute(
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
      ProviderManager.globalProvider.themeMode = ActiveThemeMode.light;
      darkModeController.forward();
    } else {
      ProviderManager.globalProvider.themeMode = ActiveThemeMode.dark;
      darkModeController.reverse();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      actions: [
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
        ItemBuilder.buildIconButton(
            context: context,
            icon: AssetUtil.loadDouble(
              context,
              AssetUtil.dressLightIcon,
              AssetUtil.dressDarkIcon,
            ),
            onTap: () {
              RouteUtil.pushCupertinoRoute(
                context,
                const DressScreen(),
              );
            }),
        const SizedBox(width: 5),
        ItemBuilder.buildIconButton(
          context: context,
          icon: Icon(
            Icons.notifications_on_outlined,
            size: 23,
            color: Theme.of(context).iconTheme.color,
          ),
          onTap: () {
            RouteUtil.pushCupertinoRoute(
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
              RouteUtil.pushCupertinoRoute(context, const SettingScreen());
            }),
        const SizedBox(width: 5),
      ],
    );
  }
}
