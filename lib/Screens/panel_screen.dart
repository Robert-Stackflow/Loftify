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

import 'package:flutter/material.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Navigation/dynamic_screen.dart';
import 'package:loftify/Screens/Navigation/mine_screen.dart';
import 'package:loftify/Screens/refresh_interface.dart';
import 'package:loftify/Utils/ilogger.dart';
import 'package:provider/provider.dart';

import '../Resources/theme.dart';
import '../Utils/app_provider.dart';
import '../Utils/constant.dart';
import '../Utils/enums.dart';
import '../Utils/lottie_util.dart';
import '../Utils/responsive_util.dart';
import '../Utils/route_util.dart';
import '../Utils/utils.dart';
import '../Widgets/Hidable/scroll_to_hide.dart';
import '../Widgets/Item/item_builder.dart';
import '../Widgets/Scaffold/my_bottom_navigation_bar.dart';
import '../Widgets/Scaffold/my_scaffold.dart';
import '../Widgets/Window/window_caption.dart';
import '../generated/l10n.dart';
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

class PanelScreenState extends State<PanelScreen>
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

  bool canPop = true;

  @override
  void initState() {
    super.initState();
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initPage();
      darkModeWidget = LottieUtil.load(
        LottieUtil.sunLight,
        size: 25,
        autoForward: !Utils.isDark(context),
        controller: darkModeController,
      );
    });
  }

  popAll([bool initPage = true]) {
    ResponsiveUtil.doInLandscape(landscape: () {
      while (panelNavigatorState?.canPop() ?? false) {
        panelNavigatorState?.pop();
      }
      canPop = !(panelNavigatorState?.canPop() ?? false);
      appProvider.showPanelNavigator = false;
      if (initPage) {
        _pageController =
            PageController(initialPage: appProvider.sidebarChoice.index);
      }
    });
  }

  pushPage(Widget page) {
    ResponsiveUtil.doInLandscape(
      landscape: () {
        appProvider.showPanelNavigator = true;
        panelNavigatorState?.push(RouteUtil.getFadeRoute(page));
        canPop = !(panelNavigatorState?.canPop() ?? false);
      },
      portrait: () {
        RouteUtil.pushCupertinoRoute(rootContext, page);
      },
    );
  }

  popPage() {
    ResponsiveUtil.doInLandscape(
      landscape: () {
        if (panelNavigatorState?.canPop() ?? false) {
          panelNavigatorState?.pop();
          if (!(panelNavigatorState?.canPop() ?? false)) {
            appProvider.showPanelNavigator = false;
          }
        } else {
          appProvider.showPanelNavigator = false;
        }
        _pageController =
            PageController(initialPage: appProvider.sidebarChoice.index);
        canPop = !(panelNavigatorState?.canPop() ?? false);
      },
      portrait: () {
        Navigator.pop(rootContext);
      },
    );
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
    if (mounted) setState(() {});
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
    var scaffold = MyScaffold(
      body: Stack(
        children: [
          if (unlogin)
            Center(
              child: ItemBuilder.buildRoundButton(
                context,
                text: S.current.goToLogin,
                background: MyTheme.primaryColor,
                onTap: () {
                  RouteUtil.pushDialogRoute(
                    rootContext,
                    const LoginByCaptchaScreen(),
                    popAll: true,
                  );
                },
              ),
            )
          else
            PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: _pageList,
            ),
          ResponsiveUtil.buildDesktopWidget(
              andCondition: unlogin, desktop: const WindowMoveHandle()),
          Selector<AppProvider, bool>(
            selector: (context, provider) => provider.showPanelNavigator,
            builder: (context, value, child) => Offstage(
              offstage: !value,
              child: Navigator(
                key: panelNavigatorKey,
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(builder: (context) => emptyWidget);
                },
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: ResponsiveUtil.buildLandscapeWidgetNullable(
        orCondition: unlogin,
        landscape: null,
        portrait: _buildBottomNavigationBar(),
      ),
    );
    return ResponsiveUtil.buildLandscapeWidget(
      landscape: PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (_, __) => popPage(),
          child: scaffold),
      portrait: scaffold,
    );
  }

  _buildBottomNavigationBar() {
    return ScrollToHide(
      controller: _scrollToHideController,
      scrollControllers: getScrollControllers(),
      hideDirection: AxisDirection.down,
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
          currentIndex: _currentIndex,
          selectedItemColor: Theme.of(context).primaryColor,
          showSelectedLabels: false,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined, size: 28),
              activeIcon: const Icon(Icons.explore_rounded, size: 28),
              label: S.current.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_rounded, size: 28),
              activeIcon: const Icon(Icons.manage_search_rounded, size: 28),
              label: S.current.search,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border_rounded, size: 28),
              activeIcon: const Icon(Icons.favorite_rounded, size: 28),
              label: S.current.dynamic,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded, size: 28),
              activeIcon: const Icon(Icons.person_rounded, size: 28),
              label: S.current.mine,
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
    if (Utils.isDark(context)) {
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
