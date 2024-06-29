import '../Utils/request_util.dart';

class DressApi {
  static Future getDressList({
    int partTargetId = 235504,
    String activityCode = "2024CustomSuit",
    int offset = 0,
    int propType = 2,
    String tag = "",
  }) async {
    return RequestUtil.get(
      "/trade/act/paidContent/propMarket.json",
      domainType: DomainType.www,
      params: {
        "tag": tag,
        "activityCode": activityCode,
        "propType": propType,
        "offset": offset,
        "partTargetId": partTargetId,
        "_": DateTime.timestamp().microsecond,
      },
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
}
