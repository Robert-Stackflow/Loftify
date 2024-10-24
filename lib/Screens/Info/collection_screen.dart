import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../Post/collection_detail_screen.dart';

class CollectionScreen extends StatefulWidget {
  CollectionScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
    this.collectionCount,
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

class _CollectionScreenState extends State<CollectionScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<FullPostCollection> _collectionList = [];
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
    if (widget.infoMode != InfoMode.me) {
      _onRefresh();
    }
  }

  _fetchGrain({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _collectionList.length;
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
            if (((widget.collectionCount != null &&
                        _collectionList.length >= widget.collectionCount!) ||
                    tmp.isEmpty) &&
                !refresh) {
              _noMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          ILogger.error("Failed to load collection list", e, t);
          if (mounted) IToast.showTop("加载失败");
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
          ? MyTheme.getBackground(context)
          : Colors.transparent,
      appBar: widget.infoMode == InfoMode.me ? _buildAppBar() : null,
      body: EasyRefresh.builder(
        refreshOnStart: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoad: _onLoad,
        triggerAxis: Axis.vertical,
        childBuilder: (context, physics) {
          return _buildBody(physics);
        },
      ),
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    return ItemBuilder.buildLoadMoreNotification(
      noMore: _noMore,
      onLoad: _onLoad,
      child: WaterfallFlow.extent(
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
      ),
    );
  }

  _buildCollectionRow(
    FullPostCollection collection, {
    Function()? onTap,
    double verticalPadding = 12,
  }) {
    List<String> tags = collection.tags.split(",");
    return ItemBuilder.buildClickItem(
      GestureDetector(
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
                    child: ItemBuilder.buildCachedImage(
                      context: context,
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
                            "${collection.postCount}篇 · 更新于${Utils.formatTimestamp(collection.lastPublishTime)}",
                            style: Theme.of(context).textTheme.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 20,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              cacheExtent: 9999,
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildDesktopAppBar(
      context: context,
      showBack: true,
      title: "我的合集",
    );
  }
}
