import 'package:loftify/Models/return_gift_response.dart';

///GiftData
class GiftData {
  GiftDress? returnGiftDress;
  GiftEmote? returnGiftEmotePackage;
  int type;

  GiftData({
    required this.returnGiftDress,
    required this.returnGiftEmotePackage,
    required this.type,
  });

  factory GiftData.fromJson(Map<String, dynamic> json) => GiftData(
        returnGiftDress: json["returnGiftDress"] == null
            ? null
            : GiftDress.fromJson(json["returnGiftDress"]),
        returnGiftEmotePackage: json["returnGiftEmotePackage"] == null
            ? null
            : GiftEmote.fromJson(json["returnGiftEmotePackage"]),
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "returnGiftDress": returnGiftDress?.toJson(),
        "returnGiftEmotePackage": returnGiftEmotePackage?.toJson(),
        "type": type,
      };
}

class GiftDress {
  String coverImg;
  int creatorBlogId;
  String creatorBlogName;
  String creatorNickName;
  int gainedFansVip;
  int giftId;
  String img;
  String name;
  int partCount;
  List<GiftPartItem> partList;
  int returnGiftDressId;
  String saleEndText;
  int saleEndTime;
  dynamic salePromotion;

  GiftDress({
    required this.coverImg,
    required this.creatorBlogId,
    required this.creatorBlogName,
    required this.creatorNickName,
    required this.gainedFansVip,
    required this.giftId,
    required this.img,
    required this.name,
    required this.partCount,
    required this.partList,
    required this.returnGiftDressId,
    required this.saleEndText,
    required this.saleEndTime,
    required this.salePromotion,
  });

  factory GiftDress.fromJson(Map<String, dynamic> json) => GiftDress(
        coverImg: json["coverImg"],
        creatorBlogId: json["creatorBlogId"],
        creatorBlogName: json["creatorBlogName"],
        creatorNickName: json["creatorNickName"],
        gainedFansVip: json["gainedFansVip"],
        giftId: json["giftId"],
        img: json["img"],
        name: json["name"],
        partCount: json["partCount"],
        partList: List<GiftPartItem>.from(
            json["partList"].map((x) => GiftPartItem.fromJson(x))),
        returnGiftDressId: json["returnGiftDressId"],
        saleEndText: json["saleEndText"],
        saleEndTime: json["saleEndTime"],
        salePromotion: json["salePromotion"],
      );

  Map<String, dynamic> toJson() => {
        "coverImg": coverImg,
        "creatorBlogId": creatorBlogId,
        "creatorBlogName": creatorBlogName,
        "creatorNickName": creatorNickName,
        "gainedFansVip": gainedFansVip,
        "giftId": giftId,
        "img": img,
        "name": name,
        "partCount": partCount,
        "partList": List<dynamic>.from(partList.map((x) => x.toJson())),
        "returnGiftDressId": returnGiftDressId,
        "saleEndText": saleEndText,
        "saleEndTime": saleEndTime,
        "salePromotion": salePromotion,
      };
}

///GiftPartItem
class GiftPartItem {
  int expireDays;
  int id;
  String img;
  int obtainDays;
  int obtainPermanent;
  int onSale;
  String partName;
  int partType;
  String partUrl;
  int saleSaleEndTime;
  int saleStartTime;
  int scarce;

  GiftPartItem({
    required this.expireDays,
    required this.id,
    required this.img,
    required this.obtainDays,
    required this.obtainPermanent,
    required this.onSale,
    required this.partName,
    required this.partType,
    required this.partUrl,
    required this.saleSaleEndTime,
    required this.saleStartTime,
    required this.scarce,
  });

  factory GiftPartItem.fromJson(Map<String, dynamic> json) => GiftPartItem(
        expireDays: json["expireDays"],
        id: json["id"],
        img: json["img"],
        obtainDays: json["obtainDays"],
        obtainPermanent: json["obtainPermanent"],
        onSale: json["onSale"],
        partName: json["partName"],
        partType: json["partType"],
        partUrl: json["partUrl"],
        saleSaleEndTime: json["saleSaleEndTime"],
        saleStartTime: json["saleStartTime"],
        scarce: json["scarce"],
      );

