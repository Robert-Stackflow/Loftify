import 'package:flutter/material.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../PostItem/general_post_item_builder.dart';

class FavoriteFolderPostItemBuilder {
  static GeneralPostItem getGeneralPostItem(FavoritePostDetailData item) {
    List<PhotoLink> photoLinks = [];
    switch (getPostType(item)) {
      case PostType.video:
        String url =
            item.postData!.postView.videoPostView!.videoInfo.videoFirstImg;
        photoLinks = [
          PhotoLink(
            orign: url,
            raw: url,
            small: url,
            middle: url,
            rw: 0,
            rh: 0,
            ow: 0,
            oh: 0,
          ),
        ];
        break;
      case PostType.image:
        photoLinks = item.postData!.postView.photoPostView!.photoLinks
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
      blogId: item.postData!.postView.blogId,
      postId: item.postData!.postView.id,
      permalink: item.postData!.postView.permalink,
      collectionId: item.postData!.postView.postCollection?.id ?? 0,
      liked: item.liked!,
      blogName: item.postData!.blogInfo.blogName,
      blogNickName: item.postData!.blogInfo.blogNickName,
      title: item.postData!.postView.title,
      digest: item.postData!.postView.digest,
      content: item.postData!.postView.content,
      firstImageUrl: item.postData!.postView.firstImageUrl,
      duration: item.postData!.postView.videoPostView?.videoInfo.duration ?? 0,
      likeCount: item.postData!.postView.postCount?.favoriteCount ?? 0,
      tags: item.postData!.postView.tagList,
      bigAvaImg: item.postData!.blogInfo.bigAvaImg,
    );
  }

  static Widget buildNineGridPostItem(
    BuildContext context,
    FavoritePostDetailData item, {
    double wh = 100,
    int? activePostId,
  }) {
    return GridPostItemWidget(
      wh: wh,
      activePostId: activePostId,
      item: getGeneralPostItem(item),
    );
  }

  static bool hasImage(FavoritePostDetailData item) {
    return item.postData!.postView.photoPostView!.photoLinks.isNotEmpty;
  }

  static bool isVideo(FavoritePostDetailData item) {
    return item.postData!.postView.type == 4;
  }

  static bool isInvalid(FavoritePostDetailData item) {
    return item.postData!.postView.blogId == 0;
  }

  static PostType getPostType(FavoritePostDetailData item) {
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
}
