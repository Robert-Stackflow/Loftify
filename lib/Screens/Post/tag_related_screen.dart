import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Api/post_api.dart';
import '../../Models/enums.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';

class TagRelatedScreen extends StatefulWidget {
  const TagRelatedScreen({super.key, required this.tag});

  static const String routeName = "/tag/related";

  final String tag;

  @override
  State<TagRelatedScreen> createState() => _TagRelatedScreenState();
}

class _TagRelatedScreenState extends State<TagRelatedScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostListItem> _postList = [];
  final EasyRefreshController _refreshController = EasyRefreshController();

  int _pageCount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: AppTheme.getBackground(context),
      body: _buildMainBody(),
    );
  }

  _fetchResult({bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    if (refresh) {
      _pageCount = 0;
    } else {
      _pageCount++;
    }
    return await TagApi.getRelatedTagPostList(
      tag: widget.tag,
      count: _pageCount,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
        } else {
          List<PostListItem> tmp = [];
          if (value['data'] != null) {
            if (value['data']['list'] != null) {
              tmp = (value['data']['list'] as List)
                  .map((e) => PostListItem.fromJson(e))
                  .toList();
              if (refresh) _postList.clear();
              for (var exist in _postList) {
                tmp.removeWhere((element) => element.itemId == exist.itemId);
              }
              _postList.addAll(tmp);
            }
          }
          if (mounted) setState(() {});
          if (tmp.isEmpty) {
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (_) {
        IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  _buildMainBody() {
    return EasyRefresh.builder(
      refreshOnStart: true,
      controller: _refreshController,
      onRefresh: () async {
        return await _fetchResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => WaterfallFlow.builder(
        cacheExtent: 9999,
        physics: physics,
        padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
        gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          maxCrossAxisExtent: 300,
        ),
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            child: RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
              context,
              _postList[index],
              onLikeTap: () async {
                var item = _postList[index];
                HapticFeedback.mediumImpact();
                return await PostApi.likeOrUnLike(
                        isLike: !item.favorite,
                        postId: item.itemId,
                        blogId: item.blogInfo!.blogId)
                    .then((value) {
                  setState(() {
                    if (value['meta']['status'] != 200) {
                      IToast.showTop(context,
                          text: value['meta']['desc'] ?? value['meta']['msg']);
                    } else {
                      item.favorite = !item.favorite;
                      item.postData!.postCount!.favoriteCount +=
                          item.favorite ? 1 : -1;
                    }
                  });
                  return value['meta']['status'];
                });
              },
              excludeTag: widget.tag,
            ),
          );
        },
        itemCount: _postList.length,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      backgroundColor: AppTheme.getBackground(context),
      leading: Icons.arrow_back_rounded,
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ItemBuilder.buildTagItem(
          context,
          widget.tag,
          TagType.normal,
          shownTag: "#${widget.tag}#的相关标签",
          backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          showRightIcon: true,
          showTagLabel: false,
        ),
      ),
      center: true,
      actions: [
        ItemBuilder.buildBlankIconButton(context),
        const SizedBox(width: 5),
      ],
    );
  }
}
