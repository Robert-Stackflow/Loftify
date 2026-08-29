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
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/cloud_control_provider.dart';
import '../../Utils/tab_state_util.dart';
import '../../Utils/uri_util.dart';
import '../../Widgets/BottomSheet/newest_filter_bottom_sheet.dart';
import '../../Widgets/Design/loftify_controls.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';
import '../../Widgets/Tag/tag_detail_components.dart';
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
    final design = context.design;
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: design.colors.page,
      body: _tagDetailData != null
          ? _buildMainBody()
          : LoadingWidget(background: design.colors.page),
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

  Future<void> _fetchTagDetail() async {
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

  Widget _buildMainBody() {
    final design = context.design;
    return ColoredBox(
      color: design.colors.page,
      child: ExtendedNestedScrollView(
        controller: _scrollController,
        onlyOneScrollInBody: true,
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildTagHero()),
          SliverToBoxAdapter(child: _buildEntries()),
          if (_tabLabelList.isNotEmpty) _buildTabBar(),
          if (_currentTabIndex == 1) _buildNewestFilterBar(),
          if (_currentTabIndex == 2) _buildHottestFilterBar(),
        ],
        body: _buildTabView(),
      ),
    );
  }

  Widget _buildTagHero() {
    final data = _tagDetailData!;
    return _buildContentFrame(
      LoftifyTagHero(
        tag: data.tag,
        subscribed: data.favorited,
        subscribeLabel: appLocalizations.subscribe,
        subscribedLabel: appLocalizations.subscribed,
        metrics: [
          if (data.tagRanksNew.isNotEmpty &&
              StringUtil.isNotEmpty(data.tagRanksNew.first.name))
            LoftifyTagMetric(
              data.tagRanksNew.first.name ?? '',
              emphasized: true,
            ),
          LoftifyTagMetric(
            '${StringUtil.formatCount(data.tagViewCount)}${appLocalizations.viewCount}',
          ),
          LoftifyTagMetric(
            '${StringUtil.formatCount(data.postAllCount)}${appLocalizations.participateCount}',
          ),
        ],
        onSubscriptionPressed: _toggleSubscription,
        trailing:
            ResponsiveUtil.isLandscapeLayout() ? _buildButtons(true) : const [],
      ),
    );
  }

  void _toggleSubscription() {
    HapticFeedback.mediumImpact();
    TagApi.subscribeOrUnSubscribe(
      tag: widget.tag,
      isSubscribe: !_tagDetailData!.favorited,
      id: NumberUtil.parseToInt(_tagDetailData!.favoritedTagId),
    ).then((value) {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
      } else {
        _tagDetailData!.favorited = !_tagDetailData!.favorited;
        if (mounted) setState(() {});
      }
    });
  }

  Widget _buildContentFrame(
    Widget child, {
    double top = 0,
    double bottom = 0,
  }) {
    final design = context.design;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centeredInset = ((width - design.grid.maximumContentWidth) / 2)
            .clamp(0.0, double.infinity);
        final pageInset = design.grid.pagePaddingFor(width);
        return Padding(
          padding: EdgeInsets.only(
            left: centeredInset + pageInset,
            right: centeredInset + pageInset,
            top: top,
            bottom: bottom,
          ),
          child: child,
        );
      },
    );
  }

  double _contentInsetFor(double width) {
    final design = context.design;
    final centeredInset = ((width - design.grid.maximumContentWidth) / 2)
        .clamp(0.0, double.infinity);
    return centeredInset + design.grid.pagePaddingFor(width);
  }

  Widget _buildTabBar() {
    final design = context.design;
    final tabBar = TabBarWrapper(
      tabController: _tabController,
      tabBarPadding: EdgeInsets.zero,
      labelPadding: EdgeInsets.zero,
      background: design.colors.page,
      tabs: _tabLabelList
          .asMap()
          .entries
          .map((entry) => ItemBuilder.buildAnimatedTab(
                context,
                selected: entry.key == _currentTabIndex,
                text: entry.value,
                controller: _tabController,
                tabIndex: entry.key,
                sameFontSize: true,
                fontSizeDelta: -1,
              ))
          .toList(),
      onTap: (index) {
        if (_currentTabIndex == index) {
          _refreshTabData(index);
        }
        _setCurrentTab(index);
      },
    );
    return SliverPersistentHeader(
      pinned: true,
      key: ValueKey('tag-detail-tabs-${widget.tag}'),
      delegate: SliverAppBarDelegate(
        radius: 0,
        background: design.colors.page,
        tabBar: PreferredSize(
          preferredSize: tabBar.preferredSize,
          child: _buildContentFrame(tabBar),
        ),
      ),
    );
  }

  void scrollToTop() {
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
    final design = context.design;
    final entryHeight = LoftifyTagDiscoveryCard.preferredHeight(context);
    bool showTagDress = controlProvider.globalControl.showTagDress;
    bool showEntries = _tagDetailData!.collectionRank != null ||
        (_tagDetailData!.propGiftTagConfig != null && showTagDress) ||
        StringUtil.isNotEmpty(_tagDetailData!.relatedTags);
    return showEntries
        ? SizedBox(
            height: entryHeight + design.spacing.lg,
            width: MediaQuery.sizeOf(context).width,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final inset = _contentInsetFor(constraints.maxWidth);
                return ListView(
                  padding: EdgeInsets.only(
                    left: inset,
                    right: inset,
                    bottom: design.spacing.lg,
                  ),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (_tagDetailData!.collectionRank != null)
                      _buildEntryItem(
                        darkBg: AssetUtil.collectionDarkIllust,
                        lightBg: AssetUtil.collectionLightIllust,
                        title: appLocalizations.collectionGrain,
                        desc: appLocalizations.collectionGrainDetail(
                          _tagDetailData!.collectionRank!.title,
                        ),
                        onTap: () {
                          RouteUtil.pushPanelCupertinoRoute(
                            context,
                            TagCollectionGrainScreen(tag: widget.tag),
                          );
                        },
                      ),
                    if (StringUtil.isNotEmpty(_tagDetailData!.relatedTags))
                      _buildEntryItem(
                        darkBg: AssetUtil.tagDarkIllust,
                        lightBg: AssetUtil.tagLightIllust,
                        title: appLocalizations.relatedTag,
                        desc: _tagDetailData!.relatedTags,
                        onTap: () {
                          RouteUtil.pushPanelCupertinoRoute(
                            context,
                            TagRelatedScreen(tag: widget.tag),
                          );
                        },
                      ),
                    if (_tagDetailData!.propGiftTagConfig != null &&
                        showTagDress)
                      _buildEntryItem(
                        darkBg: AssetUtil.dressDarkIllust,
                        lightBg: AssetUtil.dressLightIllust,
                        title: appLocalizations.relatedDressShort,
                        desc: appLocalizations.relatedDressShortDetail(
                          _tagDetailData!.propGiftTagConfig!.slotCount,
                        ),
                        onTap: () {
                          RouteUtil.pushPanelCupertinoRoute(
                            context,
                            DressScreen(tag: widget.tag),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          )
        : emptyWidget;
  }

  Widget _buildEntryItem({
    required String lightBg,
    required String darkBg,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    final design = context.design;
    final entryHeight = LoftifyTagDiscoveryCard.preferredHeight(context);
    final entryWidth = LoftifyTagDiscoveryCard.preferredWidth(context);
    return Padding(
      padding: EdgeInsets.only(right: design.spacing.md),
      child: LoftifyTagDiscoveryCard(
        title: title,
        description: desc,
        onTap: onTap,
        illustration: AssetUtil.loadDouble(
          context,
          lightBg,
          darkBg,
          width: entryWidth,
          height: entryHeight,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildNewestFilterBar() {
    final design = context.design;
    return SliverPersistentHeader(
      key: ValueKey('tag-detail-newest-filter-$_currentTabIndex'),
      pinned: true,
      delegate: SliverHeaderDelegate.fixedHeight(
        height: 64,
        child: ColoredBox(
          color: design.colors.page,
          child: _buildContentFrame(
            _buildFilterStrip(
              selectedIndex: _currentNewestIndex,
              labels: [
                appLocalizations.releaseRecently,
                appLocalizations.commentRecently,
              ],
              onSelected: (index) {
                setState(() {
                  _currentNewestIndex = index;
                  _newestParams = _newestParams.copyWith(
                    tagPostResultType: index == 0
                        ? TagPostResultType.newPost
                        : TagPostResultType.newComment,
                  );
                });
                _persistFilter(HiveUtil.tagNewestFilterKey, _newestParams);
                _refreshTabData(1);
              },
              onFilter: () {
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
            top: design.spacing.md,
            bottom: design.spacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildHottestFilterBar() {
    final design = context.design;
    return SliverPersistentHeader(
      key: ValueKey('tag-detail-hottest-filter-$_currentTabIndex'),
      pinned: true,
      delegate: SliverHeaderDelegate.fixedHeight(
        height: 64,
        child: ColoredBox(
          color: design.colors.page,
          child: _buildContentFrame(
            _buildFilterStrip(
              selectedIndex: _currentHottestIndex,
              labels: [
                appLocalizations.all,
                appLocalizations.dayRank,
                appLocalizations.weekRank,
                appLocalizations.monthRank,
              ],
              onSelected: (index) {
                setState(() {
                  _currentHottestIndex = index;
                  _hottestParams = _hottestParams.copyWith(
                    tagPostResultType: switch (index) {
                      0 => TagPostResultType.total,
                      1 => TagPostResultType.date,
                      2 => TagPostResultType.week,
                      _ => TagPostResultType.month,
                    },
                  );
                });
                _persistFilter(HiveUtil.tagHottestFilterKey, _hottestParams);
                _refreshTabData(2);
              },
              onFilter: () {
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
            top: design.spacing.md,
            bottom: design.spacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterStrip({
    required int selectedIndex,
    required List<String> labels,
    required ValueChanged<int> onSelected,
    required VoidCallback onFilter,
  }) {
    final design = context.design;
    final segmentTextStyle = design.typography.label.copyWith(
      color: design.colors.textPrimary,
    );
    return Row(
      children: [
        Expanded(
          child: CustomSlidingSegmentedControl<int>(
            isStretch: true,
            innerPadding: EdgeInsets.all(design.spacing.xxs),
            padding: design.spacing.md,
            height: 40,
            decoration: BoxDecoration(
              color: design.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(design.radii.full),
            ),
            thumbDecoration: BoxDecoration(
              color: design.colors.surfaceRaised,
              borderRadius: BorderRadius.circular(design.radii.full),
              border: Border.all(
                color: design.colors.outline,
                width: design.borders.hairline,
              ),
            ),
            duration: design.motion.effective(context, design.motion.state),
            curve: design.motion.enterCurve,
            children: {
              for (var index = 0; index < labels.length; index++)
                index: Text(
                  labels[index],
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: segmentTextStyle,
                ),
            },
            initialValue: selectedIndex,
            onValueChanged: onSelected,
          ),
        ),
        SizedBox(width: design.spacing.md),
        LoftifyButton(
          label: appLocalizations.filter,
          icon: LoftifyIcons.filter,
          variant: LoftifyButtonVariant.ghost,
          size: LoftifyButtonSize.compact,
          onPressed: onFilter,
        ),
      ],
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

  FlutterContextMenu _buildMoreButtons() {
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

double _tagResultContentInset(BuildContext context, double viewportWidth) {
  final design = context.design;
  final centeredInset = ((viewportWidth - design.grid.maximumContentWidth) / 2)
      .clamp(0.0, double.infinity);
  return centeredInset + design.grid.pagePaddingFor(viewportWidth);
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
    final design = context.design;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final horizontalInset = _tagResultContentInset(context, viewportWidth);
    final gutter = design.grid.gutterFor(viewportWidth);
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
              padding: EdgeInsets.only(
                top: design.spacing.sectionTop,
                left: horizontalInset,
                right: horizontalInset,
              ),
              gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: gutter,
                crossAxisSpacing: gutter,
                maxCrossAxisExtent: design.grid.maximumDenseCardExtent,
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
              padding: EdgeInsets.only(
                top: design.spacing.sectionTop,
                left: horizontalInset,
                right: horizontalInset,
              ),
              physics: physics,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: design.grid.maximumDenseCardExtent,
                mainAxisSpacing: gutter,
                crossAxisSpacing: gutter,
              ),
              itemCount: _recommendList.length,
              itemBuilder: (context, index) {
                return LayoutBuilder(
                  builder: (context, constraints) =>
                      RecommendFlowItemBuilder.buildNineGridPostItem(
                    context,
                    _recommendList[index],
                    wh: constraints.maxWidth,
                  ),
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
    final design = context.design;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final horizontalInset = _tagResultContentInset(context, viewportWidth);
    final gutter = design.grid.gutterFor(viewportWidth);
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
              padding: EdgeInsets.only(
                top: design.spacing.sectionTop,
                left: horizontalInset,
                right: horizontalInset,
              ),
              gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: gutter,
                crossAxisSpacing: gutter,
                maxCrossAxisExtent: design.grid.maximumDenseCardExtent,
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
              padding: EdgeInsets.only(
                top: design.spacing.sectionTop,
                left: horizontalInset,
                right: horizontalInset,
              ),
              physics: physics,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: design.grid.maximumDenseCardExtent,
                mainAxisSpacing: gutter,
                crossAxisSpacing: gutter,
              ),
              itemCount: _hottestList.length,
              itemBuilder: (context, index) {
                return LayoutBuilder(
                  builder: (context, constraints) =>
                      RecommendFlowItemBuilder.buildNineGridPostItem(
                    context,
                    _hottestList[index],
                    wh: constraints.maxWidth,
                  ),
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
    final design = context.design;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final horizontalInset = _tagResultContentInset(context, viewportWidth);
    final gutter = design.grid.gutterFor(viewportWidth);
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
              padding: EdgeInsets.only(
                top: design.spacing.sectionTop,
                left: horizontalInset,
                right: horizontalInset,
              ),
              gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: gutter,
                crossAxisSpacing: gutter,
                maxCrossAxisExtent: design.grid.maximumDenseCardExtent,
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
              padding: EdgeInsets.only(
                top: design.spacing.sectionTop,
                left: horizontalInset,
                right: horizontalInset,
              ),
              physics: physics,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: design.grid.maximumDenseCardExtent,
                mainAxisSpacing: gutter,
                crossAxisSpacing: gutter,
              ),
              itemCount: _newestList.length,
              itemBuilder: (context, index) {
                return LayoutBuilder(
                  builder: (context, constraints) =>
                      RecommendFlowItemBuilder.buildNineGridPostItem(
                    context,
                    _newestList[index],
                    wh: constraints.maxWidth,
                  ),
                );
              },
            ),
    );
  }
}
