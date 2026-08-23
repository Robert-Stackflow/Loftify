import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';
import 'package:loftify/Widgets/BottomSheet/shield_bottom_sheet.dart';
import 'package:loftify/Widgets/PostItem/general_post_item.dart';

import '../../Api/post_api.dart';
import '../../Api/user_api.dart';
import '../../Models/illust.dart';
import '../../Models/post_detail_response.dart';
import '../../Screens/Info/user_detail_screen.dart';
import '../../Screens/Post/post_detail_screen.dart';
import '../../Screens/Post/video_detail_screen.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';
import '../Item/item_builder.dart';
import '../Item/loftify_item_builder.dart';
import '../loftify_icons.dart';
import 'image_grid.dart';

export 'package:loftify/Widgets/PostItem/general_post_item.dart';

const double _postCardRadius = 12;

double _safePhotoAspectRatio(PhotoLink photo) {
  if (photo.ow <= 0 || photo.oh <= 0) return 1;
  final ratio = photo.ow / photo.oh;
  return ratio.isFinite && ratio > 0 ? ratio : 1;
}

Widget _buildInvalidPostCard(
  BuildContext context, {
  double? width,
  double? height,
  double minHeight = 96,
}) {
  return ContainerItem(
    backgroundColor: ChewieTheme.canvasColor,
    radius: _postCardRadius,
    roundTop: true,
    roundBottom: true,
    border: Border.all(color: Theme.of(context).dividerColor, width: 0.8),
    child: SizedBox(
      width: width,
      height: height,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChewieIcon(
                  LoftifyIcons.invalidContent,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(height: 5),
                Text(
                  appLocalizations.invalidContent,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.apply(fontWeightDelta: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class WaterfallFlowPostItemWidget extends StatefulWidget {
  final GeneralPostItem item;

  const WaterfallFlowPostItemWidget({
    super.key,
    required this.item,
  });

  @override
  WaterfallFlowPostItemWidgetState createState() =>
      WaterfallFlowPostItemWidgetState();
}

class WaterfallFlowPostItemWidgetState
    extends State<WaterfallFlowPostItemWidget> {
  late GeneralPostItem item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  @override
  void didUpdateWidget(covariant WaterfallFlowPostItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    return buildWaterfallFlowPostItem();
  }

  Widget buildWaterfallFlowPostItem() {
    double width = (MediaQuery.sizeOf(context).width - 24) / 2;
    PostType type = item.type;
    late Widget main;
    switch (type) {
      case PostType.image:
        main = item.photoLinks.isNotEmpty
            ? buildWaterfallFlowImageItem(width: width)
            : item.hasTitleOrContent
                ? buildWaterfallFlowArticleItem(width: width)
                : _buildInvalidPostCard(
                    context,
                    width: width,
                    minHeight: 120,
                  );
      case PostType.article:
        main = item.showArticle ?? true
            ? buildWaterfallFlowArticleItem(width: width)
            : emptyWidget;
      case PostType.video:
        main = item.showVideo ?? true
            ? item.photoLinks.isNotEmpty
                ? buildWaterfallFlowVideoItem(width: width)
                : item.hasTitleOrContent
                    ? buildWaterfallFlowArticleItem(width: width)
                    : _buildInvalidPostCard(
                        context,
                        width: width,
                        minHeight: 120,
                      )
            : emptyWidget;
      case PostType.grain:
        main = emptyWidget;
      case PostType.invalid:
        main = _buildInvalidPostCard(
          context,
          width: width,
          minHeight: 120,
        );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => GeneralPostItemBuilder.onTapItem(context, item),
      onLongPress: item.showMoreButton
          ? () {
              HapticFeedback.mediumImpact();
              GeneralPostItemBuilder.showMoreSheet(context, item);
            }
          : null,
      child: ClickableWrapper(child: main),
    );
  }

  Widget buildWaterfallFlowArticleItem({
    required double width,
  }) {
    return Column(
      children: [
        ContainerItem(
          backgroundColor: Theme.of(context).cardColor,
          radius: _postCardRadius,
          roundTop: true,
          roundBottom: true,
          child: Container(
            padding: const EdgeInsets.all(15),
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.apply(
                        fontWeightDelta: 2,
                        fontSizeDelta: -1,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  HtmlUtil.extractTextFromHtml(item.digest),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        buildWaterfallFlowPostItemMeta(
          showTitle: false,
        ),
      ],
    );
  }

  Widget buildWaterfallFlowImageItem({
    required double width,
    double maxHeight = 300,
    double minHeight = 120,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).dividerColor, width: 0.3),
                borderRadius: BorderRadius.circular(_postCardRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_postCardRadius),
                child: SizedBox(
                  height: (width / _safePhotoAspectRatio(item.photoLinks[0]))
                      .clamp(minHeight, maxHeight),
                  width: width,
                  child: ChewieItemBuilder.buildCachedImage(
                    context: context,
                    fit: BoxFit.cover,
                    showLoading: false,
                    imageUrl: Utils.getUrlByQuality(
                        item.photoLinks[0].middle,
                        HiveUtil.getImageQuality(
                            HiveUtil.waterfallFlowImageQualityKey)),
                  ),
                ),
              ),
            ),
            if (Utils.isGIF(item.firstImageUrl))
              Positioned(
                left: 4,
                top: 4,
                child: ItemBuilder.buildTranslucentTag(context,
                    text: appLocalizations.animatedGif),
              ),
            if ((item.photoCount ?? item.photoLinks.length) > 1)
              Positioned(
                bottom: 4,
                right: 4,
                child: ItemBuilder.buildTranslucentTag(
                  context,
                  text: '${(item.photoCount ?? item.photoLinks.length)}',
                  isCircle: true,
                  padding: EdgeInsets.all(
                      (item.photoCount ?? item.photoLinks.length) > 10 ? 3 : 5),
                ),
              ),
          ],
        ),
        buildWaterfallFlowPostItemMeta(),
      ],
    );
  }

  Widget buildWaterfallFlowVideoItem({
    required double width,
    double maxHeight = 300,
    double minHeight = 120,
  }) {
    final height = (width / _safePhotoAspectRatio(item.photoLinks[0]))
        .clamp(minHeight, maxHeight);
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).dividerColor, width: 0.3),
                borderRadius: BorderRadius.circular(_postCardRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_postCardRadius),
                child: SizedBox(
                  height: height,
                  width: width,
                  child: ChewieItemBuilder.buildCachedImage(
                    context: context,
                    fit: BoxFit.cover,
                    showLoading: false,
                    imageUrl: Utils.getUrlByQuality(
                        item.photoLinks[0].orign,
                        HiveUtil.getImageQuality(
                            HiveUtil.waterfallFlowImageQualityKey)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 4,
              child: ItemBuilder.buildTranslucentTag(context,
                  text: appLocalizations.video),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: ItemBuilder.buildTranslucentTag(
                context,
                text: Utils.formatDuration(item.duration),
              ),
            ),
          ],
        ),
        buildWaterfallFlowPostItemMeta(),
      ],
    );
  }

  Widget buildWaterfallFlowPostItemMeta({
    bool showTitle = true,
  }) {
    String tag = "";
    if (item.tags.isNotEmpty) {
      tag = item.tags[0];
    }
    if (StringUtil.isNotEmpty(item.excludeTag)) {
      while (tag.contains(item.excludeTag!) && tag != item.tags.last) {
        tag = item.tags[item.tags.indexOf(tag) + 1];
      }
    }
    String shownTitle = item.processedTitle;
    bool hasTitle = item.hasTitleOrContent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    showTitle && hasTitle
                        ? Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              shownTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.apply(
                                    fontSizeDelta: -2,
                                    fontWeightDelta: 2,
                                  ),
                            ),
                          )
                        : const SizedBox(height: 3),
                    if (tag.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        alignment: Alignment.centerLeft,
                        child: ItemBuilder.buildSmallTagItem(context, tag),
                      ),
                  ],
                ),
              ),
              if (item.showMoreButton)
                GestureDetector(
                  onTap: () {
                    GeneralPostItemBuilder.showMoreSheet(context, item);
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: showTitle && hasTitle ? 3 : 5),
                    child: const ChewieIcon(
                      LoftifyIcons.moreVertical,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    RouteUtil.pushPanelCupertinoRoute(
                      context,
                      UserDetailScreen(
                        blogId: item.blogId,
                        blogName: item.blogName,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: ItemBuilder.buildAvatar(
                      context: context,
                      imageUrl: item.bigAvaImg,
                      showLoading: false,
                      size: 15,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      RouteUtil.pushPanelCupertinoRoute(
                        context,
                        UserDetailScreen(
                          blogId: item.blogId,
                          blogName: item.blogName,
                        ),
                      );
                    },
                    child: Text(
                      item.blogNickName,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                if (item.showLikeButton == true)
                  LoftifyItemBuilder.buildLikedButton(
                    context,
                    isLiked: item.liked,
                    showCount: true,
                    likeCount: item.likeCount,
                    position: CountPostion.right,
                    size: 16,
                    iconSize: 16,
                    likeCountPadding: const EdgeInsets.only(left: 3),
                    defaultColor: Theme.of(context).textTheme.bodySmall?.color,
                    countStyle: Theme.of(context).textTheme.bodySmall,
                    onTap: (_) async {
                      HapticFeedback.mediumImpact();
                      int status = await PostApi.likeOrUnLike(
                        isLike: !item.liked,
                        postId: item.postId,
                        blogId: item.blogId,
                      ).then((value) {
                        if (!mounted) return value['meta']['status'];
                        setState(() {
                          if (value['meta']['status'] != 200) {
                            IToast.showTop(
                                value['meta']['desc'] ?? value['meta']['msg']);
                          } else {
                            item.liked = !item.liked;
                            item.likeCount += item.liked ? 1 : -1;
                            item.likeCount =
                                item.likeCount.clamp(0, 100000000000000000);
                            item.onLikeChanged?.call(item.liked);
                          }
                        });
                        return value['meta']['status'];
                      });
                      if (!mounted) return item.liked;
                      if (status == 4071) {
                        Utils.validSlideCaptcha(context);
                      }
                      return !item.liked;
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridPostItemWidget extends StatefulWidget {
  final GeneralPostItem item;

  final int? activePostId;
  final double wh;

  const GridPostItemWidget({
    super.key,
    required this.item,
    this.wh = 100,
    this.activePostId,
  });

  @override
  GridPostItemWidgetState createState() => GridPostItemWidgetState();
}

class GridPostItemWidgetState extends State<GridPostItemWidget> {
  late GeneralPostItem item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  @override
  void didUpdateWidget(covariant GridPostItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    return buildGridPostItem(
      context,
      widget.item,
      wh: widget.wh,
      activePostId: widget.activePostId,
    );
  }

  Widget buildGridPostItem(
    BuildContext context,
    GeneralPostItem item, {
    double wh = 100,
    int? activePostId,
  }) {
    late Widget main;
    switch (item.type) {
      case PostType.image:
        main = item.photoLinks.isNotEmpty
            ? buildNineGridImageItem(wh: wh, activePostId: activePostId)
            : item.hasTitleOrContent
                ? buildNineGridArticleItem(
                    wh: wh,
                    activePostId: activePostId,
                  )
                : buildInvalidItem(wh: wh);
      case PostType.article:
        main = buildNineGridArticleItem(wh: wh, activePostId: activePostId);
      case PostType.video:
        main = item.photoLinks.isNotEmpty
            ? buildNineGridVideoItem(wh: wh, activePostId: activePostId)
            : item.hasTitleOrContent
                ? buildNineGridArticleItem(
                    wh: wh,
                    activePostId: activePostId,
                  )
                : buildInvalidItem(wh: wh);
      case PostType.grain:
        main = emptyWidget;
      case PostType.invalid:
        main = buildInvalidItem(wh: wh);
    }
    return Material(
      color: item.type == PostType.article
          ? Theme.of(context).cardColor
          : item.type == PostType.invalid
              ? ChewieTheme.canvasColor
              : Colors.transparent,
      borderRadius: BorderRadius.circular(_postCardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_postCardRadius),
        onTap: () => GeneralPostItemBuilder.onTapItem(context, item),
        onLongPress: item.showMoreButton
            ? () {
                HapticFeedback.mediumImpact();
                GeneralPostItemBuilder.showMoreSheet(context, item);
              }
            : null,
        child: ClickableWrapper(child: main),
      ),
    );
  }

  Widget buildNineGridImageItem({
    int? activePostId = 0,
    required double wh,
  }) {
    return SizedBox(
      width: wh,
      height: wh,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: activePostId == item.postId
                  ? Border.all(
                      color: Theme.of(context).primaryColor, width: 1.6)
                  : Border.all(
                      color: Theme.of(context).dividerColor, width: 0.8),
              borderRadius: BorderRadius.circular(_postCardRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_postCardRadius),
              child: SizedBox(
                height: wh,
                width: wh,
                child: ChewieItemBuilder.buildCachedImage(
                  context: context,
                  fit: BoxFit.cover,
                  showLoading: false,
                  imageUrl: Utils.removeWatermark(item.photoLinks[0].middle),
                ),
              ),
            ),
          ),
          if ((item.photoCount ?? item.photoLinks.length) > 1)
            Positioned(
              bottom: 1,
              right: 5,
              child: ItemBuilder.buildTranslucentTag(
                context,
                text: '${(item.photoCount ?? item.photoLinks.length)}',
                isCircle: true,
                padding: const EdgeInsets.all(5),
                fontSizeDelta: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildNineGridArticleItem({
    int? activePostId = 0,
    required double wh,
  }) {
    return ContainerItem(
      backgroundColor: Colors.transparent,
      radius: _postCardRadius,
      roundTop: true,
      roundBottom: true,
      border: activePostId == item.postId
          ? Border.all(color: Theme.of(context).primaryColor, width: 1.6)
          : Border.all(color: Theme.of(context).dividerColor, width: 0.8),
      child: Container(
        padding: const EdgeInsets.all(5),
        width: wh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.title.isNotEmpty)
              Text(
                "${item.title}\n",
                style: Theme.of(context).textTheme.titleSmall?.apply(
                      fontWeightDelta: 2,
                      fontSizeDelta: -1,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: item.title.isNotEmpty ? 5 : 5),
            Expanded(
              child: Text(
                StringUtil.clearBlank(
                    HtmlUtil.extractTextFromHtml(item.digest)),
                maxLines: item.title.isNotEmpty ? 6 : 8,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.apply(
                      fontSizeDelta: -1,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNineGridVideoItem({
    required double wh,
    int? activePostId = 0,
  }) {
    return SizedBox(
      width: wh,
      height: wh,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: activePostId == item.postId
                  ? Border.all(
                      color: Theme.of(context).primaryColor, width: 1.6)
                  : Border.all(
                      color: Theme.of(context).dividerColor, width: 0.8),
              borderRadius: BorderRadius.circular(_postCardRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_postCardRadius),
              child: SizedBox(
                height: wh,
                width: wh,
                child: ChewieItemBuilder.buildCachedImage(
                  context: context,
                  fit: BoxFit.cover,
                  imageUrl: item.photoLinks[0].orign,
                  showLoading: false,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: 5,
            child: ItemBuilder.buildTranslucentTag(
              context,
              text: appLocalizations.video,
            ),
          ),
          Positioned(
            bottom: 6,
            right: 5,
            child: ItemBuilder.buildTranslucentTag(
              context,
              text: Utils.formatDuration(item.duration),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInvalidItem({required double wh}) {
    return _buildInvalidPostCard(
      context,
      width: wh,
      height: wh,
      minHeight: wh,
    );
  }
}

class TilePostItemWidget extends StatefulWidget {
  final GeneralPostItem item;

  final bool isFirst;

  const TilePostItemWidget(
      {super.key, required this.item, this.isFirst = false});

  @override
  TilePostItemWidgetState createState() => TilePostItemWidgetState();
}

class TilePostItemWidgetState extends State<TilePostItemWidget>
    with TickerProviderStateMixin {
  late GeneralPostItem item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  @override
  void didUpdateWidget(covariant TilePostItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    return buildTilePostItem();
  }

  Widget buildTilePostItem() {
    PostType type = item.type;
    late Widget main;
    switch (type) {
      case PostType.image:
        main = item.photoLinks.isNotEmpty
            ? buildTileImageItem()
            : item.hasTitleOrContent
                ? buildTileArticleItem()
                : _buildInvalidPostCard(
                    context,
                    width: double.infinity,
                  );
      case PostType.article:
        main = item.showArticle ?? true ? buildTileArticleItem() : emptyWidget;
      case PostType.video:
        main = item.showVideo ?? true
            ? item.photoLinks.isNotEmpty
                ? buildTileVideoItem()
                : item.hasTitleOrContent
                    ? buildTileArticleItem()
                    : _buildInvalidPostCard(
                        context,
                        width: double.infinity,
                      )
            : emptyWidget;
      case PostType.grain:
        main = emptyWidget;
      case PostType.invalid:
        main = _buildInvalidPostCard(
          context,
          width: double.infinity,
        );
    }
    final isLandscape = ResponsiveUtil.isLandscapeLayout();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_postCardRadius),
        onTap: () => GeneralPostItemBuilder.onTapItem(context, item),
        onLongPress: item.showMoreButton
            ? () {
                HapticFeedback.mediumImpact();
                GeneralPostItemBuilder.showMoreSheet(context, item);
              }
            : null,
        child: Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: !isLandscape && widget.isFirst ? 0 : 12,
            bottom: isLandscape ? 12 : 0,
          ),
          decoration: isLandscape
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.3,
                    ),
                  ),
                )
              : null,
          child: main,
        ),
      ),
    );
  }

  Widget buildTileShareRow() {
    if (item.shareInfo != null) {
      return FutureBuilder(
        future: HiveUtil.getUserId(),
        builder: (context, data) {
          int id = data.data ?? 0;
          return GestureDetector(
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                UserDetailScreen(
                  blogId: item.shareInfo!.blogInfo.blogId,
                  blogName: item.shareInfo!.blogInfo.blogName,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.only(bottom: 8, left: 8),
              child: Row(
                children: [
                  ChewieIcon(
                    LoftifyIcons.recommend,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      id == item.shareInfo!.blogInfo.blogId
                          ? appLocalizations.fromMyRecommend
                          : appLocalizations.fromOtherRecommend(
                              item.shareInfo!.blogInfo.blogNickName),
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return emptyWidget;
    }
  }

  Widget buildTileUserRow() {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          UserDetailScreen(
            blogId: item.blogId,
            blogName: item.blogName,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            ItemBuilder.buildAvatar(
              context: context,
              imageUrl: item.bigAvaImg,
              showLoading: false,
              size: 36,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.blogNickName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.apply(fontSizeDelta: -2, fontWeightDelta: 2),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    TimeUtil.formatTimestamp(item.opTime),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (item.followed != true)
              LoftifyItemBuilder.buildFramedDoubleButton(
                context: context,
                isFollowed: item.followed == true,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  UserApi.followOrUnfollow(
                          isFollow: !(item.followed == true),
                          blogId: item.blogId,
                          blogName: item.blogName)
                      .then((value) {
                    if (value['meta']['status'] != 200) {
                      IToast.showTop(
                          value['meta']['desc'] ?? value['meta']['msg']);
                    } else {
                      item.followed = !(item.followed == true);
                    }
                    setState(() {});
                  });
                },
              ),
            if (item.followed != true) const SizedBox(width: 8),
            CircleIconButton(
              icon: const ChewieIcon(
                LoftifyIcons.moreVertical,
                size: 20,
              ),
              onTap: () {
                BottomSheetBuilder.showContextMenu(
                    context, _buildMoreButtons());
              },
            ),
          ],
        ),
      ),
    );
  }

  FlutterContextMenu _buildMoreButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.copyLink,
          iconData: LoftifyIcons.copy,
          onPressed: () {
            Utils.copy(
              context,
              LoftifyUriUtil.getPostUrlById(
                item.blogName,
                item.postId,
                item.blogId,
              ),
            );
          },
        ),
        FlutterContextMenuItem(appLocalizations.visitOriginalPost,
            iconData: LoftifyIcons.originalPost, onPressed: () {
          UriUtil.openInternal(
            context,
            LoftifyUriUtil.getPostUrlById(
              item.blogName,
              item.postId,
              item.blogId,
            ),
            processUri: false,
          );
        }),
        FlutterContextMenuItem(appLocalizations.openWithBrowser,
            iconData: LoftifyIcons.openExternal, onPressed: () {
          UriUtil.openExternal(
            LoftifyUriUtil.getPostUrlById(
              item.blogName,
              item.postId,
              item.blogId,
            ),
          );
        }),
        FlutterContextMenuItem(appLocalizations.shareToOtherApps,
            iconData: LoftifyIcons.share, onPressed: () {
          UriUtil.share(
            LoftifyUriUtil.getPostUrlById(
              item.blogName,
              item.postId,
              item.blogId,
            ),
          );
        }),
      ],
    );
  }

  Widget buildTileContentRow() {
    String title = StringUtil.clearBlank(item.title);
    String content = item.digest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        if (title.isNotEmpty && content.isNotEmpty) const SizedBox(height: 5),
        if (content.isNotEmpty)
          CustomHtmlWidget(
            content: content,
            selectable: false,
            style: Theme.of(context).textTheme.bodyMedium,
            // linkBold: false,
            // selectable: false,
          ),
        if (title.isNotEmpty || content.isNotEmpty) const SizedBox(height: 10),
      ],
    );
  }

  List<Illust> _getImageIllusts() {
    List<Illust> illusts = [];
    List<PhotoLink> photoLinks = item.photoLinks;
    for (int i = 0; i < photoLinks.length; i++) {
      PhotoLink e = photoLinks[i];
      String rawUrl = Utils.getUrlByQuality(e.middle, ImageQuality.raw);
      illusts.add(
        Illust(
          extension: FileUtil.extractFileExtensionFromUrl(rawUrl),
          originalName: FileUtil.extractFileNameFromUrl(rawUrl),
          blogId: item.blogId,
          blogLofterId: item.blogName,
          blogNickName: item.blogNickName,
          postId: item.postId,
          part: i,
          url: rawUrl,
          postTitle: item.title,
          postDigest: item.digest,
          tags: item.tags,
          publishTime: item.publishTime,
        ),
      );
    }
    return illusts;
  }

  Widget buildTileImageItem() {
    var grid = ImageGrid(
      ratios: item.photoLinks.map(_safePhotoAspectRatio).toList(),
      itemCount: item.photoLinks.length,
      itemBuilder: (BuildContext context, int index, BorderRadius radius) {
        radius =
            radius.copyWith(topLeft: radius.topLeft, topRight: radius.topRight);
        bool isGif = Utils.isGIF(item.photoLinks[index].middle);
        String tagPrefix = "TilePost";
        String imageUrl = Utils.getUrlByQuality(item.photoLinks[index].middle,
            HiveUtil.getImageQuality(HiveUtil.postDetailImageQualityKey));
        var image = SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  RouteUtil.pushDialogRoute(
                    context,
                    showClose: false,
                    fullScreen: true,
                    useFade: true,
                    opaque: false,
                    HeroPhotoViewScreen(
                      imageUrls: _getImageIllusts()
                          .map((illust) => illust.url)
                          .toList(),
                      initIndex: index,
                      tagPrefix: "TilePost",
                      useMainColor: true,
                    ),
                  );
                },
                child: Hero(
                  tag: Utils.getHeroTag(
                    tagPrefix: tagPrefix,
                    url: imageUrl,
                  ),
                  child: ChewieItemBuilder.buildCachedImage(
                    context: context,
                    fit: BoxFit.cover,
                    showLoading: false,
                    width: MediaQuery.sizeOf(context).width,
                    height: MediaQuery.sizeOf(context).height,
                    imageUrl: Utils.getUrlByQuality(
                        item.photoLinks[index].middle, ImageQuality.origin),
                  ),
                ),
              ),
              if (isGif)
                Positioned(
                  left: 4,
                  top: 4,
                  child: ItemBuilder.buildTranslucentTag(context,
                      text: appLocalizations.animatedGif),
                ),
            ],
          ),
        );
        double ratio = _safePhotoAspectRatio(item.photoLinks[index]);
        ratio = ratio.clamp(0.8, 1.6);
        bool isSingle = item.photoLinks.length == 1;
        return Container(
          decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).dividerColor, width: 0.5),
            borderRadius: radius,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: isSingle
                ? Container(
                    constraints:
                        const BoxConstraints(maxWidth: maxMediaOrQuoteWidth),
                    child: AspectRatio(aspectRatio: ratio, child: image),
                  )
                : image,
          ),
        );
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildTileShareRow(),
        buildTileUserRow(),
        buildTileContentRow(),
        grid,
        buildTilePostItemMeta(),
      ],
    );
  }

  Widget buildTileArticleItem() {
    return Column(
      children: [
        buildTileShareRow(),
        buildTileUserRow(),
        buildTileContentRow(),
        buildTilePostItemMeta(showTitle: false),
      ],
    );
  }

  Widget buildTileVideoItem({
    double maxHeight = 300,
    double minHeight = 120,
  }) {
    double ratio = _safePhotoAspectRatio(item.photoLinks[0]);
    ratio = ratio.clamp(0.8, 1.6);
    return Column(
      children: [
        buildTileShareRow(),
        buildTileUserRow(),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).dividerColor, width: 0.3),
                borderRadius: BorderRadius.circular(_postCardRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_postCardRadius),
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: ChewieItemBuilder.buildCachedImage(
                    context: context,
                    fit: BoxFit.cover,
                    showLoading: false,
                    imageUrl: Utils.getUrlByQuality(
                        item.photoLinks[0].orign,
                        HiveUtil.getImageQuality(
                            HiveUtil.waterfallFlowImageQualityKey)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 4,
              child: ItemBuilder.buildTranslucentTag(context,
                  text: appLocalizations.video),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: ItemBuilder.buildTranslucentTag(
                context,
                text: Utils.formatDuration(item.duration),
              ),
            ),
          ],
        ),
        buildTilePostItemMeta(),
      ],
    );
  }

  Widget buildTilePostItemMeta({
    bool showTitle = true,
  }) {
    List<String> tagList = item.tags;
    Map<String, TagType> tags = {};
    for (var e in tagList) {
      tags[e] = TagType.normal;
    }
    List<MapEntry<String, TagType>> sortedTags = tags.entries.toList();
    sortedTags.sort((a, b) => b.value.index.compareTo(a.value.index));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.start,
          children: List.generate(sortedTags.length, (index) {
            return MouseRegion(
              cursor: sortedTags[index].value != TagType.egg
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: ItemBuilder.buildTagItem(
                context,
                sortedTags[index].key,
                sortedTags[index].value,
                fontWeightDelta: 2,
                fontSizeDelta: -1,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            ItemBuilder.buildIconTextButton(
              context,
              text: StringUtil.formatCount(item.likeCount),
              spacing: 4,
              icon: !item.liked
                  ? const ChewieIcon(
                      LoftifyIcons.favorite,
                      size: 20,
                    )
                  : const ChewieIcon(
                      LoftifyIcons.favorite,
                      color: ChewieColors.likeButtonColor,
                      size: 20,
                    ),
              onTap: () {
                _handleLike();
              },
            ),
            const SizedBox(width: 12),
            ItemBuilder.buildIconTextButton(
              context,
              text: StringUtil.formatCount(item.shareCount),
              spacing: 4,
              icon: !item.shared
                  ? const ChewieIcon(
                      LoftifyIcons.recommend,
                      size: 18,
                    )
                  : const ChewieIcon(
                      LoftifyIcons.recommend,
                      color: ChewieColors.shareButtonColor,
                      size: 18,
                    ),
              onTap: () {
                _handleRecommend();
              },
            ),
            const SizedBox(width: 12),
            ItemBuilder.buildIconTextButton(
              context,
              text: appLocalizations.comment,
              icon: const ChewieIcon(LoftifyIcons.comment, size: 18),
              spacing: 4,
              onTap: () {
                RouteUtil.pushPanelCupertinoRoute(
                  context,
                  PostDetailScreen(
                    generalPostItem: item,
                    isArticle: item.type == PostType.article,
                    sequenceSource: item.sequenceSource,
                  ),
                );
              },
            ),
          ],
        ),
        if (!ResponsiveUtil.isLandscapeLayout()) const SizedBox(height: 10),
        if (!ResponsiveUtil.isLandscapeLayout())
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleLike() async {
    HapticFeedback.mediumImpact();
    final value = await PostApi.likeOrUnLike(
      isLike: !item.liked,
      postId: item.postId,
      blogId: item.blogId,
    );
    if (!mounted) return;
    if (value['meta']['status'] != 200) {
      if (StringUtil.isNotEmpty(value['meta']['desc']) &&
          StringUtil.isNotEmpty(value['meta']['msg'])) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
      }
      if (value['meta']['status'] == 4071) {
        Utils.validSlideCaptcha(context);
      }
    } else {
      item.liked = !item.liked;
      if (item.liked != true) {
        IToast.showTop(appLocalizations.unlike);
      }
      item.likeCount += item.liked ? 1 : -1;
      item.likeCount = item.likeCount.clamp(0, 100000000000000000);
      item.onLikeChanged?.call(item.liked);
    }
    setState(() {});
  }

  Future<void> _handleRecommend() async {
    HapticFeedback.mediumImpact();
    final value = await PostApi.shareOrUnShare(
      isShare: !item.shared,
      postId: item.postId,
      blogId: item.blogId,
    );
    if (!mounted) return;
    if (value['meta']['status'] != 200) {
      if (StringUtil.isNotEmpty(value['meta']['desc']) &&
          StringUtil.isNotEmpty(value['meta']['msg'])) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
      }
      if (value['meta']['status'] == 4071) {
        Utils.validSlideCaptcha(context);
      }
    } else {
      item.shared = !item.shared;
      if (item.shared) {
        IToast.showTop(appLocalizations.unrecommend);
      }
      item.shareCount += item.shared ? 1 : -1;
      item.shareCount = item.shareCount.clamp(0, 100000000000000000);
    }
    setState(() {});
  }
}

