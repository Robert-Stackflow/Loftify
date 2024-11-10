import 'package:blur/blur.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart' hide AnimatedSlide;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Widgets/Dialog/custom_dialog.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

import '../../Api/collection_api.dart';
import '../../Models/history_response.dart';
import '../../Models/post_detail_response.dart';
import '../../Models/recommend_response.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/enums.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/Custom/sliver_appbar_delegate.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../generated/l10n.dart';

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

class CollectionDetailScreenState extends State<CollectionDetailScreen>
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
        if (mounted) IToast.showTop(S.current.getLinkFailed);
        return IndicatorResult.fail;
      }
    });
  }

  _fetchData({bool refresh = false, bool showLoading = false}) async {
    if (loading) return;
    if (refresh) noMore = false;
    if (showLoading) CustomLoadingDialog.showLoading(title: S.current.loading);
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
          if (posts.length >= postCollection!.postCount || newPosts.isEmpty) {
            noMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load collection detail", e, t);
        if (mounted) IToast.showTop(S.current.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (showLoading) CustomLoadingDialog.dismissLoading();
        if (mounted) setState(() {});
        loading = false;
      }
    });
  }

  _onRefresh() async {
    await _fetchData(refresh: true);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.getBackground(context),
      appBar: ResponsiveUtil.isLandscape()
          ? ItemBuilder.buildResponsiveAppBar(
              context: context,
              showBack: true,
              title: S.current.collectionDetail)
          : null,
      bottomNavigationBar:
          blogInfo != null && postCollection != null ? _buildFooter() : null,
      body: blogInfo != null && postCollection != null
          ? NestedScrollView(
              headerSliverBuilder: (_, __) => _buildHeaderSlivers(),
              body: _buildNineGridGroup())
          : ItemBuilder.buildLoadingWidget(
              context,
              background: Colors.transparent,
            ),
    );
  }

  _buildHeaderSlivers() {
    if (!ResponsiveUtil.isLandscape()) {
      return <Widget>[
        ItemBuilder.buildSliverAppBar(
          context: context,
          expandedHeight: 265,
          backgroundWidget: _buildBackground(),
          actions: [
            ItemBuilder.buildIconButton(
              context: context,
              onTap: () {
                BottomSheetBuilder.showContextMenu(
                    context, _buildMoreButtons());
              },
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
              ),
            ),
          ],
          centerTitle: !ResponsiveUtil.isLandscape(),
          title: Text(
            S.current.collection,
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
          key: ValueKey(Utils.getRandomString()),
          pinned: true,
          delegate: SliverAppBarDelegate(
            radius: 0,
            background: MyTheme.getBackground(context),
            tabBar: _buildFixedBar(),
          ),
        ),
      ];
    }
  }

  PreferredSize _buildFixedBar([double height = 56]) {
    bool hasDesc = Utils.isNotEmpty(postCollection!.description);
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: MyTheme.getBackground(context),
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
                        : S.current.noDescription,
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
                  text: isOldest ? S.current.order : S.current.reverseOrder,
                  icon: AssetUtil.load(
                    isOldest
                        ? AssetUtil.orderDownDarkIcon
                        : AssetUtil.orderUpDarkIcon,
                    size: 15,
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
            // if (Utils.isNotEmpty(postCollection!.tags)) _buildTagList(),
            const SizedBox(height: 8),
            ItemBuilder.buildDivider(
              context,
              horizontal: 0,
              vertical: 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 65,
      width: MediaQuery.sizeOf(context).width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: ItemBuilder.buildRoundButton(
              context,
              text: subscribed
                  ? S.current.unsubscribe
                  : S.current.subscribeCollection,
              background: Theme.of(context).primaryColor.withAlpha(40),
              padding: const EdgeInsets.symmetric(vertical: 15),
              color: Theme.of(context).primaryColor,
              onTap: () {
                HapticFeedback.mediumImpact();
                CollectionApi.subscribeOrUnSubscribe(
                  collectionId: widget.collectionId,
                  isSubscribe: !subscribed,
                ).then((value) {
                  if (value['meta']['status'] != 200) {
                    IToast.showTop(
                        value['meta']['desc'] ?? value['meta']['msg']);
                  } else {
                    subscribed = !subscribed;
                    setState(() {});
                  }
                });
              },
              fontSizeDelta: 2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ItemBuilder.buildRoundButton(
              context,
              text: S.current.continueRead,
              background: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              onTap: () {
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
                  IToast.showTop(S.current.noPostInCollection);
                }
              },
              fontSizeDelta: 2,
            ),
          ),
        ],
      ),
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
            child: ItemBuilder.buildHeroCachedImage(
              imageUrl: postCollection!.coverUrl,
              context: context,
              height: 80,
              width: 80,
              tagPrefix: Utils.getRandomString(),
              title: S.current.collectionCover,
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
                ItemBuilder.buildClickable(
                  GestureDetector(
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
                            "${blogInfo!.blogNickName} · ${S.current.updateAt}${Utils.formatTimestamp(postCollection!.lastPublishTime)}",
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
          if (ResponsiveUtil.isLandscape()) ...[
            ItemBuilder.buildIconButton(
              context: context,
              onTap: () {
                BottomSheetBuilder.showContextMenu(
                    context, _buildMoreButtons());
              },
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
              ),
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
          title: S.current.postCount,
          count: postCollection!.postCount,
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: S.current.subscribeCount,
          count: postCollection!.subscribedCount,
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: S.current.totalHotCount,
          count: postCollection!.postCollectionHot,
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: S.current.viewCountLong,
          count: postCollection!.viewCount,
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
      ],
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
      widgets.add(ItemBuilder.buildTitle(
        context,
        title: S.current.descriptionWithPostCount(e.desc, e.count.toString()),
        topMargin: 16,
        bottomMargin: 0,
      ));
      widgets.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    return EasyRefresh.builder(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoad: _onLoad,
      childBuilder: (context, physics) {
        return Container(
          height: MediaQuery.sizeOf(context).height,
          color: MyTheme.getBackground(context),
          child: ItemBuilder.buildLoadMoreNotification(
            child: ListView(
              physics: physics,
              shrinkWrap: true,
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
              children: widgets,
            ),
            noMore: noMore,
            onLoad: _onLoad,
          ),
        );
      },
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
          wh: 160,
          activePostId: widget.postId,
        );
      }),
    );
  }

  _buildMoreButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          S.current.copyLink,
          icon: const Icon(Icons.copy_rounded),
          onPressed: () {
            Utils.copy(context, collectionUrl);
          },
        ),
        ContextMenuButtonConfig(S.current.openWithBrowser,
            icon: const Icon(Icons.open_in_browser_rounded), onPressed: () {
          UriUtil.openExternal(collectionUrl);
        }),
        ContextMenuButtonConfig(S.current.shareToOtherApps,
            icon: const Icon(Icons.share_rounded), onPressed: () {
          UriUtil.share(context, collectionUrl);
        }),
      ],
    );
  }

  Widget _buildBackground({double? height}) {
    String backgroudUrl = postCollection!.coverUrl;
    return Blur(
      blur: 20,
      blurColor: Colors.black12,
      child: ItemBuilder.buildCachedImage(
        context: context,
        imageUrl: backgroudUrl,
        showLoading: false,
        fit: BoxFit.cover,
        width: MediaQuery.sizeOf(context).width * 2,
        height: height ?? MediaQuery.sizeOf(context).height * 0.7,
        placeholderBackground: Theme.of(context).textTheme.labelSmall?.color,
        bottomPadding: 50,
      ),
    );
  }
}
