import 'package:flutter/material.dart';
import 'package:loftify/Models/grain_response.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/utils.dart';
import 'general_post_item_builder.dart';

class GrainPostItemBuilder {
  static GeneralPostItem getGeneralPostItem(GrainPostItem item) {
    List<PhotoLink> photoLinks = [];
    switch (getPostType(item)) {
      case PostType.video:
        if (Utils.isNotEmpty(item.postData.postView.firstImageUrl)) {
          photoLinks = Utils.parseJsonList(item.postData.postView.firstImageUrl)
              .map((e) => PhotoLink(
                    orign: e.toString(),
                    raw: e.toString(),
                    small: e.toString(),
                    middle: e.toString(),
                    rw: 0,
                    rh: 0,
                    ow: 0,
                    oh: 0,
                  ))
              .toList();
        } else if (item.postData.postView.firstImage != null) {
          photoLinks = [
            PhotoLink(
              orign: item.postData.postView.firstImage!.orign,
              raw: item.postData.postView.firstImage!.orign,
              small: item.postData.postView.firstImage!.orign,
              middle: item.postData.postView.firstImage!.orign,
              rw: item.postData.postView.firstImage!.ow,
              rh: item.postData.postView.firstImage!.oh,
              ow: item.postData.postView.firstImage!.ow,
              oh: item.postData.postView.firstImage!.oh,
            )
          ];
        }
        break;
      case PostType.image:
        photoLinks = item.postData.postView.photoPostView!.photoLinks
            .map(
              (e) => PhotoLink(
                orign: e.orign,
                raw: e.orign,
                small: e.orign,
                middle: e.orign,
                rw: e.ow,
                rh: e.oh,
                ow: e.ow,
                oh: e.oh,
              ),
            )
            .toList();
        break;
      default:
        photoLinks = [];
    }
    return GeneralPostItem(
      type: getPostType(item),
      photoLinks: photoLinks,
      blogId: item.postData.postView.blogId,
      postId: item.postData.postView.id,
      permalink: item.postData.postView.permalink,
      collectionId: item.postData.postView.postCollection?.id ?? 0,
      liked: item.liked,
      blogName: item.postData.blogInfo.blogName,
      blogNickName: item.postData.blogInfo.blogNickName,
      title: item.postData.postView.title,
      digest: item.postData.postView.digest,
      content: item.postData.postView.content,
      firstImageUrl: item.postData.postView.firstImageUrl,
      duration: item.postData.postView.videoPostView?.videoInfo.duration ?? 0,
      likeCount: item.postData.postCountView.favoriteCount,
      tags: item.postData.postView.tagList,
      bigAvaImg: item.postData.blogInfo.bigAvaImg,
      publishTime: item.postData.postView.publishTime,
      opTime: item.opTime,
      shareInfo: item.shareInfo,
      followed: item.followed,
      shareCount: item.postData.postCountView.shareCount,
      commentCount: item.postData.postCountView.responseCount,
      shared: item.shared,
    );
  }

  static Widget buildWaterfallFlowPostItem(
      BuildContext context, GrainPostItem item) {
    return WaterfallFlowPostItemWidget(
      key: ValueKey(item.postData.postView.id),
      item: getGeneralPostItem(item),
    );
  }

  static Widget buildTilePostItem(
    BuildContext context,
    GrainPostItem item, {
    bool isFirst = false,
  }) {
    return TilePostItemWidget(
      item: getGeneralPostItem(item),
      isFirst: isFirst,
    );
  }

  static bool hasImage(GrainPostItem item) {
    return item.postData.postView.photoPostView != null &&
        item.postData.postView.photoPostView!.photoLinks.isNotEmpty;
  }

  static bool isVideo(GrainPostItem item) {
    return item.postData.postView.type == 4;
  }

  static bool isInvalid(GrainPostItem item) {
    return item.postData.postView.blogId == 0;
  }

  static bool hasContent(GrainPostItem item) {
    String title = Utils.clearBlank(item.postData.postView.title);
    String content = Utils.clearBlank(
        Utils.extractTextFromHtml(item.postData.postView.content));
    return (title.isNotEmpty || content.isNotEmpty);
  }

  static PostType getPostType(GrainPostItem item) {
    if (isInvalid(item)) {
      return PostType.invalid;
    }
    if (isVideo(item)) {
      return PostType.video;
    }
    if (hasImage(item)) {
      return PostType.image;
    } else {
      return PostType.article;
    }
  }

  static Widget buildNineGridPostItem(
    BuildContext context,
    GrainPostItem item, {
    double wh = 100,
    int? activePostId,
  }) {
    return GridPostItemWidget(
      wh: wh,
      activePostId: activePostId,
      item: getGeneralPostItem(item),
    );
  }
}