  Map<String, dynamic> toJson() => {
        "expireDays": expireDays,
        "id": id,
        "img": img,
        "obtainDays": obtainDays,
        "obtainPermanent": obtainPermanent,
        "onSale": onSale,
        "partName": partName,
        "partType": partType,
        "partUrl": partUrl,
        "saleSaleEndTime": saleSaleEndTime,
        "saleStartTime": saleStartTime,
        "scarce": scarce,
      };
}

///GiftEmote
class GiftEmote {
  int creatorBlogId;
  int emoteCount;
  List<EmoteItem> emoteList;
  int endTime;
  int giftId;
  String img;
  String name;
  int packageId;
  String promotion;
  String saleEndText;
  int sizeType;
  String url;

  GiftEmote({
    required this.creatorBlogId,
    required this.emoteCount,
    required this.emoteList,
    required this.endTime,
    required this.giftId,
    required this.img,
    required this.name,
    required this.packageId,
    required this.promotion,
    required this.saleEndText,
    required this.sizeType,
    required this.url,
  });

  factory GiftEmote.fromJson(Map<String, dynamic> json) => GiftEmote(
        creatorBlogId: json["creatorBlogId"],
        emoteCount: json["emoteCount"],
        emoteList: List<EmoteItem>.from(
            json["emoteList"].map((x) => EmoteItem.fromJson(x))),
        endTime: json["endTime"],
        giftId: json["giftId"],
        img: json["img"],
        name: json["name"],
        packageId: json["packageId"],
        promotion: json["promotion"],
        saleEndText: json["saleEndText"],
        sizeType: json["sizeType"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "creatorBlogId": creatorBlogId,
        "emoteCount": emoteCount,
        "emoteList": List<dynamic>.from(emoteList.map((x) => x.toJson())),
        "endTime": endTime,
        "giftId": giftId,
        "img": img,
        "name": name,
        "packageId": packageId,
        "promotion": promotion,
        "saleEndText": saleEndText,
        "sizeType": sizeType,
        "url": url,
      };
}

class EmoteItem {
  int acquired;
  int auditTime;
  int id;
  String name;
  int newest;
  bool onSale;
  int packageId;
  int saleEndTime;
  int saleStartTime;
  int scarce;
  int sizeType;
  String url;

  EmoteItem({
    required this.acquired,
    required this.auditTime,
    required this.id,
    required this.name,
    required this.newest,
    required this.onSale,
    required this.packageId,
    required this.saleEndTime,
    required this.saleStartTime,
    required this.scarce,
    required this.sizeType,
    required this.url,
  });

  factory EmoteItem.fromJson(Map<String, dynamic> json) => EmoteItem(
        acquired: json["acquired"],
        auditTime: json["auditTime"],
        id: json["id"],
        name: json["name"],
        newest: json["newest"],
        onSale: json["onSale"],
        packageId: json["packageId"],
        saleEndTime: json["saleEndTime"],
        saleStartTime: json["saleStartTime"],
        scarce: json["scarce"],
        sizeType: json["sizeType"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "acquired": acquired,
        "auditTime": auditTime,
        "id": id,
        "name": name,
        "newest": newest,
        "onSale": onSale,
        "packageId": packageId,
        "saleEndTime": saleEndTime,
        "saleStartTime": saleStartTime,
        "scarce": scarce,
        "sizeType": sizeType,
        "url": url,
      };
}

class GrantRecord {
  final String action;
  final String img;
  int grantTime;
  int count;
  String rule;

  GrantRecord({
    required this.action,
    required this.img,
    required this.grantTime,
    required this.count,
    required this.rule,
  });

  factory GrantRecord.fromJson(Map<String, dynamic> json) => GrantRecord(
        action: json["action"],
        img: json["img"],
        grantTime: json["grantTime"],
        count: json["count"],
        rule: json["rule"],
      );

  Map<String, dynamic> toJson() => {
        "action": action,
        "img": img,
        "grantTime": grantTime,
        "count": count,
        "rule": rule,
      };
}

class CosumeLog {
  final String action;
  final int type;
  final String tip;
  final String link;
  final String img;
  final int count;
  final int time;

