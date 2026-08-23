import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Models/post_detail_response.dart';
import '../../Models/recommend_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
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
    final postData = item.postData;
    if (postData == null) {
      return _invalidPostItem(item.itemId);
    }
    final postView = postData.postView;
    final blogInfo = item.blogInfo;
    List<PhotoLink> photoLinks = [];
    PostType type = getPostType(item);
    switch (type) {
      case PostType.video:
        final firstImage = postView.firstImage;
        final cover = StringUtil.isNotEmpty(postView.previewUrl)
            ? postView.previewUrl!
            : firstImage?.orign ?? '';
        if (StringUtil.isNotEmpty(cover)) {
          photoLinks = [
            PhotoLink(
              orign: cover,
              raw: cover,
              small: cover,
              middle: cover,
              rw: firstImage?.ow ?? 0,
              rh: firstImage?.oh ?? 0,
              ow: firstImage?.ow ?? 0,
              oh: firstImage?.oh ?? 0,
            )
          ];
        }
        break;
      case PostType.image:
        final firstImage = postView.firstImage!;
        photoLinks = [
          PhotoLink(
            orign: firstImage.orign,
            raw: firstImage.orign,
            small: firstImage.orign,
            middle: firstImage.orign,
            rw: firstImage.ow,
            rh: firstImage.oh,
            ow: firstImage.ow,
            oh: firstImage.oh,
          )
        ];
        break;
      default:
        photoLinks = [];
    }
    return GeneralPostItem(
      type: type,
      photoLinks: photoLinks,
      blogId: postView.blogId,
      postId: postView.id,
      permalink: postView.permalink,
      collectionId: postData.postCollection?.id ?? 0,
      liked: item.favorite,
      blogName: blogInfo?.blogName ?? '',
      blogNickName: blogInfo?.blogNickName ?? '',
      title: postView.title,
      digest: postView.digest,
      content: postView.digest,
      firstImageUrl: postView.firstImage?.orign ?? '',
      duration: postView.videoPostView?.videoInfo.duration ?? 0,
      likeCount: postData.postCount?.favoriteCount ?? 0,
      photoCount: postView.photoCount,
      tags: postView.tagList,
      bigAvaImg: blogInfo?.bigAvaImg ?? '',
      showArticle: ChewieHiveUtil.getBool(HiveUtil.showRecommendArticleKey),
      showVideo: ChewieHiveUtil.getBool(HiveUtil.showRecommendVideoKey),
      excludeTag: excludeTag,
      showMoreButton: showMoreButton,
      onShieldUser: onShieldUser,
      onShieldContent: onShieldContent,
      onShieldTag: onShieldTag,
    );
  }

  static GeneralPostItem _invalidPostItem(int postId) {
    return GeneralPostItem(
      type: PostType.invalid,
      photoLinks: const [],
      blogId: 0,
      postId: postId,
      permalink: '',
      collectionId: 0,
      liked: false,
      blogName: '',
      blogNickName: '',
      title: '',
      digest: '',
      content: '',
      firstImageUrl: '',
      duration: 0,
      likeCount: 0,
      tags: const [],
      bigAvaImg: '',
    );
  }

  static Widget buildWaterfallFlowPostItem(
    BuildContext context,
    PostListItem item, {
    // final Function(String tag)? onShieldTag,
    // final Function()? onShieldContent,
    // final Function()? onShieldUser,
    String? excludeTag,
    bool showMoreButton = false,
  }) {
    return WaterfallFlowPostItemWidget(
      key: ValueKey(item.postData?.postView.id ?? item.itemId),
      item: getGeneralPostItem(
        item,
        excludeTag: excludeTag,
        // onShieldTag: onShieldTag,
        // onShieldContent: onShieldContent,
        // onShieldUser: onShieldUser,
        showMoreButton: showMoreButton,
      ),
    );
  }

  static Widget buildNineGridPostItem(
    BuildContext context,
    PostListItem item, {
    double wh = 100,
    int? activePostId,
  }) {
    return GridPostItemWidget(
      key: ValueKey(item.postData?.postView.id ?? item.itemId),
      wh: wh,
      activePostId: activePostId,
      item: getGeneralPostItem(
        item,
      ),
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
