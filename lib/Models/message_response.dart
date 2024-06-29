import 'dart:convert';

import 'account_response.dart';

///LikeMessageItem
class MessageItem {
  FullBlogInfo actUserBlogInfo;
  int actUserId;
  int blogId;
  FullBlogInfo blogInfo;
  int commentLikeType;
  String content;
  late SimpleMessagePost simplePost;
  String defString;
  int id;
  int publishTime;
  String thumbnail;
  int type;

  MessageItem({
    required this.actUserBlogInfo,
    required this.actUserId,
    required this.blogId,
    required this.blogInfo,
    required this.commentLikeType,
    required this.content,
    required this.defString,
    required this.id,
    required this.publishTime,
    required this.thumbnail,
    required this.type,
  }) {
    simplePost = SimpleMessagePost.fromJson(
      jsonDecode(content),
      blogId,
    );
  }

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      actUserBlogInfo: FullBlogInfo.fromJson(json['actUserBlogInfo']),
      actUserId: json['actUserId'],
      blogId: json['blogId'],
      blogInfo: FullBlogInfo.fromJson(json['blogInfo']),
      commentLikeType: json['commentLikeType'],
      content: json['content'],
      defString: json['defString'],
      id: json['id'],
      publishTime: json['publishTime'],
      thumbnail: json['thumbnail'],
      type: json['type'],
    );
  }
}

class SimpleMessagePost {
  int postViewRank;
  int blogId;
  String postUrl;

  String bigAvaImg;

  String blogNickName;

  String blogName;

  String postPermalink;

  int postId;

  String postTitle;

  int postType;

  int isReblog;

  SimpleMessagePost({
    required this.blogId,
    required this.postViewRank,
    required this.postUrl,
    required this.bigAvaImg,
    required this.blogNickName,
    required this.blogName,
    required this.postPermalink,
    required this.postId,
    required this.postTitle,
    required this.postType,
    required this.isReblog,
  });

  factory SimpleMessagePost.fromJson(Map<String, dynamic> json, int blogId) {
    return SimpleMessagePost(
      blogId: blogId,
      postViewRank: json['postViewRank'],
      postUrl: json['postUrl'],
      bigAvaImg: json['bigAvaImg'],
      blogNickName: json['blogNickName'],
      blogName: json['blogName'],
      postPermalink: json['postPermalink'],
      postId: json['postId'],
      postTitle: json['postTitle'],
      postType: json['postType'],
      isReblog: json['isReblog'],
    );
  }
}
