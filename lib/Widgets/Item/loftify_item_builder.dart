import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';
import 'package:loftify/Utils/lottie_files.dart';

import '../../Api/post_api.dart';
import '../../Api/user_api.dart';
import '../../Models/collection_response.dart';
import '../../Models/post_detail_response.dart';
import '../../Models/recommend_response.dart';
import '../../Models/search_response.dart';
import '../../Models/user_response.dart';
import '../../Screens/Info/user_detail_screen.dart';
import '../../Screens/Login/login_by_captcha_screen.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/enums.dart';
import '../PostDetail/comment_item.dart';
import '../../l10n/l10n.dart';
import '../loftify_icons.dart';
import 'item_builder.dart';

const CircleColor shareButtonCircleColor =
    CircleColor(start: Color(0xff00ddff), end: Color(0xff0099cc));
const BubblesColor shareButtonBubblesColor = BubblesColor(
  dotPrimaryColor: Color(0xff33b5e5),
  dotSecondaryColor: Color(0xff0099cc),
);

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
    final remainingReplies =
        max(0, comment.l2Count - comment.l2Comments.length);
    return CommentItem(
      margin: padding,
      onTap: onTap,
      avatar: _buildCommentAvatar(context, comment, size: 38),
      header: _buildCommentHeader(context, comment, writerId: writerId),
      content: _buildCommentContent(context, comment),
      metadata: _buildCommentMetadata(context, comment),
      trailing: _buildCommentLikeButton(context, comment),
      replies: [
        for (final reply in comment.l2Comments)
          buildL2CommentRow(
            context,
            reply,
            padding: l2Padding,
            writerId: writerId,
          ),
      ],
      footer: remainingReplies == 0
          ? null
          : comment.l2CommentLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: chewieProvider.loadingWidgetBuilder(16, false),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      appLocalizations.loading,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                )
              : Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => onL2CommentTap?.call(comment),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              appLocalizations.moreComments(remainingReplies),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          const SizedBox(width: 2),
                          ChewieIcon(
                            LoftifyIcons.expand,
                            size: 17,
                            color:
                                Theme.of(context).textTheme.labelMedium?.color,
                          ),
                        ],
                      ),
                    ),
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
    return CommentItem(
      nested: true,
      margin: padding,
      onTap: onTap,
      avatar: _buildCommentAvatar(context, comment, size: 28),
      header: _buildCommentHeader(context, comment, writerId: writerId),
      content: _buildCommentContent(context, comment),
      metadata: _buildCommentMetadata(context, comment),
      trailing: _buildCommentLikeButton(context, comment),
    );
  }

  static Widget _buildCommentAvatar(
    BuildContext context,
    Comment comment, {
    required double size,
  }) {
    return ClickableGestureDetector(
      onTap: () => _openCommentAuthor(comment),
      child: ItemBuilder.buildAvatar(
        context: context,
        imageUrl: comment.publisherBlogInfo.bigAvaImg,
        showBorder: true,
        size: size,
      ),
    );
  }

  static Widget _buildCommentHeader(
    BuildContext context,
    Comment comment, {
    required int writerId,
  }) {
    final replyName = comment.replyBlogInfo?.blogNickName;
    return ClickableGestureDetector(
      onTap: () => _openCommentAuthor(comment),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.publisherBlogInfo.blogNickName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.78),
                      ),
                ),
              ),
              if (writerId == comment.publisherBlogInfo.blogId) ...[
                const SizedBox(width: 4),
                _buildCommentBadge(
                  context,
                  appLocalizations.author,
                  Theme.of(context).primaryColor,
                ),
              ],
              if (comment.top == 1) ...[
                const SizedBox(width: 4),
                _buildCommentBadge(
                  context,
                  appLocalizations.pin,
                  ChewieColors.likeButtonColor,
                ),
              ],
            ],
          ),
          if (StringUtil.isNotEmpty(replyName)) ...[
            const SizedBox(height: 2),
            Text(
              appLocalizations.replyTo(replyName!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.52),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildCommentBadge(
    BuildContext context,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }

  static Widget _buildCommentContent(BuildContext context, Comment comment) {
    var richContent = comment.content;
    for (final emote in comment.emotes) {
      final image =
          '<img src="${emote.url}" style="height:38px;width:38px;" alt=""/>';
      richContent = richContent.replaceAll(emote.name, image);
    }
    return ItemBuilder.buildCopyable(
      context,
      text: comment.content,
      toastText: appLocalizations.haveCopiedComment(
        comment.publisherBlogInfo.blogNickName,
      ),
      child: CustomHtmlWidget(
        content: richContent,
        parseImage: false,
        showLoading: false,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  static Widget _buildCommentMetadata(BuildContext context, Comment comment) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.56),
        );
    return Wrap(
      spacing: 5,
      runSpacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(TimeUtil.formatTimestamp(comment.publishTime), style: style),
        if (StringUtil.isNotEmpty(comment.ipLocation)) Text('·', style: style),
        if (StringUtil.isNotEmpty(comment.ipLocation))
          Text(comment.ipLocation, style: style),
      ],
    );
  }

  static Widget _buildCommentLikeButton(
    BuildContext context,
    Comment comment,
  ) {
    return LoftifyItemBuilder.buildLikedButton(
      context,
      isLiked: comment.liked,
      size: 22,
      iconSize: 17,
      defaultColor: Theme.of(context).textTheme.labelMedium?.color,
      countStyle: Theme.of(context).textTheme.labelSmall,
      position: CountPostion.bottom,
      showCount: true,
      likeCount: comment.likeCount,
      zeroPlaceHolder: '',
      onTap: (_) async {
        HapticFeedback.mediumImpact();
        final value = await PostApi.likeOrUnlikeComment(
          isLike: !comment.liked,
          postId: comment.postId,
          blogId: comment.blogId,
          commentId: comment.id,
        );
        if (value['meta']['status'] != 200) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        } else {
          comment.liked = !comment.liked;
          comment.likeCount += comment.liked ? 1 : -1;
        }
        return comment.liked;
      },
    );
  }

  static void _openCommentAuthor(Comment comment) {
    panelScreenState?.pushPage(
      UserDetailScreen(
        blogId: comment.publisherBlogInfo.blogId,
        blogName: comment.publisherBlogInfo.blogName,
      ),
    );
  }

  static Widget buildFollowerOrFollowingItem(
    BuildContext context,
    int index,
    FollowingUserItem item, {
    Function()? onFollowOrUnFollow,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.65),
          width: 0.6,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          panelScreenState?.pushPage(
            UserDetailScreen(
              blogId: item.blogInfo.blogId,
              blogName: item.blogInfo.blogName,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              ItemBuilder.buildAvatar(
                context: context,
                size: 48,
                imageUrl: item.blogInfo.bigAvaImg,
                tagPrefix: "relation-${item.blogInfo.blogId}",
                showDetailMode: ShowDetailMode.not,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.blogInfo.blogNickName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID: ${item.blogInfo.blogName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.blogInfo.selfIntro.isNotEmpty)
                      const SizedBox(height: 3),
                    if (item.blogInfo.selfIntro.isNotEmpty)
                      Text(
                        item.blogInfo.selfIntro,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LoftifyItemBuilder.buildFramedDoubleButton(
                context: context,
                isFollowed: item.following,
                positiveText: item.follower
                    ? appLocalizations.followEach
                    : appLocalizations.followed,
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
                          ? appLocalizations.followed
                          : appLocalizations.followEach);
                      onFollowOrUnFollow?.call();
                    }
                  });
                },
              ),
            ],
          ),
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
          return ChewieIcon(
            LoftifyIcons.favorite,
            color: isLiked
                ? ChewieColors.likeButtonColor
                : defaultColor ?? Theme.of(context).iconTheme.color,
            size: iconSize,
          );
          // return LottieUtil.load(
          //   ColorUtil.isDark(context)
          //       ? LottieUtil.likeBigNormalDark
          //       : LottieUtil.likeBigNormalLight,
          //   size: iconSize,
          //   controller: animationController,
          // );
        },
        likeCount: likeCount,
        countPostion: position,
        likeCountAnimationType: LikeCountAnimationType.none,
        likeCountPadding: likeCountPadding,
        countBuilder: (int? count, bool isLiked, String text) {
          return showCount
              ? Text(
                  count == 0 ? zeroPlaceHolder ?? appLocalizations.like : text,
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
              ColorUtil.isDark(context)
                  ? LottieFiles.likeMediumDark
                  : LottieFiles.likeMediumLight,
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
                  likeCount == 0 ? appLocalizations.like : "$likeCount",
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
              ColorUtil.isDark(context)
                  ? LottieFiles.recommendMediumFocusDark
                  : LottieFiles.recommendMediumFocusLight,
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
                  shareCount == 0 ? appLocalizations.recommend : "$shareCount",
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
        circleColor: shareButtonCircleColor,
        bubblesColor: shareButtonBubblesColor,
        likeBuilder: (bool isShared) {
          return ChewieIcon(
            LoftifyIcons.recommend,
            color: isShared
                ? ChewieColors.shareButtonColor
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
                    count == 0 ? appLocalizations.recommend : text,
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
        child: ClickableWrapper(
          child: Container(
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
                      ? positiveText ?? appLocalizations.followed
                      : negtiveText ?? appLocalizations.follow,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isFollowed
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).primaryColor,
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
          ResponsiveUtil.selectByPlatform(desktop: const WindowMoveHandle()),
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
                RoundIconTextButton(
                  width: 230,
                  text: appLocalizations.loginToGetPersonalizedService,
                  background: Theme.of(context).primaryColor,
                  fontSizeDelta: 2,
                  onPressed: () {
                    if (ResponsiveUtil.isLandscapeLayout()) {
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
    return ClickableGestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          image: useBackground
              ? DecorationImage(
                  image: AssetImage(ColorUtil.isDark(context)
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
                      if (StringUtil.isNotEmpty(tag.rankName))
                        RoundIconTextButton(
                          text: tag.rankName!,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 2,
                          ),
                          radius: 3,
                          color: ChewieColors.likeButtonColor,
                          fontSizeDelta: -2,
                        ),
                      if (tag.subscribed) const SizedBox(width: 5),
                      if (tag.subscribed)
                        RoundIconTextButton(
                          text: appLocalizations.subscribed,
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
                    appLocalizations.joinCount(tag.joinCount.toString()),
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
            RoundIconTextButton(
              text: appLocalizations.enter,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Theme.of(context).primaryColor,
              onPressed: onTap,
            ),
          ],
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
            ChewieIcon(
              tag.joinCount == -1 ? LoftifyIcons.search : LoftifyIcons.tag,
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
                appLocalizations.joinCount(tag.joinCount.toString()),
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
                  child: ChewieItemBuilder.buildCachedImage(
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
                          "${collection.postCount}${appLocalizations.chapter} · ${appLocalizations.updateAt}${TimeUtil.formatTimestamp(collection.lastPublishTime)}",
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
                  child: ChewieItemBuilder.buildCachedImage(
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
                          "${grain.postCount}${appLocalizations.chapter} · ${appLocalizations.updateAt}${TimeUtil.formatTimestamp(grain.updateTime)}",
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
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.65),
          width: 0.6,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              ItemBuilder.buildAvatar(
                context: context,
                imageUrl: blog.blogInfo.bigAvaImg,
                showLoading: false,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blog.blogInfo.blogNickName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${blog.blogInfo.blogName}${blog.blogCount != null && blog.blogCount!.publicPostCount > 0 ? "   ${appLocalizations.article}: ${blog.blogCount!.publicPostCount}" : ""}${blog.blogCount != null && blog.blogCount!.followerCount > 0 ? "   ${appLocalizations.follower}: ${blog.blogCount!.followerCount}" : ""}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
