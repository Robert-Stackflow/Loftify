import 'package:loftify/Models/recommend_response.dart';

///ShowCaseItem
class ShowCaseItem {
  String icon;
  int itemId;
  SimplePostData? postSimpleData;
  PostCollection? postCollection;
  int type;

  ShowCaseItem({
    required this.icon,
    required this.itemId,
    required this.postSimpleData,
    required this.type,
    required this.postCollection,
  });

  factory ShowCaseItem.fromJson(Map<String, dynamic> json) {
    return ShowCaseItem(
      icon: json['icon'] ?? "",
      itemId: json['itemId'],
      postSimpleData: json['postSimpleData'] != null
          ? SimplePostData.fromJson(json['postSimpleData'])
          : null,
      postCollection: json['postCollection'] != null
          ? PostCollection.fromJson(json['postCollection'])
          : null,
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['icon'] = icon;
    data['itemId'] = itemId;
    data['postSimpleData'] = postSimpleData?.toJson();
    data['postCollection'] = postCollection?.toJson();
    data['type'] = type;
    return data;
  }
}

///SimplePostData
class SimplePostData {
  PostCount postCountView;
  SimplePostView postView;

  SimplePostData({
    required this.postCountView,
    required this.postView,
  });

  factory SimplePostData.fromJson(Map<String, dynamic> json) {
    return SimplePostData(
      postCountView: PostCount.fromJson(json['postCountView']),
      postView: SimplePostView.fromJson(json['postView']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['postCountView'] = this.postCountView.toJson();
    data['postView'] = this.postView.toJson();
    return data;
  }
}

///SimplePostView
class SimplePostView {
  int allowReward;
  int allowView;
  bool auditing;
  int blogId;
  String blogName;
  int ccType;
  int citeParentBlogId;
  int citeParentPostId;
  int citeRootBlogId;
  int citeRootPostId;
  int collectionId;
  int createTime;
  String digest;
  int fansVipPost;
  FirstImage firstImage;
  bool forbid;
  int forbidJoinGrain;
  int forbidShare;
  int id;
  int isContribute;
  int locationId;
  String moveFrom;
  int payView;
  String permalink;
  int photoCount;
  bool publicOut;
  bool published;
  int publisherUserId;
  int publishTime;
  List<String> tagList;
  String title;
  int top;
  int type;
  int valid;
  int viewRank;
  bool viewRankPublic;

  SimplePostView({
    this.blogName = "",
    required this.allowReward,
    required this.allowView,
    required this.auditing,
    required this.blogId,
    required this.ccType,
    required this.citeParentBlogId,
    required this.citeParentPostId,
    required this.citeRootBlogId,
    required this.citeRootPostId,
    required this.collectionId,
    required this.createTime,
    required this.digest,
    required this.fansVipPost,
    required this.firstImage,
    required this.forbid,
    required this.forbidJoinGrain,
    required this.forbidShare,
    required this.id,
    required this.isContribute,
    required this.locationId,
    required this.moveFrom,
    required this.payView,
    required this.permalink,
    required this.photoCount,
    required this.publicOut,
    required this.published,
    required this.publisherUserId,
    required this.publishTime,
    required this.tagList,
    required this.title,
    required this.top,
    required this.type,
    required this.valid,
    required this.viewRank,
    required this.viewRankPublic,
  });

  factory SimplePostView.fromJson(Map<String, dynamic> json) {
    return SimplePostView(
      allowReward: json['allowReward'],
      allowView: json['allowView'],
      auditing: json['auditing'],
      blogId: json['blogId'],
      ccType: json['ccType'],
      citeParentBlogId: json['citeParentBlogId'],
      citeParentPostId: json['citeParentPostId'],
      citeRootBlogId: json['citeRootBlogId'],
      citeRootPostId: json['citeRootPostId'],
      collectionId: json['collectionId'],
      createTime: json['createTime'],
      digest: json['digest'],
      fansVipPost: json['fansVipPost'],
      firstImage: FirstImage.fromJson(json['firstImage']),
      forbid: json['forbid'],
      forbidJoinGrain: json['forbidJoinGrain'],
      forbidShare: json['forbidShare'],
      id: json['id'],
      isContribute: json['isContribute'],
      locationId: json['locationId'],
      moveFrom: json['moveFrom'] ?? "",
      payView: json['payView'],
      permalink: json['permalink'],
      photoCount: json['photoCount'],
      publicOut: json['publicOut'],
      published: json['published'],
      publisherUserId: json['publisherUserId'],
      publishTime: json['publishTime'],
      tagList: List<String>.from(json['tagList']),
      title: json['title'],
      top: json['top'],
      type: json['type'],
      valid: json['valid'],
      viewRank: json['viewRank'],
      viewRankPublic: json['viewRankPublic'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['allowReward'] = this.allowReward;
    data['allowView'] = this.allowView;
    data['auditing'] = this.auditing;
    data['blogId'] = this.blogId;
    data['ccType'] = this.ccType;
    data['citeParentBlogId'] = this.citeParentBlogId;
    data['citeParentPostId'] = this.citeParentPostId;
    data['citeRootBlogId'] = this.citeRootBlogId;
    data['citeRootPostId'] = this.citeRootPostId;
    data['collectionId'] = this.collectionId;
    data['createTime'] = this.createTime;
    data['digest'] = this.digest;
    data['fansVipPost'] = this.fansVipPost;
    data['firstImage'] = this.firstImage.toJson();
    data['forbid'] = this.forbid;
    data['forbidJoinGrain'] = this.forbidJoinGrain;
    data['forbidShare'] = this.forbidShare;
    data['id'] = this.id;
    data['isContribute'] = this.isContribute;
    data['locationId'] = this.locationId;
    data['moveFrom'] = this.moveFrom;
    data['payView'] = this.payView;
    data['permalink'] = this.permalink;
    data['photoCount'] = this.photoCount;
    data['publicOut'] = this.publicOut;
    data['published'] = this.published;
    data['publisherUserId'] = this.publisherUserId;
    data['publishTime'] = this.publishTime;
    data['tagList'] = this.tagList;
    data['title'] = this.title;
    data['top'] = this.top;
    data['type'] = this.type;
    data['valid'] = this.valid;
    data['viewRank'] = this.viewRank;
    data['viewRankPublic'] = this.viewRankPublic;
    return data;
  }
}
