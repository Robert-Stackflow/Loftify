///Collection
class Collection {
  ///作者ID
  int blogId;

  ///作者域名名称
  String blogName;

  ///类型
  int collectionType;

  ///封面地址
  String coverUrl;

  ///合集ID
  int id;

  ///最新发布时间
  int lastPublishTime;

  ///合集名称
  String name;

  ///帖子数量
  int postCount;

  ///帖子列表
  List<SimplePost>? posts;

  ///？
  String rankContent;

  ///？
  String rankUrl;

  ///是否订阅
  bool subscribed;

  ///标签列表
  List<String> tags;

  ///？
  bool top;

  Collection({
    required this.blogId,
    required this.blogName,
    required this.collectionType,
    required this.coverUrl,
    required this.id,
    required this.lastPublishTime,
    required this.name,
    required this.postCount,
    this.posts,
    required this.rankContent,
    required this.rankUrl,
    required this.subscribed,
    required this.tags,
    required this.top,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      blogId: json['blogId'],
      blogName: json['blogName'],
      collectionType: json['collectionType'],
      coverUrl: json['coverUrl'],
      id: json['id'],
      lastPublishTime: json['lastPublishTime'],
      name: json['name'],
      postCount: json['postCount'],
      posts: json['posts'] != null
          ? List<SimplePost>.from(
              json['posts'].map((x) => SimplePost.fromJson(x)))
          : null,
      rankContent: json['rankContent'],
      rankUrl: json['rankUrl'],
      subscribed: json['subscribed'],
      tags: List<String>.from(json['tags'].map((x) => x)),
      top: json['top'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['blogName'] = blogName;
    data['collectionType'] = collectionType;
    data['coverUrl'] = coverUrl;
    data['id'] = id;
    data['lastPublishTime'] = lastPublishTime;
    data['name'] = name;
    data['postCount'] = postCount;
    if (posts != null) {
      data['posts'] = posts!.map((v) => v.toJson()).toList();
    }
    data['rankContent'] = rankContent;
    data['rankUrl'] = rankUrl;
    data['subscribed'] = subscribed;
    data['tags'] = tags;
    data['top'] = top;
    return data;
  }
}

///SimplePost
class SimplePost {
  ///作者ID
  int blogId;

  ///摘要
  String digest;

  ///图片
  String image;

  ///永久链接
  String permalink;

  ///帖子ID
  int postId;

  ///发布时间
  int publishTime;

  ///标题
  String title;

  ///帖子类型
  int type;

  ///？
  int valid;

  SimplePost({
    required this.blogId,
    required this.digest,
    required this.image,
    required this.permalink,
    required this.postId,
    required this.publishTime,
    required this.title,
    required this.type,
    required this.valid,
  });

  factory SimplePost.fromJson(Map<String, dynamic> json) {
    return SimplePost(
      blogId: json['blogId'],
      digest: json['digest'],
      image: json['image'],
      permalink: json['permalink'],
      postId: json['postId'],
      publishTime: json['publishTime'],
      title: json['title'],
      type: json['type'],
      valid: json['valid'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['digest'] = digest;
    data['image'] = image;
    data['permalink'] = permalink;
    data['postId'] = postId;
    data['publishTime'] = publishTime;
    data['title'] = title;
    data['type'] = type;
    data['valid'] = valid;
    return data;
  }
}
