import 'package:loftify/Models/post_detail_response.dart';

///GiftInfoData
class GiftInfoData {
  int fansPrivateUnlock;
  List<Gift> gainReturnGifts;
  int giftAccountType;
  List<PurpleGift> gifts;
  OfficialGrainSchema officialGrainSchema;
  List<ReturnGift> returnGifts;
  SupportInfo supportInfo;
  UserBag userBag;
  int userType;
  int vipShowStyle;

  GiftInfoData({
    required this.fansPrivateUnlock,
    required this.gainReturnGifts,
    required this.giftAccountType,
    required this.gifts,
    required this.officialGrainSchema,
    required this.returnGifts,
    required this.supportInfo,
    required this.userBag,
    required this.userType,
    required this.vipShowStyle,
  });

  factory GiftInfoData.fromJson(Map<String, dynamic> json) => GiftInfoData(
        fansPrivateUnlock: json["fansPrivateUnlock"],
        gainReturnGifts: List<Gift>.from(
            json["gainReturnGifts"].map((x) => Gift.fromJson(x))),
        giftAccountType: json["giftAccountType"],
        gifts: List<PurpleGift>.from(
            json["gifts"].map((x) => PurpleGift.fromJson(x))),
        officialGrainSchema:
            OfficialGrainSchema.fromJson(json["officialGrainSchema"]),
        returnGifts: List<ReturnGift>.from(
            json["returnGifts"].map((x) => ReturnGift.fromJson(x))),
        supportInfo: SupportInfo.fromJson(json["supportInfo"]),
        userBag: UserBag.fromJson(json["userBag"]),
        userType: json["userType"],
        vipShowStyle: json["vipShowStyle"],
      );

  Map<String, dynamic> toJson() => {
        "fansPrivateUnlock": fansPrivateUnlock,
        "gainReturnGifts":
            List<dynamic>.from(gainReturnGifts.map((x) => x.toJson())),
        "giftAccountType": giftAccountType,
        "gifts": List<dynamic>.from(gifts.map((x) => x.toJson())),
        "officialGrainSchema": officialGrainSchema.toJson(),
        "returnGifts": List<dynamic>.from(returnGifts.map((x) => x.toJson())),
        "supportInfo": supportInfo.toJson(),
        "userBag": userBag.toJson(),
        "userType": userType,
        "vipShowStyle": vipShowStyle,
      };
}

///Gift
class Gift {
  int? coin;
  int? count;
  String coupons;
  int? expireDays;
  int giftType;
  int? id;
  String? image;
  String? name;
  int type;

  Gift({
    this.coin,
    this.count,
    required this.coupons,
    this.expireDays,
    required this.giftType,
    this.id,
    this.image,
    this.name,
    required this.type,
  });

