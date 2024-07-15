import 'package:dio/dio.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Utils/request_header_util.dart';

import '../Utils/request_util.dart';
import '../Utils/utils.dart';

class UserApi {
  static Future getUserInfo() async {
    return RequestUtil.get(
      "/v1.1/usercounts.api",
      params: {
        "market": RequestHeaderUtil.getMarket(),
        "deviceid": RequestHeaderUtil.getDeviceId(),
        "isNewer": 0,
        "scene": "login"
      },
    );
  }

  static Future getMiscInfo() async {
    return RequestUtil.post(
      "/v1.1/miscInfo.api",
      data: {
        "deviceid": RequestHeaderUtil.getDeviceId(),
      },
    );
  }

  static Future getMeInfo({
    required String blogName,
  }) async {
    return RequestUtil.post(
      "/v1.1/meInfo.api",
      data: {
        "blogdomain": Utils.getBlogDomain(blogName),
      },
    );
  }

  static Future getLikeList(
      {int offset = 0, int limit = 20, required String blogName}) async {
    return RequestUtil.get(
      "/v1.1/batchdata.api",
      params: {
        "supportposttypes": "1,2,3,4,5,6",
        "blogdomain": Utils.getBlogDomain(blogName),
        "offset": offset,
        "postdigestnew": 1,
        "returnData": 1,
        "limit": limit,
        "method": "favorites",
      },
    );
  }

  static Future getPostList({
    int offset = 0,
    int limit = 20,
    required String blogName,
    required int blogId,
  }) async {
    return RequestUtil.get(
      "/v2.0/blogHomePage.api",
      params: {
        "supportposttypes": "1,2,3,4,5,6",
        "blogdomain": Utils.getBlogDomain(blogName),
        "targetblogid": blogId,
        "offset": offset,
        "postdigestnew": 1,
        "returnData": 1,
        "limit": limit,
        "openFansVipPlan": 0,
        "checkpwd": 1,
        "needgetpoststat": 1,
        "method": "getPostLists",
      },
    );
  }

  static Future getCollectionList(
      {int offset = 0, int limit = 20, required String blogName}) async {
    return RequestUtil.post(
      "/v1.1/postCollection.api",
      data: {
        "blogdomain": Utils.getBlogDomain(blogName),
        "needViewCount": 1,
        "offset": offset,
        "limit": limit,
        "method": "getCollectionList",
      },
    );
  }

  static Future getGrainList(
      {int offset = 0, int limit = 20, required int blogId}) async {
    return RequestUtil.get(
      "/api-grain/grain/list.json",
      params: {
        "blogId": "$blogId",
        "offset": offset,
      },
    );
  }

  static Future getShareList(
      {int offset = 0, int limit = 20, required String blogName}) async {
    return RequestUtil.get(
      "/v1.1/batchdata.api",
      params: {
        "supportposttypes": "1,2,3,4,5,6",
        "blogdomain": Utils.getBlogDomain(blogName),
        "offset": offset,
        "postdigestnew": 1,
        "returnData": 1,
        "limit": limit,
        "method": "shares",
      },
    );
  }

  static Future getFavoriteFolderList({
    int offset = 0,
    int postId = 0,
    int blogId = 0,
    int type = 1,
  }) async {
    return RequestUtil.post(
      "/newapi/subFolder/list.json",
      data: {
        "offset": "$offset",
        "postId": postId,
        "blogId": blogId,
        "type": type,
      },
    );
  }

  static Future getFavoriteFolderDetail({
    int offset = 0,
    int folderId = 0,
    int limit = 0,
  }) async {
    return RequestUtil.get(
      "/newapi/subFolder/getDetail.json",
      params: {
        "offset": "$offset",
        "folderId": folderId,
        "limit": limit,
      },
    );
  }

  static Future getHistoryList({
    int offset = 0,
    required String blogDomain,
  }) async {
    return RequestUtil.get(
      "/v2.0/history.api",
      params: {
        "blogdomain": blogDomain,
        "method": "getList",
        "offset": offset,
      },
    );
  }

  static Future closeHistory({
    required int recordHistory,
    required String blogName,
  }) async {
    return RequestUtil.get(
      "/v2.0/history.api",
      params: {
        "blogdomain": Utils.getBlogDomain(blogName),
        "method": "updateSetting",
        "recordHistory": recordHistory,
      },
    );
  }

  static Future clearHistory() async {
    return RequestUtil.get(
      "/v2.0/history.api",
      params: {
        "method": "clear",
      },
    );
  }

  static Future deleteHistroy({
    required int postId,
    required String blogName,
  }) async {
    return RequestUtil.post(
      "/v2.0/history.api",
      data: {
        "method": "del",
        "postid": postId,
        "blogdomain": Utils.getBlogDomain(blogName),
      },
    );
  }

  static Future deleteLike({
    required int postId,
    required int blogId,
  }) async {
    return RequestUtil.post(
      "/v1.1/like.api",
      data: {
        "method": "unlike",
        "postid": postId,
        "blogid": blogId,
      },
    );
  }

