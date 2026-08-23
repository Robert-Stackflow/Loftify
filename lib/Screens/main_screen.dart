import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:loftify/Api/server_api.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/panel_screen.dart';
import 'package:loftify/Utils/cloud_control_provider.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:loftify/Widgets/loftify_icons.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/l10n.dart';
import '../Api/login_api.dart';
import '../Api/user_api.dart';
import '../Models/account_response.dart';
import '../Utils/app_provider.dart';
import '../Utils/enums.dart';
import '../Utils/hive_util.dart';
import '../Utils/utils.dart';
import 'Info/system_notice_screen.dart';
import 'Info/user_detail_screen.dart';
import 'Lock/pin_verify_screen.dart';
import 'Setting/setting_screen.dart';
import 'Suit/suit_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String routeName = "/";

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends BaseWindowState<MainScreen>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        TrayListener,
        AutomaticKeepAliveClientMixin {
  Timer? _timer;
  late AnimationController darkModeController;
  Widget? darkModeWidget;
  FullBlogInfo? blogInfo;
  bool _hasJumpedToPinVerify = false;
  bool _orientationPolicyUpdateScheduled = false;
  Orientation? _oldOrientation;

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
  void onWindowEvent(String eventName) {
    super.onWindowEvent(eventName);
    if (eventName == "hide") {
      setTimer();
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
            await ChewieHiveUtil.put(
                HiveUtil.userIdKey, accountResponse.blogs[0].blogInfo?.blogId);
            setState(() {
              blogInfo = accountResponse.blogs[0].blogInfo;
            });
            return IndicatorResult.success;
          }
        } catch (e, t) {
          ILogger.error("Failed to load user info", e, t);
          if (mounted) IToast.showTop(appLocalizations.loadFailed);
          return IndicatorResult.fail;
        } finally {}
      });
    }
    if (mounted) setState(() {});
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

  login() {
    dialogNavigatorState?.popAll();
    panelScreenState?.login();
    _fetchUserInfo();
  }

  logout() {
    panelScreenState?.logout();
    blogInfo = null;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      showQQGroupDialog();
      jumpToLogin();
      darkModeWidget = LottieUtil.load(
        LottieFiles.sunLight,
        size: 25,
        autoForward: !ColorUtil.isDark(context),
        controller: darkModeController,
      );
      ResponsiveUtil.runByPlatform(desktop: () async {
        await Utils.initTray();
        trayManager.addListener(this);
        appProvider.shortcutFocusNode.requestFocus();
      });
    });
    initConfig();
    fetchBasicData();
    fetchData();
  }

  void fetchBasicData() {
    ServerApi.getCloudControl();
    CustomFont.downloadFont(showToast: false);
    _fetchUserInfo();
    if (ChewieHiveUtil.getBool(HiveUtil.autoCheckUpdateKey)) {
      ChewieUtils.getReleases(
        context: context,
        showLoading: false,
        showUpdateDialog: true,
        showFailedToast: false,
        showLatestToast: false,
      );
    }
  }

  Future<void> fetchData() async {
    await LoginApi.uploadNewDevice();
    await LoginApi.autoLogin();
    await LoginApi.getConfigs();
  }

  initConfig() {
    unawaited(ResponsiveUtil.checkSizeCondition());
    ResponsiveUtil.runByPlatform(
      desktop: () {
        initHotKey();
        windowManager
            .isAlwaysOnTop()
            .then((value) => setState(() => isStayOnTop = value));
        windowManager
            .isMaximized()
            .then((value) => setState(() => isMaximized = value));
      },
      mobile: () {
        ChewieUtils.setSafeMode(ChewieHiveUtil.getBool(
            HiveUtil.enableSafeModeKey,
            defaultValue: false));
      },
    );
    initDeepLinks();
    initEasyRefresh();
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
        RouteUtil.pushPanelCupertinoRoute(rootContext, const SettingScreen());
      },
    );
  }

  initEasyRefresh() {
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(36, false),
          hapticFeedback: true,
          triggerOffset: 52,
          maxOverOffset: 76,
          radius: 18,
        );
    EasyRefresh.defaultFooterBuilder = () => LottieCupertinoFooter(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(32, false),
          triggerOffset: 48,
          maxOverOffset: 68,
          infiniteOffset: 240,
          radius: 16,
        );
    chewieProvider.loadingWidgetBuilder = LottieFiles.buildLoadingAnimation;
  }

  showQQGroupDialog() {
    bool haveShownQQGroupDialog = ChewieHiveUtil.getBool(
        HiveUtil.haveShownQQGroupDialogKey,
        defaultValue: false);
    if (!haveShownQQGroupDialog) {
      ChewieHiveUtil.put(HiveUtil.haveShownQQGroupDialogKey, true);
      DialogBuilder.showConfirmDialog(
        context,
        title: appLocalizations.feedbackWelcome,
        message: appLocalizations.feedbackWelcomeMessage,
        messageTextAlign: TextAlign.center,
        confirmButtonText: appLocalizations.goToQQ,
        cancelButtonText: appLocalizations.joinLater,
        onTapConfirm: () {
          UriUtil.openExternal(controlProvider.globalControl.qqGroupUrl);
        },
      );
    }
  }

  void jumpToLogin() {
    if (ChewieHiveUtil.isFirstLogin() &&
        ChewieHiveUtil.getString(HiveUtil.tokenKey, defaultValue: null) ==
            null) {
      HiveUtil.initConfig();
      ChewieHiveUtil.setFirstLogin();
      if (ResponsiveUtil.isLandscapeLayout()) {
        DialogBuilder.showPageDialog(context,
            child: const LoginByCaptchaScreen());
      } else {
        RouteUtil.pushPanelCupertinoRoute(
            context, const LoginByCaptchaScreen());
      }
    }
  }

  void jumpToLock({bool autoAuth = false}) {
    if (HiveUtil.shouldAutoLock()) {
      _hasJumpedToPinVerify = true;
      RouteUtil.pushCupertinoRoute(
          context,
          PinVerifyScreen(
            isModal: true,
            autoAuth: autoAuth,
            showWindowTitle: true,
          ), onThen: (_) {
        _hasJumpedToPinVerify = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return OrientationBuilder(builder: (context, orientation) {
      if (_oldOrientation != null && orientation != _oldOrientation) {
        // ResponsiveUtil.returnToMainScreen(context);
      }
      _oldOrientation = orientation;
      return ResponsiveUtil.selectByResponsive(
        landscape: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: ChewieTheme.scaffoldBackgroundColor,
          body: SafeArea(child: _buildDesktopBody()),
        ),
        desktop: _buildDesktopBody(),
        portrait: PanelScreen(key: panelScreenKey),
      );
    });
  }

  _buildDesktopBody() {
    return Row(
      children: [
        _sideBar(leftPadding: 8, rightPadding: 8),
        Expanded(
          child: Stack(
            children: [
              PanelScreen(key: panelScreenKey),
              Positioned(
                right: 0,
                child: _titleBar(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _buildAvatarContextMenuButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.viewPersonalHomepage,
          iconData: LoftifyIcons.profile,
          onPressed: () async {
            panelScreenState?.pushPage(UserDetailScreen(
              blogId: blogInfo!.blogId,
              blogName: blogInfo!.blogName,
            ));
          },
        ),
        FlutterContextMenuItem.divider(),
        FlutterContextMenuItem(
          appLocalizations.logout,
          status: MenuItemStatus.warning,
          iconData: LoftifyIcons.logout,
          onPressed: () async {
            HiveUtil.confirmLogout(context);
          },
        ),
      ],
    );
  }

  _titleBar() {
    return ResponsiveUtil.selectByPlatform(
      desktop: WindowTitleWrapper(
        backgroundColor: Colors.transparent,
        isStayOnTop: isStayOnTop,
        isMaximized: isMaximized,
        onStayOnTopTap: () {
          setState(() {
            isStayOnTop = !isStayOnTop;
            windowManager.setAlwaysOnTop(isStayOnTop);
          });
        },
        rightButtons: const [],
      ),
    );
  }

  changeMode() {
    if (ColorUtil.isDark(context)) {
      appProvider.themeMode = ActiveThemeMode.light;
      darkModeController.forward();
    } else {
      appProvider.themeMode = ActiveThemeMode.dark;
      darkModeController.reverse();
    }
  }

  _sideBar({
    double leftPadding = 0,
    double rightPadding = 0,
  }) {
    return Container(
      width: 42 + leftPadding + rightPadding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
      child: Stack(
        children: [
          ResponsiveUtil.selectByPlatform(desktop: const WindowMoveHandle()),
          Consumer<LoftifyControlProvider>(
            builder: (_, cloudControlProvider, __) =>
                Selector<AppProvider, SideBarChoice>(
              selector: (context, appProvider) => appProvider.sidebarChoice,
              builder: (context, sidebarChoice, child) =>
                  Selector<AppProvider, bool>(
                selector: (context, appProvider) =>
                    !appProvider.showPanelNavigator,
                builder: (context, hideNavigator, child) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ResponsiveUtil.selectByPlatform(
                        desktop: const SizedBox(height: 5)),
                    ResponsiveUtil.selectByPlatform(desktop: _buildLogo()),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected:
                          hideNavigator && sidebarChoice == SideBarChoice.Home,
                      icon: LoftifyIcons.home,
                      selectedIcon: LoftifyIcons.home,
                      onPressed: () async {
                        appProvider.sidebarChoice = SideBarChoice.Home;
                        panelScreenState?.popAll(false);
                      },
                      iconSize: 24,
                    ),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected: hideNavigator &&
                          sidebarChoice == SideBarChoice.Search,
                      icon: LoftifyIcons.search,
                      selectedIcon: LoftifyIcons.search,
                      onPressed: () async {
                        appProvider.sidebarChoice = SideBarChoice.Search;
                        panelScreenState?.popAll(false);
                      },
                    ),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected: hideNavigator &&
                          sidebarChoice == SideBarChoice.Dynamic,
                      icon: LoftifyIcons.activity,
                      selectedIcon: LoftifyIcons.activity,
                      onPressed: () async {
                        appProvider.sidebarChoice = SideBarChoice.Dynamic;
                        panelScreenState?.popAll(false);
                      },
                    ),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected:
                          hideNavigator && sidebarChoice == SideBarChoice.Mine,
                      icon: LoftifyIcons.profile,
                      selectedIcon: LoftifyIcons.profile,
                      onPressed: () async {
                        appProvider.sidebarChoice = SideBarChoice.Mine;
                        panelScreenState?.popAll(false);
                      },
                    ),
                    const Spacer(),
                    const SizedBox(height: 8),
                    ClickableGestureDetector(
                      onTap: () async {
                        if (blogInfo == null) {
                          RouteUtil.pushDialogRoute(
                              context, const LoginByCaptchaScreen());
                        } else {
                          BottomSheetBuilder.showContextMenu(
                              context, _buildAvatarContextMenuButtons());
                        }
                      },
                      child: ItemBuilder.buildAvatar(
                        showLoading: false,
                        context: context,
                        imageUrl: blogInfo?.bigAvaImg ?? "",
                        useDefaultAvatar: blogInfo == null,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ItemBuilder.buildDynamicToolButton(
                      context: context,
                      iconBuilder: (colors) => darkModeWidget ?? emptyWidget,
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
                      },
                    ),
                    const SizedBox(height: 2),
                    if (cloudControlProvider.globalControl.showDress) ...[
                      ToolButton(
                        context: context,
                        icon: LoftifyIcons.dress,
                        onPressed: () {
                          RouteUtil.pushPanelCupertinoRoute(
                              context, const SuitScreen());
                        },
                      ),
                      const SizedBox(height: 2),
                    ],
                    ToolButton(
                      context: context,
                      icon: LoftifyIcons.notifications,
                      onPressed: () {
                        RouteUtil.pushPanelCupertinoRoute(
                            context, const SystemNoticeScreen());
                      },
                    ),
                    const SizedBox(height: 2),
                    ToolButton(
                      context: context,
                      icon: LoftifyIcons.settings,
                      onPressed: () {
                        RouteUtil.pushPanelCupertinoRoute(
                            context, const SettingScreen());
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildLogo({
    double size = 50,
  }) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/logo-transparent.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
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
        Duration(seconds: appProvider.autoLockSeconds),
        () {
          jumpToLock();
        },
      );
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!ResponsiveUtil.isMobile() || _orientationPolicyUpdateScheduled) {
      return;
    }
    _orientationPolicyUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orientationPolicyUpdateScheduled = false;
      if (mounted) {
        unawaited(ResponsiveUtil.checkSizeCondition());
      }
    });
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
    ChewieUtils.displayApp();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    Utils.processTrayMenuItemClick(context, menuItem, false);
  }

  @override
  bool get wantKeepAlive => true;
}
