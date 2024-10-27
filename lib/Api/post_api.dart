import 'package:dio/dio.dart';

import '../Utils/request_util.dart';
import '../Utils/utils.dart';

class PostApi {
  static Future likeOrUnLike({
    bool isLike = true,
    required int postId,
    required int blogId,
    String scene = "note",
  }) async {
    return RequestUtil.post(
      "/v1.1/like.api",
      data: {
        "liketype": isLike ? "like" : "unlike",
        "postid": postId,
        "blogid": blogId,
        "scene": scene
      },
    );
  }

  static Future shareOrUnShare({
    bool isShare = true,
    required int postId,
    required int blogId,
    String scene = "note",
  }) async {
    return RequestUtil.post(
      "/v1.1/share.api",
      data: {
        "optype": isShare ? "share" : "unshare",
        "postid": postId,
        "blogid": blogId,
        "scene": scene
      },
    );
  }

  static Future getDetail({
    required int postId,
    required int blogId,
    required String blogName,
  }) async {
    String blogDomain = Utils.getBlogDomain(blogName);
    Map<String, dynamic> data = {
      "supportposttypes": "1,2,3,4,5,6",
      "postid": postId,
      "requestType": 0,
      "offset": 0,
      "postdigestnew": 1,
      "checkpwd": 1,
      "needgetpoststat": 1,
    };
    if (Utils.isNotEmpty(blogDomain)) {
      data.addAll({
        "blogdomain": blogDomain,
        "blogId": blogId,
      });
    } else {
      data.addAll({
        "targetblogid": blogId,
      });
    }
    return RequestUtil.post(
      "/oldapi/post/detail.api",
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  static Future getHotComments({
    required int postId,
    required int blogId,
    required int postPublishTime,
  }) async {
    return RequestUtil.get(
      "/comment/l1/hotnew.json",
      params: {
        "needAuthL2": 1,
        "postId": postId,
        "blogId": blogId,
        "needGift": 0,
        "commentId": -1,
        "openFansVipPlan": 0,
        "scene": "note",
        "postPublishTime": postPublishTime,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  static Future likeOrUnlikeComment({
    required int postId,
    required int blogId,
    required int commentId,
    required bool isLike,
  }) async {
    return RequestUtil.post(
      "/v2.0/commentHot.api",
      data: {
        "postId": postId,
        "blogId": "$blogId",
        "likeType": isLike ? 1 : 0,
        "commentId": commentId,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  static Future getL1Comments({
    required int postId,
    required int blogId,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/comment/l1/page.json",
      params: {
        "postId": postId,
        "blogId": blogId,
        "offset": offset,
        "needGift": "0",
        "openFansVipPlan": 0,
        "dunType": 1,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  static Future getL2Comments({
    required int id,
    required int postId,
    required int blogId,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/comment/l2/page.json",
      params: {
        "id": id,
        "postId": postId,
        "blogId": blogId,
        "offset": offset,
        "fromSrc": "",
        "fromId": "",
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  static Future getVideoDetail({
    required String permalink,
    int offset = 0,
    int count = 0,
  }) async {
    return RequestUtil.get(
      "/recommend/postVideoFlow.json",
      params: {
        "permalink": permalink,
        "offset": offset,
        "count": count,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  static Future getGifts({
    required int postId,
    required int blogId,
    String scene = "note",
  }) async {
    return RequestUtil.get(
      "/v1.1/trade/gift/post/newSupportInfo",
      params: {
        "postId": postId,
        "blogId": blogId,
        "vipFans": 0,
        "openFansVipPlan": 0,
        "scene": scene,
      },
    );
  }

  static Future getMyReturnGift({
    required int postId,
    required int blogId,
    required int giftId,
  }) async {
    return RequestUtil.get(
      "/v1.1/trade/gift/myReturnGift",
      params: {
        "postId": postId,
        "blogId": "$blogId",
        "id": giftId,
      },
    );
  }

  static Future presentGift({
    required int postId,
    required int blogId,
    required int giftId,
    required int count,
    required int myBlogId,
  }) async {
    return RequestUtil.post(
      "/v1.1/trade/gift/present",
      domainType: DomainType.www,
      params: {
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
      data: {
        "postId": postId,
        "blogId": blogId,
        "giftId": giftId,
        "count": count,
        "currentUserId": "$myBlogId",
        "couponId": "",
      },
    );
  }

  static Future getBalance({
    required int postId,
    required int blogId,
    required int giftId,
    required int count,
    required int myBlogId,
  }) async {
    return RequestUtil.get(
      "/trade/loftercoin/balance",
      domainType: DomainType.www,
      params: {
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future uploadHistory({
    required int postId,
    required int blogId,
    required int userId,
    int? collectionId,
    int postType = 2,
    String scene = "note",
  }) async {
    Map item = {
      "postId": "$postId",
      "blogId": "$blogId",
      "postType": postType,
      "time": DateTime.now().millisecondsSinceEpoch,
    };
    if (collectionId != 0) {
      item.addAll({
        "collectionId": collectionId,
      });
    }
    return RequestUtil.post(
      "/datacollect/v1/upload",
      domainType: DomainType.da,
      data: {
        "time": DateTime.now().millisecondsSinceEpoch,
        "list": [
          {
            "userId": userId,
            "data": item,
            "type": "postRead",
          }
        ]
      },
      options: Options(contentType: Headers.jsonContentType),
    );
  }
}
