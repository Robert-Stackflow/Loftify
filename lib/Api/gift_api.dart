import '../Utils/request_util.dart';

class GiftApi {
  static Future getGrantRecords({
    int type = 0,
    int offset = 0,
  }) async {
    //0任务获取，1购买获取
    return RequestUtil.get(
      "/trade/freegift/grantRecords",
      domainType: DomainType.www,
      params: {
        "type": type,
        "offset": offset,
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future getConsumeLog({
    int type = 0,
    int offset = 0,
  }) async {
    //0任务获取，1购买获取
    return RequestUtil.get(
      "/trade/freegift/consumeLog",
      domainType: DomainType.www,
      params: {
        "type": type,
        "offset": offset,
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future getCouponCount({
    int type = 0,
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/trade/act/coupon/my.json",
      domainType: DomainType.www,
      params: {
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future getCouponGetLog({
    int type = 1,
    int offset = 0,
  }) async {
    //1表示我的糖果券，2表示获取记录
    //couponList
    return RequestUtil.get(
      "/trade/act/coupon/archive.json",
      domainType: DomainType.www,
      params: {
        "type": type,
        "offset": offset,
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future getCouponPurchaseLog({
    int offset = 0,
  }) async {
    //使用记录
    // purchaseList
    return RequestUtil.get(
      "/trade/act/coupon/purchase.json",
      domainType: DomainType.www,
      params: {
        "offset": offset,
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future getUserTasks({
    int offset = 0,
  }) async {
    //purchaseList
    return RequestUtil.get(
      "/trade/gift/userTasks.json",
      domainType: DomainType.www,
      params: {
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future getCoinOrder({
    int offset = 0,
  }) async {
    //orderList
    return RequestUtil.post(
      "/v1.1/trade/wallet/lofterCoinLog",
      domainType: DomainType.api,
      data: {
        "offset": "$offset",
      },
    );
  }

  static Future getAccountOrder({
    int offset = 0,
    int type = 2,
  }) async {
    //orderList
    return RequestUtil.post(
      "/v1.1/trade/wallet/order",
      domainType: DomainType.api,
      data: {
        "offset": "$offset",
        "type": "$type",
      },
    );
  }

  static Future getFansVipOrder({
    int offset = 0,
  }) async {
    //打赏消费
    //orderList
    return RequestUtil.get(
      "/v1.1/trade/wallet/fansvip/orders",
      domainType: DomainType.api,
      params: {
        "offset": "$offset",
      },
    );
  }

  static Future getCustomBgAvatarList({
    int offset = 0,
    int type = 0,
    String tag = "",
  }) async {
    return RequestUtil.get(
      "/trade/imageMarket/products.json",
      domainType: DomainType.www,
      params: {
        "offset": "$offset",
        "type": type,
        "tag": tag,
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future getProductDetail({
    int type = 0,
    required int id,
  }) async {
    return RequestUtil.get(
      "/trade/imageMarket/post/product.json",
      domainType: DomainType.www,
      params: {
        "productId": "$id",
        "productType": type,
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future getUserProductList({
    int type = 1,
    int offset = 0,
    required int blogId,
  }) async {
    //1壁纸，2装扮，3表情
    return RequestUtil.get(
      "/trade/imageMarket/creator/products.json",
      domainType: DomainType.www,
      params: {
        "blogId": "$blogId",
        "type": type,
        "offset": "$offset",
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future getDressSuitList({
    int offset = 0,
  }) async {
    return RequestUtil.get(
      "/newweb/dressingStore/list.json",
      domainType: DomainType.www,
      params: {
        "offset": "$offset",
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  static Future getDressSuitDetail({
    required int suitId,
  }) async {
    return RequestUtil.get(
      "/newweb/dressingStore/suitDetail.json",
      domainType: DomainType.www,
      params: {
        "suitId": "$suitId",
        "groupBuyingId": "",
        "_": DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }
}
