import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart' hide AnimatedSlide;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

import '../../Api/collection_api.dart';
import '../../Models/download_task.dart';
import '../../Models/history_response.dart';
import '../../Models/post_detail_response.dart';
import '../../Models/recommend_response.dart';
import '../../Screens/Download/batch_download_screen.dart';
import '../../Utils/enums.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../Widgets/PostItem/general_post_item.dart';
import '../../Widgets/PostItem/loftify_post_archive_grid.dart';
import '../../Widgets/PostDetail/detail_bottom_bar.dart';
import '../../Widgets/Design/loftify_media_overlays.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    required this.postId,
    required this.blogId,
    required this.blogName,
  });

  final int collectionId;
  final int postId;
  final int blogId;
  final String blogName;

  static const String routeName = "/collection/detail";

  @override
  CollectionDetailScreenState createState() => CollectionDetailScreenState();
}

class CollectionDetailScreenState
    extends BaseDynamicState<CollectionDetailScreen>
    with TickerProviderStateMixin {
  final EasyRefreshController _refreshController = EasyRefreshController();

  bool subscribed = false;
  SimpleBlogInfo? blogInfo;
  FullPostCollection? postCollection;
  String collectionUrl = "";
  bool loading = false;
  List<PostDetailData> posts = [];
  bool isOldest = false;
  final List<ArchiveData> _archiveDataList = [];
  bool noMore = false;

  _fetchIncantation() {
    CollectionApi.getIncantation(
      collectionId: widget.collectionId,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          if (value['data']['collectionLink'] != null) {
            collectionUrl = value['data']['collectionLink'];
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load collection url", e, t);
        if (mounted) IToast.showTop(appLocalizations.getLinkFailed);
        return IndicatorResult.fail;
      }
    });
  }

  _fetchData({bool refresh = false, bool showLoading = false}) async {
    if (loading || (!refresh && noMore)) return IndicatorResult.none;
    if (refresh) noMore = false;
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: appLocalizations.loading);
    }
    loading = true;
    int offset = refresh ? 0 : posts.length;
    return await CollectionApi.getCollectionDetail(
      collectionId: widget.collectionId,
      blogId: widget.blogId,
      offset: offset,
      order: isOldest ? 1 : 0,
    ).then((value) {
      try {
        if (value['meta']['status'] != 200) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
          return IndicatorResult.fail;
        } else {
          subscribed = value['response']['subscribed'];
          postCollection =
              FullPostCollection.fromJson(value['response']['collection']);
          blogInfo = SimpleBlogInfo.fromJson(value['response']['blogInfo']);
          List<dynamic> t = value['response']['items'];
          List<PostDetailData> newPosts = [];
          for (var e in t) {
            if (e != null) {
              newPosts.add(PostDetailData.fromJson(e));
            }
          }
          if (refresh) posts.clear();
          List<PostDetailData> notExistPostList = [];
          for (var e in newPosts) {
            if (posts.indexWhere((element) => element.post!.id == e.post!.id) ==
                -1) {
              notExistPostList.add(e);
            }
          }
          newPosts = notExistPostList;
          posts.addAll(newPosts);
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
          noMore =
              posts.length >= postCollection!.postCount || newPosts.isEmpty;
          if (noMore && !refresh) {
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load collection detail", e, t);
        if (mounted) IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (showLoading) CustomLoadingDialog.dismissLoading();
        if (mounted) setState(() {});
        loading = false;
      }
    });
  }

  _onRefresh() async {
    return await _fetchData(refresh: true);
  }

  _onLoad() async {
    return await _fetchData();
  }

  @override
  void initState() {
    super.initState();
    _fetchData(refresh: true);
    _fetchIncantation();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: ResponsiveUtil.isLandscapeLayout()
          ? ResponsiveAppBar(
              showBack: true, title: appLocalizations.collectionDetail)
          : null,
      bottomNavigationBar:
          blogInfo != null && postCollection != null ? _buildFooter() : null,
      body: blogInfo != null && postCollection != null
          ? _buildScrollableBody()
          : const LoadingWidget(background: Colors.transparent),
    );
  }

  Widget _buildScrollableBody() {
    return EasyRefresh.builder(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoad: noMore ? null : _onLoad,
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        physics: physics,
        slivers: [
          ..._buildHeaderSlivers(),
          ..._buildPostSlivers(),
        ],
      ),
    );
  }

  List<Widget> _buildHeaderSlivers() {
    if (!ResponsiveUtil.isLandscapeLayout()) {
      return <Widget>[
        SliverAppBarWrapper(
          context: context,
          expandedHeight: 265,
          backgroundWidget: _buildBackground(),
          actions: [
            ChewieIconButton(
              icon: LoftifyIcons.moreVertical,
              tooltip: appLocalizations.moreInfo,
              foregroundColor: Colors.white,
              onPressed: () {
                BottomSheetBuilder.showContextMenu(
                    context, _buildMoreButtons());
              },
            ),
          ],
          centerTitle: !ResponsiveUtil.isLandscapeLayout(),
          title: Text(
            appLocalizations.collection,
            style: Theme.of(context).textTheme.titleMedium?.apply(
                  color: Colors.white,
                  fontWeightDelta: 2,
                ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              children: [
                _buildBackground(),
                Column(
                  children: [
                    SizedBox(
                        height: kToolbarHeight +
                            MediaQuery.of(context).padding.top),
                    _buildInfoRow(),
                    _buildStatsticRow(),
                  ],
                ),
              ],
            ),
          ),
          bottom: _buildFixedBar(0),
        ),
      ];
    } else {
      return [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              _buildBackground(height: 180),
              Column(
                children: [
                  const SizedBox(height: 10),
                  _buildInfoRow(),
                  _buildStatsticRow(),
                ],
              ),
            ],
          ),
        ),
        SliverPersistentHeader(
          key: const ValueKey('collection-detail-fixed-header'),
          pinned: true,
          delegate: SliverAppBarDelegate(
            radius: 0,
            background: ChewieTheme.getBackground(context),
            tabBar: _buildFixedBar(),
          ),
        ),
      ];
    }
  }

  PreferredSize _buildFixedBar([double height = 56]) {
    bool hasDesc = StringUtil.isNotEmpty(postCollection!.description);
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ChewieTheme.getBackground(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        width: MediaQuery.sizeOf(context).width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    hasDesc
                        ? postCollection!.description
                        : appLocalizations.noDescription,
                    style: Theme.of(context).textTheme.labelLarge?.apply(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 5),
                ItemBuilder.buildIconTextButton(
                  context,
                  text: isOldest
                      ? appLocalizations.order
                      : appLocalizations.reverseOrder,
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
                    _fetchData(refresh: true, showLoading: true);
                  },
                ),
              ],
            ),
            // if (StringUtil.isNotEmpty(postCollection!.tags)) _buildTagList(),
            const SizedBox(height: 8),
            MyDivider(
              horizontal: 0,
              vertical: 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return DetailBottomBar(
      horizontalPadding: 12,
      spacing: 10,
      children: [
        RoundIconTextButton(
          text: subscribed
              ? appLocalizations.unsubscribe
              : appLocalizations.subscribeCollection,
          background: Theme.of(context).primaryColor.withAlpha(40),
          padding: const EdgeInsets.symmetric(vertical: 15),
          color: Theme.of(context).primaryColor,
          onPressed: () {
            HapticFeedback.mediumImpact();
            CollectionApi.subscribeOrUnSubscribe(
              collectionId: widget.collectionId,
              isSubscribe: !subscribed,
            ).then((value) {
              if (value['meta']['status'] != 200) {
                IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
              } else {
                subscribed = !subscribed;
                setState(() {});
              }
            });
          },
          fontSizeDelta: 2,
        ),
        RoundIconTextButton(
          text: appLocalizations.continueRead,
          background: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          onPressed: () {
            if (posts.isNotEmpty) {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                PostDetailScreen(
                  postDetailData: posts[0],
                  isArticle: CommonInfoItemBuilder.getPostType(posts[0]) ==
                      PostType.article,
                ),
              );
            } else {
              IToast.showTop(appLocalizations.noPostInCollection);
            }
          },
          fontSizeDelta: 2,
        ),
      ],
    );
  }

  _buildInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ChewieItemBuilder.buildHeroCachedImage(
              imageUrl: postCollection!.coverUrl,
              context: context,
              height: 80,
              width: 80,
              tagPrefix: StringUtil.getRandomString(),
              title: appLocalizations.collectionCover,
              showLoading: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  postCollection!.name,
                  style: Theme.of(context).textTheme.titleMedium?.apply(
                        fontSizeDelta: 2,
                        color: Colors.white,
                        fontWeightDelta: 2,
                      ),
                ),
                const SizedBox(height: 6),
                ClickableWrapper(
                  child: GestureDetector(
                    onTap: () {
                      RouteUtil.pushPanelCupertinoRoute(
                        context,
                        UserDetailScreen(
                          blogId: widget.blogId,
                          blogName: widget.blogName,
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 5),
                          child: ItemBuilder.buildAvatar(
                            context: context,
                            imageUrl: blogInfo!.bigAvaImg,
                            size: 20,
                            showBorder: false,
                            showLoading: false,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "${blogInfo!.blogNickName} · ${appLocalizations.updateAt}${TimeUtil.formatTimestamp(postCollection!.lastPublishTime)}",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.apply(color: Colors.white, fontSizeDelta: -1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          if (ResponsiveUtil.isLandscapeLayout()) ...[
            ChewieIconButton(
              icon: LoftifyIcons.moreVertical,
              tooltip: appLocalizations.moreInfo,
              foregroundColor: Colors.white,
              onPressed: () {
                BottomSheetBuilder.showContextMenu(
                    context, _buildMoreButtons());
              },
            ),
            const SizedBox(width: 5),
          ]
        ],
      ),
    );
  }

  _buildStatsticRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ItemBuilder.buildStatisticItem(
          context,
          title: appLocalizations.postCount,
          count: postCollection!.postCount,
          countColor: Colors.white,
          labelColor: LoftifyCoverScrim.secondaryForeground,
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: appLocalizations.subscribeCount,
          count: postCollection!.subscribedCount,
          countColor: Colors.white,
          labelColor: LoftifyCoverScrim.secondaryForeground,
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: appLocalizations.totalHotCount,
          count: postCollection!.postCollectionHot,
          countColor: Colors.white,
          labelColor: LoftifyCoverScrim.secondaryForeground,
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: appLocalizations.viewCountLong,
          count: postCollection!.viewCount,
          countColor: Colors.white,
          labelColor: LoftifyCoverScrim.secondaryForeground,
        ),
      ],
    );
  }

  List<Widget> _buildPostSlivers() {
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
      widgets.add(ItemBuilder.buildTitle(
        context,
        title: appLocalizations.descriptionWithPostCount(
            e.desc, e.count.toString()),
        topMargin: 16,
        bottomMargin: 0,
      ));
      widgets.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    if (widgets.isEmpty) {
      return [
        SliverEmptyPlaceholder(text: appLocalizations.noArticle),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
        sliver: SliverList.list(children: widgets),
      ),
    ];
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

  _buildMoreButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.batchDownload,
          iconData: LoftifyIcons.download,
          onPressed: _openBatchDownload,
        ),
        FlutterContextMenuItem(
          appLocalizations.copyLink,
          iconData: LoftifyIcons.copy,
          onPressed: () {
            ChewieUtils.copy(context, collectionUrl);
          },
        ),
        FlutterContextMenuItem(appLocalizations.openWithBrowser,
            iconData: LoftifyIcons.openExternal, onPressed: () {
          UriUtil.openExternal(collectionUrl);
        }),
        FlutterContextMenuItem(appLocalizations.shareToOtherApps,
            iconData: LoftifyIcons.share, onPressed: () {
          UriUtil.share(collectionUrl);
        }),
      ],
    );
  }

  void _openBatchDownload() {
    RouteUtil.pushPanelCupertinoRoute(
      context,
      BatchDownloadScreen(
        sourceTitle: postCollection?.name ?? appLocalizations.collection,
        source: DownloadSourceDescriptor(
          type: DownloadSourceType.collection,
          sourceId: widget.collectionId.toString(),
          title: postCollection?.name ?? appLocalizations.collection,
          thumbnailUrl: postCollection?.coverUrl,
          metadata: <String, String>{
            'collectionId': widget.collectionId.toString(),
            'postId': widget.postId.toString(),
            'blogId': widget.blogId.toString(),
            'blogName': widget.blogName,
          },
        ),
        initialItems:
            posts.map(CommonInfoItemBuilder.getGeneralPostItem).toList(),
        loadAllItems: _loadAllBatchItems,
      ),
    );
  }

  Future<List<GeneralPostItem>> _loadAllBatchItems() async {
    if (posts.isEmpty) await _onRefresh();
    while (!noMore) {
      final previousLength = posts.length;
      final result = await _onLoad();
      if (result == IndicatorResult.fail ||
          result == IndicatorResult.none ||
          posts.length == previousLength) {
        break;
      }
    }
    return posts
        .map(CommonInfoItemBuilder.getGeneralPostItem)
        .toList(growable: false);
  }

  Widget _buildBackground({double? height}) {
    String backgroudUrl = postCollection!.coverUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        Blur(
          blur: 20,
          blurColor: Colors.black12,
          child: ChewieItemBuilder.buildCachedImage(
            context: context,
            imageUrl: backgroudUrl,
            showLoading: false,
            fit: BoxFit.cover,
            width: MediaQuery.sizeOf(context).width * 2,
            height: height ?? MediaQuery.sizeOf(context).height * 0.7,
            placeholderBackground:
                Theme.of(context).textTheme.labelSmall?.color,
            bottomPadding: 50,
          ),
        ),
        const LoftifyCoverScrim(),
      ],
    );
  }
}
