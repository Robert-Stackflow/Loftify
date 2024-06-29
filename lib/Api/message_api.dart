import '../Utils/request_util.dart';

enum MessageType { all, recommend, gift, at, subscribe, collection, other }

class MessageApi {
  static Future getLikeMessages({
    int offset = 0,
    int limit = 20,
    required int blogId,
  }) async {
    return RequestUtil.get(
      "/v1.1/messagecenter.api",
      params: {
        "offset": offset,
        "method": "getNewLikeList",
        "limit": limit,
        "userid": blogId,
        "blogid": blogId,
      },
    );
  }

  static getMessageTypeString(MessageType type) {
    switch (type) {
      case MessageType.all:
        return "";
      case MessageType.recommend:
        return "rec";
      case MessageType.gift:
        return "gift";
      case MessageType.at:
        return "at";
      case MessageType.subscribe:
        return "collection";
      case MessageType.collection:
        return "subscribe";
      case MessageType.other:
        return "other";
    }
  }

  static Future getSystemNoticeList({
    int offset = 0,
    int limit = 20,
    required int blogId,
    required MessageType type,
  }) async {
    return RequestUtil.get(
      "/v1.1/messagecenter.api",
      params: {
        "offset": offset,
        "method": "getSystemNoticeList",
        "limit": limit,
        "userid": blogId,
        "subType": getMessageTypeString(type),
        "blogid": blogId,
      },
    );
  }

  static Future getCommentMessages({
    int offset = 0,
    int limit = 20,
    required int blogId,
  }) async {
    return RequestUtil.get(
      "/v1.1/usertimeline.api",
      params: {
        "supportposttypes": "1,2,3,4,5,6",
        "supportnoticetype": 32,
        "extranoticetypes": 36,
        "offset": offset,
        "method": "getUserNoticeListOnlyResponse",
        "limit": limit,
        "userid": blogId,
        "blogid": blogId,
      },
    );
  }
}
