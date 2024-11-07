import '../../generated/l10n.dart';
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:loftify/Api/server_api.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/panel_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/cloud_control_provider.dart';
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
import '../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../Widgets/Dialog/dialog_builder.dart';
import '../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../Widgets/General/LottieCupertinoRefresh/lottie_cupertino_refresh.dart';
import '../Widgets/Scaffold/my_scaffold.dart';
import '../Widgets/Window/window_button.dart';
import 'Info/system_notice_screen.dart';
import 'Info/user_detail_screen.dart';
import 'Lock/pin_verify_screen.dart';
import 'Setting/setting_screen.dart';
import 'Suit/suit_screen.dart';

const borderColor = Color(0xFF805306);
const backgroundStartColor = Color(0xFFFFD500);
const backgroundEndColor = Color(0xFFF6A00C);

enum SideBarChoice {
  Home("home"),
  Search("search"),
  Dynamic("dynamic"),
  Mine("mine");

  final String key;

  const SideBarChoice(this.key);

  static fromString(String string) {
    switch (string) {
      case "home":
        return SideBarChoice.Home;
      case "search":
        return SideBarChoice.Search;
      case "dynamic":
        return SideBarChoice.Dynamic;
      case "mine":
        return SideBarChoice.Mine;
      default:
        return SideBarChoice.Home;
    }
  }

