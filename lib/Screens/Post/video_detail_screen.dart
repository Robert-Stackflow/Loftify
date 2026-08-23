import 'dart:async';
import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
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
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Widgets/PostItem/general_post_item.dart';
import 'package:video_player/video_player.dart';

import '../../Models/illust.dart';
import '../../Utils/cloud_control_provider.dart';
import '../../Utils/loftify_file_util.dart';
import '../../Widgets/BottomSheet/comment_bottom_sheet.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

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

class _VideoDetailScreenState extends BaseDynamicState<VideoDetailScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  PostListItem? _currentPostItem;
  final List<PostListItem> _postItemList = [];
  String permalink = "";
  int postId = 0;
  int blogId = 0;
  int page = 0;
  int offset = 0;
  final PageController _pageController = PageController();
  final VideoListController _videoListController = VideoListController();
  final GlobalKey<InteractiveAuthorSwipeState> _authorSwipeKey =
      GlobalKey<InteractiveAuthorSwipeState>();
  final Map<int, double> _downloadProgress = {};
  final Map<int, List<String>> _danmakuMessages = {};
  final Set<int> _loadingDanmaku = {};
  Timer? _initialFetchTimer;
  PageRoute<dynamic>? _subscribedRoute;
  Object? _initialLoadError;
  Size? _sizeBeforeFullscreen;
  bool _initialLoading = true;
  bool _fetching = false;
  bool _hasMoreVideo = true;
  bool _routeVisible = true;
  bool _resumeAfterInterruption = false;
  bool _isFullScreen = false;
  bool _authorPaneOpen = false;
  bool _authorNavigationPending = false;
  bool _continuousPlayback = false;
  bool _danmakuEnabled = false;
  bool _autoAdvanceInProgress = false;
  double _playbackSpeed = 1;
  int _requestGeneration = 0;

  @override
  void dispose() {
    _initialFetchTimer?.cancel();
    _requestGeneration++;
    if (_subscribedRoute != null) {
      chewieProvider.routeObserver.unsubscribe(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    _videoListController.removeListener(_handleVideoControllerChanged);
    _videoListController.dispose();
    _pageController.dispose();
    if (_isFullScreen) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
      unawaited(ResponsiveUtil.restoreOrientationPolicy(
        logicalSize: _sizeBeforeFullscreen,
      ));
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && !identical(route, _subscribedRoute)) {
      if (_subscribedRoute != null) {
        chewieProvider.routeObserver.unsubscribe(this);
      }
      _subscribedRoute = route;
      chewieProvider.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _pauseForInterruption();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _resumeFromInterruption();
  }

  @override
  void didPop() {
    _routeVisible = false;
    unawaited(_videoListController.pauseCurrent());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_routeVisible) _resumeFromInterruption();
      return;
    }
    _pauseForInterruption();
  }

  @override
  void initState() {
    super.initState();
    _continuousPlayback = ChewieHiveUtil.getBool(
      HiveUtil.videoContinuousPlaybackKey,
      defaultValue: false,
    );
    _danmakuEnabled = ChewieHiveUtil.getBool(
      HiveUtil.videoDanmakuEnabledKey,
      defaultValue: false,
    );
    WidgetsBinding.instance.addObserver(this);
    _videoListController.addListener(_handleVideoControllerChanged);
    _initParams();
    _initialFetchTimer = Timer(const Duration(milliseconds: 250), _fetchData);
  }

  void _handleVideoControllerChanged() {
    final value =
        _videoListController.currentPlayerOrNull?.controllerOrNull?.value;
    if (_continuousPlayback &&
        !_autoAdvanceInProgress &&
        (value?.isCompleted ?? false)) {
      unawaited(_advanceToNextVideo());
    }
    if (mounted) setState(() {});
  }

  void _pauseForInterruption() {
    final player = _videoListController.currentPlayerOrNull;
    _resumeAfterInterruption =
        _resumeAfterInterruption || (player?.isPlaying ?? false);
    unawaited(player?.pause() ?? Future<void>.value());
  }

  void _resumeFromInterruption() {
    if (!_resumeAfterInterruption) return;
    _resumeAfterInterruption = false;
    unawaited(_videoListController.resumeCurrent());
  }

  Future<void> _advanceToNextVideo() async {
    if (_autoAdvanceInProgress || !_continuousPlayback || !mounted) return;
    final nextIndex = _videoListController.index.value + 1;
    if (nextIndex >= _videoListController.videoCount ||
        !_pageController.hasClients) {
      return;
    }
    _autoAdvanceInProgress = true;
    try {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _autoAdvanceInProgress = false;
    }
  }

  Future<void> _setContinuousPlayback(bool enabled) async {
    if (_continuousPlayback == enabled) return;
    if (mounted) setState(() => _continuousPlayback = enabled);
    await Future.wait([
      ChewieHiveUtil.put(HiveUtil.videoContinuousPlaybackKey, enabled),
      ..._videoListController.playerList
          .map((player) => player.setLooping(!enabled)),
    ]);
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    if (_playbackSpeed == speed) return;
    if (mounted) setState(() => _playbackSpeed = speed);
    await Future.wait(
      _videoListController.playerList
          .map((player) => player.setPlaybackSpeed(speed)),
    );
  }

  Future<void> _setDanmakuEnabled(
    bool enabled,
    PostListItem item,
  ) async {
    if (mounted) setState(() => _danmakuEnabled = enabled);
    await ChewieHiveUtil.put(HiveUtil.videoDanmakuEnabledKey, enabled);
    if (enabled) await _loadDanmaku(item);
  }

  Future<void> _loadDanmaku(PostListItem item) async {
    final itemId = item.itemId;
    if (_danmakuMessages.containsKey(itemId) || !_loadingDanmaku.add(itemId)) {
      return;
    }
    try {
      final response = await PostApi.getL1Comments(
        postId: item.postData!.postView.id,
        blogId: item.postData!.postView.blogId,
      );
      final rawList = response is Map && response['data'] is Map
          ? (response['data'] as Map)['list']
          : null;
      final messages = rawList is List
          ? rawList
              .whereType<Map>()
              .map((raw) {
                try {
                  return HtmlUtil.extractTextFromHtml(
                    Comment.fromJson(Map<String, dynamic>.from(raw)).content,
                  ).trim();
                } catch (_) {
                  return '';
                }
              })
              .where((message) => message.isNotEmpty)
              .take(12)
              .toList()
          : <String>[];
      _danmakuMessages[itemId] = messages;
    } catch (error, stackTrace) {
      ILogger.error('Failed to load video danmaku', error, stackTrace);
      _danmakuMessages[itemId] = const [];
    } finally {
      _loadingDanmaku.remove(itemId);
      if (mounted) setState(() {});
    }
  }

  void _initParams() {
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
      postId = NumberUtil.hexToInt(widget.meta!['postId']!);
      blogId = NumberUtil.hexToInt(widget.meta!['blogId']!);
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

  Future<void> _uploadHistory() async {
    if (_currentPostItem == null) return;
    int userId = await HiveUtil.getUserId();
    final current = _currentPostItem!;
    PostApi.uploadHistory(
      postId: current.itemId,
      blogId: current.blogInfo!.blogId,
      userId: userId,
      postType: current.itemType,
      collectionId: current.postCollection?.grainId,
    ).then((value) {
      if (value['code'] != 200) {
        IToast.showTop(value['msg']);
      }
    });
  }

  Future<List<PostListItem>> _fetchData({bool init = true}) async {
    if (_fetching || !_hasMoreVideo) return const [];
    _fetching = true;
    final generation = _requestGeneration;
    if (init && mounted) {
      setState(() {
        _initialLoading = true;
        _initialLoadError = null;
      });
    }

    try {
      final value = await PostApi.getVideoDetail(
        permalink: permalink,
        offset: offset,
        count: page,
      );
      if (!mounted || generation != _requestGeneration) return const [];
      if (value['code'] != 0) {
        throw StateError(
            value['msg']?.toString() ?? appLocalizations.loadFailed);
      }

      final data = value['data'];
      final rawList = data is Map ? data['list'] : null;
      final parsed = <PostListItem>[];
      if (rawList is List) {
        for (final rawItem in rawList) {
          try {
            final item = PostListItem.fromJson(rawItem);
            final url =
                item.postData?.postView.videoPostView?.videoInfo.originUrl;
            final uri = url == null ? null : Uri.tryParse(url);
            if (uri != null && uri.hasScheme) parsed.add(item);
          } catch (error, stackTrace) {
            ILogger.error('Skipped malformed video item', error, stackTrace);
          }
        }
      }

      page++;
      if (data is Map && data['offset'] is int) offset = data['offset'] as int;
      if (parsed.isEmpty) _hasMoreVideo = false;
      _postItemList.addAll(parsed);

      if (init && parsed.isNotEmpty) {
        _currentPostItem = parsed.first;
        _initPlayer();
        unawaited(_uploadHistory());
        if (_danmakuEnabled) unawaited(_loadDanmaku(parsed.first));
      }
      return parsed;
    } catch (error, stackTrace) {
      ILogger.error('Failed to load video detail', error, stackTrace);
      if (init) _initialLoadError = error;
      if (!init) {
        if (mounted) IToast.showTop(appLocalizations.loadFailed);
        rethrow;
      }
      return const [];
    } finally {
      _fetching = false;
      if (init) _initialLoading = false;
      if (mounted && generation == _requestGeneration) setState(() {});
    }
  }

  void _initPlayer() {
    unawaited(_videoListController.init(
      initialList: _postItemList.map(_buildVideoController).toList(),
      videoProvider: (int index, List<CustomVideoController> list) async {
        final additions = await _fetchData(init: false);
        return additions.map(_buildVideoController).toList();
      },
    ));
  }

  CustomVideoController _buildVideoController(PostListItem item) {
    return CustomVideoController(
      videoInfo: item,
      looping: !_continuousPlayback,
      playbackSpeed: _playbackSpeed,
      builder: () => VideoPlayerController.networkUrl(
        Uri.parse(
          item.postData!.postView.videoPostView!.videoInfo.originUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: ColoredBox(
          color: Colors.black,
          child: _buildInteractiveVideoExperience(),
        ),
      ),
    );
  }

  Widget _buildInteractiveVideoExperience() {
    final content = Stack(
      children: [
        _buildBody(),
        _buildTopWidget(),
      ],
    );
    final item = _currentPostItem;
    if (item?.blogInfo == null) return content;
    return InteractiveAuthorSwipe(
      key: _authorSwipeKey,
      authorId: item!.itemId,
      authorBuilder: (_) => UserDetailScreen(
        blogId: item.blogInfo!.blogId,
        blogName: item.blogInfo!.blogName,
        onBack: () =>
            unawaited(_authorSwipeKey.currentState?.close() ?? Future.value()),
      ),
      onOpen: () {
        if (mounted) setState(() => _authorPaneOpen = true);
        _pauseForInterruption();
      },
      onClose: () {
        if (mounted) setState(() => _authorPaneOpen = false);
        _resumeFromInterruption();
      },
      child: content,
    );
  }

  Widget _buildBody() {
    if (_videoListController.videoCount == 0) {
      if (_initialLoadError != null) return _buildInitialLoadError();
      if (_initialLoading) {
        return const LoadingWidget(
          forceDark: true,
          showText: false,
          bottomPadding: 0,
        );
      }
      return _buildInitialLoadError();
    }

    return PageView.builder(
      physics: const ClampingScrollPhysics(),
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videoListController.videoCount,
      onPageChanged: (index) {
        final player = _videoListController.playerOfIndex(index);
        _currentPostItem = player?.videoInfo;
        unawaited(_uploadHistory());
        unawaited(_videoListController.loadIndex(index));
        if (_danmakuEnabled && _currentPostItem != null) {
          unawaited(_loadDanmaku(_currentPostItem!));
        }
      },
      itemBuilder: (context, index) {
        final player = _videoListController.playerOfIndex(index)!;
        final item = player.videoInfo!;
        return _buildVideoPage(
          item,
          hidePauseIcon: !player.showPauseIcon,
          onSingleTap: () async {
            if (player.loadState == VideoLoadState.failed) {
              await player.retry(
                autoplay: index == _videoListController.index.value,
              );
            } else if (player.isPlaying) {
              await player.pause(showPauseIcon: true);
            } else {
              await player.play();
            }
          },
          video: _buildVideoSurface(player, index),
          progressPlayer: player,
          canResumeAfterScrub: () =>
              mounted &&
              _routeVisible &&
              index == _videoListController.index.value,
        );
      },
    );
  }

  Widget _buildInitialLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ChewieIcon(LoftifyIcons.invalidContent,
                size: 42, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              appLocalizations.loadFailed,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                _hasMoreVideo = true;
                unawaited(_fetchData());
              },
              icon: const ChewieIcon(LoftifyIcons.retry),
              label: Text(appLocalizations.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSurface(CustomVideoController player, int index) {
    final controller = player.controllerOrNull;
    if (player.loadState == VideoLoadState.failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ChewieIcon(LoftifyIcons.videoUnavailable,
                  size: 42, color: Colors.white70),
              const SizedBox(height: 12),
              Text(
                appLocalizations.loadFailed,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => unawaited(player.retry(
                  autoplay: index == _videoListController.index.value,
                )),
                icon: const ChewieIcon(LoftifyIcons.retry),
                label: Text(appLocalizations.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (player.loadState != VideoLoadState.ready || controller == null) {
      return const LoadingWidget(
        forceDark: true,
        showText: false,
        bottomPadding: 0,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio > 0
                ? controller.value.aspectRatio
                : 9 / 16,
            child: VideoPlayer(controller),
          ),
        ),
        if (controller.value.isBuffering)
          const IgnorePointer(
            child: LoadingWidget(
              size: 42,
              forceDark: true,
              showText: false,
              bottomPadding: 0,
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPage(
    PostListItem postListItem, {
    bool hidePauseIcon = false,
    required Widget video,
    Function()? onSingleTap,
    required CustomVideoController progressPlayer,
    required bool Function() canResumeAfterScrub,
  }) {
    final bottomSafeInset =
        _isFullScreen ? 0.0 : MediaQuery.viewPaddingOf(context).bottom;
    Widget videoContainer = Stack(
      children: <Widget>[
        Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.black,
          alignment: Alignment.center,
          child: video,
        ),
        if (!hidePauseIcon)
          Container(
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.center,
            child: ChewieIcon(
              LoftifyIcons.play,
              size: 90,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
    Widget body = Stack(
      children: <Widget>[
        videoContainer,
        if (_danmakuEnabled)
          Positioned.fill(
            child: IgnorePointer(
              child: DanmakuOverlay(
                messages: _danmakuMessages[postListItem.itemId] ?? const [],
                player: progressPlayer,
              ),
            ),
          ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: SizedBox(
              height: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x33000000),
                      Color(0xB3000000),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomSafeInset + 14,
          child: _buildVideoMeta(postListItem),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomSafeInset,
          child: ImmersiveVideoProgressBar(
            player: progressPlayer,
            canResume: canResumeAfterScrub,
            semanticLabel: appLocalizations.video,
          ),
        ),
      ],
    );
    return VideoLongPressGesture(
      player: progressPlayer,
      onTap: onSingleTap,
      onOpenMenu: () => unawaited(_showVideoActions(postListItem)),
      child: body,
    );
  }

  Widget _buildVideoMeta(PostListItem postListItem) {
    final useLandscapeLayout =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    if (useLandscapeLayout) {
      return SafeArea(
        top: false,
        minimum: const EdgeInsets.only(left: 18, right: 18, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: min(MediaQuery.sizeOf(context).width * 0.48, 520),
                  ),
                  child: _buildPostContent(postListItem, landscape: true),
                ),
              ),
            ),
            const SizedBox(width: 20),
            VideoListButtonColumn(
              isLandscape: true,
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
              onLike: () => _handleLike(postListItem),
              onComment: () => _showComments(postListItem),
              onTapAvatar: () => unawaited(_openAuthor(postListItem)),
              onFollow: () => _handleFollow(postListItem),
              onShare: () => _handleShare(postListItem),
              downloadProgress: _downloadProgress[postListItem.itemId],
              onDownload: () => _handleDownload(postListItem),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
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
            onLike: () => _handleLike(postListItem),
            onComment: () => _showComments(postListItem),
            onTapAvatar: () => unawaited(_openAuthor(postListItem)),
            onFollow: () => _handleFollow(postListItem),
            onShare: () => _handleShare(postListItem),
            downloadProgress: _downloadProgress[postListItem.itemId],
            onDownload: () => _handleDownload(postListItem),
          ),
        ],
      ),
    );
  }

  void _handleLike(PostListItem postListItem) {
    HapticFeedback.mediumImpact();
    PostApi.likeOrUnLike(
      isLike: !(postListItem.favorite == true),
      postId: postListItem.itemId,
      blogId: postListItem.blogInfo!.blogId,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return;
      }
      postListItem.favorite = !(postListItem.favorite == true);
      postListItem.postData!.postCount!.favoriteCount +=
          postListItem.favorite == true ? 1 : -1;
      if (mounted) setState(() {});
    });
  }

  void _showComments(PostListItem postListItem) {
    BottomSheetBuilder.showBottomSheet(
      context,
      (context) => CommentBottomSheet(
        postId: postListItem.postData!.postView.id,
        blogId: postListItem.postData!.postView.blogId,
        publishTime: postListItem.postData!.postView.publishTime,
      ),
      enableDrag: false,
      backgroundColor: ChewieTheme.getBackground(context),
    );
  }

  Future<void> _showVideoActions(PostListItem postListItem) async {
    HapticFeedback.mediumImpact();
    final player = _videoListController.currentPlayerOrNull;
    final shouldResume = player?.isPlaying ?? false;
    if (shouldResume) await player?.pause();
    if (!mounted) return;

    await BottomSheetBuilder.showBottomSheet(
      context,
      (sheetContext) => VideoPlaybackActionsSheet(
        continuousPlayback: _continuousPlayback,
        danmakuEnabled: _danmakuEnabled,
        playbackSpeed: _playbackSpeed,
        downloading: _downloadProgress.containsKey(postListItem.itemId),
        onContinuousPlaybackChanged: (enabled) {
          unawaited(_setContinuousPlayback(enabled));
        },
        onDanmakuChanged: (enabled) {
          unawaited(_setDanmakuEnabled(enabled, postListItem));
        },
        onPlaybackSpeedChanged: (speed) {
          unawaited(_setPlaybackSpeed(speed));
        },
        onShare: () {
          Navigator.pop(sheetContext);
          UriUtil.share(
            LoftifyUriUtil.getPostUrlByPermalink(
              postListItem.blogInfo!.blogName,
              postListItem.postData!.postView.permalink,
            ),
          );
        },
        onDownload: () {
          Navigator.pop(sheetContext);
          unawaited(_handleDownload(postListItem));
        },
      ),
      responsive: true,
      backgroundColor: Colors.transparent,
    );

    if (shouldResume &&
        mounted &&
        _routeVisible &&
        identical(player, _videoListController.currentPlayerOrNull)) {
      await player?.play();
    }
  }

  Future<void> _openAuthor(PostListItem postListItem) async {
    if (_authorNavigationPending || !mounted) return;
    _authorNavigationPending = true;
    if (_isFullScreen) await _toggleFullScreen();
    if (!mounted) return;
    RouteUtil.pushPanelCupertinoRoute(
      context,
      UserDetailScreen(
        blogId: postListItem.blogInfo!.blogId,
        blogName: postListItem.blogInfo!.blogName,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _authorNavigationPending = false;
  }

  void _handleFollow(PostListItem postListItem) {
    HapticFeedback.mediumImpact();
    UserApi.followOrUnfollow(
      isFollow: !postListItem.following,
      blogId: postListItem.blogInfo!.blogId,
      blogName: postListItem.blogInfo!.blogName,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return;
      }
      postListItem.following = !postListItem.following;
      if (mounted) setState(() {});
    });
  }

  void _handleShare(PostListItem postListItem) {
    HapticFeedback.mediumImpact();
    PostApi.shareOrUnShare(
      isShare: !(postListItem.share == true),
      postId: postListItem.itemId,
      blogId: postListItem.blogInfo!.blogId,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return;
      }
      postListItem.share = !(postListItem.share == true);
      postListItem.postData!.postCount!.shareCount +=
          postListItem.share == true ? 1 : -1;
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleDownload(PostListItem postListItem) async {
    final itemId = postListItem.itemId;
    if (_downloadProgress.containsKey(itemId)) return;
    if (mounted) setState(() => _downloadProgress[itemId] = 0);
    try {
      await LoftifyFileUtil.saveVideoByIllust(
        context,
        getIllust(postListItem),
        onReceiveProgress: (count, total) {
          if (!mounted || total <= 0) return;
          setState(() {
            _downloadProgress[itemId] = (count / total).clamp(0, 1);
          });
        },
      );
    } catch (error, stackTrace) {
      ILogger.error('Failed to download video', error, stackTrace);
      if (mounted) IToast.showTop(appLocalizations.downloadFailed);
    } finally {
      if (mounted) setState(() => _downloadProgress.remove(itemId));
    }
  }

  Illust getIllust(PostListItem postListItem) {
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

  bool _hasContent(PostListItem postListItem) {
    String title = StringUtil.clearBlank(postListItem.postData!.postView.title);
    String content = StringUtil.clearBlank(
        HtmlUtil.extractTextFromHtml(postListItem.postData!.postView.digest));
    return (title.isNotEmpty || content.isNotEmpty);
  }

  Widget _buildPostContent(
    PostListItem postListItem, {
    bool landscape = false,
  }) {
    String title = StringUtil.clearBlank(postListItem.postData!.postView.title);
    String digest = StringUtil.limitString(
        HtmlUtil.extractTextFromHtml(postListItem.postData!.postView.digest));
    final html = [
      if (title.isNotEmpty) '<p><strong>$title</strong></p>',
      if (digest.isNotEmpty) digest,
    ].join();
    return _hasContent(postListItem)
        ? Container(
            padding: landscape
                ? const EdgeInsets.only(left: 6, bottom: 4)
                : const EdgeInsets.only(
                    left: 16,
                    top: 16,
                    bottom: 16,
                  ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (html.isNotEmpty)
                  HtmlWidget(
                    html,
                    textStyle: Theme.of(context).textTheme.titleSmall?.apply(
                          fontSizeDelta: 1,
                          color: Colors.grey[300],
                        ),
                    customStylesBuilder: (e) {
                      if (e.attributes.containsKey('href')) {
                        final color = Theme.of(context).primaryColor;
                        return {
                          'color':
                              '#${color.toARGB32().toRadixString(16).substring(2, 8)}'
                        };
                      }
                      return null;
                    },
                    onTapUrl: (url) async {
                      UriUtil.processUrl(context, url);
                      return true;
                    },
                  ),
                if (html.isNotEmpty) const SizedBox(height: 8),
                if (postListItem.postData!.postView.tagList.isNotEmpty)
                  _buildTagList(postListItem),
              ],
            ),
          )
        : emptyWidget;
  }

  Widget _buildTagList(PostListItem postListItem) {
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
            ChewieIconButton(
              icon: LoftifyIcons.back,
              foregroundColor: Colors.white,
              onPressed: _handleBack,
            ),
            const Spacer(),
            ChewieIconButton(
              icon: (_videoListController.currentPlayerOrNull?.isMuted ?? false)
                  ? LoftifyIcons.mute
                  : LoftifyIcons.sound,
              foregroundColor: Colors.white,
              onPressed: () {
                unawaited(
                  _videoListController.currentPlayerOrNull?.toggleMute() ??
                      Future<void>.value(),
                );
              },
            ),
            ChewieIconButton(
              icon: _isFullScreen
                  ? LoftifyIcons.exitFullscreen
                  : LoftifyIcons.enterFullscreen,
              foregroundColor: Colors.white,
              onPressed: () => unawaited(_toggleFullScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFullScreen() async {
    if (!ResponsiveUtil.isMobile()) return;
    if (!_isFullScreen) {
      _sizeBeforeFullscreen = MediaQuery.sizeOf(context);
      if (mounted) setState(() => _isFullScreen = true);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return;
    }

    if (mounted) setState(() => _isFullScreen = false);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await ResponsiveUtil.restoreOrientationPolicy(
      logicalSize: _sizeBeforeFullscreen,
    );
  }

  void _handleBack() {
    final authorSwipe = _authorSwipeKey.currentState;
    if (_authorPaneOpen || (authorSwipe?.isAuthorVisible ?? false)) {
      unawaited(authorSwipe?.close() ?? Future<void>.value());
      return;
    }
    if (_isFullScreen) {
      unawaited(_toggleFullScreen());
      return;
    }
    Navigator.of(context).pop();
  }
}

class InteractiveAuthorSwipe extends StatefulWidget {
  const InteractiveAuthorSwipe({
    super.key,
    required this.authorId,
    required this.child,
    required this.authorBuilder,
    this.onOpen,
    this.onClose,
  });

  final Object authorId;
  final Widget child;
  final WidgetBuilder authorBuilder;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  State<InteractiveAuthorSwipe> createState() => InteractiveAuthorSwipeState();
}

class InteractiveAuthorSwipeState extends State<InteractiveAuthorSwipe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final GlobalKey<NavigatorState> _authorNavigatorKey =
      GlobalKey<NavigatorState>();
  bool _authorBuilt = false;
  bool _open = false;
  bool _closing = false;
  bool _removingHistoryEntry = false;
  LocalHistoryEntry? _historyEntry;
  double _width = 1;

  bool get isAuthorVisible =>
      _authorBuilt &&
      (_open || _controller.isAnimating || _controller.value > 0.001);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant InteractiveAuthorSwipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authorId == widget.authorId) return;
    _controller.stop();
    _removeHistoryEntry();
    _controller.value = 0;
    _authorBuilt = false;
    _open = false;
    _closing = false;
  }

  @override
  void dispose() {
    _closing = true;
    _removeHistoryEntry();
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _controller.stop();
    _ensureHistoryEntry();
    if (!_authorBuilt) setState(() => _authorBuilt = true);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _controller.value =
        (_controller.value - details.delta.dx / _width).clamp(0, 1);
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final settleThreshold = _open ? 0.76 : 0.24;
    final shouldOpen = velocity <= -600 ||
        (velocity < 600 && _controller.value >= settleThreshold);
    if (shouldOpen) {
      _animateOpen();
    } else {
      _animateClosed();
    }
  }

  void _handleDragCancel() {
    if (_open) {
      _animateOpen();
    } else {
      _animateClosed();
    }
  }

  Future<void> _animateOpen() async {
    _ensureHistoryEntry();
    if (!_authorBuilt && mounted) setState(() => _authorBuilt = true);
    if (!_open) {
      setState(() => _open = true);
      widget.onOpen?.call();
    }
    await _controller.animateTo(1, curve: Curves.easeOutCubic);
  }

  Future<void> _animateClosed({bool removeHistoryEntry = true}) async {
    if (_closing) return;
    _closing = true;
    if (removeHistoryEntry) _removeHistoryEntry();
    final wasOpen = _open;
    try {
      await _controller.animateTo(0, curve: Curves.easeOutCubic);
      if (!mounted) return;
      if (wasOpen) widget.onClose?.call();
      setState(() => _open = false);
    } finally {
      _closing = false;
    }
  }

  Future<void> close() => _animateClosed();

  void _ensureHistoryEntry() {
    if (_historyEntry != null) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    late final LocalHistoryEntry entry;
    entry = LocalHistoryEntry(
      onRemove: () {
        if (identical(_historyEntry, entry)) _historyEntry = null;
        if (_removingHistoryEntry || !mounted) return;
        unawaited(_animateClosed(removeHistoryEntry: false));
      },
    );
    _historyEntry = entry;
    route.addLocalHistoryEntry(entry);
  }

  void _removeHistoryEntry() {
    final entry = _historyEntry;
    if (entry == null) return;
    _historyEntry = null;
    _removingHistoryEntry = true;
    entry.remove();
    _removingHistoryEntry = false;
  }

  Widget _buildAuthorNavigator() {
    return Navigator(
      key: _authorNavigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_animateClosed());
          },
          child: widget.authorBuilder(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _open) unawaited(_animateClosed());
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _width = max(1, constraints.maxWidth);
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: _handleDragCancel,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = _controller.value;
                return ClipRect(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Transform.translate(
                          key: const ValueKey('interactive-video-pane'),
                          offset: Offset(-_width * 0.16 * progress, 0),
                          child: widget.child,
                        ),
                      ),
                      if (progress > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(
                              color: Colors.black.withValues(
                                alpha: 0.2 * progress,
                              ),
                            ),
                          ),
                        ),
                      if (_authorBuilt)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: progress < 0.999,
                            child: Transform.translate(
                              key: const ValueKey('interactive-author-pane'),
                              offset: Offset(_width * (1 - progress), 0),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 18,
                                      offset: Offset(-5, 0),
                                    ),
                                  ],
                                ),
                                child: _buildAuthorNavigator(),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class VideoLongPressGesture extends StatefulWidget {
  const VideoLongPressGesture({
    super.key,
    required this.player,
    required this.child,
    required this.onOpenMenu,
    this.onTap,
    this.edgeFraction = 0.16,
    this.minimumEdgeWidth = 52,
    this.maximumEdgeWidth = 92,
    this.temporarySpeed = 2,
  });

  final CustomVideoController player;
  final Widget child;
  final VoidCallback onOpenMenu;
  final VoidCallback? onTap;
  final double edgeFraction;
  final double minimumEdgeWidth;
  final double maximumEdgeWidth;
  final double temporarySpeed;

  @override
  State<VideoLongPressGesture> createState() => _VideoLongPressGestureState();
}

class _VideoLongPressGestureState extends State<VideoLongPressGesture> {
  bool _speeding = false;
  bool _leftEdge = false;
  double _restoreSpeed = 1;

  @override
  void didUpdateWidget(covariant VideoLongPressGesture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.player, widget.player) && _speeding) {
      unawaited(oldWidget.player.setPlaybackSpeed(_restoreSpeed));
      _speeding = false;
    }
  }

  @override
  void dispose() {
    if (_speeding) {
      unawaited(widget.player.setPlaybackSpeed(_restoreSpeed));
    }
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details, double width) {
    final edgeWidth = (width * widget.edgeFraction)
        .clamp(widget.minimumEdgeWidth, widget.maximumEdgeWidth)
        .toDouble();
    final onLeft = details.localPosition.dx <= edgeWidth;
    final onRight = details.localPosition.dx >= width - edgeWidth;
    if (!onLeft && !onRight) {
      widget.onOpenMenu();
      return;
    }
    if (!widget.player.prepared || _speeding) return;
    _restoreSpeed = widget.player.playbackSpeed;
    _leftEdge = onLeft;
    HapticFeedback.selectionClick();
    setState(() => _speeding = true);
    unawaited(widget.player.setPlaybackSpeed(widget.temporarySpeed));
  }

  void _stopTemporarySpeed() {
    if (!_speeding) return;
    final restoreSpeed = _restoreSpeed;
    setState(() => _speeding = false);
    unawaited(widget.player.setPlaybackSpeed(restoreSpeed));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPressStart: (details) =>
            _handleLongPressStart(details, constraints.maxWidth),
        onLongPressEnd: (_) => _stopTemporarySpeed(),
        onLongPressCancel: _stopTemporarySpeed,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (_speeding)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 68,
                left: _leftEdge ? 20 : null,
                right: _leftEdge ? null : 20,
                child: IgnorePointer(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      '${widget.temporarySpeed.toStringAsFixed(0)}x',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DanmakuOverlay extends StatefulWidget {
  const DanmakuOverlay({
    super.key,
    required this.messages,
    required this.player,
  });

  final List<String> messages;
  final CustomVideoController player;

  @override
  State<DanmakuOverlay> createState() => _DanmakuOverlayState();
}

class _DanmakuOverlayState extends State<DanmakuOverlay>
    with SingleTickerProviderStateMixin {
  static const double _slotSeconds = 4;
  static const double _travelSeconds = 8;
  static const List<double> _lanePhaseFractions = [
    0,
    0.42,
    0.76,
    0.2,
    0.58,
  ];
  static const List<double> _laneVerticalJitter = [0, 6, -3, 5, -5];
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    widget.player.revision.addListener(_syncPlayback);
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant DanmakuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.player, widget.player)) {
      oldWidget.player.revision.removeListener(_syncPlayback);
      widget.player.revision.addListener(_syncPlayback);
    }
    _syncPlayback();
  }

  @override
  void dispose() {
    widget.player.revision.removeListener(_syncPlayback);
    _controller.dispose();
    super.dispose();
  }

  void _syncPlayback() {
    final shouldAnimate = widget.messages.isNotEmpty && widget.player.isPlaying;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop(canceled: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final laneCount = width > 700 ? 5 : 4;
          final itemsPerLane =
              max(1, (widget.messages.length / laneCount).ceil());
          final cycleSeconds = (itemsPerLane + 1) * _slotSeconds +
              _lanePhaseFractions.take(laneCount).reduce(
                      (current, next) => current > next ? current : next) *
                  _slotSeconds;
          final cycleDuration = Duration(
            milliseconds: (cycleSeconds * 1000).round(),
          );
          if (_controller.duration != cycleDuration) {
            _controller.duration = cycleDuration;
          }
          final maxMessageWidth = min(width * 0.72, 560.0);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final elapsed = _controller.value * cycleSeconds;
              return Stack(
                children: [
                  for (var index = 0; index < widget.messages.length; index++)
                    if (_localDanmakuTimeForIndex(
                          elapsed,
                          index,
                          laneCount,
                          cycleSeconds,
                        ) <
                        _travelSeconds)
                      Positioned(
                        top: 82 +
                            (index % laneCount) * 38 +
                            _laneVerticalJitter[index % laneCount],
                        left: width -
                            (width + maxMessageWidth) *
                                (_localDanmakuTimeForIndex(
                                      elapsed,
                                      index,
                                      laneCount,
                                      cycleSeconds,
                                    ) /
                                    _travelSeconds),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxMessageWidth,
                          ),
                          child: Text(
                            widget.messages[index],
                            key: ValueKey('danmaku-$index'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 3),
                                Shadow(
                                    color: Colors.black54,
                                    offset: Offset(1, 1)),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  double _localDanmakuTime(
    double elapsed,
    int sequence,
    int lane,
    double cycleSeconds,
  ) {
    final lanePhase = _lanePhaseFractions[lane] * _slotSeconds;
    return (elapsed - sequence * _slotSeconds - lanePhase + cycleSeconds) %
        cycleSeconds;
  }

  double _localDanmakuTimeForIndex(
    double elapsed,
    int index,
    int laneCount,
    double cycleSeconds,
  ) =>
      _localDanmakuTime(
        elapsed,
        index ~/ laneCount,
        index % laneCount,
        cycleSeconds,
      );
}

class ImmersiveVideoProgressBar extends StatefulWidget {
  const ImmersiveVideoProgressBar({
    super.key,
    required this.player,
    required this.canResume,
    required this.semanticLabel,
  });

  final CustomVideoController player;
  final bool Function() canResume;
  final String semanticLabel;

  @override
  State<ImmersiveVideoProgressBar> createState() =>
      _ImmersiveVideoProgressBarState();
}

class _ImmersiveVideoProgressBarState extends State<ImmersiveVideoProgressBar> {
  Timer? _seekThrottle;
  Future<void> _seekChain = Future<void>.value();
  Duration? _pendingPosition;
  double? _dragFraction;
  bool _dragging = false;
  bool _wasPlaying = false;
  int _seekTicket = 0;

  @override
  void initState() {
    super.initState();
    widget.player.revision.addListener(_handlePlayerChanged);
  }

  @override
  void didUpdateWidget(covariant ImmersiveVideoProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.player, widget.player)) {
      oldWidget.player.revision.removeListener(_handlePlayerChanged);
      widget.player.revision.addListener(_handlePlayerChanged);
      _cancelScrub();
    }
  }

  @override
  void dispose() {
    widget.player.revision.removeListener(_handlePlayerChanged);
    _seekThrottle?.cancel();
    super.dispose();
  }

  void _handlePlayerChanged() {
    if (mounted) setState(() {});
  }

  void _cancelScrub() {
    _seekThrottle?.cancel();
    _seekThrottle = null;
    _pendingPosition = null;
    _dragFraction = null;
    _dragging = false;
    _seekTicket++;
  }

  void _beginScrub(LongPressStartDetails details, double width) {
    final controller = widget.player.controllerOrNull;
    if (controller == null || !controller.value.isInitialized) return;
    _wasPlaying = widget.player.isPlaying;
    HapticFeedback.selectionClick();
    setState(() => _dragging = true);
    if (_wasPlaying) unawaited(widget.player.pause());
    _updateScrub(details.localPosition.dx, width);
  }

  void _updateScrub(double dx, double width) {
    final controller = widget.player.controllerOrNull;
    if (!_dragging || controller == null || width <= 0) return;
    final fraction = (dx / width).clamp(0.0, 1.0);
    final duration = controller.value.duration;
    setState(() => _dragFraction = fraction);
    _scheduleSeek(Duration(
      milliseconds: (duration.inMilliseconds * fraction).round(),
    ));
  }

  void _scheduleSeek(Duration position) {
    _pendingPosition = position;
    if (_seekThrottle != null) return;
    _commitPendingSeek();
    _seekThrottle = Timer(const Duration(milliseconds: 45), () {
      _seekThrottle = null;
      final pending = _pendingPosition;
      if (pending != null) _scheduleSeek(pending);
    });
  }

  void _commitPendingSeek() {
    final position = _pendingPosition;
    final controller = widget.player.controllerOrNull;
    if (position == null || controller == null) return;
    _pendingPosition = null;
    final ticket = ++_seekTicket;
    _seekChain = _seekChain.then((_) async {
      if (!mounted || ticket != _seekTicket) return;
      if (!identical(widget.player.controllerOrNull, controller)) return;
      try {
        await controller.seekTo(position);
      } catch (error) {
        debugPrint('Failed to seek video: $error');
      }
    });
  }

  Future<void> _finishScrub() async {
    if (!_dragging) return;
    final controller = widget.player.controllerOrNull;
    final fraction = _dragFraction;
    _seekThrottle?.cancel();
    _seekThrottle = null;
    _pendingPosition = null;
    final ticket = ++_seekTicket;
    if (controller != null && fraction != null) {
      final position = Duration(
        milliseconds:
            (controller.value.duration.inMilliseconds * fraction).round(),
      );
      _seekChain = _seekChain.then((_) async {
        if (!mounted || ticket != _seekTicket) return;
        if (!identical(widget.player.controllerOrNull, controller)) return;
        try {
          await controller.seekTo(position);
        } catch (error) {
          debugPrint('Failed to finish video seek: $error');
        }
      });
      await _seekChain;
    }
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _dragFraction = null;
    });
    if (_wasPlaying && widget.canResume()) await widget.player.play();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = max(0, duration.inSeconds);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.player.controllerOrNull;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(height: 30);
    }
    final value = controller.value;
    final durationMs = max(1, value.duration.inMilliseconds);
    final playedFraction = _dragFraction ??
        (value.position.inMilliseconds / durationMs).clamp(0.0, 1.0);
    final bufferedFraction = value.buffered.isEmpty
        ? 0.0
        : (value.buffered.last.end.inMilliseconds / durationMs).clamp(0.0, 1.0);
    final shownPosition = Duration(
      milliseconds: (durationMs * playedFraction).round(),
    );

    return Semantics(
      label: widget.semanticLabel,
      value:
          '${_formatDuration(shownPosition)} / ${_formatDuration(value.duration)}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bubbleLeft = (width * playedFraction - 38)
              .clamp(8.0, max(8.0, width - 84))
              .toDouble();
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            onLongPressStart: (details) => _beginScrub(details, width),
            onLongPressMoveUpdate: (details) {
              _updateScrub(details.localPosition.dx, width);
            },
            onLongPressEnd: (_) => unawaited(_finishScrub()),
            onLongPressCancel: () => unawaited(_finishScrub()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              height: _dragging ? 58 : 30,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (_dragging)
                    Positioned(
                      left: bubbleLeft,
                      bottom: 19,
                      child: Container(
                        width: 76,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.76),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_formatDuration(shownPosition)} / ${_formatDuration(value.duration)}',
                          maxLines: 1,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _dragging ? 7 : 3,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(color: Colors.white24),
                        ),
                        Positioned.fill(
                          child: FractionallySizedBox(
                            widthFactor: bufferedFraction,
                            alignment: Alignment.centerLeft,
                            child: const ColoredBox(color: Colors.white38),
                          ),
                        ),
                        Positioned.fill(
                          child: FractionallySizedBox(
                            widthFactor: playedFraction,
                            alignment: Alignment.centerLeft,
                            child: const ColoredBox(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_dragging)
                    Positioned(
                      left: (width * playedFraction - 7)
                          .clamp(0.0, max(0.0, width - 14)),
                      bottom: -3.5,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black54, width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 5),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class VideoPlaybackActionsSheet extends StatefulWidget {
  const VideoPlaybackActionsSheet({
    super.key,
    required this.continuousPlayback,
    required this.danmakuEnabled,
    required this.playbackSpeed,
    required this.downloading,
    required this.onContinuousPlaybackChanged,
    required this.onDanmakuChanged,
    required this.onPlaybackSpeedChanged,
    required this.onShare,
    required this.onDownload,
  });

  final bool continuousPlayback;
  final bool danmakuEnabled;
  final double playbackSpeed;
  final bool downloading;
  final ValueChanged<bool> onContinuousPlaybackChanged;
  final ValueChanged<bool> onDanmakuChanged;
  final ValueChanged<double> onPlaybackSpeedChanged;
  final VoidCallback onShare;
  final VoidCallback onDownload;

  @override
  State<VideoPlaybackActionsSheet> createState() =>
      _VideoPlaybackActionsSheetState();
}

class _VideoPlaybackActionsSheetState extends State<VideoPlaybackActionsSheet> {
  static const _speeds = <double>[0.5, 0.75, 1, 1.25, 1.5, 2];
  late bool _continuousPlayback;
  late bool _danmakuEnabled;
  late double _playbackSpeed;

  @override
  void initState() {
    super.initState();
    _continuousPlayback = widget.continuousPlayback;
    _danmakuEnabled = widget.danmakuEnabled;
    _playbackSpeed = widget.playbackSpeed;
  }

  String _speedLabel(double speed) {
    return speed == speed.roundToDouble() ? '${speed.toInt()}x' : '${speed}x';
  }

  @override
  Widget build(BuildContext context) {
    final radius = ChewieDimens.defaultRadius;
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: radius,
              bottom: ResponsiveUtil.isWideDevice() ? radius : Radius.zero,
            ),
            color: ChewieTheme.scaffoldBackgroundColor,
            border: ChewieTheme.responsiveBorder,
            boxShadow: ChewieTheme.defaultBoxShadow,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: ChewieTheme.dividerColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  _buildHeader(),
                  const SizedBox(height: 6),
                  _buildActionGrid(),
                  CaptionItem(
                    title: appLocalizations.playbackSpeed,
                    initiallyExpanded: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final speed in _speeds)
                              _VideoSpeedChip(
                                label: _speedLabel(speed),
                                selected: _playbackSpeed == speed,
                                onTap: () {
                                  setState(() => _playbackSpeed = speed);
                                  widget.onPlaybackSpeedChanged(speed);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ChewieTheme.primaryColor.withAlpha(30),
              borderRadius: BorderRadius.circular(9),
            ),
            child: ChewieIcon(
              LoftifyIcons.videoSettings,
              color: ChewieTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              appLocalizations.videoPlaybackOptions,
              style: ChewieTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: ChewieTheme.primaryColor.withAlpha(24),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _speedLabel(_playbackSpeed),
              style: ChewieTheme.labelMedium.copyWith(
                color: ChewieTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      _VideoActionTile(
        icon: LoftifyIcons.continuousPlayback,
        label: appLocalizations.continuousPlayback,
        selected: _continuousPlayback,
        onTap: () {
          setState(() => _continuousPlayback = !_continuousPlayback);
          widget.onContinuousPlaybackChanged(_continuousPlayback);
        },
      ),
      _VideoActionTile(
        icon: LoftifyIcons.share,
        label: appLocalizations.share,
        onTap: widget.onShare,
      ),
      _VideoActionTile(
        icon: LoftifyIcons.danmaku,
        label: appLocalizations.danmaku,
        selected: _danmakuEnabled,
        onTap: () {
          setState(() => _danmakuEnabled = !_danmakuEnabled);
          widget.onDanmakuChanged(_danmakuEnabled);
        },
      ),
      _VideoActionTile(
        icon: LoftifyIcons.download,
        iconWidget: widget.downloading
            ? SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(
                  color: ChewieTheme.primaryColor,
                  strokeWidth: 2,
                ),
              )
            : null,
        label: widget.downloading
            ? appLocalizations.downloading
            : appLocalizations.download,
        onTap: widget.downloading ? null : widget.onDownload,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 54,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (_, index) => actions[index],
        );
      },
    );
  }
}

class _VideoActionTile extends StatelessWidget {
  const _VideoActionTile({
    required this.icon,
    required this.label,
    this.iconWidget,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final Widget? iconWidget;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? ChewieTheme.primaryColor : ChewieTheme.bodyMedium.color;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressableAnimation(
        child: Material(
          color: selected
              ? ChewieTheme.primaryColor.withAlpha(22)
              : ChewieTheme.canvasColor,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: ChewieTheme.primaryColor.withAlpha(
                        selected ? 42 : 24,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: iconWidget ??
                          ChewieIcon(icon, color: foreground, size: 17),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ChewieTheme.bodyMedium.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (selected)
                    ChewieIcon(
                      LoftifyIcons.check,
                      size: 16,
                      color: ChewieTheme.primaryColor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoSpeedChip extends StatelessWidget {
  const _VideoSpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: PressableAnimation(
        child: Material(
          color: selected
              ? ChewieTheme.primaryColor.withAlpha(28)
              : ChewieTheme.cardColor,
          borderRadius: BorderRadius.circular(99),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    ChewieIcon(
                      LoftifyIcons.check,
                      size: 15,
                      color: ChewieTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: ChewieTheme.bodyMedium.copyWith(
                      color: selected
                          ? ChewieTheme.primaryColor
                          : ChewieTheme.bodyMedium.color,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
  final bool isLandscape;

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
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isLandscape ? 28.0 : 35.0;
    final actions = <Widget>[
      _IconButton(
        compact: isLandscape,
        icon: ChewieIcon(
          LoftifyIcons.favorite,
          size: iconSize,
          color: isLiked ? ChewieColors.likeButtonColor : Colors.white,
        ),
        text: _formatVideoCount(likeCount),
        onTap: onLike,
      ),
      _IconButton(
        compact: isLandscape,
        icon: ChewieIcon(
          LoftifyIcons.recommend,
          size: iconSize,
          color: isShared ? ChewieColors.shareButtonColor : Colors.white,
        ),
        text: _formatVideoCount(shareCount),
        onTap: onShare,
      ),
      _IconButton(
        compact: isLandscape,
        icon: ChewieIcon(
          LoftifyIcons.comment,
          size: iconSize,
          color: Colors.white,
        ),
        text: _formatVideoCount(commentCount),
        onTap: onComment,
      ),
      if (showDownloadButton)
        downloadProgress != null
            ? _IconButton(
                compact: isLandscape,
                icon: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator(
                    value: downloadProgress!.clamp(0.0, 1.0).toDouble(),
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                    strokeWidth: isLandscape ? 2 : 2.5,
                  ),
                ),
                text: '${(downloadProgress! * 100).toStringAsFixed(0)}%',
                onTap: onDownload,
              )
            : _IconButton(
                compact: isLandscape,
                icon: ChewieIcon(
                  LoftifyIcons.download,
                  size: iconSize,
                  color: Colors.white,
                ),
                text: appLocalizations.download,
                onTap: onDownload,
              ),
    ];

    if (isLandscape) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(context, compact: true),
            const SizedBox(width: 7),
            for (final action in actions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: action,
              ),
          ],
        ),
      );
    }

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
          _buildAvatar(context),
          const SizedBox(height: 10),
          ...actions,
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static String _formatVideoCount(int count) {
    if (count < 10000) return '$count';
    if (count < 1000000) {
      final truncated = (count / 1000).floor() / 10;
      return '${truncated.toStringAsFixed(1)}w';
    }
    if (count < 100000000) return '${(count / 10000).floor()}w';
    final truncated = (count / 10000000).floor() / 10;
    return '${truncated.toStringAsFixed(1)}y';
  }

  Widget _buildAvatar(BuildContext context, {bool compact = false}) {
    final avatarSize = compact ? 34.0 : 40.0;
    return GestureDetector(
      onTap: onTapAvatar,
      child: Stack(
        children: [
          SizedBox(
            width: compact ? 39 : 45,
            height: compact ? 39 : 45,
          ),
          ItemBuilder.buildAvatar(
            context: context,
            imageUrl: blogInfo.bigAvaImg,
            showLoading: false,
            size: avatarSize,
            showBorder: false,
          ),
          if (!isFollowing)
            Positioned(
              bottom: 0,
              left: 0,
              right: compact ? 5 : 0,
              child: Center(
                child: ClickableWrapper(
                  child: GestureDetector(
                    onTap: onFollow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withAlpha(127),
                          width: 0.5,
                        ),
                      ),
                      child: ChewieIcon(
                        LoftifyIcons.add,
                        size: compact ? 10 : 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final Widget? icon;
  final String? text;
  final Function? onTap;
  final bool compact;

  const _IconButton({
    this.icon,
    this.text,
    this.onTap,
    this.compact = false,
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
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 40 : 46),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text ?? '??',
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ),
        ),
      ],
    );
    return ClickableWrapper(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 2 : 0,
          vertical: compact ? 4 : 10,
        ),
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