class GeneralPostItemBuilder {
  static void onTapItem(BuildContext context, GeneralPostItem item) {
    if (item.type == PostType.invalid) {
      IToast.showTop(appLocalizations.invalidContent);
    } else if (item.type == PostType.video) {
      if (ResponsiveUtil.isDesktop()) {
        IToast.showTop(appLocalizations.unSupportVideoInDesktop);
      } else {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          VideoDetailScreen(generalPostItem: item),
        );
      }
    } else {
      RouteUtil.pushPanelCupertinoRoute(
        context,
        PostDetailScreen(
          generalPostItem: item,
          isArticle: item.type == PostType.article,
          sequenceSource: item.sequenceSource,
        ),
      );
    }
  }

  static void showMoreSheet(BuildContext context, GeneralPostItem item) {
    BottomSheetBuilder.showBottomSheet(
      context,
      (sheetContext) => ShieldBottomSheet(
        tags: item.tags,
        onShieldContent: () {
          item.onShieldContent?.call();
          Navigator.pop(sheetContext);
        },
        onShieldUser: () {
          item.onShieldUser?.call();
          Navigator.pop(sheetContext);
        },
        onShieldTag: (tag) {
          item.onShieldTag?.call(tag);
          Navigator.pop(sheetContext);
        },
      ),
      responsive: true,
      preferMinWidth: 400,
    );
  }
}
