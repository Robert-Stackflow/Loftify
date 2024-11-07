import 'dart:math';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';
import 'package:loftify/Resources/colors.dart';
import 'package:loftify/Screens/Post/video_detail_screen.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Widgets/BottomSheet/shield_bottom_sheet.dart';

import '../../Api/post_api.dart';
import '../../Api/user_api.dart';
import '../../Models/grain_response.dart';
import '../../Models/illust.dart';
import '../../Models/post_detail_response.dart';
import '../../Resources/theme.dart';
import '../../Screens/Info/user_detail_screen.dart';
import '../../Screens/Post/post_detail_screen.dart';
import '../../Utils/constant.dart';
import '../../Utils/enums.dart';
import '../../Utils/file_util.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';
import '../BottomSheet/bottom_sheet_builder.dart';
import '../Custom/floating_modal.dart';
import '../Custom/hero_photo_view_screen.dart';
import '../Item/item_builder.dart';
import 'image_grid.dart';

class GeneralPostItem {
  PostType type;
  List<PhotoLink> photoLinks;
  int blogId;
  int publishTime;
  int opTime;
  int postId;
  String permalink;
  int collectionId;
  bool liked;
  bool shared;
  bool? followed;
  String blogName;
  String blogNickName;
  String title;
  String digest;
  String content;
  String firstImageUrl;
  int duration;
  int likeCount;
  int shareCount;
  int commentCount;
  List<String> tags;
  String bigAvaImg;
  int? photoCount;
  String? tagPrefix;
  bool? showVideo;
  bool? showArticle;
  bool? showLikeButton;
  String? excludeTag;
  bool showMoreButton;
  ShareInfo? shareInfo;
  final Function(String tag)? onShieldTag;
  final Function()? onShieldContent;
  final Function()? onShieldUser;

  GeneralPostItem({
    this.showLikeButton = true,
    this.showArticle = true,
    this.showVideo = true,
    this.tagPrefix,
    this.photoCount,
    this.shareInfo,
    this.followed,
    this.shared = false,
    this.shareCount = 0,
    this.commentCount = 0,
    required this.type,
    required this.photoLinks,
    required this.blogId,
    required this.postId,
    required this.permalink,
    required this.collectionId,
    required this.liked,
    required this.blogName,
    required this.blogNickName,
    required this.title,
    required this.digest,
    required this.content,
    required this.firstImageUrl,
    required this.duration,
    required this.likeCount,
    required this.tags,
    required this.bigAvaImg,
    this.excludeTag,
    this.publishTime = 0,
    this.opTime = 0,
    this.showMoreButton = false,
    this.onShieldTag,
    this.onShieldContent,
    this.onShieldUser,
  });

  bool get hasTitleOrContent {
    var item = this;
    String title = Utils.clearBlank(item.title);
    String content = Utils.clearBlank(Utils.extractTextFromHtml(item.content));
    String digest = Utils.clearBlank(Utils.extractTextFromHtml(item.digest));
    return (Utils.isNotEmpty(title) ||
        Utils.isNotEmpty(content) ||
        Utils.isNotEmpty(digest));
  }

  String get processedTitle {
    var item = this;
    String title = Utils.clearBlank(item.title);
    String digest = Utils.clearBlank(Utils.extractTextFromHtml(item.digest));
    String content = Utils.clearBlank(Utils.extractTextFromHtml(item.content));
    String shownTitle = Utils.isNotEmpty(title)
        ? title
        : Utils.isNotEmpty(digest)
            ? digest
            : content;
    return shownTitle;
  }
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
  Widget build(BuildContext context) {
    return buildWaterfallFlowPostItem();
  }

