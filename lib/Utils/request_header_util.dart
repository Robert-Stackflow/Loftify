import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/utils.dart';

import 'app_provider.dart';
import 'hive_util.dart';
import 'jwt_decoder.dart';

class RequestHeaderUtil {
  static const String defaultMarket = "xiaomi";
  static const String defaultUA =
      "LOFTER-Android 7.8.6 (23127PN0CC; Android 14; null) WIFI";
  static const String defaultProduct = "lofter-android-7.8.6";
  static const String defaultLofProduct = "lofter-android-7.8.6";
  static const String defaultDeviceId = "3451efd56bgg6h47";
  static const String defaultAndroidId = "3451efd56bgg6h47";
  static const String defaultOaid = "32b4d2c348650842";
  static const String defaultPhone = "15934867293";
  static const String defaultDaDeviceId =
      "2ef9ea6c17b7c6881c71915a4fefd932edc01af0";
  static AndroidDeviceInfo? androidInfo;

  static initAndroidInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      await deviceInfo.androidInfo.then((value) => androidInfo = value);
    } on PlatformException {
      androidInfo = null;
    }
  }

  static getAuthHeader() {
    int tokenTypeIndex =
        HiveUtil.getInt(HiveUtil.tokenTypeKey, defaultValue: 0);
    tokenTypeIndex = max(tokenTypeIndex, 0);
    TokenType tokenType = TokenType.values[tokenTypeIndex];
    String? token = appProvider.token;
    Map<String, dynamic> res = {};
    switch (tokenType) {
      case TokenType.captchCode:
      case TokenType.password:
        res["lofter-phone-login-auth"] = token;
        break;
      case TokenType.lofterID:
        res["authorization"] = "ThirdParty $token";
        break;
      case TokenType.none:
        break;
    }
    return res;
  }

  static getHeaders() {
    Map<String, dynamic> headers = {
      "x-device": getXDevice(),
      "lofproduct": getLofProduct(),
      "user-agent": getUA(),
      "market": getMarket(),
      "deviceid": getDeviceId(),
      "dadeviceid": getDaDeviceId(),
      "androidid": getAndroidId(),
      "x-reqid": getXReqId(),
      "portrait": getPortrait(),
    };
    if (Utils.isNotEmpty(appProvider.captchaToken)) {
      headers.addAll({"capttoken": appProvider.captchaToken});
    }
    Map<String, dynamic> authHeader = getAuthHeader();
    if (authHeader.isNotEmpty) {
      headers.addAll(authHeader);
    }
    return headers;
  }

  static String getPortrait() {
    return JwtDecoder.encodePayload({
      "imei": getAndroidId(),
      "androidId": getAndroidId(),
      "oaid": defaultOaid,
      "mac": "02:00:00:00:00:00",
      "phone": defaultPhone,
    });
  }

  static String getXDevice() {
    return "qv+Dz73SObtbEFG7P0Gq12HkjzNb+iOK6KHWTPKHBTEZu26C6MJOMukkAG7dETo2";
  }

  static String getProduct() {
    return defaultProduct;
  }

  static String getLofProduct() {
    return defaultLofProduct;
  }

  static String getUA() {
    if (androidInfo == null) {
      return defaultUA;
    }
    return "LOFTER-Android 7.8.6 (${androidInfo!.model}; Android ${androidInfo!.version.release}; null) WIFI";
  }

  static String getMarket() {
    if (androidInfo == null) {
      return defaultProduct;
    }
    if (Utils.isNotEmpty(androidInfo!.manufacturer)) {
      return androidInfo!.manufacturer;
    }
    if (Utils.isNotEmpty(androidInfo!.brand)) {
      return androidInfo!.brand;
    }
    return defaultProduct;
  }

  static String getDeviceId() {
    return defaultDeviceId;
  }

  static String getDaDeviceId() {
    return defaultDaDeviceId;
  }

  static String getAndroidId() {
    return defaultAndroidId;
  }

  static String getXReqId({int length = 8}) {
    return Utils.getRandomString(length: length);
  }
}
