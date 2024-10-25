import 'package:loftify/Models/collection_response.dart';

import '../Utils/utils.dart';

///PostListItem
class PostListItem {
  ///作者信息
  SimpleBlogInfo? blogInfo;

  ///作者推广信息
  DirectInfo? directInfo;

  ///是否喜欢
  bool favorite;

  ///是否关注
  bool following;

  ///当推荐粮单时使用，粮单信息
  GrainInfo? grainInfo;

  ///？
  dynamic groupInfo;

  ///帖子ID，与postView.id相同
  int itemId;

  ///帖子类型
  int itemType;

  ///评论列表
  List<SimpleComment>? mountCommentList;

  ///？
  dynamic postCollection;

  ///帖子数据
  PostData? postData;

  ///与recommendReport.recReasonType一致
  String? reason;

  ///包含评论列表时使用，说明有多少人在讨论
  ReasonInfo? reasonInfo;

  ///推荐报告（显示在瀑布流左下角红色tag）
  RecommendReport? recommendReport;

  ///是否推荐
  bool? share;
  bool? showGift;
  bool? subscribe;

  PostListItem({
    this.blogInfo,
    this.directInfo,
    required this.favorite,
    required this.following,
    this.grainInfo,
    required this.groupInfo,
    required this.itemId,
    required this.itemType,
    this.mountCommentList,
    required this.postCollection,
    this.postData,
    this.reason,
    this.reasonInfo,
    this.recommendReport,
    this.share,
    this.showGift,
    this.subscribe,
  });

