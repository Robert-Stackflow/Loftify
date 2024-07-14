import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:loftify/Api/github_api.dart';
import 'package:loftify/Models/nav_entry.dart';
import 'package:loftify/Resources/colors.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Navigation/dynamic_screen.dart';
import 'package:loftify/Screens/Navigation/home_screen.dart';
import 'package:loftify/Screens/Setting/setting_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Widgets/Dialog/custom_dialog.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:loftify/Widgets/LottieCupertinoRefresh/lottie_cupertino_refresh.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../Api/login_api.dart';
import '../Api/user_api.dart';
import '../Models/account_response.dart';
import '../Models/github_response.dart';
import '../Providers/global_provider.dart';
import '../Providers/provider_manager.dart';
import '../Resources/fonts.dart';
import '../Utils/hive_util.dart';
import '../Utils/iprint.dart';
import '../Utils/itoast.dart';
import '../Utils/lottie_util.dart';
import '../Utils/route_util.dart';
import '../Utils/utils.dart';
import '../Widgets/EasyRefresh/easy_refresh.dart';
import '../Widgets/Scaffold/my_bottom_navigation_bar.dart';
import '../Widgets/Scaffold/my_scaffold.dart';
import 'Info/dress_screen.dart';
import 'Info/system_notice_screen.dart';
import 'Info/user_detail_screen.dart';
import 'Lock/pin_verify_screen.dart';
import 'Post/search_result_screen.dart';

final GlobalKey<NavigatorState> desktopNavigatorKey =
    GlobalKey<NavigatorState>();

