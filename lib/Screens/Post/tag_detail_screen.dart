import 'dart:async';
import 'dart:convert';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/tag_response.dart';
import 'package:loftify/Screens/Post/tag_collection_grain_screen.dart';
import 'package:loftify/Screens/Post/tag_insearch_screen.dart';
import 'package:loftify/Screens/Post/tag_related_screen.dart';
import 'package:loftify/Screens/Suit/dress_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/cloud_control_provider.dart';
import '../../Utils/tab_state_util.dart';
import '../../Utils/uri_util.dart';
import '../../Widgets/BottomSheet/newest_filter_bottom_sheet.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

class TagDetailScreen extends StatefulWidget {
  const TagDetailScreen({super.key, required this.tag});

  static const String routeName = "/tag/detail";

  final String tag;

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends BaseDynamicState<TagDetailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  TagDetailData? _tagDetailData;
  late TabController _tabController;
  late final LazyTabLoadState _tabLoadState;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RecommendTabState> _recommendKey = GlobalKey();
  final GlobalKey<NewestTabState> _newestKey = GlobalKey();
  final GlobalKey<HottestTabState> _hottestKey = GlobalKey();
  final List<SubordinateScrollController?> _tabScrollControllers =
      List<SubordinateScrollController?>.filled(3, null);
  PostLayoutType _postLayoutType = PostLayoutType.values[ChewieUtils.patchEnum(
      ChewieHiveUtil.getInt(HiveUtil.tagDetailPostLayoutTypeKey,
          defaultValue: 0),
      PostLayoutType.values.length)];

  int _currentTabIndex = 0;
  final List<String> _tabLabelList = [
    appLocalizations.explore,
    appLocalizations.newest,
    appLocalizations.hottest
  ];
  static const List<String> _tabIdList = ['explore', 'newest', 'hottest'];

  late GetTagPostListParams _hottestParams;
  int _currentHottestIndex = 0;
  late GetTagPostListParams _newestParams;
  int _currentNewestIndex = 0;

