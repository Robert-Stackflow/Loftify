import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Utils/iprint.dart';
import 'package:loftify/Utils/utils.dart';

import '../Providers/provider_manager.dart';
import 'hive_util.dart';

class RequestHeaderUtil {
  static const String defaultMarket = "xiaomi";
  static const String defaultUA =
      "LOFTER-Android 7.8.6 (23127PN0CC; Android 14; null) WIFI";
  static const String defaultProduct = "lofter-android-7.8.6";
  static const String defaultLofProduct = "lofter-android-7.8.6";
  static const String defaultDeviceId = "4151dea95acc4a53";
  static const String defaultAndroidId = "4151dea95acc4a53";
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
        HiveUtil.getInt(key: HiveUtil.tokenTypeKey, defaultValue: 0);
    tokenTypeIndex = max(tokenTypeIndex, 0);
    TokenType tokenType = TokenType.values[tokenTypeIndex];
    String? token = ProviderManager.globalProvider.token;
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
    };
    if (Utils.isNotEmpty(ProviderManager.globalProvider.captchaToken)) {
      headers
          .addAll({"capttoken": ProviderManager.globalProvider.captchaToken});
    }
    Map<String, dynamic> authHeader = getAuthHeader();
    if (authHeader.isNotEmpty) {
      headers.addAll(authHeader);
    }
    return headers;
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