  factory Gift.fromJson(Map<String, dynamic> json) => Gift(
        coin: json["coin"] ?? 0,
        count: json["count"] ?? 0,
        coupons: json["coupons"] ?? "",
        expireDays: json["expireDays"] ?? 0,
        giftType: json["giftType"] ?? 0,
        id: json["id"] ?? 0,
        image: json["image"] ?? "",
        name: json["name"] ?? "",
        type: json["type"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "coin": coin,
        "count": count,
        "coupons": coupons,
        "expireDays": expireDays,
        "giftType": giftType,
        "id": id,
        "image": image,
        "name": name,
        "type": type,
      };

  Gift copyWith({
    int? coin,
    int? count,
    String? coupons,
    int? expireDays,
    int? giftType,
    int? id,
    String? image,
    String? name,
    int? type,
  }) {
    return Gift(
      coin: coin ?? this.coin,
      count: count ?? this.count,
      coupons: coupons ?? this.coupons,
      expireDays: expireDays ?? this.expireDays,
      giftType: giftType ?? this.giftType,
      id: id ?? this.id,
      image: image ?? this.image,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}

class PurpleGift {
  Gift gift;
  PlanType? planType;

  PurpleGift({
    required this.gift,
    this.planType,
  });

  factory PurpleGift.fromJson(Map<String, dynamic> json) => PurpleGift(
        gift: Gift.fromJson(json["gift"]),
        planType: json["planType"] == null
            ? null
            : PlanType.fromJson(json["planType"]),
      );

  Map<String, dynamic> toJson() => {
        "gift": gift.toJson(),
        "planType": planType?.toJson(),
      };
}

///PlanType
class PlanType {
  String bcolor;
  String bgImg;
  String icon;
  int id;
  String img;
  String imgV2;
  String name;
  int planType;

  PlanType({
    required this.bcolor,
    required this.bgImg,
    required this.icon,
    required this.id,
    required this.img,
    required this.imgV2,
    required this.name,
    required this.planType,
  });

  factory PlanType.fromJson(Map<String, dynamic> json) => PlanType(
        bcolor: json["bcolor"] ?? "",
        bgImg: json["bgImg"] ?? "",
        icon: json["icon"] ?? "",
        id: json["id"] ?? 0,
        img: json["img"] ?? "",
        imgV2: json["imgV2"] ?? "",
        name: json["name"] ?? "",
        planType: json["planType"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "bcolor": bcolor,
        "bgImg": bgImg,
        "icon": icon,
        "id": id,
        "img": img,
        "imgV2": imgV2,
        "name": name,
        "planType": planType,
      };
}

///OfficialGrainSchema
class OfficialGrainSchema {
  String schema;
  String title;
  int type;

  OfficialGrainSchema({
    required this.schema,
    required this.title,
    required this.type,
  });

  factory OfficialGrainSchema.fromJson(Map<String, dynamic> json) =>
      OfficialGrainSchema(
        schema: json["schema"] ?? "",
        title: json["title"] ?? "",
        type: json["type"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "schema": schema,
        "title": title,
        "type": type,
      };
}

///ReturnGift
class ReturnGift {
  List<String>? avaImgs;
  List<String>? feedbacks;
  int? chanceCount;
  String? defaultPromotion;
  List<Gift>? defaultSelectedGifts;
  String? firstImage;
  int? id;
  int? imgCount;
  List<GiftPriorityLabel>? labels;
  PlanType? planType;
  List<PreviewImage>? previewImages;
  String? promotion;
  int? screenshotFlag;
  String? title;
  int? unlockCount;
  int? wordCount;
  int? unlockType;
  String? digest;
  String? content;
  List<PreviewImage> images;

  ReturnGift({
    this.avaImgs,
    required this.images,
    this.chanceCount,
    this.defaultPromotion,
    this.defaultSelectedGifts,
    this.firstImage,
    this.id,
    this.imgCount,
    this.labels,
    this.planType,
    this.previewImages,
    this.promotion,
    this.screenshotFlag,
    this.title,
    this.unlockCount,
    this.wordCount,
    this.unlockType,
    this.feedbacks,
    this.digest,
    this.content,
  });

  factory ReturnGift.fromJson(Map<String, dynamic> json) => ReturnGift(
        avaImgs: json["avaImgs"] == null
            ? null
            : List<String>.from(json["avaImgs"].map((x) => x)),
        feedbacks: json["feedbacks"] == null
            ? null
            : List<String>.from(json["feedbacks"].map((x) => x.toString())),
        chanceCount: json["chanceCount"],
        defaultPromotion: json["defaultPromotion"],
        defaultSelectedGifts: json["defaultSelectedGifts"] == null
            ? null
            : List<Gift>.from(
                json["defaultSelectedGifts"].map((x) => Gift.fromJson(x))),
        firstImage: json["firstImage"],
        id: json["id"],
        imgCount: json["imgCount"],
        labels: json["labels"] == null
            ? null
            : List<GiftPriorityLabel>.from(
                json["labels"].map((x) => GiftPriorityLabel.fromJson(x))),
        planType: json["planType"] == null
            ? null
            : PlanType.fromJson(json["planType"]),
        previewImages: json["previewImages"] == null
            ? null
            : List<PreviewImage>.from(
                json["previewImages"].map((x) => PreviewImage.fromJson(x))),
        promotion: json["promotion"] ?? '',
        screenshotFlag: json["screenshotFlag"] ?? 0,
        title: json["title"] ?? "",
        unlockCount: json["unlockCount"] ?? 0,
        wordCount: json["wordCount"] ?? 0,
        unlockType: json["unlockType"] ?? 0,
        digest: json['digest'] ?? '',
        content: json['content'] ?? "",
        images: json['images'] == null
            ? []
            : List<PreviewImage>.from(
                json['images'].map((x) => PreviewImage.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "avaImgs":
            avaImgs == null ? null : List<dynamic>.from(avaImgs!.map((x) => x)),
        "chanceCount": chanceCount,
        "defaultPromotion": defaultPromotion,
        "defaultSelectedGifts": defaultSelectedGifts == null
            ? null
            : List<dynamic>.from(defaultSelectedGifts!.map((x) => x.toJson())),
        "firstImage": firstImage,
        "id": id,
        "imgCount": imgCount,
        "labels": labels == null
            ? null
            : List<dynamic>.from(labels!.map((x) => x.toJson())),
        "planType": planType?.toJson(),
        "previewImages": previewImages == null
            ? null
            : List<dynamic>.from(previewImages!.map((x) => x.toJson())),
        "promotion": promotion,
        "screenshotFlag": screenshotFlag,
        "title": title,
        "unlockCount": unlockCount,
        "unlockType": unlockType,
        'digest': digest,
      };
}

///GiftPriorityLabel
class GiftPriorityLabel {
  String? label;
  int? priority;

  GiftPriorityLabel({
    this.label,
    this.priority,
  });

  factory GiftPriorityLabel.fromJson(Map<String, dynamic> json) =>
      GiftPriorityLabel(
        label: json["label"] ?? '',
        priority: json["priority"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "label": label,
        "priority": priority,
      };
}

class SupportInfo {
  List<String> avaImgs;
  int supporterCount;

  SupportInfo({
    required this.avaImgs,
    required this.supporterCount,
  });

  factory SupportInfo.fromJson(Map<String, dynamic> json) => SupportInfo(
        avaImgs: List<String>.from(json["avaImgs"].map((x) => x)),
        supporterCount: json["supporterCount"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "avaImgs": List<dynamic>.from(avaImgs.map((x) => x)),
        "supporterCount": supporterCount,
      };
}

///UserBag
class UserBag {
  int coin;
  List<Gift> exchangeCoupons;
  List<Gift> gifts;
  String pageUrl;

  UserBag({
    required this.coin,
    required this.exchangeCoupons,
    required this.gifts,
    required this.pageUrl,
  });

  factory UserBag.fromJson(Map<String, dynamic> json) => UserBag(
        coin: json["coin"] ?? 0,
        exchangeCoupons: List<Gift>.from(
            json["exchangeCoupons"].map((x) => Gift.fromJson(x))),
        gifts: List<Gift>.from(json["gifts"].map((x) => Gift.fromJson(x))),
        pageUrl: json["pageUrl"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "coin": coin,
        "exchangeCoupons":
            List<dynamic>.from(exchangeCoupons.map((x) => x.toJson())),
        "gifts": List<dynamic>.from(gifts.map((x) => x.toJson())),
        "pageUrl": pageUrl,
      };
}
