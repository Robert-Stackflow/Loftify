import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:loftify/Api/server_api.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/panel_screen.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/cloud_control_provider.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:loftify/Widgets/Navigation/loftify_glass_navigation_bar.dart';
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
import '../Utils/clipboard_link_controller.dart';
import '../Widgets/Dialog/clipboard_link_dialog.dart';
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
  Timer? _clipboardTimer;
  late final ClipboardLinkController _clipboardLinks;
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
    _scheduleClipboardCheck();
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
    _clipboardLinks = ClipboardLinkController(
      canPrompt: () =>
          mounted &&
          !_hasJumpedToPinVerify &&
          (WidgetsBinding.instance.lifecycleState == null ||
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed) &&
          (ModalRoute.of(context)?.isCurrent ?? false),
      confirm: (url) => ClipboardLinkDialog.show(context, url),
      open: (url) async {
        await UriUtil.processUrl(context, url, pass: false);
      },
    );
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      showQQGroupDialog();
      jumpToLogin();
      _scheduleClipboardCheck();
      darkModeWidget = LottieFiles.buildAnimation(
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

  void initEasyRefresh() {
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(40, false),
          hapticFeedback: true,
          triggerOffset: 56,
          maxOverOffset: 84,
          radius: 20,
        );
    EasyRefresh.defaultFooterBuilder = () => LottieCupertinoFooter(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(36, false),
          triggerOffset: 52,
          maxOverOffset: 76,
          infiniteOffset: 240,
          radius: 18,
        );
    chewieProvider.loadingWidgetBuilder = LottieFiles.buildLoadingAnimation;
    chewieProvider.stateWidgetBuilder = LoftifyStateView.fromChewie;
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
        _scheduleClipboardCheck();
      });
    }
  }

  void _scheduleClipboardCheck() {
    _clipboardTimer?.cancel();
    _clipboardTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) unawaited(_clipboardLinks.check());
    });
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
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          _sideBar(leftPadding: 8, rightPadding: 8),
          Expanded(
            child: Stack(
              children: [
                PanelScreen(key: panelScreenKey),
                Positioned(
                  right: 0,
                  width: desktopWindowControlsWidth,
                  child: _titleBar(),
                ),
              ],
            ),
          ),
        ],
      ),
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
          status: MenuItemStatus.error,
          style: MenuItemStyle(errorColor: Theme.of(context).colorScheme.error),
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

  Widget _buildSidebarNavigationItem({
    required SideBarChoice choice,
    required LoftifyNavigationDestination destination,
    required bool selected,
  }) {
    return LoftifyNavigationRailItem(
      destination: destination,
      selected: selected,
      onTap: () {
        appProvider.sidebarChoice = choice;
        panelScreenState?.popAll(false);
      },
    );
  }

  Widget _buildSidebarActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final iconColor = LoftifyDesignThemeData.of(context).colors.textPrimary;
    return ToolButton(
      context: context,
      icon: icon,
      // The theme Lottie uses a 25px canvas with transparent margins; these
      // glyphs are visually larger at the same nominal size.
      iconSize: 20,
      padding: const EdgeInsets.all(7),
      colors: ChewieColors.getNormalButtonColors(context).copyWith(
        iconNormal: iconColor,
        iconMouseOver: iconColor,
        iconMouseDown: iconColor,
      ),
      onPressed: onPressed,
    );
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
            builder: (_, cloudControlProvider, __) => Selector<AppProvider,
                ({SideBarChoice sidebarChoice, bool hideSearch})>(
              selector: (context, appProvider) => (
                sidebarChoice: appProvider.sidebarChoice,
                hideSearch: appProvider.hideSearchNavigation,
              ),
              builder: (context, preferences, child) =>
                  Selector<AppProvider, bool>(
                selector: (context, appProvider) =>
                    !appProvider.showPanelNavigator,
                builder: (context, hideNavigator, child) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ResponsiveUtil.selectByPlatform(
                        desktop: const SizedBox(height: 5)),
                    const SizedBox(height: 8),
                    _buildSidebarNavigationItem(
                      choice: SideBarChoice.Home,
                      selected: hideNavigator &&
                          preferences.sidebarChoice == SideBarChoice.Home,
                      destination: LoftifyNavigationDestination(
                        icon: LoftifyIcons.home,
                        lottieAsset: LottieFiles.navHome,
                        label: appLocalizations.home,
                      ),
                    ),
                    if (!preferences.hideSearch) ...[
                      const SizedBox(height: 8),
                      _buildSidebarNavigationItem(
                        choice: SideBarChoice.Search,
                        selected: hideNavigator &&
                            preferences.sidebarChoice == SideBarChoice.Search,
                        destination: LoftifyNavigationDestination(
                          icon: LoftifyIcons.search,
                          lottieAsset: LottieFiles.navSearch,
                          label: appLocalizations.search,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildSidebarNavigationItem(
                      choice: SideBarChoice.Dynamic,
                      selected: hideNavigator &&
                          preferences.sidebarChoice == SideBarChoice.Dynamic,
                      destination: LoftifyNavigationDestination(
                        icon: LoftifyIcons.activity,
                        lottieAsset: LottieFiles.navHeart,
                        label: appLocalizations.dynamicTab,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSidebarNavigationItem(
                      choice: SideBarChoice.Mine,
                      selected: hideNavigator &&
                          preferences.sidebarChoice == SideBarChoice.Mine,
                      destination: LoftifyNavigationDestination(
                        icon: LoftifyIcons.profile,
                        lottieAsset: LottieFiles.navUser,
                        label: appLocalizations.mine,
                      ),
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
                      _buildSidebarActionButton(
                        icon: LoftifyIcons.dress,
                        onPressed: () {
                          RouteUtil.pushPanelCupertinoRoute(
                              context, const SuitScreen());
                        },
                      ),
                      const SizedBox(height: 2),
                    ],
                    _buildSidebarActionButton(
                      icon: LoftifyIcons.notifications,
                      onPressed: () {
                        RouteUtil.pushPanelCupertinoRoute(
                            context, const SystemNoticeScreen());
                      },
                    ),
                    const SizedBox(height: 2),
                    _buildSidebarActionButton(
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
        _scheduleClipboardCheck();
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
    _clipboardTimer?.cancel();
    _clipboardLinks.dispose();
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
