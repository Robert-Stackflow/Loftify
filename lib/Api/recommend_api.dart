import '../Utils/request_util.dart';

class RecommendApi {
  static Future getExploreRecomend({
    int offset = 0,
    int page = 0,
    int feed = 0,
  }) async {
    return RequestUtil.post("/recommend/exploreRecom.json", data: {
      "offset": "$offset",
      "count": page,
      "feedTime": feed,
    });
  }

  static Future getPostRecomend({
    int page = 0,
    required int postId,
    required int blogId,
  }) async {
    return RequestUtil.get("/recommend/postRecom.json", params: {
      "count": "$page",
      "postId": postId,
      "blogId": blogId,
    });
  }

  static Future getTimeline({
    int showOffset = 0,
    int publishOffset = 0,
    int shareOffset = 0,
  }) async {
    return RequestUtil.get(
      "/timeline/app/getTrackItemListWithShare.json",
      params: {
        "showOffset": "$showOffset",
        "publishOffset": "$publishOffset",
        "shareOffset": "$shareOffset",
      },
    );
  }
}
