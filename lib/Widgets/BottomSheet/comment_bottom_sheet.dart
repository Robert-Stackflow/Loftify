import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Models/post_detail_response.dart';

import '../../Api/post_api.dart';
import '../../Resources/theme.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
import '../Custom/sliver_appbar_delegate.dart';
import '../Item/item_builder.dart';

class CommentBottomSheet extends StatefulWidget {
  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.blogId,
    required this.publishTime,
    this.showDetail = false,
  });

  final int postId;
  final int blogId;
  final int publishTime;
  final bool showDetail;

  @override
  CommentBottomSheetState createState() => CommentBottomSheetState();
}

class CommentBottomSheetState extends State<CommentBottomSheet> {
  int l1CommentOffset = 0;
  bool isInited = false;
  int totalHotComments = 0;
  List<Comment> hotComments = [];
  List<Comment> newComments = [];
  bool loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      _onRefresh();
    });
  }

  _fetchHotComments() async {
    return await PostApi.getHotComments(
      postId: widget.postId,
      blogId: widget.blogId,
      postPublishTime: widget.publishTime,
    ).then((value) {
      try {
        if (value == null) return IndicatorResult.fail;
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
          return IndicatorResult.fail;
        } else {
          totalHotComments = value['data']['hotTotal'];
          hotComments.clear();
          List<dynamic> comments = value['data']['hotList'] as List;
          for (var comment in comments) {
            hotComments.add(Comment.fromJson(comment));
          }
          return IndicatorResult.success;
        }
      } catch (_) {
        IToast.showTop(context, text: "热门评论加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
      }
    });
  }

  _fetchComments({bool refresh = false}) async {
    if (loading) return;
    loading = true;
    return await PostApi.getL1Comments(
      postId: widget.postId,
      blogId: widget.blogId,
      offset: refresh ? 0 : l1CommentOffset,
    ).then((value) {
      try {
        if (value == null) return IndicatorResult.fail;
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
          return IndicatorResult.fail;
        } else {
          l1CommentOffset = value['data']['offset'];
          if (refresh) newComments.clear();
          List<dynamic> comments = value['data']['list'] as List;
          for (var comment in comments) {
            newComments.add(Comment.fromJson(comment));
          }
          if (comments.isEmpty && !refresh) {
            return IndicatorResult.noMore;
          }
          return IndicatorResult.success;
        }
      } catch (_) {
        IToast.showTop(context, text: "最新评论加载失败");
        return IndicatorResult.fail;
      } finally {
        loading = false;
        isInited = true;
        if (mounted) setState(() {});
      }
    });
  }

  _fetchL2Comments(Comment currentComment) async {
    currentComment.l2CommentLoading = true;
    if (mounted) setState(() {});
    return await PostApi.getL2Comments(
      id: currentComment.id,
      offset: currentComment.l2CommentOffset,
      postId: widget.postId,
      blogId: widget.blogId,
    ).then((value) {
      try {
        if (value == null) return IndicatorResult.fail;
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
          return IndicatorResult.fail;
        } else {
          currentComment.l2CommentOffset = value['data']['offset'];
          List<dynamic> comments = value['data']['list'] as List;
          for (var comment in comments) {
            currentComment.l2Comments.add(Comment.fromJson(comment));
          }
          return IndicatorResult.success;
        }
      } catch (_) {
        IToast.showTop(context, text: "回复加载失败");
        return IndicatorResult.fail;
      } finally {
        currentComment.l2CommentLoading = false;
        if (mounted) setState(() {});
      }
    });
  }

  _onRefresh() async {
    // var t1 = await _fetchHotComments();
    var t1 = IndicatorResult.success;
    var t2 = await _fetchComments(refresh: true);
    return t1 == IndicatorResult.success && t2 == IndicatorResult.success
        ? IndicatorResult.success
        : IndicatorResult.fail;
  }

  _onLoad() async {
    return await _fetchComments();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      height: MediaQuery.sizeOf(context).height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: EasyRefresh(
              controller: _refreshController,
              onLoad: _onLoad,
              triggerAxis: Axis.vertical,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  _buildHeader() {
    return Container();
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        // if (hotComments.isNotEmpty)
        //   SliverPersistentHeader(
        //     pinned: true,
        //     delegate: SliverHeaderDelegate(
        //       maxHeight: 50,
        //       minHeight: 50,
        //       child: Container(
        //         color: AppTheme.getBackground(context),
        //         child: ItemBuilder.buildTitle(
        //           context,
        //           title: "热门评论",
        //           bottomMargin: 0,
        //           topMargin: 0,
        //         ),
        //       ),
        //     ),
        //   ),
        // if (hotComments.isNotEmpty) _buildComments(hotComments),
        if (newComments.isEmpty)
          SliverToBoxAdapter(
            child: !isInited
                ? Container(
                    alignment: Alignment.center,
                    child: ItemBuilder.buildLoadingDialog(
                      context,
                      text: "",
                      background: AppTheme.getBackground(context),
                      size: 40,
                      topPadding: 40,
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    child: ItemBuilder.buildEmptyPlaceholder(
                        context: context, text: "暂无评论"),
                  ),
          ),
        if (newComments.isNotEmpty)
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverHeaderDelegate(
              maxHeight: 50,
              minHeight: 50,
              child: Container(
                color: AppTheme.getBackground(context),
                child: ItemBuilder.buildTitle(
                  context,
                  title: "最新评论",
                  bottomMargin: 0,
                  topMargin: 0,
                  textStyle: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.apply(fontWeightDelta: 2),
                ),
              ),
            ),
          ),
        if (newComments.isNotEmpty) _buildComments(newComments),
      ],
    );
  }

  _buildComments(List<Comment> comments) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          ListView.builder(
            shrinkWrap: true,
            itemCount: comments.length,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => ItemBuilder.buildCommentRow(
              context,
              comments[index],
              padding: const EdgeInsets.only(bottom: 12),
              writerId: widget.blogId,
              l2Padding: const EdgeInsets.only(top: 12, right: 0),
              onL2CommentTap: (comment) {
                HapticFeedback.mediumImpact();
                _fetchL2Comments(comment);
              },
            ),
          )
        ],
      ),
    );
  }
}