  static fromInt(int index) {
    switch (index) {
      case 0:
        return SideBarChoice.Home;
      case 1:
        return SideBarChoice.Search;
      case 2:
        return SideBarChoice.Dynamic;
      case 3:
        return SideBarChoice.Mine;
      default:
        return SideBarChoice.Home;
    }
  }
}

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
  Timer? _timer;
  late AnimationController darkModeController;
  Widget? darkModeWidget;
  FullBlogInfo? blogInfo;
  bool _isMaximized = false;
  bool _isStayOnTop = false;
  bool _hasJumpedToPinVerify = false;
  Orientation _oldOrientation = Orientation.portrait;

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
    appProvider.windowSize = await windowManager.getSize();
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
            await HiveUtil.put(
                HiveUtil.userIdKey, accountResponse.blogs[0].blogInfo?.blogId);
            setState(() {
              blogInfo = accountResponse.blogs[0].blogInfo;
            });
            return IndicatorResult.success;
          }
        } catch (e, t) {
          ILogger.error("Failed to load user info", e, t);
          if (mounted) IToast.showTop(S.current.loadFailed);
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
        showUpdateDialog: HiveUtil.getBool(HiveUtil.autoCheckUpdateKey),
        showFailedToast: false,
        showLatestToast: false,
      );
    }
  }

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ServerApi.getCloudControl();
    initDeepLinks();
    CustomFont.downloadFont(showToast: false);
    if (ResponsiveUtil.isLandscape()) _fetchUserInfo();
    if (ResponsiveUtil.isDesktop()) initHotKey();
    if (HiveUtil.getBool(HiveUtil.autoCheckUpdateKey)) fetchReleases();
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      showQQGroupDialog();
      jumpToLogin();
      jumpToLock(autoAuth: true);
      darkModeWidget = LottieUtil.load(
        LottieUtil.sunLight,
        size: 25,
        autoForward: !Utils.isDark(context),
        controller: darkModeController,
      );
      if (ResponsiveUtil.isDesktop()) {
        await Utils.initTray();
        trayManager.addListener(this);
        keyboardHandlerState?.focus();
      }
    });
    initGlobalConfig();
    fetchData();
  }

  showQQGroupDialog() {
    bool haveShownQQGroupDialog = HiveUtil.getBool(
        HiveUtil.haveShownQQGroupDialogKey,
        defaultValue: false);
    if (!haveShownQQGroupDialog) {
      HiveUtil.put(HiveUtil.haveShownQQGroupDialogKey, true);
      DialogBuilder.showConfirmDialog(
        context,
        title: S.current.feedbackWelcome,
        message: S.current.feedbackWelcomeMessage,
        messageTextAlign: TextAlign.center,
        confirmButtonText: S.current.goToQQ,
        cancelButtonText: S.current.joinLater,
        onTapConfirm: () {
          UriUtil.openExternal(controlProvider.globalControl.qqGroupUrl);
        },
      );
    }
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
      // EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
      //       backgroundColor: Theme.of(context).canvasColor,
      //       indicator: LottieUtil.load(LottieUtil.getLoadingPath(context)),
      //       hapticFeedback: true,
      //       triggerOffset: 40,
      //     );
      EasyRefresh.defaultHeaderBuilder = () => MaterialHeader(
            backgroundColor: Theme.of(context).canvasColor,
            color: Theme.of(context).primaryColor,
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

  void jumpToLogin() {
    if (HiveUtil.isFirstLogin() &&
        HiveUtil.getString(HiveUtil.tokenKey, defaultValue: null) == null) {
      HiveUtil.initConfig();
      HiveUtil.setFirstLogin();
      if (ResponsiveUtil.isLandscape()) {
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
        RouteUtil.pushPanelCupertinoRoute(rootContext, const SettingScreen());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return OrientationBuilder(builder: (ctx, ori) {
      if (ori != _oldOrientation) {
        // globalNavigatorState?.popUntil((route) => route.isFirst);
      }
      _oldOrientation = ori;
      return _buildBodyByPlatform();
    });
  }

  _buildBodyByPlatform() {
    if (!ResponsiveUtil.isLandscape()) {
      return _buildMobileBody();
    } else if (ResponsiveUtil.isMobile()) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).canvasColor,
        body: SafeArea(
          child: _buildDesktopBody(),
        ),
      );
    } else {
      return _buildDesktopBody();
    }
  }

  _buildMobileBody() {
    return PanelScreen(key: panelScreenKey);
  }

  _buildDesktopBody() {
    var leftPosWidget = Row(
      children: [
        _sideBar(leftPadding: 8, rightPadding: 8),
        Expanded(
          child: Stack(
            children: [
              _desktopMainContent(),
              Positioned(
                right: 0,
                child: _titleBar(),
              ),
            ],
          ),
        ),
      ],
    );
    return MyScaffold(
      resizeToAvoidBottomInset: false,
      body: leftPosWidget,
    );
  }

  _buildAvatarContextMenuButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          S.current.viewPersonalHomepage,
          onPressed: () async {
            panelScreenState?.pushPage(UserDetailScreen(
              blogId: blogInfo!.blogId,
              blogName: blogInfo!.blogName,
            ));
          },
        ),
        ContextMenuButtonConfig.divider(),
        ContextMenuButtonConfig.warning(
          S.current.logout,
          onPressed: () async {
            HiveUtil.confirmLogout(context);
          },
        ),
      ],
    );
  }

  _titleBar() {
    return (ResponsiveUtil.isDesktop())
        ? ItemBuilder.buildWindowTitle(
            context,
            backgroundColor: Colors.transparent,
            isStayOnTop: _isStayOnTop,
            isMaximized: _isMaximized,
            onStayOnTopTap: () {
              setState(() {
                _isStayOnTop = !_isStayOnTop;
                windowManager.setAlwaysOnTop(_isStayOnTop);
              });
            },
            rightButtons: [],
          )
        : emptyWidget;
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

  _sideBar({
    double leftPadding = 0,
    double rightPadding = 0,
  }) {
    return Container(
      width: 42 + leftPadding + rightPadding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
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
          if (ResponsiveUtil.isDesktop()) const WindowMoveHandle(),
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
                    if (ResponsiveUtil.isDesktop()) const SizedBox(height: 5),
                    if (ResponsiveUtil.isDesktop()) _buildLogo(),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected:
                          hideNavigator && sidebarChoice == SideBarChoice.Home,
                      icon: Icons.explore_outlined,
                      selectedIcon: Icons.explore_rounded,
                      onTap: () async {
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
                      icon: Icons.search_rounded,
                      selectedIcon: Icons.manage_search_rounded,
                      onTap: () async {
                        appProvider.sidebarChoice = SideBarChoice.Search;
                        panelScreenState?.popAll(false);
                      },
                    ),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected: hideNavigator &&
                          sidebarChoice == SideBarChoice.Dynamic,
                      icon: Icons.favorite_border_rounded,
                      selectedIcon: Icons.favorite_rounded,
                      onTap: () async {
                        appProvider.sidebarChoice = SideBarChoice.Dynamic;
                        panelScreenState?.popAll(false);
                      },
                    ),
                    const SizedBox(height: 8),
                    ToolButton(
                      context: context,
                      selected:
                          hideNavigator && sidebarChoice == SideBarChoice.Mine,
                      icon: Icons.person_outline_rounded,
                      selectedIcon: Icons.person_rounded,
                      onTap: () async {
                        appProvider.sidebarChoice = SideBarChoice.Mine;
                        panelScreenState?.popAll(false);
                      },
                    ),
                    const Spacer(),
                    const SizedBox(height: 8),
                    ItemBuilder.buildClickItem(
                      GestureDetector(
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
                            if (Utils.isDark(context)) {
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
                        iconBuilder: (_) => AssetUtil.loadDouble(
                          context,
                          AssetUtil.dressLightIcon,
                          AssetUtil.dressDarkIcon,
                        ),
                        padding: const EdgeInsets.all(8),
                        onTap: () {
                          RouteUtil.pushPanelCupertinoRoute(
                              context, const SuitScreen());
                        },
                      ),
                      const SizedBox(height: 2),
                    ],
                    ToolButton(
                      context: context,
                      iconBuilder: (_) => Icon(
                        Icons.notifications_on_outlined,
                        color: Theme.of(context).iconTheme.color,
                        size: 20,
                      ),
                      onTap: () {
                        RouteUtil.pushPanelCupertinoRoute(
                            context, const SystemNoticeScreen());
                      },
                    ),
                    const SizedBox(height: 2),
                    ToolButton(
                      context: context,
                      iconBuilder: (_) => AssetUtil.loadDouble(
                        context,
                        AssetUtil.settingLightIcon,
                        AssetUtil.settingDarkIcon,
                      ),
                      padding: const EdgeInsets.all(8),
                      onTap: () {
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

  _desktopMainContent({
    double leftMargin = 0,
    double rightMargin = 0,
  }) {
    return Container(
      margin: EdgeInsets.only(left: leftMargin, right: rightMargin),
      child: PanelScreen(key: panelScreenKey),
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
    Utils.displayApp();
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
