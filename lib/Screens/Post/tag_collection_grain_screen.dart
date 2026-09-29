import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Models/tag_response.dart';
import 'package:loftify/Screens/Post/collection_detail_screen.dart';

import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/tab_state_util.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'grain_detail_screen.dart';

Widget _buildHotRankMarker(BuildContext context, int index) {
  if (index > 2) {
    return SizedBox(
      width: 24,
      child: Text(
        '${index + 1}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
  final hotColor = ChewieColors.getHotTagTextColor(context).withValues(
    alpha: 1 - index * 0.18,
  );
  return Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: hotColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        ChewieIcon(LoftifyIcons.hot, size: 16, color: hotColor),
        Positioned(
          top: 1,
          right: 2,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: hotColor,
              fontSize: 7,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class TagCollectionGrainScreen extends StatefulWidget {
  const TagCollectionGrainScreen({super.key, required this.tag});

  static const String routeName = "/tag/collectionAndGrain";

  final String tag;

  @override
  State<TagCollectionGrainScreen> createState() =>
      _TagCollectionGrainScreenState();
}

class _TagCollectionGrainScreenState
    extends BaseDynamicState<TagCollectionGrainScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;
  late final LazyTabLoadState _tabLoadState;

  List<String> _tabLabelList = [];
  final GlobalKey _collectionKey = GlobalKey();
  final GlobalKey _grainKey = GlobalKey();
  int _currentTabIndex = 0;
  static const List<String> _tabIdList = ['collection', 'grain'];

  @override
  void initState() {
    super.initState();
    initTab();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureTabLoaded(_currentTabIndex);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  initTab() {
    _tabLabelList = [appLocalizations.collection, appLocalizations.grain];
    final restored = PersistentTabState.restore(
      idKey: HiveUtil.tagCollectionGrainTabIdKey,
      legacyIndexKey: HiveUtil.tagCollectionGrainTabIndexKey,
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
      idKey: HiveUtil.tagCollectionGrainTabIdKey,
      legacyIndexKey: HiveUtil.tagCollectionGrainTabIndexKey,
      itemIds: _tabIdList,
      index: safeIndex,
    );
    _ensureTabLoaded(safeIndex);
  }

  void _ensureTabLoaded(int index) {
    if (!_tabLoadState.selectAndShouldLoad(index)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (index == 0) {
        final state = _collectionKey.currentState as CollectionTabState?;
        if (state == null) {
          _tabLoadState.markLoadFailed(index);
        } else {
          state.callRefresh();
        }
      } else {
        final state = _grainKey.currentState as GrainTabState?;
        if (state == null) {
          _tabLoadState.markLoadFailed(index);
        } else {
          state.callRefresh();
        }
      }
    });
  }

  Widget _buildTabView() {
    List<Widget> children = [];
    children.add(CollectionTab(key: _collectionKey, tag: widget.tag));
    children.add(GrainTab(key: _grainKey, tag: widget.tag));
    return TabBarView(
      controller: _tabController,
      children: children,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      centerTitle: true,
      titleWidget: ClickableWrapper(
        child: ItemBuilder.buildTagItem(
          context,
          widget.tag,
          TagType.normal,
          backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          showRightIcon: true,
        ),
      ),
      bottomHeight: 56,
      bottomWidget: TabBarWrapper(
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
        width: MediaQuery.sizeOf(context).width,
        background: ChewieTheme.getBackground(context),
        showBorder: ResponsiveUtil.isLandscapeLayout(),
      ),
      actions: [
        Visibility(
          visible: false,
          maintainAnimation: true,
          maintainState: true,
          maintainSize: true,
          child: ChewieIconButton(
            icon: LoftifyIcons.moreVertical,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class CollectionTab extends StatefulWidget {
  const CollectionTab({
    super.key,
    required this.tag,
  });

  final String tag;

  @override
  State<StatefulWidget> createState() => CollectionTabState();
}

class CollectionTabState extends BaseDynamicState<CollectionTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<SimpleCollectionInfo> _recommendCollectionList = [];
  final List<SimpleCollectionInfo> _hotCollectionList = [];
  final EasyRefreshController _collectionRefreshController =
      EasyRefreshController();
  bool _noMore = false;
  int _collectionOffset = 0;
  bool _collectionLoading = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildCollectionResultTab();
  }

  callRefresh() {
    _collectionRefreshController.callRefresh();
  }

  _fetchCollectionResult({bool refresh = false}) async {
    if (_collectionLoading) return;
    if (refresh) _noMore = false;
    _collectionLoading = true;
    return await TagApi.getCollectionList(
      tag: widget.tag,
      offset: refresh ? 0 : _collectionOffset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
        } else {
          List<SimpleCollectionInfo> tmp = [];
          if (value['data'] != null) {
            if (value['data']['offset'] != null) {
              _collectionOffset = value['data']['offset'];
            }
            if (value['data']['recommend'] != null) {
              tmp = (value['data']['recommend'] as List)
                  .map((e) => SimpleCollectionInfo.fromJson(e))
                  .toList();
              if (refresh) _recommendCollectionList.clear();
              for (var exist in _recommendCollectionList) {
                tmp.removeWhere((element) => element.id == exist.id);
              }
              _recommendCollectionList.addAll(tmp);
            }
            if (value['data']['hot'] != null) {
              if (refresh) _hotCollectionList.clear();
              _hotCollectionList.addAll((value['data']['hot'] as List)
                  .map((e) => SimpleCollectionInfo.fromJson(e))
                  .toList());
            }
          }
          if (mounted) setState(() {});
          if (tmp.isEmpty) {
            _noMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load tag collection list", e, t);
        IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _collectionLoading = false;
      }
    });
  }

  Widget _buildCollectionResultTab() {
    return EasyRefresh.builder(
      refreshOnStart: false,
      controller: _collectionRefreshController,
      onRefresh: () async {
        return await _fetchCollectionResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchCollectionResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => LoadMoreNotification(
        noMore: _noMore,
        onLoad: _fetchCollectionResult,
        child: CustomScrollView(
          physics: physics,
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 10),
                  if (_hotCollectionList.isEmpty ||
                      _recommendCollectionList.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      height: 160,
                      child: EmptyPlaceholder(
                        text: appLocalizations.noCollection,
                      ),
                    ),
                  if (_hotCollectionList.isNotEmpty)
                    ItemBuilder.buildTitle(
                      context,
                      title: appLocalizations.hotCollectionRank,
                      bottomMargin: 12,
                      topMargin: 0,
                    ),
                  if (_hotCollectionList.isNotEmpty)
                    _buildHotCollectionRankList(),
                  if (_recommendCollectionList.isNotEmpty)
                    ItemBuilder.buildTitle(
                      context,
                      title: appLocalizations.hotRecommend,
                      bottomMargin: 12,
                      topMargin: _hotCollectionList.isNotEmpty ? 24 : 0,
                    ),
                  if (_recommendCollectionList.isNotEmpty)
                    _buildRecommendCollectionList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendCollectionList() {
    return WaterfallFlow.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shrinkWrap: true,
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        maxCrossAxisExtent: 120,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendCollectionList.length,
      itemBuilder: (context, index) =>
          _buildRecommendCollectionItem(_recommendCollectionList[index]),
    );
  }

  Widget _buildRecommendCollectionItem(SimpleCollectionInfo info) {
    return ClickableWrapper(
      child: GestureDetector(
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            CollectionDetailScreen(
                collectionId: info.id,
                postId: 0,
                blogId: info.blogId,
                blogName: ""),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ChewieItemBuilder.buildCachedImage(
                    context: context,
                    imageUrl: info.coverUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    showLoading: false,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: ItemBuilder.buildTranslucentTag(
                    context,
                    text: "${info.postCount}",
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: ItemBuilder.buildTranslucentTag(
                    context,
                    text: "",
                    icon: const ChewieIcon(
                      LoftifyIcons.collection,
                      size: 12,
                      color: Colors.white,
                    ),
                    isCircle: true,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: ItemBuilder.buildTranslucentTag(
                    context,
                    text: StringUtil.formatCount(info.viewCount),
                    icon: const ChewieIcon(
                      LoftifyIcons.hot,
                      color: Colors.white,
                      size: 12,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                ),
              ],
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Text(
                info.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotCollectionRankList() {
    return SizedBox(
      height: 248,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: (_hotCollectionList.length / 3).ceil(),
        itemBuilder: (context, index) {
          return _buildHotCollectionRankListItem(index);
        },
      ),
    );
  }

  Widget _buildHotCollectionRankListItem(int index) {
    int trueCount = index < (_hotCollectionList.length / 3).floor()
        ? 3
        : _hotCollectionList.length % 3;
    return Container(
      margin: EdgeInsets.only(right: trueCount < 3 ? 0 : 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(trueCount, (i) {
          return _buildHotCollectionRankItem(
              i + index * 3, _hotCollectionList[i + index * 3]);
        }),
      ),
    );
  }

  Widget _buildHotCollectionRankItem(int index, SimpleCollectionInfo info) {
    return ClickableWrapper(
      child: GestureDetector(
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            CollectionDetailScreen(
              collectionId: info.id,
              postId: 0,
              blogId: info.blogId,
              blogName: "",
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(8),
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHotRankMarker(context, index),
              const SizedBox(width: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ChewieItemBuilder.buildCachedImage(
                  context: context,
                  imageUrl: info.coverUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  showLoading: false,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: Theme.of(context).textTheme.titleMedium?.apply(
                            fontSizeDelta: -1,
                            fontWeightDelta: 2,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${StringUtil.formatCount(info.subscribedCount)}${appLocalizations.subscribe} · ${StringUtil.formatCount(info.viewCount)}${appLocalizations.viewCount}",
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}

class GrainTab extends StatefulWidget {
  const GrainTab({
    super.key,
    required this.tag,
  });

  final String tag;

  @override
  State<StatefulWidget> createState() => GrainTabState();
}

class GrainTabState extends BaseDynamicState<GrainTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<SimpleGrainInfo> _hotGrainList = [];
  final List<SimpleGrainInfo> _recommendGrainList = [];
  final EasyRefreshController _grainRefreshController = EasyRefreshController();
  int _grainOffset = 0;
  bool _grainLoading = false;
  bool _noMore = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildGrainResultTab();
  }

  callRefresh() {
    _grainRefreshController.callRefresh();
  }

  _fetchGrainResult({bool refresh = false}) async {
    if (_grainLoading) return;
    if (refresh) _noMore = false;
    _grainLoading = true;
    return await TagApi.getGrainList(
      tag: widget.tag,
      offset: refresh ? 0 : _grainOffset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
        } else {
          List<SimpleGrainInfo> tmp = [];
          if (value['data'] != null) {
            if (value['data']['offset'] != null) {
              _grainOffset = value['data']['offset'];
            }
            if (value['data']['recommend'] != null) {
              tmp = (value['data']['recommend'] as List)
                  .map((e) => SimpleGrainInfo.fromJson(e))
                  .toList();
              if (refresh) _recommendGrainList.clear();
              for (var exist in _recommendGrainList) {
                tmp.removeWhere((element) => element.id == exist.id);
              }
              _recommendGrainList.addAll(tmp);
            }
            if (value['data']['hot'] != null) {
              if (refresh) _hotGrainList.clear();
              _hotGrainList.addAll((value['data']['hot'] as List)
                  .map((e) => SimpleGrainInfo.fromJson(e))
                  .toList());
            }
          }
          if (mounted) setState(() {});
          if (tmp.isEmpty) {
            _noMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load tag grain list", e, t);
        IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _grainLoading = false;
      }
    });
  }

  Widget _buildGrainResultTab() {
    return EasyRefresh.builder(
      refreshOnStart: false,
      controller: _grainRefreshController,
      onRefresh: () async {
        return await _fetchGrainResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchGrainResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => LoadMoreNotification(
        noMore: _noMore,
        onLoad: _fetchGrainResult,
        child: CustomScrollView(
          physics: physics,
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 10),
                  if (_hotGrainList.isEmpty && _recommendGrainList.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      height: 160,
                      child: EmptyPlaceholder(
                        text: appLocalizations.noGrain,
                      ),
                    ),
                  if (_hotGrainList.isNotEmpty)
                    ItemBuilder.buildTitle(
                      context,
                      title: appLocalizations.hotGrainRank,
                      bottomMargin: 12,
                      topMargin: 0,
                    ),
                  if (_hotGrainList.isNotEmpty) _buildHotGrainRankList(),
                  if (_recommendGrainList.isNotEmpty)
                    ItemBuilder.buildTitle(
                      context,
                      title: appLocalizations.hotRecommend,
                      bottomMargin: 12,
                      topMargin: _hotGrainList.isNotEmpty ? 24 : 0,
                    ),
                  if (_recommendGrainList.isNotEmpty)
                    _buildRecommendGrainList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendGrainList() {
    return WaterfallFlow.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shrinkWrap: true,
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        maxCrossAxisExtent: 120,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendGrainList.length,
      itemBuilder: (context, index) =>
          _buildRecommendGrainItem(_recommendGrainList[index]),
    );
  }

  Widget _buildRecommendGrainItem(SimpleGrainInfo info) {
    return ClickableWrapper(
      child: GestureDetector(
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            GrainDetailScreen(
              grainId: info.id,
              blogId: info.userId,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ChewieItemBuilder.buildCachedImage(
                      context: context,
                      imageUrl: info.coverUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      showLoading: false,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: ItemBuilder.buildTranslucentTag(
                    context,
                    text: "${info.postCount}",
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: ItemBuilder.buildTranslucentTag(
                    context,
                    text: "",
                    icon: const ChewieIcon(
                      LoftifyIcons.grain,
                      size: 12,
                      color: Colors.white,
                    ),
                    isCircle: true,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: ItemBuilder.buildTranslucentTag(
                    context,
                    text: StringUtil.formatCount(info.viewCount),
                    icon: const ChewieIcon(
                      LoftifyIcons.hot,
                      color: Colors.white,
                      size: 12,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                ),
              ],
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Text(
                info.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotGrainRankList() {
    return SizedBox(
      height: 248,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: (_hotGrainList.length / 3).ceil(),
        itemBuilder: (context, index) {
          return _buildHotGrainRankListItem(index);
        },
      ),
    );
  }

  Widget _buildHotGrainRankListItem(int index) {
    int trueCount = index < (_hotGrainList.length / 3).floor()
        ? 3
        : _hotGrainList.length % 3;
    return Container(
      margin: EdgeInsets.only(right: trueCount < 3 ? 0 : 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(trueCount, (i) {
          return _buildHotGrainRankItem(
              i + index * 3, _hotGrainList[i + index * 3]);
        }),
      ),
    );
  }

  Widget _buildHotGrainRankItem(int index, SimpleGrainInfo info) {
    return ClickableWrapper(
      child: GestureDetector(
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            GrainDetailScreen(
              grainId: info.id,
              blogId: info.userId,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(8),
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHotRankMarker(context, index),
              const SizedBox(width: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ChewieItemBuilder.buildCachedImage(
                  context: context,
                  imageUrl: info.coverUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  showLoading: false,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: Theme.of(context).textTheme.titleMedium?.apply(
                            fontSizeDelta: -1,
                            fontWeightDelta: 2,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${StringUtil.formatCount(info.subscribedCount)}${appLocalizations.subscribe} · ${StringUtil.formatCount(info.viewCount)}${appLocalizations.viewCount}",
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
