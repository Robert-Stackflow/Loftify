import 'package:flutter/material.dart';

import '../../Models/post_detail_response.dart';
import '../../Models/search_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/utils.dart';
import 'general_post_item_builder.dart';

class SearchPostFlowItemBuilder {
  static GeneralPostItem getGeneralPostItem(SearchPost item) {
    List<PhotoLink> photoLinks = [];
    switch (getPostType(item)) {
      case PostType.video:
        String cover = "";
        if (Utils.isNotEmpty(item.videoPostView!.videoInfo.videoImgUrl)) {
          cover = item.videoPostView!.videoInfo.videoImgUrl;
        } else {
          cover = item.videoPostView!.videoInfo.videoFirstImg;
        }
        photoLinks = [
          PhotoLink(
            orign: cover,
            raw: cover,
            small: cover,
            middle: cover,
            rw: Utils.parseToInt(item.videoPostView!.videoInfo.imgWidth),
            rh: Utils.parseToInt(item.videoPostView!.videoInfo.imgHeight),
            ow: Utils.parseToInt(item.videoPostView!.videoInfo.imgWidth),
            oh: Utils.parseToInt(item.videoPostView!.videoInfo.imgHeight),
          )
        ];
        break;
      case PostType.image:
        photoLinks = item.photoPostView!.photoLinks
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
      blogId: item.blogInfo.blogId,
      postId: item.id,
      permalink: item.permalink,
      collectionId: 0,
      liked: false,
      showLikeButton: false,
      blogName: item.blogInfo.blogName,
      blogNickName: item.blogInfo.blogNickName,
      title: item.title,
      digest: item.digest,
      content: item.digest,
      firstImageUrl: item.photoPostView?.firstImage.orign ?? "",
      duration: item.videoPostView?.videoInfo.duration ?? 0,
      likeCount: 0,
      photoCount: item.photoPostView?.photoLinks.length ?? 0,
      tags: item.tagList,
      bigAvaImg: item.blogInfo.bigAvaImg,
      showArticle: HiveUtil.getBool(key: HiveUtil.showRecommendArticleKey),
      showVideo: HiveUtil.getBool(key: HiveUtil.showRecommendVideoKey),
    );
  }

  static Widget buildWaterfallFlowPostItem(
    BuildContext context,
    SearchPost item, {
    Future<int> Function()? onLikeTap,
    Function()? onTap,
  }) {
    return GeneralPostItemBuilder.buildWaterfallFlowPostItem(
      context,
      getGeneralPostItem(item),
      onTap: onTap,
      onLikeTap: onLikeTap,
    );
  }

  static bool isVideo(SearchPost item) {
    return item.videoPostView != null;
  }

  static hasImage(SearchPost item) {
    return item.photoPostView != null &&
        item.photoPostView!.firstImage.orign.isNotEmpty;
  }

  static PostType getPostType(SearchPost item) {
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
