import '../Utils/request_util.dart';

class ImageApi {
  static Future getImageToken({
    required String fileExt,
  }) async {
    return RequestUtil.post(
      "/v1.1/img/upload/genToken.api",
      data: {
        "fileExt": fileExt,
        "logic": 1,
      },
    );
  }

  static Future getAvatarImageToken({
    required String fileExt,
    required int blogId,
  }) async {
    return RequestUtil.post(
      "/avaimage/upload/genToken.api",
      data: {
        "fileExt": fileExt,
        "blogId": blogId,
      },
    );
  }

  static Future uploadImage({
    required String bucketName,
    required String objectName,
  }) async {
    return RequestUtil.post(
      "/$bucketName/$objectName",
      domainType: DomainType.image,
      params: {
        "version": "1.0",
        "offset": 0,
        "complete": true,
      },
    );
  }

  static Future updateAvatar({
    required String imageUrl,
    required int blogId,
  }) async {
    return RequestUtil.post(
      "/v1.1/avaimageupload.api",
      data: {
        "imageUrl": imageUrl,
        "blogId": blogId,
      },
    );
  }
}
