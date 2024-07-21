import 'package:flutter/material.dart';

import '../../Models/post_detail_response.dart';
import '../../Models/recommend_response.dart';
import '../../Utils/constant.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/utils.dart';
import 'general_post_item_builder.dart';

class RecommendFlowItemBuilder {
  static GeneralPostItem getGeneralPostItem(
    PostListItem item, {
    String? excludeTag,
    final Function(String tag)? onShieldTag,
    final Function()? onShieldContent,
    final Function()? onShieldUser,
    bool showMoreButton = false,
  }) {
    List<PhotoLink> photoLinks = [];
    switch (getPostType(item)) {
      case PostType.video:
        String cover = "";
        if (Utils.isNotEmpty(item.postData!.postView.previewUrl)) {
          cover = item.postData!.postView.previewUrl!;
        } else {
          cover = item.postData!.postView.firstImage!.orign;
        }
        photoLinks = [
          PhotoLink(
            orign: cover,
            raw: cover,
            small: cover,
            middle: cover,
            rw: item.postData!.postView.firstImage!.ow,
            rh: item.postData!.postView.firstImage!.oh,
            ow: item.postData!.postView.firstImage!.ow,
            oh: item.postData!.postView.firstImage!.oh,
          )
        ];
        break;
      case PostType.image:
        photoLinks = [
          PhotoLink(
            orign: item.postData!.postView.firstImage!.orign,
            raw: item.postData!.postView.firstImage!.orign,
            small: item.postData!.postView.firstImage!.orign,
            middle: item.postData!.postView.firstImage!.orign,
            rw: item.postData!.postView.firstImage!.ow,
            rh: item.postData!.postView.firstImage!.oh,
            ow: item.postData!.postView.firstImage!.ow,
            oh: item.postData!.postView.firstImage!.oh,
          )
        ];
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
      collectionId: item.postData!.postCollection?.id ?? 0,
      liked: item.favorite,
      blogName: item.blogInfo!.blogName,
      blogNickName: item.blogInfo!.blogNickName,
      title: item.postData!.postView.title,
      digest: item.postData!.postView.digest,
      content: item.postData!.postView.digest,
      firstImageUrl: item.postData!.postView.firstImage?.orign ?? "",
      duration: item.postData!.postView.videoPostView?.videoInfo.duration ?? 0,
      likeCount: item.postData!.postCount!.favoriteCount,
      photoCount: item.postData!.postView.photoCount,
      tags: item.postData!.postView.tagList,
      bigAvaImg: item.blogInfo!.bigAvaImg,
      showArticle: HiveUtil.getBool(HiveUtil.showRecommendArticleKey),
      showVideo: HiveUtil.getBool(HiveUtil.showRecommendVideoKey),
      excludeTag: excludeTag,
      showMoreButton: showMoreButton,
      onShieldUser: onShieldUser,
      onShieldContent: onShieldContent,
      onShieldTag: onShieldTag,
    );
  }

  static Widget buildWaterfallFlowPostItem(
    BuildContext context,
    PostListItem item, {
    Future<int> Function()? onLikeTap,
    final Function(String tag)? onShieldTag,
    final Function()? onShieldContent,
    final Function()? onShieldUser,
    Function()? onTap,
    String? excludeTag,
    bool showMoreButton = false,
  }) {
    if (item.postData == null) return emptyWidget;
    return GeneralPostItemBuilder.buildWaterfallFlowPostItem(
      context,
      getGeneralPostItem(
        item,
        excludeTag: excludeTag,
        onShieldTag: onShieldTag,
        onShieldContent: onShieldContent,
        onShieldUser: onShieldUser,
        showMoreButton: showMoreButton,
      ),
      onTap: onTap,
      onLikeTap: onLikeTap,
    );
  }

  static bool isVideo(PostListItem item) {
    return item.postData?.postView.videoPostView != null;
  }

  static hasImage(PostListItem item) {
    return item.postData != null &&
        item.postData!.postView.firstImage != null &&
        item.postData!.postView.firstImage!.orign.isNotEmpty;
  }

  static isGrain(PostListItem item) {
    return item.grainInfo != null;
  }

  static isInvalid(PostListItem item) {
    return item.postData == null;
  }

  static PostType getPostType(PostListItem item) {
    if (isInvalid(item)) {
      return PostType.invalid;
    }
    if (isVideo(item)) {
      return PostType.video;
    }
    if (isGrain(item)) {
      return PostType.grain;
    }
    if (hasImage(item)) {
      return PostType.image;
    } else {
      return PostType.article;
    }
  }
}
