import '../Utils/request_util.dart';
import '../Utils/utils.dart';

class CollectionApi {
  static Future getCollection({
    int offset = 0,
    int limit = 20,
    int order = 1,
    int startPostId = 0,
    required int postId,
    required int collectionId,
    int upDown = -1,
    int subscribeBlogId = 0,
    required int blogId,
    required String blogName,
    String scene = "progress",
  }) async {
    String blogDomain = Utils.getBlogDomain(blogName);
    var data = {
      "blogdomain": blogDomain,
      "method": "getCollectionSimple",
      "blogid": blogId,
      "collectionid": collectionId,
      "offset": offset,
      "upDown": upDown,
      "order": order,
      "scene": scene,
    };
    if (subscribeBlogId != 0) {
      data.addAll({
        "subscribeBlogid": subscribeBlogId,
      });
    }
    if (upDown == -1) {
      data.addAll({
        "postId": postId,
        "startPostId": "",
      });
    } else {
      data.addAll({
        "startPostId": startPostId,
      });
    }
    return RequestUtil.post(
      "/v1.1/postCollection.api",
      data: data,
    );
  }

  static Future getCollectionDetail({
    int offset = 0,
    int limit = 20,
    int order = 1,
    required int collectionId,
    int subscribeBlogId = 0,
    required int blogId,
  }) async {
    var data = {
      "method": "getCollectionDetail",
      "blogid": blogId,
      "collectionid": collectionId,
      "offset": offset,
      "order": order,
    };
    if (subscribeBlogId != 0) {
      data.addAll({
        "subscribeBlogid": subscribeBlogId,
      });
    }
    return RequestUtil.post(
      "/v1.1/postCollection.api",
      data: data,
    );
  }

  static Future getSubscribdCollectionList({
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/newapi/subscribeCollection/list.json",
      params: {
        "offset": "$offset",
      },
    );
  }

  static Future getUnreadSubscribeCollectionCount({
    int offset = 0,
    int limit = 0,
  }) async {
    return RequestUtil.get(
      "/v2.0/subscribeCollection.api",
      params: {
        "method": "unreadSubscribeCollectionCount",
      },
    );
  }

  static Future getIncantation({
    required int collectionId,
  }) async {
    return RequestUtil.post(
      "/newapi/postCollection/createIncantation.json",
      params: {
        "collectionId": "$collectionId",
      },
    );
  }

  static Future subscribeOrUnSubscribe({
    bool isSubscribe = true,
    required int collectionId,
  }) async {
    return RequestUtil.post(
      "/v2.0/subscribeCollection.api",
      data: {
        "method": isSubscribe ? "subscribe" : "unsubscribe",
        "collectionId": collectionId,
      },
    );
  }

  static Future getPreOrNextPost({
    bool isPre = true,
    required int postId,
    required int blogId,
    required int collectionId,
    required String blogName,
  }) async {
    return RequestUtil.post(
      "/oldapi/collection/${isPre ? "pre" : "next"}.api",
      data: {
        "blogdomain": Utils.getBlogDomain(blogName),
        "method": isPre ? "getPrePost" : "getAfterPost",
        "collectionid": collectionId,
        "postid": postId,
        "blogid": blogId,
      },
    );
  }
}
