// To parse this JSON data, do
//
//     final dressingListData = dressingListDataFromJson(jsonString);

import 'dart:convert';

DressingListData dressingListDataFromJson(String str) =>
    DressingListData.fromJson(json.decode(str));

String dressingListDataToJson(DressingListData data) =>
    json.encode(data.toJson());

///ApifoxModel
class DressingListData {
  ExpiredSuit expiredSuit;
  List<DressingItem> list;
  int offset;
  int totalCount;

  DressingListData({
    required this.expiredSuit,
    required this.list,
    required this.offset,
    required this.totalCount,
  });

  factory DressingListData.fromJson(Map<String, dynamic> json) =>
      DressingListData(
        expiredSuit: ExpiredSuit.fromJson(json["expiredSuit"]),
        list: List<DressingItem>.from(
            json["list"].map((x) => DressingItem.fromJson(x))),
        offset: json["offset"],
        totalCount: json["totalCount"],
      );

  Map<String, dynamic> toJson() => {
        "expiredSuit": expiredSuit.toJson(),
        "list": List<dynamic>.from(list.map((x) => x.toJson())),
        "offset": offset,
        "totalCount": totalCount,
      };
}

///ExpiredSuit
class ExpiredSuit {
  int id;
  String name;

  ExpiredSuit({
    required this.id,
    required this.name,
  });

  factory ExpiredSuit.fromJson(Map<String, dynamic> json) => ExpiredSuit(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

///DressingItem
class DressingItem {
  List<BarrageList> barrageList;
  int groupBuying;
  int id;
  String img;
  String intro;
  int limitedStock;
  String name;
  int payType;
  int reserved;
  int reserveType;
  int rewardCenter;
  int saleTime;
  String showPrice;
  String specialLabel;
  List<StockList> stockList;
  String underLinePrice;

  DressingItem({
    required this.barrageList,
    required this.groupBuying,
    required this.id,
    required this.img,
    required this.intro,
    required this.limitedStock,
    required this.name,
    required this.payType,
    required this.reserved,
    required this.reserveType,
    required this.rewardCenter,
    required this.saleTime,
    required this.showPrice,
    required this.specialLabel,
    required this.stockList,
    required this.underLinePrice,
  });

  factory DressingItem.fromJson(Map<String, dynamic> json) => DressingItem(
        barrageList: json['barrageList'] == null
            ? []
            : List<BarrageList>.from(
                json["barrageList"].map((x) => BarrageList.fromJson(x))),
        groupBuying: json["groupBuying"],
        id: json["id"],
        img: json["img"],
        intro: json["intro"],
        limitedStock: json["limitedStock"],
        name: json["name"],
        payType: json["payType"],
        reserved: json["reserved"],
        reserveType: json["reserveType"],
        rewardCenter: json["rewardCenter"],
        saleTime: json["saleTime"],
        showPrice: json["showPrice"],
        specialLabel: json["specialLabel"],
        stockList: json["stockList"] == null
            ? []
            : List<StockList>.from(
                json["stockList"].map((x) => StockList.fromJson(x))),
        underLinePrice: json["underLinePrice"],
      );

  Map<String, dynamic> toJson() => {
        "barrageList": List<dynamic>.from(barrageList.map((x) => x.toJson())),
        "groupBuying": groupBuying,
        "id": id,
        "img": img,
        "intro": intro,
        "limitedStock": limitedStock,
        "name": name,
        "payType": payType,
        "reserved": reserved,
        "reserveType": reserveType,
        "rewardCenter": rewardCenter,
        "saleTime": saleTime,
        "showPrice": showPrice,
        "specialLabel": specialLabel,
        "stockList": List<dynamic>.from(stockList.map((x) => x.toJson())),
        "underLinePrice": underLinePrice,
      };
}

///BarrageItem
class BarrageList {
  String avatarUrl;
  int luckyNo;
  String nickName;
  String number;
  int userId;

  BarrageList({
    required this.avatarUrl,
    required this.luckyNo,
    required this.nickName,
    required this.number,
    required this.userId,
  });

  factory BarrageList.fromJson(Map<String, dynamic> json) => BarrageList(
        avatarUrl: json["avatarUrl"],
        luckyNo: json["luckyNo"],
        nickName: json["nickName"],
        number: json["number"],
        userId: json["userId"],
      );

  Map<String, dynamic> toJson() => {
        "avatarUrl": avatarUrl,
        "luckyNo": luckyNo,
        "nickName": nickName,
        "number": number,
        "userId": userId,
      };
}

///StockItem
class StockList {
  int price;
  int saleCount;
  bool selected;
  int stock;
  int type;

  StockList({
    required this.price,
    required this.saleCount,
    required this.selected,
    required this.stock,
    required this.type,
  });

  factory StockList.fromJson(Map<String, dynamic> json) => StockList(
        price: json["price"],
        saleCount: json["saleCount"],
        selected: json["selected"],
        stock: json["stock"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "price": price,
        "saleCount": saleCount,
        "selected": selected,
        "stock": stock,
        "type": type,
      };
}