  Widget buildWaterfallFlowPostItem() {
    double width = (MediaQuery.sizeOf(context).width - 24) / 2;
    PostType type = item.type;
    late Widget main;
    switch (type) {
      case PostType.image:
        main = buildWaterfallFlowImageItem(width: width);
      case PostType.article:
        main = item.showArticle ?? true
            ? buildWaterfallFlowArticleItem(width: width)
            : emptyWidget;
      case PostType.video:
        main = item.showVideo ?? true
            ? buildWaterfallFlowVideoItem(width: width)
            : emptyWidget;
      case PostType.grain:
        main = emptyWidget;
      case PostType.invalid:
        main = emptyWidget;
    }
    return GestureDetector(
      onTap: () {
        GeneralPostItemBuilder.onTapItem(context, item);
      },
      onLongPress: item.showMoreButton
          ? () {
              HapticFeedback.mediumImpact();
              GeneralPostItemBuilder.showMoreSheet(context, item);
            }
          : null,
      child: ItemBuilder.buildClickItem(main),
    );
  }

  Widget buildWaterfallFlowArticleItem({
    required double width,
  }) {
    return Column(
      children: [
        ItemBuilder.buildContainerItem(
          backgroundColor: Theme.of(context).cardColor,
          topRadius: true,
          bottomRadius: true,
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
                  Utils.extractTextFromHtml(item.digest),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          context: context,
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: max(
                    min(item.photoLinks[0].oh * (width / item.photoLinks[0].ow),
                        maxHeight),
                    minHeight,
                  ),
                  width: width,
                  child: ItemBuilder.buildCachedImage(
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
                child: ItemBuilder.buildTransparentTag(context, text: "动图"),
              ),
            if ((item.photoCount ?? item.photoLinks.length) > 1)
              Positioned(
                bottom: 4,
                right: 4,
                child: ItemBuilder.buildTransparentTag(
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
    var height = max(
      min(item.photoLinks[0].oh * (width / item.photoLinks[0].ow), maxHeight),
      minHeight,
    );
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).dividerColor, width: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: height.isNaN ? maxHeight : height,
                  width: width,
                  child: ItemBuilder.buildCachedImage(
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
              child: ItemBuilder.buildTransparentTag(context, text: "视频"),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: ItemBuilder.buildTransparentTag(
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
    if (Utils.isNotEmpty(item.excludeTag)) {
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
                    child: const Icon(
                      Icons.more_vert_rounded,
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
                  ItemBuilder.buildLikedButton(
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
                        setState(() {
                          if (value['meta']['status'] != 200) {
                            IToast.showTop(
                                value['meta']['desc'] ?? value['meta']['msg']);
                          } else {
                            item.liked = !item.liked;
                            item.likeCount += item.liked ? 1 : -1;
                            item.likeCount =
                                item.likeCount.clamp(0, 100000000000000000);
                          }
                        });
                        return value['meta']['status'];
                      });
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
        main = buildNineGridImageItem(wh: wh, activePostId: activePostId);
      case PostType.article:
        main = buildNineGridArticleItem(wh: wh, activePostId: activePostId);
      case PostType.video:
        main = buildNineGridVideoItem(wh: wh, activePostId: activePostId);
      case PostType.grain:
        main = emptyWidget;
      case PostType.invalid:
        main = buildInvalidItem(wh: wh);
    }
    return GestureDetector(
      onTap: () {
        GeneralPostItemBuilder.onTapItem(context, item);
      },
      child: ItemBuilder.buildClickItem(main),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: wh,
                width: wh,
                child: ItemBuilder.buildCachedImage(
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
              child: ItemBuilder.buildTransparentTag(
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
    return ItemBuilder.buildContainerItem(
      backgroundColor: Theme.of(context).cardColor,
      topRadius: true,
      bottomRadius: true,
      radius: 12,
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
                Utils.clearBlank(Utils.extractTextFromHtml(item.digest)),
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
      context: context,
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: wh,
                width: wh,
                child: ItemBuilder.buildCachedImage(
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
            child: ItemBuilder.buildTransparentTag(
              context,
              text: '视频',
            ),
          ),
          Positioned(
            bottom: 6,
            right: 5,
            child: ItemBuilder.buildTransparentTag(
              context,
              text: Utils.formatDuration(item.duration),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInvalidItem({required double wh}) {
    return ItemBuilder.buildContainerItem(
      backgroundColor: MyTheme.getCardBackground(context),
      topRadius: true,
      bottomRadius: true,
      border: Border.all(color: Theme.of(context).dividerColor, width: 0.8),
      child: Container(
        padding: const EdgeInsets.all(5),
        width: wh,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).textTheme.labelSmall?.color,
              size: 24,
            ),
            const SizedBox(height: 5),
            Text(
              "无效内容",
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.apply(fontWeightDelta: 1),
            ),
          ],
        ),
      ),
      context: context,
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
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late GeneralPostItem item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildTilePostItem();
  }

  Widget buildTilePostItem() {
    double width = (MediaQuery.sizeOf(context).width - 24) / 2;
    PostType type = item.type;
    late Widget main;
    switch (type) {
      case PostType.image:
        main = buildTileImageItem();
      case PostType.article:
        main = item.showArticle ?? true ? buildTileArticleItem() : emptyWidget;
      case PostType.video:
        main = item.showVideo ?? true ? buildTileVideoItem() : emptyWidget;
      case PostType.grain:
      case PostType.invalid:
        main = emptyWidget;
    }
    var res = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          GeneralPostItemBuilder.onTapItem(context, item);
        },
        onLongPress: item.showMoreButton
            ? () {
                HapticFeedback.mediumImpact();
                GeneralPostItemBuilder.showMoreSheet(context, item);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.3,
              ),
            ),
          ),
          child: main,
        ),
      ),
    );
    return ResponsiveUtil.isLandscape()
        ? res
        : GestureDetector(
            onTap: () {
              GeneralPostItemBuilder.onTapItem(context, item);
            },
            onLongPress: item.showMoreButton
                ? () {
                    HapticFeedback.mediumImpact();
                    GeneralPostItemBuilder.showMoreSheet(context, item);
                  }
                : null,
            child: Container(
              color: Colors.transparent,
              padding: EdgeInsets.only(
                  left: 12, right: 12, top: widget.isFirst ? 0 : 12),
              child: main,
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
                  Icon(
                    Icons.thumb_up_alt,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      id == item.shareInfo!.blogInfo.blogId
                          ? "来自我的推荐"
                          : "来自好友 ${item.shareInfo!.blogInfo.blogNickName} 推荐",
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
                    Utils.formatTimestamp(item.opTime),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (item.followed != true)
              ItemBuilder.buildFramedDoubleButton(
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
            ItemBuilder.buildIconButton(
              context: context,
              icon: const Icon(Icons.more_vert_rounded, size: 20),
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

  _buildMoreButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          S.current.copyLink,
          icon: const Icon(Icons.copy_rounded),
          onPressed: () {
            Utils.copy(
              context,
              UriUtil.getPostUrlById(
                item.blogName,
                item.postId,
                item.blogId,
              ),
            );
          },
        ),
        ContextMenuButtonConfig("访问原文",
            icon: const Icon(Icons.view_carousel_outlined), onPressed: () {
          UriUtil.openInternal(
            context,
            UriUtil.getPostUrlById(
              item.blogName,
              item.postId,
              item.blogId,
            ),
            processUri: false,
          );
        }),
        ContextMenuButtonConfig(S.current.openWithBrowser,
            icon: const Icon(Icons.open_in_browser_rounded), onPressed: () {
          UriUtil.openExternal(
            UriUtil.getPostUrlById(
              item.blogName,
              item.postId,
              item.blogId,
            ),
          );
        }),
        ContextMenuButtonConfig(S.current.shareToOtherApps,
            icon: const Icon(Icons.share_rounded), onPressed: () {
          UriUtil.share(
            context,
            UriUtil.getPostUrlById(
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
    String title = Utils.clearBlank(item.title);
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
          ItemBuilder.buildHtmlWidget(
            context,
            content,
            textStyle: Theme.of(context).textTheme.bodyMedium,
            linkBold: false,
            selectable: false,
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
      ratios: item.photoLinks.map((e) => e.ow / e.oh).toList(),
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
                    HeroPhotoViewScreen(
                      imageUrls: _getImageIllusts(),
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
                  child: ItemBuilder.buildCachedImage(
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
                  child: ItemBuilder.buildTransparentTag(context, text: "动图"),
                ),
            ],
          ),
        );
        double ratio = item.photoLinks[index].ow / item.photoLinks[index].oh;
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
    double ratio = item.photoLinks[0].ow / item.photoLinks[0].oh;
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: ItemBuilder.buildCachedImage(
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
              child: ItemBuilder.buildTransparentTag(context, text: "视频"),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: ItemBuilder.buildTransparentTag(
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
              text: Utils.formatCount(item.likeCount),
              spacing: 4,
              icon: !item.liked
                  ? const Icon(
                      Icons.favorite_border_rounded,
                      size: 20,
                    )
                  : const Icon(
                      Icons.favorite_rounded,
                      color: MyColors.likeButtonColor,
                      size: 20,
                    ),
              onTap: () {
                _handleLike();
              },
            ),
            const SizedBox(width: 12),
            ItemBuilder.buildIconTextButton(
              context,
              text: Utils.formatCount(item.shareCount),
              spacing: 4,
              icon: !item.shared
                  ? const Icon(
                      Icons.thumb_up_outlined,
                      size: 18,
                    )
                  : const Icon(
                      Icons.thumb_up,
                      color: MyColors.shareButtonColor,
                      size: 18,
                    ),
              onTap: () {
                _handleRecommend();
              },
            ),
            const SizedBox(width: 12),
            ItemBuilder.buildIconTextButton(
              context,
              text: "评论",
              icon: const Icon(Icons.mode_comment_outlined, size: 18),
              spacing: 4,
              onTap: () {
                RouteUtil.pushPanelCupertinoRoute(
                  context,
                  PostDetailScreen(
                    generalPostItem: item,
                    isArticle: item.type == PostType.article,
                  ),
                );
              },
            ),
          ],
        ),
        if (!ResponsiveUtil.isLandscape()) const SizedBox(height: 10),
        if (!ResponsiveUtil.isLandscape())
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

  _handleLike() async {
    HapticFeedback.mediumImpact();
    await PostApi.likeOrUnLike(
      isLike: !item.liked,
      postId: item.postId,
      blogId: item.blogId,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        if (Utils.isNotEmpty(value['meta']['desc']) &&
            Utils.isNotEmpty(value['meta']['msg'])) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        }
        if (value['meta']['status'] == 4071) {
          Utils.validSlideCaptcha(context);
        }
      } else {
        item.liked = !item.liked;
        if (item.liked == true) {
          IToast.showTop("点赞成功");
        } else {
          IToast.showTop("取消点赞");
        }
        item.likeCount += item.liked ? 1 : -1;
        item.likeCount = item.likeCount.clamp(0, 100000000000000000);
      }
      setState(() {});
    });
  }

  _handleRecommend() async {
    HapticFeedback.mediumImpact();
    await PostApi.shareOrUnShare(
      isShare: !item.shared,
      postId: item.postId,
      blogId: item.blogId,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        if (Utils.isNotEmpty(value['meta']['desc']) &&
            Utils.isNotEmpty(value['meta']['msg'])) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        }
        if (value['meta']['status'] == 4071) {
          Utils.validSlideCaptcha(context);
        }
      } else {
        item.shared = !item.shared;
        if (item.shared) {
          IToast.showTop("推荐成功");
        } else {
          IToast.showTop("取消推荐");
        }
        item.shareCount += item.shared ? 1 : -1;
        item.shareCount = item.shareCount.clamp(0, 100000000000000000);
      }
      setState(() {});
    });
  }

  @override
  bool get wantKeepAlive => true;
}

class GeneralPostItemBuilder {
  static onTapItem(BuildContext context, GeneralPostItem item) {
    if (item.type == PostType.invalid) {
      IToast.showTop("无效内容");
    } else if (item.type == PostType.video) {
      if (ResponsiveUtil.isDesktop()) {
        IToast.showTop("桌面端不支持播放视频");
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
        ),
      );
    }
  }

  static showMoreSheet(BuildContext context, GeneralPostItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return FloatingModal(
          preferMinWidth: 400,
          child: ShieldBottomSheet(
            tags: item.tags,
            onShieldContent: () {
              item.onShieldContent?.call();
              Navigator.pop(context);
            },
            onShieldUser: () {
              item.onShieldUser?.call();
              Navigator.pop(context);
            },
            onShieldTag: (tag) {
              item.onShieldTag?.call(tag);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}