  @override
  void initState() {
    super.initState();
    initFilter();
    initTab();
    _fetchTagDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _tabScrollControllers) {
      controller?.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void initFilter() {
    _hottestParams = _restoreFilter(
      HiveUtil.tagHottestFilterKey,
      fallbackResultType: TagPostResultType.week,
    );
    _currentHottestIndex = switch (_hottestParams.tagPostResultType) {
      TagPostResultType.total => 0,
      TagPostResultType.date => 1,
      TagPostResultType.week => 2,
      TagPostResultType.month => 3,
      _ => 2,
    };
    _newestParams = _restoreFilter(
      HiveUtil.tagNewestFilterKey,
      fallbackResultType: TagPostResultType.newPost,
    );
    _currentNewestIndex = switch (_newestParams.tagPostResultType) {
      TagPostResultType.newComment => 1,
      _ => 0,
    };
  }

  GetTagPostListParams _restoreFilter(
    String key, {
    required TagPostResultType fallbackResultType,
  }) {
    dynamic savedValue;
    final encoded = ChewieHiveUtil.getString(key);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        savedValue = jsonDecode(encoded);
      } catch (error, stackTrace) {
        ILogger.error("Failed to restore tag filter", error, stackTrace);
      }
    }
    return GetTagPostListParams.fromPreference(
      tag: widget.tag,
      value: savedValue,
      fallbackResultType: fallbackResultType,
    );
  }

  void _persistFilter(String key, GetTagPostListParams params) {
    ChewieHiveUtil.put(
      key,
      jsonEncode(params.toPreferenceJson()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: ChewieTheme.getBackground(context),
      body: _tagDetailData != null
          ? _buildMainBody()
          : LoadingWidget(background: ChewieTheme.getBackground(context)),
    );
  }

  void initTab() {
    final restored = PersistentTabState.restore(
      idKey: HiveUtil.tagDetailTabIdKey,
      legacyIndexKey: HiveUtil.tagDetailTabIndexKey,
      itemIds: _tabIdList,
    );
    _tabLoadState = LazyTabLoadState(
      itemIds: _tabIdList,
      savedId: restored.id,
    );
    _currentTabIndex = _tabLoadState.currentIndex;
    _tabController = TabController(
      length: _tabLabelList.length,
      initialIndex: _currentTabIndex,
      vsync: this,
    );
    _tabController.addListener(() {
      final preloadIndex = _tabController.indexIsChanging
          ? _tabController.index
          : _tabController.offset > 0.001
              ? _tabController.index + 1
              : _tabController.offset < -0.001
                  ? _tabController.index - 1
                  : _tabController.index;
      if (preloadIndex >= 0 && preloadIndex < _tabLabelList.length) {
        unawaited(_ensureTabLoaded(preloadIndex));
      }
      final index =
          (_tabController.animation?.value ?? _tabController.index).round();
      if (index != _currentTabIndex) _setCurrentTab(index);
    });
  }

  void _setCurrentTab(int index) {
    final safeIndex = TabStatePreference.restoreIndex(
      index,
      _tabLabelList.length,
    );
    if (safeIndex != _currentTabIndex) {
      setState(() => _currentTabIndex = safeIndex);
    }
    PersistentTabState.save(
      idKey: HiveUtil.tagDetailTabIdKey,
      legacyIndexKey: HiveUtil.tagDetailTabIndexKey,
      itemIds: _tabIdList,
      index: safeIndex,
    );
    _ensureTabLoaded(safeIndex);
  }

  Future<void> _ensureTabLoaded(int index) async {
    if (!_tabLoadState.selectAndShouldLoad(index)) return;
    final started = await _refreshTabData(index);
    if (!started) {
      _tabLoadState.markLoadFailed(index);
    }
  }

  Future<bool> _refreshTabData(int index) async {
    // Do not start an incoming page's refresh while it is still mostly
    // off-screen. EasyRefresh can finish a fast request before the TabBarView
    // transition settles, which makes the required refresh animation appear
    // to be missing. Distant pages also need more than a handful of frames to
    // attach their nested scroll position.
    for (var attempt = 0; attempt < 60; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return false;
      final tabPosition =
          _tabController.animation?.value ?? _tabController.index.toDouble();
      if ((tabPosition - index).abs() > 0.01) continue;
      switch (index) {
        case 0:
          final state = _recommendKey.currentState;
          if (state != null && state.refreshReady) {
            await state.callRefresh();
            return true;
          }
          break;
        case 1:
          final state = _newestKey.currentState;
          if (state != null && state.refreshReady) {
            await state.filterData(_newestParams);
            return true;
          }
          break;
        case 2:
          final state = _hottestKey.currentState;
          if (state != null && state.refreshReady) {
            await state.filterData(_hottestParams);
            return true;
          }
          break;
      }
    }
    return false;
  }

  _fetchTagDetail() async {
    TagApi.getTagDetail(tag: widget.tag).then((value) {
      try {
        if (value['meta']['status'] != 200) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        } else {
          if (value['response'] != null) {
            _tagDetailData = TagDetailData.fromJson(value['response']);
          }
          if (mounted) {
            setState(() {});
            _ensureTabLoaded(_currentTabIndex);
          }
        }
      } catch (e, t) {
        IToast.showTop(appLocalizations.loadFailed);
        ILogger.error("Failed to load tag", e, t);
      }
    });
  }

  _buildMainBody() {
    return Container(
      decoration: BoxDecoration(
        color: ChewieTheme.getBackground(context),
      ),
      child: ExtendedNestedScrollView(
        controller: _scrollController,
        onlyOneScrollInBody: true,
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              child: const ChewieIcon(
                                LoftifyIcons.tag,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _tagDetailData!.tag,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.apply(
                                      fontSizeDelta: 4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      LoftifyItemBuilder.buildFramedDoubleButton(
                        context: context,
                        isFollowed: _tagDetailData!.favorited,
                        positiveText: appLocalizations.subscribed,
                        negtiveText: appLocalizations.subscribe,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          TagApi.subscribeOrUnSubscribe(
                            tag: widget.tag,
                            isSubscribe: !_tagDetailData!.favorited,
                            id: NumberUtil.parseToInt(
                                _tagDetailData!.favoritedTagId),
                          ).then((value) {
                            if (value['meta']['status'] != 200) {
                              IToast.showTop(value['meta']['desc'] ??
                                  value['meta']['msg']);
                            } else {
                              _tagDetailData!.favorited =
                                  !_tagDetailData!.favorited;
                              setState(() {});
                            }
                          });
                        },
                      ),
                      if (ResponsiveUtil.isLandscapeLayout())
                        ..._buildButtons(true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    alignment: WrapAlignment.start,
                    children: [
                      if (_tagDetailData!.tagRanksNew.isNotEmpty)
                        ItemBuilder.buildTagItem(
                          context,
                          _tagDetailData!.tagRanksNew[0].name ?? "",
                          TagType.hot,
                          showIcon: false,
                          jumpToTag: false,
                        ),
                      ItemBuilder.buildTagItem(
                        context,
                        "${StringUtil.formatCount(_tagDetailData!.tagViewCount)}${appLocalizations.viewCount}",
                        TagType.normal,
                        showTagLabel: false,
                        showIcon: false,
                        jumpToTag: false,
                      ),
                      ItemBuilder.buildTagItem(
                        context,
                        showTagLabel: false,
                        "${StringUtil.formatCount(_tagDetailData!.postAllCount)}${appLocalizations.participateCount}",
                        TagType.normal,
                        showIcon: false,
                        jumpToTag: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MyDivider(horizontal: 0, vertical: 0),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildEntries(),
          ),
          if (_tabLabelList.isNotEmpty) _buildTabBar(),
          if (_currentTabIndex == 1) _buildNewestFilterBar(),
          if (_currentTabIndex == 2) _buildHottestFilterBar(),
        ],
        body: _buildTabView(),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      key: ValueKey('tag-detail-tabs-${widget.tag}'),
      delegate: SliverAppBarDelegate(
        radius: 0,
        background: ChewieTheme.getBackground(context),
        tabBar: TabBarWrapper(
          tabController: _tabController,
          tabBarPadding: const EdgeInsets.symmetric(horizontal: 4),
          labelPadding: EdgeInsets.zero,
          background: ChewieTheme.getBackground(context),
          tabs: _tabLabelList
              .asMap()
              .entries
              .map((entry) => ItemBuilder.buildAnimatedTab(context,
                  selected: entry.key == _currentTabIndex,
                  text: entry.value,
                  controller: _tabController,
                  tabIndex: entry.key))
              .toList(),
          onTap: (index) {
            if (_currentTabIndex == index) {
              _refreshTabData(index);
            }
            _setCurrentTab(index);
          },
        ),
      ),
    );
  }

  scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        Builder(builder: (context) {
          final parentController = PrimaryScrollController.of(context);
          if (_tabScrollControllers[0]?.parent != parentController) {
            _tabScrollControllers[0]?.dispose();
            _tabScrollControllers[0] =
                SubordinateScrollController(parentController);
          }
          return RecommendTab(
            key: _recommendKey,
            tag: widget.tag,
            scrollController: _tabScrollControllers[0],
            postLayoutType: _postLayoutType,
          );
        }),
        Builder(builder: (context) {
          final parentController = PrimaryScrollController.of(context);
          if (_tabScrollControllers[1]?.parent != parentController) {
            _tabScrollControllers[1]?.dispose();
            _tabScrollControllers[1] =
                SubordinateScrollController(parentController);
          }
          return NewestTab(
            key: _newestKey,
            tag: widget.tag,
            scrollController: _tabScrollControllers[1],
            postLayoutType: _postLayoutType,
            initialParams: _newestParams,
          );
        }),
        Builder(builder: (context) {
          final parentController = PrimaryScrollController.of(context);
          if (_tabScrollControllers[2]?.parent != parentController) {
            _tabScrollControllers[2]?.dispose();
            _tabScrollControllers[2] =
                SubordinateScrollController(parentController);
          }
          return HottestTab(
            key: _hottestKey,
            tag: widget.tag,
            scrollController: _tabScrollControllers[2],
            postLayoutType: _postLayoutType,
            initialParams: _hottestParams,
          );
        }),
      ],
    );
  }

  Widget _buildEntries() {
    bool showTagDress = controlProvider.globalControl.showTagDress;
    bool showEntries = _tagDetailData!.collectionRank != null ||
        (_tagDetailData!.propGiftTagConfig != null && showTagDress) ||
        StringUtil.isNotEmpty(_tagDetailData!.relatedTags);
    return showEntries
        ? Container(
            height: 70,
            width: MediaQuery.sizeOf(context).width,
            margin: const EdgeInsets.only(top: 10),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                if (_tagDetailData!.collectionRank != null)
                  _buildEntryItem(
                      darkBg: AssetUtil.collectionDarkIllust,
                      lightBg: AssetUtil.collectionLightIllust,
                      title: appLocalizations.collectionGrain,
                      desc: appLocalizations.collectionGrainDetail(
                          _tagDetailData!.collectionRank!.title),
                      onTap: () {
                        RouteUtil.pushPanelCupertinoRoute(
                            context, TagCollectionGrainScreen(tag: widget.tag));
                      }),
                if (StringUtil.isNotEmpty(_tagDetailData!.relatedTags))
                  _buildEntryItem(
                      darkBg: AssetUtil.tagDarkIllust,
                      lightBg: AssetUtil.tagLightIllust,
                      title: appLocalizations.relatedTag,
                      desc: _tagDetailData!.relatedTags,
                      onTap: () {
                        RouteUtil.pushPanelCupertinoRoute(
                            context, TagRelatedScreen(tag: widget.tag));
                      }),
                if (_tagDetailData!.propGiftTagConfig != null && showTagDress)
                  _buildEntryItem(
                    darkBg: AssetUtil.dressDarkIllust,
                    lightBg: AssetUtil.dressLightIllust,
                    title: appLocalizations.relatedDressShort,
                    desc: appLocalizations.relatedDressShortDetail(
                        _tagDetailData!.propGiftTagConfig!.slotCount),
                    onTap: () {
                      RouteUtil.pushPanelCupertinoRoute(
                          context, DressScreen(tag: widget.tag));
                    },
                  ),
              ],
            ),
          )
        : emptyWidget;
  }

  Widget _buildEntryItem({
    required String lightBg,
    required String darkBg,
    required String title,
    required String desc,
    Function()? onTap,
  }) {
    return ClickableWrapper(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          width: 170,
          height: 65,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AssetUtil.loadDouble(
                  context,
                  lightBg,
                  darkBg,
                  width: 170,
                  height: 65,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.apply(fontSizeDelta: -1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewestFilterBar() {
    return SliverPersistentHeader(
      key: ValueKey("$_currentTabIndex"),
      pinned: true,
      delegate: SliverHeaderDelegate.fixedHeight(
        height: 50,
        child: Container(
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
                  height: 50,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  children: <int, Widget>{
                    0: Text(appLocalizations.releaseRecently),
                    1: Text(appLocalizations.commentRecently),
                  },
                  initialValue: _currentNewestIndex,
                  onValueChanged: (index) {
                    setState(() {
                      _currentNewestIndex = index;
                      switch (_currentNewestIndex) {
                        case 0:
                          _newestParams = _newestParams.copyWith(
                            tagPostResultType: TagPostResultType.newPost,
                          );
                          break;
                        case 1:
                          _newestParams = _newestParams.copyWith(
                            tagPostResultType: TagPostResultType.newComment,
                          );
                          break;
                      }
                    });
                    _persistFilter(
                      HiveUtil.tagNewestFilterKey,
                      _newestParams,
                    );
                    _refreshTabData(1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ItemBuilder.buildIconTextButton(
                context,
                icon: const ChewieIcon(LoftifyIcons.filter, size: 16),
                text: appLocalizations.filter,
                onTap: () {
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    (context) => NewestFilterBottomSheet(
                      params: _newestParams.clone(),
                      onConfirm: (params) {
                        _newestParams = params;
                        _persistFilter(
                          HiveUtil.tagNewestFilterKey,
                          _newestParams,
                        );
                        _refreshTabData(1);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHottestFilterBar() {
    return SliverPersistentHeader(
      key: ValueKey("$_currentTabIndex"),
      pinned: true,
      delegate: SliverHeaderDelegate.fixedHeight(
        height: 50,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: ChewieTheme.getBackground(context),
          ),
          child: Row(
            children: [
              Expanded(
                child: CustomSlidingSegmentedControl(
                  isStretch: true,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  height: 50,
                  thumbDecoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  children: <int, Widget>{
                    0: Text(appLocalizations.all),
                    1: Text(appLocalizations.dayRank),
                    2: Text(appLocalizations.weekRank),
                    3: Text(appLocalizations.monthRank),
                  },
                  initialValue: _currentHottestIndex,
                  onValueChanged: (index) {
                    setState(() {
                      _currentHottestIndex = index;
                      switch (_currentHottestIndex) {
                        case 0:
                          _hottestParams = _hottestParams.copyWith(
                            tagPostResultType: TagPostResultType.total,
                          );
                          break;
                        case 1:
                          _hottestParams = _hottestParams.copyWith(
                            tagPostResultType: TagPostResultType.date,
                          );
                          break;
                        case 2:
                          _hottestParams = _hottestParams.copyWith(
                            tagPostResultType: TagPostResultType.week,
                          );
                          break;
                        case 3:
                          _hottestParams = _hottestParams.copyWith(
                            tagPostResultType: TagPostResultType.month,
                          );
                          break;
                      }
                    });
                    _persistFilter(
                      HiveUtil.tagHottestFilterKey,
                      _hottestParams,
                    );
                    _refreshTabData(2);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ItemBuilder.buildIconTextButton(
                context,
                icon: const ChewieIcon(LoftifyIcons.filter, size: 16),
                text: appLocalizations.filter,
                onTap: () {
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    (context) => NewestFilterBottomSheet(
                      params: _hottestParams.clone(),
                      onConfirm: (params) {
                        _hottestParams = params;
                        _persistFilter(
                          HiveUtil.tagHottestFilterKey,
                          _hottestParams,
                        );
                        _refreshTabData(2);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      titleWidget: Text(
        appLocalizations.tag,
        style: Theme.of(context).textTheme.titleMedium?.apply(
              fontWeightDelta: 2,
            ),
      ),
      actions: [..._buildButtons()],
    );
  }

  List<Widget> _buildButtons([bool small = false]) {
    return [
      const SizedBox(width: 5),
      ChewieIconButton(
        icon: LoftifyIcons.search,
        tooltip: appLocalizations.search,
        iconSize: small ? 20 : 24,
        onPressed: () {
          RouteUtil.pushPanelCupertinoRoute(
              context, TagInsearchScreen(tag: widget.tag));
        },
      ),
      const SizedBox(width: 5),
      ChewieIconButton(
        icon: _postLayoutType == PostLayoutType.waterfallflow
            ? LoftifyIcons.listLayout
            : LoftifyIcons.gridLayout,
        tooltip: appLocalizations.layoutSetting,
        iconSize: small ? 20 : 24,
        onPressed: () {
          if (_postLayoutType == PostLayoutType.waterfallflow) {
            _postLayoutType = PostLayoutType.grid;
          } else {
            _postLayoutType = PostLayoutType.waterfallflow;
          }
          ChewieHiveUtil.put(
              HiveUtil.tagDetailPostLayoutTypeKey, _postLayoutType.index);
          setState(() {});
        },
      ),
      const SizedBox(width: 5),
      ChewieIconButton(
        icon: LoftifyIcons.moreVertical,
        tooltip: appLocalizations.moreInfo,
        iconSize: small ? 20 : 24,
        onPressed: () {
          BottomSheetBuilder.showContextMenu(context, _buildMoreButtons());
        },
      ),
    ];
  }

  _buildMoreButtons() {
    String url = LoftifyUriUtil.getTagUrlByTagName(widget.tag);
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.copyLink,
          iconData: LoftifyIcons.copy,
          onPressed: () {
            ChewieUtils.copy(context, url);
          },
        ),
        FlutterContextMenuItem(appLocalizations.openWithBrowser,
            iconData: LoftifyIcons.openExternal, onPressed: () {
          UriUtil.openExternal(url);
        }),
        FlutterContextMenuItem(appLocalizations.shareToOtherApps,
            iconData: LoftifyIcons.share, onPressed: () {
          UriUtil.share(url);
        }),
      ],
    );
  }
}

class RecommendTab extends StatefulWidget {
  const RecommendTab({
    super.key,
    required this.tag,
    this.scrollController,
    required this.postLayoutType,
  });

  final String tag;
  final ScrollController? scrollController;
  final PostLayoutType postLayoutType;

  @override
  State<StatefulWidget> createState() => RecommendTabState();
}

class RecommendTabState extends BaseDynamicState<RecommendTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostListItem> _recommendList = [];
  final EasyRefreshController _recommendResultRefreshController =
      EasyRefreshController();
  int _recommendResultOffset = 0;
  bool _recommendResultLoading = false;
  bool _recommendNoMore = false;

  bool get isWaterfallFlow =>
      widget.postLayoutType == PostLayoutType.waterfallflow;

  bool get refreshReady =>
      (widget.scrollController?.hasClients ?? false) ||
      _recommendResultRefreshController.headerState != null;

  Future<void> callRefresh() => _recommendResultRefreshController.callRefresh(
        overOffset: 28,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        scrollController: widget.scrollController,
        jumpToEdge: false,
      );

  @override
  void dispose() {
    _recommendResultRefreshController.dispose();
    super.dispose();
  }

  Future<IndicatorResult> _fetchRecommendResult({bool refresh = false}) async {
    if (_recommendResultLoading || (!refresh && _recommendNoMore)) {
      return IndicatorResult.none;
    }
    if (refresh) _recommendNoMore = false;
    _recommendResultLoading = true;
    return await TagApi.getRecommendList(
      tag: widget.tag,
      offset: refresh ? 0 : _recommendResultOffset,
    ).then<IndicatorResult>((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          List<PostListItem> newPosts = [];
          if (value['data'] != null) {
            _recommendResultOffset = value['data']['offset'];
            if (refresh) _recommendList.clear();
            newPosts = (value['data']['list'] as List)
                .map((e) => PostListItem.fromJson(e))
                .toList();
            newPosts.removeWhere((e) =>
                _recommendList.any((element) => element.itemId == e.itemId));
            _recommendList.addAll(newPosts);
            _recommendList
                .removeWhere((e) => RecommendFlowItemBuilder.isInvalid(e));
          }
          if (mounted) setState(() {});
          _recommendNoMore = newPosts.isEmpty;
          if (_recommendNoMore && !refresh) {
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load tag recommend result list", e, t);
        IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        _recommendResultLoading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh.builder(
      controller: _recommendResultRefreshController,
      refreshOnStart: false,
      onRefresh: () async {
        return await _fetchRecommendResult(refresh: true);
      },
      onLoad: _recommendNoMore ? null : _fetchRecommendResult,
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => isWaterfallFlow
          ? WaterfallFlow.builder(
              controller: widget.scrollController,
              cacheExtent: MediaQuery.sizeOf(context).height,
              physics: physics,
              padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
              gridDelegate:
                  const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                maxCrossAxisExtent: 300,
              ),
              itemBuilder: (BuildContext context, int index) {
                return RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
                  context,
                  _recommendList[index],
                  excludeTag: widget.tag,
                );
              },
              itemCount: _recommendList.length,
            )
          : GridView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
              physics: physics,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: _recommendList.length,
              itemBuilder: (context, index) {
                return RecommendFlowItemBuilder.buildNineGridPostItem(
                  context,
                  _recommendList[index],
                  wh: 160,
                );
              },
            ),
    );
  }
}

class HottestTab extends StatefulWidget {
  const HottestTab({
    super.key,
    required this.tag,
    this.scrollController,
    required this.postLayoutType,
    required this.initialParams,
  });

  final String tag;
  final PostLayoutType postLayoutType;
  final ScrollController? scrollController;
  final GetTagPostListParams initialParams;

  @override
  State<StatefulWidget> createState() => HottestTabState();
}

class HottestTabState extends BaseDynamicState<HottestTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostListItem> _hottestList = [];
  final EasyRefreshController _hottestResultRefreshController =
      EasyRefreshController();

  GetTagPostListParams? _hottestParams;
  int _hottestResultOffset = 0;
  bool _hottestNoMore = false;
  bool _hottestResultLoading = false;

  bool get isWaterfallFlow =>
      widget.postLayoutType == PostLayoutType.waterfallflow;

  bool get refreshReady =>
      (widget.scrollController?.hasClients ?? false) ||
      _hottestResultRefreshController.headerState != null;

  @override
  void initState() {
    super.initState();
    _hottestParams = widget.initialParams.clone();
  }

  Future<void> filterData(GetTagPostListParams newParam) {
    _hottestParams = newParam.clone();
    return _hottestResultRefreshController.callRefresh(
      overOffset: 28,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      scrollController: widget.scrollController,
      jumpToEdge: false,
    );
  }

  @override
  void dispose() {
    _hottestResultRefreshController.dispose();
    super.dispose();
  }

  Future<IndicatorResult> _fetchHottestResult({bool refresh = false}) async {
    if (_hottestResultLoading || (!refresh && _hottestNoMore)) {
      return IndicatorResult.none;
    }
    if (refresh) _hottestNoMore = false;
    _hottestResultLoading = true;
    return await TagApi.getPostList(
      _hottestParams!.copyWith(offset: refresh ? 0 : _hottestResultOffset),
    ).then<IndicatorResult>((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          List<PostListItem> newPosts = [];
          if (value['data'] != null) {
            _hottestResultOffset = value['data']['offset'];
            if (refresh) _hottestList.clear();
            newPosts = (value['data']['list'] as List)
                .map((e) => PostListItem.fromJson(e))
                .toList();
            newPosts.removeWhere((e) =>
                _hottestList.any((element) => element.itemId == e.itemId));
            _hottestList.addAll(newPosts);
            _hottestList
                .removeWhere((e) => RecommendFlowItemBuilder.isInvalid(e));
          }
          if (mounted) setState(() {});
          _hottestNoMore = newPosts.isEmpty;
          if (_hottestNoMore && !refresh) {
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load tag hottest result list", e, t);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _hottestResultLoading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh.builder(
      controller: _hottestResultRefreshController,
      refreshOnStart: false,
      onRefresh: () async {
        return await _fetchHottestResult(refresh: true);
      },
      onLoad: _hottestNoMore ? null : _fetchHottestResult,
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => isWaterfallFlow
          ? WaterfallFlow.builder(
              controller: widget.scrollController,
              cacheExtent: MediaQuery.sizeOf(context).height,
              physics: physics,
              padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
              gridDelegate:
                  const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                maxCrossAxisExtent: 300,
              ),
              itemBuilder: (BuildContext context, int index) {
                return RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
                  context,
                  _hottestList[index],
                  excludeTag: widget.tag,
                );
              },
              itemCount: _hottestList.length,
            )
          : GridView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
              physics: physics,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: _hottestList.length,
              itemBuilder: (context, index) {
                return RecommendFlowItemBuilder.buildNineGridPostItem(
                  context,
                  _hottestList[index],
                  wh: 160,
                );
              },
            ),
    );
  }
}

class NewestTab extends StatefulWidget {
  const NewestTab({
    super.key,
    required this.tag,
    this.scrollController,
    required this.postLayoutType,
    required this.initialParams,
  });

  final String tag;
  final PostLayoutType postLayoutType;
  final ScrollController? scrollController;
  final GetTagPostListParams initialParams;

  @override
  State<StatefulWidget> createState() => NewestTabState();
}

class NewestTabState extends BaseDynamicState<NewestTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostListItem> _newestList = [];
  final EasyRefreshController _newestResultRefreshController =
      EasyRefreshController();
  GetTagPostListParams? _newestParams;
  int _newestResultOffset = 0;
  bool _newestResultLoading = false;
  bool _newestNoMore = false;

  bool get isWaterfallFlow =>
      widget.postLayoutType == PostLayoutType.waterfallflow;

  bool get refreshReady =>
      (widget.scrollController?.hasClients ?? false) ||
      _newestResultRefreshController.headerState != null;

  @override
  void initState() {
    super.initState();
    _newestParams = widget.initialParams.clone();
  }

  Future<void> filterData(GetTagPostListParams newParam) {
    _newestParams = newParam.clone();
    return _newestResultRefreshController.callRefresh(
      overOffset: 28,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      scrollController: widget.scrollController,
      jumpToEdge: false,
    );
  }

  @override
  void dispose() {
    _newestResultRefreshController.dispose();
    super.dispose();
  }

  Future<IndicatorResult> _fetchNewestResult({bool refresh = false}) async {
    if (_newestResultLoading || (!refresh && _newestNoMore)) {
      return IndicatorResult.none;
    }
    if (refresh) _newestNoMore = false;
    _newestResultLoading = true;
    return await TagApi.getPostList(
      _newestParams!.copyWith(offset: refresh ? 0 : _newestResultOffset),
    ).then<IndicatorResult>((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          List<PostListItem> newPosts = [];

          if (value['data'] != null) {
            _newestResultOffset = value['data']['offset'];
            if (refresh) _newestList.clear();
            newPosts = (value['data']['list'] as List)
                .map((e) => PostListItem.fromJson(e))
                .toList();
            newPosts.removeWhere((e) =>
                _newestList.any((element) => element.itemId == e.itemId));
            _newestList.addAll(newPosts);
            _newestList
                .removeWhere((e) => RecommendFlowItemBuilder.isInvalid(e));
          }
          if (mounted) setState(() {});
          _newestNoMore = newPosts.isEmpty;
          if (_newestNoMore && !refresh) {
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load tag newest result list", e, t);
        IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _newestResultLoading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh.builder(
      controller: _newestResultRefreshController,
      refreshOnStart: false,
      onRefresh: () async {
        return await _fetchNewestResult(refresh: true);
      },
      onLoad: _newestNoMore ? null : _fetchNewestResult,
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => isWaterfallFlow
          ? WaterfallFlow.builder(
              controller: widget.scrollController,
              cacheExtent: MediaQuery.sizeOf(context).height,
              physics: physics,
              padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
              gridDelegate:
                  const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                maxCrossAxisExtent: 300,
              ),
              itemBuilder: (BuildContext context, int index) {
                return RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
                  context,
                  _newestList[index],
                  excludeTag: widget.tag,
                );
              },
              itemCount: _newestList.length,
            )
          : GridView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
              physics: physics,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: _newestList.length,
              itemBuilder: (context, index) {
                return RecommendFlowItemBuilder.buildNineGridPostItem(
                  context,
                  _newestList[index],
                  wh: 160,
                );
              },
            ),
    );
  }
}
