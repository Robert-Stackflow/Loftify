import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:loftify/Utils/crypt_util.dart';
import 'package:loftify/Utils/iprint.dart';
import 'package:loftify/Utils/request_util.dart';

class LoginApi {
  static String calculateSHA256(String input) {
    Uint8List bytes = utf8.encode(input);
    List<int> hashBytes = crypto.sha256.convert(bytes).bytes;
    String hashString = hashBytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join('');
    return hashString;
  }

  static Future<dynamic> loginByPassword(String mobile, String password) async {
    return RequestUtil.post(
      "/lpt/login.do",
      domainType: DomainType.www,
      data: {
        "phone": mobile,
        "passport": calculateSHA256(password),
        "sourceType": 0,
        "type": 0,
        "deviceType": 0,
        "clientType": 0,
      },
    );
  }

  static Future<dynamic> loginByLofterID(
      String lofterID, String password) async {
    return RequestUtil.post(
      "/lpt/account/login.do",
      domainType: DomainType.www,
      data: {
        "blogName": lofterID,
        "password": calculateSHA256(password),
      },
    );
  }

  static Future<dynamic> loginByCaptchaCode(
      String mobile, String captchaCode) async {
    return RequestUtil.post(
      "/lpt/login.do",
      domainType: DomainType.www,
      data: {
        "phone": mobile,
        "captcha": captchaCode,
        "sourceType": 0,
        "type": 1,
        "deviceType": 0,
        "clientType": 0,
      },
    );
  }

  static Future<dynamic> getPhotoCaptcha() async {
    return RequestUtil.post(
      domainType: DomainType.www,
      "/lpt/photoCaptcha/getPhotoCaptcha.do",
      data: {"width": "270", "height": "126"},
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );
  }

  static Future<dynamic> getSlideCaptcha() async {
    return RequestUtil.get(
      domainType: DomainType.captcha,
      "/captcha/get",
      params: {
        "type": "jigsaw",
      },
    );
  }

  static String RSA_PUBLIC_KEY =
      "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAm4re9B8pjX71Up+b97dvV41bEvNTD0e7aaMyPr8FTHkINSrrGqXjz4pQ6x8AbioULXYIrzcMO3LyXolLcjE/+0Ubx8KMu30CS2D7TVHEkaZKqz5EKOgWFeepAL6++klyjXO+vVWSDjb8R6g1VoQKh9MPxLJGqXoFOh9cDahdDRLH1M4a8XboWwljx4CM+vHAuDAwY7i3R4E+bsE+GW5LI7zt/rnTF4tnt0CFazl65SiXthyPJglwCZOF2SLs8JJCrknVoWeDyGBMmQ/0gghK4VMAyFcxHCs8y4v7HtOEsRvS4fksSzLSpyNkhGGuNKHk5tBm5L5m6vApmvUYP6QSdwIDAQAB";

  static Future<dynamic> verifySlideCaptcha({
    required String id,
    required double offset,
    required String rawKey,
    required String rawIv,
  }) async {
    var data = {
      "id": id,
      "type": "jigsaw",
      "data": json.encode({"xPos": offset.toInt()}),
    };
    IPrint.debug(data);
    var aesRes = CryptUtil.encryptDataByAES(data, rawKey, rawIv);
    var xEncseckey =
        CryptUtil.encryptDataByRSA("$rawKey-$rawIv", RSA_PUBLIC_KEY);
    return RequestUtil.post(
      domainType: DomainType.captcha,
      "/captcha/check",
      stream: true,
      data: base64.decode(aesRes).toList(),
      options: Options(
        headers: {
          "X-Encseckey": xEncseckey,
          HttpHeaders.contentLengthHeader: base64.decode(aesRes).length,
        },
        contentType: "${Headers.jsonContentType}; charset=utf-8",
        responseType: ResponseType.bytes,
      ),
    );
  }

  static Future<dynamic> getCaptchaCode(String mobile, String imageCode) async {
    return RequestUtil.post(
      domainType: DomainType.www,
      "/lpt/getCaptchaPlus.do",
      data: {
        "clientType": 0,
        "phone": mobile,
        "sourceType": 0,
        "imageCode": imageCode
      },
    );
  }

  static Future uploadNewDevice() async {
    return RequestUtil.post(
      "/v2.0/uploadNewDevice.api",
      data: {
        "entryInfo":
            "DcmPruYFa9GNMfH9e87brXYbS3J1TsKqPRjORY/yXYDSMCX7F3+jKruDzeePT+6QiB1WkPaNdhT1fjomjAtBnC266hQ3u0iZuyfm7aGATj5ZE2V82cKbuAeY69fbDRvnaBYbURlk8xETDGFN5vCdFBibCvt11whjq0Y0gnJb+vl7LeMUzykCZ90lG8e0o7LikqOC6C4PCuaEYMXiA8hvbJ6GH8j04Bg/s7cbQuuSF04=",
      },
    );
  }

  static Future getConfigs() async {
    return RequestUtil.get(
      "/v1.1/configs.api",
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
  }

  static Future autoLogin() async {
    return RequestUtil.get(
      "/v2.0/autoLogin.api",
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
  }
}
