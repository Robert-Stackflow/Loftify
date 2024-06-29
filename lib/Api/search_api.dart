import '../Utils/request_util.dart';

class SearchApi {
  static Future getGuessList() async {
    return RequestUtil.get(
      "/newsearch/guess/keywords.json",
    );
  }

  static Future getSuggestList({
    required String key,
  }) async {
    return RequestUtil.get(
      "/newsearch/sug.json",
      params: {
        "key": key,
      },
    );
  }

  static Future getRankList() async {
    return RequestUtil.get("/newapi/hotsearch/ranklist.json");
  }

  static Future getAllSearchResult({
    required String key,
    int sortType = 0,
  }) async {
    return RequestUtil.get(
      "/newsearch/v2/all.json",
      params: {
        "key": key,
        "sortType": sortType,
        "version": 0,
      },
    );
  }

  static Future getAllSearchPostResult({
    required String key,
    int sortType = 0,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/newsearch/all/post.json",
      params: {
        "key": key,
        "sortType": sortType,
        "offset": offset,
      },
    );
  }

  static Future getTagSearchResult({
    required String key,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/newsearch/tag.json",
      params: {
        "key": key,
        "offset": offset,
      },
    );
  }

  static Future getCollectionSearchResult({
    required String key,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/newsearch/collection.json",
      params: {
        "key": key,
        "offset": offset,
      },
    );
  }

  static Future getPostSearchResult({
    required String key,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/newsearch/post.json",
      params: {
        "key": key,
        "offset": offset,
      },
    );
  }

  static Future getGrainSearchResult({
    required String key,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/newsearch/grain.json",
      params: {
        "key": key,
        "offset": offset,
      },
    );
  }

  static Future getUserSearchResult({
    required String key,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/newsearch/blog.json",
      params: {
        "key": key,
        "offset": offset,
      },
    );
  }
}
