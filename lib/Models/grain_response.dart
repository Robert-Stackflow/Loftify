import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Models/recommend_response.dart';

import 'collection_response.dart';

///GrainDetailData
class GrainDetailData {
  SimpleBlogInfo blogInfo;
  int commentCount;
  bool followStatus;
  GrainInfo grainInfo;
  int offset;
  List<GrainPostItem> posts;

  GrainDetailData({
    required this.blogInfo,
    required this.commentCount,
    required this.followStatus,
    required this.grainInfo,
    required this.offset,
    required this.posts,
  });

  factory GrainDetailData.fromJson(Map<String, dynamic> json) {
    return GrainDetailData(
      blogInfo: SimpleBlogInfo.fromJson(json['blogInfo']),
      commentCount: json['commentCount'],
      followStatus: json['followStatus'],
      grainInfo: GrainInfo.fromJson(json['grainInfo']),
      offset: json['offset'],
      posts: List<GrainPostItem>.from(
          json['posts'].map((x) => GrainPostItem.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogInfo'] = blogInfo.toJson();
    data['commentCount'] = commentCount;
    data['followStatus'] = followStatus;
    data['grainInfo'] = grainInfo.toJson();
    data['offset'] = offset;
    data['posts'] = posts.map((x) => x.toJson()).toList();
    return data;
  }
}

///GrainPostItem
class GrainPostItem {
  bool followed;
  bool liked;
  int opTime;
  GrainPostData postData;
  bool shared;
  bool showFullText;
  bool subscribed;

  GrainPostItem({
    required this.followed,
    required this.liked,
    required this.opTime,
    required this.postData,
    required this.shared,
    required this.showFullText,
    required this.subscribed,
  });

  factory GrainPostItem.fromJson(Map<String, dynamic> json) {
    return GrainPostItem(
      followed: json['followed'],
      liked: json['liked'],
      opTime: json['opTime'],
      postData: GrainPostData.fromJson(json['postData']),
      shared: json['shared'],
      showFullText: json['showFullText'],
      subscribed: json['subscribed'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['followed'] = followed;
    data['liked'] = liked;
    data['opTime'] = opTime;
    data['postData'] = postData.toJson();
    data['shared'] = shared;
    data['showFullText'] = showFullText;
    data['subscribed'] = subscribed;
    return data;
  }
}

///GrainPostData
class GrainPostData {
  SimpleBlogInfo blogInfo;
  PostCollection? postCollection;
  PostCount postCountView;
  PostExt? postExt;
  PostDetail postView;

  GrainPostData({
    required this.blogInfo,
    required this.postCollection,
    required this.postCountView,
    required this.postExt,
    required this.postView,
  });

  factory GrainPostData.fromJson(Map<String, dynamic> json) {
    return GrainPostData(
      blogInfo: SimpleBlogInfo.fromJson(json['blogInfo']),
      postCollection: json['postCollection'] != null
          ? PostCollection.fromJson(json['postCollection'])
          : null,
      postCountView: PostCount.fromJson(json['postCountView']),
      postExt:
          json['postExt'] != null ? PostExt.fromJson(json['postExt']) : null,
      postView: PostDetail.fromJson(json['postView']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogInfo'] = blogInfo.toJson();
    data['postCollection'] = postCollection?.toJson();
    data['postCountView'] = postCountView.toJson();
    data['postExt'] = postExt?.toJson();
    data['postView'] = postView.toJson();
    return data;
  }
}

///PostExt，扩展项
class PostExt {
  int applyStatus;
  bool infringement;
  bool newVersionAuditing;
  String postUrl;

  PostExt({
    required this.applyStatus,
    required this.infringement,
    required this.newVersionAuditing,
    required this.postUrl,
  });

  factory PostExt.fromJson(Map<String, dynamic> json) {
    return PostExt(
      applyStatus: json['applyStatus'],
      infringement: json['infringement'],
      newVersionAuditing: json['newVersionAuditing'],
      postUrl: json['postUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['applyStatus'] = applyStatus;
    data['infringement'] = infringement;
    data['newVersionAuditing'] = newVersionAuditing;
    data['postUrl'] = postUrl;
    return data;
  }
}

///GrainData
class GrainData {
  SimpleBlogInfo? blogInfo;
  GrainInfo? grain;
  SimplePost? latestPost;
  int? unreadCount;

  GrainData({
    this.blogInfo,
    this.grain,
    this.latestPost,
    this.unreadCount,
  });

  factory GrainData.fromJson(Map<String, dynamic> json) {
    return GrainData(
      blogInfo: json['blogInfo'] != null
          ? SimpleBlogInfo.fromJson(json['blogInfo'])
          : null,
      grain: json['grain'] != null ? GrainInfo.fromJson(json['grain']) : null,
      latestPost: json['latestPost'] != null
          ? SimplePost.fromJson(json['latestPost'])
          : null,
      unreadCount: json['unreadCount'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (blogInfo != null) {
      data['blogInfo'] = blogInfo!.toJson();
    }
    if (grain != null) {
      data['grain'] = grain!.toJson();
    }
    if (latestPost != null) {
      data['latestPost'] = latestPost!.toJson();
    }
    data['unreadCount'] = unreadCount;
    return data;
  }
}
