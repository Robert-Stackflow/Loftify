import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Models/post_detail_response.dart';

import '../../Api/post_api.dart';
import '../../l10n/l10n.dart';
import '../Design/loftify_surfaces.dart';
import '../Item/loftify_item_builder.dart';

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
  List<Comment> newComments = [];
  bool loading = false;
  bool _loadFailed = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onRefresh();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<IndicatorResult> _fetchComments({bool refresh = false}) async {
    if (loading) return IndicatorResult.none;
    loading = true;
    if (refresh) {
      _loadFailed = false;
      _noMore = false;
    }
    return await PostApi.getL1Comments(
      postId: widget.postId,
      blogId: widget.blogId,
      offset: refresh ? 0 : l1CommentOffset,
    ).then((value) {
      try {
        if (value == null) return IndicatorResult.fail;
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          l1CommentOffset = value['data']['offset'];
          if (refresh) newComments.clear();
          List<dynamic> comments = value['data']['list'] as List;
          for (var comment in comments) {
            newComments.add(Comment.fromJson(comment));
          }
          _loadFailed = false;
          if (comments.isEmpty && !refresh) {
            _noMore = true;
            return IndicatorResult.noMore;
          }
          return IndicatorResult.success;
        }
      } catch (e, t) {
        ILogger.error("Failed to load newest comments", e, t);
        if (refresh) _loadFailed = true;
        return IndicatorResult.fail;
      } finally {
        loading = false;
        isInited = true;
        if (mounted) setState(() {});
      }
    });
  }

  Future<IndicatorResult> _fetchL2Comments(Comment currentComment) async {
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
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          currentComment.l2CommentOffset = value['data']['offset'];
          List<dynamic> comments = value['data']['list'] as List;
          for (var comment in comments) {
            currentComment.l2Comments.add(Comment.fromJson(comment));
          }
          return IndicatorResult.success;
        }
      } catch (e, t) {
        ILogger.error("Failed to load comment reply", e, t);
        IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        currentComment.l2CommentLoading = false;
        if (mounted) setState(() {});
      }
    });
  }

  Future<IndicatorResult> _onRefresh() async {
    return _fetchComments(refresh: true);
  }

  Future<IndicatorResult> _onLoad() async {
    return await _fetchComments();
  }

  @override
  Widget build(BuildContext context) {
    return LoftifyCommentPanel(
      title: appLocalizations.latestComment,
      body: EasyRefresh(
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoad: _noMore ? null : _onLoad,
        triggerAxis: Axis.vertical,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        if (newComments.isEmpty)
          SliverToBoxAdapter(
            child: !isInited
                ? Container(
                    alignment: Alignment.center,
                    child: LoadingWidget(
                      text: "",
                      background: ChewieTheme.getBackground(context),
                      size: 40,
                      topPadding: 40,
                    ),
                  )
                : _loadFailed
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: CustomErrorWidget(onTap: _onRefresh),
                      )
                    : Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        child:
                            EmptyPlaceholder(text: appLocalizations.noComment),
                      ),
          ),
        if (newComments.isNotEmpty) _buildComments(newComments),
      ],
    );
  }

  Widget _buildComments(List<Comment> comments) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 8),
      sliver: SliverList.builder(
        itemCount: comments.length,
        itemBuilder: (context, index) => LoftifyItemBuilder.buildCommentRow(
          context,
          comments[index],
          writerId: widget.blogId,
          onL2CommentTap: (comment) {
            HapticFeedback.mediumImpact();
            _fetchL2Comments(comment);
          },
        ),
      ),
    );
  }
}

/// Responsive frame shared by the live comment sheet and deterministic layout
/// tests. The body owns the only scroll chain; the panel header remains stable.
class LoftifyCommentPanel extends StatelessWidget {
  const LoftifyCommentPanel({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final visibleHeight = max(0.0, media.size.height - media.viewInsets.bottom);
    final panelHeight = min(visibleHeight * 0.82, 760.0);
    return SafeArea(
      top: false,
      child: SizedBox(
        key: const ValueKey('loftify-comment-panel'),
        height: panelHeight,
        child: LoftifyPanel(
          title: title,
          semanticLabel: title,
          expandBody: true,
          body: body,
        ),
      ),
    );
  }
}
