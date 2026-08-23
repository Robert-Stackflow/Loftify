/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Navigation/dynamic_screen.dart';
import 'package:loftify/Screens/Navigation/mine_screen.dart';
import 'package:provider/provider.dart';

import '../Utils/app_provider.dart';
import '../Utils/enums.dart';
import '../Utils/lottie_files.dart';
import '../Widgets/loftify_icons.dart';
import '../l10n/l10n.dart';
import 'Navigation/home_screen.dart';
import 'Navigation/search_screen.dart';

class PanelScreen extends StatefulWidget {
  const PanelScreen({
    super.key,
  });

  static const String routeName = "/panel";

  @override
  State<PanelScreen> createState() => PanelScreenState();
}

class PanelScreenState extends BasePanelScreenState<PanelScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScrollToHideMixin {
  PageController _pageController = PageController();
  List<Widget> _pageList = [];
  List<GlobalKey> _keyList = [];
  bool unlogin = false;
  int _currentIndex = 0;
  late AnimationController darkModeController;
  Widget? darkModeWidget;
  final ScrollToHideController _scrollToHideController =
      ScrollToHideController();

  GlobalKey<NavigatorState> panelNavigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get panelNavigatorState => panelNavigatorKey.currentState;

  bool canRootPop = true;

  @override
  void initState() {
    super.initState();
    updateStatusBar();
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initPage();
      darkModeWidget = LottieUtil.load(
        LottieFiles.sunLight,
        size: 25,
        autoForward: !ColorUtil.isDark(context),
        controller: darkModeController,
      );
    });
  }

  login() {
    popAll();
    initPage();
  }

  logout() {
    popAll();
    initPage();
  }

  popAll([bool initPage = true]) {
    while (panelNavigatorState?.canPop() ?? false) {
      panelNavigatorState?.pop();
    }
    canRootPop = !(panelNavigatorState?.canPop() ?? false);
    appProvider.showPanelNavigator = false;
    if (initPage) {
      _pageController =
          PageController(initialPage: appProvider.sidebarChoice.index);
    }
  }

  pushPage(Widget page) {
    ResponsiveUtil.runByOrientation(
      landscape: () {
        appProvider.showPanelNavigator = true;
        panelNavigatorState?.push(RouteUtil.getFadeRoute(page));
        canRootPop = false;
        if (mounted) setState(() {});
      },
      portrait: () {
        appProvider.showPanelNavigator = true;
        RouteUtil.pushCupertinoRoute(panelNavigatorState!.context, page);
        canRootPop = false;
        if (mounted) setState(() {});
      },
    );
  }

  popPage() {
    if (panelNavigatorState?.canPop() ?? false) {
      panelNavigatorState?.pop();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!(panelNavigatorState?.canPop() ?? false)) {
          appProvider.showPanelNavigator = false;
        }
      });
    } else {
      appProvider.showPanelNavigator = false;
    }
    _pageController =
        PageController(initialPage: appProvider.sidebarChoice.index);
    canRootPop = !(panelNavigatorState?.canPop() ?? false);
    if (mounted) setState(() {});
  }

  @override
  void updateStatusBar() {
    final brightness = appProvider.getBrightness() ??
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final systemUiOverlayStyle =
        AppBarWrapper.systemUiOverlayStyleForBrightness(
      brightness,
      includeNavigationBar: true,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  Future<void> initPage() async {
    _keyList = [
      homeScreenKey,
      searchScreenKey,
      GlobalKey(),
      GlobalKey(),
    ];
    _pageList = [
      HomeScreen(key: _keyList[0]),
      SearchScreen(key: _keyList[1]),
      DynamicScreen(key: _keyList[2]),
      MineScreen(key: _keyList[3]),
    ];
    try {
      ILogger.debug(
          "init panel page and jump to ${appProvider.sidebarChoice.index.clamp(0, _pageList.length - 1)}");
    } catch (e, t) {
      ILogger.error("Failed to init panel page", e, t);
    }
    jumpToPage(appProvider.sidebarChoice.index.clamp(0, _pageList.length - 1));
  }

  void jumpToPage(int index) {
    if (_currentIndex == index) {
      BottomNavgationMixin? mixin =
          _keyList[_currentIndex].currentState is BottomNavgationMixin?
              ? _keyList[_currentIndex].currentState as BottomNavgationMixin?
              : null;
      mixin?.onTapBottomNavigation();
    } else {
      _currentIndex = index;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    }
    if (mounted) setState(() {});
  }

  void refreshScrollControllers() {
    setState(() {});
  }

  void showBottomNavigationBar() {
    _scrollToHideController.show();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var scaffold = Stack(
      children: [
        MyScaffold(
          body: unlogin
              ? Stack(
                  children: [
                    Center(
                      child: RoundIconTextButton(
                        text: appLocalizations.goToLogin,
                        background: ChewieTheme.primaryColor,
                        onPressed: () {
                          RouteUtil.pushDialogRoute(
                            rootContext,
                            const LoginByCaptchaScreen(),
                            popAll: true,
                          );
                        },
                      ),
                    ),
                    ResponsiveUtil.selectByPlatform(
                        andCondition: unlogin,
                        desktop: const WindowMoveHandle()),
                  ],
                )
              : PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  children: _pageList,
                ),
          extendBody: true,
          bottomNavigationBar: ResponsiveUtil.selectByOrientationNullable(
            orCondition: unlogin,
            landscape: null,
            portrait: _buildBottomNavigationBar(),
          ),
        ),
        Selector<AppProvider, bool>(
          selector: (context, provider) => provider.showPanelNavigator,
          builder: (context, value, child) => Offstage(
            offstage: !value,
            child: Navigator(
              key: panelNavigatorKey,
              onGenerateRoute: (settings) {
                return RouteUtil.getFadeRoute(
                  emptyWidget,
                  duration: Duration.zero,
                );
              },
            ),
          ),
        ),
      ],
    );
    return PopScope(
      canPop: canRootPop,
      onPopInvokedWithResult: (_, __) => popPage(),
      child: scaffold,
    );
  }

  _buildBottomNavigationBar() {
    return ScrollToHide.multi(
      controller: _scrollToHideController,
      scrollControllers: getScrollControllers(),
      hideDirection: Axis.vertical,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: MyBottomNavigationBar(
          backgroundColor: ChewieTheme.scaffoldBackgroundColor,
          currentIndex: _currentIndex,
          selectedItemColor: Theme.of(context).primaryColor,
          showSelectedLabels: false,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const ChewieIcon(LoftifyIcons.home, size: 24),
              activeIcon: const ChewieIcon(LoftifyIcons.home, size: 24),
              label: appLocalizations.home,
            ),
            BottomNavigationBarItem(
              icon: const ChewieIcon(LoftifyIcons.search, size: 24),
              activeIcon: const ChewieIcon(LoftifyIcons.search, size: 24),
              label: appLocalizations.search,
            ),
            BottomNavigationBarItem(
              icon: const ChewieIcon(LoftifyIcons.activity, size: 24),
              activeIcon: const ChewieIcon(LoftifyIcons.activity, size: 24),
              label: appLocalizations.dynamicTab,
            ),
            BottomNavigationBarItem(
              icon: const ChewieIcon(LoftifyIcons.profile, size: 24),
              activeIcon: const ChewieIcon(LoftifyIcons.profile, size: 24),
              label: appLocalizations.mine,
            ),
          ],
          onTap: (index) {
            appProvider.sidebarChoice = SideBarChoice.fromInt(index);
          },
          onDoubleTap: (index) {
            appProvider.sidebarChoice = SideBarChoice.fromInt(index);
          },
        ),
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

  @override
  List<ScrollController> getScrollControllers() {
    List<ScrollController> res = [];
    for (var page in _pageList) {
      var state = _keyList[_pageList.indexOf(page)].currentState;
      if (state is ScrollToHideMixin) {
        res.addAll((state as ScrollToHideMixin).getScrollControllers());
      }
    }
    return res;
  }

  @override
  bool get wantKeepAlive => true;
}
