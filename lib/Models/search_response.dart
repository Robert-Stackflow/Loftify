import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Models/recommend_response.dart';

import 'enums.dart';

///GuessKeyword
class GuessKeyword {
  ///关键词
  String keyword;

  ///推荐报告
  RecommendReport recommendReport;

  ///类型
  int type;

  GuessKeyword({
    required this.keyword,
    required this.recommendReport,
    required this.type,
  });

  factory GuessKeyword.fromJson(Map<String, dynamic> json) {
    return GuessKeyword(
      keyword: json['keyword'],
      recommendReport: RecommendReport.fromJson(json['recommendReport']),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['keyword'] = keyword;
    data['recommendReport'] = recommendReport.toJson();
    data['type'] = type;
    return data;
  }
}

///RankListItem
class RankListItem {
  ///榜单内容列表
  List<RankItem> hotLists;

  ///榜单名称
  String listName;

  ///榜单规则地址
  String ruleUrl;

  ///榜单排序
  int sortNo;

  ///榜单类型，0为普通，1为游戏标签，3为图文视频帖子，4为合集，
  int type;

  RankListType rankListType;

  RankListItem({
    required this.hotLists,
    required this.listName,
    required this.ruleUrl,
    required this.sortNo,
    required this.type,
    this.rankListType = RankListType.unset,
  }) {
    rankListType = RankListType.values[type];
  }

