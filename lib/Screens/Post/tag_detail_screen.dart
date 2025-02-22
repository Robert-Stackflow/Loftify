import 'package:context_menus/context_menus.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/tag_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Post/tag_collection_grain_screen.dart';
import 'package:loftify/Screens/Post/tag_insearch_screen.dart';
import 'package:loftify/Screens/Post/tag_related_screen.dart';
import 'package:loftify/Screens/Suit/dress_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/ilogger.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Utils/route_util.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/cloud_control_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/newest_filter_bottom_sheet.dart';
import '../../Widgets/Custom/custom_tab_indicator.dart';
import '../../Widgets/Custom/sliver_appbar_delegate.dart';
import '../../Widgets/Custom/subordinate_scroll_controller.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';
import '../../generated/l10n.dart';

class TagDetailScreen extends StatefulWidget {
  const TagDetailScreen({super.key, required this.tag});

  static const String routeName = "/tag/detail";

  final String tag;

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  TagDetailData? _tagDetailData;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RecommendTabState> _recommendKey = GlobalKey();
  final GlobalKey<NewestTabState> _newestKey = GlobalKey();
  final GlobalKey<HottestTabState> _hottestKey = GlobalKey();
  final List<SubordinateScrollController?> scrollControllers =
      List.filled(3, null);

  PostLayoutType _postLayoutType = PostLayoutType.values[Utils.patchEnum(
      HiveUtil.getInt(HiveUtil.tagDetailPostLayoutTypeKey, defaultValue: 0),
      PostLayoutType.values.length)];

  int _currentTabIndex = 0;
  final List<String> _tabLabelList = [
    S.current.explore,
    S.current.newest,
    S.current.hottest
  ];

  late GetTagPostListParams _hottestParams;
  int _currentHottestIndex = 0;
  late GetTagPostListParams _newestParams;
  int _currentNewestIndex = 0;

  @override
  void initState() {
    super.initState();
    initTab();
    _fetchTagDetail();
    initFilter();
  }

  initFilter() {
    _hottestParams = GetTagPostListParams(
      tag: widget.tag,
      tagPostResultType: TagPostResultType.week,
    );
    _currentHottestIndex = _hottestParams.tagPostResultType.index - 2;
    _newestParams = GetTagPostListParams(
      tag: widget.tag,
      tagPostResultType: TagPostResultType.newPost,
    );
    _currentNewestIndex = _newestParams.tagPostResultType.index;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: MyTheme.getBackground(context),
      body: _tagDetailData != null
          ? _buildMainBody()
          : ItemBuilder.buildLoadingWidget(context,
              background: MyTheme.getBackground(context)),
    );
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

