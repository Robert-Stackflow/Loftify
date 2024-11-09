import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';

import '../../Api/post_api.dart';
import '../../Api/user_api.dart';
import '../../Models/collection_response.dart';
import '../../Models/post_detail_response.dart';
import '../../Models/recommend_response.dart';
import '../../Models/search_response.dart';
import '../../Models/user_response.dart';
import '../../Resources/colors.dart';
import '../../Screens/Info/user_detail_screen.dart';
import '../../Screens/Login/login_by_captcha_screen.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/constant.dart';
import '../../Utils/enums.dart';
import '../../Utils/itoast.dart';
import '../../Utils/lottie_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';
import '../Dialog/dialog_builder.dart';
import '../Window/window_caption.dart';
import 'item_builder.dart';

class LoftifyItemBuilder {
  static Widget buildCommentRow(
    BuildContext context,
    Comment comment, {
    Function()? onTap,
    Function(Comment)? onL2CommentTap,
    EdgeInsets? padding,
    EdgeInsets? l2Padding,
    required int writerId,
  }) {
    String richContent = comment.content;
    for (var e in comment.emotes) {
      String img =
          '<img src="${e.url}" style="height:50px;width:50px;" alt=""/>';
      richContent = richContent.replaceAll(e.name, img);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemBuilder.buildClickable(
              GestureDetector(
                onTap: () {
                  panelScreenState?.pushPage(
                    UserDetailScreen(
                        blogId: comment.publisherBlogInfo.blogId,
                        blogName: comment.publisherBlogInfo.blogName),
                  );
                },
                child: ItemBuilder.buildAvatar(
                  context: context,
                  imageUrl: comment.publisherBlogInfo.bigAvaImg,
                  showBorder: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ItemBuilder.buildClickable(
                              GestureDetector(
                                onTap: () {
                                  panelScreenState?.pushPage(
                                    UserDetailScreen(
                                        blogId:
                                            comment.publisherBlogInfo.blogId,
                                        blogName:
                                            comment.publisherBlogInfo.blogName),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        comment.publisherBlogInfo.blogNickName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                    if (writerId ==
                                        comment.publisherBlogInfo.blogId)
                                      const SizedBox(width: 3),
                                    if (writerId ==
                                        comment.publisherBlogInfo.blogId)
                                      ItemBuilder.buildRoundButton(
                                        context,
                                        text: S.current.author,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 3, vertical: 2),
                                        radius: 3,
                                        color: Theme.of(context).primaryColor,
                                        fontSizeDelta: -2,
                                      ),
                                    if (comment.top == 1)
                                      const SizedBox(width: 3),
                                    if (comment.top == 1)
                                      ItemBuilder.buildRoundButton(
                                        context,
                                        text: S.current.pin,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 3, vertical: 2),
                                        radius: 3,
                                        color: MyColors.likeButtonColor,
                                        fontSizeDelta: -2,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            ItemBuilder.buildCopyable(
                              context,
                              text: comment.content,
                              toastText: S.current.haveCopiedComment(
                                  comment.publisherBlogInfo.blogNickName),
                              child: ItemBuilder.buildHtmlWidget(
                                context,
                                richContent,
                                parseImage: false,
                                showLoading: false,
                                textStyle:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  Utils.formatTimestamp(comment.publishTime),
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                if (Utils.isNotEmpty(comment.ipLocation))
                                  LoftifyItemBuilder.buildDot(
                                    context,
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                if (Utils.isNotEmpty(comment.ipLocation))
                                  Text(
                                    comment.ipLocation,
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      LoftifyItemBuilder.buildLikedButton(
                        context,
                        isLiked: comment.liked,
                        size: 20,
                        iconSize: 16,
                        defaultColor:
                            Theme.of(context).textTheme.labelMedium?.color,
                        countStyle: Theme.of(context).textTheme.labelSmall,
                        position: CountPostion.bottom,
                        showCount: true,
                        likeCount: comment.likeCount,
                        zeroPlaceHolder: "",
                        onTap: (_) async {
                          HapticFeedback.mediumImpact();
                          await PostApi.likeOrUnlikeComment(
                            isLike: !comment.liked,
                            postId: comment.postId,
                            blogId: comment.blogId,
                            commentId: comment.id,
                          ).then((value) {
                            if (value['meta']['status'] != 200) {
                              IToast.showTop(value['meta']['desc'] ??
                                  value['meta']['msg']);
                            } else {
                              comment.liked = !comment.liked;
                              comment.likeCount += comment.liked ? 1 : -1;
                            }
                          });
                          return Future.sync(() => comment.liked);
                        },
                      ),
                    ],
                  ),
                  if (comment.l2Comments.isNotEmpty)
                    ...List.generate(
                      comment.l2Comments.length,
                      (l2Index) => buildL2CommentRow(
                        context,
                        padding: l2Padding,
                        comment.l2Comments[l2Index],
                        writerId: writerId,
                      ),
                    ),
                  if (comment.l2Count - comment.l2Comments.length > 0)
                    const SizedBox(height: 5),
                  if (comment.l2Count - comment.l2Comments.length > 0 &&
                      comment.l2CommentLoading)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            color:
                                Theme.of(context).textTheme.labelMedium?.color,
                            strokeWidth: 1.2,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          S.current.loading,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  if (comment.l2Count - comment.l2Comments.length > 0 &&
                      !comment.l2CommentLoading)
                    GestureDetector(
                      onTap: () => onL2CommentTap?.call(comment),
                      child: ItemBuilder.buildClickable(
                        Text.rich(
                          style: Theme.of(context).textTheme.labelMedium,
                          TextSpan(
                            style: Theme.of(context).textTheme.labelMedium,
                            children: [
                              TextSpan(
                                text: S.current.moreComments(comment.l2Count -
                                    comment.l2Comments.length),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              WidgetSpan(
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildL2CommentRow(
    BuildContext context,
    Comment comment, {
    Function()? onTap,
    EdgeInsets? padding,
    required int writerId,
  }) {
    String richContent = comment.content;
    for (var e in comment.emotes) {
      String img =
          '<img src="${e.url}" style="height:50px;width:50px;" alt=""/>';
      richContent = richContent.replaceAll(e.name, img);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.only(top: 12, right: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ItemBuilder.buildClickableGestureDetector(
                    onTap: () {
                      panelScreenState?.pushPage(
                        UserDetailScreen(
                            blogId: comment.publisherBlogInfo.blogId,
                            blogName: comment.publisherBlogInfo.blogName),
                      );
                    },
                    child: Row(
                      children: [
                        ItemBuilder.buildAvatar(
                          context: context,
                          imageUrl: comment.publisherBlogInfo.bigAvaImg,
                          showBorder: true,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.publisherBlogInfo.blogNickName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (writerId == comment.publisherBlogInfo.blogId)
                          const SizedBox(width: 3),
                        if (writerId == comment.publisherBlogInfo.blogId)
                          ItemBuilder.buildRoundButton(
                            context,
                            text: S.current.author,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 2),
                            radius: 3,
                            color: Theme.of(context).primaryColor,
                            fontSizeDelta: -2,
                          ),
                        if (comment.top == 1) const SizedBox(width: 3),
                        if (comment.top == 1)
                          ItemBuilder.buildRoundButton(
                            context,
                            text: S.current.pin,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 2),
                            radius: 3,
                            color: MyColors.likeButtonColor,
                            fontSizeDelta: -2,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  ItemBuilder.buildCopyable(
                    context,
                    text: comment.content,
                    toastText: S.current.haveCopiedComment(
                        comment.publisherBlogInfo.blogNickName),
                    child: ItemBuilder.buildHtmlWidget(
                      context,
                      richContent,
                      showLoading: false,
                      parseImage: false,
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        Utils.formatTimestamp(comment.publishTime),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      if (Utils.isNotEmpty(comment.ipLocation))
                        LoftifyItemBuilder.buildDot(
                          context,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      if (Utils.isNotEmpty(comment.ipLocation))
                        Text(
                          comment.ipLocation,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            LoftifyItemBuilder.buildLikedButton(
              context,
              isLiked: comment.liked,
              size: 20,
              iconSize: 16,
              defaultColor: Theme.of(context).textTheme.labelMedium?.color,
              countStyle: Theme.of(context).textTheme.labelSmall,
              position: CountPostion.bottom,
              showCount: true,
              likeCount: comment.likeCount,
              zeroPlaceHolder: "",
              onTap: (_) async {
                HapticFeedback.mediumImpact();
                await PostApi.likeOrUnlikeComment(
                  isLike: !comment.liked,
                  postId: comment.postId,
                  blogId: comment.blogId,
                  commentId: comment.id,
                ).then((value) {
                  if (value['meta']['status'] != 200) {
                    IToast.showTop(
                        value['meta']['desc'] ?? value['meta']['msg']);
                  } else {
                    comment.liked = !comment.liked;
                    comment.likeCount += comment.liked ? 1 : -1;
                  }
                });
                return Future.sync(() => comment.liked);
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildFollowerOrFollowingItem(
    BuildContext context,
    int index,
    FollowingUserItem item, {
    Function()? onFollowOrUnFollow,
  }) {
    return ItemBuilder.buildClickableGestureDetector(
      onTap: () {
        panelScreenState?.pushPage(
          UserDetailScreen(
            blogId: item.blogInfo.blogId,
            blogName: item.blogInfo.blogName,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            ItemBuilder.buildAvatar(
              context: context,
              size: 40,
              imageUrl: item.blogInfo.bigAvaImg,
              tagPrefix: "$index",
              showDetailMode: ShowDetailMode.not,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.blogInfo.blogNickName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (item.blogInfo.selfIntro.isNotEmpty)
                    const SizedBox(height: 5),
                  if (item.blogInfo.selfIntro.isNotEmpty)
                    Text(
                      item.blogInfo.selfIntro,
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (item.follower)
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.star_rate_rounded,
                  size: 22,
                  color: MyColors.getHotTagTextColor(context),
                ),
              ),
            LoftifyItemBuilder.buildFramedDoubleButton(
              context: context,
              isFollowed: item.following,
              positiveText:
                  item.follower ? S.current.followEach : S.current.followed,
              onTap: () {
                UserApi.followOrUnfollow(
                  isFollow: !item.following,
                  blogId: item.blogInfo.blogId,
                  blogName: item.blogInfo.blogName,
                ).then((value) {
                  if (value['meta']['status'] != 200) {
                    IToast.showTop(
                        value['meta']['desc'] ?? value['meta']['msg']);
                  } else {
                    item.following = !item.following;
                    IToast.showTop(item.following
                        ? S.current.followed
                        : S.current.followEach);
                    onFollowOrUnFollow?.call();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildLikedButton(
    BuildContext context, {
    Future<bool?> Function(bool)? onTap,
    double size = 25,
    double iconSize = 25,
    required bool? isLiked,
    bool filled = false,
    Color? defaultColor,
    bool showCount = false,
    int likeCount = 0,
    CountPostion position = CountPostion.bottom,
    EdgeInsetsGeometry? likeCountPadding,
    TextStyle? countStyle,
    AnimationController? animationController,
    String? zeroPlaceHolder,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: LikeButton(
        onTap: onTap,
        size: size,
        isLiked: isLiked,
        likeBuilder: (bool isLiked) {
          return Icon(
            isLiked || filled
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isLiked
                ? MyColors.likeButtonColor
                : defaultColor ?? Theme.of(context).iconTheme.color,
            size: iconSize,
          );
          // return LottieUtil.load(
          //   Utils.isDark(context)
          //       ? LottieUtil.likeBigNormalDark
          //       : LottieUtil.likeBigNormalLight,
          //   size: iconSize,
          //   controller: animationController,
          // );
          // return AssetUtil.loadDouble(
          //   context,
          //   isLiked || filled
          //       ? AssetUtil.likeFilledIcon
          //       : AssetUtil.likeLightIcon,
          //   isLiked || filled
          //       ? AssetUtil.likeFilledIcon
          //       : AssetUtil.likeLightIcon,
          //   size: iconSize,
          // );
        },
        likeCount: likeCount,
        countPostion: position,
        likeCountAnimationType: LikeCountAnimationType.none,
        likeCountPadding: likeCountPadding,
        countBuilder: (int? count, bool isLiked, String text) {
          return showCount
              ? Text(
                  count == 0 ? zeroPlaceHolder ?? S.current.like : text,
                  style: countStyle ?? Theme.of(context).textTheme.labelSmall,
                )
              : emptyWidget;
        },
      ),
    );
  }

  static Widget buildLikedLottieButton(
    BuildContext context, {
    Function()? onTap,
    double iconSize = 50,
    required bool? isLiked,
    bool filled = false,
    Color? defaultColor,
    bool showCount = false,
    int likeCount = 0,
    CountPostion position = CountPostion.bottom,
    EdgeInsetsGeometry? likeCountPadding,
    TextStyle? countStyle,
    AnimationController? animationController,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            LottieUtil.load(
              Utils.isDark(context)
                  ? LottieUtil.likeMediumDark
                  : LottieUtil.likeMediumLight,
              size: iconSize,
              fit: BoxFit.cover,
              controller: animationController,
              onLoaded: () {
                animationController?.value = isLiked! ? 1 : 0;
              },
            ),
            if (showCount)
              Positioned(
                bottom: -4,
                right: 0,
                left: 0,
                child: Text(
                  likeCount == 0 ? S.current.like : "$likeCount",
                  style: countStyle ?? Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildLottieSharedButton(
    BuildContext context, {
    Function()? onTap,
    double iconSize = 25,
    required bool? isShared,
    bool filled = false,
    Color? defaultColor,
    bool showCount = false,
    int shareCount = 0,
    EdgeInsetsGeometry? shareCountPadding,
    TextStyle? countStyle,
    AnimationController? animationController,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            LottieUtil.load(
              Utils.isDark(context)
                  ? LottieUtil.recommendMediumFocusDark
                  : LottieUtil.recommendMediumFocusLight,
              size: iconSize,
              fit: BoxFit.fill,
              controller: animationController,
            ),
            if (showCount)
              Positioned(
                bottom: -4,
                right: 0,
                left: 0,
                child: Text(
                  shareCount == 0 ? S.current.recommend : "$shareCount",
                  style: countStyle ?? Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildSharedButton(
    BuildContext context, {
    Future<bool?> Function(bool)? onTap,
    double size = 25,
    double iconSize = 25,
    required bool? isShared,
    bool filled = false,
    Color? defaultColor,
    bool showCount = false,
    int likeCount = 0,
    CountPostion position = CountPostion.bottom,
    EdgeInsetsGeometry? likeCountPadding,
    TextStyle? countStyle,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: LikeButton(
        onTap: onTap,
        size: size,
        isLiked: isShared,
        circleColor: MyColors.shareButtonCircleColor,
        bubblesColor: MyColors.shareButtonBubblesColor,
        likeBuilder: (bool isShared) {
          return Icon(
            isShared || filled
                ? Icons.thumb_up_rounded
                : Icons.thumb_up_outlined,
            color: isShared
                ? MyColors.shareButtonColor
                : defaultColor ?? Theme.of(context).iconTheme.color,
            size: iconSize,
          );
        },
        likeCount: likeCount,
        countPostion: position,
        likeCountPadding:
            likeCountPadding ?? const EdgeInsets.only(right: 3, bottom: 5),
        likeCountAnimationType: LikeCountAnimationType.none,
        countBuilder: (int? count, bool isLiked, String text) {
          return showCount
              ? Container(
                  margin: const EdgeInsets.only(top: 5),
                  child: Text(
                    count == 0 ? S.current.recommend : text,
                    style: countStyle ?? Theme.of(context).textTheme.labelSmall,
                  ),
                )
              : emptyWidget;
        },
      ),
    );
  }

  static Widget buildDot(
    BuildContext context, {
    TextStyle? style,
  }) {
    return Text(
      " · ",
      style: style ??
          Theme.of(context).textTheme.titleSmall?.apply(fontWeightDelta: 2),
    );
  }

  static Widget buildFramedDoubleButton({
    required BuildContext context,
    required bool isFollowed,
    required Function() onTap,
    String? positiveText,
    String? negtiveText,
    double radius = 50,
    Color? outline,
  }) {
    return Material(
      color: isFollowed ? Theme.of(context).cardColor : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: ItemBuilder.buildClickable(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isFollowed
                    ? Theme.of(context).dividerColor
                    : outline ?? Theme.of(context).primaryColor.withAlpha(127),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  isFollowed
                      ? positiveText ?? S.current.followed
                      : negtiveText ?? S.current.follow,
                  style: TextStyle(
                    color: isFollowed
                        ? Theme.of(context).textTheme.labelSmall?.color
                        : Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static buildUnLoginMainBody(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ResponsiveUtil.buildDesktopWidget(desktop: const WindowMoveHandle()),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 100),
                ItemBuilder.buildAvatar(
                  showLoading: false,
                  context: context,
                  useDefaultAvatar: true,
                  size: 72,
                  imageUrl: '',
                ),
                const SizedBox(height: 24),
                ItemBuilder.buildRoundButton(
                  context,
                  width: 230,
                  text: S.current.loginToGetPersonalizedService,
                  background: Theme.of(context).primaryColor,
                  fontSizeDelta: 2,
                  onTap: () {
                    if (ResponsiveUtil.isLandscape()) {
                      DialogBuilder.showPageDialog(
                        context,
                        child: const LoginByCaptchaScreen(),
                      );
                    } else {
                      panelScreenState?.pushPage(const LoginByCaptchaScreen());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static buildRankTagRow(
    BuildContext context,
    TagInfo tag, {
    Function()? onTap,
    bool useBackground = false,
  }) {
    return ItemBuilder.buildClickable(
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            image: useBackground
                ? DecorationImage(
                    image: AssetImage(Utils.isDark(context)
                        ? AssetUtil.tagRowBgDarkMess
                        : AssetUtil.tagRowBgMess),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  image: DecorationImage(
                    image: AssetImage(AssetUtil.tagIconBgMess),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Text(
                  textAlign: TextAlign.center,
                  tag.tagName,
                  style: Theme.of(context).textTheme.titleSmall?.apply(
                        color: Colors.white,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "#${tag.tagName}",
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        if (Utils.isNotEmpty(tag.rankName))
                          ItemBuilder.buildRoundButton(
                            context,
                            text: tag.rankName!,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 2,
                            ),
                            radius: 3,
                            color: MyColors.likeButtonColor,
                            fontSizeDelta: -2,
                          ),
                        if (tag.subscribed) const SizedBox(width: 5),
                        if (tag.subscribed)
                          ItemBuilder.buildRoundButton(
                            context,
                            text: S.current.subscribed,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 2),
                            radius: 3,
                            color: Theme.of(context).primaryColor,
                            fontSizeDelta: -2,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      S.current.joinCount(tag.joinCount.toString()),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.apply(fontWeightDelta: 1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ItemBuilder.buildRoundButton(
                context,
                text: S.current.enter,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Theme.of(context).primaryColor,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static buildTagRow(
    BuildContext context,
    TagInfo tag, {
    Function()? onTap,
    double verticalPadding = 12,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding:
            EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
        child: Row(
          children: [
            Icon(
              tag.joinCount == -1 ? Icons.search_rounded : Icons.tag_rounded,
              size: 20,
              color: Theme.of(context).textTheme.labelMedium?.color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tag.tagName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (tag.joinCount != -1)
              Text(
                S.current.joinCount(tag.joinCount.toString()),
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
      ),
    );
  }

  static buildCollectionRow(
    BuildContext context,
    Collection collection, {
    Function()? onTap,
    double verticalPadding = 12,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding:
            EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ItemBuilder.buildCachedImage(
                    context: context,
                    imageUrl: collection.coverUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    showLoading: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.apply(fontWeightDelta: 2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${collection.postCount}${S.current.chapter} · ${S.current.updateAt}${Utils.formatTimestamp(collection.lastPublishTime)}",
                          style: Theme.of(context).textTheme.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: 20,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ...List.generate(
                                collection.tags.length,
                                (index) => Container(
                                  margin: const EdgeInsets.only(right: 5),
                                  child: ItemBuilder.buildSmallTagItem(
                                    context,
                                    collection.tags[index],
                                    showIcon: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  static buildGrainRow(
    BuildContext context,
    GrainInfo grain, {
    Function()? onTap,
    double verticalPadding = 12,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding:
            EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ItemBuilder.buildCachedImage(
                    context: context,
                    imageUrl: grain.coverUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    showLoading: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grain.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.apply(fontWeightDelta: 2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${grain.postCount}${S.current.chapter} · ${S.current.updateAt}${Utils.formatTimestamp(grain.updateTime)}",
                          style: Theme.of(context).textTheme.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        SizedBox(
                          height: 20,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ...List.generate(
                                grain.tags.length,
                                (index) => Container(
                                  margin: const EdgeInsets.only(right: 5),
                                  child: ItemBuilder.buildSmallTagItem(
                                    context,
                                    grain.tags[index],
                                    showIcon: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  static buildUserRow(BuildContext context, SearchBlogData blog,
      {Function()? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            ItemBuilder.buildAvatar(
              context: context,
              imageUrl: blog.blogInfo.bigAvaImg,
              showLoading: false,
              size: 40,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.blogInfo.blogNickName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    "ID: ${blog.blogInfo.blogName}${blog.blogCount != null && blog.blogCount!.publicPostCount > 0 ? "   ${S.current.article}: ${blog.blogCount!.publicPostCount}" : ""}${blog.blogCount != null && blog.blogCount!.followerCount > 0 ? "   ${S.current.follower}: ${blog.blogCount!.followerCount}" : ""}",
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