  factory RankListItem.fromJson(Map<String, dynamic> json) {
    return RankListItem(
      hotLists: List<RankItem>.from(
          json['hotLists'].map((x) => RankItem.fromJson(x))),
      listName: json['listName'],
      ruleUrl: json['ruleUrl'],
      sortNo: json['sortNo'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hotLists'] = hotLists.map((x) => x.toJson()).toList();
    data['listName'] = listName;
    data['ruleUrl'] = ruleUrl;
    data['sortNo'] = sortNo;
    data['type'] = type;
    return data;
  }
}

///榜单内容项
///
///RankItem，榜单内容项
class RankItem {
  ///帖子作者ID
  int? blogId;

  ///图标地址
  String icon;

  ///图片地址
  String? img;

  ///交互量
  int interactionCount;

  ///？
  bool isAuth;

  ///？
  bool isVerify;

  ///帖子摘要
  String? postDigest;

  ///帖子ID
  int? postId;

  ///0表示搜索词，1表示纯文字，2表示图文，4表示视频
  int postType;

  ///页面浏览量
  int pv;

  ///为1表示·
  int resource;

  ///榜单评分
  String? score;

  ///不包含该字段表示·
  String? searchingCircle;

  ///标题
  String title;

  ///趋势，1表示上升
  int trend;

  ///链接
  String url;

  RankItem({
    this.blogId,
    required this.icon,
    this.img,
    required this.interactionCount,
    required this.isAuth,
    required this.isVerify,
    this.postDigest,
    this.postId,
    required this.postType,
    required this.pv,
    required this.resource,
    this.score,
    this.searchingCircle,
    required this.title,
    required this.trend,
    required this.url,
  });

  factory RankItem.fromJson(Map<String, dynamic> json) {
    return RankItem(
      blogId: json['blogId'],
      icon: json['icon'],
      img: json['img'],
      interactionCount: json['interactionCount'],
      isAuth: json['isAuth'],
      isVerify: json['isVerify'],
      postDigest: json['postDigest'],
      postId: json['postId'],
      postType: json['postType'],
      pv: json['pv'],
      resource: json['resource'],
      score: json['score'],
      searchingCircle: json['searchingCircle'],
      title: json['title'],
      trend: json['trend'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['icon'] = icon;
    data['img'] = img;
    data['interactionCount'] = interactionCount;
    data['isAuth'] = isAuth;
    data['isVerify'] = isVerify;
    data['postDigest'] = postDigest;
    data['postId'] = postId;
    data['postType'] = postType;
    data['pv'] = pv;
    data['resource'] = resource;
    data['score'] = score;
    data['searchingCircle'] = searchingCircle;
    data['title'] = title;
    data['trend'] = trend;
    data['url'] = url;
    return data;
  }
}

///ConfigListItem，搜索页面顶部入口
class ConfigListItem {
  ///内容
  String content;

  ///图片地址
  String imageUrl;

  ///链接
  String linkUrl;

  ///副标题
  String subTitle;

  ///标题
  String title;

  ConfigListItem({
    required this.content,
    required this.imageUrl,
    required this.linkUrl,
    required this.subTitle,
    required this.title,
  });

  factory ConfigListItem.fromJson(Map<String, dynamic> json) {
    return ConfigListItem(
      content: json['content'],
      imageUrl: json['imageUrl'],
      linkUrl: json['linkUrl'],
      subTitle: json['subTitle'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['content'] = content;
    data['imageUrl'] = imageUrl;
    data['linkUrl'] = linkUrl;
    data['subTitle'] = subTitle;
    data['title'] = title;
    return data;
  }
}

///SearchSuggestItem
class SearchSuggestItem {
  ///用户信息
  SearchBlogData? blogData;

  ///推荐原因
  String? recomReason;

  ///标签信息
  TagInfo? tagInfo;

  ///类型，1表示标签，2表示用户
  int type;

  SearchSuggestItem({
    this.blogData,
    required this.recomReason,
    this.tagInfo,
    required this.type,
  });

  factory SearchSuggestItem.fromJson(Map<String, dynamic> json) {
    return SearchSuggestItem(
      blogData: json['blogData'] != null
          ? SearchBlogData.fromJson(json['blogData'])
          : null,
      recomReason: json['recomReason'],
      tagInfo:
          json['tagInfo'] != null ? TagInfo.fromJson(json['tagInfo']) : null,
      type: json['type'],
    );
  }
}

///用户信息
///
///BlogData
class SearchBlogData {
  ///用户统计数据
  SimpleBlogCount? blogCount;
  SimpleBlogInfo blogInfo;

  ///推荐报告
  RecommendReport recommendReport;

  SearchBlogData({
    required this.blogCount,
    required this.blogInfo,
    required this.recommendReport,
  });

  factory SearchBlogData.fromJson(Map<String, dynamic> json) {
    return SearchBlogData(
      blogCount: json['blogCount'] != null
          ? SimpleBlogCount.fromJson(json['blogCount'])
          : null,
      blogInfo: SimpleBlogInfo.fromJson(json['blogInfo']),
      recommendReport: RecommendReport.fromJson(json['recommendReport']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogCount'] = blogCount?.toJson();
    data['blogInfo'] = blogInfo.toJson();
    data['recommendReport'] = recommendReport.toJson();
    return data;
  }
}

///用户统计数据
///
///SimpleBlogCount
class SimpleBlogCount {
  ///粉丝数目
  int followerCount;

  ///帖子数目
  int publicPostCount;

  SimpleBlogCount({
    required this.followerCount,
    required this.publicPostCount,
  });

  factory SimpleBlogCount.fromJson(Map<String, dynamic> json) {
    return SimpleBlogCount(
      followerCount: json['followerCount'],
      publicPostCount: json['publicPostCount'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['followerCount'] = followerCount;
    data['publicPostCount'] = publicPostCount;
    return data;
  }
}

///标签信息
///
///TagInfo，标签信息
class TagInfo {
  ///标签图片地址
  String? imageUrl;

  ///参与数
  int? joinCount;

  ///？
  String? rankName;

  ///推荐报告
  RecommendReport recommendReport;

  ///是否订阅
  bool subscribed;

  ///标签名称
  String tagName;

  ///类型，1
  int? tagType;

  TagInfo({
    this.imageUrl,
    this.joinCount,
    this.rankName,
    required this.recommendReport,
    required this.subscribed,
    required this.tagName,
    this.tagType,
  });

  factory TagInfo.fromJson(Map<String, dynamic> json) {
    return TagInfo(
      imageUrl: json['imageUrl'],
      joinCount: json['joinCount'] ?? -1,
      rankName: json['rankName'],
      recommendReport: RecommendReport.fromJson(json['recommendReport']),
      subscribed: json['subscribed'],
      tagName: json['tagName'],
      tagType: json['tagType'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['imageUrl'] = imageUrl;
    data['joinCount'] = joinCount;
    data['rankName'] = rankName;
    data['recommendReport'] = recommendReport.toJson();
    data['subscribed'] = subscribed;
    data['tagName'] = tagName;
    data['tagType'] = tagType;
    return data;
  }
}

class SearchAllResult {
  bool hasResult;
  bool jumpTag;
  int offset;
  List<PostListItem> posts;

  ///热门标签
  TagInfo? tagRank;

  ///所有标签
  List<TagInfo> tags;

  SearchAllResult({
    required this.hasResult,
    required this.jumpTag,
    required this.offset,
    required this.posts,
    required this.tagRank,
    required this.tags,
  });

  factory SearchAllResult.fromJson(Map<String, dynamic> json) {
    List tmp = [];
    List<PostListItem> posts = [];
    if (json['posts'] != null) {
      tmp = (json['posts'] as List);
      for (var e in tmp) {
        if (e['postData']['postCount'] != null) {
          posts.add(PostListItem.fromJson(e));
        }
      }
    }
    return SearchAllResult(
      hasResult: json['hasResult'] ?? false,
      jumpTag: json['jumpTag'] ?? false,
      offset: json['offset'],
      posts: json['posts'] != null ? posts : [],
      tagRank:
          json['tagRank'] != null ? TagInfo.fromJson(json['tagRank']) : null,
      tags: json['tags'] != null
          ? List<TagInfo>.from(json['tags'].map((x) => TagInfo.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hasResult'] = hasResult;
    data['jumpTag'] = jumpTag;
    data['offset'] = offset;
    data['posts'] = posts.map((x) => x.toJson()).toList();
    data['tagRank'] = tagRank?.toJson();
    data['tags'] = tags.map((x) => x.toJson()).toList();
    return data;
  }
}

///SearchPost
class SearchPost {
  ///作者ID
  int blogId;

  ///作者信息
  SimpleBlogInfo blogInfo;

  ///摘要
  String digest;

  ///首张图片
  FirstImage? firstImage;

  ///是否禁止推荐
  int forbidShare;

  ///帖子ID
  int id;

  ///类型
  int itemType;

  ///永久链接
  String permalink;

  ///图片数量
  int photoCount;

  ///统计数据
  PostCount postCount;

  ///链接
  String postPageUrl;

  ///？
  String previewUrl;

  ///发布时间
  int publishTime;

  ///推荐报告
  RecommendReport recommendReport;

  PhotoPostView? photoPostView;
  VideoPostView? videoPostView;

  ///推荐原因
  String recReason;

  ///标签列表
  List<String> tagList;

  ///标题
  String title;

  ///类型
  int type;

  SearchPost({
    required this.blogId,
    required this.blogInfo,
    required this.digest,
    required this.photoPostView,
    required this.videoPostView,
    this.firstImage,
    required this.forbidShare,
    required this.id,
    required this.itemType,
    required this.permalink,
    required this.photoCount,
    required this.postCount,
    required this.postPageUrl,
    required this.previewUrl,
    required this.publishTime,
    required this.recommendReport,
    required this.recReason,
    required this.tagList,
    required this.title,
    required this.type,
  });

  factory SearchPost.fromJson(Map<String, dynamic> json) {
    return SearchPost(
      blogId: json['blogId'],
      blogInfo: SimpleBlogInfo.fromJson(json['blogInfo']),
      digest: json['digest'],
      firstImage: json['firstImage'] != null
          ? FirstImage.fromJson(json['firstImage'])
          : null,
      forbidShare: json['forbidShare'],
      id: json['id'],
      itemType: json['itemType'],
      permalink: json['permalink'],
      photoCount: json['photoCount'],
      postCount: PostCount.fromJson(json['postCount']),
      postPageUrl: json['postPageUrl'],
      previewUrl: json['previewUrl'],
      publishTime: json['publishTime'],
      recommendReport: RecommendReport.fromJson(json['recommendReport']),
      recReason: json['recReason'],
      tagList: List<String>.from(json['tagList']),
      title: json['title'],
      type: json['type'],
      photoPostView: json['photoPostView'] != null
          ? PhotoPostView.fromJson(json['photoPostView'])
          : null,
      videoPostView: json['videoPostView'] != null
          ? VideoPostView.fromJson(json['videoPostView'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['blogInfo'] = blogInfo.toJson();
    data['digest'] = digest;
    data['firstImage'] = firstImage?.toJson();
    data['forbidShare'] = forbidShare;
    data['id'] = id;
    data['itemType'] = itemType;
    data['permalink'] = permalink;
    data['photoCount'] = photoCount;
    data['postCount'] = postCount.toJson();
    data['postPageUrl'] = postPageUrl;
    data['previewUrl'] = previewUrl;
    data['publishTime'] = publishTime;
    data['recommendReport'] = recommendReport.toJson();
    data['recReason'] = recReason;
    data['tagList'] = tagList;
    data['title'] = title;
    data['type'] = type;
    return data;
  }
}
