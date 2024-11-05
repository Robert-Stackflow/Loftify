import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dart_sm/dart_sm.dart';
import 'package:dio/dio.dart';
import 'package:loftify/Utils/crypt_util.dart';
import 'package:loftify/Utils/request_util.dart';

import '../Utils/ilogger.dart';

class LoginApi {
  static String RSA_PUBLIC_KEY =
      "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAm4re9B8pjX71Up+b97dvV41bEvNTD0e7aaMyPr8FTHkINSrrGqXjz4pQ6x8AbioULXYIrzcMO3LyXolLcjE/+0Ubx8KMu30CS2D7TVHEkaZKqz5EKOgWFeepAL6++klyjXO+vVWSDjb8R6g1VoQKh9MPxLJGqXoFOh9cDahdDRLH1M4a8XboWwljx4CM+vHAuDAwY7i3R4E+bsE+GW5LI7zt/rnTF4tnt0CFazl65SiXthyPJglwCZOF2SLs8JJCrknVoWeDyGBMmQ/0gghK4VMAyFcxHCs8y4v7HtOEsRvS4fksSzLSpyNkhGGuNKHk5tBm5L5m6vApmvUYP6QSdwIDAQAB";
  static String RSA_PUBLIC_KEY_V2 =
      "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC5gsH+AA4XWONB5TDcUd+xCz7ejOFHZKlcZDx+pF1i7Gsvi1vjyJoQhRtRSn950x498VUkx7rUxg1/ScBVfrRxQOZ8xFBye3pjAzfb22+RCuYApSVpJ3OO3KsEuKExftz9oFBv3ejxPlYc5yq7YiBO8XlTnQN0Sa4R4qhPO3I2MQIDAQAB";
  static String SM4_PUB_KEY = "BC60B8B9E4FFEFFA219E5AD77F11F9E2";

  static String calculateSHA256(String input) {
    Uint8List bytes = utf8.encode(input);
    List<int> hashBytes = crypto.sha256.convert(bytes).bytes;
    String hashString = hashBytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join('');
    return hashString;
  }

