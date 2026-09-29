import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../l10n/l10n.dart';
import '../Post/collection_detail_screen.dart';

class CollectionScreen extends StatefulWidgetForNested {
  CollectionScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
    this.collectionCount,
    super.nested = false,
    super.refreshListenable,
    super.refreshId = 'collection',
  }) {
    if (infoMode == InfoMode.other) {
      assert(blogName != null);
    }
  }

  final InfoMode infoMode;
  final int? blogId;
  final int? collectionCount;
  final String? blogName;
  final ScrollController? scrollController;

  static const String routeName = "/info/collection";

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends BaseDynamicState<CollectionScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        NestedRefreshSignalMixin<CollectionScreen> {
  @override
  bool get wantKeepAlive => true;
  final List<FullPostCollection> _collectionList = [];
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  InitPhase _initPhase = InitPhase.haveNotConnected;

  @override
  void initState() {
    super.initState();
    bindNestedRefreshSignal(() {
      _refreshController.callRefresh(
        overOffset: 28,
        duration: const Duration(milliseconds: 140),
      );
    });
    if (widget.nested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onRefresh();
      });
    } else {
      _initPhase = InitPhase.successful;
      setState(() {});
    }
  }

  @override
  void dispose() {
    unbindNestedRefreshSignal();
    _refreshController.dispose();
    super.dispose();
  }

  _fetchGrain({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _collectionList.length;
    if (_initPhase != InitPhase.successful) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      String blogName = widget.infoMode == InfoMode.me
          ? blogInfo!.blogName
          : widget.blogName!;
      return await UserApi.getCollectionList(blogName: blogName, offset: offset)
          .then((value) {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            return IndicatorResult.fail;
          } else {
            List<FullPostCollection> tmp = [];
            if (refresh) _collectionList.clear();
            for (var e in (value['response']['collections'] as List)) {
              if (e != null &&
                  _collectionList
                          .indexWhere((element) => element.id == e['id']) ==
                      -1) {
                tmp.add(FullPostCollection.fromJson(e));
              }
            }
            _collectionList.addAll(tmp);
            if (mounted) setState(() {});
            _initPhase = InitPhase.successful;
            _noMore = (widget.collectionCount != null &&
                    _collectionList.length >= widget.collectionCount!) ||
                tmp.isEmpty;
            if (_noMore && !refresh) {
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          _initPhase = InitPhase.failed;
          ILogger.error("Failed to load collection list", e, t);
          if (mounted) IToast.showTop(appLocalizations.loadFailed);
          return IndicatorResult.fail;
        } finally {
          if (mounted) setState(() {});
          _loading = false;
        }
      });
    });
  }

  _onRefresh() async {
    return await _fetchGrain(refresh: true);
  }

  _onLoad() async {
    return await _fetchGrain();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: widget.infoMode == InfoMode.me
          ? ChewieTheme.getBackground(context)
          : Colors.transparent,
      appBar: widget.infoMode == InfoMode.me ? _buildAppBar() : null,
      body: _buildBody(),
    );
  }

  _buildBody() {
    switch (_initPhase) {
      case InitPhase.connecting:
        return const LoadingWidget(background: Colors.transparent);
      case InitPhase.failed:
        return CustomErrorWidget(
          onTap: _onRefresh,
        );
      case InitPhase.successful:
        return EasyRefresh.builder(
          header: widget.nested ? buildNestedRefreshHeader() : null,
          refreshOnStart: !widget.nested,
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoad: _noMore ? null : _onLoad,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) {
            return _collectionList.isNotEmpty
                ? _buildMainBody(physics)
                : EmptyPlaceholder(
                    text: appLocalizations.noCollection,
                    physics: physics,
                    shrinkWrap: false,
                  );
          },
        );
      default:
        return Container();
    }
  }

  Widget _buildMainBody(ScrollPhysics physics) {
    return WaterfallFlow.extent(
      controller: widget.scrollController,
      maxCrossAxisExtent: 560,
      physics: physics,
      padding: const EdgeInsets.only(bottom: 20),
      children: List.generate(
        _collectionList.length,
        (index) => _buildCollectionRow(
          _collectionList[index],
          verticalPadding: 8,
          onTap: () {
            RouteUtil.pushPanelCupertinoRoute(
              context,
              CollectionDetailScreen(
                collectionId: _collectionList[index].id,
                blogId: _collectionList[index].blogId,
                blogName: "",
                postId: 0,
              ),
            );
          },
        ),
      ),
    );
  }

  _buildCollectionRow(
    FullPostCollection collection, {
    Function()? onTap,
    double verticalPadding = 12,
  }) {
    List<String> tags = collection.tags.split(",");
    return ClickableGestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding:
            EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MyCachedNetworkImage(
                    imageUrl: collection.coverUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    showLoading: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${collection.postCount}${appLocalizations.chapter} · ${appLocalizations.updateAt}${TimeUtil.formatTimestamp(collection.lastPublishTime)}",
                          style: Theme.of(context).textTheme.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: 20,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ...List.generate(
                                tags.length,
                                (index) => Container(
                                  margin: const EdgeInsets.only(right: 5),
                                  child: ItemBuilder.buildSmallTagItem(
                                    context,
                                    tags[index],
                                    showIcon: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.myCollections,
    );
  }
}
