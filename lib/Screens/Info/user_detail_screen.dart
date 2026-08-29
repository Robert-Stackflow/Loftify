import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:blur/blur.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
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
import 'package:loftify/Screens/Suit/user_market_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:loftify/Widgets/Design/loftify_surfaces.dart';
import 'package:loftify/Widgets/Design/loftify_media_overlays.dart';
import 'package:loftify/Widgets/Profile/profile_overview_card.dart';
import 'package:loftify/Widgets/Profile/profile_header_components.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

import '../../Api/user_api.dart';
import '../../Models/user_response.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/tab_state_util.dart';
import '../../Utils/utils.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../l10n/l10n.dart';
import '../Post/collection_detail_screen.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({
    super.key,
    required this.blogId,
    required this.blogName,
    this.onBack,
  });

  final int blogId;
  final String blogName;
  final VoidCallback? onBack;

  static const String routeName = "/user/detail";

  @override
  UserDetailScreenState createState() => UserDetailScreenState();
}

class UserDetailScreenState extends BaseDynamicState<UserDetailScreen>
    with TickerProviderStateMixin {
  TotalBlogData? _fullBlogData;
  bool? isMe = false;
  late TabController _tabController;
  bool _tabControllerInitialized = false;
  List<Tab> tabList = [];
  final List<String> _tabIdList = [];
  int _currentTabIndex = 0;
  List<ShowCaseItem> showCases = [];
  String _followButtonText = appLocalizations.follow;
  bool _usesWideHeaderLayout(BuildContext context) {
    return LoftifyProfileHeaderLayout.usesSideBySide(
      context,
      hasShowcase: showCases.isNotEmpty,
    );
  }

  double _profileHeaderHeight(
    BuildContext context, {
    required bool includesAppBar,
  }) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final wide = _usesWideHeaderLayout(context);
    final base = showCases.isEmpty
        ? (includesAppBar ? 350.0 : 240.0)
        : wide
            ? (includesAppBar ? 390.0 : 285.0)
            : (includesAppBar ? 524.0 : 412.0);
    final accessibilityGrowth =
        ((scale - 1).clamp(0, 1.25) * 128) + (scale > 1.45 ? 96 : 0);
    return base + accessibilityGrowth;
  }

  InfoMode get infoMode => isMe == true ? InfoMode.me : InfoMode.other;

  Future<void> _fetchData() async {
    try {
      final value = await UserApi.getUserDetail(
        blogId: widget.blogId,
        blogName: widget.blogName,
      );
      if (!mounted) return;
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return;
      }

      final blogData = TotalBlogData.fromJson(value['response']);
      final userId = await HiveUtil.getUserId();
      if (!mounted) return;
      _fullBlogData = blogData;
      isMe = blogData.blogInfo.blogId == userId;
      initTab();
      updateFollowStatus(rebuild: false);
      setState(() {});
      _fetchShowCases();
    } catch (e, t) {
      ILogger.error("Failed to get user detail", e, t);
      if (mounted) IToast.showTop(appLocalizations.loadFailed);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void initTab() {
    if (_tabControllerInitialized) {
      _tabController.dispose();
    }
    tabList.clear();
    _tabIdList.clear();
    tabList.add(Tab(text: appLocalizations.article));
    _tabIdList.add('article');
    if (_fullBlogData!.showLike == 1) {
      tabList.add(Tab(text: appLocalizations.like));
      _tabIdList.add('like');
    }
    if (_fullBlogData!.showShare == 1) {
      tabList.add(Tab(text: appLocalizations.recommend));
      _tabIdList.add('recommend');
    }
    tabList.add(Tab(text: appLocalizations.collection));
    _tabIdList.add('collection');
    if (_fullBlogData!.showFoods == 1) {
      tabList.add(Tab(text: appLocalizations.grain));
      _tabIdList.add('grain');
    }
    _currentTabIndex = PersistentTabState.restore(
      idKey: HiveUtil.userDetailTabIdKey,
      legacyIndexKey: HiveUtil.userDetailTabIndexKey,
      itemIds: _tabIdList,
    ).index;
    _tabController = TabController(
      length: tabList.length,
      initialIndex: _currentTabIndex,
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.offset.abs() > 0.001) {
        return;
      }
      _setCurrentTab(_tabController.index);
    });
    _tabControllerInitialized = true;
  }

  void _setCurrentTab(int index) {
    final safeIndex = TabStatePreference.restoreIndex(index, tabList.length);
    if (safeIndex != _currentTabIndex && mounted) {
      setState(() => _currentTabIndex = safeIndex);
    }
    PersistentTabState.save(
      idKey: HiveUtil.userDetailTabIdKey,
      legacyIndexKey: HiveUtil.userDetailTabIndexKey,
      itemIds: _tabIdList,
      index: safeIndex,
    );
  }

  @override
  void dispose() {
    if (_tabControllerInitialized) {
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.design.colors.page,
      resizeToAvoidBottomInset: false,
      appBar: ResponsiveUtil.isLandscapeLayout()
          ? ResponsiveAppBar(
              showBack: true,
              title: appLocalizations.personalHomepage,
              onTapBack: widget.onBack,
            )
          : null,
      body: _fullBlogData != null
          ? ExtendedNestedScrollView(
              onlyOneScrollInBody: true,
              headerSliverBuilder: (_, __) => _buildHeaderSlivers(),
              body: _mainContent(),
            )
          : LoadingWidget(
              background: ChewieTheme.getBackground(context),
            ),
    );
  }

  List<Widget> _buildHeaderSlivers() {
    if (!ResponsiveUtil.isLandscapeLayout()) {
      return <Widget>[
        SliverAppBarWrapper(
          context: context,
          onBack: widget.onBack,
          expandedHeight: _profileHeaderHeight(
            context,
            includesAppBar: true,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          collapsedHeight: 56,
          backgroundWidget: _buildHeaderBackground(),
          actions: _appBarActions(),
          centerTitle: !ResponsiveUtil.isLandscapeLayout(),
          title: Text(
            appLocalizations.personalHomepage,
            style: Theme.of(context).textTheme.titleMedium?.apply(
                  color: Colors.white,
                  fontWeightDelta: 2,
                ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                _buildHeaderBackground(),
                _buildInfo(),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: TabBarWrapper(
                tabController: _tabController,
                tabs: tabList,
                width: MediaQuery.sizeOf(context).width,
                isScrollable: false,
                onTap: _setCurrentTab,
              ),
            ),
          ),
        ),
      ];
    } else {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: _profileHeaderHeight(
              context,
              includesAppBar: false,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildHeaderBackground(),
                _buildInfo(12),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          key: const ValueKey('user-profile-tabs'),
          pinned: true,
          delegate: SliverAppBarDelegate(
            radius: 0,
            background: context.design.colors.page,
            tabBar: TabBarWrapper(
              tabController: _tabController,
              tabs: tabList,
              width: MediaQuery.sizeOf(context).width,
              isScrollable: false,
              showBorder: true,
              onTap: _setCurrentTab,
            ),
          ),
        ),
      ];
    }
  }

  Widget _mainContent() {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.design.radii.panel),
      ),
      child: ColoredBox(
        color: context.design.colors.page,
        child: _buildTabView(),
      ),
    );
  }

  FlutterContextMenu _buildMoreButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.viewThemeBg,
          iconData: LoftifyIcons.image,
          onPressed: () {
            RouteUtil.pushDialogRoute(
              context,
              showClose: false,
              fullScreen: true,
              useFade: true,
              opaque: false,
              HeroPhotoViewScreen(
                tagPrefix: StringUtil.getRandomString(),
                imageUrls: [Utils.removeImageParam(backgroudUrl)],
                useMainColor: false,
                title: appLocalizations.themeBg,
                captions: ["「${_fullBlogData!.blogInfo.blogNickName}」"],
              ),
            );
          },
        ),
        FlutterContextMenuItem(
          appLocalizations.viewShop,
          iconData: LoftifyIcons.shop,
          onPressed: () {
            RouteUtil.pushPanelCupertinoRoute(context,
                UserMarketScreen(blogId: _fullBlogData!.blogInfo.blogId));
          },
        ),
        if (infoMode == InfoMode.other) ...[
          if (StringUtil.isNotEmpty(_fullBlogData!.blogInfo.avatarBoxImage))
            FlutterContextMenuItem(
              ChewieHiveUtil.getString(HiveUtil.customAvatarBoxKey) ==
                      _fullBlogData!.blogInfo.avatarBoxImage
                  ? appLocalizations.undressAvatarBox
                  : appLocalizations.dressAvatarBox,
              iconData: LoftifyIcons.avatarFrame,
              onPressed: () async {
                String? currentAvatarImg =
                    ChewieHiveUtil.getString(HiveUtil.customAvatarBoxKey);
                if (currentAvatarImg ==
                    _fullBlogData!.blogInfo.avatarBoxImage) {
                  await ChewieHiveUtil.put(HiveUtil.customAvatarBoxKey, "");
                  if (!mounted) return;
                  currentAvatarImg = "";
                  setState(() {});
                  IToast.showTop(appLocalizations.unDressSuccess);
                } else {
                  await ChewieHiveUtil.put(HiveUtil.customAvatarBoxKey,
                      _fullBlogData!.blogInfo.avatarBoxImage);
                  if (!mounted) return;
                  currentAvatarImg = _fullBlogData!.blogInfo.avatarBoxImage;
                  setState(() {});
                  IToast.showTop(appLocalizations.dressSuccess);
                }
              },
            ),
          FlutterContextMenuItem(
            appLocalizations.setRemark,
            iconData: LoftifyIcons.edit,
            onPressed: () {
              BottomSheetBuilder.showBottomSheet(
                context,
                (sheetContext) => InputBottomSheet(
                  title: appLocalizations
                      .setRemarkMessage(_fullBlogData!.blogInfo.blogNickName),
                  text: _fullBlogData!.blogInfo.remarkName.trim(),
                  onConfirm: (text) {
                    UserApi.setRemark(
                      blogId: _fullBlogData!.blogInfo.blogId,
                      remark: text,
                    ).then((value) {
                      if (!mounted) return;
                      if (value['meta']['status'] != 200) {
                        IToast.showTop(
                            value['meta']['desc'] ?? value['meta']['msg']);
                      } else {
                        _fullBlogData!.blogInfo.remarkName = text;
                        setState(() {});
                        IToast.showTop(appLocalizations.setRemarkSuccess);
                      }
                    });
                  },
                ),
                preferMinWidth: 400,
                responsive: true,
              );
            },
          ),
          const MenuDivider(
            thickness: 0.6,
            indent: 46,
            endIndent: 8,
          ),
          FlutterContextMenuItem(
            status: MenuItemStatus.error,
            _fullBlogData!.isBlackBlog
                ? appLocalizations.unlockBlacklist
                : appLocalizations.blockBlacklist,
            iconData: LoftifyIcons.block,
            onPressed: () {
              _doBlockUser(
                isBlock: !_fullBlogData!.isBlackBlog,
                onSuccess: () {
                  if (!mounted) return;
                  if (_fullBlogData!.isBlackBlog) {
                    IToast.showTop(appLocalizations.blockBlacklistSuccess);
                  } else {
                    IToast.showTop(appLocalizations.unblockBlacklistSuccess);
                  }
                  updateFollowStatus();
                },
              );
            },
          ),
          if (_fullBlogData!.following) ...[
            FlutterContextMenuItem(
              status: MenuItemStatus.error,
              _fullBlogData!.isShieldRecom == 1
                  ? appLocalizations.recoverViewRecommend
                  : appLocalizations.shieldViewRecommend,
              iconData: LoftifyIcons.block,
              onPressed: () {
                UserApi.shieldRecommendOrUnShield(
                  blogId: _fullBlogData!.blogInfo.blogId,
                  isShield: !(_fullBlogData!.isShieldRecom == 1),
                ).then((value) {
                  if (!mounted) return;
                  if (value['meta']['status'] != 200) {
                    IToast.showTop(
                        value['meta']['desc'] ?? value['meta']['msg']);
                  } else {
                    _fullBlogData!.isShieldRecom =
                        _fullBlogData!.isShieldRecom == 1 ? 0 : 1;
                    setState(() {});
                  }
                });
              },
            ),
            FlutterContextMenuItem(
              status: MenuItemStatus.error,
              _fullBlogData!.shieldUserTimeline
                  ? appLocalizations.recoverViewDynamic
                  : appLocalizations.shieldViewDynamic,
              iconData: LoftifyIcons.block,
              onPressed: () {
                UserApi.shieldBlogOrUnShield(
                  blogId: _fullBlogData!.blogInfo.blogId,
                  isShield: !_fullBlogData!.shieldUserTimeline,
                ).then((value) {
                  if (!mounted) return;
                  if (value['code'] != 0) {
                    IToast.showTop(value['msg']);
                  } else {
                    _fullBlogData!.shieldUserTimeline =
                        !_fullBlogData!.shieldUserTimeline;
                    setState(() {});
                  }
                });
              },
            ),
          ],
        ],
        const MenuDivider(
          thickness: 0.6,
          indent: 46,
          endIndent: 8,
        ),
        FlutterContextMenuItem(
          appLocalizations.copyHomepageLink,
          iconData: LoftifyIcons.copy,
          onPressed: () {
            ChewieUtils.copy(context, _fullBlogData!.blogInfo.homePageUrl);
          },
        ),
        FlutterContextMenuItem(appLocalizations.openWithBrowser,
            iconData: LoftifyIcons.openExternal, onPressed: () {
          UriUtil.openExternal(_fullBlogData!.blogInfo.homePageUrl);
        }),
        FlutterContextMenuItem(appLocalizations.shareToOtherApps,
            iconData: LoftifyIcons.share, onPressed: () {
          UriUtil.share(_fullBlogData!.blogInfo.homePageUrl);
        }),
      ],
    );
  }

  List<Widget> _appBarActions() {
    return [
      ChewieIconButton(
        icon: LoftifyIcons.moreVertical,
        tooltip: appLocalizations.moreInfo,
        foregroundColor: Colors.white,
        onPressed: () {
          BottomSheetBuilder.showContextMenu(context, _buildMoreButtons());
        },
      ),
    ];
  }

  Future<void> _fetchShowCases() async {
    try {
      final value = await UserApi.getShowCases(
        blogId: _fullBlogData!.blogInfo.blogId,
        blogName: _fullBlogData!.blogInfo.blogName,
      );
      if (!mounted) return;
      if (value['code'] != 200) {
        IToast.showTop(value['msg']);
      } else if (value['data']['showCaseList'] != null) {
        showCases = (value['data']['showCaseList'] as List)
            .map((e) => ShowCaseItem.fromJson(e))
            .toList();
        showCases = showCases
            .where(
                (e) => !(e.postCollection == null && e.postSimpleData == null))
            .toList();
        updateFollowStatus(rebuild: false);
        setState(() {});
      }
    } catch (e, t) {
      ILogger.error("Failed to get user showcases", e, t);
    }
  }

  String getAvatarBoxImage() {
    if (infoMode == InfoMode.me) {
      String url = ChewieHiveUtil.getString(HiveUtil.customAvatarBoxKey) ?? "";
      return url.isNotEmpty ? url : _fullBlogData!.blogInfo.avatarBoxImage;
    } else {
      return _fullBlogData!.blogInfo.avatarBoxImage;
    }
  }

  Widget _buildInfo([double? topMargin]) {
    final design = context.design;
    final hasRemarkName =
        StringUtil.isNotEmpty(_fullBlogData!.blogInfo.remarkName);
    final hasDescription = StringUtil.isNotEmpty(
      StringUtil.clearBlank(_fullBlogData!.blogInfo.selfIntro),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        design.spacing.xl,
        topMargin ?? kToolbarHeight + MediaQuery.paddingOf(context).top + 8,
        design.spacing.xl,
        design.spacing.lg,
      ),
      child: LoftifyProfileHeaderLayout(
        summary: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIdentitySummary(
              hasRemarkName: hasRemarkName,
              hasDescription: hasDescription,
            ),
            SizedBox(height: design.spacing.lg),
            _buildStatisticsCard(),
            SizedBox(height: design.spacing.sectionTop),
            _buildProfileAction(),
          ],
        ),
        showcase: showCases.isNotEmpty ? _buildShowCases() : null,
      ),
    );
  }

  Widget _buildIdentitySummary({
    required bool hasRemarkName,
    required bool hasDescription,
  }) {
    final info = _fullBlogData!.blogInfo;
    final idLabel = 'ID: ${info.blogName}'
        '${hasRemarkName ? appLocalizations.remarkSuffix(info.remarkName) : ''}';
    final gender = info.gendar == 1
        ? appLocalizations.male
        : info.gendar == 2
            ? appLocalizations.female
            : appLocalizations.confidential;
    final metadata = '${appLocalizations.gender}: $gender'
        '${StringUtil.isNotEmpty(info.ipLocation) ? '${appLocalizations.ipSuffix}${info.ipLocation}' : ''}';
    return LoftifyProfileIdentity(
      key: const ValueKey('user-profile-identity'),
      avatar: ItemBuilder.buildAvatar(
        context: context,
        size: StringUtil.isNotEmpty(getAvatarBoxImage()) ? 54 : 80,
        showBorder: false,
        showDetailMode: ShowDetailMode.avatar,
        imageUrl: Utils.removeImageParam(info.bigAvaImg),
        avatarBoxImageUrl: getAvatarBoxImage(),
        title: appLocalizations.personalAvatar,
        caption: '「${info.blogNickName}」',
        tagPrefix: 'user-profile-${info.blogId}',
      ),
      displayName: info.blogNickName,
      idLabel: idLabel,
      metadata: metadata,
      onDisplayNameLongPress: () => ChewieUtils.copy(
        context,
        info.blogNickName,
        toastText: appLocalizations.haveCopiedNickName,
      ),
      onIdLongPress: () => ChewieUtils.copy(
        context,
        info.blogName,
        toastText: appLocalizations.haveCopiedLofterID,
      ),
      descriptionLabel: hasDescription ? appLocalizations.moreInfo : null,
      onDescriptionPressed: hasDescription ? _showDescription : null,
      trailing: ResponsiveUtil.isLandscapeLayout()
          ? ChewieIconButton(
              icon: LoftifyIcons.moreVertical,
              tooltip: appLocalizations.moreInfo,
              foregroundColor: Colors.white,
              onPressed: () => BottomSheetBuilder.showContextMenu(
                context,
                _buildMoreButtons(),
              ),
            )
          : null,
    );
  }

  void _showDescription() {
    DialogBuilder.showInfoDialog(
      context,
      title: appLocalizations.descriptionTitle(
        _fullBlogData!.blogInfo.blogNickName,
      ),
      message: _fullBlogData!.blogInfo.selfIntro,
      onTapDismiss: () {},
      customDialogType: CustomDialogType.normal,
    );
  }

  Widget _buildStatisticsCard() {
    final info = _fullBlogData!.blogInfo;
    return ProfileOverviewCard(
      backgroundColor: Colors.black.withValues(alpha: 0.22),
      foregroundColor: Colors.white,
      statistics: [
        ProfileStatisticData(
          title: appLocalizations.following,
          count: info.blogStat.followingCount,
          onTap: _openFollowing,
        ),
        ProfileStatisticData(
          title: appLocalizations.follower,
          count: info.blogStat.followedCount,
          onTap: _openFollowers,
        ),
        ProfileStatisticData(
          title: appLocalizations.hotCount,
          count: info.hot.hotCount,
          onTap: _showHotDetails,
        ),
        ProfileStatisticData(
          title: appLocalizations.supporter,
          count: info.blogStat.supporterCount,
          onTap: _openSupporters,
        ),
      ],
    );
  }

  Widget _buildProfileAction() {
    final isOwnProfile = infoMode == InfoMode.me;
    return LoftifyProfileAction(
      onPressed: isOwnProfile
          ? () => UriUtil.openExternal(_fullBlogData!.blogInfo.homePageUrl)
          : _processFollow,
      label: isOwnProfile
          ? appLocalizations.openWithBrowser
          : _followButtonText.trim(),
      icon: isOwnProfile
          ? LoftifyIcons.openExternal
          : _fullBlogData!.isBlackBlog
              ? LoftifyIcons.block
              : LoftifyIcons.follow,
      emphasized: !isOwnProfile &&
          !_fullBlogData!.following &&
          !_fullBlogData!.isBlackBlog,
      danger: _fullBlogData!.isBlackBlog,
    );
  }

  void _openFollowing() {
    if (_fullBlogData!.showFollow == 1 || infoMode == InfoMode.me) {
      RouteUtil.pushPanelCupertinoRoute(
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
      IToast.showTop(appLocalizations.cannotViewFollowingList);
    }
  }

  void _openFollowers() {
    if (_fullBlogData!.showFans == 1 || infoMode == InfoMode.me) {
      RouteUtil.pushPanelCupertinoRoute(
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
      IToast.showTop(appLocalizations.cannotViewFollowerList);
    }
  }

  void _openSupporters() {
    if (_fullBlogData!.showSupport == 1 || infoMode == InfoMode.me) {
      RouteUtil.pushPanelCupertinoRoute(
        context,
        SupporterScreen(
          infoMode: infoMode,
          blogId: _fullBlogData!.blogInfo.blogId,
        ),
      );
    } else {
      IToast.showTop(appLocalizations.cannotViewSupporterList);
    }
  }

  void _showHotDetails() {
    final hot = _fullBlogData!.blogInfo.hot;
    DialogBuilder.showInfoDialog(
      context,
      title: '${appLocalizations.totalHotCount}${hot.hotCount}',
      messageChild: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHotItem(
            icon: LoftifyIcons.favorite,
            title: appLocalizations.postLikes,
            count: hot.favoriteCount,
          ),
          _buildHotItem(
            icon: LoftifyIcons.recommend,
            title: appLocalizations.postRecommends,
            count: hot.shareCount,
          ),
          _buildHotItem(
            icon: LoftifyIcons.bookmark,
            title: appLocalizations.postFavorites,
            count: hot.subscribeCount,
          ),
          _buildHotItem(
            icon: LoftifyIcons.comment,
            title: appLocalizations.commentLikes,
            count: hot.tagChatFavoriteCount,
          ),
        ],
      ),
      buttonText: appLocalizations.comeOn,
      onTapDismiss: () {},
      customDialogType: CustomDialogType.custom,
    );
  }

  void updateFollowStatus({bool rebuild = true}) {
    if (_fullBlogData!.following) {
      _followButtonText = _fullBlogData!.specialfollowing
          ? appLocalizations.specialFollowed
          : appLocalizations.followed;
    } else {
      _followButtonText = " ${appLocalizations.follow} ";
    }
    if (_fullBlogData!.isBlackBlog) {
      _followButtonText = appLocalizations.blacklisted;
    }
    if (rebuild && mounted) setState(() {});
  }

  Widget _buildHotItem({
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
              color: color ?? ChewieColors.getHotTagTextColor(context),
              shape: BoxShape.circle,
            ),
            child: ChewieIcon(icon, size: 12, color: Colors.white),
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

  void _doFollow({required bool isFollow}) {
    UserApi.followOrUnfollow(
      isFollow: isFollow,
      blogId: _fullBlogData!.blogInfo.blogId,
      blogName: _fullBlogData!.blogInfo.blogName,
    ).then((value) {
      if (!mounted) return;
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
      } else {
        _fullBlogData!.following = !_fullBlogData!.following;
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
      if (!mounted) return;
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

  void _doSpecialFollow({required bool isSpecialFollow}) {
    UserApi.specialFollowOrSpecialUnfollow(
      isSpecialFollow: isSpecialFollow,
      blogId: _fullBlogData!.blogInfo.blogId,
      blogName: _fullBlogData!.blogInfo.blogName,
    ).then((value) {
      if (!mounted) return;
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
      } else {
        _fullBlogData!.specialfollowing = !_fullBlogData!.specialfollowing;
        updateFollowStatus();
      }
    });
  }

  void _processFollow() {
    if (_fullBlogData!.isBlackBlog) {
      DialogBuilder.showConfirmDialog(
        context,
        title: appLocalizations.unlockBlacklist,
        message: appLocalizations
            .unlockBlacklistMessage(_fullBlogData!.blogInfo.blogNickName),
        confirmButtonText: appLocalizations.confirm,
        cancelButtonText: appLocalizations.cancel,
        onTapConfirm: () async {
          _doBlockUser(
              isBlock: !_fullBlogData!.isBlackBlog,
              onSuccess: () {
                if (!mounted) return;
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
        BottomSheetBuilder.showContextMenu(context, _buildFollowButtons());
      }
    }
  }

  FlutterContextMenu _buildFollowButtons() {
    return FlutterContextMenu(entries: [
      FlutterContextMenuItem(
          _fullBlogData!.specialfollowing
              ? appLocalizations.unSpecialFollow
              : appLocalizations.specialFollow,
          iconData: LoftifyIcons.specialFollow, onPressed: () {
        _doSpecialFollow(isSpecialFollow: !_fullBlogData!.specialfollowing);
      }),
      FlutterContextMenuItem(
        appLocalizations.unfollow,
        iconData: LoftifyIcons.unfollow,
        onPressed: () {
          _doFollow(isFollow: !_fullBlogData!.following);
        },
      ),
    ]);
  }

  Widget _buildTabView() {
    List<Widget> children = [];
    children.add(
      PostScreen(
        infoMode: InfoMode.other,
        blogId: _fullBlogData!.blogInfo.blogId,
        blogName: _fullBlogData!.blogInfo.blogName,
        nested: true,
      ),
    );
    if (_fullBlogData!.showLike == 1) {
      children.add(
        LikeScreen(
          infoMode: InfoMode.other,
          blogId: _fullBlogData!.blogInfo.blogId,
          blogName: _fullBlogData!.blogInfo.blogName,
          nested: true,
        ),
      );
    }
    if (_fullBlogData!.showShare == 1) {
      children.add(
        ShareScreen(
          infoMode: InfoMode.other,
          blogId: _fullBlogData!.blogInfo.blogId,
          blogName: _fullBlogData!.blogInfo.blogName,
          nested: true,
        ),
      );
    }
    children.add(
      CollectionScreen(
        infoMode: InfoMode.other,
        blogId: _fullBlogData!.blogInfo.blogId,
        blogName: _fullBlogData!.blogInfo.blogName,
        collectionCount: _fullBlogData!.collectionCount,
        nested: true,
      ),
    );
    if (_fullBlogData!.showFoods == 1) {
      children.add(
        GrainScreen(
          infoMode: InfoMode.other,
          blogId: _fullBlogData!.blogInfo.blogId,
          blogName: _fullBlogData!.blogInfo.blogName,
          nested: true,
        ),
      );
    }
    return Container(
      color: ChewieTheme.getBackground(context),
      child: TabBarView(
        controller: _tabController,
        children: children,
      ),
    );
  }

  Widget _buildShowCases() {
    final design = context.design;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final itemExtent = 112.0 + ((scale - 1).clamp(0, 1) * 24);
    return LoftifyCard(
      backgroundColor: Colors.black.withValues(alpha: 0.22),
      radius: design.radii.card,
      padding: EdgeInsets.all(design.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ChewieIcon(
                LoftifyIcons.premium,
                size: 16,
                color: Colors.white,
              ),
              SizedBox(width: design.spacing.sm),
              Expanded(
                child: Text(
                  appLocalizations.masterpiece,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: design.spacing.md),
          SizedBox(
            height: itemExtent,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: showCases.length,
              itemBuilder: (context, index) =>
                  _buildShowCaseItem(showCases[index], itemExtent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowCaseItem(ShowCaseItem item, double extent) {
    late String title;
    late String backgroundUrl;
    late String hotCount;
    late Function() onTap;
    if (item.postSimpleData != null) {
      title = item.postSimpleData!.postView.title;
      backgroundUrl = item.postSimpleData!.postView.firstImage.orign;
      hotCount = item.postSimpleData!.postCountView.hotCount.toString();
      if (title.isEmpty) {
        title =
            HtmlUtil.extractTextFromHtml(item.postSimpleData!.postView.digest);
      }
      onTap = () {
        item.postSimpleData!.postView.blogName =
            _fullBlogData!.blogInfo.blogName;
        RouteUtil.pushPanelCupertinoRoute(
          context,
          PostDetailScreen(
            showCaseItem: item,
            isArticle: StringUtil.isEmpty(backgroundUrl),
          ),
        );
      };
    } else if (item.postCollection != null) {
      title = item.postCollection!.name;
      backgroundUrl = item.postCollection!.coverUrl;
      hotCount = item.postCollection!.postCollectionHot.toString();
      onTap = () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          CollectionDetailScreen(
            blogId: widget.blogId,
            blogName: widget.blogName,
            collectionId: item.postCollection!.id,
            postId: item.postCollection!.id,
          ),
        );
      };
    } else {
      ILogger.info("Loftify", item.toJson());
    }
    final design = context.design;
    return Padding(
      padding: EdgeInsets.only(right: design.spacing.md),
      child: SizedBox(
        height: extent,
        width: extent,
        child: LoftifyCard(
          onTap: onTap,
          semanticLabel: '$title, $hotCount',
          radius: design.radii.control,
          backgroundColor: Colors.black.withValues(alpha: 0.18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              StringUtil.isNotEmpty(backgroundUrl)
                  ? ChewieItemBuilder.buildCachedImage(
                      context: context,
                      imageUrl: backgroundUrl,
                      height: extent,
                      width: extent,
                      fit: BoxFit.cover,
                      showLoading: false,
                      placeholderBackground: Colors.transparent,
                    )
                  : AssetUtil.loadDouble(
                      context,
                      AssetUtil.lofterDarkIllust,
                      AssetUtil.lofterDarkIllust,
                      size: extent,
                      fit: BoxFit.cover,
                    ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(design.spacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: design.spacing.xxl),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: design.typography.cardTitle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: design.spacing.xs),
                      Row(
                        children: [
                          const ChewieIcon(
                            LoftifyIcons.hot,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: design.spacing.xs),
                          Expanded(
                            child: Text(
                              hotCount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: design.typography.metadata.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: ChewieItemBuilder.buildCachedImage(
                  context: context,
                  imageUrl: item.icon,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  showLoading: false,
                  placeholderBackground: Colors.transparent,
                ),
              ),
              if (item.postCollection != null)
                Positioned(
                  top: design.spacing.sm,
                  left: design.spacing.sm,
                  child: const ChewieIcon(
                    LoftifyIcons.collection,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String get backgroudUrl =>
      _fullBlogData!.blogcover.customBlogCover ?? _fullBlogData!.blogcover.url;

  Widget _buildHeaderBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Blur(
          blur: 10,
          blurColor: Colors.black12,
          child: SizedBox.expand(
            child: ChewieItemBuilder.buildCachedImage(
              context: context,
              imageUrl: Utils.removeImageParam(backgroudUrl),
              fit: BoxFit.cover,
              placeholderBackground:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              bottomPadding: 50,
              showLoading: false,
            ),
          ),
        ),
        const LoftifyCoverScrim(),
      ],
    );
  }
}
