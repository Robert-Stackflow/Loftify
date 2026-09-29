import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Screens/Suit/custom_bg_avatar_list_screen.dart';
import 'package:loftify/Screens/Suit/dress_suit_list_screen.dart';

import '../../Api/gift_api.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/tab_state_util.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../l10n/l10n.dart';
import 'custom_dress_list_screen.dart';

class SuitScreen extends StatefulWidget {
  const SuitScreen({super.key});

  static const String routeName = "/info/suit";

  @override
  State<SuitScreen> createState() => _SuitScreenState();
}

class _SuitScreenState extends BaseDynamicState<SuitScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<String> _tabLabelList = ["官方", "定制"];
  static const List<String> _tabIdList = ['official', 'custom'];
  static const List<String> _customPageIdList = [
    'background',
    'dress',
    'emote',
  ];
  late TabController _tabController;
  int _currentTabIndex = 0;
  int _currentOfficialBottomBarIndex = 0;
  int _currentCustomBottomBarIndex = 0;
  List<Widget> _pageList = [];
  List<Widget> _officialPageList = [];
  List<Widget> _customPageList = [];
  final PageController _officialPageController = PageController();
  late final PageController _customPageController;
  final GlobalKey<DressSuitListScreenState> _officialPageKey = GlobalKey();
  final GlobalKey<CustomBgAvatarListScreenState> _backgroundPageKey =
      GlobalKey();
  final GlobalKey<CustomDressListScreenState> _dressPageKey = GlobalKey();
  final GlobalKey<CustomDressListScreenState> _emotePageKey = GlobalKey();
  final Set<String> _loadedPageIds = <String>{};
  List<String> tags = [];

  @override
  void initState() {
    super.initState();
    _currentCustomBottomBarIndex = PersistentTabState.restore(
      idKey: HiveUtil.suitCustomPageIdKey,
      legacyIndexKey: HiveUtil.suitCustomPageIndexKey,
      itemIds: _customPageIdList,
    ).index;
    _customPageController = PageController(
      initialPage: _currentCustomBottomBarIndex,
    );
    _customPageController.addListener(_handleCustomPageChanged);
    _officialPageController.addListener(_handleOfficialPageChanged);
    initTab();
    fetchTag();
    initPage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureCurrentPageLoaded();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customPageController
      ..removeListener(_handleCustomPageChanged)
      ..dispose();
    _officialPageController
      ..removeListener(_handleOfficialPageChanged)
      ..dispose();
    super.dispose();
  }

  void _handleCustomPageChanged() {
    final page = _customPageController.page?.round();
    if (page == null || page == _currentCustomBottomBarIndex || !mounted) {
      return;
    }
    setState(() => _currentCustomBottomBarIndex = page);
    PersistentTabState.save(
      idKey: HiveUtil.suitCustomPageIdKey,
      legacyIndexKey: HiveUtil.suitCustomPageIndexKey,
      itemIds: _customPageIdList,
      index: page,
    );
    _ensureCurrentPageLoaded();
  }

  void _handleOfficialPageChanged() {
    final page = _officialPageController.page?.round();
    if (page == null || page == _currentOfficialBottomBarIndex || !mounted) {
      return;
    }
    setState(() => _currentOfficialBottomBarIndex = page);
  }

  fetchTag() async {
    try {
      var res = await GiftApi.getCustomBgAvatarList(
        type: 0,
        offset: 0,
        tag: "",
      );
      String t = res['data']["tags"];
      if (!mounted) return;
      tags = t.split(",");
      initPage();
    } catch (e, t) {
      ILogger.error("Failed to fetch Tag", e, t);
    }
  }

  initPage() {
    _officialPageList = [
      DressSuitListScreen(
        key: _officialPageKey,
        refreshOnStart: false,
      ),
    ];
    _customPageList = [
      CustomBgAvatarListScreen(
        key: _backgroundPageKey,
        tags: tags,
        refreshOnStart: false,
      ),
      CustomDressListScreen(
        key: _dressPageKey,
        tags: tags,
        refreshOnStart: false,
      ),
      CustomDressListScreen(
        key: _emotePageKey,
        tags: tags,
        propType: 3,
        refreshOnStart: false,
      ),
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
    setState(() {});
  }

  initTab() {
    _currentTabIndex = PersistentTabState.restore(
      idKey: HiveUtil.suitTabIdKey,
      legacyIndexKey: HiveUtil.suitTabIndexKey,
      itemIds: _tabIdList,
    ).index;
    _tabController = TabController(
      length: _tabLabelList.length,
      initialIndex: _currentTabIndex,
      vsync: this,
    );
    _tabController.addListener(() {
      final index =
          (_tabController.animation?.value ?? _tabController.index).round();
      if (index != _currentTabIndex) _setCurrentTab(index);
    });
  }

  void _setCurrentTab(int index) {
    final safeIndex = TabStatePreference.restoreIndex(index, _tabIdList.length);
    if (safeIndex != _currentTabIndex && mounted) {
      setState(() => _currentTabIndex = safeIndex);
    }
    PersistentTabState.save(
      idKey: HiveUtil.suitTabIdKey,
      legacyIndexKey: HiveUtil.suitTabIndexKey,
      itemIds: _tabIdList,
      index: safeIndex,
    );
    _ensureCurrentPageLoaded();
  }

  void _ensureCurrentPageLoaded() {
    final pageId = _currentTabIndex == 0
        ? 'official'
        : 'custom:${_customPageIdList[_currentCustomBottomBarIndex]}';
    if (!_loadedPageIds.add(pageId)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var loaded = false;
      switch (pageId) {
        case 'official':
          final state = _officialPageKey.currentState;
          if (state != null) {
            state.callRefresh();
            loaded = true;
          }
          break;
        case 'custom:background':
          final state = _backgroundPageKey.currentState;
          if (state != null) {
            state.callRefresh();
            loaded = true;
          }
          break;
        case 'custom:dress':
          final state = _dressPageKey.currentState;
          if (state != null) {
            state.callRefresh();
            loaded = true;
          }
          break;
        case 'custom:emote':
          final state = _emotePageKey.currentState;
          if (state != null) {
            state.callRefresh();
            loaded = true;
          }
          break;
      }
      if (!loaded) _loadedPageIds.remove(pageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: _buildTabView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      centerTitle: true,
      titleWidget: _buildTabBar(),
      actions: const [BlankIconButton()],
      bottomHeight: 56,
      bottomWidget: _currentTabIndex == 0
          ? _buildOfficialBottomBar()
          : _buildCustomBottomBar(),
    );
  }

  _buildTabBar() {
    return TabBarWrapper(
      tabController: _tabController,
      tabs: _tabLabelList
          .asMap()
          .entries
          .map(
            (entry) => ItemBuilder.buildAnimatedTab(context,
                selected: entry.key == _currentTabIndex,
                text: entry.value,
                controller: _tabController,
                tabIndex: entry.key,
                normalUserBold: true,
                sameFontSize: true),
          )
          .toList(),
      onTap: (index) {
        _setCurrentTab(index);
      },
      background: ResponsiveUtil.isLandscapeLayout()
          ? Colors.transparent
          : ChewieTheme.getBackground(context),
      showBorder: ResponsiveUtil.isLandscapeLayout(),
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
        color: ChewieTheme.getBackground(context),
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
              children: <int, Widget>{
                0: Text(appLocalizations.dressTheme),
                // 1: Text(appLocalizations.avatarBox),
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
        color: ChewieTheme.getBackground(context),
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
              children: <int, Widget>{
                0: Text(appLocalizations.bgAvatar),
                1: Text(appLocalizations.dress),
                2: Text(appLocalizations.emotePackage),
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
