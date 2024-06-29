import '../Utils/request_util.dart';

class GrainApi {
  static Future getGrainDetail({
    required int grainId,
    required int blogId,
    int offset = 0,
    int sortType = 0,
  }) async {
    return RequestUtil.get(
      "/api-grain/grain/getDetail.json",
      params: {
        "grainId": "$grainId",
        "grainUserId": blogId,
        "offset": offset,
        "sortType": sortType,
      },
    );
  }

  static Future listSubscribdGrainList({
    int offset = 0,
    int limit = 20,
  }) async {
    return RequestUtil.get(
      "/api-grain/grain/listSubscribeGrains.json",
      params: {
        "offset": offset,
        "limit": "$limit",
        "withPost": 1,
      },
    );
  }

  static Future getIncantation({
    required int grainId,
    required int blogId,
  }) async {
    return RequestUtil.post(
      "/api-grain/grain/createIncantation.json",
      params: {
        "grainId": "$grainId",
        "grainUserId": blogId,
      },
    );
  }

  static Future subscribeOrUnSubscribe({
    bool isSubscribe = true,
    required int grainId,
    required int blogId,
  }) async {
    return RequestUtil.post(
      "/api-grain/grain/subscribe.json",
      data: {
        "subscribe": isSubscribe ? 1 : 0,
        "grainId": "$grainId",
        "grainUserId": blogId,
      },
    );
  }
}