  CosumeLog({
    required this.action,
    required this.type,
    required this.tip,
    required this.link,
    required this.img,
    required this.count,
    required this.time,
  });

  factory CosumeLog.fromJson(Map<String, dynamic> json) => CosumeLog(
        action: json["action"],
        type: json["type"],
        tip: json["tip"],
        link: json["link"],
        img: json["img"],
        count: json["count"],
        time: json["time"],
      );

  Map<String, dynamic> toJson() => {
        "action": action,
        "type": type,
        "tip": tip,
        "link": link,
        "img": img,
        "count": count,
        "time": time,
      };
}

class UserTasksData {
  final UserLimitedTasks limitedTasks;
  final Gift freeGiftBag;
  final List<UserTask> tasks;

  UserTasksData({
    required this.limitedTasks,
    required this.freeGiftBag,
    required this.tasks,
  });

  factory UserTasksData.fromJson(Map<String, dynamic> json) => UserTasksData(
        limitedTasks: UserLimitedTasks.fromJson(json["limitedTasks"]),
        freeGiftBag: Gift.fromJson(json["freeGiftBag"]),
        tasks:
            List<UserTask>.from(json["tasks"].map((x) => UserTask.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "limitedTasks": limitedTasks.toJson(),
        "freeGiftBag": freeGiftBag.toJson(),
        "tasks": List<dynamic>.from(tasks.map((x) => x.toJson())),
      };
}

class UserTask {
  String action;
  String rule;
  String img;
  int progress;
  int goal;
  int count;
  int type;

  UserTask({
    required this.action,
    required this.rule,
    required this.img,
    required this.progress,
    required this.goal,
    required this.count,
    required this.type,
  });

  factory UserTask.fromJson(Map<String, dynamic> json) => UserTask(
        action: json["action"],
        rule: json["rule"],
        img: json["img"],
        progress: json["progress"],
        goal: json["goal"],
        count: json["count"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "action": action,
        "rule": rule,
        "img": img,
        "progress": progress,
        "goal": goal,
        "count": count,
        "type": type,
      };
}

class UserLimitedTasks {
  final List<AdReawrdTask> adReawrdTasks;

  const UserLimitedTasks({
    required this.adReawrdTasks,
  });

  factory UserLimitedTasks.fromJson(Map<String, dynamic> json) =>
      UserLimitedTasks(
        adReawrdTasks: List<AdReawrdTask>.from(
            json["adReawrdTasks"].map((x) => AdReawrdTask.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "adReawrdTasks":
            List<dynamic>.from(adReawrdTasks.map((x) => x.toJson())),
      };
}

class AdReawrdTask {
  final String rewardName;
  final int rewardId;
  final int rewardCount;
  final int rewardType;
  final int rewardStatus; //1已经获取 0未获取

  const AdReawrdTask({
    required this.rewardName,
    required this.rewardId,
    required this.rewardCount,
    required this.rewardType,
    required this.rewardStatus,
  });

  factory AdReawrdTask.fromJson(Map<String, dynamic> json) => AdReawrdTask(
        rewardName: json["rewardName"],
        rewardId: json["rewardId"],
        rewardCount: json["rewardCount"],
        rewardType: json["rewardType"],
        rewardStatus: json["rewardStatus"],
      );

  Map<String, dynamic> toJson() => {
        "rewardName": rewardName,
        "rewardId": rewardId,
        "rewardCount": rewardCount,
        "rewardType": rewardType,
        "rewardStatus": rewardStatus,
      };
}

class CoinOrder {
  String amount;
  String desc;
  int createTime;
  int finishTime;
  int type;
  int id;

  CoinOrder({
    required this.amount,
    required this.desc,
    required this.createTime,
    required this.finishTime,
    required this.type,
    required this.id,
  });

  factory CoinOrder.fromJson(Map<String, dynamic> json) => CoinOrder(
        amount: json["amount"],
        desc: json["desc"],
        createTime: json["createTime"],
        finishTime: json["finishTime"],
        type: json["type"],
        id: json["id"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "desc": desc,
        "createTime": createTime,
        "finishTime": finishTime,
        "type": type,
        "id": id,
      };
}
