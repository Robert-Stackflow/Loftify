import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:loftify/Models/nav_entry.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Navigation/dynamic_screen.dart';
import 'package:loftify/Screens/Navigation/home_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/constant.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:loftify/Widgets/Window/window_caption.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../Api/login_api.dart';
import '../Api/user_api.dart';
import '../Models/account_response.dart';
import '../Resources/fonts.dart';
import '../Utils/app_provider.dart';
import '../Utils/enums.dart';
import '../Utils/hive_util.dart';
import '../Utils/ilogger.dart';
import '../Utils/itoast.dart';
import '../Utils/lottie_util.dart';
import '../Utils/route_util.dart';
import '../Utils/utils.dart';
import '../Widgets/Dialog/dialog_builder.dart';
import '../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../Widgets/General/LottieCupertinoRefresh/lottie_cupertino_refresh.dart';
import '../Widgets/Scaffold/my_bottom_navigation_bar.dart';
import '../Widgets/Scaffold/my_scaffold.dart';
import 'Info/dress_screen.dart';
import 'Info/system_notice_screen.dart';
import 'Info/user_detail_screen.dart';
import 'Lock/pin_verify_screen.dart';
import 'Post/search_result_screen.dart';
import 'Post/search_screen.dart';
import 'Setting/setting_screen.dart';

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
        TrayListener,
        WindowListener,
        AutomaticKeepAliveClientMixin {
  final List<Widget> _pageList = [];
  final List<GlobalKey> _keyList = [];
  final SortableItemList _navItemList = SortableItemList(
      items: appProvider.navItems,
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
  bool _isMaximized = false;
  bool _isStayOnTop = false;
  bool _hasJumpedToPinVerify = false;
  late Navigator navigator;
  late PageView pageView;

  @override
  void onWindowMinimize() {
    setTimer();
    super.onWindowMinimize();
  }

  @override
  void onWindowRestore() {
    super.onWindowRestore();
    cancleTimer();
  }

  @override
  void onWindowFocus() {
    cancleTimer();
    super.onWindowFocus();
  }

  @override
  Future<void> onWindowResized() async {
    super.onWindowResized();
    HiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowMoved() async {
    super.onWindowMoved();
    HiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  void onWindowEvent(String eventName) {
    super.onWindowEvent(eventName);
    if (eventName == "hide") {
      setTimer();
    }
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
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
            return IndicatorResult.success;
          }
        } catch (e, t) {
          ILogger.error("Failed to load user info", e, t);
          if (mounted) IToast.showTop("加载失败");
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
      ILogger.error('Failed to get URI: $err');
    });
  }

  Future<void> fetchReleases() async {
    if (HiveUtil.getBool(HiveUtil.autoCheckUpdateKey)) {
      Utils.getReleases(
        context: context,
        showLoading: false,
        showUpdateDialog: true,
        showNoUpdateToast: false,
      );
    }
  }

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initDeepLinks();
    CustomFont.downloadFont(showToast: false);
    if (ResponsiveUtil.isLandscape()) _fetchUserInfo();
    if (ResponsiveUtil.isDesktop()) initHotKey();
    if (HiveUtil.getBool(HiveUtil.autoCheckUpdateKey)) fetchReleases();
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      jumpToLogin();
      jumpToPinVerify(autoAuth: true);
      darkModeWidget = LottieUtil.load(
        LottieUtil.sunLight,
        size: 25,
        autoForward: !Utils.isDark(context),
        controller: darkModeController,
      );
    });
    initGlobalConfig();
    fetchData();
    appProvider.addListener(() {
      if (mounted) {
        setState(() {
          clearNavSelectState = appProvider.canPopByProvider;
        });
      }
    });
    navigator = Navigator(
      key: desktopNavigatorKey,
      onGenerateRoute: (settings) {
        return RouteUtil.getFadeRoute(_pageList[0]);
      },
    );
    pageView = PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: _pageList,
    );
  }

  initGlobalConfig() {
    if (ResponsiveUtil.isDesktop()) {
      windowManager
          .isAlwaysOnTop()
          .then((value) => setState(() => _isStayOnTop = value));
      windowManager
          .isMaximized()
          .then((value) => setState(() => _isMaximized = value));
    }
    ResponsiveUtil.checkSizeCondition();
    if (mounted) {
      EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
            backgroundColor: Theme.of(context).canvasColor,
            indicator: LottieUtil.load(LottieUtil.getLoadingPath(context)),
            hapticFeedback: true,
            triggerOffset: 40,
          );
      EasyRefresh.defaultFooterBuilder = () => LottieCupertinoFooter(
            indicator: LottieUtil.load(LottieUtil.getLoadingPath(context)),
          );
    }
    if (ResponsiveUtil.isMobile()) {
      if (HiveUtil.getBool(HiveUtil.enableSafeModeKey, defaultValue: false)) {
        FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } else {
        FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    }
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
    bool canRefresh = ((ResponsiveUtil.isMobile() &&
                !ResponsiveUtil.isLandscape()) ||
            (ResponsiveUtil.isLandscape() && !appProvider.canPopByProvider)) &&
        _bottomBarSelectedIndex == index;
    if (canRefresh) {
      var page = _pageList[index];
      var currentState = _keyList[index].currentState;
      if (page is HomeScreen && currentState != null) {
        (currentState as HomeScreenState).scrollToTopAndRefresh();
      } else if (page is DynamicScreen && currentState != null) {
        (currentState as DynamicScreenState).scrollToTopAndRefresh();
      }
    }
    if (ResponsiveUtil.isLandscape()) {
      appProvider.canPopByProvider = false;
      if (!canRefresh) {
        RouteUtil.pushDesktopFadeRoute(_pageList[index], removeUtil: true);
      }
    } else {
      _pageController.jumpToPage(index);
    }
    setState(() {
      _bottomBarSelectedIndex = index;
    });
  }

  void jumpToLogin() {
    if (HiveUtil.isFirstLogin() &&
        HiveUtil.getString(HiveUtil.tokenKey, defaultValue: null) == null) {
      HiveUtil.initConfig();
      HiveUtil.setFirstLogin();
      if (ResponsiveUtil.isLandscape()) {
        DialogBuilder.showPageDialog(context,
            child: const LoginByCaptchaScreen());
      } else {
        RouteUtil.pushCupertinoRoute(context, const LoginByCaptchaScreen());
      }
    }
  }

  void jumpToPinVerify({bool autoAuth = false}) {
    if (HiveUtil.shouldAutoLock()) {
      _hasJumpedToPinVerify = true;
      RouteUtil.pushCupertinoRoute(
          context,
          PinVerifyScreen(
            onSuccess: () {},
            isModal: true,
            autoAuth: autoAuth,
          ), onThen: (_) {
        _hasJumpedToPinVerify = false;
      });
    }
  }

  initHotKey() async {
    HotKey hotKey = HotKey(
      key: PhysicalKeyboardKey.keyC,
      modifiers: [HotKeyModifier.alt],
      scope: HotKeyScope.inapp,
    );
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        RouteUtil.pushDesktopFadeRoute(const SettingScreen());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: !appProvider.canPopByProvider,
      onPopInvoked: (_) {
        if (canPopByKey) {
          desktopNavigatorState?.pop();
        }
        appProvider.canPopByProvider = canPopByKey;
      },
      child: _buildBodyByPlatform(),
    );
  }

  _buildBodyByPlatform() {
    if (!ResponsiveUtil.isLandscape()) {
      return _buildMobileBody();
    } else if (ResponsiveUtil.isMobile()) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(child: _buildDesktopBody()),
      );
    } else {
      return _buildDesktopBody();
    }
  }

  _buildMobileBody() {
    return FutureBuilder(
      future: Future.sync(() => initData()),
      builder: (_, __) => MyScaffold(
        body: pageView,
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
        resizeToAvoidBottomInset: false,
        body: Row(
          children: [_sideBar(), _desktopMainContent()],
        ),
      ),
    );
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

  _sideBar() {
    return SizedBox(
      width: 56,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            if (ResponsiveUtil.isDesktop()) const WindowMoveHandle(),
            Column(
              children: [
                const SizedBox(height: 80),
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
                          DialogBuilder.showPageDialog(
                            context,
                            child: const LoginByCaptchaScreen(),
                          );
                        } else {
                          RouteUtil.pushDesktopFadeRoute(
                            UserDetailScreen(
                                blogId: blogInfo!.blogId,
                                blogName: blogInfo!.blogName),
                          );
                        }
                      },
                      child: ItemBuilder.buildClickItem(
                        ItemBuilder.buildAvatar(
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
                      },
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _desktopMainContent() {
    return Expanded(
      child: Column(
        children: [
          ItemBuilder.buildWindowTitle(
            context,
            isStayOnTop: _isStayOnTop,
            isMaximized: _isMaximized,
            leftWidgets: [
              Selector<AppProvider, bool>(
                selector: (context, globalProvider) =>
                    globalProvider.canPopByProvider,
                builder: (context, desktopCanpop, child) => MouseRegion(
                  cursor: desktopCanpop
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: ItemBuilder.buildRoundIconButton(
                    context: context,
                    disabled: !desktopCanpop,
                    normalBackground: Colors.grey.withAlpha(40),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: desktopCanpop
                          ? Theme.of(context).iconTheme.color
                          : Colors.grey,
                    ),
                    onTap: () {
                      if (canPopByKey) {
                        desktopNavigatorState?.pop();
                      }
                      appProvider.canPopByProvider = canPopByKey;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ItemBuilder.buildRoundIconButton(
              //   context: context,
              //   normalBackground: Colors.grey.withAlpha(40),
              //   icon: Icon(
              //     Icons.home_filled,
              //     size: 20,
              //     color: Theme.of(context).iconTheme.color,
              //   ),
              //   onTap: () {
              //     ProviderManager.globalProvider.desktopCanpop = false;
              //     desktopNavigatorKey =
              //         GlobalKey<NavigatorState>();
              //   },
              // ),
              // const SizedBox(width: 8),
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
                      if (Utils.isNotEmpty(text)) {
                        RouteUtil.pushDesktopFadeRoute(
                            SearchResultScreen(searchKey: text));
                      } else {
                        RouteUtil.pushDesktopFadeRoute(const SearchScreen());
                      }
                    }),
              ),
            ],
            onStayOnTopTap: () {
              setState(() {
                _isStayOnTop = !_isStayOnTop;
                windowManager.setAlwaysOnTop(_isStayOnTop);
              });
            },
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: navigator,
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
    if (!_hasJumpedToPinVerify) {
      _timer = Timer(
        Duration(minutes: appProvider.autoLockTime),
        () {
          jumpToPinVerify();
        },
      );
    }
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
    trayManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    darkModeController.dispose();
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
    windowManager.restore();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
      windowManager.restore();
    } else if (menuItem.key == 'lock_window') {
      if (HiveUtil.canLock()) {
        _hasJumpedToPinVerify = true;
        RouteUtil.pushCupertinoRoute(
            context,
            PinVerifyScreen(
              onSuccess: () {},
              isModal: true,
              autoAuth: false,
            ), onThen: (_) {
          _hasJumpedToPinVerify = false;
        });
      } else {
        windowManager.show();
        windowManager.focus();
        windowManager.restore();
        IToast.showTop("尚未设置手势密码");
      }
    } else if (menuItem.key == 'show_official_website') {
      UriUtil.launchUrlUri(context, officialWebsite);
    } else if (menuItem.key == 'show_github_repo') {
      UriUtil.launchUrlUri(context, repoUrl);
    } else if (menuItem.key == 'exit_app') {
      windowManager.close();
    }
  }

  @override
  bool get wantKeepAlive => true;
}
