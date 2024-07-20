import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';
import 'package:loftify/Screens/Post/video_detail_screen.dart';
import 'package:loftify/Widgets/BottomSheet/shield_bottom_sheet.dart';

import '../../Models/post_detail_response.dart';
import '../../Resources/theme.dart';
import '../../Screens/Info/user_detail_screen.dart';
import '../../Screens/Post/post_detail_screen.dart';
import '../../Utils/constant.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../Custom/floating_modal.dart';
import '../Item/item_builder.dart';

class GeneralPostItem {
  PostType type;
  List<PhotoLink> photoLinks;
  int blogId;
  int postId;
  String permalink;
  int collectionId;
  bool liked;
  String blogName;
  String blogNickName;
  String title;
  String digest;
  String content;
  String firstImageUrl;
  int duration;
  int likeCount;
  List<String> tags;
  String bigAvaImg;
  int? photoCount;
  String? tagPrefix;
  bool? showVideo;
  bool? showArticle;
  bool? showLikeButton;
  String? excludeTag;
  bool showMoreButton;
  final Function(String tag)? onShieldTag;
  final Function()? onShieldContent;
  final Function()? onShieldUser;

  GeneralPostItem({
    this.showLikeButton = true,
    this.showArticle = true,
    this.showVideo = true,
    this.tagPrefix,
    this.photoCount,
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
    this.showMoreButton = false,
    this.onShieldTag,
    this.onShieldContent,
    this.onShieldUser,
  });
}

class GeneralPostItemBuilder {
  static Widget buildWaterfallFlowPostItem(
    BuildContext context,
    GeneralPostItem item, {
    Future<int> Function()? onLikeTap,
    Function()? onTap,
  }) {
    double width = (MediaQuery.sizeOf(context).width - 24) / 2;
    PostType type = item.type;
    late Widget main;
    switch (type) {
      case PostType.image:
        main = buildWaterfallFlowImageItem(context, item,
            width: width, onLikeTap: onLikeTap);
      case PostType.article:
        main = item.showArticle ?? true
            ? buildWaterfallFlowArticleItem(context, item,
                width: width, onLikeTap: onLikeTap)
            : emptyWidget;
      case PostType.video:
        main = item.showVideo ?? true
            ? buildWaterfallFlowVideoItem(context, item,
                width: width, onLikeTap: onLikeTap)
            : emptyWidget;
      case PostType.grain:
        main = buildWaterfallFlowGrainItem(context, item,
            width: width, onLikeTap: onLikeTap);
      case PostType.invalid:
        main = emptyWidget;
    }
    return GestureDetector(
      onTap: () {
        onTap?.call();
        onTapItem(context, item);
      },
      onLongPress: item.showMoreButton
          ? () {
              HapticFeedback.mediumImpact();
              showMoreSheet(context, item);
            }
          : null,
      child: ItemBuilder.buildClickItem(main),
    );
  }

  static onTapItem(BuildContext context, GeneralPostItem item) {
    if (item.type == PostType.invalid) {
      IToast.showTop("无效内容");
    } else if (item.type == PostType.video) {
      RouteUtil.pushCupertinoRoute(
        context,
        VideoDetailScreen(
          generalPostItem: item,
        ),
      );
    } else {
      RouteUtil.pushCupertinoRoute(
        context,
        PostDetailScreen(
          generalPostItem: item,
          isArticle: item.type == PostType.article,
        ),
      );
    }
  }

  static bool hasTitleOrContent(GeneralPostItem item) {
    String title = Utils.clearBlank(item.title);
    String content = Utils.clearBlank(Utils.extractTextFromHtml(item.content));
    String digest = Utils.clearBlank(Utils.extractTextFromHtml(item.digest));
    return (Utils.isNotEmpty(title) ||
        Utils.isNotEmpty(content) ||
        Utils.isNotEmpty(digest));
  }

  static String getTitle(GeneralPostItem item) {
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

  static Widget buildWaterfallFlowArticleItem(
    BuildContext context,
    GeneralPostItem item, {
    required double width,
    Function()? onLikeTap,
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
        buildWaterfallFlowPostItemMeta(context, item,
            showTitle: false, onLikeTap: onLikeTap),
      ],
    );
  }

  static Widget buildWaterfallFlowImageItem(
    BuildContext context,
    GeneralPostItem item, {
    required double width,
    double maxHeight = 300,
    double minHeight = 120,
    Function()? onLikeTap,
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
        buildWaterfallFlowPostItemMeta(context, item, onLikeTap: onLikeTap),
      ],
    );
  }

  static Widget buildWaterfallFlowVideoItem(
    BuildContext context,
    GeneralPostItem item, {
    required double width,
    Function()? onLikeTap,
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
        buildWaterfallFlowPostItemMeta(context, item, onLikeTap: onLikeTap),
      ],
    );
  }

  static Widget buildWaterfallFlowGrainItem(
    BuildContext context,
    GeneralPostItem item, {
    required double width,
    Function()? onLikeTap,
  }) {
    return emptyWidget;
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

  static Widget buildWaterfallFlowPostItemMeta(
    BuildContext context,
    GeneralPostItem item, {
    bool showTitle = true,
    Function()? onLikeTap,
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
    String shownTitle = getTitle(item);
    bool hasTitle = hasTitleOrContent(item);
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
                    showMoreSheet(context, item);
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
                    RouteUtil.pushCupertinoRoute(
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
                      RouteUtil.pushCupertinoRoute(
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
                      int status = await onLikeTap?.call();
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

  static Widget buildNineGridPostItem(
    BuildContext context,
    GeneralPostItem item, {
    double wh = 100,
    int? activePostId,
    Function()? onTap,
  }) {
    late Widget main;
    switch (item.type) {
      case PostType.image:
        main = buildNineGridImageItem(context, item,
            wh: wh, activePostId: activePostId);
      case PostType.article:
        main = buildNineGridArticleItem(context, item,
            wh: wh, activePostId: activePostId);
      case PostType.video:
        main = buildNineGridVideoItem(context, item,
            wh: wh, activePostId: activePostId);
      case PostType.grain:
        main = emptyWidget;
      case PostType.invalid:
        main = buildInvalidItem(context, wh: wh);
    }
    return GestureDetector(
      onTap: () {
        onTap?.call();
        onTapItem(context, item);
      },
      child: ItemBuilder.buildClickItem(main),
    );
  }

  static Widget buildNineGridImageItem(
    BuildContext context,
    GeneralPostItem item, {
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

  static Widget buildNineGridArticleItem(
    BuildContext context,
    GeneralPostItem item, {
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

  static Widget buildNineGridVideoItem(
    BuildContext context,
    GeneralPostItem item, {
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

  static Widget buildInvalidItem(BuildContext context, {required double wh}) {
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
