import 'package:dio/dio.dart';
import 'package:loftify/Utils/request_header_util.dart';

import '../Utils/request_util.dart';
import '../Utils/utils.dart';

class SettingApi {
  static Future getBlacklist({
    required int offset,
    int limit = 10,
  }) async {
    return RequestUtil.post(
      "/v1.1/blacklistmanage.api",
      data: {
        "optype": "get",
        "offset": offset,
        "limit": limit,
      },
    );
  }

  static Future getShieldBloglist() async {
    return RequestUtil.get(
      "/timeline/shieldBlogList.json",
    );
  }

  static Future getShieldTagList() async {
    return RequestUtil.post(
      "/v1.1/forbidtagsmanage.api",
      data: {
        "optype": "get",
      },
    );
  }

  static Future shieldOrUnshieldTag({
    required String tag,
    required bool isShield,
  }) async {
    return RequestUtil.post(
      "/v1.1/forbidtagsmanage.api",
      data: {
        "optype": isShield ? "add" : "del",
        "tag": tag,
      },
      options: Options(
          contentType: "${Headers.formUrlEncodedContentType}; charset=utf-8"),
    );
  }

  static Future getGiftSetting() async {
    return RequestUtil.get(
      "/v1.1//trade/gift/myFlags",
    );
  }

  static Future updateGiftSetting({
    required bool acceptGiftFlag,
    required bool showReturnGiftPreviewImg,
  }) async {
    return RequestUtil.post("/v1.1/trade/gift/myFlags", data: {
      "acceptGiftFlag": acceptGiftFlag ? 1 : 0,
      "showReturnGiftPreviewImg": showReturnGiftPreviewImg ? 1 : 0,
    });
  }

  static Future updatePersonalRecommendSetting({
    required bool isEnable,
  }) async {
    return RequestUtil.post("/v1.1/updateSetting.api", data: {
      "deviceid": RequestHeaderUtil.getDeviceId(),
      "personalRecommend": isEnable ? 1 : 0,
    });
  }

  static Future updateCopyRightSetting({
    required CopyRightType copyRightType,
    required bool isClose,
    required String blogName,
  }) async {
    return RequestUtil.post("/v1.1/blogInfoManage.api", data: {
      "optype": copyRightType.name,
      "blogdomain": Utils.getBlogDomain(blogName),
      "close": isClose ? 1 : 0,
    });
  }
}

enum CopyRightType {
  videoprotection("videoprotection"),
  imageprotection("imageprotection"),
  appimagestamp("appimagestamp");

  const CopyRightType(this.name);

  final String name;
}
