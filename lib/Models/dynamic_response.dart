import 'package:loftify/Models/collection_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/tag_response.dart';

///SubscribeTagItem
class SubscribeTagItem {
  String image;
  String name;
  List<RemindItem>? remindList;
  bool subscribe;
  int unreadCount;

  SubscribeTagItem({
    required this.image,
    required this.name,
    required this.remindList,
    required this.subscribe,
    required this.unreadCount,
  });

  factory SubscribeTagItem.fromJson(Map<String, dynamic> json) {
    return SubscribeTagItem(
      image: json['image'],
      name: json['name'],
      remindList: json['remindList'] != null
          ? (json['remindList'] as List)
              .map((e) => RemindItem.fromJson(e))
              .toList()
          : null,
      subscribe: json['subscribe'],
      unreadCount: json['unreadCount'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['image'] = image;
    data['name'] = name;
    data['remindList'] = remindList?.map((v) => v.toJson()).toList();
    data['subscribe'] = subscribe;
    data['unreadCount'] = unreadCount;
    return data;
  }
}

///RemindItem
class RemindItem {
  String desc;
  int type;

  RemindItem({
    required this.desc,
    required this.type,
  });

  factory RemindItem.fromJson(Map<String, dynamic> json) {
    return RemindItem(
      desc: json['desc'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['desc'] = desc;
    data['type'] = type;
    return data;
  }
}

///FullSubscribeTagItem
class FullSubscribeTagItem {
  CardInfo? cardInfo;
  String name;
  String slogan;
  bool subscribe;
  String? image;
  int subscribeCount;
  String tagRankName;
  List<Thumbnail> thumbnails;
  int top;
  int unreadCount;

  FullSubscribeTagItem({
    required this.cardInfo,
    required this.name,
    required this.slogan,
    required this.subscribe,
    required this.subscribeCount,
    required this.tagRankName,
    required this.thumbnails,
    required this.top,
    required this.unreadCount,
    this.image,
  });

  factory FullSubscribeTagItem.fromJson(Map<String, dynamic> json) {
    return FullSubscribeTagItem(
      cardInfo:
          json['cardInfo'] != null ? CardInfo.fromJson(json['cardInfo']) : null,
      name: json['name'],
      slogan: json['slogan'] ?? "",
      subscribe: json['subscribe'] ?? false,
      subscribeCount: json['subscribeCount'] ?? 0,
      tagRankName: json['tagRankName'] ?? "",
      thumbnails: (json['thumbnails'] as List)
          .map((e) => Thumbnail.fromJson(e))
          .toList(),
      top: json['top'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
      image: json['image'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cardInfo'] = cardInfo?.toJson();
    data['name'] = name;
    data['slogan'] = slogan;
    data['subscribe'] = subscribe;
    data['subscribeCount'] = subscribeCount;
    data['tagRankName'] = tagRankName;
    data['thumbnails'] = thumbnails.map((v) => v.toJson()).toList();
    data['top'] = top;
    data['unreadCount'] = unreadCount;
    return data;
  }
}

class CardInfo {
  CollectionCard? collectionCard;
  TagPostCard? postCard;
  BlogCard? blogCard;
  String recommendMsg;
  int type;

  CardInfo({
    required this.blogCard,
    required this.collectionCard,
    required this.postCard,
    required this.recommendMsg,
    required this.type,
  });

  factory CardInfo.fromJson(Map<String, dynamic> json) {
    return CardInfo(
      blogCard:
          json['blogCard'] != null ? BlogCard.fromJson(json['blogCard']) : null,
      collectionCard: json['collectionCard'] != null
          ? CollectionCard.fromJson(json['collectionCard'])
          : null,
      postCard: json['postCard'] != null
          ? TagPostCard.fromJson(json['postCard'])
          : null,
      recommendMsg: json['recommendMsg'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogCard'] = blogCard;
    data['collectionCard'] = collectionCard?.toJson();
    data['postCard'] = postCard?.toJson();
    data['recommendMsg'] = recommendMsg;
    data['type'] = type;
    return data;
  }
}

///TagCollectionCard
class CollectionCard {
  SimpleCollectionInfo collectionInfo;

  CollectionCard({
    required this.collectionInfo,
  });

  factory CollectionCard.fromJson(Map<String, dynamic> json) {
    return CollectionCard(
      collectionInfo: SimpleCollectionInfo.fromJson(json['collectionInfo']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['collectionInfo'] = collectionInfo.toJson();
    return data;
  }
}

class TagPostCard {
  int postHot;
  SimplePost postInfo;
  int postViewCount;

  TagPostCard({
    required this.postHot,
    required this.postInfo,
    required this.postViewCount,
  });

  factory TagPostCard.fromJson(Map<String, dynamic> json) {
    return TagPostCard(
      postHot: json['postHot'],
      postInfo: SimplePost.fromJson(json['postInfo']),
      postViewCount: json['postViewCount'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['postHot'] = postHot;
    data['postInfo'] = postInfo.toJson();
    data['postViewCount'] = postViewCount;
    return data;
  }
}

class BlogCard {
  SimpleBlogInfo blogInfo;
  int rankType;
  String rankName;
  int circleHot;
  int blogId;

  BlogCard({
    required this.blogInfo,
    required this.rankType,
    required this.rankName,
    required this.circleHot,
    required this.blogId,
  });

  factory BlogCard.fromJson(Map<String, dynamic> json) {
    return BlogCard(
      blogInfo: SimpleBlogInfo.fromJson(json['blogInfo']),
      rankType: json['rankType'],
      rankName: json['rankName'] ?? "",
      circleHot: json['circleHot'],
      blogId: json['blogId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogInfo'] = blogInfo.toJson();
    data['rankType'] = rankType;
    data['rankName'] = rankName;
    data['circleCount'] = circleHot;
    data['blogId'] = blogId;
    return data;
  }
}

///TagThumbnail
class Thumbnail {
  String? digest;
  String? image;
  String? title;

  Thumbnail({
    required this.digest,
    required this.image,
    required this.title,
  });

  factory Thumbnail.fromJson(Map<String, dynamic> json) {
    return Thumbnail(
      digest: json['digest'],
      image: json['image'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['digest'] = digest;
    data['image'] = image;
    data['title'] = title;
    return data;
  }
}

///TimelineCollection
class TimelineCollection {
  int blogId;
  int collectionId;
  int collectionType;
  int contentType;
  String coverUrl;
  int lastReadBlogId;
  int lastReadPostId;
  List<String>? latestPosts;
  String name;
  int recentlyRead;
  int subscribeId;
  int unreadCount;
  bool valid;

  TimelineCollection({
    required this.blogId,
    required this.collectionId,
    required this.collectionType,
    required this.contentType,
    required this.coverUrl,
    required this.lastReadBlogId,
    required this.lastReadPostId,
    this.latestPosts,
    required this.name,
    required this.recentlyRead,
    required this.subscribeId,
    required this.unreadCount,
    required this.valid,
  });

  factory TimelineCollection.fromJson(Map<String, dynamic> json) {
    return TimelineCollection(
      blogId: json['blogId'],
      collectionId: json['collectionId'],
      collectionType: json['collectionType'],
      contentType: json['contentType'],
      coverUrl: json['coverUrl'],
      lastReadBlogId: json['lastReadBlogId'],
      lastReadPostId: json['lastReadPostId'],
      latestPosts: json['latestPosts'] != null
          ? List<String>.from(json['latestPosts'])
          : null,
      name: json['name'],
      recentlyRead: json['recentlyRead'],
      subscribeId: json['subscribeId'],
      unreadCount: json['unreadCount'],
      valid: json['valid'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['collectionId'] = collectionId;
    data['collectionType'] = collectionType;
    data['contentType'] = contentType;
    data['coverUrl'] = coverUrl;
    data['lastReadBlogId'] = lastReadBlogId;
    data['lastReadPostId'] = lastReadPostId;
    data['latestPosts'] = latestPosts;
    data['name'] = name;
    data['recentlyRead'] = recentlyRead;
    data['subscribeId'] = subscribeId;
    data['unreadCount'] = unreadCount;
    data['valid'] = valid;
    return data;
  }
}

///TimelineGuessCollection
class TimelineGuessCollection {
  int blogId;
  int collectionId;
  String coverUrl;
  int lastReadBlogId;
  int lastReadPostId;
  String latestPost;
  String name;
  int postCount;
  int subscribeCount;
  bool subscribed;
  String tags;
  String reason;

  TimelineGuessCollection({
    required this.reason,
    required this.blogId,
    required this.collectionId,
    required this.coverUrl,
    required this.lastReadBlogId,
    required this.lastReadPostId,
    required this.latestPost,
    required this.name,
    required this.postCount,
    required this.subscribeCount,
    required this.subscribed,
    required this.tags,
  });

  factory TimelineGuessCollection.fromJson(Map<String, dynamic> json) {
    return TimelineGuessCollection(
      blogId: json['blogId'],
      collectionId: json['collectionId'],
      coverUrl: json['coverUrl'],
      lastReadBlogId: json['lastReadBlogId'],
      lastReadPostId: json['lastReadPostId'],
      latestPost: json['latestPost'],
      name: json['name'],
      postCount: json['postCount'],
      subscribeCount: json['subscribeCount'],
      subscribed: json['subscribed'],
      tags: json['tags'],
      reason: json['reason'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['collectionId'] = collectionId;
    data['coverUrl'] = coverUrl;
    data['lastReadBlogId'] = lastReadBlogId;
    data['lastReadPostId'] = lastReadPostId;
    data['latestPost'] = latestPost;
    data['name'] = name;
    data['postCount'] = postCount;
    data['subscribeCount'] = subscribeCount;
    data['subscribed'] = subscribed;
    data['tags'] = tags;
    return data;
  }
}

class SubscribeGrainItem {
  GrainInfo grain;
  SimpleBlogInfo blogInfo;
  SimplePost latestPost;
  int unreadCount;

  SubscribeGrainItem({
    required this.grain,
    required this.blogInfo,
    required this.latestPost,
    required this.unreadCount,
  });

  factory SubscribeGrainItem.fromJson(Map<String, dynamic> json) {
    return SubscribeGrainItem(
      grain: GrainInfo.fromJson(json['grain']),
      blogInfo: SimpleBlogInfo.fromJson(json['blogInfo']),
      latestPost: SimplePost.fromJson(json['latestPost']),
      unreadCount: json['unreadCount'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['grain'] = grain.toJson();
    data['blogInfo'] = blogInfo.toJson();
    data['latestPost'] = latestPost.toJson();
    data['unreadCount'] = unreadCount;
    return data;
  }
}
