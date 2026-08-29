import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart' hide AnimatedSlide;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/grain_api.dart';
import 'package:loftify/Models/grain_response.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:loftify/Widgets/PostItem/general_post_item_builder.dart';
import 'package:loftify/Widgets/PostItem/grain_post_item_builder.dart';

import '../../Models/history_response.dart';
import '../../Models/download_task.dart';
import '../../Screens/Download/batch_download_screen.dart';
import '../../Utils/post_sequence_source.dart';
import '../../Widgets/PostDetail/detail_bottom_bar.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

class GrainDetailScreen extends StatefulWidget {
  const GrainDetailScreen({
    super.key,
    required this.grainId,
    required this.blogId,
  });

  final int grainId;
  final int blogId;

  static const String routeName = "/grain/detail";

  @override
  GrainDetailScreenState createState() => GrainDetailScreenState();
}

class GrainDetailScreenState extends BaseDynamicState<GrainDetailScreen>
    with TickerProviderStateMixin {
  final EasyRefreshController _refreshController = EasyRefreshController();
  String grainUrl = "";

  bool subscribed = false;
  GrainDetailData? grainDetailData;
  bool loading = false;
  List<GrainPostItem> posts = [];
  final List<ArchiveData> _archiveDataList = [];
  late final PostSequenceSource _postSequenceSource;
  bool isOldest = false;
  bool noMore = false;

  _fetchIncantation() {
    GrainApi.getIncantation(
      grainId: widget.grainId,
      blogId: widget.blogId,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          if (value['data']['grainLink'] != null) {
            grainUrl = value['data']['grainLink'];
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load grain detail", e, t);
        if (mounted) IToast.showTop(appLocalizations.getLinkFailed);
        return IndicatorResult.fail;
      }
    });
  }

  _fetchData({bool refresh = false, bool showLoading = false}) async {
    if (loading || (!refresh && noMore)) return IndicatorResult.none;
    if (refresh) noMore = false;
    if (showLoading)
      CustomLoadingDialog.showLoading(title: appLocalizations.loading);
    loading = true;
    int offset = refresh ? 0 : grainDetailData?.offset ?? 0;
    return await GrainApi.getGrainDetail(
      grainId: widget.grainId,
      blogId: widget.blogId,
      offset: offset,
      sortType: isOldest ? 0 : 1,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          GrainDetailData t = GrainDetailData.fromJson(value['data']);
          if (grainDetailData == null || refresh) {
            grainDetailData = t;
            subscribed = grainDetailData!.followStatus;
          } else if (grainDetailData != null) {
            grainDetailData!.offset = t.offset;
          }
          List<GrainPostItem> newPosts = [];
          if (refresh) posts.clear();
          for (var e in t.posts) {
            if (posts.indexWhere((element) =>
                    element.postData.postView.id == e.postData.postView.id) ==
                -1) {
              newPosts.add(e);
            }
          }
          posts.addAll(newPosts);
          Map<String, int> monthCount = {};
          for (var e in posts) {
            String yearMonth = formatLocalizedYearMonth(e.opTime);
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
          noMore = posts.length >= grainDetailData!.grainInfo.postCount ||
              newPosts.isEmpty;
          _synchronizePostSequence();
          if (noMore && !refresh) {
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load graind detail", e, t);
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
    _postSequenceSource = PostSequenceSource(
      loadMore: () async {
        await _fetchData();
      },
    );
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
              showBack: true, title: appLocalizations.grainDetail)
          : null,
      bottomNavigationBar: grainDetailData != null ? _buildFooter() : null,
      body: grainDetailData != null
          ? _buildScrollableBody()
          : LoadingWidget(
              background: Colors.transparent,
            ),
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
          title: Text(
            appLocalizations.grain,
            style: Theme.of(context).textTheme.titleMedium?.apply(
                  color: Colors.white,
                  fontWeightDelta: 2,
                ),
          ),
          centerTitle: !ResponsiveUtil.isLandscapeLayout(),
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
                    _buildStatisticRow(),
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
                  _buildStatisticRow(),
                ],
              ),
            ],
          ),
        ),
        SliverPersistentHeader(
          key: const ValueKey('grain-detail-fixed-header'),
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
            ChewieUtils.copy(context, grainUrl);
          },
        ),
        FlutterContextMenuItem(appLocalizations.openWithBrowser,
            iconData: LoftifyIcons.openExternal, onPressed: () {
          UriUtil.openExternal(grainUrl);
        }),
        FlutterContextMenuItem(appLocalizations.shareToOtherApps,
            iconData: LoftifyIcons.share, onPressed: () {
          UriUtil.share(grainUrl);
        }),
      ],
    );
  }

  void _openBatchDownload() {
    RouteUtil.pushPanelCupertinoRoute(
      context,
      BatchDownloadScreen(
        sourceTitle: grainDetailData?.grainInfo.name ?? appLocalizations.grain,
        source: DownloadSourceDescriptor(
          type: DownloadSourceType.grain,
          sourceId: widget.grainId.toString(),
          title: grainDetailData?.grainInfo.name ?? appLocalizations.grain,
          thumbnailUrl: grainDetailData?.grainInfo.coverUrl,
          metadata: <String, String>{
            'grainId': widget.grainId.toString(),
            'blogId': widget.blogId.toString(),
          },
        ),
        initialItems: posts
            .map(GrainPostItemBuilder.getGeneralPostItem)
            .toList(growable: false),
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
        .map(GrainPostItemBuilder.getGeneralPostItem)
        .toList(growable: false);
  }

  PreferredSize _buildFixedBar([double height = 56]) {
    bool hasDesc =
        StringUtil.isNotEmpty(grainDetailData!.grainInfo.description);
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
                        ? grainDetailData!.grainInfo.description
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
              : appLocalizations.subscribeGrain,
          background: Theme.of(context).primaryColor.withAlpha(40),
          padding: const EdgeInsets.symmetric(vertical: 15),
          color: Theme.of(context).primaryColor,
          onPressed: () {
            HapticFeedback.mediumImpact();
            GrainApi.subscribeOrUnSubscribe(
              grainId: widget.grainId,
              blogId: widget.blogId,
              isSubscribe: !subscribed,
            ).then((value) {
              if (value['code'] != 0) {
                IToast.showTop(value['msg']);
              } else {
                subscribed = !subscribed;
                setState(() {});
              }
            });
          },
          fontSizeDelta: 2,
        ),
        RoundIconTextButton(
          text: appLocalizations.startRead,
          background: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          onPressed: () {
            if (posts.isNotEmpty) {
              GeneralPostItemBuilder.onTapItem(
                context,
                GrainPostItemBuilder.getGeneralPostItem(
                  posts.first,
                  sequenceSource: _postSequenceSource,
                ),
              );
            } else {
              IToast.showTop(appLocalizations.noPostInGrain);
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
              imageUrl: grainDetailData!.grainInfo.coverUrl,
              context: context,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              tagPrefix: StringUtil.getRandomString(),
              title: appLocalizations.grainCover,
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
                  grainDetailData!.grainInfo.name,
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
                          blogName: grainDetailData!.blogInfo.blogName,
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 5),
                          child: ItemBuilder.buildAvatar(
                            context: context,
                            imageUrl: grainDetailData!.blogInfo.bigAvaImg,
                            size: 20,
                            showBorder: false,
                            showLoading: false,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "${grainDetailData!.blogInfo.blogNickName} · ${appLocalizations.updateAt}${TimeUtil.formatTimestamp(grainDetailData!.grainInfo.updateTime)}",
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
          ],
        ],
      ),
    );
  }

  _buildStatisticRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ItemBuilder.buildStatisticItem(
          context,
          title: appLocalizations.postCount,
          count: grainDetailData!.grainInfo.postCount,
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: appLocalizations.subscribeCount,
          count: grainDetailData!.grainInfo.subscribedCount,
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: appLocalizations.coCreatorCount,
          count: grainDetailData!.grainInfo.joinCount,
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: appLocalizations.viewCountLong,
          count: grainDetailData!.grainInfo.viewCount,
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
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
    return GridView.extent(
      padding: const EdgeInsets.only(top: 12),
      shrinkWrap: true,
      maxCrossAxisExtent: 160,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(count, (index) {
        int trueIndex = startIndex + index;
        return GrainPostItemBuilder.buildNineGridPostItem(
          context,
          posts[trueIndex],
          wh: 160,
          sequenceSource: _postSequenceSource,
        );
      }),
    );
  }

  void _synchronizePostSequence() {
    _postSequenceSource.synchronize(
      posts.map(
        (item) => PostSequenceEntry(
          postId: item.postData.postView.id,
          blogId: item.postData.postView.blogId,
          blogName: item.postData.blogInfo.blogName,
          type: GrainPostItemBuilder.getPostType(item),
        ),
      ),
      hasMore: !noMore,
    );
  }

  Widget _buildBackground({double? height}) {
    String backgroudUrl = grainDetailData!.grainInfo.coverUrl;
    return Blur(
      blur: 20,
      blurColor: Colors.black12,
      child: ChewieItemBuilder.buildCachedImage(
        context: context,
        imageUrl: backgroudUrl,
        fit: BoxFit.cover,
        showLoading: false,
        width: MediaQuery.sizeOf(context).width * 2,
        height: height ?? MediaQuery.sizeOf(context).height * 0.7,
        placeholderBackground: Theme.of(context).textTheme.labelSmall?.color,
        bottomPadding: 50,
      ),
    );
  }
}
