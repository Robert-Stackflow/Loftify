import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:loftify/Api/post_api.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/grain_response.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/search_response.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/video_list_controller.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/file_util.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Utils/route_util.dart';
import 'package:loftify/Widgets/PostItem/general_post_item_builder.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:video_player/video_player.dart';

import '../../Models/illust.dart';
import '../../Resources/colors.dart';
import '../../Resources/theme.dart';
import '../../Utils/cloud_control_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/comment_bottom_sheet.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class QuickerScrollPhysics extends BouncingScrollPhysics {
  const QuickerScrollPhysics({super.parent});

  @override
  QuickerScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return QuickerScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.2,
        stiffness: 300.0,
        ratio: 1.1,
      );
}

class VideoDetailScreen extends StatefulWidget {
  const VideoDetailScreen({
    super.key,
    this.postItem,
    this.postDetailData,
    this.favoritePostDetailData,
    this.meta,
    this.searchPost,
    this.grainPostItem,
    this.generalPostItem,
  });

  final GeneralPostItem? generalPostItem;
  final Map<String, String>? meta;
  final PostListItem? postItem;
  final GrainPostItem? grainPostItem;
  final PostDetailData? postDetailData;
  final SearchPost? searchPost;
  final FavoritePostDetailData? favoritePostDetailData;
  static const String routeName = "/video/detail";

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  PostListItem? _currentPostItem;
  final List<PostListItem> _postItemList = [];
  String permalink = "";
  int postId = 0;
  int blogId = 0;
  int page = 0;
  int offset = 0;
  double? downloadProgress;
  late ScrollController _scrollController;
  final PageController _pageController = PageController();
  final VideoListController _videoListController = VideoListController();

  @override
  void dispose() {
    _scrollController.dispose();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _videoListController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    super.didChangeDependencies();
  }