  factory PostListItem.fromJson(Map<String, dynamic> json) {
    return PostListItem(
      blogInfo: json['blogInfo'] != null
          ? SimpleBlogInfo.fromJson(json['blogInfo'])
          : null,
      directInfo: json['directInfo'] != null
          ? DirectInfo.fromJson(json['directInfo'])
          : null,
      favorite: json['favorite'],
      following: json['following'],
      grainInfo: json['grainInfo'] != null
          ? GrainInfo.fromJson(json['grainInfo'])
          : null,
      groupInfo: json['groupInfo'],
      itemId: json['itemId'] ?? 0,
      itemType: json['itemType'] ?? 0,
      mountCommentList: json['mountCommentList'] != null
          ? (json['mountCommentList'] as List)
              .map((e) => SimpleComment.fromJson(e))
              .toList()
          : null,
      postCollection: json['postCollection'] != null
          ? PostCollection.fromJson(json['postCollection'])
          : null,
      postData:
          json['postData'] != null ? PostData.fromJson(json['postData']) : null,
      reason: json['reason'],
      reasonInfo: json['reasonInfo'] != null
          ? ReasonInfo.fromJson(json['reasonInfo'])
          : null,
      recommendReport: json['recommendReport'] != null
          ? RecommendReport.fromJson(json['recommendReport'])
          : null,
      share: json['share'],
      showGift: json['showGift'],
      subscribe: json['subscribe'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogInfo'] = blogInfo;
    data['directInfo'] = directInfo;
    data['favorite'] = favorite;
    data['following'] = following;
    data['grainInfo'] = grainInfo;
    data['groupInfo'] = groupInfo;
    data['itemId'] = itemId;
    data['itemType'] = itemType;
    data['mountCommentList'] = mountCommentList;
    data['postCollection'] = postCollection;
    data['postData'] = postData;
    data['reason'] = reason;
    data['reasonInfo'] = reasonInfo;
    data['recommendReport'] = recommendReport;
    data['share'] = share;
    data['showGift'] = showGift;
    data['subscribe'] = subscribe;
    return data;
  }
}

///作者信息
///
///SimpleBlogInfo，作者信息
class SimpleBlogInfo {
  ///？
  String? authName;

  ///头像框地址
  String? avatarBoxImage;

  ///头像地址
  String bigAvaImg;

  ///作者ID
  int blogId;

  ///域名名称
  String blogName;

  ///昵称
  String blogNickName;

  ///卡片装扮
  CardDressing? cardDressing;

  ///？
  int extraBits;

  ///是否开启图片保护
  bool? imageProtected;

  ///是否为认证用户
  bool? isAuth;

  ///？
  bool? isVerify;

  ///自我介绍
  String? selfIntro;

  SimpleBlogInfo({
    this.authName,
    this.avatarBoxImage,
    required this.bigAvaImg,
    required this.blogId,
    required this.blogName,
    required this.blogNickName,
    this.cardDressing,
    required this.extraBits,
    this.imageProtected,
    this.isAuth,
    this.isVerify,
    this.selfIntro,
  });

  factory SimpleBlogInfo.fromJson(Map<String, dynamic> json) {
    return SimpleBlogInfo(
      authName: json['authName'],
      avatarBoxImage: json['avatarBoxImage'],
      bigAvaImg: json['bigAvaImg'],
      blogId: json['blogId'],
      blogName: json['blogName'],
      blogNickName: json['blogNickName'],
      cardDressing: json['cardDressing'] != null
          ? CardDressing.fromJson(json['cardDressing'])
          : null,
      extraBits: json['extraBits'] ?? 0,
      imageProtected: json['imageProtected'],
      isAuth: json['isAuth'],
      isVerify: json['isVerify'],
      selfIntro: json['selfIntro'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['authName'] = authName;
    data['avatarBoxImage'] = avatarBoxImage;
    data['bigAvaImg'] = bigAvaImg;
    data['blogId'] = blogId;
    data['blogName'] = blogName;
    data['blogNickName'] = blogNickName;
    data['cardDressing'] = cardDressing;
    data['extraBits'] = extraBits;
    data['imageProtected'] = imageProtected;
    data['isAuth'] = isAuth;
    data['isVerify'] = isVerify;
    data['selfIntro'] = selfIntro;
    return data;
  }
}

///卡片装扮
///
///CardDressing
class CardDressing {
  int partId;
  String partUrl;

  ///装扮ID
  int suitId;
  int userSuitId;

  CardDressing({
    required this.partId,
    required this.partUrl,
    required this.suitId,
    required this.userSuitId,
  });

  factory CardDressing.fromJson(Map<String, dynamic> json) {
    return CardDressing(
      partId: json['partId'],
      partUrl: json['partUrl'],
      suitId: json['suitId'],
      userSuitId: json['userSuitId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['partId'] = partId;
    data['partUrl'] = partUrl;
    data['suitId'] = suitId;
    data['userSuitId'] = userSuitId;
    return data;
  }
}

///作者推广信息
///
///DirectInfo
class DirectInfo {
  String directMsg;
  int directType;

  DirectInfo({
    required this.directMsg,
    required this.directType,
  });

  factory DirectInfo.fromJson(Map<String, dynamic> json) {
    return DirectInfo(
      directMsg: json['directMsg'] ?? "",
      directType: json['directType'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['directMsg'] = directMsg;
    data['directType'] = directType;
    return data;
  }
}

///当推荐粮单时使用，粮单信息
///
///GrainInfo，粮单信息
class GrainInfo {
  ///最近添加帖子时间
  int addPostTime;

  ///封面地址
  String coverUrl;

  SimplePost? simplePost;

  SimpleBlogInfo? blogInfo;

  ///创建时间
  int createTime;

  ///描述
  String description;

  ///？
  int endTime;

  ///？
  int exposure;

  ///？
  int greatLevel;

  ///热度
  int hotCount;

  ///？
  int hotPlanType;

  ///粮单ID
  int id;

  ///？
  int joinCount;

  ///？
  List<dynamic>? joinerAvatorList;

  ///最近订阅时间
  int lastSubscribeTime;

  ///粮单名称
  String name;

  ///？
  int planStatus;

  ///帖子数量
  int postCount;

  ///状态，默认为0
  int status;

  ///订阅量
  int subscribedCount;

  ///标签列表
  List<String> tags;

  ///类型，默认为0
  int type;

  ///更新时间
  int updateTime;

  ///作者ID
  int userId;

  ///浏览量
  int viewCount;

  GrainInfo({
    required this.addPostTime,
    required this.coverUrl,
    required this.createTime,
    required this.description,
    required this.endTime,
    required this.exposure,
    required this.greatLevel,
    required this.hotCount,
    required this.hotPlanType,
    required this.id,
    required this.joinCount,
    this.joinerAvatorList,
    required this.lastSubscribeTime,
    required this.name,
    required this.planStatus,
    required this.postCount,
    required this.status,
    required this.subscribedCount,
    required this.tags,
    required this.type,
    required this.updateTime,
    required this.userId,
    required this.viewCount,
    this.blogInfo,
    this.simplePost,
  });

  factory GrainInfo.fromJson(Map<String, dynamic> json) {
    return GrainInfo(
      addPostTime: json['addPostTime'],
      coverUrl: json['coverUrl'],
      createTime: json['createTime'],
      description: json['description'] ?? "",
      endTime: json['endTime'],
      exposure: json['exposure'],
      greatLevel: json['greatLevel'],
      hotCount: json['hotCount'],
      hotPlanType: json['hotPlanType'],
      id: json['id'],
      joinCount: json['joinCount'],
      joinerAvatorList: json['joinerAvatorList'],
      lastSubscribeTime: json['lastSubscribeTime'],
      name: json['name'],
      planStatus: json['planStatus'],
      postCount: json['postCount'],
      status: json['status'],
      subscribedCount: json['subscribedCount'],
      tags: (json['tags'] as List).map((e) => e.toString()).toList(),
      type: json['type'],
      updateTime: json['updateTime'],
      userId: json['userId'],
      viewCount: json['viewCount'],
      blogInfo: json['blogInfo'] != null
          ? SimpleBlogInfo.fromJson(json['blogInfo'])
          : null,
      simplePost: json['simplePost'] != null
          ? SimplePost.fromJson(json['simplePost'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['addPostTime'] = addPostTime;
    data['coverUrl'] = coverUrl;
    data['createTime'] = createTime;
    data['description'] = description;
    data['endTime'] = endTime;
    data['exposure'] = exposure;
    data['greatLevel'] = greatLevel;
    data['hotCount'] = hotCount;
    data['hotPlanType'] = hotPlanType;
    data['id'] = id;
    data['joinCount'] = joinCount;
    data['joinerAvatorList'] = joinerAvatorList;
    data['lastSubscribeTime'] = lastSubscribeTime;
    data['name'] = name;
    data['planStatus'] = planStatus;
    data['postCount'] = postCount;
    data['status'] = status;
    data['subscribedCount'] = subscribedCount;
    data['tags'] = tags;
    data['type'] = type;
    data['updateTime'] = updateTime;
    data['userId'] = userId;
    data['viewCount'] = viewCount;
    return data;
  }
}

///评论信息
///
///SimpleComment
class SimpleComment {
  ///评论作者ID
  int blogId;

  ///评论内容
  String content;

  ///评论ID
  int id;
  SimpleBlogInfo publisherBlogInfo;

  SimpleComment({
    required this.blogId,
    required this.content,
    required this.id,
    required this.publisherBlogInfo,
  });

  factory SimpleComment.fromJson(Map<String, dynamic> json) {
    return SimpleComment(
      blogId: json['blogId'],
      content: json['content'],
      id: json['id'],
      publisherBlogInfo: SimpleBlogInfo.fromJson(json['publisherBlogInfo']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['content'] = content;
    data['id'] = id;
    data['publisherBlogInfo'] = publisherBlogInfo;
    return data;
  }
}

///帖子数据
///
///PostData，帖子数据
class PostData {
  ///帖子合集信息
  PostCollection? postCollection;

  ///帖子统计数据
  PostCount? postCount;

  ///帖子详细信息
  PostView postView;

  PostData({
    this.postCollection,
    required this.postCount,
    required this.postView,
  });

  factory PostData.fromJson(Map<String, dynamic> json) {
    return PostData(
      postCollection: json['postCollection'] != null
          ? PostCollection.fromJson(json['postCollection'])
          : null,
      postCount: json['postCount'] != null
          ? PostCount.fromJson(json['postCount'])
          : null,
      postView: PostView.fromJson(json['postView']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['postCollection'] = postCollection;
    data['postCount'] = postCount;
    data['postView'] = postView;
    return data;
  }
}

///帖子合集信息
///
///PostCollection，帖子合集信息
class PostCollection {
  ///合集作者ID
  int blogId;

  ///合集类型，默认为0
  int collectionType;

  ///合集封面
  String coverUrl;

  ///合集ID
  int id;

  ///合集名称
  String name;

  ///帖子数量
  int postCount;
  int recShowType;

  ///是否订阅合集
  bool subscribed;

  ///合集标签列表
  List<String> tagList;

  ///浏览量
  int viewCount;

  int postCollectionHot;

  PostCollection({
    required this.blogId,
    required this.collectionType,
    required this.coverUrl,
    required this.id,
    required this.name,
    required this.postCount,
    required this.recShowType,
    required this.subscribed,
    required this.tagList,
    required this.viewCount,
    required this.postCollectionHot,
  });

  factory PostCollection.fromJson(Map<String, dynamic> json) {
    return PostCollection(
      blogId: json['blogId'],
      collectionType: json['collectionType'],
      coverUrl: json['coverUrl'],
      id: json['id'],
      name: json['name'],
      postCount: json['postCount'],
      recShowType: json['recShowType'] ?? 0,
      subscribed: json['subscribed'] ?? false,
      tagList: json['tagList'] != null
          ? (json['tagList'] as List).map((e) => e as String).toList()
          : [],
      viewCount: json['viewCount'] ?? 0,
      postCollectionHot: json['postCollectionHot'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['collectionType'] = collectionType;
    data['coverUrl'] = coverUrl;
    data['id'] = id;
    data['name'] = name;
    data['postCount'] = postCount;
    data['recShowType'] = recShowType;
    data['subscribed'] = subscribed;
    data['tagList'] = tagList;
    data['viewCount'] = viewCount;
    return data;
  }
}

///帖子统计数据
///
///PostCount，帖子数据
class PostCount {
  ///作者ID
  int? blogId;

  ///喜欢数
  int favoriteCount;

  ///热度值
  int? hotCount;
  int? postHot;

  ///转发数
  int reblogCount;

  ///回复数
  int responseCount;

  ///推荐数
  int shareCount;

  ///收藏数
  int subscribeCount;

  ///浏览量
  int viewCount;

  PostCount({
    this.blogId,
    required this.favoriteCount,
    this.hotCount,
    this.postHot,
    required this.reblogCount,
    required this.responseCount,
    required this.shareCount,
    required this.subscribeCount,
    required this.viewCount,
  });

  factory PostCount.fromJson(Map<String, dynamic> json) {
    return PostCount(
      blogId: json['blogId'],
      favoriteCount: json['favoriteCount'],
      hotCount: json['hotCount'],
      postHot: json['postHot'],
      reblogCount: json['reblogCount'],
      responseCount: json['responseCount'],
      shareCount: json['shareCount'],
      subscribeCount: json['subscribeCount'],
      viewCount: json['viewCount'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['favoriteCount'] = favoriteCount;
    data['hotCount'] = hotCount;
    data['postHot'] = postHot;
    data['reblogCount'] = reblogCount;
    data['responseCount'] = responseCount;
    data['shareCount'] = shareCount;
    data['subscribeCount'] = subscribeCount;
    data['viewCount'] = viewCount;
    return data;
  }
}

///帖子详细信息
///
///PostView，帖子详细信息
class PostView {
  ///作者ID
  int blogId;

  ///帖子摘要
  String digest;

  ///首张图片信息
  FirstImage? firstImage;

  ///是否禁止推荐
  int forbidShare;

  ///帖子ID
  int id;

  ///永久链接
  String permalink;

  ///图片数目
  int photoCount;

  ///帖子链接
  String postPageUrl;

  ///视频预览图片地址
  String? previewUrl;

  ///发布时间
  int publishTime;

  ///标签列表
  List<String> tagList;

  ///帖子标题
  String title;

  ///2表示图片帖子，4表示视频
  int type;

  ///视频信息
  VideoPostView? videoPostView;

  PostView({
    required this.blogId,
    required this.digest,
    this.firstImage,
    required this.forbidShare,
    required this.id,
    required this.permalink,
    required this.photoCount,
    required this.postPageUrl,
    this.previewUrl,
    required this.publishTime,
    required this.tagList,
    required this.title,
    required this.type,
    this.videoPostView,
  });

  factory PostView.fromJson(Map<String, dynamic> json) {
    return PostView(
      blogId: json['blogId'],
      digest: json['digest'],
      firstImage: json['firstImage'] != null
          ? FirstImage.fromJson(json['firstImage'])
          : null,
      forbidShare: json['forbidShare'],
      id: json['id'] ?? 0,
      permalink: json['permalink'],
      photoCount: json['photoCount'],
      postPageUrl: json['postPageUrl'] ?? "",
      previewUrl: json['previewUrl'],
      publishTime: json['publishTime'],
      tagList: (json['tagList'] as List).map((e) => e.toString()).toList(),
      title: json['title'] ?? "",
      type: json['type'],
      videoPostView: json['videoPostView'] != null
          ? VideoPostView.fromJson(json['videoPostView'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['digest'] = digest;
    data['firstImage'] = firstImage;
    data['forbidShare'] = forbidShare;
    data['id'] = id;
    data['permalink'] = permalink;
    data['photoCount'] = photoCount;
    data['postPageUrl'] = postPageUrl;
    data['previewUrl'] = previewUrl;
    data['publishTime'] = publishTime;
    data['tagList'] = tagList;
    data['title'] = title;
    data['type'] = type;
    data['videoPostView'] = videoPostView;
    return data;
  }
}

///首张图片信息
///
///FirstImage，首张图片信息
class FirstImage {
  ///高度
  int oh;

  ///图片地址
  String orign;

  ///宽度
  int ow;

  FirstImage({
    required this.oh,
    required this.orign,
    required this.ow,
  });

  factory FirstImage.fromJson(Map<String, dynamic> json) {
    return FirstImage(
      oh: json['oh'],
      orign: json['orign'],
      ow: json['ow'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['oh'] = oh;
    data['orign'] = orign;
    data['ow'] = ow;
    return data;
  }

  @override
  String toString() {
    return 'FirstImage{oh: $oh, orign: $orign, ow: $ow}';
  }
}

///视频信息
///
///VideoPostView，视频信息
class VideoPostView {
  ///作者ID
  int blogId;

  ///视频说明
  String caption;

  ///视频ID
  int id;

  ///播放量
  int playCount;

  ///创建时间
  int videoCreateTime;

  ///视频源信息
  VideoInfo videoInfo;

  ///？
  int videoType;

  VideoPostView({
    required this.blogId,
    required this.caption,
    required this.id,
    required this.playCount,
    required this.videoCreateTime,
    required this.videoInfo,
    required this.videoType,
  });

  factory VideoPostView.fromJson(Map<String, dynamic> json) {
    return VideoPostView(
      blogId: json['blogId'],
      caption: json['caption'],
      id: json['id'],
      playCount: json['playCount'],
      videoCreateTime: json['videoCreateTime'],
      videoInfo: VideoInfo.fromJson(json['videoInfo']),
      videoType: json['videoType'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['caption'] = caption;
    data['id'] = id;
    data['playCount'] = playCount;
    data['videoCreateTime'] = videoCreateTime;
    data['videoInfo'] = videoInfo;
    data['videoType'] = videoType;
    return data;
  }
}

///视频源信息
///
///VideoInfo，视频源信息
class VideoInfo {
  ///时长
  int duration;

  ///？
  String flashurl;

  ///？
  String h265Url;

  ///图片高度
  String imgHeight;

  ///图片宽度
  String imgWidth;

  ///视频源地址
  String originUrl;

  ///视频大小
  int size;

  ///uservideo表示用户视频
  String type;

  ///视频ID
  int vid;

  ///？
  String videoFirstImg;

  ///视频预览图片地址
  String videoImgUrl;

  VideoInfo({
    required this.duration,
    required this.flashurl,
    required this.h265Url,
    required this.imgHeight,
    required this.imgWidth,
    required this.originUrl,
    required this.size,
    required this.type,
    required this.vid,
    required this.videoFirstImg,
    required this.videoImgUrl,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    json['type'] = "uservideo";
    return VideoInfo(
      duration: Utils.parseToInt(json['duration']),
      flashurl: json['flashurl'] ?? "",
      h265Url: json['h265Url'] ?? "",
      imgHeight: json['imgHeight'] ?? json['img_height'] ?? "",
      imgWidth: json['imgWidth'] ?? json['img_width'] ?? "",
      originUrl: json['originUrl'] ?? "",
      size: Utils.parseToInt(json['size']),
      type: json['type'],
      vid: Utils.parseToInt(json['vid']),
      videoFirstImg: json['videoFirstImg'] ?? json['video_first_img'] ?? "",
      videoImgUrl: json['videoImgUrl'] ?? json['video_img_url'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['duration'] = duration;
    data['flashurl'] = flashurl;
    data['h265Url'] = h265Url;
    data['imgHeight'] = imgHeight;
    data['imgWidth'] = imgWidth;
    data['originUrl'] = originUrl;
    data['size'] = size;
    data['type'] = type;
    data['vid'] = vid;
    data['videoFirstImg'] = videoFirstImg;
    data['videoImgUrl'] = videoImgUrl;
    return data;
  }
}

///包含评论列表时使用，说明有多少人在讨论
///
///ReasonInfo
class ReasonInfo {
  String action;
  String icon;
  String msg;
  int type;

  ReasonInfo({
    required this.action,
    required this.icon,
    required this.msg,
    required this.type,
  });

  factory ReasonInfo.fromJson(Map<String, dynamic> json) {
    return ReasonInfo(
      action: json['action'] ?? "",
      icon: json['icon'] ?? "",
      msg: json['msg'] ?? "",
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['action'] = action;
    data['icon'] = icon;
    data['msg'] = msg;
    data['type'] = type;
    return data;
  }
}

///推荐报告（显示在瀑布流左下角红色tag）
///
///RecommendReport，推荐报告
class RecommendReport {
  ///算法信息
  String algInfo;

  ///推荐报告ID
  String recId;

  RecommendReport({
    required this.algInfo,
    required this.recId,
  });

  factory RecommendReport.fromJson(Map<String, dynamic> json) {
    return RecommendReport(
      algInfo: json['algInfo'],
      recId: json['recId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['algInfo'] = algInfo;
    data['recId'] = recId;
    return data;
  }
}
