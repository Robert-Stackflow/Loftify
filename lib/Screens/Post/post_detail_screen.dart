import 'dart:async';
import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/post_api.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/grain_response.dart';
import 'package:loftify/Models/illust.dart';
import 'package:loftify/Models/message_response.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/show_case_response.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Widgets/BottomSheet/collection_bottom_sheet.dart';
import 'package:loftify/Widgets/BottomSheet/comment_bottom_sheet.dart';
import 'package:loftify/Widgets/BottomSheet/subscribe_post_bottom_sheet.dart';
import 'package:loftify/Widgets/PostItem/general_post_item.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:window_manager/window_manager.dart';

import '../../Api/collection_api.dart';
import '../../Api/recommend_api.dart';
import '../../Models/return_gift_response.dart';
import '../../Models/search_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/cloud_control_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/lottie_files.dart';
import '../../Utils/loftify_file_util.dart';
import '../../Utils/post_sequence_source.dart';
import '../../Utils/post_swipe_gesture.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';
import '../../Widgets/PostDetail/detail_bottom_bar.dart';
import '../../Widgets/PostDetail/post_content_section.dart';
import '../../Widgets/PostDetail/post_swipe_gesture_detector.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import '../Info/user_detail_screen.dart';
import 'grain_detail_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    this.postItem,
    this.postDetailData,
    this.meta,
    this.favoritePostDetailData,
    this.showCaseItem,
    this.searchPost,
    this.grainPostItem,
    this.generalPostItem,
    this.sequenceSource,
    required this.isArticle,
    this.simpleMessagePost,
  });

  final bool isArticle;
  final SearchPost? searchPost;
  final ShowCaseItem? showCaseItem;
  final PostListItem? postItem;
  final GrainPostItem? grainPostItem;
  final PostDetailData? postDetailData;
  final FavoritePostDetailData? favoritePostDetailData;
  final Map<String, String>? meta;
  final SimpleMessagePost? simpleMessagePost;
  final GeneralPostItem? generalPostItem;
  final PostSequenceSource? sequenceSource;
  static const String routeName = "/post/detail";

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends BaseDynamicState<PostDetailScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WindowListener {
  @override
  bool get wantKeepAlive => true;
  static const int LIANGPIAO_GIFTID = 3001;
  PostDetailData? _postDetailData;
  List<PreviewImage> _previewImages = [];
  bool _isCatutu = false;
  String _giftTypeString = "";
  String _giftPreviewDescription = "";
  String _giftCost = "";
  int _giftCostId = LIANGPIAO_GIFTID;
  GiftInfoData? _giftInfoData;
  final SwiperController _swiperController = SwiperController();
  int _currentIndex = 1;
  final List<PostListItem> _recommendPosts = [];
  int _currentPage = 0;
  int _myBlogId = 0;
  bool _loadingInfo = false;
  bool _loadingRecommend = false;
  int _recommendRequestToken = 0;
  bool _recommendNoMore = false;
  int blogId = 0;
  int postId = 0;
  int collectionId = 0;
  String blogName = "";
  late ScrollController _scrollController;
  final ScrollController _tabletScrollController = ScrollController();
  late AnimationController _doubleTapLikeController;
  double doubleTapLikeSize = 400;
  late TapDownDetails _doubleTapDetails;
  double doubleTapDx = -1000;
  double doubleTapDy = -1000;
  bool _showDoubleTapLike = true;
  Widget? doubleTapLikeWidget;
  List<Color> mainColors = [];
  late AnimationController _shareController;
  late AnimationController _likeController;
  int totalHotOrNewComments = 0;
  List<Comment> hotComments = [];
  List<Comment> newComments = [];
  GlobalKey commentKey = GlobalKey();
  final GlobalKey _collectionViewportKey = GlobalKey();
  final GlobalKey _grainViewportKey = GlobalKey();
  final GlobalKey _tagViewportKey = GlobalKey();
  final GlobalKey _operationViewportKey = GlobalKey();
  final GlobalKey _commentListViewportKey = GlobalKey();
  final GlobalKey _commentEndViewportKey = GlobalKey();
  final GlobalKey _imageSwiperViewportKey = GlobalKey();
  final ResizableController _resizableController = ResizableController();
  late dynamic downloadIcon;
  DownloadState downloadState = DownloadState.none;
  bool isArticle = false;
  InitPhase _inited = InitPhase.haveNotConnected;
  final ValueNotifier<bool> _floatingOperationBarVisible = ValueNotifier(true);
  bool _scrollAllowsFloatingOperationBar = true;
  late final AnimationController _postSwipeAnimationController;
  Animation<double>? _postSwipeAnimation;
  final Map<bool, Future<PostDetailData?>> _adjacentPostLoads = {};
  double _postSwipeOffset = 0;
  double _postSwipeRawOffset = 0;
  bool? _postSwipePrevious;
  bool _postSwipeReady = false;
  bool _postSwipeAtBoundary = false;
  bool _postSwipeBoundaryReady = false;
  bool _switchingPost = false;

  bool get _isPostContentReady =>
      !_switchingPost &&
      _inited == InitPhase.successful &&
      _postDetailData?.post != null;

  @override
  void initState() {
    isArticle = widget.isArticle;
    _scrollController = ScrollController();
    windowManager.addListener(this);
    super.initState();
    _postSwipeAnimationController = AnimationController(vsync: this)
      ..addListener(() {
        final animation = _postSwipeAnimation;
        if (animation != null && mounted) {
          setState(() => _postSwipeOffset = animation.value);
        }
      });
    initLottie();
    setDownloadState(DownloadState.none, recover: false);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (ResponsiveUtil.isDesktop()) {
        appProvider.windowSize = await windowManager.getSize();
      }
      if (isArticle) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) initData();
        });
      } else {
        initData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabletScrollController.dispose();
    _doubleTapLikeController.dispose();
    _shareController.dispose();
    _likeController.dispose();
    _postSwipeAnimationController.dispose();
    _floatingOperationBarVisible.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  initLottie() {
    _doubleTapLikeController =
        AnimationController(duration: const Duration(seconds: 3), vsync: this);
    doubleTapLikeWidget = LottieFiles.buildAnimation(
      LottieFiles.likeDoubleClickLight,
      size: doubleTapLikeSize,
      controller: _doubleTapLikeController,
    );
    _shareController =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _likeController = AnimationController(
        duration: const Duration(milliseconds: 2500), vsync: this);
  }

  initData() async {
    _inited = InitPhase.connecting;
    if (mounted) setState(() {});
    _initParams();
    if (_inited == InitPhase.failed) {
      if (mounted) setState(() {});
      return;
    }
    final detailFuture = Future<dynamic>.sync(_fetchPostDetail);
    final recommendFuture = Future<dynamic>.sync(_fetchRecommendPosts);
    await Future.wait<dynamic>([detailFuture, recommendFuture]);
    _myBlogId = await HiveUtil.getUserId();
    if (mounted) setState(() {});
  }

  _initParams() {
    try {
      if (widget.postItem != null) {
        postId = widget.postItem!.postData!.postView.id;
        blogId = widget.postItem!.blogInfo!.blogId;
        blogName = widget.postItem!.blogInfo!.blogName;
      } else if (widget.showCaseItem != null) {
        postId = widget.showCaseItem!.itemId;
        blogId = widget.showCaseItem!.postSimpleData!.postView.blogId;
        blogName = widget.showCaseItem!.postSimpleData!.postView.blogName;
      } else if (widget.postDetailData != null) {
        postId = widget.postDetailData!.post!.id;
        blogId = widget.postDetailData!.post!.blogId;
        blogName = widget.postDetailData!.post!.blogInfo!.blogName;
      } else if (widget.simpleMessagePost != null) {
        postId = widget.simpleMessagePost!.postId;
        blogId = widget.simpleMessagePost!.blogId;
        blogName = widget.simpleMessagePost!.blogName;
      } else if (widget.favoritePostDetailData != null) {
        postId = widget.favoritePostDetailData!.post!.id;
        blogId = widget.favoritePostDetailData!.post!.blogId;
        blogName = widget.favoritePostDetailData!.postData!.blogInfo.blogName;
      } else if (widget.meta != null) {
        postId = NumberUtil.hexToInt(widget.meta!['postId']!);
        blogId = NumberUtil.hexToInt(widget.meta!['blogId']!);
        blogName = widget.meta!['blogName']!;
      } else if (widget.searchPost != null) {
        postId = widget.searchPost!.id;
        blogId = widget.searchPost!.blogId;
        blogName = widget.searchPost!.blogInfo.blogName;
      } else if (widget.grainPostItem != null) {
        postId = widget.grainPostItem!.postData.postView.id;
        blogId = widget.grainPostItem!.postData.postView.blogId;
        blogName = widget.grainPostItem!.postData.blogInfo.blogName;
      } else if (widget.generalPostItem != null) {
        postId = widget.generalPostItem!.postId;
        blogId = widget.generalPostItem!.blogId;
        blogName = widget.generalPostItem!.blogName;
      }
    } catch (e, t) {
      _inited = InitPhase.failed;
      ILogger.error("Failed to init param", e, t);
    }
  }

  _uploadHistory() async {
    final historyPostId = postId;
    final historyBlogId = blogId;
    final historyPostType = _postDetailData!.post!.type;
    final historyCollectionId = _postDetailData!.post!.collectionId;
    int userId = await HiveUtil.getUserId();
    PostApi.uploadHistory(
      postId: historyPostId,
      blogId: historyBlogId,
      userId: userId,
      postType: historyPostType,
      collectionId: historyCollectionId,
    ).then((value) {
      if (value['code'] != 200) {
        IToast.showTop(value['msg']);
      }
    });
  }

  _fetchPostDetail() async {
    if (_loadingInfo) return;
    _loadingInfo = true;
    try {
      final value = await PostApi.getDetail(
        postId: postId,
        blogId: blogId,
        blogName: blogName,
      ).timeout(const Duration(seconds: 20));
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        _inited = InitPhase.failed;
        return IndicatorResult.fail;
      }
      final posts = value['response']?['posts'];
      if (posts is! List || posts.isEmpty || posts.first is! Map) {
        throw const FormatException('Post detail response has no post data');
      }
      final parsed = PostDetailData.fromJson(
        Map<String, dynamic>.from(posts.first as Map),
      );
      if (parsed.post == null) {
        throw const FormatException('Post detail response has no post body');
      }
      _postDetailData = parsed;
      _updateMeta(swipeToFirst: false);
      _inited = InitPhase.successful;
      if (mounted) setState(() {});
      unawaited(_uploadHistory());

      // Gift and comment data enrich the page, but must not turn a valid
      // article into a full-page error when either auxiliary endpoint fails.
      try {
        await _fetchGift();
      } catch (error, stackTrace) {
        ILogger.error('Failed to load post gift', error, stackTrace);
      }
      try {
        await _fetchHotComments();
      } catch (error, stackTrace) {
        ILogger.error('Failed to load post comments', error, stackTrace);
      }
      return IndicatorResult.success;
    } catch (e, t) {
      _inited = InitPhase.failed;
      ILogger.error("Failed to fetch post detail", e, t);
      return IndicatorResult.fail;
    } finally {
      _loadingInfo = false;
      if (mounted) setState(() {});
    }
  }

  _fetchGift({int? expectedPostId}) async {
    final requestPostId = expectedPostId ?? postId;
    final requestBlogId = blogId;
    return await PostApi.getGifts(
      postId: requestPostId,
      blogId: requestBlogId,
    ).then((value) {
      if (!mounted || postId != requestPostId) return IndicatorResult.none;
      if (value == null) return IndicatorResult.fail;
      if (value['code'] != 200 || value['ok'] != true) {
        IToast.showTop(value['msg']);
        return IndicatorResult.fail;
      } else {
        _giftInfoData = GiftInfoData.fromJson(value['data']);
        _refreshPreviewImage();
        _refreshGiftDescription();
        if (mounted) setState(() {});
        return IndicatorResult.success;
      }
    });
  }

  _refreshPreviewImage() {
    if (_hasReturnContent()) {
      _previewImages = _getReturnGiftImages();
      _isCatutu = false;
    } else {
      if (controlProvider.globalControl.showCatutu) {
        _previewImages = [];
        for (var gift in _giftInfoData!.returnGifts) {
          _previewImages.addAll(gift.previewImages ?? []);
        }
        _isCatutu = true;
      }
    }
  }

  ReturnGift? _getReturnGift() {
    if (_giftInfoData != null && _giftInfoData!.returnGifts.isNotEmpty) {
      return _giftInfoData!.returnGifts.first;
    }
    return null;
  }

  ReturnContent? _getReturnContent() {
    if (_postDetailData != null &&
        _postDetailData!.post != null &&
        _postDetailData!.post!.returnContent.isNotEmpty) {
      return _postDetailData!.post!.returnContent.first;
    }
    return null;
  }

  bool _hasReturnContent() {
    return _getReturnContent() != null;
  }

  List<PreviewImage> _getReturnGiftImages() {
    ReturnContent? content = _getReturnContent();
    if (content == null) return [];
    return content.images;
  }

  void _refreshGiftDescription() {
    ReturnGift? gift = _getReturnGift();
    if (gift == null) return;
    String typeString = gift.planType?.name ?? appLocalizations.easterEgg;
    var defaultGifts = gift.defaultSelectedGifts ?? [];
    List<String> unlockCost = [];
    Map<int, int> idToCoinMap = {};
    if (defaultGifts.isNotEmpty) {
      for (var gift in defaultGifts) {
        idToCoinMap[gift.id ?? LIANGPIAO_GIFTID] = gift.coin ?? 0;
        if ((gift.coin ?? 0) > 0) {
          unlockCost
              .add("${gift.name}(${gift.coin}${appLocalizations.coinCount})");
        } else {
          unlockCost.add("${gift.name}");
        }
      }
    }
    _giftCostId =
        idToCoinMap.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    String previewDescription = "";
    if ((gift.wordCount ?? 0) > 0) {
      previewDescription = "${gift.wordCount}${appLocalizations.wordCount}";
    }
    if ((gift.imgCount ?? 0) > 0) {
      previewDescription += "${gift.imgCount}${appLocalizations.imageCount}";
    }
    if (previewDescription.isNotEmpty) {
      previewDescription = "($previewDescription)";
    }
    _giftTypeString = typeString;
    _giftPreviewDescription = previewDescription;
    _giftCost = " ${unlockCost.join(appLocalizations.or)} ";
  }

  _fetchHotComments({int? expectedPostId}) async {
    final requestPostId = expectedPostId ?? postId;
    final requestBlogId = blogId;
    final requestPublishTime = _postDetailData!.post!.publishTime;
    return await PostApi.getHotComments(
      postId: requestPostId,
      blogId: requestBlogId,
      postPublishTime: requestPublishTime,
    ).then((value) {
      try {
        if (!mounted || postId != requestPostId) {
          return IndicatorResult.none;
        }
        if (value == null) return IndicatorResult.fail;
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          totalHotOrNewComments = value['data']['hotTotal'];
          hotComments.clear();
          List<dynamic> comments = value['data']['hotList'] as List;
          for (var comment in comments) {
            hotComments.add(Comment.fromJson(comment));
          }
          newComments.clear();
          comments = value['data']['list'] as List;
          for (var comment in comments) {
            newComments.add(Comment.fromJson(comment));
          }
          return IndicatorResult.success;
        }
      } catch (e, t) {
        IToast.showTop(appLocalizations.loadFailed);
        ILogger.error("Failed to load hot comment", e, t);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
      }
    });
  }

  _fetchL2Comments(Comment currentComment) async {
    currentComment.l2CommentLoading = true;
    if (mounted) setState(() {});
    return await PostApi.getL2Comments(
      id: currentComment.id,
      offset: currentComment.l2CommentOffset,
      postId: postId,
      blogId: blogId,
    ).then((value) {
      try {
        if (value == null) return IndicatorResult.fail;
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          currentComment.l2CommentOffset = value['data']['offset'];
          List<dynamic> comments = value['data']['list'] as List;
          for (var comment in comments) {
            currentComment.l2Comments.add(Comment.fromJson(comment));
          }
          return IndicatorResult.success;
        }
      } catch (e, t) {
        IToast.showTop(appLocalizations.loadFailed);
        ILogger.error("Failed to load l2 comment", e, t);
        return IndicatorResult.fail;
      } finally {
        currentComment.l2CommentLoading = false;
        if (mounted) setState(() {});
      }
    });
  }

  Future<IndicatorResult> _fetchPreOrNextPost({required bool isPre}) async {
    final switched = await _switchToAdjacentPost(previous: isPre);
    return switched ? IndicatorResult.success : IndicatorResult.fail;
  }

  bool get _supportsPostSwipe => _postDetailData?.post != null;

  bool get _hasPostSequenceContext =>
      widget.sequenceSource != null || hasCollection();

  bool _canNavigateAdjacent({required bool previous}) {
    final source = widget.sequenceSource;
    if (source != null) {
      return source.canNavigateFrom(postId, previous: previous);
    }
    if (!hasCollection()) return false;
    final post = _postDetailData!.post!;
    return previous ? post.pos > 1 : post.pos < post.postCollection!.postCount;
  }

  Future<PostDetailData?> _loadAdjacentPost({required bool previous}) {
    final existing = _adjacentPostLoads[previous];
    if (existing != null) return existing;
    final request = widget.sequenceSource != null
        ? _loadSequenceAdjacentPost(previous: previous)
        : _loadCollectionAdjacentPost(previous: previous);
    final task = request.timeout(
      const Duration(seconds: 15),
      onTimeout: () => null,
    );
    _adjacentPostLoads[previous] = task;
    task.then((value) {
      if (value == null && identical(_adjacentPostLoads[previous], task)) {
        _adjacentPostLoads.remove(previous);
      }
    });
    return task;
  }

  Future<PostDetailData?> _loadCollectionAdjacentPost({
    required bool previous,
  }) async {
    if (!hasCollection() || !_canNavigateAdjacent(previous: previous)) {
      return null;
    }
    try {
      final value = await CollectionApi.getPreOrNextPost(
        isPre: previous,
        postId: postId,
        blogId: blogId,
        blogName: blogName,
        collectionId: collectionId,
      ).timeout(const Duration(seconds: 20));
      if (value['meta']?['status'] != 200) return null;
      final response = value['response'];
      if (response is! List || response.isEmpty || response.first is! Map) {
        return null;
      }
      return PostDetailData.fromJson(
        Map<String, dynamic>.from(response.first as Map),
      );
    } catch (error, stackTrace) {
      ILogger.error('Failed to preload collection post', error, stackTrace);
      return null;
    }
  }

  Future<PostDetailData?> _loadSequenceAdjacentPost({
    required bool previous,
  }) async {
    final source = widget.sequenceSource;
    if (source == null) return null;
    try {
      final entry = await source
          .adjacentTo(postId, previous: previous)
          .timeout(const Duration(seconds: 20));
      if (entry == null) return null;
      final value = await PostApi.getDetail(
        postId: entry.postId,
        blogId: entry.blogId,
        blogName: entry.blogName,
      ).timeout(const Duration(seconds: 20));
      if (value['meta']?['status'] != 200) return null;
      final posts = value['response']?['posts'];
      if (posts is! List || posts.isEmpty || posts.first is! Map) return null;
      return PostDetailData.fromJson(
        Map<String, dynamic>.from(posts.first as Map),
      );
    } catch (error, stackTrace) {
      ILogger.error('Failed to preload grain post', error, stackTrace);
      return null;
    }
  }

  void _scheduleAdjacentPostPreload() {
    _adjacentPostLoads.clear();
    if (!_supportsPostSwipe) return;
    for (final previous in const [true, false]) {
      if (_canNavigateAdjacent(previous: previous)) {
        unawaited(_loadAdjacentPost(previous: previous));
      }
    }
  }

  Future<bool> _switchToAdjacentPost({required bool previous}) async {
    if (_switchingPost || !_supportsPostSwipe) return false;
    if (!_canNavigateAdjacent(previous: previous)) {
      IToast.showTop(previous
          ? appLocalizations.haveAtFirstPost
          : appLocalizations.haveAtLastPost);
      await _animatePostSwipeOffset(0);
      return false;
    }

    final current = _postDetailData;
    if (current?.post == null) return false;
    final nextTask = _loadAdjacentPost(previous: previous);
    _switchingPost = true;
    _postSwipePrevious = previous;
    if (mounted) setState(() {});
    HapticFeedback.mediumImpact();
    final width = MediaQuery.sizeOf(context).width;
    final exitOffset = previous ? width : -width;
    await _animatePostSwipeOffset(
      exitOffset,
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeInCubic,
    );
    if (!mounted) return false;

    _postDetailData = null;
    _inited = InitPhase.connecting;
    _postSwipeAnimation = null;
    setState(() {
      _postSwipeOffset = 0;
      _postSwipeRawOffset = 0;
      _postSwipePrevious = null;
      _postSwipeReady = false;
      _postSwipeAtBoundary = false;
      _postSwipeBoundaryReady = false;
    });

    final result = await Future.wait<dynamic>([
      nextTask,
      Future<void>.delayed(const Duration(milliseconds: 180)),
    ]);
    if (!mounted) return false;
    final next = result.first as PostDetailData?;
    if (next?.post == null) {
      _postDetailData = current;
      _inited = InitPhase.successful;
      _postSwipeOffset = exitOffset;
      setState(() {});
      await _animatePostSwipeOffset(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return false;
      _switchingPost = false;
      setState(() {});
      IToast.showTop(appLocalizations.adjacentPostLoadFailed);
      return false;
    }

    _resetPostScopedState();
    _postDetailData = next;
    _inited = InitPhase.successful;
    _updateMeta(schedulePreload: false);
    _jumpPostScrollToTop();
    _postSwipeAnimation = null;
    setState(() {
      _postSwipeOffset = -exitOffset;
      _postSwipeRawOffset = 0;
      _postSwipeReady = false;
      _postSwipeAtBoundary = false;
      _postSwipeBoundaryReady = false;
    });
    await _animatePostSwipeOffset(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return false;

    _switchingPost = false;
    _postSwipePrevious = null;
    _scheduleAdjacentPostPreload();
    setState(() {});
    unawaited(_uploadHistory());
    unawaited(_loadCurrentPostExtras());
    return true;
  }

  void _resetPostScopedState() {
    _previewImages = [];
    _giftInfoData = null;
    _giftTypeString = '';
    _giftPreviewDescription = '';
    _giftCost = '';
    totalHotOrNewComments = 0;
    hotComments.clear();
    newComments.clear();
    _recommendPosts.clear();
    _currentPage = 0;
    _recommendNoMore = false;
    _recommendRequestToken++;
    _loadingRecommend = false;
    mainColors = [];
  }

  Future<void> _loadCurrentPostExtras() async {
    final expectedPostId = postId;
    await Future.wait<dynamic>([
      _fetchGift(expectedPostId: expectedPostId),
      _fetchHotComments(expectedPostId: expectedPostId),
      _fetchRecommendPosts(append: false, expectedPostId: expectedPostId),
    ]);
  }

  void _jumpPostScrollToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    if (_tabletScrollController.hasClients) {
      _tabletScrollController.jumpTo(0);
    }
    _scrollAllowsFloatingOperationBar = true;
    _floatingOperationBarVisible.value = true;
  }

  bool _handlePostScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    var delta = 0.0;
    if (notification is ScrollUpdateNotification) {
      delta = notification.scrollDelta ?? 0;
    } else if (notification is OverscrollNotification) {
      delta = notification.overscroll;
    }
    if (notification.metrics.pixels <= 16 || delta < -1) {
      _scrollAllowsFloatingOperationBar = true;
    } else if (delta > 1) {
      _scrollAllowsFloatingOperationBar = false;
    }
    _syncFloatingOperationBarVisibility();
    return false;
  }

  void _syncFloatingOperationBarVisibility() {
    if (!mounted) return;
    final shouldShow = _scrollAllowsFloatingOperationBar &&
        !_isInlineOperationSectionInViewport();
    if (shouldShow != _floatingOperationBarVisible.value) {
      _floatingOperationBarVisible.value = shouldShow;
    }
  }

  bool _isInlineOperationSectionInViewport() {
    return <GlobalKey>[
      _collectionViewportKey,
      _grainViewportKey,
      _tagViewportKey,
      _operationViewportKey,
      commentKey,
      _commentListViewportKey,
      _commentEndViewportKey,
    ].any(_isViewportKeyVisible);
  }

  bool _isViewportKeyVisible(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return false;
    }
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    return bottom > 0 && top < viewportHeight;
  }

  Future<void> _animatePostSwipeOffset(
    double target, {
    Duration duration = const Duration(milliseconds: 210),
    Curve curve = Curves.easeOutCubic,
  }) async {
    _postSwipeAnimationController.stop();
    _postSwipeAnimationController.duration = duration;
    _postSwipeAnimation = Tween<double>(
      begin: _postSwipeOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _postSwipeAnimationController,
      curve: curve,
    ));
    try {
      await _postSwipeAnimationController.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    _postSwipeAnimation = null;
    _postSwipeOffset = target;
  }

  _fetchRecommendPosts({
    bool append = true,
    int? expectedPostId,
  }) async {
    final requestPostId = expectedPostId ?? postId;
    final requestBlogId = blogId;
    if (requestPostId != postId) return IndicatorResult.none;
    if (_loadingRecommend || (append && _recommendNoMore)) {
      return IndicatorResult.none;
    }
    _loadingRecommend = true;
    final requestToken = ++_recommendRequestToken;
    final requestPage = append ? _currentPage + 1 : 1;
    return await RecommendApi.getPostRecomend(
      page: requestPage,
      postId: requestPostId,
      blogId: requestBlogId,
    ).then((value) {
      try {
        if (!mounted ||
            postId != requestPostId ||
            requestToken != _recommendRequestToken) {
          return IndicatorResult.none;
        }
        if (value['code'] != 0) {
          if (value['code'] != 4009) {
            IToast.showTop(value['msg']);
          }
          return IndicatorResult.fail;
        } else {
          List<dynamic> tmp = value['data']['list'];
          if (append == false) _recommendPosts.clear();
          final newPosts = tmp
              .map((e) => PostListItem.fromJson(e))
              .where(
                (post) => !_recommendPosts.any(
                  (current) => current.itemId == post.itemId,
                ),
              )
              .toList();
          _recommendPosts.addAll(newPosts);
          _currentPage = requestPage;
          _recommendNoMore = tmp.isEmpty || newPosts.isEmpty;
          if (_recommendNoMore && append) return IndicatorResult.noMore;
          return IndicatorResult.success;
        }
      } catch (e, t) {
        if (mounted) IToast.showTop(appLocalizations.loadFailed);
        ILogger.error("Failed to load recommend post", e, t);
        return IndicatorResult.fail;
      } finally {
        if (requestToken == _recommendRequestToken) {
          _loadingRecommend = false;
        }
        if (mounted) setState(() {});
      }
    });
  }

  _updateMeta({
    bool swipeToFirst = true,
    bool schedulePreload = true,
  }) {
    if (_postDetailData == null) return;
    isArticle = _postDetailData!.post!.type == 1;
    collectionId = _postDetailData!.post!.postCollection != null
        ? _postDetailData!.post!.postCollection!.id
        : 0;
    postId = _postDetailData!.post!.id;
    blogId = _postDetailData!.post!.blogId;
    blogName = _postDetailData!.post!.blogInfo!.blogName;
    final colorPostId = postId;
    _shareController.value = _postDetailData!.shared == true ? 1 : 0;
    _likeController.value = _postDetailData!.liked == true ? 1 : 0;
    setDownloadState(DownloadState.none, recover: false);
    if (swipeToFirst) {
      setState(() {
        _currentIndex = 1;
        _swiperController.move(0);
      });
    }
    if (_hasImage() && ChewieHiveUtil.getBool(HiveUtil.followMainColorKey)) {
      List<PhotoLink> photoLinks = _getImages()[0];
      ColorUtil.getMainColors(
        context,
        photoLinks.map((e) => e.middle).toList(),
      ).then((value) {
        if (!mounted || postId != colorPostId) return;
        mainColors = value;
        setState(() {});
      });
    } else {
      List<String> imageUrls = _getArticleImages();
      ColorUtil.getMainColors(
        context,
        imageUrls,
      ).then((value) {
        if (!mounted || postId != colorPostId) return;
        mainColors = value;
        setState(() {});
      });
    }
    if (schedulePreload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleAdjacentPostPreload();
      });
    }
  }

  _onRefresh() async {
    _currentPage = 0;
    _recommendNoMore = false;
    var t1 = await _fetchPostDetail();
    var t2 = await _fetchRecommendPosts(append: false);
    return t1 == IndicatorResult.success && t2 == IndicatorResult.success
        ? IndicatorResult.success
        : IndicatorResult.fail;
  }

  _onLoad() async {
    return await _fetchRecommendPosts();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: ChewieTheme.getBackground(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPostSwipeLayer(_buildBody()),
          _buildFloatingOperationOverlay(),
        ],
      ),
    );
  }

  _buildBody() {
    switch (_inited) {
      case InitPhase.connecting:
      case InitPhase.haveNotConnected:
        return LoadingWidget(
          background: ChewieTheme.getBackground(context),
        );
      case InitPhase.successful:
        if (_postDetailData != null) {
          return _buildNormalBody();
        } else {
          return CustomErrorWidget(
            onTap: initData,
          );
        }
      case InitPhase.failed:
        return CustomErrorWidget(
          onTap: initData,
        );
    }
  }

  Widget _buildPostSwipeLayer(Widget child) {
    if (!_supportsPostSwipe) return child;
    final width = MediaQuery.sizeOf(context).width;
    final contentOpacity =
        (1 - min(0.16, _postSwipeOffset.abs() / max(width, 1) * 0.16))
            .toDouble();
    return PostSwipeGestureDetector(
      behavior: HitTestBehavior.translucent,
      excludedRegions: [_imageSwiperViewportKey],
      onHorizontalDragStart: _handlePostSwipeStart,
      onHorizontalDragUpdate: _handlePostSwipeUpdate,
      onHorizontalDragEnd: _handlePostSwipeEnd,
      onHorizontalDragCancel: _handlePostSwipeCancel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.translate(
            offset: Offset(_postSwipeOffset, 0),
            child: Opacity(opacity: contentOpacity, child: child),
          ),
          _buildPostSwipeHint(),
        ],
      ),
    );
  }

  void _handlePostSwipeStart(DragStartDetails details) {
    if (_switchingPost) return;
    _postSwipeAnimationController.stop();
    _postSwipeAnimation = null;
    setState(() {
      _postSwipeRawOffset = 0;
      _postSwipeOffset = 0;
      _postSwipePrevious = null;
      _postSwipeReady = false;
      _postSwipeAtBoundary = false;
      _postSwipeBoundaryReady = false;
    });
  }

  void _handlePostSwipeUpdate(DragUpdateDetails details) {
    if (_switchingPost) return;
    _postSwipeRawOffset += details.primaryDelta ?? 0;
    if (_postSwipeRawOffset.abs() < 1) return;
    final previous = _postSwipeRawOffset > 0;
    final available = _canNavigateAdjacent(previous: previous);
    final width = MediaQuery.sizeOf(context).width;
    final reachedCommitDistance =
        PostSwipeGesturePolicy.hasReachedCommitDistance(
      rawOffset: _postSwipeRawOffset,
      viewportWidth: width,
    );
    final ready = available && reachedCommitDistance;
    final boundaryReady =
        !available && _hasPostSequenceContext && reachedCommitDistance;
    if (ready && !_postSwipeReady) HapticFeedback.selectionClick();
    if (boundaryReady && !_postSwipeBoundaryReady) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _postSwipePrevious = previous;
      _postSwipeReady = ready;
      _postSwipeAtBoundary = !available;
      _postSwipeBoundaryReady = boundaryReady;
      _postSwipeOffset = PostSwipeGesturePolicy.visualOffset(
        rawOffset: _postSwipeRawOffset,
        viewportWidth: width,
        available: available,
      );
    });
  }

  void _handlePostSwipeEnd(DragEndDetails details) {
    if (_switchingPost || _postSwipePrevious == null) return;
    final previous = _postSwipePrevious!;
    final available = _canNavigateAdjacent(previous: previous);
    final shouldCommit = PostSwipeGesturePolicy.shouldCommit(
      rawOffset: _postSwipeRawOffset,
      velocity: details.primaryVelocity ?? 0,
      viewportWidth: MediaQuery.sizeOf(context).width,
      available: available,
    );
    if (shouldCommit) {
      unawaited(_switchToAdjacentPost(previous: previous));
      return;
    }
    if (!available && _hasPostSequenceContext && _postSwipeBoundaryReady) {
      IToast.showTop(previous
          ? appLocalizations.haveAtFirstPost
          : appLocalizations.haveAtLastPost);
    }
    unawaited(_reboundPostSwipe());
  }

  void _handlePostSwipeCancel() {
    if (!_switchingPost) unawaited(_reboundPostSwipe());
  }

  Future<void> _reboundPostSwipe() async {
    setState(() {
      _postSwipeRawOffset = 0;
      _postSwipeReady = false;
      _postSwipeBoundaryReady = false;
    });
    await _animatePostSwipeOffset(0);
    if (!mounted) return;
    setState(() {
      _postSwipePrevious = null;
      _postSwipeAtBoundary = false;
      _postSwipeBoundaryReady = false;
    });
  }

  Widget _buildPostSwipeHint() {
    final previous = _postSwipePrevious;
    if (previous == null) return const SizedBox.shrink();
    if (_postSwipeAtBoundary && !_hasPostSequenceContext) {
      return const SizedBox.shrink();
    }
    final revealProgress = _switchingPost
        ? 0.0
        : _postSwipeAtBoundary
            ? PostSwipeGesturePolicy.boundaryHintRevealProgress(
                rawOffset: _postSwipeRawOffset,
                viewportWidth: MediaQuery.sizeOf(context).width,
                hasSequenceContext: _hasPostSequenceContext,
              )
            : PostSwipeGesturePolicy.hintRevealProgress(_postSwipeRawOffset);
    final postLabel =
        previous ? appLocalizations.prePost : appLocalizations.nextPost;
    final label = _postSwipeAtBoundary
        ? previous
            ? appLocalizations.haveAtFirstPost
            : appLocalizations.haveAtLastPost
        : _postSwipeReady
            ? appLocalizations.releaseToSwitchPost(postLabel)
            : appLocalizations.continueSwipeToPost(postLabel);
    final color = _postSwipeReady && !_postSwipeAtBoundary
        ? Theme.of(context).primaryColor
        : Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: _postSwipeAtBoundary ? 0.55 : 0.82);
    final shadows = [
      Shadow(
        color: ChewieTheme.getBackground(context).withValues(alpha: 0.98),
        blurRadius: 8,
      ),
      Shadow(
        color: ChewieTheme.getBackground(context).withValues(alpha: 0.9),
        blurRadius: 3,
      ),
    ];
    final icon = ChewieIcon(
      _postSwipeAtBoundary
          ? LoftifyIcons.block
          : previous
              ? LoftifyIcons.previousPost
              : LoftifyIcons.nextPost,
      size: 21,
      color: color,
      shadows: shadows,
    );
    final isChinese = Localizations.localeOf(context).languageCode == 'zh';
    final hintText = isChinese ? label.split('').join('\n') : label;
    final text = Text(
      hintText,
      textAlign: TextAlign.center,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.apply(
            color: color,
            fontWeightDelta: _postSwipeReady ? 2 : 1,
          )
          .copyWith(
            height: isChinese ? 1.08 : null,
            shadows: shadows,
          ),
    );
    return Positioned(
      left: previous ? 16 : null,
      right: previous ? null : 16,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: revealProgress),
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.72 + value * 0.28,
                child: child,
              ),
            ),
            child: Semantics(
              liveRegion: true,
              label: label,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(label),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(height: 7),
                    if (isChinese)
                      text
                    else
                      RotatedBox(
                        quarterTurns: previous ? 3 : 1,
                        child: text,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalBody() {
    return ScreenTypeLayout.builder(
      mobile: (context) => EasyRefresh.builder(
        onRefresh: _onRefresh,
        onLoad: _recommendNoMore ? null : _onLoad,
        triggerAxis: Axis.vertical,
        childBuilder: (context, physics) => Stack(
          children: [
            AbsorbPointer(
              absorbing: false,
              child: _buildMainBody(physics),
            ),
            Visibility(
              visible: _showDoubleTapLike,
              child: Positioned(
                left: doubleTapDx,
                top: doubleTapDy,
                child: IgnorePointer(
                  child: doubleTapLikeWidget,
                ),
              ),
            ),
          ],
        ),
      ),
      tablet: (context) => Stack(
        children: [
          AbsorbPointer(
            absorbing: false,
            child: _buildMainBody(const ScrollPhysics()),
          ),
          Visibility(
            visible: _showDoubleTapLike,
            child: Positioned(
              left: doubleTapDx,
              top: doubleTapDy,
              child: IgnorePointer(
                child: doubleTapLikeWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildMainBody(ScrollPhysics physics) {
    return Stack(
      children: [
        Selector<AppProvider, Size>(
          selector: (context, appProvider) => appProvider.windowSize,
          builder: (context, windowSize, child) =>
              windowSize.width > postDetailTwoPaneMinWindowSize.width ||
                      ResponsiveUtil.isLandscapeTablet()
                  ? ScreenTypeLayout.builder(
                      mobile: (context) => _buildMobileMainBody(physics),
                      tablet: (context) => _buildTabletMainBody(),
                    )
                  : _buildMobileMainBody(physics),
        ),
      ],
    );
  }

  _buildMobileMainBody(ScrollPhysics physics) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handlePostScrollNotification,
      child: CustomScrollView(
        controller: _scrollController,
        physics: physics,
        slivers: [
          SliverList.list(children: _buildCommonContent(false)),
          _buildRecommendFlow(),
        ],
      ),
    );
  }

  _buildTabletMainBody() {
    return ResizableContainer(
      direction: Axis.horizontal,
      controller: _resizableController,
      // divider: ResizableDivider(
      //   color: Theme
      //       .of(context)
      //       .dividerColor,
      //   thickness: ResponsiveUtil.isMobile() ? 2 : 1,
      //   size: 6,
      //   onHoverEnter: () {
      //     if (ResponsiveUtil.isMobile()) {
      //       HapticFeedback.lightImpact();
      //     }
      //   },
      // ),
      children: [
        ResizableChild(
          size: ResizableSize.pixels(
            isArticle
                ? MediaQuery.sizeOf(context).width * 2 / 3
                : max(MediaQuery.sizeOf(context).width * 1 / 3, 400),
          ),
          // minSize: 300,
          child: EasyRefresh.builder(
            onRefresh: _onRefresh,
            triggerAxis: Axis.vertical,
            childBuilder: (context, physics) =>
                NotificationListener<ScrollNotification>(
              onNotification: _handlePostScrollNotification,
              child: ListView(
                controller: _tabletScrollController,
                physics: physics,
                children: _buildCommonContent(true),
              ),
            ),
          ),
        ),
        ResizableChild(
          // minSize: 300,
          size: const ResizableSize.expand(),
          child: _buildRecommendFlow(sliver: false),
        ),
      ],
    );
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    doubleTapDx =
        _doubleTapDetails.globalPosition.dx - 20 - doubleTapLikeSize / 2;
    doubleTapDy =
        _doubleTapDetails.globalPosition.dy - 110 - doubleTapLikeSize / 2;
    setState(() {});
    _operateDoubleTapAction();
  }

  _operateDoubleTapAction() {
    DoubleTapAction action = DoubleTapAction.values[ChewieUtils.patchEnum(
        ChewieHiveUtil.getInt(HiveUtil.doubleTapActionKey, defaultValue: 1),
        DoubleTapAction.values.length)];
    switch (action) {
      case DoubleTapAction.none:
        break;
      case DoubleTapAction.like:
        HapticFeedback.mediumImpact();
        _showDoubleTapLike = true;
        _doubleTapLikeController.forward(from: 0);
        _doubleTapLikeController.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _showDoubleTapLike = false;
            setState(() {});
          }
        });
        _handleLike(isLike: true);
        break;
      case DoubleTapAction.download:
        HapticFeedback.mediumImpact();
        _handleDownload();
        break;
      case DoubleTapAction.downloadAll:
        HapticFeedback.mediumImpact();
        _handleDownloadAll();
        break;
      case DoubleTapAction.copyLink:
        HapticFeedback.mediumImpact();
        ChewieUtils.copy(
          context,
          LoftifyUriUtil.getPostUrlByPermalink(
            _postDetailData!.post!.blogInfo!.blogName,
            _postDetailData!.post!.permalink,
          ),
        );
        break;
      case DoubleTapAction.recommend:
        HapticFeedback.mediumImpact();
        _handleRecommend(isRecommend: true);
        break;
    }
  }

  Future<void> _handleLike({
    bool? isLike,
  }) async {
    HapticFeedback.mediumImpact();
    final previousLiked = _postDetailData!.liked == true;
    final targetLiked = isLike ?? !previousLiked;
    final value = await PostApi.likeOrUnLike(
      isLike: targetLiked,
      postId: _postDetailData!.post!.id,
      blogId: _postDetailData!.post!.blogId,
    );
    if (!mounted) return;

    final status = value['meta']['status'];
    if (status != 200) {
      final message = value['meta']['desc'] ?? value['meta']['msg'];
      if (StringUtil.isNotEmpty(message)) IToast.showTop(message);
      if (status == 4071) Utils.validSlideCaptcha(context);
      return;
    }

    final delta = targetLiked == previousLiked ? 0 : (targetLiked ? 1 : -1);
    _postDetailData!.liked = targetLiked;
    if (targetLiked) {
      _likeController.forward();
    } else {
      _likeController.value = 0;
    }
    final postCount = _postDetailData!.post!.postCount!;
    postCount.favoriteCount =
        (postCount.favoriteCount + delta).clamp(0, 100000000000000000);
    if (postCount.postHot != null) {
      postCount.postHot =
          (postCount.postHot! + delta).clamp(0, 100000000000000000);
    }
    final sourceItem = widget.generalPostItem;
    if (sourceItem != null) {
      sourceItem
        ..liked = targetLiked
        ..likeCount = postCount.favoriteCount;
      sourceItem.onLikeChanged?.call(targetLiked);
    }
    setState(() {});
  }

  _handleRecommend({
    bool? isRecommend,
  }) {
    HapticFeedback.mediumImpact();
    PostApi.shareOrUnShare(
            isShare: isRecommend ?? !(_postDetailData!.shared == true),
            postId: _postDetailData!.post!.id,
            blogId: _postDetailData!.post!.blogId)
        .then((value) {
      setState(() {
        if (value['meta']['status'] != 200) {
          if (StringUtil.isNotEmpty(value['meta']['desc']) &&
              StringUtil.isNotEmpty(value['meta']['msg'])) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
          }
          if (value['meta']['status'] == 4071) {
            Utils.validSlideCaptcha(context);
          }
        } else {
          _postDetailData!.shared =
              isRecommend ?? !(_postDetailData!.shared == true);
          if (_postDetailData!.shared == true) {
            _shareController.forward();
          } else {
            _shareController.value = 0;
          }
          _postDetailData!.post!.postCount!.shareCount +=
              (_postDetailData!.shared == true) ? 1 : -1;
          if (_postDetailData!.post!.postCount!.postHot != null) {
            _postDetailData!.post!.postCount!.postHot =
                _postDetailData!.post!.postCount!.postHot! +
                    ((_postDetailData!.shared == true) ? 1 : -1);
          }
        }
      });
    });
  }

  _handleSubscribe(List<String> folderIds) {
    HapticFeedback.mediumImpact();
    PostApi.subscribeOrUnSubscribe(
            folderIds: folderIds,
            postId: _postDetailData!.post!.id,
            blogId: _postDetailData!.post!.blogId)
        .then((value) {
      setState(() {
        if (value['meta']['status'] != 200) {
          if (StringUtil.isNotEmpty(value['meta']['desc']) &&
              StringUtil.isNotEmpty(value['meta']['msg'])) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
          }
          if (value['meta']['status'] == 4071) {
            Utils.validSlideCaptcha(context);
          }
        } else {
          _postDetailData!.subscribed = folderIds.isNotEmpty;
          _postDetailData!.post!.postCount!.subscribeCount +=
              (_postDetailData!.subscribedNotNull) ? 1 : -1;
          if (_postDetailData!.post!.postCount!.postHot != null) {
            _postDetailData!.post!.postCount!.postHot =
                _postDetailData!.post!.postCount!.postHot! +
                    ((_postDetailData!.subscribedNotNull) ? 1 : -1);
          }
        }
      });
    });
  }

  _handleDownload() {
    if (isArticle) {
      IToast.showTop(appLocalizations.unsupportDownloadCurrentImageinArticle);
      return;
    }
    if (downloadState == DownloadState.none) {
      setDownloadState(DownloadState.loading, recover: false);
      LoftifyFileUtil.saveIllust(
        context,
        _getIllusts()[_currentIndex - 1],
      ).then((res) {
        if (res) {
          setDownloadState(DownloadState.succeed);
          _handleDownloadSuccessAction();
        } else {
          setDownloadState(DownloadState.failed);
        }
      });
    }
  }

  _handleDownloadAll() {
    if (!_hasImage() && !_hasArticleImage()) {
      IToast.showTop(appLocalizations.noImageToDownload);
      return;
    }
    if (downloadState == DownloadState.none) {
      setDownloadState(DownloadState.loading, recover: false);
      LoftifyFileUtil.saveIllusts(context, _getIllusts()).then((res) {
        if (res) {
          _handleDownloadSuccessAction();
          setDownloadState(DownloadState.succeed);
        } else {
          setDownloadState(DownloadState.failed);
        }
      });
    }
  }

  _buildCommonContent(bool isTablet) {
    return <Widget>[
      GestureDetector(
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            UserDetailScreen(
              blogId: _postDetailData!.post!.blogId,
              blogName: _postDetailData!.post!.blogInfo!.blogName,
            ),
          );
        },
        child: _buildUserRow(),
      ),
      if (_hasImage()) _buildImageList(),
      GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: _buildPostContent(),
      ),
      GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: _buildEggContent(),
      ),
      if (hasCollection()) _buildCollectionItem(key: _collectionViewportKey),
      if (hasGrain()) _buildGrainItem(key: _grainViewportKey),
      GestureDetector(
        key: _tagViewportKey,
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: _buildTagList(),
      ),
      _buildMarkInfo(),
      Stack(
        key: _operationViewportKey,
        children: [
          MyDivider(),
          _buildOperationRow(),
        ],
      ),
      Container(
        key: commentKey,
        child: ItemBuilder.buildTitle(
          context,
          title: hotComments.isNotEmpty
              ? appLocalizations.hotComment
              : appLocalizations.latestComment,
          bottomMargin: 12,
          topMargin: 24,
        ),
      ),
      _buildComments(
        hotComments.isNotEmpty ? hotComments : newComments,
        key: _commentListViewportKey,
      ),
      if (totalHotOrNewComments <= 0)
        Container(
          key: _commentEndViewportKey,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(vertical: 24),
          child: EmptyPlaceholder(
            text: appLocalizations.noComment,
            topPadding: 0,
          ),
        ),
      if (totalHotOrNewComments > 0)
        Center(
          key: _commentEndViewportKey,
          child: Container(
            margin: EdgeInsets.only(
              left: isTablet ? 0 : MediaQuery.sizeOf(context).width / 5,
              right: isTablet ? 0 : MediaQuery.sizeOf(context).width / 5,
              top: 12,
              bottom: isTablet ? 20 : 0,
            ),
            width: isTablet ? 240 : null,
            child: RoundIconTextButton(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              text: appLocalizations.viewAllComments,
              onPressed: () {
                BottomSheetBuilder.showBottomSheet(
                  context,
                  (context) => CommentBottomSheet(
                    postId: postId,
                    blogId: blogId,
                    publishTime: _postDetailData!.post!.publishTime,
                  ),
                  enableDrag: false,
                  backgroundColor: ChewieTheme.getBackground(context),
                );
              },
            ),
          ),
        ),
      if (!isTablet)
        ItemBuilder.buildTitle(
          context,
          title: appLocalizations.moreRecommend,
          bottomMargin: 12,
          topMargin: 24,
        ),
    ];
  }

  Future<void> jumpToComment() async {
    final visibleContext = commentKey.currentContext;
    if (visibleContext != null) {
      await Scrollable.ensureVisible(
        visibleContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final controller = _scrollController.hasClients
        ? _scrollController
        : _tabletScrollController.hasClients
            ? _tabletScrollController
            : null;
    if (controller == null) return;

    // SliverList builds lazily, so a long article can leave the comment
    // anchor without a context. Move by less than one viewport until the
    // anchor is materialized, then align it normally.
    for (var step = 0; step < 80 && mounted; step++) {
      final anchorContext = commentKey.currentContext;
      if (anchorContext != null) {
        await Scrollable.ensureVisible(
          anchorContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      if (!controller.hasClients) return;
      final position = controller.position;
      final target = min(
        position.maxScrollExtent,
        position.pixels + position.viewportDimension * 0.8,
      );
      if (target <= position.pixels + 0.5) return;
      await controller.animateTo(
        target,
        duration: const Duration(milliseconds: 45),
        curve: Curves.linear,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  _buildEggTitle(String tag, String title) {
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 8),
              child: RoundIconTextButton(
                text: tag,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                background: ChewieColors.biliPinkPrimaryColor,
                radius: 4,
              ),
            ),
          ),
          TextSpan(
            text: title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.apply(fontSizeDelta: -1),
          ),
        ],
      ),
    );
  }

  _buildRichIconTextButton({
    required Widget icon,
    required String text,
    double spacing = 2,
  }) {
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: EdgeInsets.only(right: spacing),
              child: icon,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<UserBag> getUserBag() async {
    var value = await PostApi.getUserBag(postId: postId, blogId: blogId);
    return UserBag.fromJson(value['data']);
  }

  _buildEggContent() {
    ReturnGift? gift = _getReturnGift();
    ReturnContent? returnContent = _getReturnContent();
    if (gift == null) return emptyWidget;
    var bodySmall = Theme.of(context).textTheme.bodySmall;
    var labelSmall = Theme.of(context).textTheme.labelSmall;
    var coinCount = _giftInfoData!.userBag.coin;
    int liangpiaoCount = 0;
    var currentGifts = _giftInfoData!.userBag.gifts
        .where((element) => element.id == LIANGPIAO_GIFTID);
    if (currentGifts.isNotEmpty) {
      liangpiaoCount = currentGifts.first.count ?? 0;
    }
    Widget promotionWidget = StringUtil.isNotEmpty(gift.promotion)
        ? Container(
            color: Colors.transparent,
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: _buildRichIconTextButton(
              icon: RotatedBox(
                quarterTurns: 2,
                child: ChewieIcon(
                  LoftifyIcons.quote,
                  size: 16,
                  color: labelSmall?.color,
                ),
              ),
              text: gift.promotion!,
            ),
          )
        : emptyWidget;
    List<Widget> topWidgets = [
      const SizedBox(height: 16),
      Center(
        child: ItemBuilder.buildTextDivider(
            context: context,
            text:
                "$_giftTypeString${(gift.unlockCount ?? 0) > 0 ? "(${appLocalizations.unlockCount(gift.unlockCount!)})" : ""}"),
      ),
      const SizedBox(height: 20),
      _buildEggTitle(
          returnContent == null
              ? "$_giftTypeString${appLocalizations.preview}$_giftPreviewDescription"
              : "${appLocalizations.unlocked}$_giftTypeString$_giftPreviewDescription",
          gift.title ?? ""),
      promotionWidget,
    ];
    if (returnContent == null) {
      topWidgets.addAll(
        [
          if (StringUtil.isNotEmpty(gift.digest))
            Container(
              color: Colors.transparent,
              padding:
                  const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              child: Text(
                "${gift.digest!}...",
                style: bodySmall?.apply(fontSizeDelta: 2),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: RoundIconTextButton(
              text: "$_giftCost${appLocalizations.unlockGift}",
              background: Theme.of(context).primaryColor,
              onPressed: () async {
                presentAndGetGift() async {
                  var value = await PostApi.presentGift(
                    postId: _postDetailData!.post!.id,
                    blogId: blogId,
                    giftId: _giftCostId,
                    count: 1,
                    myBlogId: _myBlogId,
                  );
                  if (value['code'] != 200 || value['ok'] != true) {
                    IToast.showTop(value['msg']);
                  } else {
                    int returnGiftId = value['data']['returnGiftId'];
                    var returnGiftData = await PostApi.getMyReturnGift(
                      postId: _postDetailData!.post!.id,
                      blogId: blogId,
                      giftId: returnGiftId,
                    );
                    if (returnGiftData['code'] != 200 ||
                        returnGiftData['ok'] != true) {
                      IToast.showTop(returnGiftData['msg']);
                    } else {
                      IToast.showTop(appLocalizations.unlockSuccess);
                      var returnGift =
                          ReturnGift.fromJson(returnGiftData['data']['plan']);
                      returnGift.digest = gift.digest;
                      returnGift.defaultSelectedGifts =
                          gift.defaultSelectedGifts;
                      returnGift.imgCount = gift.imgCount;
                      returnGift.wordCount = gift.wordCount;
                      returnGift.unlockCount = (gift.unlockCount ?? 0) + 1;
                      _giftInfoData!.returnGifts.clear();
                      _giftInfoData!.returnGifts.add(returnGift);
                      _postDetailData!.post!.returnContent.add(
                        ReturnContent(
                          id: returnGift.id ?? 0,
                          content: returnGift.content ?? "",
                          images: returnGift.images,
                          planTypeName: returnGift.planType?.name ?? "",
                        ),
                      );
                      _refreshPreviewImage();
                      _refreshGiftDescription();
                      setState(() {});
                    }
                  }
                }

                try {
                  UserBag userBag = await getUserBag();
                  coinCount = userBag.coin;
                  var bag = userBag.bag
                      .where((element) => element.id == LIANGPIAO_GIFTID);
                  if (bag.isNotEmpty) {
                    liangpiaoCount = bag.first.count ?? 0;
                  }
                } catch (e, t) {
                  ILogger.error("Failed to get user bag", e, t);
                  return;
                }

                if (_giftCostId == LIANGPIAO_GIFTID) {
                  if (liangpiaoCount > 0) {
                    DialogBuilder.showConfirmDialog(
                      context,
                      title: appLocalizations
                          .presentToUnlock(appLocalizations.liangpiao),
                      message: appLocalizations.presentToUnlockMessage(
                          "$liangpiaoCount${appLocalizations.liangpiaoCount}"),
                      onTapConfirm: () async {
                        await presentAndGetGift();
                      },
                    );
                  } else {
                    IToast.showTop(appLocalizations.notEnoughLiangpiao);
                  }
                } else {
                  DialogBuilder.showConfirmDialog(
                    context,
                    title: appLocalizations.presentToUnlock(_giftCost),
                    message: appLocalizations.presentToUnlockMessage(
                        "$coinCount${appLocalizations.coinCount}"),
                    onTapConfirm: () async {
                      await presentAndGetGift();
                    },
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    } else {
      topWidgets.addAll(
        [
          if (StringUtil.isNotEmpty(returnContent.content))
            Container(
              color: Colors.transparent,
              padding:
                  const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              child: SelectableAreaWrapper(
                focusNode: FocusNode(),
                child: Text(
                  returnContent.content,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.apply(fontSizeDelta: 3, heightDelta: 0.3),
                ),
              ),
            ),
          if (isArticle && _previewImages.isNotEmpty)
            _buildImageList(_getImageIllusts().length, 16),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topWidgets,
    );
  }

  _buildUserRow() {
    bool hasAvatarBox =
        (_postDetailData!.post?.blogInfo!.bigAvaImg ?? "").isNotEmpty;
    return ClickableWrapper(
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(
            left: 16,
            right: ResponsiveUtil.isLandscapeLayout() ? 10 : 16,
            top: 10,
            bottom: 10),
        child: Row(
          children: [
            ItemBuilder.buildAvatar(
              context: context,
              avatarBoxImageUrl:
                  _postDetailData!.post?.blogInfo!.avatarBoxImage ?? "",
              imageUrl: _postDetailData!.post?.blogInfo!.bigAvaImg ?? "",
              tagPrefix: "postDetailScreen${_postDetailData!.post!.id}",
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: hasAvatarBox
                    ? MainAxisAlignment.spaceEvenly
                    : MainAxisAlignment.start,
                children: [
                  ItemBuilder.buildCopyable(
                    context,
                    toastText: appLocalizations.haveCopiedNickName,
                    text: _postDetailData!.post?.blogInfo!.blogNickName,
                    child: Text(
                      _postDetailData!.post?.blogInfo!.blogNickName ?? "",
                      style: Theme.of(context).textTheme.titleSmall?.apply(
                            fontWeightDelta: 2,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasAvatarBox) const SizedBox(height: 3),
                  Text(
                    "${TimeUtil.formatTimestamp(_postDetailData!.post?.publishTime ?? 0)} · ${StringUtil.isNotEmpty(_postDetailData!.post?.ipLocation) ? _postDetailData!.post?.ipLocation : ""} · ${_postDetailData!.post?.postCount?.postHot ?? 0}${appLocalizations.hotCount}",
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
            if (_myBlogId != _postDetailData!.post!.blogId)
              LoftifyItemBuilder.buildFramedDoubleButton(
                context: context,
                isFollowed: _postDetailData!.followed == 1 ? true : false,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  UserApi.followOrUnfollow(
                          isFollow: !(_postDetailData!.followed == 1),
                          blogId: _postDetailData!.post!.blogId,
                          blogName: _postDetailData!.post!.blogInfo!.blogName)
                      .then((value) {
                    if (value['meta']['status'] != 200) {
                      IToast.showTop(
                          value['meta']['desc'] ?? value['meta']['msg']);
                    } else {
                      _postDetailData!.followed =
                          !(_postDetailData!.followed == 1) ? 1 : 0;
                      setState(() {});
                    }
                  });
                },
              ),
            if (ResponsiveUtil.isLandscapeLayout()) ..._buildButtons(),
          ],
        ),
      ),
    );
  }

  List<String> _getArticleImages() {
    List<String> imageUrls =
        HtmlUtil.extractImagesFromHtml(_postDetailData!.post!.content);
    return imageUrls;
  }

  List<dynamic> _getImages() {
    String photoJson = _postDetailData!.post!.photoLinks;
    if (StringUtil.isEmpty(photoJson)) photoJson = "[]";
    List<PhotoLink> photoLinks = StringUtil.parseJsonList(photoJson)
        .map((e) => PhotoLink.fromJson(e))
        .toList();
    int previewIndex = photoLinks.length;
    for (var e in _previewImages) {
      photoLinks.add(PhotoLink(
        orign: e.baseImage,
        oh: e.oh,
        ow: e.ow,
        raw: e.baseImage,
        middle: e.baseImage,
        small: e.baseImage,
        rh: e.oh,
        rw: e.ow,
      ));
    }
    return [photoLinks, previewIndex];
  }

  _buildImageList([int startIndex = 0, double horizontalPaddding = 12]) {
    late List<PhotoLink> photoLinks;
    late int previewIndex;
    [photoLinks, previewIndex] = _getImages();
    String photoCaptionJson = _postDetailData!.post!.photoCaptions;
    if (StringUtil.isEmpty(photoCaptionJson)) photoCaptionJson = "[]";
    List<String> captions = StringUtil.parseJsonList(photoCaptionJson)
        .map((e) => e.toString())
        .toList();
    double heightMinThreshold = 200;
    // double heightMaxThreshold = MediaQuery.sizeOf(context).height - 340;
    double heightMaxThreshold = 600;
    double preferedHeight = 0;
    double preferedWidth = MediaQuery.sizeOf(context).width;
    preferedHeight =
        (photoLinks[0].oh * 1.0) * preferedWidth / photoLinks[0].ow;
    preferedHeight =
        max(heightMinThreshold, min(preferedHeight, heightMaxThreshold));
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          key: photoLinks.length > 1 ? _imageSwiperViewportKey : null,
          height: preferedHeight,
          child: Swiper(
            controller: _swiperController,
            loop: false,
            control: null,
            itemBuilder: (BuildContext context, int index) {
              double trueHeight =
                  (photoLinks[index].oh / photoLinks[index].ow) * preferedWidth;
              trueHeight = max(trueHeight, 50);
              double padding = (preferedHeight - trueHeight) / 2;
              padding = max(padding, 0);
              String imageUrl = Utils.getUrlByQuality(photoLinks[index].middle,
                  HiveUtil.getImageQuality(HiveUtil.postDetailImageQualityKey));
              String tagPrefix = StringUtil.getRandomString();
              return Container(
                width: preferedWidth,
                height: trueHeight,
                padding: EdgeInsets.symmetric(vertical: padding),
                margin: EdgeInsets.only(
                  left: horizontalPaddding,
                  right: horizontalPaddding,
                  bottom: 18,
                ),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        RouteUtil.pushDialogRoute(
                          context,
                          showClose: false,
                          fullScreen: true,
                          useFade: true,
                          opaque: false,
                          HeroPhotoViewScreen(
                            imageUrls: _getIllusts()
                                .map((illust) => illust.url)
                                .toList(),
                            initIndex: startIndex + index,
                            captions: captions,
                            tagPrefix: tagPrefix,
                            mainColors: mainColors,
                            useMainColor: true,
                            onIndexChanged: (index) {
                              _currentIndex = index + 1;
                              _swiperController.move(index);
                              setState(() {});
                            },
                            onDownloadSuccess: () {
                              _handleDownloadSuccessAction();
                            },
                          ),
                        );
                      },
                      child: Container(
                        width: preferedWidth,
                        height: trueHeight,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Hero(
                            tag: Utils.getHeroTag(
                              tagPrefix: tagPrefix,
                              url: imageUrl,
                            ),
                            child: ChewieItemBuilder.buildCachedImage(
                              context: context,
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (index >= previewIndex)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: ItemBuilder.buildTranslucentTag(
                          context,
                          text: _isCatutu
                              ? appLocalizations.eraseBlur
                              : _giftTypeString,
                          opacity: 0.5,
                        ),
                      ),
                  ],
                ),
              );
            },
            itemCount: photoLinks.length,
            pagination: photoLinks.length > 1
                ? SwiperPagination(
                    margin: const EdgeInsets.only(top: 15),
                    builder: DotSwiperPaginationBuilder(
                      color: Colors.grey[300],
                      activeColor: Theme.of(context).primaryColor,
                      size: 4,
                      activeSize: 6,
                    ),
                  )
                : null,
            onIndexChanged: (index) {
              setState(() {
                _currentIndex = index + 1;
              });
            },
          ),
        ),
        if (photoLinks.length > 1)
          Positioned(
            top: 6,
            right: 18,
            child: ItemBuilder.buildTranslucentTag(
              context,
              text: '$_currentIndex/${photoLinks.length}',
              opacity: 0.5,
            ),
          ),
        if (photoLinks.length > 1 && ResponsiveUtil.isDesktop())
          Positioned(
            left: 16,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _currentIndex == 1
                    ? Colors.black.withOpacity(0.1)
                    : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: GestureDetector(
                onTap: () {
                  _swiperController.previous();
                },
                child: ClickableWrapper(
                  clickable: _currentIndex != 1,
                  child: const ChewieIcon(
                    LoftifyIcons.previous,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        if (photoLinks.length > 1 && ResponsiveUtil.isDesktop())
          Positioned(
            right: 16,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _currentIndex == photoLinks.length
                    ? Colors.black.withOpacity(0.1)
                    : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: GestureDetector(
                onTap: () {
                  _swiperController.next();
                },
                child: ClickableWrapper(
                  clickable: _currentIndex != photoLinks.length,
                  child: const ChewieIcon(
                    LoftifyIcons.next,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  _hasImage() {
    return _postDetailData == null
        ? !isArticle
        : _postDetailData!.post!.photoLinks.isNotEmpty;
  }

  _hasArticleImage() {
    return _postDetailData == null
        ? false
        : HtmlUtil.extractImagesFromHtml(_postDetailData!.post!.content)
            .isNotEmpty;
  }

  List<Illust> _getImageIllusts() {
    List<Illust> illusts = [];
    List<PhotoLink> photoLinks = _getImages()[0];
    for (int i = 0; i < photoLinks.length; i++) {
      PhotoLink e = photoLinks[i];
      String rawUrl = Utils.getUrlByQuality(e.middle, ImageQuality.raw);
      illusts.add(
        Illust(
          extension: FileUtil.extractFileExtensionFromUrl(rawUrl),
          originalName: FileUtil.extractFileNameFromUrl(rawUrl),
          blogId: _postDetailData!.post!.blogId,
          blogLofterId: _postDetailData!.post!.blogInfo!.blogName,
          blogNickName: _postDetailData!.post!.blogInfo!.blogNickName,
          postId: _postDetailData!.post!.id,
          part: i,
          url: rawUrl,
          postTitle: _postDetailData!.post!.title,
          postDigest: _postDetailData!.post!.digest,
          tags: _postDetailData!.post?.tagList ?? [],
          publishTime: _postDetailData!.post!.publishTime,
        ),
      );
    }
    return illusts;
  }

  List<Illust> _getArticleIllusts() {
    List<Illust> illusts = [];
    List<String> imageUrls = _getArticleImages();
    for (int i = 0; i < imageUrls.length; i++) {
      String rawUrl = Utils.getUrlByQuality(imageUrls[i], ImageQuality.raw);
      illusts.add(
        Illust(
          extension: FileUtil.extractFileExtensionFromUrl(rawUrl),
          originalName: FileUtil.extractFileNameFromUrl(rawUrl),
          blogId: _postDetailData!.post!.blogId,
          blogLofterId: _postDetailData!.post!.blogInfo!.blogName,
          blogNickName: _postDetailData!.post!.blogInfo!.blogNickName,
          postId: _postDetailData!.post!.id,
          part: i,
          url: rawUrl,
          postTitle: _postDetailData!.post!.title,
          postDigest: _postDetailData!.post!.digest,
          tags: _postDetailData!.post?.tagList ?? [],
          publishTime: _postDetailData!.post!.publishTime,
        ),
      );
    }
    return illusts;
  }

  List<Illust> _getIllusts() {
    List<Illust> illusts = [];
    if (isArticle) {
      illusts.addAll(_getArticleIllusts());
      illusts.addAll(_getImageIllusts());
    } else {
      illusts.addAll(_getImageIllusts());
    }
    return illusts;
  }

  bool _hasContent() {
    final title = StringUtil.clearBlank(_postDetailData!.post!.title);
    try {
      final content = StringUtil.clearBlank(
        HtmlUtil.extractTextFromHtml(_postDetailData!.post!.content),
      );
      return title.isNotEmpty || content.isNotEmpty;
    } catch (error, stackTrace) {
      ILogger.error('Failed to inspect post content', error, stackTrace);
      return title.isNotEmpty || _postDetailData!.post!.content.isNotEmpty;
    }
  }

  Widget _buildPostContent() {
    return PostContentSection(
      title: _postDetailData!.post!.title,
      content: _postDetailData!.post!.content,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.apply(fontSizeDelta: 3, heightDelta: 0.3),
      onDownloadSuccess: _handleDownloadSuccessAction,
    );
  }

  _handleDownloadSuccessAction() {
    Utils.handleDownloadSuccessAction(onUnlike: () {
      _handleLike(isLike: false);
    }, onUnrecommend: () {
      _handleRecommend(isRecommend: false);
    });
  }

  _buildGrainItem({Key? key}) {
    return ClickableWrapper(
      key: key,
      child: GestureDetector(
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            GrainDetailScreen(
              grainId: _postDetailData!.grainInfo!.id,
              blogId: _postDetailData!.grainInfo!.userId,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).cardColor,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ChewieIcon(
                    LoftifyIcons.grain,
                    size: 16,
                    color: ChewieColors.getHotTagTextColor(context),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    appLocalizations.includedIn,
                    style: Theme.of(context).textTheme.titleSmall?.apply(
                        fontSizeDelta: -1,
                        fontWeightDelta: 2,
                        color: ChewieColors.getHotTagTextColor(context)),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      _postDetailData!.grainInfo!.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.apply(fontSizeDelta: -1),
                    ),
                  ),
                  ChewieIcon(
                    LoftifyIcons.next,
                    size: 16,
                    color: Theme.of(context).textTheme.labelSmall?.color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildCollectionItem({Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ChewieIcon(
                LoftifyIcons.collection,
                size: 16,
                color: Theme.of(context).textTheme.labelSmall?.color,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  _postDetailData!.post!.postCollection!.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.apply(fontSizeDelta: -1),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  CollectionApi.subscribeOrUnSubscribe(
                    collectionId: collectionId,
                    isSubscribe:
                        !(_postDetailData!.post!.postCollection!.subscribed),
                  ).then((value) {
                    if (value['meta']['status'] != 200) {
                      IToast.showTop(
                          value['meta']['desc'] ?? value['meta']['msg']);
                    } else {
                      _postDetailData!.post!.postCollection!.subscribed =
                          !(_postDetailData!.post!.postCollection!.subscribed);
                      setState(() {});
                    }
                  });
                },
                child: ClickableWrapper(
                  child: Text(
                    _postDetailData!.post!.postCollection!.subscribed
                        ? appLocalizations.subscribed
                        : appLocalizations.subscribeCollection,
                    style: Theme.of(context).textTheme.titleSmall?.apply(
                          fontSizeDelta: -2,
                          fontWeightDelta: 2,
                          color: _postDetailData!
                                  .post!.postCollection!.subscribed
                              ? Theme.of(context).textTheme.labelSmall?.color
                              : Theme.of(context).primaryColor,
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildButton(
                  text: _postDetailData!.post!.pos > 1
                      ? appLocalizations.prePost
                      : appLocalizations.atFirstPost,
                  disabled: _postDetailData!.post!.pos <= 1,
                  onTap: () {
                    if (_postDetailData!.post!.pos > 1) {
                      setState(() {});
                      _fetchPreOrNextPost(isPre: true);
                    } else {
                      IToast.showTop(appLocalizations.haveAtFirstPost);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildButton(
                  text: appLocalizations.catelog,
                  onTap: showCollectionBottomSheet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildButton(
                  text: _postDetailData!.post!.pos <
                          _postDetailData!.post!.postCollection!.postCount
                      ? appLocalizations.nextPost
                      : appLocalizations.atLastPost,
                  disabled: _postDetailData!.post!.pos >=
                      _postDetailData!.post!.postCollection!.postCount,
                  onTap: () {
                    if (_postDetailData!.post!.pos <
                        _postDetailData!.post!.postCollection!.postCount) {
                      setState(() {});
                      _fetchPreOrNextPost(isPre: false);
                    } else {
                      IToast.showTop(appLocalizations.haveAtLastPost);
                    }
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  _buildButton({String? text, Function()? onTap, bool disabled = false}) {
    return ClickableWrapper(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ChewieTheme.getBackground(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text ?? "",
            style: disabled
                ? Theme.of(context).textTheme.titleSmall?.apply(
                    color: Theme.of(context).textTheme.labelSmall?.color)
                : Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ),
    );
  }

  _buildTagList() {
    Map<String, TagType> tags = {};
    if (_previewImages.isNotEmpty) {
      if (_isCatutu) {
        tags.addAll({appLocalizations.eraseBlur: TagType.catutu});
      } else {
        tags.addAll({_giftTypeString: TagType.egg});
      }
    }
    _postDetailData!.post?.tagList.forEach((e) {
      tags[e] = _postDetailData!.post!.tagRankList.contains(e)
          ? TagType.hot
          : TagType.normal;
    });
    List<MapEntry<String, TagType>> sortedTags = tags.entries.toList();
    sortedTags.sort((a, b) => b.value.index.compareTo(a.value.index));
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      padding: EdgeInsets.only(
          left: 16, right: 16, top: _hasContent() ? 8 : 16, bottom: 8),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.start,
        children: List.generate(sortedTags.length, (index) {
          return MouseRegion(
            cursor: sortedTags[index].value != TagType.egg
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: ItemBuilder.buildTagItem(
              context,
              sortedTags[index].key,
              sortedTags[index].value,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMarkInfo() {
    var color = Theme.of(context).textTheme.labelSmall?.color;
    bool showMark = StringUtil.isNotEmpty(_postDetailData!.post!.imageMarkInfo);
    bool showReBlog = _postDetailData!.post!.imageReblogMark == 1 &&
        StringUtil.isNotEmpty(_postDetailData!.post!.reblogAuthorFromEmbed);
    bool showCopyright = _postDetailData!.post!.cctype > 0;
    if (showMark || showCopyright || showReBlog) {
      return Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showCopyright)
                    ItemBuilder.buildIconTextButton(
                      context,
                      text: Copyright.fromInt(_postDetailData!.post!.cctype)
                          .label,
                      start: true,
                      color: color,
                      spacing: 6,
                      icon: ChewieIcon(
                        LoftifyIcons.copyright,
                        size: 16,
                        color: color,
                      ),
                    ),
                  if (showCopyright && (showMark || showReBlog))
                    const SizedBox(height: 4),
                  if (showMark)
                    ItemBuilder.buildIconTextButton(
                      context,
                      text: _postDetailData!.post!.imageMarkInfo,
                      start: true,
                      color: color,
                      spacing: 6,
                      icon: ChewieIcon(
                        LoftifyIcons.magic,
                        size: 16,
                        color: color,
                      ),
                    ),
                  if (showMark && showReBlog) const SizedBox(height: 4),
                  if (showReBlog)
                    ItemBuilder.buildIconTextButton(
                      context,
                      text: appLocalizations.reblogFrom(
                          _postDetailData!.post!.reblogAuthorFromEmbed),
                      spacing: 6,
                      start: true,
                      color: color,
                      icon: ChewieIcon(
                        LoftifyIcons.reblog,
                        size: 16,
                        color: color,
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return emptyWidget;
    }
  }

  Widget _buildOperationRow() {
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 16, top: 8, bottom: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Stack(
                children: [
                  LoftifyItemBuilder.buildLikedLottieButton(
                    context,
                    showCount: true,
                    iconSize: 52,
                    animationController: _likeController,
                    likeCount: _postDetailData!.post!.postCount!.favoriteCount,
                    isLiked: _postDetailData!.liked,
                    onTap: () async {
                      _handleLike();
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 42),
                    child: LoftifyItemBuilder.buildLottieSharedButton(
                      context,
                      showCount: true,
                      iconSize: 52,
                      shareCount: _postDetailData!.post!.postCount!.shareCount,
                      isShared: _postDetailData!.shared,
                      animationController: _shareController,
                      onTap: () async {
                        _handleRecommend();
                      },
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
          Positioned(
            top: 12,
            right: 0,
            child: ItemBuilder.buildIconTextButton(
              context,
              text: _postDetailData!.subscribedNotNull
                  ? appLocalizations.favorited
                  : appLocalizations.favorite,
              icon: ChewieIcon(
                LoftifyIcons.bookmark,
                size: 28,
                color: _postDetailData!.subscribedNotNull
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              direction: Axis.vertical,
              spacing: 0,
              style: Theme.of(context).textTheme.labelSmall,
              onTap: () {
                BottomSheetBuilder.showBottomSheet(
                  context,
                  enableDrag: false,
                  (context) => SubscribePostBottomSheet(
                    postId: postId,
                    blogId: blogId,
                    onConfirm: (folderIds) {
                      _handleSubscribe(folderIds);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingOperationOverlay() {
    if (_postDetailData?.post == null) return const SizedBox.shrink();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFloatingOperationBarVisibility();
    });
    return Positioned(
      right: 0,
      bottom: 0,
      child: ValueListenableBuilder<bool>(
        valueListenable: _floatingOperationBarVisible,
        builder: (context, showFloatingBar, child) {
          final visible = _isPostContentReady && showFloatingBar;
          return SafeArea(
            top: false,
            left: false,
            minimum: const EdgeInsets.only(right: 12, bottom: 10),
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(1.18, 0),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: _buildFloatingOperationBar(),
      ),
    );
  }

  Widget _buildFloatingOperationBar() {
    final isDark = ColorUtil.isDark(context);
    final backgroundColor =
        isDark ? Theme.of(context).colorScheme.surface : Colors.white;
    return Material(
      color: backgroundColor,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.34 : 0.18),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.09),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 54,
              height: 52,
              child: DetailActionButton(
                label: _postDetailData!.post!.postCount!.favoriteCount > 0
                    ? StringUtil.formatCount(
                        _postDetailData!.post!.postCount!.favoriteCount,
                      )
                    : appLocalizations.like,
                onTap: _handleLike,
                icon: IgnorePointer(
                  child: SizedBox.square(
                    dimension: 28,
                    child: OverflowBox(
                      maxWidth: 40,
                      maxHeight: 40,
                      child: LoftifyItemBuilder.buildLikedLottieButton(
                        context,
                        showCount: false,
                        iconSize: 40,
                        animationController: _likeController,
                        isLiked: _postDetailData!.liked,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 54,
              height: 52,
              child: DetailActionButton(
                label: _postDetailData!.post!.postCount!.shareCount > 0
                    ? StringUtil.formatCount(
                        _postDetailData!.post!.postCount!.shareCount,
                      )
                    : appLocalizations.recommend,
                onTap: _handleRecommend,
                icon: IgnorePointer(
                  child: SizedBox.square(
                    dimension: 28,
                    child: OverflowBox(
                      maxWidth: 40,
                      maxHeight: 40,
                      child: LoftifyItemBuilder.buildLottieSharedButton(
                        context,
                        showCount: false,
                        iconSize: 40,
                        isShared: _postDetailData!.shared,
                        animationController: _shareController,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 54,
              height: 52,
              child: DetailActionButton(
                label: _postDetailData!.post!.postCount!.responseCount > 0
                    ? StringUtil.formatCount(
                        _postDetailData!.post!.postCount!.responseCount,
                      )
                    : appLocalizations.comment,
                icon: const ChewieIcon(LoftifyIcons.comment),
                onTap: jumpToComment,
              ),
            ),
            SizedBox(
              width: 54,
              height: 52,
              child: DetailActionButton(
                label: _postDetailData!.subscribedNotNull
                    ? appLocalizations.favorited
                    : appLocalizations.favorite,
                icon: ChewieIcon(
                  LoftifyIcons.bookmark,
                  color: _postDetailData!.subscribedNotNull
                      ? Theme.of(context).primaryColor
                      : null,
                ),
                onTap: () {
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    enableDrag: false,
                    (context) => SubscribePostBottomSheet(
                      postId: postId,
                      blogId: blogId,
                      onConfirm: _handleSubscribe,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComments(List<Comment> comments, {Key? key}) {
    return Column(
      key: key,
      children: [
        for (final comment in comments)
          LoftifyItemBuilder.buildCommentRow(
            context,
            comment,
            writerId: blogId,
            onL2CommentTap: (comment) {
              HapticFeedback.mediumImpact();
              _fetchL2Comments(comment);
            },
          ),
      ],
    );
  }

  Widget _buildRecommendFlow({bool sliver = true}) {
    Widget list = SliverPadding(
      padding:
          EdgeInsets.only(top: sliver ? 10 : 0, left: sliver ? 8 : 5, right: 8),
      sliver: SliverWaterfallFlow(
        gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          mainAxisSpacing: 12,
          crossAxisSpacing: 6,
          maxCrossAxisExtent: 300,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return GestureDetector(
              child: RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
                context,
                _recommendPosts[index],
                showMoreButton: true,
                // onShieldContent: () {
                //   _recommendPosts.remove(_recommendPosts[index]);
                //   setState(() {});
                // },
                // onShieldTag: (tag) {
                //   _recommendPosts.remove(_recommendPosts[index]);
                //   setState(() {});
                // },
                // onShieldUser: () {
                //   _recommendPosts.remove(_recommendPosts[index]);
                //   setState(() {});
                // },
              ),
            );
          },
          childCount: _recommendPosts.length,
        ),
      ),
    );
    if (sliver) {
      return list;
    } else {
      return Container(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: EasyRefresh.builder(
          onRefresh: _onRefresh,
          onLoad: _recommendNoMore ? null : _onLoad,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) => CustomScrollView(
            physics: physics,
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: ItemBuilder.buildTitle(
                  context,
                  title: appLocalizations.moreRecommend,
                  bottomMargin: 16,
                  topMargin: 16,
                  left: 8,
                ),
              ),
              list,
            ],
          ),
        ),
      );
    }
  }

  hasCollection() {
    return _postDetailData != null &&
        _postDetailData!.post!.postCollection != null;
  }

  hasGrain() {
    return _postDetailData != null && _postDetailData!.grainInfo != null;
  }

  showCollectionBottomSheet() {
    BottomSheetBuilder.showBottomSheet(
      context,
      (context) => CollectionBottomSheet(
        postCollection: _postDetailData!.post!.postCollection!,
        collectionId: collectionId,
        postId: postId,
        blogId: blogId,
        blogName: blogName,
      ),
      enableDrag: false,
    );
  }

  void setDownloadState(DownloadState state, {bool recover = true}) {
    switch (state) {
      case DownloadState.none:
        downloadIcon = ChewieIcon(
          LoftifyIcons.download,
          color: Theme.of(rootContext).iconTheme.color,
        );
        break;
      case DownloadState.loading:
        downloadIcon = Container(
          width: 20,
          height: 20,
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(
            color: Theme.of(context).iconTheme.color,
            strokeWidth: 2,
          ),
        );
        break;
      case DownloadState.succeed:
        downloadIcon = ChewieIcon(
          LoftifyIcons.check,
          color: ChewieTheme.successColor,
        );
        break;
      case DownloadState.failed:
        downloadIcon = ChewieIcon(
          LoftifyIcons.warning,
          color: ChewieTheme.errorColor,
        );
        break;
    }
    downloadState = state;
    if (mounted) setState(() {});
    if (recover) {
      final recoveryPostId = postId;
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted || postId != recoveryPostId) return;
        setDownloadState(DownloadState.none, recover: false);
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      titleWidget: Text(
        appLocalizations.postDetail,
        style: Theme.of(context).textTheme.titleLarge?.apply(
              fontWeightDelta: 2,
            ),
      ),
      actions: _isPostContentReady
          ? [
              if (hasCollection())
                ClickableWrapper(
                  child: GestureDetector(
                    onTap: showCollectionBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        children: [
                          ChewieIcon(
                            LoftifyIcons.collection,
                            size: 14,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "${appLocalizations.collection} ${_postDetailData!.post!.pos}/${_postDetailData!.post!.postCollection!.postCount}",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.apply(fontSizeDelta: -3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ..._buildButtons(),
            ]
          : const [],
    );
  }

  List<Widget> _buildButtons() {
    bool showDownloadButton =
        controlProvider.globalControl.showDownloadButton &&
            (_hasImage() ||
                _hasArticleImage() &&
                    ChewieHiveUtil.getBool(HiveUtil.showDownloadKey,
                        defaultValue: true));
    return [
      const SizedBox(width: 5),
      if (showDownloadButton) ...[
        SizedBox.square(
          dimension: 44,
          child: CircleIconButton(
            icon: downloadIcon,
            padding: EdgeInsets.zero,
            tooltip: appLocalizations.download,
            onTap: () {
              _handleDownloadAll();
            },
          ),
        ),
        const SizedBox(width: 5),
      ],
      ChewieIconButton(
        icon: LoftifyIcons.moreVertical,
        tooltip: appLocalizations.moreInfo,
        foregroundColor: Theme.of(context).iconTheme.color,
        onPressed: () {
          BottomSheetBuilder.showContextMenu(context, _buildMoreButtons());
        },
      ),
    ];
  }

  _buildMoreButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.copyLink,
          iconData: LoftifyIcons.copy,
          onPressed: () {
            ChewieUtils.copy(
              context,
              LoftifyUriUtil.getPostUrlByPermalink(
                _postDetailData!.post!.blogInfo!.blogName,
                _postDetailData!.post!.permalink,
              ),
            );
          },
        ),
        FlutterContextMenuItem(
          appLocalizations.visitOriginalPost,
          iconData: LoftifyIcons.originalPost,
          onPressed: () {
            UriUtil.openInternal(
              context,
              LoftifyUriUtil.getPostUrlById(
                blogName,
                postId,
                blogId,
              ),
              processUri: false,
            );
          },
        ),
        FlutterContextMenuItem(appLocalizations.openWithBrowser,
            iconData: LoftifyIcons.openExternal, onPressed: () {
          UriUtil.openExternal(
            LoftifyUriUtil.getPostUrlByPermalink(
              _postDetailData!.post!.blogInfo!.blogName,
              _postDetailData!.post!.permalink,
            ),
          );
        }),
        FlutterContextMenuItem(
          appLocalizations.shareToOtherApps,
          iconData: LoftifyIcons.share,
          onPressed: () {
            UriUtil.share(
              LoftifyUriUtil.getPostUrlByPermalink(
                _postDetailData!.post!.blogInfo!.blogName,
                _postDetailData!.post!.permalink,
              ),
            );
          },
        ),
      ],
    );
  }
}