  @override
  void didPushNext() {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        _videoListController.currentPlayer.pause();
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.paused:
        _videoListController.currentPlayer.pause();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
    if (state != AppLifecycleState.resumed) {
      _videoListController.currentPlayer.pause();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController = ScrollController();
      _videoListController.addListener(() {
        if (mounted) setState(() {});
      });
      _initParams();
      Future.delayed(const Duration(milliseconds: 500), () {
        _fetchData();
      });
    });
  }

  _initParams() {
    if (widget.postItem != null) {
      permalink = widget.postItem!.postData!.postView.permalink;
      postId = widget.postItem!.postData!.postView.id;
      blogId = widget.postItem!.postData!.postView.blogId;
    } else if (widget.postDetailData != null) {
      permalink = widget.postDetailData!.post!.permalink;
      postId = widget.postDetailData!.post!.id;
      blogId = widget.postDetailData!.post!.blogId;
    } else if (widget.favoritePostDetailData != null) {
      permalink = widget.favoritePostDetailData!.post!.permalink;
      postId = widget.favoritePostDetailData!.post!.id;
      blogId = widget.favoritePostDetailData!.post!.blogId;
    } else if (widget.meta != null) {
      permalink = widget.meta!['permalink']!;
      postId = Utils.hexToInt(widget.meta!['postId']!);
      blogId = Utils.hexToInt(widget.meta!['blogId']!);
    } else if (widget.searchPost != null) {
      postId = widget.searchPost!.id;
      blogId = widget.searchPost!.blogId;
      permalink = widget.searchPost!.permalink;
    } else if (widget.grainPostItem != null) {
      postId = widget.grainPostItem!.postData.postView.id;
      blogId = widget.grainPostItem!.postData.postView.blogId;
      permalink = widget.grainPostItem!.postData.postView.permalink;
    } else if (widget.generalPostItem != null) {
      postId = widget.generalPostItem!.postId;
      blogId = widget.generalPostItem!.blogId;
      permalink = widget.generalPostItem!.permalink;
    }
  }

  _uploadHistory() async {
    if (_currentPostItem == null) return;
    int userId = await HiveUtil.getUserId();
    PostApi.uploadHistory(
      postId: _currentPostItem!.itemId,
      blogId: _currentPostItem!.blogInfo!.blogId,
      userId: userId,
      postType: _currentPostItem!.itemType,
      collectionId: _currentPostItem!.postCollection?.grainId,
    ).then((value) {
      if (value['code'] != 200) {
        IToast.showTop(value['msg']);
      }
    });
  }

  _fetchData({bool init = true}) async {
    List<PostListItem> tmp = [];
    await PostApi.getVideoDetail(
      permalink: permalink,
      offset: offset,
      count: page,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
        } else {
          page++;
          offset = value['data']['offset'];
          List<dynamic> t = value['data']['list'];
          for (var e in t) {
            tmp.add(PostListItem.fromJson(e));
          }
          _postItemList.addAll(tmp);
          if (init) {
            _initPlayer();
            _uploadHistory();
            _currentPostItem = _postItemList[0];
          }
          setState(() {});
        }
      } catch (e, t) {
        ILogger.error("Failed to load video detail", e, t);
        if (mounted) IToast.showTop(S.current.loadFailed);
      }
      if (mounted) setState(() {});
    });
    return tmp;
  }

  void _initPlayer() {
    _videoListController.init(
      context: context,
      pageController: _pageController,
      initialList: _postItemList
          .map(
            (e) => CustomVideoController(
              videoInfo: e,
              builder: () => VideoPlayerController.networkUrl(
                Uri.parse(
                    e.postData!.postView.videoPostView!.videoInfo.originUrl),
              ),
            ),
          )
          .toList(),
      videoProvider: (int index, List<CustomVideoController> list) async {
        List<PostListItem> tmp = await _fetchData(init: false);
        return tmp
            .map(
              (e) => CustomVideoController(
                videoInfo: e,
                builder: () => VideoPlayerController.networkUrl(
                  Uri.parse(
                      e.postData!.postView.videoPostView!.videoInfo.originUrl),
                ),
              ),
            )
            .toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            _buildBody(),
            if (!ResponsiveUtil.isLandscape()) _buildTopWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return PageView.builder(
      physics: const ClampingScrollPhysics(),
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videoListController.videoCount,
      onPageChanged: (index) {
        _currentPostItem = _postItemList[index];
        _uploadHistory();
      },
      itemBuilder: (context, index) {
        var player = _videoListController.playerOfIndex(index)!;
        return _buildVideoPage(
          player.videoInfo!,
          hidePauseIcon: !player.showPauseIcon.value,
          aspectRatio: 1,
          bottomPadding: 16.0,
          onSingleTap: () async {
            if (player.controller.value.isPlaying) {
              await player.pause();
            } else {
              await player.play();
            }
            setState(() {});
          },
          onAddFavorite: () {},
          video: Center(
            child: AspectRatio(
              aspectRatio: player.controller.value.aspectRatio,
              child: VideoPlayer(player.controller),
            ),
          ),
        );
      },
    );
  }

  _buildVideoPage(
    PostListItem postListItem, {
    double bottomPadding = 16,
    double aspectRatio = 9 / 16.0,
    bool hidePauseIcon = false,
    required Widget video,
    Function()? onSingleTap,
    Function()? onAddFavorite,
  }) {
    Widget videoContainer = Stack(
      children: <Widget>[
        Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.black,
          alignment: Alignment.center,
          child: aspectRatio == 1
              ? video
              : AspectRatio(
                  aspectRatio: aspectRatio,
                  child: video,
                ),
        ),
        if (!hidePauseIcon)
          Container(
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.center,
            child: Icon(
              Icons.play_arrow_rounded,
              size: 90,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
      ],
    );
    Widget body = Stack(
      children: <Widget>[
        videoContainer,
        Positioned(
          child: _buildVideoMeta(postListItem),
        ),
      ],
    );
    return GestureDetector(
      onTap: onSingleTap,
      child: body,
    );
  }

  _buildVideoMeta(PostListItem postListItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildPostContent(postListItem),
          ),
          VideoListButtonColumn(
            bottomPadding: 0,
            blogInfo: postListItem.blogInfo!,
            likeCount: postListItem.postData!.postCount!.favoriteCount,
            shareCount: postListItem.postData!.postCount!.shareCount,
            commentCount: postListItem.postData!.postCount!.responseCount,
            isShared: postListItem.share ?? false,
            isLiked: postListItem.favorite,
            isFollowing: postListItem.following,
            showDownloadButton:
                controlProvider.globalControl.showVideoDownloadButton,
            onLike: () {
              HapticFeedback.mediumImpact();
              PostApi.likeOrUnLike(
                      isLike: !(postListItem.favorite == true),
                      postId: postListItem.itemId,
                      blogId: postListItem.blogInfo!.blogId)
                  .then((value) {
                if (value['meta']['status'] != 200) {
                  IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
                } else {
                  postListItem.favorite = !(postListItem.favorite == true);
                  postListItem.postData!.postCount!.favoriteCount +=
                      postListItem.favorite == true ? 1 : -1;
                  if (mounted) setState(() {});
                }
              });
            },
            onComment: () {
              BottomSheetBuilder.showBottomSheet(
                context,
                (context) => SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: CommentBottomSheet(
                    postId: postListItem.postData!.postView.id,
                    blogId: postListItem.postData!.postView.blogId,
                    publishTime: postListItem.postData!.postView.publishTime,
                  ),
                ),
                enableDrag: false,
                backgroundColor: MyTheme.getBackground(context),
              );
            },
            onTapAvatar: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                UserDetailScreen(
                  blogId: postListItem.blogInfo!.blogId,
                  blogName: postListItem.blogInfo!.blogName,
                ),
              );
            },
            onFollow: () {
              HapticFeedback.mediumImpact();
              UserApi.followOrUnfollow(
                isFollow: !postListItem.following,
                blogId: postListItem.blogInfo!.blogId,
                blogName: postListItem.blogInfo!.blogName,
              ).then((value) {
                if (value['meta']['status'] != 200) {
                  IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
                }
                postListItem.following = !postListItem.following;
                setState(() {});
              });
            },
            onShare: () {
              HapticFeedback.mediumImpact();
              PostApi.shareOrUnShare(
                      isShare: !(postListItem.share == true),
                      postId: postListItem.itemId,
                      blogId: postListItem.blogInfo!.blogId)
                  .then((value) {
                if (value['meta']['status'] != 200) {
                  IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
                } else {
                  postListItem.share = !(postListItem.share == true);
                  postListItem.postData!.postCount!.shareCount +=
                      postListItem.share == true ? 1 : -1;
                  if (mounted) setState(() {});
                }
              });
            },
            downloadProgress: downloadProgress,
            onDownload: () {
              if (downloadProgress == null) {
                FileUtil.saveVideoByIllust(
                  context,
                  getIllust(postListItem),
                  onReceiveProgress: (count, total) {
                    downloadProgress = count / total;
                    setState(() {});
                  },
                ).then((res) {
                  downloadProgress = null;
                  setState(() {});
                });
              }
            },
          ),
        ],
      ),
    );
  }

  getIllust(PostListItem postListItem) {
    String rawUrl =
        postListItem.postData!.postView.videoPostView!.videoInfo.originUrl;
    return Illust(
      extension: FileUtil.extractFileExtensionFromUrl(rawUrl),
      originalName: FileUtil.extractFileNameFromUrl(rawUrl),
      blogId: postListItem.blogInfo!.blogId,
      blogLofterId: postListItem.blogInfo!.blogName,
      blogNickName: postListItem.blogInfo!.blogNickName,
      postId: postListItem.itemId,
      part: 0,
      url: rawUrl,
      postTitle: postListItem.postData!.postView.title,
      postDigest: postListItem.postData!.postView.digest,
      tags: postListItem.postData!.postView.tagList,
      publishTime: postListItem.postData!.postView.publishTime,
    );
  }

  _hasContent(PostListItem postListItem) {
    String title = Utils.clearBlank(postListItem.postData!.postView.title);
    String content = Utils.clearBlank(
        Utils.extractTextFromHtml(postListItem.postData!.postView.digest));
    return (title.isNotEmpty || content.isNotEmpty);
  }

  _buildPostContent(PostListItem postListItem) {
    String title = Utils.clearBlank(postListItem.postData!.postView.title);
    String digest = Utils.limitString(
        Utils.extractTextFromHtml(postListItem.postData!.postView.digest));
    return _hasContent(postListItem)
        ? Container(
            padding:
                const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (digest.isNotEmpty)
                  HtmlWidget(
                    "<p><strong>$title</strong></p>$digest",
                    textStyle: Theme.of(context).textTheme.titleSmall?.apply(
                          fontSizeDelta: 1,
                          color: Colors.grey[300],
                        ),
                    customStylesBuilder: (e) {
                      if (e.attributes.containsKey('href')) {
                        final color = Theme.of(context).primaryColor;
                        return {
                          'color':
                              '#${color.value.toRadixString(16).substring(2, 8)}'
                        };
                      }
                      return null;
                    },
                    onTapUrl: (url) async {
                      UriUtil.processUrl(context, url);
                      return true;
                    },
                  ),
                if (digest.isNotEmpty) const SizedBox(height: 8),
                if (postListItem.postData!.postView.tagList.isNotEmpty)
                  _buildTagList(postListItem),
              ],
            ),
          )
        : emptyWidget;
  }

  _buildTagList(PostListItem postListItem) {
    return Container(
      padding: EdgeInsets.only(
        right: 16,
        top: _hasContent(postListItem) ? 8 : 16,
        bottom: 8,
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.start,
        children: List.generate(
            min(3, postListItem.postData!.postView.tagList.length), (index) {
          return ItemBuilder.buildTagItem(
            context,
            postListItem.postData!.postView.tagList[index],
            TagType.normal,
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          );
        }),
      ),
    );
  }

  Widget _buildTopWidget() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Row(
          children: [
            ItemBuilder.buildIconButton(
              context: context,
              onTap: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoListButtonColumn extends StatelessWidget {
  final double? bottomPadding;
  final bool isLiked;
  final bool isShared;
  final bool isFollowing;
  final Function()? onLike;
  final Function()? onComment;
  final Function()? onDownload;
  final Function()? onShare;
  final Function()? onFollow;
  final Function()? onTapAvatar;
  final int likeCount;
  final int shareCount;
  final int commentCount;
  final SimpleBlogInfo blogInfo;
  final double? downloadProgress;
  final bool showDownloadButton;

  const VideoListButtonColumn({
    super.key,
    this.bottomPadding,
    this.showDownloadButton = true,
    this.onLike,
    this.onComment,
    this.onShare,
    this.isLiked = false,
    this.isShared = false,
    required this.likeCount,
    required this.shareCount,
    required this.commentCount,
    this.onDownload,
    this.onFollow,
    required this.blogInfo,
    this.isFollowing = false,
    this.onTapAvatar,
    this.downloadProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      margin: EdgeInsets.only(
        bottom: bottomPadding ?? 50,
        right: 12,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          GestureDetector(
            onTap: onTapAvatar,
            child: Stack(
              children: [
                const SizedBox(width: 45, height: 45),
                ItemBuilder.buildAvatar(
                  context: context,
                  imageUrl: blogInfo.bigAvaImg,
                  showLoading: false,
                  size: 40,
                  showBorder: false,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ItemBuilder.buildClickable(
                      GestureDetector(
                        onTap: onFollow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color:
                                  Theme.of(context).primaryColor.withAlpha(127),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            isFollowing
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            size: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _IconButton(
            icon: Icon(Icons.favorite_rounded,
                size: 35,
                color: isLiked ? MyColors.likeButtonColor : Colors.white),
            text: '$likeCount',
            onTap: onLike,
          ),
          _IconButton(
            icon: Icon(Icons.thumb_up_rounded,
                size: 35,
                color: isShared ? MyColors.shareButtonColor : Colors.white),
            text: '$shareCount',
            onTap: onShare,
          ),
          _IconButton(
            icon: const Icon(Icons.mode_comment_rounded,
                size: 35, color: Colors.white),
            text: '$commentCount',
            onTap: onComment,
          ),
          if (showDownloadButton)
            downloadProgress != null
                ? _IconButton(
                    icon: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(bottom: 3),
                      child: CircularProgressIndicator(
                        value: downloadProgress,
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    text: '${(downloadProgress! * 100).toStringAsFixed(0)}%',
                    onTap: onDownload,
                  )
                : _IconButton(
                    icon: const Icon(Icons.download_rounded,
                        size: 35, color: Colors.white),
                    text: S.current.download,
                    onTap: onDownload,
                  ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final Widget? icon;
  final String? text;
  final Function? onTap;

  const _IconButton({
    this.icon,
    this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget body = Column(
      children: <Widget>[
        GestureDetector(
          child: icon ?? emptyWidget,
          onTap: () {
            onTap?.call();
          },
        ),
        Container(height: 2),
        Text(
          text ?? '??',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ],
    );
    return ItemBuilder.buildClickable(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: body,
      ),
    );
  }
}

class VideoLoadingPlaceHolder extends StatelessWidget {
  const VideoLoadingPlaceHolder({
    super.key,
    required this.tag,
  });

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          colors: <Color>[
            Colors.blue,
            Colors.green,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // SpinKitWave(
          //   size: 36,
          //   color: Colors.white.withOpacity(0.3),
          // ),
          Container(
            padding: const EdgeInsets.all(50),
            child: Text(
              tag,
            ),
          ),
        ],
      ),
    );
  }
}
