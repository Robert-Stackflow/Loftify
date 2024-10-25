import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:card_swiper/card_swiper.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:loftify/Api/post_api.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/grain_response.dart';
import 'package:loftify/Models/illust.dart';
import 'package:loftify/Models/message_response.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/show_case_response.dart';
import 'package:loftify/Resources/colors.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/file_util.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/ilogger.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Widgets/BottomSheet/collection_bottom_sheet.dart';
import 'package:loftify/Widgets/BottomSheet/comment_bottom_sheet.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:waterfall_flow/waterfall_flow.dart';
import 'package:window_manager/window_manager.dart';

import '../../Api/collection_api.dart';
import '../../Api/recommend_api.dart';
import '../../Models/search_response.dart';
import '../../Resources/theme.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/constant.dart';
import '../../Utils/lottie_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/Custom/hero_photo_view_screen.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/general_post_item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';
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
  static const String routeName = "/post/detail";

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WindowListener {
  @override
  bool get wantKeepAlive => true;
  PostDetailData? _postDetailData;
  List<PreviewImage> _previewImages = [];
  final SwiperController _swiperController = SwiperController();
  int _currentIndex = 1;
  final List<PostListItem> _recommendPosts = [];
  int _currentPage = 0;
  int _myBlogId = 0;
  bool _loadingInfo = false;
  bool _loadingRecommend = false;
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
  final ResizableController _resizableController = ResizableController();
  late dynamic downloadIcon;
  DownloadState downloadState = DownloadState.none;
  bool isArticle = false;
  InitPhase _inited = InitPhase.haveNotConnected;

  @override
  void initState() {
    isArticle = widget.isArticle;
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    _scrollController = ScrollController();
    windowManager.addListener(this);
    super.initState();
    setDownloadState(DownloadState.none, recover: false);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Future.delayed(const Duration(milliseconds: 500), initLottie);
      initLottie();
      if (isArticle) {
        Future.delayed(const Duration(milliseconds: 500), initData);
      } else {
        initData();
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - kLoadExtentOffset) {
        _onLoad();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _doubleTapLikeController.dispose();
    _shareController.dispose();
    _likeController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  initLottie() {
    _doubleTapLikeController =
        AnimationController(duration: const Duration(seconds: 3), vsync: this);
    doubleTapLikeWidget = LottieUtil.load(
      LottieUtil.likeDoubleClickLight,
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
    setState(() {});
    _initParams();
    _fetchPostDetail();
    _fetchRecommendPosts();
    setState(() {});
    _myBlogId = await HiveUtil.getUserId();
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
        postId = Utils.hexToInt(widget.meta!['postId']!);
        blogId = Utils.hexToInt(widget.meta!['blogId']!);
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
    int userId = await HiveUtil.getUserId();
    PostApi.uploadHistory(
      postId: postId,
      blogId: blogId,
      userId: userId,
      postType: _postDetailData!.post!.type,
      collectionId: _postDetailData!.post!.collectionId,
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
      var t1 = await PostApi.getDetail(
        postId: postId,
        blogId: blogId,
        blogName: blogName,
      ).then((value) {
        if (value['meta']['status'] != 200) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
          return IndicatorResult.fail;
        } else {
          _postDetailData =
              PostDetailData.fromJson(value['response']['posts'][0]);
          _updateMeta(swipeToFirst: false);
          if (mounted) setState(() {});
          _uploadHistory();
          return IndicatorResult.success;
        }
      });
      var t2 = await _fetchGift();
      await _fetchHotComments();
      _inited = InitPhase.successful;
      return t1 == IndicatorResult.success && t2 == IndicatorResult.success
          ? IndicatorResult.success
          : IndicatorResult.fail;
    } catch (e, t) {
      _inited = InitPhase.failed;
      ILogger.error("Failed to fetch post detail", e, t);
      return IndicatorResult.fail;
    } finally {
      _loadingInfo = false;
      if (mounted) setState(() {});
    }
  }

  _fetchGift() async {
    return await PostApi.getGifts(
      postId: postId,
      blogId: blogId,
    ).then((value) {
      if (value == null) return IndicatorResult.fail;
      if (value['code'] != 200 || value['ok'] != true) {
        IToast.showTop(value['msg']);
        return IndicatorResult.fail;
      } else {
        List<dynamic> gifts = value['data']['returnGifts'] as List;
        _previewImages = [];
        for (var gift in gifts) {
          if (gift['previewImages'] != null) {
            List<dynamic> images = gift['previewImages'] as List;
            for (var image in images) {
              _previewImages.add(PreviewImage.fromJson(image));
            }
            break;
          }
        }
        if (mounted) setState(() {});
        return IndicatorResult.success;
      }
    });
  }

  _fetchHotComments() async {
    return await PostApi.getHotComments(
      postId: postId,
      blogId: blogId,
      postPublishTime: _postDetailData!.post!.publishTime,
    ).then((value) {
      try {
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
        IToast.showTop("评论加载失败");
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
        IToast.showTop("评论加载失败");
        ILogger.error("Failed to load l2 comment", e, t);
        return IndicatorResult.fail;
      } finally {
        currentComment.l2CommentLoading = false;
        if (mounted) setState(() {});
      }
    });
  }

  _fetchPreOrNextPost({required bool isPre}) async {
    if (_loadingInfo) return;
    _loadingInfo = true;
    var t1 = await CollectionApi.getPreOrNextPost(
      isPre: isPre,
      postId: postId,
      blogId: blogId,
      blogName: blogName,
      collectionId: collectionId,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return IndicatorResult.fail;
      } else {
        _postDetailData = PostDetailData.fromJson(value['response'][0]);
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.ease);
        if (_tabletScrollController.hasClients) {
          _tabletScrollController.animateTo(0,
              duration: const Duration(milliseconds: 300), curve: Curves.ease);
        }
        _updateMeta();
        setState(() {});
        _uploadHistory();
        return IndicatorResult.success;
      }
    });
    var t2 = await _fetchGift();
    _loadingInfo = false;
    return t1 == IndicatorResult.success && t2 == IndicatorResult.success
        ? IndicatorResult.success
        : IndicatorResult.fail;
  }

  _fetchRecommendPosts({bool append = true}) async {
    if (_loadingRecommend) return;
    _loadingRecommend = true;
    if (append) _currentPage++;
    return await RecommendApi.getPostRecomend(
      page: _currentPage,
      postId: postId,
      blogId: blogId,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          if (value['code'] != 4009) {
            IToast.showTop(value['msg']);
          }
          return IndicatorResult.fail;
        } else {
          List<dynamic> tmp = value['data']['list'];
          if (append == false) _recommendPosts.clear();
          _recommendPosts
              .addAll(tmp.map((e) => PostListItem.fromJson(e)).toList());
          return IndicatorResult.success;
        }
      } catch (e, t) {
        if (mounted) IToast.showTop("加载失败");
        ILogger.error("Failed to load recommend post", e, t);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loadingRecommend = false;
      }
    });
  }

  _updateMeta({bool swipeToFirst = true}) {
    if (_postDetailData == null) return;
    setState(() {
      isArticle = _postDetailData!.post!.type == 1;
    });
    collectionId = _postDetailData!.post!.postCollection != null
        ? _postDetailData!.post!.postCollection!.id
        : 0;
    postId = _postDetailData!.post!.id;
    blogId = _postDetailData!.post!.blogId;
    blogName = _postDetailData!.post!.blogInfo!.blogName;
    _shareController.value = _postDetailData!.shared == true ? 1 : 0;
    _likeController.value = _postDetailData!.liked == true ? 1 : 0;
    setDownloadState(DownloadState.none, recover: false);
    int count = 3;
    while (count-- > 0) {
      Future.delayed(const Duration(milliseconds: 300),
          () => _likeController.value = _postDetailData!.liked == true ? 1 : 0);
      Future.delayed(
          const Duration(milliseconds: 300),
          () =>
              _shareController.value = _postDetailData!.shared == true ? 1 : 0);
    }
    if (swipeToFirst) {
      setState(() {
        _currentIndex = 1;
        _swiperController.move(0);
      });
    }
    if (_hasImage() && HiveUtil.getBool(HiveUtil.followMainColorKey)) {
      List<PhotoLink> photoLinks = _getImages()[0];
      Utils.getMainColors(
        context,
        photoLinks.map((e) => e.middle).toList(),
      ).then((value) {
        if (mounted) setState(() {});
        mainColors = value;
      });
    } else {
      List<String> imageUrls = _getArticleImages();
      Utils.getMainColors(
        context,
        imageUrls,
      ).then((value) {
        if (mounted) setState(() {});
        mainColors = value;
      });
    }
  }

  _onRefresh() async {
    _currentPage = 0;
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
      backgroundColor: MyTheme.getBackground(context),
      body: _buildBody(),
    );
  }

  _buildBody() {
    switch (_inited) {
      case InitPhase.connecting:
      case InitPhase.haveNotConnected:
        return ItemBuilder.buildLoadingDialog(
          context,
          background: MyTheme.getBackground(context),
        );
      case InitPhase.successful:
        if (_postDetailData != null) {
          return _buildNormalBody();
        } else {
          return ItemBuilder.buildError(
            context: context,
            onTap: initData,
          );
        }
      case InitPhase.failed:
        return ItemBuilder.buildError(
          context: context,
          onTap: initData,
        );
    }
  }

  Widget _buildNormalBody() {
    return ScreenTypeLayout.builder(
      mobile: (context) => EasyRefresh.builder(
        onRefresh: _onRefresh,
        onLoad: _onLoad,
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
    return ScreenTypeLayout.builder(
      mobile: (context) => _buildMobileMainBody(physics),
      tablet: (context) => _buildTabletMainBody(),
    );
  }

  _buildMobileMainBody(ScrollPhysics physics) {
    return CustomScrollView(
      controller: _scrollController,
      physics: physics,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildCommonContent(false),
          ),
        ),
        _buildRecommendFlow(),
      ],
    );
  }

  _buildTabletMainBody() {
    return ResizableContainer(
      direction: Axis.horizontal,
      controller: _resizableController,
      divider: ResizableDivider(
        color: Theme.of(context).dividerColor,
        thickness: ResponsiveUtil.isMobile() ? 2 : 1,
        size: 6,
        onHoverEnter: () {
          if (ResponsiveUtil.isMobile()) {
            HapticFeedback.lightImpact();
          }
        },
      ),
      children: [
        ResizableChild(
          size: ResizableSize.pixels(
            isArticle
                ? MediaQuery.sizeOf(context).width * 2 / 3
                : max(MediaQuery.sizeOf(context).width * 1 / 3, 400),
          ),
          minSize: 300,
          child: ListView(
            controller: _tabletScrollController,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildCommonContent(true),
              ),
            ],
          ),
        ),
        ResizableChild(
          minSize: 200,
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
    DoubleTapAction action = DoubleTapAction.values[Utils.patchEnum(
        HiveUtil.getInt(HiveUtil.doubleTapActionKey, defaultValue: 1),
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
        Utils.copy(
          context,
          UriUtil.getPostUrlByPermalink(
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

  _handleLike({
    bool? isLike,
  }) {
    HapticFeedback.mediumImpact();
    PostApi.likeOrUnLike(
            isLike: isLike ?? !(_postDetailData!.liked == true),
            postId: _postDetailData!.post!.id,
            blogId: _postDetailData!.post!.blogId)
        .then((value) {
      setState(() {
        if (value['meta']['status'] != 200) {
          if (Utils.isNotEmpty(value['meta']['desc']) &&
              Utils.isNotEmpty(value['meta']['msg'])) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
          }
          if (value['meta']['status'] == 4071) {
            Utils.validSlideCaptcha(context);
          }
        } else {
          _postDetailData!.liked = isLike ?? !(_postDetailData!.liked == true);
          if (_postDetailData!.liked == true) {
            _likeController.forward();
          } else {
            _likeController.value = 0;
          }
          _postDetailData!.post!.postCount!.favoriteCount +=
              (_postDetailData!.liked == true) ? 1 : -1;
          if (_postDetailData!.post!.postCount!.postHot != null) {
            _postDetailData!.post!.postCount!.postHot =
                _postDetailData!.post!.postCount!.postHot! +
                    ((_postDetailData!.liked == true) ? 1 : -1);
          }
        }
      });
    });
  }

  _handleRecommend({
    bool? isRecommend,
  }) {
    HapticFeedback.mediumImpact();
    HapticFeedback.mediumImpact();
    PostApi.shareOrUnShare(
            isShare: isRecommend ?? !(_postDetailData!.shared == true),
            postId: _postDetailData!.post!.id,
            blogId: _postDetailData!.post!.blogId)
        .then((value) {
      setState(() {
        if (value['meta']['status'] != 200) {
          if (Utils.isNotEmpty(value['meta']['desc']) &&
              Utils.isNotEmpty(value['meta']['msg'])) {
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

  _handleDownload() {
    if (isArticle) {
      IToast.showTop("文章不支持下载当前图片");
      return;
    }
    if (downloadState == DownloadState.none) {
      setDownloadState(DownloadState.loading, recover: false);
      FileUtil.saveIllust(
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
      IToast.showTop("没有图片可以下载");
      return;
    }
    if (downloadState == DownloadState.none) {
      setDownloadState(DownloadState.loading, recover: false);
      FileUtil.saveIllusts(context, _getIllusts()).then((res) {
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
      if (hasCollection()) _buildCollectionItem(),
      if (hasGrain()) _buildGrainItem(),
      GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: _buildTagList(),
      ),
      Stack(
        children: [
          ItemBuilder.buildDivider(context),
          _buildOperationRow(),
        ],
      ),
      Container(
        key: commentKey,
        child: ItemBuilder.buildTitle(
          context,
          title: hotComments.isNotEmpty ? "热门评论" : "最新评论",
          bottomMargin: 12,
          topMargin: 24,
        ),
      ),
      Flexible(
        fit: FlexFit.loose,
        child:
            _buildComments(hotComments.isNotEmpty ? hotComments : newComments),
      ),
      if (totalHotOrNewComments <= 0)
        Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(vertical: 24),
          child: ItemBuilder.buildEmptyPlaceholder(
              context: context, text: "暂无评论", topPadding: 0),
        ),
      if (totalHotOrNewComments > 0)
        Center(
          child: Container(
            margin: EdgeInsets.only(
              left: isTablet ? 0 : MediaQuery.sizeOf(context).width / 5,
              right: isTablet ? 0 : MediaQuery.sizeOf(context).width / 5,
              top: 12,
              bottom: isTablet ? 20 : 0,
            ),
            width: isTablet ? 240 : null,
            child: ItemBuilder.buildRoundButton(
              context,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              text: "查看全部评论",
              onTap: () {
                BottomSheetBuilder.showBottomSheet(
                  context,
                  (context) => SingleChildScrollView(
                    controller: ModalScrollController.of(context),
                    child: CommentBottomSheet(
                      postId: postId,
                      blogId: blogId,
                      publishTime: _postDetailData!.post!.publishTime,
                    ),
                  ),
                  enableDrag: false,
                  backgroundColor: MyTheme.getBackground(context),
                );
              },
            ),
          ),
        ),
      if (!isTablet)
        ItemBuilder.buildTitle(
          context,
          title: "更多推荐",
          bottomMargin: 12,
          topMargin: 24,
        ),
    ];
  }

  _buildUserRow() {
    bool hasAvatarBox =
        (_postDetailData!.post?.blogInfo!.bigAvaImg ?? "").isNotEmpty;
    return ItemBuilder.buildClickItem(
      Container(
        color: Colors.transparent,
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
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
                  ItemBuilder.buildCopyItem(
                    context,
                    toastText: "已复制昵称",
                    copyText: _postDetailData!.post?.blogInfo!.blogNickName,
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
                    "${Utils.formatTimestamp(_postDetailData!.post?.publishTime ?? 0)} · ${Utils.isNotEmpty(_postDetailData!.post?.ipLocation) ? _postDetailData!.post?.ipLocation : ""} · ${_postDetailData!.post?.postCount?.postHot ?? 0}热度",
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
            if (_myBlogId != _postDetailData!.post!.blogId)
              ItemBuilder.buildFramedDoubleButton(
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
            if (ResponsiveUtil.isLandscape()) ..._buildButtons(),
          ],
        ),
      ),
    );
  }

  List<String> _getArticleImages() {
    List<String> imageUrls =
        Utils.extractImagesFromHtml(_postDetailData!.post!.content);
    return imageUrls;
  }

  List<dynamic> _getImages() {
    List<PhotoLink> photoLinks =
        Utils.parseJsonList(_postDetailData!.post!.photoLinks)
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

  _buildImageList() {
    late List<PhotoLink> photoLinks;
    late int previewIndex;
    [photoLinks, previewIndex] = _getImages();
    List<String> captions =
        Utils.parseJsonList(_postDetailData!.post!.photoCaptions)
            .map((e) => e.toString())
            .toList();
    double heightMinThreshold = 200;
    double heightMaxThreshold = MediaQuery.sizeOf(context).height - 340;
    double preferedHeight = 0;
    double preferedWidth = MediaQuery.sizeOf(context).width;
    // for (var e in photoLinks) {
    //   double t = (e.oh * 1.0) * preferedWidth / e.ow;
    //   preferedHeight = max(t, preferedHeight);
    // }
    preferedHeight =
        (photoLinks[0].oh * 1.0) * preferedWidth / photoLinks[0].ow;
    preferedHeight =
        max(heightMinThreshold, min(preferedHeight, heightMaxThreshold));
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
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
              String tagPrefix = Utils.getRandomString();
              return Container(
                width: preferedWidth,
                height: trueHeight,
                padding: EdgeInsets.symmetric(vertical: padding),
                margin: const EdgeInsets.only(
                  left: 12,
                  right: 12,
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
                          useMaterial: true,
                          HeroPhotoViewScreen(
                            imageUrls: _getIllusts(),
                            initIndex: index,
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
                            child: ItemBuilder.buildCachedImage(
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
                        child: ItemBuilder.buildTransparentTag(
                          context,
                          text: '彩蛋',
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
            child: ItemBuilder.buildTransparentTag(
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
                child: MouseRegion(
                  cursor: _currentIndex == 1
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: const Icon(
                    Icons.keyboard_arrow_left_rounded,
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
                child: MouseRegion(
                  cursor: _currentIndex == photoLinks.length
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: const Icon(
                    Icons.keyboard_arrow_right_rounded,
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
        : Utils.extractImagesFromHtml(_postDetailData!.post!.content)
            .isNotEmpty;
  }

  List<Illust> _getIllusts() {
    List<Illust> illusts = [];
    if (_hasImage()) {
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
          ),
        );
      }
    } else if (_hasArticleImage()) {
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
          ),
        );
      }
    }
    return illusts;
  }

  _hasContent() {
    String title = Utils.clearBlank(_postDetailData!.post!.title);
    String content = Utils.clearBlank(
        Utils.extractTextFromHtml(_postDetailData!.post!.content));
    return (title.isNotEmpty || content.isNotEmpty);
  }

  _buildPostContent() {
    String title = Utils.clearBlank(_postDetailData!.post!.title);
    String content = Utils.extractTextFromHtml(_postDetailData!.post!.content);
    String htmlTitle = Utils.isNotEmpty(title)
        ? "<p id='title'><strong>${_postDetailData!.post?.title}</strong></p>"
        : "";
    return _hasContent() || title.isNotEmpty || content.isNotEmpty
        ? Container(
            color: Colors.transparent,
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: ItemBuilder.buildHtmlWidget(
              context,
              "$htmlTitle${_postDetailData!.post?.content}",
              illusts: _getIllusts(),
              textStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.apply(fontSizeDelta: 3, heightDelta: 0.3),
              onDownloadSuccess: _handleDownloadSuccessAction,
            ),
          )
        : emptyWidget;
  }

  _handleDownloadSuccessAction() {
    Utils.handleDownloadSuccessAction(onUnlike: () {
      _handleLike(isLike: false);
    }, onUnrecommend: () {
      _handleRecommend(isRecommend: false);
    });
  }

  _buildGrainItem() {
    return ItemBuilder.buildClickItem(
      GestureDetector(
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
                  Icon(
                    Icons.grain_rounded,
                    size: 16,
                    color: MyColors.getHotTagTextColor(context),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    "收录至",
                    style: Theme.of(context).textTheme.titleSmall?.apply(
                        fontSizeDelta: -1,
                        fontWeightDelta: 2,
                        color: MyColors.getHotTagTextColor(context)),
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
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
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

  _buildCollectionItem() {
    return Container(
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
              AssetUtil.loadDouble(
                context,
                AssetUtil.collectionLightIcon,
                AssetUtil.collectionDarkIcon,
                size: 12,
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
                child: ItemBuilder.buildClickItem(
                  Text(
                    _postDetailData!.post!.postCollection!.subscribed
                        ? "已订阅"
                        : "订阅合集",
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
                  text: _postDetailData!.post!.pos > 1 ? "上一篇" : "已在首篇",
                  disabled: _postDetailData!.post!.pos <= 1,
                  onTap: () {
                    if (_postDetailData!.post!.pos > 1) {
                      setState(() {});
                      _fetchPreOrNextPost(isPre: true);
                    } else {
                      IToast.showTop("已经是第一篇了");
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildButton(
                  text: "目录",
                  onTap: showCollectionBottomSheet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildButton(
                  text: _postDetailData!.post!.pos <
                          _postDetailData!.post!.postCollection!.postCount
                      ? "下一篇"
                      : "已在末篇",
                  disabled: _postDetailData!.post!.pos >=
                      _postDetailData!.post!.postCollection!.postCount,
                  onTap: () {
                    if (_postDetailData!.post!.pos <
                        _postDetailData!.post!.postCollection!.postCount) {
                      setState(() {});
                      _fetchPreOrNextPost(isPre: false);
                    } else {
                      IToast.showTop("已经是最后一篇了");
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
    return ItemBuilder.buildClickItem(
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MyTheme.getBackground(context),
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
    if (_previewImages.isNotEmpty) tags.addAll({"彩蛋": TagType.egg});
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

  Widget _buildOperationRow() {
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 16, top: 8, bottom: 8),
      child: Row(
        children: [
          Stack(
            children: [
              ItemBuilder.buildLikedLottieButton(
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
                child: ItemBuilder.buildLottieSharedButton(
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
    );
  }

  Widget _buildComments(List<Comment> comments) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: comments.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => ItemBuilder.buildCommentRow(
        context,
        comments[index],
        writerId: blogId,
        l2Padding: const EdgeInsets.only(top: 12),
        onL2CommentTap: (comment) {
          HapticFeedback.mediumImpact();
          _fetchL2Comments(comment);
        },
      ),
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
                onLikeTap: () async {
                  var item = _recommendPosts[index];
                  HapticFeedback.mediumImpact();
                  return await PostApi.likeOrUnLike(
                          isLike: !item.favorite,
                          postId: item.itemId,
                          blogId: item.blogInfo!.blogId)
                      .then((value) {
                    setState(() {
                      if (value['meta']['status'] != 200) {
                        IToast.showTop(
                            value['meta']['desc'] ?? value['meta']['msg']);
                      } else {
                        item.favorite = !item.favorite;
                        item.postData!.postCount!.favoriteCount +=
                            item.favorite ? 1 : -1;
                      }
                    });
                    return value['meta']['status'];
                  });
                },
                onShieldContent: () {
                  _recommendPosts.remove(_recommendPosts[index]);
                  setState(() {});
                },
                onShieldTag: (tag) {
                  _recommendPosts.remove(_recommendPosts[index]);
                  setState(() {});
                },
                onShieldUser: () {
                  _recommendPosts.remove(_recommendPosts[index]);
                  setState(() {});
                },
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
          onLoad: _onLoad,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) => CustomScrollView(
            physics: physics,
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: ItemBuilder.buildTitle(
                  context,
                  title: "更多推荐",
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
      (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: CollectionBottomSheet(
          postCollection: _postDetailData!.post!.postCollection!,
          collectionId: collectionId,
          postId: postId,
          blogId: blogId,
          blogName: blogName,
        ),
      ),
      enableDrag: false,
    );
  }

  void setDownloadState(DownloadState state, {bool recover = true}) {
    switch (state) {
      case DownloadState.none:
        downloadIcon = Icon(Icons.download_rounded,
            color: Theme.of(rootContext).iconTheme.color);
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
        downloadIcon = const Icon(Icons.check_rounded, color: Colors.green);
        break;
      case DownloadState.failed:
        downloadIcon =
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent);
        break;
    }
    downloadState = state;
    if (mounted) setState(() {});
    if (recover) {
      Future.delayed(const Duration(seconds: 2), () {
        setDownloadState(DownloadState.none, recover: false);
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildDesktopAppBar(
      context: context,
      showBack: true,
      titleWidget: Text(
        "帖子详情",
        style: Theme.of(context).textTheme.titleLarge?.apply(
              fontWeightDelta: 2,
            ),
      ),
      actions: [
        if (hasCollection())
          ItemBuilder.buildClickItem(
            GestureDetector(
              onTap: showCollectionBottomSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    AssetUtil.loadDouble(
                      context,
                      AssetUtil.collectionLightIcon,
                      AssetUtil.collectionDarkIcon,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      "合集 ${_postDetailData!.post!.pos}/${_postDetailData!.post!.postCollection!.postCount}",
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
        const SizedBox(width: 5),
      ],
    );
  }

  List<Widget> _buildButtons() {
    return [
      const SizedBox(width: 5),
      if (_hasImage() ||
          _hasArticleImage() &&
              HiveUtil.getBool(HiveUtil.showDownloadKey, defaultValue: true))
        ItemBuilder.buildIconButton(
          context: context,
          icon: downloadIcon,
          onTap: () {
            _handleDownloadAll();
          },
        ),
      if ((_hasImage() || _hasArticleImage()) &&
          HiveUtil.getBool(HiveUtil.showDownloadKey, defaultValue: true))
        const SizedBox(width: 5),
      ItemBuilder.buildIconButton(
        context: context,
        icon: Icon(Icons.more_vert_rounded,
            color: Theme.of(context).iconTheme.color),
        onTap: () {
          BottomSheetBuilder.showContextMenu(context, _buildMoreButtons());
        },
      ),
    ];
  }

  _buildMoreButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          "复制链接",
          icon: const Icon(Icons.copy_rounded),
          onPressed: () {
            Utils.copy(
              context,
              UriUtil.getPostUrlByPermalink(
                _postDetailData!.post!.blogInfo!.blogName,
                _postDetailData!.post!.permalink,
              ),
            );
          },
        ),
        ContextMenuButtonConfig("访问原文",
            icon: const Icon(Icons.view_carousel_outlined), onPressed: () {
          UriUtil.openInternal(
            context,
            UriUtil.getPostUrlById(
              blogName,
              postId,
              blogId,
            ),
            processUri: false,
          );
        }),
        ContextMenuButtonConfig("在浏览器打开",
            icon: const Icon(Icons.open_in_browser_rounded), onPressed: () {
          UriUtil.openExternal(
            UriUtil.getPostUrlByPermalink(
              _postDetailData!.post!.blogInfo!.blogName,
              _postDetailData!.post!.permalink,
            ),
          );
        }),
        ContextMenuButtonConfig("分享到其他应用",
            icon: const Icon(Icons.share_rounded), onPressed: () {
          UriUtil.share(
            context,
            UriUtil.getPostUrlByPermalink(
              _postDetailData!.post!.blogInfo!.blogName,
              _postDetailData!.post!.permalink,
            ),
          );
        }),
      ],
    );
  }
}
