import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/collection_api.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Screens/Post/collection_detail_screen.dart';

import '../../Models/history_response.dart';
import '../../Resources/theme.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../General/EasyRefresh/easy_refresh.dart';
import '../Item/item_builder.dart';
import '../PostItem/common_info_post_item_builder.dart';

class CollectionBottomSheet extends StatefulWidget {
  const CollectionBottomSheet({
    super.key,
    required this.collectionId,
    required this.postId,
    required this.blogId,
    required this.blogName,
    required this.postCollection,
  });

  final FullPostCollection postCollection;
  final int collectionId;
  final int postId;
  final int blogId;
  final String blogName;

  @override
  CollectionBottomSheetState createState() => CollectionBottomSheetState();
}

class CollectionBottomSheetState extends State<CollectionBottomSheet> {
  int offset = 0;
  bool subscribed = false;
  SimpleBlogInfo? blogInfo;
  bool loading = false;
  bool isInited = false;
  List<PostDetailData> posts = [];
  final List<ArchiveData> _archiveDataList = [];
  final EasyRefreshController _refreshController = EasyRefreshController();

  @override
  void initState() {
    super.initState();
  }

  _fetchData({
    int upDown = -1,
    int startPostId = 0,
  }) async {
    if (loading) return;
    loading = true;
    return await CollectionApi.getCollection(
      postId: widget.postId,
      collectionId: widget.collectionId,
      blogId: widget.blogId,
      blogName: widget.blogName,
      startPostId: startPostId,
      upDown: upDown,
    ).then((value) {
      try {
        if (value['meta']['status'] != 200) {
          IToast.showTop(context,
              text: value['meta']['desc'] ?? value['meta']['msg']);
          return IndicatorResult.fail;
        } else {
          subscribed = value['response']['subscribed'];
          blogInfo = SimpleBlogInfo.fromJson(value['response']['blogInfo']);
          List<dynamic> t = value['response']['items'];
          List<PostDetailData> newPosts = [];
          for (var e in t) {
            if (e != null) {
              newPosts.add(PostDetailData.fromJson(e));
            }
          }
          if (upDown == -1) {
            posts.clear();
            posts.addAll(newPosts);
          } else {
            List<PostDetailData> notExistPostList = [];
            for (var e in newPosts) {
              if (posts.indexWhere(
                      (element) => element.post!.id == e.post!.id) ==
                  -1) {
                notExistPostList.add(e);
              }
            }
            newPosts = notExistPostList;
            if (upDown == 0) {
              posts.insertAll(0, newPosts);
            } else if (upDown == 1) {
              posts.addAll(newPosts);
            }
          }
          Map<String, int> monthCount = {};
          for (var e in posts) {
            String yearMonth = Utils.formatYearMonth(e.post!.publishTime);
            monthCount.putIfAbsent(yearMonth, () => 0);
            monthCount[yearMonth] = monthCount[yearMonth]! + 1;
          }
          _archiveDataList.clear();
          for (var e in monthCount.keys) {
            _archiveDataList.add(ArchiveData(
              desc: e,
              count: monthCount[e] ?? 0,
              endTime: 0,
              startTime: 0,
            ));
          }
          if (mounted) setState(() {});
          if (posts.length >= widget.postCollection.postCount ||
              newPosts.isEmpty) {
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e) {
        if (mounted) IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        loading = false;
      }
    });
  }

  _onRefresh() async {
    if (!isInited) {
      isInited = true;
      return await _fetchData(
          upDown: -1, startPostId: posts.length > 1 ? posts.first.post!.id : 0);
    } else {
      return await _fetchData(
          upDown: 0, startPostId: posts.length > 1 ? posts.first.post!.id : 0);
    }
  }

  _onLoad() async {
    return await _fetchData(
        upDown: 1, startPostId: posts.length > 1 ? posts.last.post!.id : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        color: AppTheme.getBackground(context),
      ),
      height: MediaQuery.sizeOf(context).height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: EasyRefresh(
              refreshOnStart: true,
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoad: _onLoad,
              triggerAxis: Axis.vertical,
              child: _buildNineGridGroup(),
            ),
          ),
        ],
      ),
    );
  }

  _buildHeader() {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushCupertinoRoute(
          context,
          CollectionDetailScreen(
            blogId: widget.blogId,
            blogName: widget.blogName,
            collectionId: widget.collectionId,
            postId: widget.postId,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ItemBuilder.buildCachedImage(
                context: context,
                imageUrl: widget.postCollection.coverUrl,
                width: 50,
                height: 50,
                showLoading: false,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.postCollection.name}（${widget.postCollection.postCount}篇）",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.apply(fontWeightDelta: 2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.postCollection.description.isNotEmpty)
                    Text(
                      widget.postCollection.description,
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ItemBuilder.buildFramedButton(
                context: context,
                isFollowed: subscribed,
                positiveText: "已订阅",
                negtiveText: "订阅",
                onTap: () {
                  HapticFeedback.mediumImpact();
                  CollectionApi.subscribeOrUnSubscribe(
                    collectionId: widget.collectionId,
                    isSubscribe: !subscribed,
                  ).then((value) {
                    if (value['meta']['status'] != 200) {
                      IToast.showTop(context,
                          text: value['meta']['desc'] ?? value['meta']['msg']);
                    } else {
                      subscribed = !subscribed;
                      setState(() {});
                    }
                  });
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildNineGridGroup() {
    List<Widget> widgets = [];
    int startIndex = 0;
    for (var e in _archiveDataList) {
      if (posts.length < startIndex) {
        break;
      }
      if (e.count == 0) continue;
      int count = e.count;
      if (posts.length < startIndex + count) {
        count = posts.length - startIndex;
      }
      widgets.add(Container(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          "${e.desc}（${e.count}篇）",
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ));
      widgets.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    return ListView(
      padding: EdgeInsets.zero,
      children: widgets,
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return GridView.extent(
      padding: const EdgeInsets.only(top: 12),
      shrinkWrap: true,
      maxCrossAxisExtent: 160,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(count, (index) {
        int trueIndex = startIndex + index;
        return CommonInfoItemBuilder.buildNineGridPostItem(
          context,
          posts[trueIndex],
          wh: (MediaQuery.sizeOf(context).width - 22) / 3,
          activePostId: widget.postId,
        );
      }),
    );
  }
}