  static Future deleteShare({
    required int postId,
    required int blogId,
  }) async {
    return RequestUtil.post(
      "/v1.1/share.api",
      data: {
        "method": "unshare",
        "postid": postId,
        "blogid": blogId,
      },
    );
  }

  static Future deleteInvalidHistory({
    required int blogId,
  }) async {
    return RequestUtil.get(
      "/v2.0/batchData.api",
      params: {
        "method": "clearInvalid",
        "targetblogid": blogId,
        "type": "history",
      },
    );
  }

  static Future deleteInvalidLike({
    required int blogId,
  }) async {
    return RequestUtil.get(
      "/v2.0/batchData.api",
      params: {
        "method": "clearInvalid",
        "targetblogid": blogId,
        "type": "favorite",
      },
    );
  }

  static Future deleteInvalidShare({
    required int blogId,
  }) async {
    return RequestUtil.get(
      "/v2.0/batchData.api",
      params: {
        "method": "clearInvalid",
        "targetblogid": blogId,
        "type": "share",
      },
    );
  }

  static Future setRemark({
    required int blogId,
    required String remark,
  }) async {
    return RequestUtil.post(
      "/v2.0/addNameRemark.api",
      data: {
        "targetblogid": blogId,
        "remark": remark,
      },
      options: Options(
          contentType: "${Headers.formUrlEncodedContentType}; charset=utf-8"),
    );
  }

  static Future followOrUnfollow({
    bool isFollow = true,
    required int blogId,
    required String blogName,
  }) async {
    return RequestUtil.post(
      "/v1.1/follow.api",
      params: {
        "followtype": isFollow ? "follow" : "unfollow",
      },
      data: {
        "blogdomain": Utils.getBlogDomain(blogName),
        "targetblogid": blogId,
      },
    );
  }

  static Future blockOrUnBlock({
    bool isBlock = true,
    required int blogId,
  }) async {
    return RequestUtil.post(
      "/v1.1//blacklistmanage.api",
      data: {
        "optype": isBlock ? "add" : "del",
        "targetblogid": blogId,
      },
    );
  }

  static Future shieldRecommendOrUnShield({
    bool isShield = true,
    required int blogId,
  }) async {
    return RequestUtil.post(
      "/v1.1/shieldrecommanage.api",
      data: {
        "optype": isShield ? "add" : "del",
        "shieldBlogId": blogId,
      },
    );
  }

  static Future shieldBlogOrUnShield({
    bool isShield = true,
    required int blogId,
  }) async {
    return RequestUtil.post(
      "/timeline/manage.json",
      data: {
        "op": isShield ? "shield" : "show",
        "blogId": blogId,
      },
    );
  }

  static Future specialFollowOrSpecialUnfollow({
    bool isSpecialFollow = true,
    required int blogId,
    required String blogName,
  }) async {
    return RequestUtil.post(
      "/v1.1/specialfollow.api",
      data: {
        "followtype": isSpecialFollow ? "specialfollow" : "unSpecialfollow",
        "blogdomain": Utils.getBlogDomain(blogName),
        "targetblogid": blogId,
      },
    );
  }

  static Future getUserDetail({
    required int blogId,
    required String blogName,
  }) async {
    return RequestUtil.post(
      "/v2.0/blogHomePage.api",
      data: {
        "targetblogid": blogId,
        "blogdomain": Utils.getBlogDomain(blogName),
        "method": "getBlogInfoDetail",
        "checkpwd": 1,
        "returnData": 1,
        "needgetpoststat": 1,
      },
    );
  }

  static Future getShowCases({
    required int blogId,
    required String blogName,
  }) async {
    return RequestUtil.get(
      "/newapi/showcase/homeList.json",
      params: {
        "targetBlogId": blogId,
        "targetBlogDomain": Utils.getBlogDomain(blogName),
      },
    );
  }

  static Future getFollowingList({
    required String blogName,
    int offset = 0,
    int limit = 20,
    required FollowingMode followingMode,
  }) async {
    return RequestUtil.get(
      "/v1.1/${followingMode == FollowingMode.following
          ? "userfollowing"
          : "blogfollower"}.api",
      params: {
        // "timestamp": 0,
        "blogdomain": Utils.getBlogDomain(blogName),
        "offset": offset,
        "limit": limit,
      },
    );
  }

  static Future getFollowingTimeline({
    required String blogName,
    int offset = 0,
    int limit = 20,
    int postNum = 6,
  }) async {
    return RequestUtil.post(
      "/v1.1/usertimeline.api",
      data: {
        "blogdomain": Utils.getBlogDomain(blogName),
        "offset": offset,
        "limit": limit,
        "postnum": postNum,
        "method": "getFollowsNew",
      },
    );
  }

  static Future getSupporterList({
    required int blogId,
  }) async {
    return RequestUtil.get(
      "/v1.1/trade/support/queryDetailForBlog",
      params: {
        "blogId": "$blogId",
      },
    );
  }
}
