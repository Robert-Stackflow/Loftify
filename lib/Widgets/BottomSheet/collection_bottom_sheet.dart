import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/collection_api.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Screens/Post/collection_detail_screen.dart';

import '../../Models/history_response.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../l10n/l10n.dart';
import '../Design/loftify_controls.dart';
import '../Design/loftify_surfaces.dart';
import '../Item/item_builder.dart';
import '../PostItem/common_info_post_item_builder.dart';
import '../PostItem/loftify_post_archive_grid.dart';
import '../loftify_icons.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool bottomNoMore = false;
  bool isOldest = false;

  @override
  void initState() {
    super.initState();
    subscribed = widget.postCollection.subscribed;
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<IndicatorResult> _fetchData({
    int upDown = -1,
    int startPostId = 0,
    bool showLoading = false,
  }) async {
    if (loading ||
        (upDown != -1 && startPostId == 0) ||
        (upDown == 1 && bottomNoMore)) {
      return IndicatorResult.none;
    }
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: appLocalizations.loading);
    }
    loading = true;
    return await CollectionApi.getCollection(
      postId: widget.postId,
      collectionId: widget.collectionId,
      blogId: widget.blogId,
      blogName: widget.blogName,
      startPostId: startPostId,
      upDown: upDown,
      order: isOldest ? 1 : 0,
    ).then((value) {
      try {
        if (value['meta']['status'] != 200) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
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
            String yearMonth = formatLocalizedYearMonth(e.post!.publishTime);
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
            if (upDown == 1) {
              bottomNoMore = true;
            }
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load collection detail list", e, t);
        if (mounted) IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (showLoading) CustomLoadingDialog.dismissLoading();
        if (mounted) setState(() {});
        loading = false;
      }
    });
  }

  Future<IndicatorResult> _onRefresh({
    bool showLoading = false,
  }) async {
    if (!isInited) {
      isInited = true;
      return await _fetchData(
        upDown: -1,
        startPostId: posts.length > 1 ? posts.first.post!.id : 0,
        showLoading: showLoading,
      );
    } else {
      return await _fetchData(
        upDown: 0,
        startPostId: posts.length > 1 ? posts.first.post!.id : 0,
        showLoading: showLoading,
      );
    }
  }

  Future<IndicatorResult> _onLoad() async {
    return await _fetchData(
        upDown: 1, startPostId: posts.length > 1 ? posts.last.post!.id : 0);
  }

  @override
  Widget build(BuildContext context) {
    return LoftifyCollectionPanelFrame(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.design.spacing.lg),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: EasyRefresh(
                refreshOnStart: true,
                controller: _refreshController,
                onRefresh: _onRefresh,
                onLoad: bottomNoMore ? null : _onLoad,
                triggerAxis: Axis.vertical,
                child: _buildNineGridGroup(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final design = context.design;
    final followButton = LoftifyButton(
      label:
          subscribed ? appLocalizations.subscribed : appLocalizations.subscribe,
      variant: subscribed
          ? LoftifyButtonVariant.secondary
          : LoftifyButtonVariant.tonal,
      size: LoftifyButtonSize.compact,
      onPressed: _toggleSubscribe,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: design.spacing.lg,
        horizontal: design.spacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                CollectionDetailScreen(
                  blogId: widget.blogId,
                  blogName: widget.blogName,
                  collectionId: widget.collectionId,
                  postId: widget.postId,
                ),
              );
            },
            child: ClickableWrapper(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.35;
                  final summary = Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(design.radii.control),
                        child: ChewieItemBuilder.buildCachedImage(
                          context: context,
                          imageUrl: widget.postCollection.coverUrl,
                          width: 50,
                          height: 50,
                          showLoading: false,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: design.spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.postCollection.name}（${widget.postCollection.postCount}篇）",
                              style: design.typography.sectionTitle,
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.postCollection.description.isNotEmpty)
                              Text(
                                widget.postCollection.description,
                                style: design.typography.metadata.copyWith(
                                  color: design.colors.textSecondary,
                                ),
                                maxLines: compact ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (!compact) ...[
                        SizedBox(width: design.spacing.md),
                        followButton,
                      ],
                    ],
                  );
                  if (!compact) return summary;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      summary,
                      SizedBox(height: design.spacing.md),
                      Align(
                        alignment: Alignment.centerRight,
                        child: followButton,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ItemBuilder.buildIconTextButton(
                context,
                text: isOldest ? "正序" : "倒序",
                icon: AnimatedRotation(
                  turns: isOldest ? 0 : 0.5,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: ChewieIcon(
                    LoftifyIcons.sortDirection,
                    size: 16,
                    color: Theme.of(context).textTheme.labelMedium?.color,
                  ),
                ),
                fontSizeDelta: 1,
                color: Theme.of(context).textTheme.labelMedium?.color,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    isOldest = !isOldest;
                  });
                  _scrollController.animateTo(0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                  bottomNoMore = false;
                  isInited = false;
                  _refreshController.resetHeader();
                  _refreshController.resetFooter();
                  _onRefresh(showLoading: true);
                },
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleSubscribe() {
    HapticFeedback.mediumImpact();
    CollectionApi.subscribeOrUnSubscribe(
      collectionId: widget.collectionId,
      isSubscribe: !subscribed,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
      } else if (mounted) {
        setState(() => subscribed = !subscribed);
      }
    });
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
          appLocalizations.descriptionWithPostCount(e.desc, e.count.toString()),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ));
      widgets.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      children: widgets,
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return LoftifyPostArchiveGrid(
      itemCount: count,
      itemBuilder: (context, index, tileExtent) {
        final trueIndex = startIndex + index;
        return CommonInfoItemBuilder.buildNineGridPostItem(
          context,
          posts[trueIndex],
          wh: tileExtent,
          activePostId: widget.postId,
        );
      },
    );
  }
}

class LoftifyCollectionPanelFrame extends StatelessWidget {
  const LoftifyCollectionPanelFrame({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final visibleHeight = (media.size.height - media.viewInsets.bottom)
        .clamp(0.0, double.infinity);
    final compact = media.size.width < 380 ||
        media.textScaler.scale(1) > 1.35 ||
        visibleHeight * 0.8 < 420;
    final panelHeight =
        (visibleHeight * (compact ? 0.92 : 0.8)).clamp(0.0, 760.0);
    return SafeArea(
      top: false,
      child: SizedBox(
        key: const ValueKey('loftify-collection-panel'),
        height: panelHeight,
        child: LoftifyPanel(
          expandBody: true,
          body: body,
        ),
      ),
    );
  }
}
