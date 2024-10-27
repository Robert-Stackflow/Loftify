import 'package:loftify/Models/recommend_response.dart';

import '../Utils/ilogger.dart';
import '../Utils/utils.dart';
import 'account_response.dart';

///PostDetailData
class PostDetailData {
  int? followed;
  bool? liked;
  String? misc;
  PostDetail? post;
  PostDetail? postData;
  GrainInfo? grainInfo;
  bool? shared;
  bool? showLuckyBoy;
  bool? subscribed;
  int? opTime;

  PostDetailData({
    this.followed,
    this.liked,
    this.misc,
    this.post,
    this.postData,
    this.shared,
    this.showLuckyBoy,
    this.subscribed,
    this.opTime,
    this.grainInfo,
  }) {
    if (postData != null) {
      post = postData;
    }
  }

  PostDetailData.fromJson(Map<String, dynamic> json) {
    followed = (json['followed'] is bool)
        ? (json['followed'] == true ? 1 : 0)
        : json['followed'];
    liked = json['liked'];
    misc = json['misc'];
    post = json['post'] != null ? PostDetail.fromJson(json['post']) : null;
    postData =
        json['postData'] != null ? PostDetail.fromJson(json['postData']) : null;
    shared = json['shared'];
    showLuckyBoy = json['showLuckyBoy'];
    opTime = json['opTime'];
    subscribed = json['subscribed'];
    grainInfo = json['grainInfo'] != null
        ? GrainInfo.fromJson(json['grainInfo'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['followed'] = followed;
    data['liked'] = liked;
    data['misc'] = misc;
    if (post != null) {
      data['post'] = post!.toJson();
    }
    data['shared'] = shared;
    data['showLuckyBoy'] = showLuckyBoy;
    data['subscribed'] = subscribed;
    data['opTime'] = opTime;
    return data;
  }
}

class FavoritePostDetailData {
  int? followed;
  bool? liked;
  String? misc;
  FavoritePostDetail? postData;
  bool? shared;
  bool? showLuckyBoy;
  bool? subscribed;
  int? opTime;

  PostDetail? get post => postData!.postView;

  FavoritePostDetailData({
    this.followed,
    this.liked,
    this.misc,
    this.postData,
    this.shared,
    this.showLuckyBoy,
    this.subscribed,
    this.opTime,
  });

  FavoritePostDetailData.fromJson(Map<String, dynamic> json) {
    followed = (json['followed'] is bool)
        ? (json['followed'] == true ? 1 : 0)
        : json['followed'];
    liked = json['liked'];
    misc = json['misc'];
    postData = json['postData'] != null
        ? FavoritePostDetail.fromJson(json['postData'])
        : null;
    shared = json['shared'];
    showLuckyBoy = json['showLuckyBoy'];
    opTime = json['opTime'];
    subscribed = json['subscribed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['followed'] = followed;
    data['liked'] = liked;
    data['misc'] = misc;
    if (postData != null) {
      data['postData'] = postData!.toJson();
    }
    data['shared'] = shared;
    data['showLuckyBoy'] = showLuckyBoy;
    data['subscribed'] = subscribed;
    data['opTime'] = opTime;
    return data;
  }
}

class FavoritePostDetail {
  PostDetail postView;
  PostCount postCountView;
  SimpleBlogInfo blogInfo;

  FavoritePostDetail({
    required this.postView,
    required this.postCountView,
    required this.blogInfo,
  }) {
    postView.postCount = postCountView;
  }

  factory FavoritePostDetail.fromJson(Map<String, dynamic> json) {
    return FavoritePostDetail(
      postView: PostDetail.fromJson(json['postView']),
      postCountView: PostCount.fromJson(json['postCountView']),
      blogInfo: SimpleBlogInfo.fromJson(json['blogInfo']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['postView'] = postView.toJson();
    data['postCountView'] = postCountView.toJson();
    data['blogInfo'] = blogInfo.toJson();
    return data;
  }
}

///PostDetail
class PostDetail {
  int allowReward;
  int allowView;
  int applyStatus;
  int blogId;
  FullBlogInfo? blogInfo;
  String blogPageUrl;
  String caption;
  int cctype;
  bool cited;
  int citeParentBlogId;
  String citeParentPermalink;
  int citeParentPostId;
  int citeRootBlogId;
  int citeRootPostId;
  int collectionId;
  String content;
  String digest;
  int dirPostType;
  int fansVipPost;
  String? embed;
  FirstImage? firstImage;
  String firstImageUrl;
  List<int> firstImageWh;
  String firstSmallImageUrl;
  int forbidPcomment;
  int forbidShare;
  int hot;
  int id;
  String ipLocation;
  bool isContribute;
  bool isPublished;
  int locationId;
  bool needPay;
  bool newVersionAuditing;
  bool payingView;
  int payView;
  bool payViewExpire;
  bool payViewPost;
  String permalink;
  String photoCaptions;
  String photoLinks;
  int photoType;
  int pos;
  FullPostCollection? postCollection;
  VideoPostView? videoPostView;
  PhotoPostView? photoPostView;
  PostCount? postCount;
  int postSource;
  int postStyle;
  FullBlogInfo? publisherMainBlogInfo;
  int publisherUserId;
  int publishTime;
  int rank;
  String imageMarkInfo;
  int imageReblogMark;
  int imageAiMark;
  String reblogAuthorFromEmbed;
  List<ReturnContent> returnContent;
  int showGift;
  String tag;
  List<String> tagList;
  List<String> tagRankList;
  String title;
  int top;
  int type;
  int valid;
  int viewRank;
  VideoInfo? videoInfo;

  PostDetail({
    required this.imageAiMark,
    required this.imageMarkInfo,
    required this.imageReblogMark,
    required this.reblogAuthorFromEmbed,
    required this.allowReward,
    required this.allowView,
    required this.applyStatus,
    required this.blogId,
    required this.returnContent,
    this.blogInfo,
    this.embed,
    this.videoInfo,
    required this.blogPageUrl,
    required this.caption,
    required this.cctype,
    required this.cited,
    this.firstImage,
    this.videoPostView,
    this.photoPostView,
    required this.citeParentBlogId,
    required this.citeParentPermalink,
    required this.citeParentPostId,
    required this.citeRootBlogId,
    required this.citeRootPostId,
    required this.collectionId,
    required this.content,
    required this.digest,
    required this.dirPostType,
    required this.fansVipPost,
    required this.firstImageUrl,
    required this.firstImageWh,
    required this.firstSmallImageUrl,
    required this.forbidPcomment,
    required this.forbidShare,
    required this.hot,
    required this.id,
    required this.ipLocation,
    required this.isContribute,
    required this.isPublished,
    required this.locationId,
    required this.needPay,
    required this.newVersionAuditing,
    required this.payingView,
    required this.payView,
    required this.payViewExpire,
    required this.payViewPost,
    required this.permalink,
    required this.photoCaptions,
    required this.photoLinks,
    required this.photoType,
    required this.pos,
    this.postCollection,
    this.postCount,
    required this.postSource,
    required this.postStyle,
    this.publisherMainBlogInfo,
    required this.publisherUserId,
    required this.publishTime,
    required this.rank,
    required this.showGift,
    required this.tag,
    required this.tagList,
    required this.tagRankList,
    required this.title,
    required this.top,
    required this.type,
    required this.valid,
    required this.viewRank,
  }) {
    if (Utils.isNotEmpty(embed)) {
      try {
        videoInfo = VideoInfo.fromJson(Utils.parseJson(embed ?? "{}"));
      } catch (e, t) {
        ILogger.error("Failed to init videoInfo from $embed", e, t);
      }
    }
  }

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    return PostDetail(
      imageAiMark: json['imageAiMark'] ?? 0,
      imageMarkInfo: json['imageMarkInfo'] ?? "",
      imageReblogMark: json['imageReblogMark'] ?? 0,
      reblogAuthorFromEmbed: json['reblogAuthorFromEmbed'] ?? "",
      allowReward: json['allowReward'] ?? 0,
      allowView: json['allowView'] ?? 0,
      applyStatus: json['applyStatus'] ?? 0,
      blogId: json['blogId'] ?? 0,
      blogInfo: json['blogInfo'] != null
          ? FullBlogInfo.fromJson(json['blogInfo'])
          : null,
      returnContent: json['returnContent'] != null
          ? (json['returnContent'] as List)
              .map((v) => ReturnContent.fromJson(v))
              .toList()
          : [],
      blogPageUrl: json['blogPageUrl'] ?? "",
      caption: json['caption'] ?? "",
      embed: json['embed'] ?? "",
      cctype: (json['cctype'] ?? json['ccType']) ?? 0,
      cited: json['cited'] ?? false,
      citeParentBlogId: json['citeParentBlogId'] ?? 0,
      citeParentPermalink: json['citeParentPermalink'] ?? "",
      citeParentPostId: json['citeParentPostId'] ?? 0,
      citeRootBlogId: json['citeRootBlogId'] ?? 0,
      citeRootPostId: json['citeRootPostId'] ?? 0,
      collectionId: json['collectionId'] ?? 0,
      content: json['content'] ?? "",
      digest: json['digest'] ?? "",
      dirPostType: json['dirPostType'] ?? 0,
      fansVipPost: json['fansVipPost'] ?? 0,
      firstImage: json['firstImage'] != null
          ? FirstImage.fromJson(json['firstImage'])
          : null,
      firstImageUrl: json['firstImageUrl'] ?? "",
      firstImageWh: json['firstImageWh'] != null
          ? (json['firstImageWh'] as List).map((v) => v as int).toList()
          : [],
      firstSmallImageUrl: json['firstSmallImageUrl'] ?? "",
      forbidPcomment: json['forbidPcomment'] ?? 0,
      forbidShare: json['forbidShare'] ?? 0,
      hot: json['hot'] ?? 0,
      id: json['id'] ?? 0,
      ipLocation: json['ipLocation'] ?? "",
      isContribute: json['isContribute'] == 1 ? true : false,
      isPublished: json['isPublished'] == 1 ? true : false,
      locationId: json['locationId'] ?? 0,
      needPay: json['needPay'] ?? false,
      newVersionAuditing: json['newVersionAuditing'] ?? false,
      payingView: json['payingView'] ?? false,
      payView: json['payView'] ?? 0,
      payViewExpire: json['payViewExpire'] ?? false,
      payViewPost: json['payViewPost'] ?? false,
      permalink: json['permalink'] ?? "",
      photoCaptions: json['photoCaptions'] ?? "",
      photoLinks: json['photoLinks'] ?? "",
      photoType: json['photoType'] ?? 0,
      pos: json['pos'] ?? 0,
      postCollection: json['postCollection'] != null
          ? FullPostCollection.fromJson(json['postCollection'])
          : null,
      postCount: json['postCount'] != null
          ? PostCount.fromJson(json['postCount'])
          : null,
      postSource: json['postSource'] ?? 0,
      postStyle: json['postStyle'] ?? 0,
      publisherMainBlogInfo: json['publisherMainBlogInfo'] != null
          ? FullBlogInfo.fromJson(json['publisherMainBlogInfo'])
          : null,
      publisherUserId: json['publisherUserId'],
      publishTime: json['publishTime'],
      rank: json['rank'] ?? 0,
      showGift: json['showGift'] ?? 0,
      tag: json['tag'] ?? "",
      tagList: json['tagList'] != null
          ? (json['tagList'] as List).map((v) => v as String).toList()
          : [],
      tagRankList: json['tagRankList'] != null
          ? (json['tagRankList'] as List).map((v) => v as String).toList()
          : [],
      title: json['title'] ?? "",
      top: json['top'],
      type: json['type'],
      valid: json['valid'],
      viewRank: json['viewRank'],
      videoPostView: json['videoPostView'] != null
          ? VideoPostView.fromJson(json['videoPostView'])
          : null,
      photoPostView: json['photoPostView'] != null
          ? PhotoPostView.fromJson(json['photoPostView'])
          : null,
    );
  }

//生成fromJson、toJson
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['allowReward'] = allowReward;
    data['allowView'] = allowView;
    data['applyStatus'] = applyStatus;
    data['blogId'] = blogId;
    // data['blogInfo'] = blogInfo?.toJson();
    data['blogPageUrl'] = blogPageUrl;
    data['caption'] = caption;
    data['cctype'] = cctype;
    data['cited'] = cited;
    data['citeParentBlogId'] = citeParentBlogId;
    data['citeParentPermalink'] = citeParentPermalink;
    data['citeParentPostId'] = citeParentPostId;
    data['citeRootBlogId'] = citeRootBlogId;
    data['citeRootPostId'] = citeRootPostId;
    data['collectionId'] = collectionId;
    data['content'] = content;
    data['digest'] = digest;
    data['dirPostType'] = dirPostType;
    data['fansVipPost'] = fansVipPost;
    data['firstImageUrl'] = firstImageUrl;
    data['firstImageWh'] = firstImageWh;
    data['firstSmallImageUrl'] = firstSmallImageUrl;
    data['forbidPcomment'] = forbidPcomment;
    data['forbidShare'] = forbidShare;
    data['hot'] = hot;
    data['id'] = id;
    data['ipLocation'] = ipLocation;
    data['isContribute'] = isContribute;
    data['isPublished'] = isPublished;
    data['locationId'] = locationId;
    data['needPay'] = needPay;
    data['newVersionAuditing'] = newVersionAuditing;
    data['payingView'] = payingView;
    data['payView'] = payView;
    data['payViewExpire'] = payViewExpire;
    data['payViewPost'] = payViewPost;
    data['permalink'] = permalink;
    data['photoCaptions'] = photoCaptions;
    data['photoLinks'] = photoLinks;
    data['photoType'] = photoType;
    data['pos'] = pos;
    data['postCollection'] = postCollection?.toJson();
    data['postCount'] = postCount?.toJson();
    data['postSource'] = postSource;
    data['postStyle'] = postStyle;
    data['publisherMainBlogInfo'] = publisherMainBlogInfo?.toJson();
    data['publisherUserId'] = publisherUserId;
    data['publishTime'] = publishTime;
    data['rank'] = rank;
    data['showGift'] = showGift;
    data['tag'] = tag;
    data['tagList'] = tagList;
    data['tagRankList'] = tagRankList;
    data['title'] = title;
    data['top'] = top;
    data['type'] = type;
    data['valid'] = valid;
    data['viewRank'] = viewRank;
    data['videoPostView'] = videoPostView?.toJson();
    data['photoPostView'] = photoPostView?.toJson();
    return data;
  }

  @override
  String toString() {
    return 'PostDetail{allowReward: $allowReward, allowView: $allowView, applyStatus: $applyStatus, blogId: $blogId, blogInfo: $blogInfo, blogPageUrl: $blogPageUrl, caption: $caption, cctype: $cctype, cited: $cited, citeParentBlogId: $citeParentBlogId, citeParentPermalink: $citeParentPermalink, citeParentPostId: $citeParentPostId, citeRootBlogId: $citeRootBlogId, citeRootPostId: $citeRootPostId, collectionId: $collectionId, content: $content, digest: $digest, dirPostType: $dirPostType, fansVipPost: $fansVipPost, firstImageUrl: $firstImageUrl, firstImageWh: $firstImageWh, firstSmallImageUrl: $firstSmallImageUrl, forbidPcomment: $forbidPcomment, forbidShare: $forbidShare, hot: $hot, id: $id, ipLocation: $ipLocation, isContribute: $isContribute, isPublished: $isPublished, locationId: $locationId, needPay: $needPay, newVersionAuditing: $newVersionAuditing, payingView: $payingView, payView: $payView, payViewExpire: $payViewExpire, payViewPost: $payViewPost, permalink: $permalink, photoCaptions: $photoCaptions, photoLinks: $photoLinks, photoType: $photoType, pos: $pos, postCollection: $postCollection, postCount: $postCount, postSource: $postSource, postStyle: $postStyle, publisherMainBlogInfo: $publisherMainBlogInfo, publisherUserId: $publisherUserId, publishTime: $publishTime, rank: $rank, showGift: $showGift, tag: $tag, tagList: $tagList, tagRankList: $tagRankList, title: $title, top: $top, type: $type, valid: $valid, viewRank: $viewRank}';
  }
}

class ReturnContent {
  final int id;
  final String content;
  final String planTypeName;
  final List<PreviewImage> images;

  ReturnContent({
    required this.id,
    required this.content,
    required this.planTypeName,
    required this.images,
  });

  factory ReturnContent.fromJson(Map<String, dynamic> json) {
    return ReturnContent(
      id: json['id'] ?? 0,
      content: json['content'] ?? "",
      planTypeName: json['planTypeName'] ?? "",
      images: (json['images'] as List)
          .map((e) => PreviewImage.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['content'] = content;
    data['planTypeName'] = planTypeName;
    data['images'] = images;
    return data;
  }
}

///FullFullPostCollection
class FullPostCollection {
  int blogId;
  int collectionType;
  int contentType;
  String coverUrl;
  int createTime;
  String description;
  int favoriteCount;
  int postCollectionHot;
  int subscribedCount;
  int lastReadBlogId;
  int lastReadPostId;
  int id;
  int lastPublishTime;
  String name;
  int postCount;
  int status;
  bool subscribed;
  String tags;
  int updateTime;
  int viewCount;

  FullPostCollection({
    required this.lastReadBlogId,
    required this.lastReadPostId,
    required this.subscribedCount,
    required this.postCollectionHot,
    required this.blogId,
    required this.collectionType,
    required this.contentType,
    required this.coverUrl,
    required this.createTime,
    required this.description,
    required this.favoriteCount,
    required this.id,
    required this.lastPublishTime,
    required this.name,
    required this.postCount,
    required this.status,
    required this.subscribed,
    required this.tags,
    required this.updateTime,
    required this.viewCount,
  });

//生成fromJson、toJson
  factory FullPostCollection.fromJson(Map<String, dynamic> json) {
    return FullPostCollection(
      blogId: json['blogId'],
      collectionType: json['collectionType'],
      contentType: json['contentType'],
      coverUrl: json['coverUrl'],
      createTime: json['createTime'],
      description: json['description'],
      favoriteCount: json['favoriteCount'],
      id: json['id'],
      lastPublishTime: json['lastPublishTime'],
      name: json['name'],
      postCount: json['postCount'],
      status: json['status'],
      subscribed: json['subscribed'],
      tags: json['tags'],
      updateTime: json['updateTime'],
      viewCount: json['viewCount'],
      postCollectionHot: json['postCollectionHot'] ?? 0,
      lastReadPostId: json['lastReadPostId'] ?? 0,
      lastReadBlogId: json['lastReadBlogId'] ?? 0,
      subscribedCount: json['subscribedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['collectionType'] = collectionType;
    data['contentType'] = contentType;
    data['coverUrl'] = coverUrl;
    data['createTime'] = createTime;
    data['description'] = description;
    data['favoriteCount'] = favoriteCount;
    data['id'] = id;
    data['lastPublishTime'] = lastPublishTime;
    data['name'] = name;
    data['postCount'] = postCount;
    data['status'] = status;
    data['subscribed'] = subscribed;
    data['tags'] = tags;
    data['updateTime'] = updateTime;
    data['viewCount'] = viewCount;
    return data;
  }
}

class PhotoLink {
  String orign;
  String raw;
  String small;
  String middle;
  int rw;
  int rh;
  int ow;
  int oh;

  PhotoLink({
    required this.orign,
    required this.raw,
    required this.small,
    required this.middle,
    required this.rw,
    required this.rh,
    required this.ow,
    required this.oh,
  });

  factory PhotoLink.fromJson(Map<String, dynamic> json) {
    return PhotoLink(
      orign: json['orign'] ?? "",
      raw: json['raw'] ?? "",
      small: json['small'] ?? "",
      middle: json['middle'] ?? "",
      rw: json['rw'] ?? 0,
      rh: json['rh'] ?? 0,
      ow: json['ow'] ?? 0,
      oh: json['oh'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['orign'] = orign;
    data['raw'] = raw;
    data['small'] = small;
    data['middle'] = middle;
    data['rw'] = rw;
    data['rh'] = rh;
    data['ow'] = ow;
    data['oh'] = oh;
    return data;
  }
}

class PreviewImage {
  String baseImage;
  int oh;
  int ow;
  String raw;

  PreviewImage({
    required this.baseImage,
    required this.oh,
    required this.ow,
    required this.raw,
  });

  factory PreviewImage.fromJson(Map<String, dynamic> json) {
    return PreviewImage(
      baseImage: json['baseImage'] ?? json['raw'] ?? "",
      oh: json['oh'],
      ow: json['ow'],
      raw: json['raw'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['baseImage'] = baseImage;
    data['oh'] = oh;
    data['ow'] = ow;
    data['raw'] = raw;
    return data;
  }

  @override
  String toString() {
    return 'PreviewImage{baseImage: $baseImage, oh: $oh, ow: $ow, raw: $raw}';
  }
}

///PhotoPostView
class PhotoPostView {
  ///作者ID
  int blogId;

  ///说明
  String caption;

  ///首张图片
  FirstImage firstImage;

  ///？
  dynamic h5Info;

  ///帖子ID
  int id;

  ///？
  dynamic liverInfo;

  ///图片说明列表
  List<String> photoCaptions;

  ///文件Exif信息
  List<String>? photoExifs;

  ///图片列表
  List<SimplePhotoLink> photoLinks;

  ///图片类型
  int photoType;

  ///？
  dynamic product;

  ///？
  dynamic shareCollectionInfo;

  ///？
  dynamic shareGrainInfo;

  ///？
  dynamic shareSubFolderInfo;

  PhotoPostView({
    required this.blogId,
    required this.caption,
    required this.firstImage,
    this.h5Info,
    required this.id,
    this.liverInfo,
    required this.photoCaptions,
    this.photoExifs,
    required this.photoLinks,
    required this.photoType,
    this.product,
    this.shareCollectionInfo,
    this.shareGrainInfo,
    this.shareSubFolderInfo,
  });

  factory PhotoPostView.fromJson(Map<String, dynamic> json) {
    return PhotoPostView(
      blogId: json['blogId'],
      caption: json['caption'],
      firstImage: FirstImage.fromJson(json['firstImage']),
      h5Info: json['h5Info'],
      id: json['id'],
      liverInfo: json['liverInfo'],
      photoCaptions:
          (json['photoCaptions'] as List).map((v) => v as String).toList(),
      photoExifs: json['photoExifs'] != null
          ? (json['photoExifs'] as List).map((v) => v as String).toList()
          : null,
      photoLinks: (json['photoLinks'] as List)
          .map((v) => SimplePhotoLink.fromJson(v))
          .toList(),
      photoType: json['photoType'],
      product: json['product'],
      shareCollectionInfo: json['shareCollectionInfo'],
      shareGrainInfo: json['shareGrainInfo'],
      shareSubFolderInfo: json['shareSubFolderInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['caption'] = caption;
    data['firstImage'] = firstImage.toJson();
    data['h5Info'] = h5Info;
    data['id'] = id;
    data['liverInfo'] = liverInfo;
    data['photoCaptions'] = photoCaptions;
    data['photoExifs'] = photoExifs;
    data['photoLinks'] = photoLinks.map((v) => v.toJson()).toList();
    data['photoType'] = photoType;
    data['product'] = product;
    data['shareCollectionInfo'] = shareCollectionInfo;
    data['shareGrainInfo'] = shareGrainInfo;
    data['shareSubFolderInfo'] = shareSubFolderInfo;
    return data;
  }
}

///SimplePhotoLink
class SimplePhotoLink {
  ///？
  dynamic labels;

  ///高度
  int oh;

  ///图片地址
  String orign;

  ///宽度
  int ow;

  ///？
  dynamic trades;

  SimplePhotoLink({
    required this.labels,
    required this.oh,
    required this.orign,
    required this.ow,
    required this.trades,
  });

  factory SimplePhotoLink.fromJson(Map<String, dynamic> json) {
    return SimplePhotoLink(
      labels: json['labels'],
      oh: json['oh'],
      orign: json['orign'],
      ow: json['ow'],
      trades: json['trades'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['labels'] = labels;
    data['oh'] = oh;
    data['orign'] = orign;
    data['ow'] = ow;
    data['trades'] = trades;
    return data;
  }
}

///Comment
class Comment {
  int blogId;
  String content;
  List<CommentEmote> emotes;
  int id;
  String ipLocation;
  List<Comment> l2Comments;
  int l2Count;
  int likeCount;
  bool liked;
  int postId;
  bool l2CommentLoading = false;
  SimpleBlogInfo publisherBlogInfo;
  SimpleBlogInfo? replyBlogInfo;
  int publishTime;
  int replyL1CommentId;
  int replyL2CommentId;
  int top;
  int l2CommentOffset;

  Comment({
    required this.blogId,
    required this.content,
    required this.emotes,
    required this.id,
    required this.ipLocation,
    required this.l2Comments,
    required this.l2Count,
    required this.likeCount,
    required this.liked,
    required this.postId,
    required this.publisherBlogInfo,
    required this.publishTime,
    required this.replyL1CommentId,
    required this.replyL2CommentId,
    required this.top,
    required this.replyBlogInfo,
    required this.l2CommentOffset,
  }) {
    l2CommentOffset = l2Comments.length;
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      l2CommentOffset: -1,
      blogId: json['blogId'],
      content: json['content'],
      emotes: json['emotes'] != null
          ? (json['emotes'] as List)
              .map((v) => CommentEmote.fromJson(v))
              .toList()
          : [],
      id: json['id'],
      ipLocation: json['ipLocation'] ?? "",
      l2Comments: json['l2Comments'] != null
          ? (json['l2Comments'] as List)
              .map((v) => Comment.fromJson(v))
              .toList()
          : [],
      l2Count: json['l2Count'] ?? 0,
      likeCount: json['likeCount'],
      liked: json['liked'],
      postId: json['postId'],
      publisherBlogInfo: SimpleBlogInfo.fromJson(json['publisherBlogInfo']),
      publishTime: json['publishTime'],
      replyL1CommentId: json['replyL1CommentId'],
      replyL2CommentId: json['replyL2CommentId'],
      top: json['top'],
      replyBlogInfo: json['replyBlogInfo'] != null
          ? SimpleBlogInfo.fromJson(json['replyBlogInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['content'] = content;
    data['emotes'] = emotes.map((v) => v.toJson()).toList();
    data['id'] = id;
    data['ipLocation'] = ipLocation;
    data['l2Comments'] = l2Comments;
    data['l2Count'] = l2Count;
    data['likeCount'] = likeCount;
    data['liked'] = liked;
    data['postId'] = postId;
    data['publisherBlogInfo'] = publisherBlogInfo.toJson();
    data['publishTime'] = publishTime;
    data['replyL1CommentId'] = replyL1CommentId;
    data['replyL2CommentId'] = replyL2CommentId;
    data['top'] = top;
    return data;
  }
}

class CommentEmote {
  int id;
  String name;
  int sizeType;
  String url;

  CommentEmote({
    required this.id,
    required this.name,
    required this.sizeType,
    required this.url,
  });

  factory CommentEmote.fromJson(Map<String, dynamic> json) {
    return CommentEmote(
      id: json['id'],
      name: json['name'],
      sizeType: json['sizeType'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['sizeType'] = sizeType;
    data['url'] = url;
    return data;
  }
}