const borderColor = Color(0xFF805306);
const backgroundStartColor = Color(0xFFFFD500);
const backgroundEndColor = Color(0xFFF6A00C);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String routeName = "/";

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin {
  final List<Widget> _pageList = [];
  final List<GlobalKey> _keyList = [];
  final SortableItemList _navItemList = SortableItemList(
      items: ProviderManager.globalProvider.navItems,
      defaultItems: SortableItemList.defaultNavItems);
  final List<BottomNavigationBarItem> _navigationBarItemList = [];
  List<SortableItem> _navItems = [];
  Timer? _timer;
  int _bottomBarSelectedIndex = 0;
  final _pageController = PageController(keepPage: true);
  late AnimationController darkModeController;
  Widget? darkModeWidget;
  FullBlogInfo? blogInfo;
  bool clearNavSelectState = false;

  _fetchUserInfo() async {
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
            return IndicatorResult.success;
          }
        } catch (_) {
          if (mounted) IToast.showTop(context, text: "加载失败");
          return IndicatorResult.fail;
        } finally {}
      });
    }
    return IndicatorResult.success;
  }

  Future<void> initDeepLinks() async {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        UriUtil.processUrl(context, uri.toString(), pass: false);
      }
    }, onError: (Object err) {
      IPrint.debug('Failed to get URI: $err');
    });
  }

  Future<void> fetchReleases() async {
    String currentVersion = "";
    String latestVersion = "";
    ReleaseItem? latestReleaseItem;
    await PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        currentVersion = packageInfo.version;
      });
    });
    GithubApi.getReleases("Robert-Stackflow", "Loftify").then((releases) async {
      for (var release in releases) {
        String tagName = release.tagName;
        tagName = tagName.replaceAll(RegExp(r'[a-zA-Z]'), '');
        setState(() {
          if (latestVersion.compareTo(tagName) < 0) {
            latestVersion = tagName;
            latestReleaseItem = release;
          }
        });
      }
      if (latestVersion.compareTo(currentVersion) > 0 &&
          latestReleaseItem != null) {
        CustomConfirmDialog.showAnimatedFromBottom(
          context,
          title: "发现新版本$latestVersion",
          message:
              "是否立即更新？${Utils.isNotEmpty(latestReleaseItem!.body) ? "更新日志如下：\n${latestReleaseItem!.body}" : ""}",
          confirmButtonText: "立即下载",
          cancelButtonText: "暂不更新",
          onTapConfirm: () {
            Utils.downloadAndUpdate(
              context,
              latestReleaseItem!.assets.isNotEmpty
                  ? latestReleaseItem!.assets[0].browserDownloadUrl
                  : "",
              latestReleaseItem!.htmlUrl,
              version: latestVersion,
            );
          },
          onTapCancel: () {},
          customDialogType: CustomDialogType.normal,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (Utils.isDesktop()) {
      _fetchUserInfo();
    }
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      darkModeWidget = LottieUtil.load(
        LottieUtil.sunLight,
        size: 25,
        autoForward: !Utils.isDark(context),
        controller: darkModeController,
      );
    });
    FontEnum.downloadFont(showToast: false);
    initDeepLinks();
    if (HiveUtil.getBool(key: HiveUtil.autoCheckUpdateKey)) fetchReleases();
    WidgetsBinding.instance.addObserver(this);
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: Theme.of(context).canvasColor,
          indicator: LottieUtil.load(LottieUtil.getLoadingPath(context)),
          hapticFeedback: true,
          triggerOffset: 40,
        );
    EasyRefresh.defaultFooterBuilder = () => LottieCupertinoFooter(
          indicator: LottieUtil.load(LottieUtil.getLoadingPath(context)),
        );
    if (Utils.isMobile()) {
      if (HiveUtil.getBool(
          key: HiveUtil.enableSafeModeKey, defaultValue: false)) {
        FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } else {
        FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      goLogin();
      goPinVerify();
    });
    fetchData();
    ProviderManager.globalProvider.addListener(() {
      // initData();
      setState(() {
        clearNavSelectState = ProviderManager.globalProvider.desktopCanpop;
      });
    });
  }

  Future<void> fetchData() async {
    await LoginApi.uploadNewDevice();
    await LoginApi.autoLogin();
    await LoginApi.getConfigs();
  }

  void initData() {
    _pageList.clear();
    _navigationBarItemList.clear();
    _navItems = _navItemList.getShownItems();
    for (SortableItem item in _navItems) {
      _navigationBarItemList.add(
        BottomNavigationBarItem(
          icon: AssetUtil.loadDouble(
            context,
            item.lightIcon,
            item.darkIcon,
            size: 30,
          ),
          activeIcon: AssetUtil.loadDouble(
            context,
            item.lightSelectedIcon,
            item.darkSelectedIcon,
            size: 30,
          ),
          label: SortableItemList.getNavItemLabel(item.id),
        ),
      );
      _pageList.add(SortableItemList.getNavItemPage(item.id));
      _keyList.add(SortableItemList.getNavItemKey(item.id));
    }
    _bottomBarSelectedIndex =
        min(_navItems.length - 1, _bottomBarSelectedIndex);
    setState(() {});
  }

  void onBottomNavigationBarItemTap(int index) {
    if (index == _bottomBarSelectedIndex &&
        _pageList[index] is HomeScreen &&
        _keyList[index].currentState != null) {
      (_keyList[index].currentState as HomeScreenState).scrollToTopAndRefresh();
    } else if (index == _bottomBarSelectedIndex &&
        _pageList[index] is DynamicScreen &&
        _keyList[index].currentState != null) {
      (_keyList[index].currentState as DynamicScreenState)
          .scrollToTopAndRefresh();
    }
    if (Utils.isMobile()) {
      _pageController.jumpToPage(index);
    } else {
      if (ProviderManager.globalProvider.desktopCanpop ||
          ProviderManager.globalProvider.bottomBarSelectedIndex != index) {
        ProviderManager.globalProvider.bottomBarSelectedIndex = index;
        RouteUtil.pushDesktopFadeRoute(_pageList[index], removeUtil: true);
      }
    }
    setState(() {
      _bottomBarSelectedIndex = index;
    });
  }

  void goLogin() {
    if (HiveUtil.isFirstLogin() &&
        HiveUtil.getString(key: HiveUtil.tokenKey, defaultValue: null) ==
            null) {
      HiveUtil.initConfig();
      HiveUtil.setFirstLogin();
      RouteUtil.pushCupertinoRoute(
        context,
        const LoginByCaptchaScreen(),
      );
    }
  }

  void goPinVerify() {
    if (HiveUtil.shouldAutoLock()) {
      RouteUtil.pushCupertinoRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {},
          isModal: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildBodyByPlatform();
  }

  _buildBodyByPlatform() {
    if (Utils.isMobile()) {
      return _buildMobileBody();
    } else {
      return _buildDesktopBody();
    }
  }

  _buildMobileBody() {
    return FutureBuilder(
      future: Future.sync(() => initData()),
      builder: (_, __) => MyScaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _pageList,
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: _bottomBarSelectedIndex,
          backgroundColor: Theme.of(context).canvasColor,
          items: _navigationBarItemList,
          elevation: 0,
          unselectedItemColor: Theme.of(context).textTheme.labelSmall?.color,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          onTap: onBottomNavigationBarItemTap,
          onDoubleTap: onBottomNavigationBarItemTap,
        ),
      ),
    );
  }

  _buildDesktopBody() {
    return FutureBuilder(
      future: Future.sync(() => initData()),
      builder: (_, __) => MyScaffold(
        body: Row(
          children: [_sideBar(), _desktopMainContent()],
        ),
      ),
    );
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

  _sideBar() {
    return SizedBox(
      width: 65,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            MoveWindow(),
            Column(
              children: [
                const SizedBox(height: 17),
                Selector<GlobalProvider, bool>(
                  selector: (context, globalProvider) =>
                      globalProvider.desktopCanpop,
                  builder: (context, desktopCanpop, child) => MouseRegion(
                    cursor: desktopCanpop
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                      onTap: () {
                        if (desktopNavigatorKey.currentState != null &&
                            desktopNavigatorKey.currentState!.canPop()) {
                          desktopNavigatorKey.currentState?.pop();
                          ProviderManager.globalProvider.desktopCanpop =
                              desktopNavigatorKey.currentState!.canPop();
                        } else {
                          ProviderManager.globalProvider.desktopCanpop =
                              desktopNavigatorKey.currentState?.canPop() ??
                                  false;
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(9.5),
                        decoration: BoxDecoration(
                          color: desktopCanpop
                              ? Colors.grey.withAlpha(40)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: desktopCanpop
                              ? Theme.of(context).iconTheme.color
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                MyBottomNavigationBar(
                  currentIndex: _bottomBarSelectedIndex,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  items: _navigationBarItemList,
                  clearNavSelectState: clearNavSelectState,
                  direction: Axis.vertical,
                  elevation: 0,
                  unselectedItemColor:
                      Theme.of(context).textTheme.labelSmall?.color,
                  selectedItemColor: Theme.of(context).primaryColor,
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  selectedLabelStyle: const TextStyle(fontSize: 12),
                  onTap: onBottomNavigationBarItemTap,
                  onDoubleTap: onBottomNavigationBarItemTap,
                ),
                const Spacer(),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (blogInfo == null) {
                          RouteUtil.pushDesktopFadeRoute(
                              const LoginByCaptchaScreen());
                        } else {
                          RouteUtil.pushDesktopFadeRoute(
                            UserDetailScreen(
                                blogId: blogInfo!.blogId,
                                blogName: blogInfo!.blogName),
                          );
                        }
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ItemBuilder.buildAvatar(
                          showLoading: false,
                          context: context,
                          imageUrl: blogInfo?.bigAvaImg ?? "",
                          useDefaultAvatar: blogInfo == null,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 2),
                    ItemBuilder.buildIconButton(
                        context: context,
                        icon: AssetUtil.loadDouble(
                          context,
                          AssetUtil.dressLightIcon,
                          AssetUtil.dressDarkIcon,
                        ),
                        onTap: () {
                          RouteUtil.pushDesktopFadeRoute(const DressScreen());
                        }),
                    const SizedBox(width: 6),
                    ItemBuilder.buildIconButton(
                      context: context,
                      icon: Icon(
                        Icons.mail_outline_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onTap: () {
                        RouteUtil.pushDesktopFadeRoute(
                            const SystemNoticeScreen());
                      },
                    ),
                    ItemBuilder.buildDynamicIconButton(
                        context: context,
                        icon: AssetUtil.loadDouble(
                          context,
                          AssetUtil.settingLightIcon,
                          AssetUtil.settingDarkIcon,
                        ),
                        onTap: () async {
                          RouteUtil.pushDesktopFadeRoute(const SettingScreen());
                        }),
                    const SizedBox(height: 15),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  _desktopMainContent() {
    return Expanded(
      child: Column(
        children: [
          WindowTitleBarBox(
            titleBarHeightDelta: 40,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: Row(
              children: [
                SizedBox(
                  width: min(300, MediaQuery.sizeOf(context).width - 240),
                  child: ItemBuilder.buildDesktopSearchBar(
                      context: context,
                      controller: TextEditingController(),
                      background: Colors.grey.withAlpha(40),
                      hintText: "搜索感兴趣的内容",
                      borderRadius: 8,
                      bottomMargin: 18,
                      hintFontSizeDelta: 1,
                      onSubmitted: (text) {
                        RouteUtil.pushDesktopFadeRoute(
                            SearchResultScreen(searchKey: text));
                      }),
                ),
                const Spacer(),
                Row(
                  children: [
                    MinimizeWindowButton(
                      colors: MyColors.getNormalButtonColors(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    appWindow.isMaximized
                        ? RestoreWindowButton(
                            colors: MyColors.getNormalButtonColors(context),
                            borderRadius: BorderRadius.circular(10),
                            onPressed: maximizeOrRestore,
                          )
                        : MaximizeWindowButton(
                            colors: MyColors.getNormalButtonColors(context),
                            borderRadius: BorderRadius.circular(10),
                            onPressed: maximizeOrRestore,
                          ),
                    CloseWindowButton(
                      colors: MyColors.getNormalButtonColors(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Navigator(
                  key: desktopNavigatorKey,
                  onGenerateRoute: (settings) {
                    if (settings.name == "/") {
                      return PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (BuildContext context,
                            Animation<double> animation,
                            Animation secondaryAnimation) {
                          return FadeTransition(
                            opacity: CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                            child: _pageList[0],
                          );
                        },
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void cancleTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void setTimer() {
    _timer = Timer(
      Duration(minutes: ProviderManager.globalProvider.autoLockTime),
      goPinVerify,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        fetchData();
        cancleTimer();
        break;
      case AppLifecycleState.paused:
        setTimer();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    darkModeController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
