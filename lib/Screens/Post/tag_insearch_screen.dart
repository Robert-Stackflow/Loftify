import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Api/post_api.dart';
import '../../Models/enums.dart';
import '../../Utils/utils.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';

class TagInsearchScreen extends StatefulWidget {
  const TagInsearchScreen({super.key, required this.tag});

  static const String routeName = "/tag/insearch";

  final String tag;

  @override
  State<TagInsearchScreen> createState() => _TagInsearchScreenState();
}

class _TagInsearchScreenState extends State<TagInsearchScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostListItem> _postList = [];
  final List<String> _relatedTagList = [];
  final EasyRefreshController _refreshController = EasyRefreshController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _offset = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        _postList.clear();
        if (mounted) setState(() {});
      }
    });
    _fetchRelatedTag();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   FocusScope.of(context).requestFocus(_focusNode);
    // });
    Future.delayed(const Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: AppTheme.getBackground(context),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_relatedTagList.isNotEmpty && _postList.isEmpty)
                      ItemBuilder.buildTitle(context,
                          title: "大家都在搜", bottomMargin: 8),
                    if (_relatedTagList.isNotEmpty && _postList.isEmpty)
                      ItemBuilder.buildWrapTagList(
                        context,
                        _relatedTagList,
                        onTap: (str) {
                          _searchController.text = str;
                          _performSearch(str);
                        },
                      ),
                  ],
                ),
                if (_postList.isNotEmpty) _buildResultList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _performSearch(String key) {
    if (Utils.isNotEmpty(key)) {
      _fetchResult(key, refresh: true);
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  _fetchRelatedTag() async {
    TagApi.getRecommendRelatedTag(
      tag: widget.tag,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
        } else {
          List<String> tmp = [];
          if (value['data'] != null) {
            if (value['data']['list'] != null) {
              tmp = (value['data']['list'] as List)
                  .map((e) => e['tag'] as String)
                  .toList();
            }
          }
          _relatedTagList.clear();
          _relatedTagList.addAll(tmp);
          if (mounted) setState(() {});
        }
      } catch (_) {}
    });
  }

  _fetchResult(String key, {bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    return await TagApi.getSearchPostList(
      tag: widget.tag,
      key: key,
      offset: refresh ? 0 : _offset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
        } else {
          List<PostListItem> tmp = [];
          if (value['data'] != null) {
            _offset = value['data']['offset'];
            if (value['data']['postList'] != null) {
              tmp = (value['data']['postList'] as List)
                  .map((e) => PostListItem.fromJson(e))
                  .toList();
              if (refresh) _postList.clear();
              for (var exist in _postList) {
                tmp.removeWhere((element) =>
                    element.postData!.postView.id ==
                    exist.postData!.postView.id);
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

  _buildResultList() {
    return EasyRefresh.builder(
      controller: _refreshController,
      onRefresh: () async {
        return await _fetchResult(_searchController.text, refresh: true);
      },
      onLoad: () async {
        return await _fetchResult(_searchController.text);
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => WaterfallFlow.builder(
        physics: physics,
        cacheExtent: 9999,
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

  Widget _buildSearchBar() {
    return Container(
      height: 35,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ItemBuilder.buildSearchBar(
              focusNode: _focusNode,
              context: context,
              hintText: "多个搜索词以空格隔开",
              onSubmitted: (value) {
                _performSearch(value);
              },
              controller: _searchController,
            ),
          ),
          const SizedBox(width: 12),
          ItemBuilder.buildIconTextButton(
            context,
            showIcon: false,
            text: "搜索",
            onTap: () {
              _performSearch(_searchController.text);
            },
          ),
        ],
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
      title: ItemBuilder.buildTagItem(
        context,
        widget.tag,
        TagType.normal,
        shownTag: "在#${widget.tag}#内搜索",
        backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
        color: Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        showRightIcon: true,
        showTagLabel: false,
      ),
      center: true,
      actions: [
        ItemBuilder.buildBlankIconButton(context),
        const SizedBox(width: 5),
      ],
    );
  }
}
