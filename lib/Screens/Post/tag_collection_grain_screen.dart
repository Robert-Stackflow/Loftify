import 'package:flutter/material.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Models/tag_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Post/collection_detail_screen.dart';
import 'package:loftify/Utils/asset_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/route_util.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Utils/enums.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Custom/custom_tab_indicator.dart';
import '../../Widgets/Custom/sliver_appbar_delegate.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import 'grain_detail_screen.dart';

class TagCollectionGrainScreen extends StatefulWidget {
  const TagCollectionGrainScreen({super.key, required this.tag});

  static const String routeName = "/tag/collectionAndGrain";

  final String tag;

  @override
  State<TagCollectionGrainScreen> createState() =>
      _TagCollectionGrainScreenState();
}

class _TagCollectionGrainScreenState extends State<TagCollectionGrainScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<Tab> _tabList = [];
  final GlobalKey _collectionKey = GlobalKey();
  final GlobalKey _grainKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    initTab();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MyTheme.getBackground(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            Expanded(
              child: _buildMainBody(),
            ),
          ],
        ),
      ),
    );
  }

  initTab() {
    _tabList
      ..add(const Tab(text: "合集"))
      ..add(const Tab(text: "粮单"));
    _tabController = TabController(length: _tabList.length, vsync: this);
  }

  _buildMainBody() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_tabList.isNotEmpty)
          SliverPersistentHeader(
            key: ValueKey(Utils.getRandomString()),
            pinned: true,
            delegate: SliverAppBarDelegate(
              radius: 0,
              background: MyTheme.getBackground(context),
              tabBar: TabBar(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                controller: _tabController,
                tabs: _tabList,
                labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                enableFeedback: true,
                dividerHeight: 0,
                physics: const BouncingScrollPhysics(),
                labelStyle: Theme.of(context).textTheme.titleLarge,
                unselectedLabelStyle: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.apply(color: Colors.grey),
                indicator: CustomTabIndicator(
                  borderColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        if (_tabList.isNotEmpty)
          SliverFillRemaining(
            child: _buildTabView(),
          ),
      ],
    );
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
    return ItemBuilder.buildAppBar(
      context: context,
      backgroundColor: MyTheme.getBackground(context),
      leading: Icons.arrow_back_rounded,
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: ItemBuilder.buildClickItem(
        ItemBuilder.buildTagItem(
          context,
          widget.tag,
          TagType.normal,
          backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          showRightIcon: true,
        ),
      ),
      center: true,
      actions: [
        Visibility(
          visible: false,
          maintainAnimation: true,
          maintainState: true,
          maintainSize: true,
          child: ItemBuilder.buildIconButton(
              context: context,
              icon: Icon(Icons.more_vert_rounded,
                  color: Theme.of(context).iconTheme.color),
              onTap: () {}),
        ),
        const SizedBox(width: 5),
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

class CollectionTabState extends State<CollectionTab>
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
      } catch (_) {
        IToast.showTop("加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _collectionLoading = false;
      }
    });
  }

  Widget _buildCollectionResultTab() {
    return EasyRefresh.builder(
      refreshOnStart: true,
      controller: _collectionRefreshController,
      onRefresh: () async {
        return await _fetchCollectionResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchCollectionResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => ItemBuilder.buildLoadMoreNotification(
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
                      child: ItemBuilder.buildEmptyPlaceholder(
                        context: context,
                        text: "暂无合集",
                      ),
                    ),
                  if (_hotCollectionList.isNotEmpty)
                    ItemBuilder.buildTitle(
                      context,
                      title: "热门合集榜",
                      bottomMargin: 12,
                      topMargin: 0,
                    ),
                  if (_hotCollectionList.isNotEmpty)
                    _buildHotCollectionRankList(),
                  if (_recommendCollectionList.isNotEmpty)
                    ItemBuilder.buildTitle(
                      context,
                      title: "热门推荐",
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
    return ItemBuilder.buildClickItem(
      GestureDetector(
        onTap: () {
          RouteUtil.pushCupertinoRoute(
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
                  child: ItemBuilder.buildCachedImage(
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
                  child: ItemBuilder.buildTransparentTag(
                    context,
                    text: "${info.postCount}",
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: ItemBuilder.buildTransparentTag(
                    context,
                    text: "",
                    icon: AssetUtil.load(
                      AssetUtil.collectionWhiteIcon,
                      size: 12,
                    ),
                    isCircle: true,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: ItemBuilder.buildTransparentTag(
                    context,
                    text: Utils.formatCount(info.viewCount),
                    icon: const Icon(
                      Icons.local_fire_department_rounded,
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

  String? getIcon(int index) {
    switch (index) {
      case 0:
        return AssetUtil.hottestIcon;
      case 1:
        return AssetUtil.hotIcon;
      case 2:
        return AssetUtil.hotlessIcon;
      default:
        return null;
    }
  }

  Widget _buildHotCollectionRankItem(int index, SimpleCollectionInfo info) {
    String? icon = getIcon(index);
    return ItemBuilder.buildClickItem(
      GestureDetector(
        onTap: () {
          RouteUtil.pushCupertinoRoute(
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
              Container(
                height: 24,
                width: 24,
                alignment: Alignment.center,
                decoration: icon != null
                    ? BoxDecoration(
                        image: AssetUtil.loadDecorationImage(icon),
                      )
                    : null,
                child: Text(
                  "${index + 1}",
                  style: Theme.of(context).textTheme.labelLarge?.apply(
                        fontWeightDelta: 3,
                        color: icon != null ? Colors.transparent : null,
                      ),
                ),
              ),
              const SizedBox(width: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ItemBuilder.buildCachedImage(
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
                      "${Utils.formatCount(info.subscribedCount)}订阅 · ${Utils.formatCount(info.viewCount)}浏览",
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

class GrainTabState extends State<GrainTab> with AutomaticKeepAliveClientMixin {
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
      } catch (_) {
        IToast.showTop("加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _grainLoading = false;
      }
    });
  }

  Widget _buildGrainResultTab() {
    return EasyRefresh.builder(
      refreshOnStart: true,
      controller: _grainRefreshController,
      onRefresh: () async {
        return await _fetchGrainResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchGrainResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => ItemBuilder.buildLoadMoreNotification(
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
                      child: ItemBuilder.buildEmptyPlaceholder(
                        context: context,
                        text: "暂无粮单",
                      ),
                    ),
                  if (_hotGrainList.isNotEmpty)
                    ItemBuilder.buildTitle(
                      context,
                      title: "热门粮单榜",
                      bottomMargin: 12,
                      topMargin: 0,
                    ),
                  if (_hotGrainList.isNotEmpty) _buildHotGrainRankList(),
                  if (_recommendGrainList.isNotEmpty)
                    ItemBuilder.buildTitle(
                      context,
                      title: "热门推荐",
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
    return ItemBuilder.buildClickItem(
      GestureDetector(
        onTap: () {
          RouteUtil.pushCupertinoRoute(
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
                    child: ItemBuilder.buildCachedImage(
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
                  child: ItemBuilder.buildTransparentTag(
                    context,
                    text: "${info.postCount}",
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: ItemBuilder.buildTransparentTag(
                    context,
                    text: "",
                    icon: AssetUtil.load(
                      AssetUtil.grainWhiteIcon,
                      size: 12,
                    ),
                    isCircle: true,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: ItemBuilder.buildTransparentTag(
                    context,
                    text: Utils.formatCount(info.viewCount),
                    icon: const Icon(
                      Icons.local_fire_department_rounded,
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

  String? getIcon(int index) {
    switch (index) {
      case 0:
        return AssetUtil.hottestIcon;
      case 1:
        return AssetUtil.hotIcon;
      case 2:
        return AssetUtil.hotlessIcon;
      default:
        return null;
    }
  }

  Widget _buildHotGrainRankItem(int index, SimpleGrainInfo info) {
    String? icon = getIcon(index);
    return ItemBuilder.buildClickItem(
      GestureDetector(
        onTap: () {
          RouteUtil.pushCupertinoRoute(
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
              Container(
                height: 24,
                width: 24,
                alignment: Alignment.center,
                decoration: icon != null
                    ? BoxDecoration(
                        image: AssetUtil.loadDecorationImage(icon),
                      )
                    : null,
                child: Text(
                  "${index + 1}",
                  style: Theme.of(context).textTheme.labelLarge?.apply(
                        fontWeightDelta: 3,
                        color: icon != null ? Colors.transparent : null,
                      ),
                ),
              ),
              const SizedBox(width: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ItemBuilder.buildCachedImage(
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
                      "${Utils.formatCount(info.subscribedCount)}订阅 · ${Utils.formatCount(info.viewCount)}浏览",
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
