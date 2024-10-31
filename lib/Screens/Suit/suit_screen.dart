import 'dart:io';

import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Suit/custom_bg_avatar_list_screen.dart';
import 'package:loftify/Screens/Suit/dress_suit_list_screen.dart';
import 'package:loftify/Utils/ilogger.dart';
import 'package:loftify/Utils/responsive_util.dart';

import '../../Api/gift_api.dart';
import '../../Widgets/Item/item_builder.dart';
import 'custom_dress_list_screen.dart';

class SuitScreen extends StatefulWidget {
  const SuitScreen({super.key});

  static const String routeName = "/info/suit";

  @override
  State<SuitScreen> createState() => _SuitScreenState();
}

class _SuitScreenState extends State<SuitScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<String> _tabLabelList = ["官方", "定制"];
  late TabController _tabController;
  int _currentTabIndex = 0;
  int _currentOfficialBottomBarIndex = 0;
  int _currentCustomBottomBarIndex = 0;
  List<Widget> _pageList = [];
  List<Widget> _officialPageList = [];
  List<Widget> _customPageList = [];
  final PageController _officialPageController = PageController();
  final PageController _customPageController = PageController();
  List<String> tags = [];

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
    initTab();
    fetchTag();
    initPage();
  }

  fetchTag() async {
    try {
      var res = await GiftApi.getCustomBgAvatarList(
        type: 0,
        offset: 0,
        tag: "",
      );
      String t = res['data']["tags"];
      tags = t.split(",");
      initPage();
      setState(() {});
    } catch (e, t) {
      ILogger.error("Failed to fetch Tag", e, t);
    }
  }

  initPage() {
    _officialPageList = [
      const DressSuitListScreen(),
    ];
    _customPageList = [
      CustomBgAvatarListScreen(tags: tags),
      CustomDressListScreen(tags: tags),
      CustomDressListScreen(tags: tags, propType: 3),
    ];
    _pageList = [
      PageView(
        controller: _officialPageController,
        children: _officialPageList,
      ),
      PageView(
        physics: const ClampingScrollPhysics(),
        controller: _customPageController,
        children: _customPageList,
      ),
    ];
    _customPageController.addListener(() {
      if (_customPageController.page != _currentCustomBottomBarIndex) {
        setState(() {
          _currentCustomBottomBarIndex = _customPageController.page!.round();
        });
      }
    });
    _officialPageController.addListener(() {
      if (_officialPageController.page != _currentOfficialBottomBarIndex) {
        setState(() {
          _currentOfficialBottomBarIndex =
              _officialPageController.page!.round();
        });
      }
    });
    setState(() {});
  }

  initTab() {
    _tabController = TabController(length: _tabLabelList.length, vsync: this);
    _tabController.animation?.addListener(() {
      int indexChange =
          _tabController.offset.abs() > 0.8 ? _tabController.offset.round() : 0;
      int index = _tabController.index + indexChange;
      if (index != _currentTabIndex) {
        setState(() => _currentTabIndex = index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MyTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: _buildTabView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildDesktopAppBar(
      context: context,
      showBack: true,
      centerInMobile: true,
      titleWidget: _buildTabBar(),
      actions: [
        ItemBuilder.buildBlankIconButton(context),
        const SizedBox(width: 5),
      ],
      bottomHeight: 56,
      bottom: _currentTabIndex == 0
          ? _buildOfficialBottomBar()
          : _buildCustomBottomBar(),
    );
  }

  _buildTabBar() {
    return ItemBuilder.buildTabBar(
      context,
      _tabController,
      _tabLabelList
          .asMap()
          .entries
          .map(
            (entry) => ItemBuilder.buildAnimatedTab(context,
                selected: entry.key == _currentTabIndex,
                text: entry.value,
                normalUserBold: true,
                sameFontSize: true),
          )
          .toList(),
      onTap: (index) {
        setState(() {
          _currentTabIndex = index;
        });
      },
      background: ResponsiveUtil.isLandscape()
          ? Colors.transparent
          : MyTheme.getBackground(context),
      showBorder: ResponsiveUtil.isLandscape(),
    );
  }

  _buildTabView() {
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      controller: _tabController,
      children: _pageList,
    );
  }

  _buildOfficialBottomBar([double height = 56]) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MyTheme.getBackground(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: CustomSlidingSegmentedControl(
              isStretch: true,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(50),
              ),
              thumbDecoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: BorderRadius.circular(50),
              ),
              height: height,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              children: const <int, Widget>{
                0: Text("装扮主题"),
                // 1: Text("头像框"),
              },
              initialValue: _currentOfficialBottomBarIndex,
              onValueChanged: (index) {
                _currentOfficialBottomBarIndex = index;
                setState(() {});
                _officialPageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _buildCustomBottomBar([double height = 56]) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MyTheme.getBackground(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: CustomSlidingSegmentedControl(
              isStretch: true,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(50),
              ),
              thumbDecoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: BorderRadius.circular(50),
              ),
              height: height,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              children: const <int, Widget>{
                0: Text("壁纸头像"),
                1: Text("装扮"),
                2: Text("表情包"),
              },
              initialValue: _currentCustomBottomBarIndex,
              onValueChanged: (index) {
                _currentCustomBottomBarIndex = index;
                setState(() {});
                _customPageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
