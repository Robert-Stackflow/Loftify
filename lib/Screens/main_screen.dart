import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:loftify/Api/github_api.dart';
import 'package:loftify/Models/nav_entry.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Navigation/dynamic_screen.dart';
import 'package:loftify/Screens/Navigation/home_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Widgets/Dialog/custom_dialog.dart';
import 'package:loftify/Widgets/LottieCupertinoRefresh/lottie_cupertino_refresh.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../Api/login_api.dart';
import '../Models/github_response.dart';
import '../Providers/provider_manager.dart';
import '../Resources/fonts.dart';
import '../Utils/hive_util.dart';
import '../Utils/iprint.dart';
import '../Utils/lottie_util.dart';
import '../Utils/route_util.dart';
import '../Utils/utils.dart';
import '../Widgets/EasyRefresh/easy_refresh.dart';
import '../Widgets/Scaffold/my_bottom_navigation_bar.dart';
import '../Widgets/Scaffold/my_scaffold.dart';
import 'Lock/pin_verify_screen.dart';

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
          confirmButtonText: "前往更新",
          cancelButtonText: "暂不更新",
          onTapConfirm: () {
            Navigator.pop(context);
            UriUtil.openExternal(latestReleaseItem!.htmlUrl);
          },
          onTapCancel: () {
            Navigator.pop(context);
          },
          customDialogType: CustomDialogType.normal,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
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
    if (HiveUtil.getBool(
        key: HiveUtil.enableSafeModeKey, defaultValue: false)) {
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } else {
      FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      goLogin();
      goPinVerify();
    });
    fetchData();
    // ProviderManager.globalProvider.addListener(() {
    //   initData();
    // });
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
      (_keyList[index].currentState as DynamicScreenState).scrollToTopAndRefresh();
    }

    _pageController.jumpToPage(index);
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

  void cancleTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void setTimer() {
    _timer = Timer(
        Duration(minutes: ProviderManager.globalProvider.autoLockTime),
        goPinVerify);
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
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
