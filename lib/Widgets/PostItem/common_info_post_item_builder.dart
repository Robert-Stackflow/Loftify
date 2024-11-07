import 'package:flutter/material.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/utils.dart';
import '../PostItem/general_post_item_builder.dart';

class CommonInfoItemBuilder {
  static GeneralPostItem getGeneralPostItem(PostDetailData item) {
    List<PhotoLink> photoLinks = [];
    switch (getPostType(item)) {
      case PostType.video:
        photoLinks = Utils.parseJsonList(item.post!.firstImageUrl)
            .map(
              (e) => PhotoLink(
                orign: e.toString(),
                raw: e.toString(),
                small: e.toString(),
                middle: e.toString(),
                rw: 0,
                rh: 0,
                ow: 0,
                oh: 0,
              ),
            )
            .toList();
        break;
      case PostType.image:
        photoLinks = Utils.parseJsonList(item.post!.photoLinks)
            .map((e) => PhotoLink.fromJson(e))
            .toList();
        break;
      default:
        photoLinks = [];
    }
    return GeneralPostItem(
      type: getPostType(item),
      photoLinks: photoLinks,
      blogId: item.post!.blogInfo!.blogId,
      postId: item.post!.id,
      permalink: item.post!.permalink,
      collectionId: item.post!.postCollection?.id ?? 0,
      liked: item.liked!,
      blogName: item.post!.blogInfo!.blogName,
      blogNickName: item.post!.blogInfo!.blogNickName,
      title: item.post!.title,
      digest: item.post!.digest,
      content: item.post!.content,
      firstImageUrl: item.post!.firstImageUrl,
      duration: item.post!.videoInfo?.duration ?? 0,
      likeCount: item.post!.postCount?.favoriteCount ?? 0,
      tags: item.post!.tagList,
      bigAvaImg: item.post!.blogInfo!.bigAvaImg,
    );
  }

  static Widget buildWaterfallFlowPostItem(
      BuildContext context, PostDetailData item) {
    return WaterfallFlowPostItemWidget(
      key: ValueKey(item.post!.id),
      item: getGeneralPostItem(item),
    );
  }

  static bool hasImage(PostDetailData item) {
    return item.post!.photoLinks.isNotEmpty;
  }

  static bool isVideo(PostDetailData item) {
    return item.post!.type == 4;
  }

  static bool isInvalid(PostDetailData item) {
    return item.post == null ||
        item.post!.blogId == 0 ||
        item.post!.publisherUserId == 0;
  }

  static PostType getPostType(PostDetailData item) {
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
    PostDetailData item, {
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
