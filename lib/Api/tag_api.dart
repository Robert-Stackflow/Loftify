import 'package:dio/dio.dart';

import '../Models/enums.dart';
import '../Utils/request_util.dart';

class TagApi {
  static Future getTagDetail({
    required String tag,
  }) async {
    return RequestUtil.post(
      "/v1.1/newTag.api",
      data: {
        "tag": tag,
        "method": "newTagConfig",
      },
      options: Options(
          contentType: "${Headers.formUrlEncodedContentType}; charset=utf-8"),
    );
  }

  static Future getSimpleSubscribdTagList({
    int offset = 0,
    int limit = 0,
  }) async {
    return RequestUtil.get(
      "/newtag/getFavoriteTags.json",
      params: {
        "offset": offset,
        "limit": "$limit",
        "withPost": 1,
      },
    );
  }

  static Future getFullSubscribdTagList({
    int offset = 0,
    int page = 0,
  }) async {
    return RequestUtil.post(
      "/newtag/getFavoriteTags.json",
      data: {
        "offset": offset,
        "page": 0,
      },
    );
  }

  static Future subscribeOrUnSubscribe({
    bool isSubscribe = true,
    required String tag,
    int id = 0,
  }) async {
    return RequestUtil.post(
      "/v1.1/subscribetag.api",
      data: {
        "optype": isSubscribe ? "add" : "del",
        "tag": tag,
        "id": id,
      },
      options: Options(
          contentType: "${Headers.formUrlEncodedContentType}; charset=utf-8"),
    );
  }

  static Future getRecommendRelatedTag({
    required String tag,
  }) async {
    return RequestUtil.get(
      "/recommend/tagSearch.json",
      params: {
        "tag": tag,
      },
    );
  }

  static Future getSearchPostList({
    required String tag,
    required String key,
    int offset = 0,
    TagPostType postType = TagPostType.noLimit,
    String postYm = "",
    String excludeKey = "",
  }) async {
    return RequestUtil.get(
      "/newsearch/tag/post.json",
      params: {
        "tag": tag,
        "offset": offset,
        "key": key,
        "postType": postType.index,
        "postYm": postYm,
        "excludeKey": excludeKey,
      },
    );
  }

  static Future getRecommendList({
    required String tag,
    int offset = 0,
    int count = 0,
  }) async {
    return RequestUtil.get(
      "/recommend/tagRecom.json",
      params: {
        "tag": tag,
        "offset": offset,
        "count": count,
      },
    );
  }

  static Future getPostList(GetTagPostListParams param) async {
    return RequestUtil.post(
      "/newapi/tagPosts.json",
      data: param.toJson(),
    );
  }

  static Future getCollectionList({
    required String tag,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/newapi/postCollection/tagPage.json",
      params: {
        "tag": tag,
        "offset": offset,
      },
    );
  }

  static Future getGrainList({
    required String tag,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/newapi/grain/tagPage.json",
      params: {
        "tag": tag,
        "offset": offset,
      },
    );
  }

  static Future getRelatedTagPostList({
    required String tag,
    int count = 0,
  }) async {
    return RequestUtil.get(
      "/recommend/relatedTagRecom.json",
      params: {
        "tag": tag,
        "count": count,
      },
    );
  }
}

class GetTagPostListParams {
  String tag;
  int offset;
  TagPostResultType tagPostResultType;
  TagRecentDayType recentDayType;
  TagRangeType tagRangeType;
  bool protectedFlag;
  TagPostType postTypes;
  String postYm;

  GetTagPostListParams({
    required this.tag,
    this.offset = 0,
    this.tagPostResultType = TagPostResultType.newPost,
    this.recentDayType = TagRecentDayType.noLimit,
    this.tagRangeType = TagRangeType.noLimit,
    this.protectedFlag = false,
    this.postTypes = TagPostType.noLimit,
    this.postYm = "",
  });

  Map<String, dynamic> toJson() {
    int recentDay = 0;
    switch (recentDayType) {
      case TagRecentDayType.noLimit:
        recentDay = 0;
        break;
      case TagRecentDayType.oneDay:
        recentDay = 1;
        break;
      case TagRecentDayType.oneWeek:
        recentDay = 7;
        break;
      case TagRecentDayType.oneMonth:
        recentDay = 30;
        break;
    }
    String tagType = "";
    switch (tagPostResultType) {
      case TagPostResultType.newPost:
        tagType = "new";
        break;
      case TagPostResultType.newComment:
        tagType = "newComment";
        break;
      case TagPostResultType.total:
        tagType = "total";
        break;
      case TagPostResultType.date:
        tagType = "date";
        break;
      case TagPostResultType.week:
        tagType = "week";
        break;
      case TagPostResultType.month:
        tagType = "month";
        break;
    }
    return {
      "tag": tag,
      "offset": offset,
      "type": tagType,
      "recentDay": recentDay,
      "range": tagRangeType.index,
      "protectedFlag": protectedFlag ? 1 : 0,
      "postTypes": postTypes == TagPostType.noLimit ? "" : postTypes.index,
      "postYm": postYm,
    };
  }

  GetTagPostListParams clone() {
    return GetTagPostListParams(
      tag: tag,
      offset: offset,
      tagPostResultType: tagPostResultType,
      recentDayType: recentDayType,
      tagRangeType: tagRangeType,
      protectedFlag: protectedFlag,
      postTypes: postTypes,
      postYm: postYm,
    );
  }

  GetTagPostListParams copyWith({
    int? offset,
    TagPostResultType? tagPostResultType,
  }) {
    return GetTagPostListParams(
      tag: tag,
      offset: offset ?? this.offset,
      tagPostResultType: tagPostResultType ?? this.tagPostResultType,
      recentDayType: recentDayType,
      tagRangeType: tagRangeType,
      protectedFlag: protectedFlag,
      postTypes: postTypes,
      postYm: postYm,
    );
  }
}