  _fetchTagDetail() async {
    TagApi.getTagDetail(tag: widget.tag).then((value) {
      try {
        if (value['meta']['status'] != 200) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        } else {
          if (value['response'] != null) {
            _tagDetailData = TagDetailData.fromJson(value['response']);
          }
          if (mounted) setState(() {});
        }
      } catch (e, t) {
        IToast.showTop(S.current.loadFailed);
        ILogger.error("Failed to load tag", e, t);
      }
    });
  }

  _buildMainBody() {
    return Container(
      decoration: BoxDecoration(
        color: MyTheme.getBackground(context),
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
                              child: AssetUtil.loadDouble(
                                context,
                                AssetUtil.tagLightIcon,
                                AssetUtil.tagDarkIcon,
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
                        positiveText: S.current.subscribed,
                        negtiveText: S.current.subscribe,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          TagApi.subscribeOrUnSubscribe(
                            tag: widget.tag,
                            isSubscribe: !_tagDetailData!.favorited,
                            id: Utils.parseToInt(
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
                      if (ResponsiveUtil.isLandscape()) ..._buildButtons(true),
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
                        "${Utils.formatCount(_tagDetailData!.tagViewCount)}${S.current.viewCount}",
                        TagType.normal,
                        showTagLabel: false,
                        showIcon: false,
                        jumpToTag: false,
                      ),
                      ItemBuilder.buildTagItem(
                        context,
                        showTagLabel: false,
                        "${Utils.formatCount(_tagDetailData!.postAllCount)}${S.current.participateCount}",
                        TagType.normal,
                        showIcon: false,
                        jumpToTag: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ItemBuilder.buildDivider(context, horizontal: 0, vertical: 0),
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
      key: ValueKey(Utils.getRandomString()),
      delegate: SliverAppBarDelegate(
        radius: 0,
        background: MyTheme.getBackground(context),
        tabBar: TabBar(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          controller: _tabController,
          tabs: _tabLabelList
              .asMap()
              .entries
              .map((entry) => ItemBuilder.buildAnimatedTab(context,
                  selected: entry.key == _currentTabIndex, text: entry.value))
              .toList(),
          labelPadding: const EdgeInsets.symmetric(horizontal: 0),
          enableFeedback: true,
          dividerHeight: 0,
          physics: const BouncingScrollPhysics(),
          labelStyle: Theme.of(context).textTheme.titleLarge,
          unselectedLabelStyle:
              Theme.of(context).textTheme.titleLarge?.apply(color: Colors.grey),
          indicator: CustomTabIndicator(
            borderColor: Theme.of(context).primaryColor,
          ),
          onTap: (index) {
            if (_currentTabIndex == index) {
              switch (index) {
                case 0:
                  _recommendKey.currentState?.callRefresh();
                  break;
                case 1:
                  _newestKey.currentState?.filterData(_newestParams);
                  break;
                case 2:
                  _hottestKey.currentState?.filterData(_hottestParams);
                  break;
              }
            }
            setState(() {
              _currentTabIndex = index;
            });
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
    List<Widget> children = [];
    children.add(RecommendTab(
      key: _recommendKey,
      tag: widget.tag,
      postLayoutType: _postLayoutType,
    ));
    children.add(Builder(builder: (BuildContext context) {
      final parentController = PrimaryScrollController.of(context);
      if (scrollControllers[0]?.parent != parentController) {
        scrollControllers[0]?.dispose();
        scrollControllers[0] = SubordinateScrollController(parentController);
      }
      return NewestTab(
        key: _newestKey,
        tag: widget.tag,
        scrollController: scrollControllers[0],
        postLayoutType: _postLayoutType,
      );
    }));
    children.add(Builder(builder: (BuildContext context) {
      final parentController = PrimaryScrollController.of(context);
      if (scrollControllers[1]?.parent != parentController) {
        scrollControllers[1]?.dispose();
        scrollControllers[1] = SubordinateScrollController(parentController);
      }
      return HottestTab(
        key: _hottestKey,
        tag: widget.tag,
        scrollController: scrollControllers[1],
        postLayoutType: _postLayoutType,
      );
    }));
    return TabBarView(
      controller: _tabController,
      children: children,
    );
  }

  Widget _buildEntries() {
    bool showTagDress = controlProvider.globalControl.showTagDress;
    bool showEntries = _tagDetailData!.collectionRank != null ||
        (_tagDetailData!.propGiftTagConfig != null && showTagDress) ||
        Utils.isNotEmpty(_tagDetailData!.relatedTags);
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
                      title: S.current.collectionGrain,
                      desc: S.current.collectionGrainDetail(
                          _tagDetailData!.collectionRank!.title),
                      onTap: () {
                        RouteUtil.pushPanelCupertinoRoute(
                            context, TagCollectionGrainScreen(tag: widget.tag));
                      }),
                if (Utils.isNotEmpty(_tagDetailData!.relatedTags))
                  _buildEntryItem(
                      darkBg: AssetUtil.tagDarkIllust,
                      lightBg: AssetUtil.tagLightIllust,
                      title: S.current.relatedTag,
                      desc: _tagDetailData!.relatedTags,
                      onTap: () {
                        RouteUtil.pushPanelCupertinoRoute(
                            context, TagRelatedScreen(tag: widget.tag));
                      }),
                if (_tagDetailData!.propGiftTagConfig != null && showTagDress)
                  _buildEntryItem(
                    darkBg: AssetUtil.dressDarkIllust,
                    lightBg: AssetUtil.dressLightIllust,
                    title: S.current.relatedDressShort,
                    desc: S.current.relatedDressShortDetail(
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
    return ItemBuilder.buildClickable(
      GestureDetector(
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
                  height: 50,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  children: <int, Widget>{
                    0: Text(S.current.releaseRecently),
                    1: Text(S.current.commentRecently),
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
                      _newestKey.currentState?.filterData(_newestParams);
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ItemBuilder.buildIconTextButton(
                context,
                icon: const Icon(
                  Icons.filter_alt_rounded,
                  size: 16,
                ),
                text: S.current.filter,
                onTap: () {
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    (context) => NewestFilterBottomSheet(
                      params: _newestParams.clone(),
                      onConfirm: (params) {
                        _newestParams = params;
                        _newestKey.currentState?.filterData(_newestParams);
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
            color: MyTheme.getBackground(context),
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
                    0: Text(S.current.all),
                    1: Text(S.current.dayRank),
                    2: Text(S.current.weekRank),
                    3: Text(S.current.monthRank),
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
                      _hottestKey.currentState?.filterData(_hottestParams);
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ItemBuilder.buildIconTextButton(
                context,
                icon: const Icon(
                  Icons.filter_alt_rounded,
                  size: 16,
                ),
                text: S.current.filter,
                onTap: () {
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    (context) => NewestFilterBottomSheet(
                      params: _hottestParams.clone(),
                      onConfirm: (params) {
                        _hottestParams = params;
                        _hottestKey.currentState?.filterData(_hottestParams);
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
    return ItemBuilder.buildResponsiveAppBar(
      context: context,
      showBack: true,
      titleWidget: Text(
        S.current.tag,
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
      ItemBuilder.buildIconButton(
        context: context,
        icon: AssetUtil.loadDouble(
          context,
          AssetUtil.searchLightIcon,
          AssetUtil.searchDarkIcon,
          size: small ? 20 : 24,
        ),
        padding: small ? const EdgeInsets.all(4) : null,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
              context, TagInsearchScreen(tag: widget.tag));
        },
      ),
      const SizedBox(width: 5),
      ItemBuilder.buildIconButton(
        context: context,
        icon: Icon(
          _postLayoutType == PostLayoutType.waterfallflow
              ? Icons.view_agenda_outlined
              : Icons.view_module_outlined,
          color: Theme.of(context).iconTheme.color,
          size: small ? 20 : 24,
        ),
        padding: small ? const EdgeInsets.all(4) : null,
        onTap: () {
          if (_postLayoutType == PostLayoutType.waterfallflow) {
            _postLayoutType = PostLayoutType.grid;
          } else {
            _postLayoutType = PostLayoutType.waterfallflow;
          }
          HiveUtil.put(
              HiveUtil.tagDetailPostLayoutTypeKey, _postLayoutType.index);
          setState(() {});
        },
      ),
      const SizedBox(width: 5),
      ItemBuilder.buildIconButton(
        context: context,
        icon: Icon(
          Icons.more_vert_rounded,
          color: Theme.of(context).iconTheme.color,
          size: small ? 20 : 24,
        ),
        padding: small ? const EdgeInsets.all(4) : null,
        onTap: () {
          BottomSheetBuilder.showContextMenu(context, _buildMoreButtons());
        },
      ),
    ];
  }

  _buildMoreButtons() {
    String url = UriUtil.getTagUrlByTagName(widget.tag);
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          S.current.copyLink,
          icon: const Icon(Icons.copy_rounded),
          onPressed: () {
            Utils.copy(context, url);
          },
        ),
        ContextMenuButtonConfig(S.current.openWithBrowser,
            icon: const Icon(Icons.open_in_browser_rounded), onPressed: () {
          UriUtil.openExternal(url);
        }),
        ContextMenuButtonConfig(S.current.shareToOtherApps,
            icon: const Icon(Icons.share_rounded), onPressed: () {
          UriUtil.share(context, url);
        }),
      ],
    );
  }
}

class RecommendTab extends StatefulWidget {
  const RecommendTab({
    super.key,
    required this.tag,
    required this.postLayoutType,
  });

  final String tag;
  final PostLayoutType postLayoutType;

  @override
  State<StatefulWidget> createState() => RecommendTabState();
}

class RecommendTabState extends State<RecommendTab>
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

  @override
  void initState() {
    super.initState();
    callRefresh();
  }

  callRefresh() {
    _fetchRecommendResult(refresh: true);
    _recommendResultRefreshController.callRefresh();
  }

  _fetchRecommendResult({bool refresh = false}) async {
    if (_recommendResultLoading) return;
    if (refresh) _recommendNoMore = false;
    _recommendResultLoading = true;
    return await TagApi.getRecommendList(
      tag: widget.tag,
      offset: refresh ? 0 : _recommendResultOffset,
    ).then((value) {
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
          if (newPosts.isEmpty) {
            _recommendNoMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load tag recommend result list", e, t);
        IToast.showTop(S.current.loadFailed);
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
      refreshOnStart: true,
      onRefresh: () async {
        return await _fetchRecommendResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchRecommendResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => ItemBuilder.buildLoadMoreNotification(
        onLoad: _fetchRecommendResult,
        noMore: _recommendNoMore,
        child: isWaterfallFlow
            ? WaterfallFlow.builder(
                cacheExtent: 9999,
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
            : GridView.extent(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                physics: physics,
                children: List.generate(_recommendList.length, (index) {
                  return RecommendFlowItemBuilder.buildNineGridPostItem(
                    context,
                    _recommendList[index],
                    wh: 160,
                  );
                }),
              ),
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
  });

  final String tag;
  final PostLayoutType postLayoutType;
  final ScrollController? scrollController;

  @override
  State<StatefulWidget> createState() => HottestTabState();
}

class HottestTabState extends State<HottestTab>
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

  @override
  void initState() {
    super.initState();
    filterData(GetTagPostListParams(
      tag: widget.tag,
      tagPostResultType: TagPostResultType.week,
    ));
  }

  filterData(GetTagPostListParams newParam) {
    _hottestParams = newParam;
    _fetchHottestResult(refresh: true);
    _hottestResultRefreshController.callRefresh();
  }

  _fetchHottestResult({bool refresh = false}) async {
    if (_hottestResultLoading) return;
    if (refresh) _hottestNoMore = false;
    _hottestResultLoading = true;
    return await TagApi.getPostList(
      _hottestParams!.copyWith(offset: refresh ? 0 : _hottestResultOffset),
    ).then((value) {
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
          if (newPosts.isEmpty) {
            _hottestNoMore = false;
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
      refreshOnStart: true,
      onRefresh: () async {
        return await _fetchHottestResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchHottestResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => ItemBuilder.buildLoadMoreNotification(
        onLoad: _fetchHottestResult,
        noMore: _hottestNoMore,
        child: isWaterfallFlow
            ? WaterfallFlow.builder(
                cacheExtent: 9999,
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
            : GridView.extent(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                physics: physics,
                children: List.generate(_hottestList.length, (index) {
                  return RecommendFlowItemBuilder.buildNineGridPostItem(
                    context,
                    _hottestList[index],
                    wh: 160,
                  );
                }),
              ),
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
  });

  final String tag;
  final PostLayoutType postLayoutType;
  final ScrollController? scrollController;

  @override
  State<StatefulWidget> createState() => NewestTabState();
}

class NewestTabState extends State<NewestTab>
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

  @override
  void initState() {
    super.initState();
    filterData(GetTagPostListParams(
      tag: widget.tag,
      tagPostResultType: TagPostResultType.newPost,
    ));
  }

  filterData(GetTagPostListParams newParam) {
    _newestParams = newParam;
    _fetchNewestResult(refresh: true);
    _newestResultRefreshController.callRefresh();
  }

  _fetchNewestResult({bool refresh = false}) async {
    if (_newestResultLoading) return;
    if (refresh) _newestNoMore = false;
    _newestResultLoading = true;
    return await TagApi.getPostList(
      _newestParams!.copyWith(offset: refresh ? 0 : _newestResultOffset),
    ).then((value) {
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
          if (newPosts.isEmpty) {
            _newestNoMore = false;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load tag newest result list", e, t);
        IToast.showTop(S.current.loadFailed);
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
      refreshOnStart: true,
      onRefresh: () async {
        return await _fetchNewestResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchNewestResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => ItemBuilder.buildLoadMoreNotification(
        onLoad: _fetchNewestResult,
        noMore: _newestNoMore,
        child: isWaterfallFlow
            ? WaterfallFlow.builder(
                cacheExtent: 9999,
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
            : GridView.extent(
                padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
                shrinkWrap: true,
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                physics: physics,
                children: List.generate(_newestList.length, (index) {
                  return RecommendFlowItemBuilder.buildNineGridPostItem(
                    context,
                    _newestList[index],
                    wh: 160,
                  );
                }),
              ),
      ),
    );
  }
}