  static String calculateURSSM4(String input) {
    ILogger.debug("calculateURSSM4 for $input");
    SM4.setKey(SM4_PUB_KEY);
    String cipherText = SM4.encrypt(input);
    return cipherText;
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

  static Future<dynamic> getMailPower(String mail) async {
    return RequestUtil.post(
      "/dl/zj/mail/powGetP",
      domainType: DomainType.passport,
      data: {
        "encParams": calculateURSSM4(jsonEncode({
          "channel": 0,
          "pd": "lofter",
          "pkid": "YlfTAjw",
          "rtid": "HeN1DujR2kVqEtIKXsw4CJSNQOYy8mBx",
          "topURL": "https://www.lofter.com/front/login",
          "pvSid": "58aa38ca-396a-4ba4-add9-34309bee1d16",
          "un": mail,
        })),
      },
      options: Options(
        contentType: "${Headers.jsonContentType}; charset=utf-8",
        headers: {
          "Cookie":
              "firstentry=%2Flogin.do|; usertrack=c+53cWcJ4o0X34ckM2x8Ag==; JSESSIONID-WLF-XXD=ecd0454e54d08cc79a37e4ed1ce3c70349c5823c155570d49dbd03af344ace8dd4316050803ce43791c8da46634edf356eed65c1de8139ad682f77dd9bc4b477cd191c9391f5f3dd3ab39dd2c5298237423d222cd09c997a8541a23134c7e3108bef67ba167957690ed53d42fd77d3c723bca305e1cfb4ed53cbb56a05867f68c7014f32; utid=iUcefo5mCo0w8nrdx4RGC9ELzbT9t11c; NTES_WEB_FP=96c082f3dd894f696deec87f7bf724cf; gdxidpyhxdE=1f0Z%2F%2Bq4KvE8OywQscriTOyaw3eOQV2NbW%5Cwzx%2FqInKn9iI0Pk%2BizqYxO6%5Cfqj7NUG3tVz%2F7R2W5zCl1ku5wQI2Wfs8jRuJ%2Be%2FUoawiWytRtamc5JOs2ta5jp7%2BzC%5CqMcce2b6ek5YMIhy5f2f6tJbtKsvrrz2699dXNr21YoB6X52LJ%3A1728745836025; l_s_lofterYlfTAjw=4085618B4BB633950E47B39417C2C88760AA6B02D102278189B669C1A1C4BA9504472CB04226334C6FF3A47A1B8CF6B4ED86A37057D5672A11A28AF580A3478B4F47736A77DBA51AB3B3B07AE16402B202D622A42C55237B96DA5DAF668F79A78DBA698C25E7F349D1EEC2C357FD2874",
        },
      ),
    );
  }

  static Future<dynamic> loginByMailGt(String mail) async {
    return RequestUtil.post(
      "/dl/zj/mail/gt",
      domainType: DomainType.passport,
      data: {
        "encParams": calculateURSSM4(jsonEncode({
          "channel": 0,
          "pd": "lofter",
          "pkid": "YlfTAjw",
          "rtid": "HeN1DujR2kVqEtIKXsw4CJSNQOYy8mBx",
          "topURL": "https://www.lofter.com/front/login",
          "un": mail,
        })),
      },
      options: Options(
        contentType: "${Headers.jsonContentType}; charset=utf-8",
        headers: {
          "Cookie":
              "firstentry=%2Flogin.do|; usertrack=c+53cWcJ4o0X34ckM2x8Ag==; JSESSIONID-WLF-XXD=ecd0454e54d08cc79a37e4ed1ce3c70349c5823c155570d49dbd03af344ace8dd4316050803ce43791c8da46634edf356eed65c1de8139ad682f77dd9bc4b477cd191c9391f5f3dd3ab39dd2c5298237423d222cd09c997a8541a23134c7e3108bef67ba167957690ed53d42fd77d3c723bca305e1cfb4ed53cbb56a05867f68c7014f32; utid=iUcefo5mCo0w8nrdx4RGC9ELzbT9t11c; NTES_WEB_FP=96c082f3dd894f696deec87f7bf724cf; gdxidpyhxdE=1f0Z%2F%2Bq4KvE8OywQscriTOyaw3eOQV2NbW%5Cwzx%2FqInKn9iI0Pk%2BizqYxO6%5Cfqj7NUG3tVz%2F7R2W5zCl1ku5wQI2Wfs8jRuJ%2Be%2FUoawiWytRtamc5JOs2ta5jp7%2BzC%5CqMcce2b6ek5YMIhy5f2f6tJbtKsvrrz2699dXNr21YoB6X52LJ%3A1728745836025; l_s_lofterYlfTAjw=4085618B4BB633950E47B39417C2C88760AA6B02D102278189B669C1A1C4BA9504472CB04226334C6FF3A47A1B8CF6B4ED86A37057D5672A11A28AF580A3478B4F47736A77DBA51AB3B3B07AE16402B202D622A42C55237B96DA5DAF668F79A78DBA698C25E7F349D1EEC2C357FD2874",
        },
      ),
    );
  }

  static Future<dynamic> loginByMailL(
      String mail, String password, String tk) async {
    return RequestUtil.post(
      "/dl/zj/mail/l",
      domainType: DomainType.passport,
      data: {
        "encParams": calculateURSSM4(jsonEncode({
          "un": mail,
          "pd": "lofter",
          "pkid": "YlfTAjw",
          "channel": 0,
          "topURL": "https://www.lofter.com/front/login",
          "rtid": "HeN1DujR2kVqEtIKXsw4CJSNQOYy8mBx",
          "pVParam": {
            "puzzle":
                "woVmIfMmB3qI6a7ywfvS+/7oyCpQ0cGCf+o2wYqut+ifMTRYOnPGBy7ypIPV/JCCuqIBdrOwofaltqVFDkoE+yAtzkWnj2HDDGtuw3BAZoRd9ggDaxHZwpJvThbGTB3zpyqe/+mk3g9Ois3eLxplkJDcLvQWrlmj0StYq3RBR190Nv934N6l7WXL7F+xEwm1EVqv+4uOK38cGdpomlsLbKscoYRvc4MwhI1yf04AqUMvUzHF9Melq95O0L2xQwGeSjmCFIsqW8+CNUw6SXnoeQ==",
            "spendTime": 1051,
            "runTimes": 164488,
            "sid": "58aa38ca-396a-4ba4-add9-34309bee1d16",
            "args":
                '{"x":"3ebaa7f755fe3140adf4c63b85a23e44a","t":164488,"sign":1602334376}',
          },
          "pw": CryptUtil.encryptDataByRSA(password, RSA_PUBLIC_KEY_V2),
          "tk": tk,
          "pwdKeyUp": 1,
          "l": 1,
          "d": 10,
          "domains": "",
          "t": DateTime.now().millisecondsSinceEpoch,
        })),
      },
      options: Options(
        contentType: "${Headers.jsonContentType}; charset=utf-8",
        headers: {
          "Cookie":
              "firstentry=%2Flogin.do|; usertrack=c+53cWcJ4o0X34ckM2x8Ag==; JSESSIONID-WLF-XXD=ecd0454e54d08cc79a37e4ed1ce3c70349c5823c155570d49dbd03af344ace8dd4316050803ce43791c8da46634edf356eed65c1de8139ad682f77dd9bc4b477cd191c9391f5f3dd3ab39dd2c5298237423d222cd09c997a8541a23134c7e3108bef67ba167957690ed53d42fd77d3c723bca305e1cfb4ed53cbb56a05867f68c7014f32; utid=iUcefo5mCo0w8nrdx4RGC9ELzbT9t11c; NTES_WEB_FP=96c082f3dd894f696deec87f7bf724cf; gdxidpyhxdE=1f0Z%2F%2Bq4KvE8OywQscriTOyaw3eOQV2NbW%5Cwzx%2FqInKn9iI0Pk%2BizqYxO6%5Cfqj7NUG3tVz%2F7R2W5zCl1ku5wQI2Wfs8jRuJ%2Be%2FUoawiWytRtamc5JOs2ta5jp7%2BzC%5CqMcce2b6ek5YMIhy5f2f6tJbtKsvrrz2699dXNr21YoB6X52LJ%3A1728745836025; l_s_lofterYlfTAjw=4085618B4BB633950E47B39417C2C88760AA6B02D102278189B669C1A1C4BA9504472CB04226334C6FF3A47A1B8CF6B4ED86A37057D5672A11A28AF580A3478B4F47736A77DBA51AB3B3B07AE16402B202D622A42C55237B96DA5DAF668F79A78DBA698C25E7F349D1EEC2C357FD2874",
        },
      ),
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
