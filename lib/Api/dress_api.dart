import '../Utils/request_util.dart';

class DressApi {
  static Future getDressList({
    int partTargetId = 235504,
    String activityCode = "2024CustomSuit",
    int offset = 0,
    int propType = 2,
    String tag = "",
  }) async {
    var params = {
      "tag": tag,
      "activityCode": activityCode,
      "propType": propType,
      "offset": offset,
      "_": DateTime.timestamp().microsecond,
    };
    if (propType == 2) {
      params["partTargetId"] = partTargetId;
    }
    return RequestUtil.get(
      "/trade/act/paidContent/propMarket.json",
      domainType: DomainType.www,
      params: params,
    );
  }

  static Future getDressDetail({
    required int returnGiftDressId,
  }) async {
    return RequestUtil.get(
      "/trade/gift/dressing/detail",
      domainType: DomainType.www,
      params: {
        "returnGiftId": "",
        "product": "",
        "returnGiftDressId": returnGiftDressId,
      },
    );
  }

  static Future getEmoteDetail({
    required int emotePackId,
  }) async {
    return RequestUtil.get(
      "/trade/gift/emotepack/detail",
      domainType: DomainType.www,
      params: {
        "returnGiftId": "",
        "product": "",
        "emotePackId": emotePackId,
      },
    );
  }
}
