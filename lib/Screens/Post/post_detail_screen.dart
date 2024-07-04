import 'dart:io';
import 'dart:math';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/post_api.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Models/grain_response.dart';
import 'package:loftify/Models/message_response.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/show_case_response.dart';
import 'package:loftify/Resources/colors.dart';
import 'package:loftify/Resources/gaps.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Widgets/BottomSheet/collection_bottom_sheet.dart';
import 'package:loftify/Widgets/BottomSheet/comment_bottom_sheet.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:tuple/tuple.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Api/collection_api.dart';
import '../../Api/recommend_api.dart';
import '../../Models/search_response.dart';
import '../../Resources/theme.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/lottie_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/Custom/hero_photo_view_screen.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
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
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  PostDetailData? _postDetailData;
  List<PreviewImage> _previewImages = [];
  final SwiperController _swiperController = SwiperController();
  int _currentIndex = 1;
  final List<PostListItem> _recommendPosts = [];
  int _currentPage = 0;
  final int _myBlogId = HiveUtil.getInt(key: HiveUtil.userIdKey);
  bool _loadingInfo = false;
  bool _loadingRecommend = false;
  int blogId = 0;
  int postId = 0;
  int collectionId = 0;
  String blogName = "";
  late ScrollController _scrollController;
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

  @override
  void dispose() {
    _scrollController.dispose();
    _doubleTapLikeController.dispose();
    _shareController.dispose();
    _likeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    _scrollController = ScrollController();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Future.delayed(const Duration(milliseconds: 300), initLottie);
      initLottie();
      if (widget.isArticle) {
        Future.delayed(const Duration(milliseconds: 300), initData);
      } else {
        initData();
      }
    });
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

  initData() {
    _initParams();
    _fetchData();
    _fetchRecommendPosts();
    return Future(() => null);
  }

  void _onScroll(int index) {
    setState(() {
      _currentIndex = index + 1;
    });
  }

  _initParams() {
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
  }

  _uploadHistory() {
    int userId = HiveUtil.getInt(key: HiveUtil.userIdKey);
    PostApi.uploadHistory(
      postId: postId,
      blogId: blogId,
      userId: userId,
      postType: _postDetailData!.post!.type,
      collectionId: _postDetailData!.post!.collectionId,
    ).then((value) {
      if (value['code'] != 200) {
        IToast.showTop(context, text: value['msg']);
      }
    });
  }

  _fetchData() async {
    if (_loadingInfo) return;
    _loadingInfo = true;
    var t1 = await PostApi.getDetail(
      postId: postId,
      blogId: blogId,
      blogName: blogName,
    ).then((value) {
      if (value['meta']['status'] != 200) {
        IToast.showTop(context,
            text: value['meta']['desc'] ?? value['meta']['msg']);
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
    _loadingInfo = false;
    return t1 == IndicatorResult.success && t2 == IndicatorResult.success
        ? IndicatorResult.success
        : IndicatorResult.fail;
  }

  _fetchGift() async {
    return await PostApi.getGifts(
      postId: postId,
      blogId: blogId,
    ).then((value) {
      if (value == null) return IndicatorResult.fail;
      if (value['code'] != 200 || value['ok'] != true) {
        IToast.showTop(context, text: value['msg']);
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
          IToast.showTop(context, text: value['msg']);
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
      } catch (_) {
        IToast.showTop(context, text: "评论加载失败");
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
          IToast.showTop(context, text: value['msg']);
          return IndicatorResult.fail;
        } else {
          currentComment.l2CommentOffset = value['data']['offset'];
          List<dynamic> comments = value['data']['list'] as List;
          for (var comment in comments) {
            currentComment.l2Comments.add(Comment.fromJson(comment));
          }
          return IndicatorResult.success;
        }
      } catch (_) {
        IToast.showTop(context, text: "评论加载失败");
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
        IToast.showTop(context,
            text: value['meta']['desc'] ?? value['meta']['msg']);
        return IndicatorResult.fail;
      } else {
        _postDetailData = PostDetailData.fromJson(value['response'][0]);
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.ease);
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

  _updateMeta({bool swipeToFirst = true}) {
    collectionId = _postDetailData!.post!.postCollection != null
        ? _postDetailData!.post!.postCollection!.id
        : 0;
    postId = _postDetailData!.post!.id;
    blogId = _postDetailData!.post!.blogId;
    blogName = _postDetailData!.post!.blogInfo!.blogName;
    _shareController.value = _postDetailData!.shared == true ? 1 : 0;
    _likeController.value = _postDetailData!.liked == true ? 1 : 0;
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
    if (_hasImage() && HiveUtil.getBool(key: HiveUtil.followMainColorKey)) {
      List<PhotoLink> photoLinks = getImages()[0];
      Utils.getMainColors(
        context,
        photoLinks.map((e) => e.middle).toList(),
      ).then((value) {
        if (mounted) setState(() {});
        mainColors = value;
      });
    } else {
      List<String> imageUrls =
          Utils.extractImagesFromHtml(_postDetailData!.post!.content);
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
    var t1 = await _fetchData();
    var t2 = await _fetchRecommendPosts(append: false);
    return t1 == IndicatorResult.success && t2 == IndicatorResult.success
        ? IndicatorResult.success
        : IndicatorResult.fail;
  }

  _onLoad() async {
    return await _fetchRecommendPosts();
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
            IToast.showTop(context, text: value['msg']);
          }
          return IndicatorResult.fail;
        } else {
          List<dynamic> tmp = value['data']['list'];
          if (append == false) _recommendPosts.clear();
          _recommendPosts
              .addAll(tmp.map((e) => PostListItem.fromJson(e)).toList());
          return IndicatorResult.success;
        }
      } catch (e) {
        if (mounted) IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loadingRecommend = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: AppTheme.getBackground(context),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return EasyRefresh.builder(
      onRefresh: _onRefresh,
      onLoad: _onLoad,
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => _postDetailData != null
          ? Stack(
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
            )
          : ItemBuilder.buildLoadingDialog(
              context,
              background: AppTheme.getBackground(context),
            ),
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
    _showDoubleTapLike = true;
    _doubleTapLikeController.forward(from: 0);
    _doubleTapLikeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _showDoubleTapLike = false;
        setState(() {});
      }
    });
    setState(() {});
    HapticFeedback.mediumImpact();
    if (_postDetailData!.liked != true) {
      PostApi.likeOrUnLike(
              isLike: !(_postDetailData!.liked == true),
              postId: _postDetailData!.post!.id,
              blogId: _postDetailData!.post!.blogId)
          .then((value) {
        setState(() {
          if (value['meta']['status'] != 200) {
            IToast.showTop(context,
                text: value['meta']['desc'] ?? value['meta']['msg']);
            if (value['meta']['status'] == 4071) {
              Utils.validSlideCaptcha(context);
            }
          } else {
            _postDetailData!.liked = !(_postDetailData!.liked == true);
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
  }

  _buildMainBody(ScrollPhysics physics) {
    return CustomScrollView(
      controller: _scrollController,
      physics: physics,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
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
                child: _buildComments(
                    hotComments.isNotEmpty ? hotComments : newComments),
              ),
              if (totalHotOrNewComments <= 0)
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  child: ItemBuilder.buildEmptyPlaceholder(
                      context: context, text: "暂无评论"),
                ),
              if (totalHotOrNewComments > 0)
                Container(
                  margin: EdgeInsets.only(
                    left: MediaQuery.sizeOf(context).width / 5,
                    right: MediaQuery.sizeOf(context).width / 5,
                    top: 20,
                  ),
                  child: ItemBuilder.buildRoundButton(
                    context,
                    text: "查看全部评论",
                    onTap: () {
                      showMaterialModalBottomSheet(
                        context: context,
                        enableDrag: false,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        backgroundColor: AppTheme.getBackground(context),
                        builder: (context) => SingleChildScrollView(
                          controller: ModalScrollController.of(context),
                          child: CommentBottomSheet(
                            postId: postId,
                            blogId: blogId,
                            publishTime: _postDetailData!.post!.publishTime,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ItemBuilder.buildTitle(
                context,
                title: "更多推荐",
                bottomMargin: 12,
                topMargin: 24,
              ),
            ],
          ),
        ),
        _buildRecommendFlow(),
      ],
    );
  }

  _buildUserRow() {
    bool hasAvatarBox =
        (_postDetailData!.post?.blogInfo!.bigAvaImg ?? "").isNotEmpty;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
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
                Row(
                  children: [
                    Text(
                      Utils.formatTimestamp(
                          _postDetailData!.post?.publishTime ?? 0),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    ItemBuilder.buildDot(
                      context,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (Utils.isNotEmpty(_postDetailData!.post?.ipLocation))
                      Text(
                        _postDetailData!.post?.ipLocation ?? "",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (Utils.isNotEmpty(_postDetailData!.post?.ipLocation))
                      ItemBuilder.buildDot(
                        context,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Text(
                      "${_postDetailData!.post?.postCount?.postHot ?? 0}热度",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 40),
          if (_myBlogId != _postDetailData!.post!.blogId)
            ItemBuilder.buildFramedButton(
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
                      IToast.showTop(context,
                          text: value['meta']['desc'] ?? value['meta']['msg']);
                    } else {
                      _postDetailData!.followed =
                          !(_postDetailData!.followed == 1) ? 1 : 0;
                      setState(() {});
                    }
                  });
                }),
        ],
      ),
    );
  }

  List<dynamic> getImages() {
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
    [photoLinks, previewIndex] = getImages();
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HeroPhotoViewScreen(
                              imageUrls: photoLinks,
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
                            ),
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
            onIndexChanged: _onScroll,
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
      ],
    );
  }

  _hasImage() {
    return _postDetailData!.post!.photoLinks.isNotEmpty;
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
    List<String> imageUrls =
        Utils.extractImagesFromHtml(_postDetailData!.post!.content);
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
              imageUrls: imageUrls,
              textStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.apply(fontSizeDelta: 3, heightDelta: 0.3),
            ),
          )
        : MyGaps.empty;
  }

  _buildGrainItem() {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushCupertinoRoute(
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
                      IToast.showTop(context,
                          text: value['meta']['desc'] ?? value['meta']['msg']);
                    } else {
                      _postDetailData!.post!.postCollection!.subscribed =
                          !(_postDetailData!.post!.postCollection!.subscribed);
                      setState(() {});
                    }
                  });
                },
                child: Text(
                  _postDetailData!.post!.postCollection!.subscribed
                      ? "已订阅"
                      : "订阅合集",
                  style: Theme.of(context).textTheme.titleSmall?.apply(
                        fontSizeDelta: -2,
                        fontWeightDelta: 2,
                        color: _postDetailData!.post!.postCollection!.subscribed
                            ? Theme.of(context).textTheme.labelSmall?.color
                            : Theme.of(context).primaryColor,
                      ),
                ),
              )
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
                      IToast.showTop(context, text: "已经是第一篇了");
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
                      IToast.showTop(context, text: "已经是最后一篇了");
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.getBackground(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text ?? "",
          style: disabled
              ? Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.apply(color: Theme.of(context).textTheme.labelSmall?.color)
              : Theme.of(context).textTheme.titleSmall,
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
          return ItemBuilder.buildTagItem(
            context,
            sortedTags[index].key,
            sortedTags[index].value,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  HapticFeedback.mediumImpact();
                  PostApi.likeOrUnLike(
                          isLike: !(_postDetailData!.liked == true),
                          postId: _postDetailData!.post!.id,
                          blogId: _postDetailData!.post!.blogId)
                      .then((value) {
                    setState(() {
                      if (value['meta']['status'] != 200) {
                        IToast.showTop(context,
                            text:
                                value['meta']['desc'] ?? value['meta']['msg']);
                        if (value['meta']['status'] == 4071) {
                          Utils.validSlideCaptcha(context);
                        }
                      } else {
                        _postDetailData!.liked =
                            !(_postDetailData!.liked == true);
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
                    HapticFeedback.mediumImpact();
                    PostApi.shareOrUnShare(
                            isShare: !(_postDetailData!.shared == true),
                            postId: _postDetailData!.post!.id,
                            blogId: _postDetailData!.post!.blogId)
                        .then((value) {
                      setState(() {
                        if (value['meta']['status'] != 200) {
                          IToast.showTop(context,
                              text: value['meta']['desc'] ??
                                  value['meta']['msg']);
                          if (value['meta']['status'] == 4071) {
                            Utils.validSlideCaptcha(context);
                          }
                        } else {
                          _postDetailData!.shared =
                              !(_postDetailData!.shared == true);
                          if (_postDetailData!.shared == true) {
                            _shareController.forward();
                          } else {
                            _shareController.value = 0;
                          }
                          _postDetailData!.post!.postCount!.shareCount +=
                              (_postDetailData!.shared == true) ? 1 : -1;
                          if (_postDetailData!.post!.postCount!.postHot !=
                              null) {
                            _postDetailData!.post!.postCount!.postHot =
                                _postDetailData!.post!.postCount!.postHot! +
                                    ((_postDetailData!.shared == true)
                                        ? 1
                                        : -1);
                          }
                        }
                      });
                    });
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

  Widget _buildRecommendFlow() {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
      sliver: SliverWaterfallFlow(
        gridDelegate: const SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 6,
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
                        IToast.showTop(context,
                            text:
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
  }

  hasCollection() {
    return _postDetailData != null &&
        _postDetailData!.post!.postCollection != null;
  }

  hasGrain() {
    return _postDetailData != null && _postDetailData!.grainInfo != null;
  }

  showCollectionBottomSheet() {
    showMaterialModalBottomSheet(
      context: context,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      backgroundColor: AppTheme.getBackground(context),
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: CollectionBottomSheet(
          postCollection: _postDetailData!.post!.postCollection!,
          collectionId: collectionId,
          postId: postId,
          blogId: blogId,
          blogName: blogName,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      backgroundColor: AppTheme.getBackground(context),
      leading: Icons.arrow_back_rounded,
      onLeadingTap: () {
        Navigator.pop(context);
      },
      actions: [
        if (hasCollection())
          GestureDetector(
            onTap: showCollectionBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        const SizedBox(width: 5),
        ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {
              List<Tuple2<String, dynamic>> options = [
                const Tuple2("复制链接", 0),
                const Tuple2("访问原文", 1),
                const Tuple2("在浏览器打开", 2),
                const Tuple2("分享到其他应用", 3),
              ];
              BottomSheetBuilder.showListBottomSheet(
                context,
                (sheetContext) => TileList.fromOptions(
                  options,
                  (idx) {
                    Navigator.pop(sheetContext);
                    if (idx == 0) {
                      Utils.copy(
                        context,
                        UriUtil.getPostUrlByPermalink(
                          _postDetailData!.post!.blogInfo!.blogName,
                          _postDetailData!.post!.permalink,
                        ),
                      );
                    } else if (idx == 1) {
                      UriUtil.openInternal(
                        context,
                        UriUtil.getPostUrlById(
                          blogName,
                          postId,
                          blogId,
                        ),
                        processUri: false,
                      );
                    } else if (idx == 2) {
                      UriUtil.openExternal(
                        UriUtil.getPostUrlByPermalink(
                          _postDetailData!.post!.blogInfo!.blogName,
                          _postDetailData!.post!.permalink,
                        ),
                      );
                    } else if (idx == 3) {
                      UriUtil.share(
                        context,
                        UriUtil.getPostUrlByPermalink(
                          _postDetailData!.post!.blogInfo!.blogName,
                          _postDetailData!.post!.permalink,
                        ),
                      );
                    }
                  },
                  showCancel: true,
                  context: context,
                  showTitle: false,
                  onCloseTap: () => Navigator.pop(sheetContext),
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              );
            }),
        const SizedBox(width: 5),
      ],
    );
  }
}
