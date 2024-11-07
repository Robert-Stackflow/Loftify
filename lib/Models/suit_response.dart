import 'package:loftify/Models/post_detail_response.dart';

///ProductItem
class ProductItem {
  ProductData? product;
  LootBoxData? lootBox;
  List<ProductTag> tags;
  int type;

  ProductItem({
    required this.product,
    required this.tags,
    required this.type,
    required this.lootBox,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      product: json['product'] == null
          ? null
          : ProductData.fromJson(json['product']),
      lootBox: json['lootBox'] == null
          ? null
          : LootBoxData.fromJson(json['lootBox']),
      tags: List<ProductTag>.from(
          json['tags'].map((x) => ProductTag.fromJson(x))),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product'] = product?.toJson();
    data['tags'] = tags.map((x) => x.toJson()).toList();
    data['type'] = type;
    return data;
  }

  bool isSame(ProductItem other) {
    if (type == other.type) {
      if (type == 0) {
        return product?.id == other.product?.id;
      } else {
        return lootBox?.id == other.lootBox?.id;
      }
    } else {
      return false;
    }
  }
}

///ProductData
class ProductData {
  List<ProductAvatarItem> avatars;
  int blogId;
  int coin;
  int id;
  String intro;
  String name;
  bool obtained;
  List<String> procedureImgs;
  List<ProductWallpaperItem> wallpapers;

  ProductData({
    required this.avatars,
    required this.blogId,
    required this.coin,
    required this.id,
    required this.intro,
    required this.name,
    required this.obtained,
    required this.procedureImgs,
    required this.wallpapers,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      avatars: List<ProductAvatarItem>.from(
          json['avatars'].map((x) => ProductAvatarItem.fromJson(x))),
      blogId: json['blogId'],
      coin: json['coin'],
      id: json['id'],
      intro: json['intro'],
      name: json['name'],
      obtained: json['obtained'],
      procedureImgs: List<String>.from(json['procedureImgs'].map((x) => x)),
      wallpapers: List<ProductWallpaperItem>.from(
          json['wallpapers'].map((x) => ProductWallpaperItem.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['avatars'] = avatars.map((x) => x.toJson()).toList();
    data['blogId'] = blogId;
    data['coin'] = coin;
    data['id'] = id;
    data['intro'] = intro;
    data['name'] = name;
    data['obtained'] = obtained;
    data['procedureImgs'] = procedureImgs;
    data['wallpapers'] = wallpapers.map((x) => x.toJson()).toList();
    return data;
  }
}

///ProductAvatarItem
class ProductAvatarItem {
  int category;
  int id;
  PreviewImage img;
  bool obtained;
  int productId;
  int type;
  int userId;

  ProductAvatarItem({
    required this.category,
    required this.id,
    required this.img,
    required this.obtained,
    required this.productId,
    required this.type,
    required this.userId,
  });

  factory ProductAvatarItem.fromJson(Map<String, dynamic> json) {
    return ProductAvatarItem(
      category: json['category'],
      id: json['id'],
      img: PreviewImage.fromJson(json['img']),
      obtained: json['obtained'],
      productId: json['productId'],
      type: json['type'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['category'] = category;
    data['id'] = id;
    data['img'] = img.toJson();
    data['obtained'] = obtained;
    data['productId'] = productId;
    data['type'] = type;
    data['userId'] = userId;
    return data;
  }
}

///ProductWallpaperItem
class ProductWallpaperItem {
  int category;
  int id;
  PreviewImage img;
  bool obtained;
  int productId;
  int type;
  int userId;

  ProductWallpaperItem({
    required this.category,
    required this.id,
    required this.img,
    required this.obtained,
    required this.productId,
    required this.type,
    required this.userId,
  });

  factory ProductWallpaperItem.fromJson(Map<String, dynamic> json) {
    return ProductWallpaperItem(
      category: json['category'],
      id: json['id'],
      img: PreviewImage.fromJson(json['img']),
      obtained: json['obtained'],
      productId: json['productId'],
      type: json['type'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['category'] = category;
    data['id'] = id;
    data['img'] = img.toJson();
    data['obtained'] = obtained;
    data['productId'] = productId;
    data['type'] = type;
    data['userId'] = userId;
    return data;
  }
}

///ProductTag
class ProductTag {
  dynamic icon;
  String tag;

  ProductTag({
    required this.icon,
    required this.tag,
  });

  factory ProductTag.fromJson(Map<String, dynamic> json) {
    return ProductTag(
      icon: json['icon'],
      tag: json['tag'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['icon'] = icon;
    data['tag'] = tag;
    return data;
  }
}

///LootBoxData
class LootBoxData {
  int id;
  String name;
  int obtainedCount;
  List<SlotProductItem> productItems;
  List<SlotOption> slotOptions;
  int type;

  LootBoxData({
    required this.id,
    required this.name,
    required this.obtainedCount,
    required this.productItems,
    required this.slotOptions,
    required this.type,
  });

  factory LootBoxData.fromJson(Map<String, dynamic> json) {
    return LootBoxData(
      id: json['id'],
      name: json['name'],
      obtainedCount: json['obtainedCount'],
      productItems: List<SlotProductItem>.from(
          json['productItems'].map((x) => SlotProductItem.fromJson(x))),
      slotOptions: List<SlotOption>.from(
          json['slotOptions'].map((x) => SlotOption.fromJson(x))),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['obtainedCount'] = obtainedCount;
    data['productItems'] = productItems.map((x) => x.toJson()).toList();
    data['slotOptions'] = slotOptions.map((x) => x.toJson()).toList();
    data['type'] = type;
    return data;
  }
}

///SlotProductItem
class SlotProductItem {
  int category;
  int id;
  PreviewImage img;
  bool obtained;
  int productId;
  int type;
  int userId;

  SlotProductItem({
    required this.category,
    required this.id,
    required this.img,
    required this.obtained,
    required this.productId,
    required this.type,
    required this.userId,
  });

  factory SlotProductItem.fromJson(Map<String, dynamic> json) {
    return SlotProductItem(
      category: json['category'],
      id: json['id'],
      img: PreviewImage.fromJson(json['img']),
      obtained: json['obtained'],
      productId: json['productId'],
      type: json['type'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['category'] = category;
    data['id'] = id;
    data['img'] = img.toJson();
    data['obtained'] = obtained;
    data['productId'] = productId;
    data['type'] = type;
    data['userId'] = userId;
    return data;
  }
}

///SlotOptions
class SlotOption {
  String button;
  int coin;
  int cost;
  int count;
  int id;
  int type;

  SlotOption({
    required this.button,
    required this.coin,
    required this.cost,
    required this.count,
    required this.id,
    required this.type,
  });

  factory SlotOption.fromJson(Map<String, dynamic> json) {
    return SlotOption(
      button: json['button'],
      coin: json['coin'],
      cost: json['cost'],
      count: json['count'],
      id: json['id'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['button'] = button;
    data['coin'] = coin;
    data['cost'] = cost;
    data['count'] = count;
    data['id'] = id;
    data['type'] = type;
    return data;
  }
}
