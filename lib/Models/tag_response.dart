///TagDetailData
class TagDetailData {
  dynamic candyActivity;
  CollectionRank? collectionRank;
  int cosplayFlag;
  String defaultHotType;
  bool favorited;
  String favoritedTagId;
  bool forbidden;
  String grainCoverUrl;
  bool isTagManager;
  int newStyleFlag;
  int postAllCount;
  TagGiftConfig? propGiftTagConfig;
  int protectedFlag;
  int redirectTagId;
  String relatedTags;
  bool showGrainInfo;
  bool showRecommendTab;
  String tag;
  int tagChatFlag;
  TagConfig tagConfig;
  List<TagRanksNew> tagRanksNew;
  int tagStatus;
  TagTreeInfo tagTreeInfo;
  int tagViewCount;
  String type;

  TagDetailData({
    required this.candyActivity,
    required this.collectionRank,
    required this.cosplayFlag,
    required this.defaultHotType,
    required this.favorited,
    required this.favoritedTagId,
    required this.forbidden,
    required this.grainCoverUrl,
    required this.isTagManager,
    required this.newStyleFlag,
    required this.postAllCount,
    required this.propGiftTagConfig,
    required this.protectedFlag,
    required this.redirectTagId,
    required this.relatedTags,
    required this.showGrainInfo,
    required this.showRecommendTab,
    required this.tag,
    required this.tagChatFlag,
    required this.tagConfig,
    required this.tagRanksNew,
    required this.tagStatus,
    required this.tagTreeInfo,
    required this.tagViewCount,
    required this.type,
  });

  factory TagDetailData.fromJson(Map<String, dynamic> json) => TagDetailData(
        candyActivity: json["candyActivity"],
        collectionRank: json["collectionRank"] != null
            ? CollectionRank.fromJson(json["collectionRank"])
            : null,
        cosplayFlag: json["cosplayFlag"] ?? 0,
        defaultHotType: json["defaultHotType"] ?? "",
        favorited: json["favorited"],
        favoritedTagId: json["favoritedTagId"] ?? "",
        forbidden: json["forbidden"],
        grainCoverUrl: json["grainCoverUrl"],
        isTagManager: json["isTagManager"],
        newStyleFlag: json["newStyleFlag"],
        postAllCount: json["postAllCount"],
        propGiftTagConfig: json["propGiftTagConfig"] != null
            ? TagGiftConfig.fromJson(json["propGiftTagConfig"])
            : null,
        protectedFlag: json["protectedFlag"],
        redirectTagId: json["redirectTagId"],
        relatedTags: json["relatedTags"] ?? "",
        showGrainInfo: json["showGrainInfo"],
        showRecommendTab: json["showRecommendTab"],
        tag: json["tag"],
        tagChatFlag: json["tagChatFlag"],
        tagConfig: TagConfig.fromJson(json["tagConfig"]),
        tagRanksNew: List<TagRanksNew>.from(
            json["tagRanksNew"].map((x) => TagRanksNew.fromJson(x))),
        tagStatus: json["tagStatus"],
        tagTreeInfo: TagTreeInfo.fromJson(json["tagTreeInfo"]),
        tagViewCount: json["tagViewCount"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "candyActivity": candyActivity,
        "collectionRank": collectionRank?.toJson(),
        "cosplayFlag": cosplayFlag,
        "defaultHotType": defaultHotType,
        "favorited": favorited,
        "favoritedTagId": favoritedTagId,
        "forbidden": forbidden,
        "grainCoverUrl": grainCoverUrl,
        "isTagManager": isTagManager,
        "newStyleFlag": newStyleFlag,
        "postAllCount": postAllCount,
        "propGiftTagConfig": propGiftTagConfig?.toJson(),
        "protectedFlag": protectedFlag,
        "redirectTagId": redirectTagId,
        "relatedTags": relatedTags,
        "showGrainInfo": showGrainInfo,
        "showRecommendTab": showRecommendTab,
        "tag": tag,
        "tagChatFlag": tagChatFlag,
        "tagConfig": tagConfig.toJson(),
        "tagRanksNew":
            List<TagRanksNew>.from(tagRanksNew.map((x) => x.toJson())),
        "tagStatus": tagStatus,
        "tagTreeInfo": tagTreeInfo.toJson(),
        "tagViewCount": tagViewCount,
        "type": type,
      };
}

///TagCollectionRank
class CollectionRank {
  int collectionId;
  int rankDayTime;
  String title;
  bool updated;

  CollectionRank({
    required this.collectionId,
    required this.rankDayTime,
    required this.title,
    required this.updated,
  });

  factory CollectionRank.fromJson(Map<String, dynamic> json) => CollectionRank(
        collectionId: json["collectionId"],
        rankDayTime: json["rankDayTime"],
        title: json["title"],
        updated: json["updated"],
      );

  Map<String, dynamic> toJson() => {
        "collectionId": collectionId,
        "rankDayTime": rankDayTime,
        "title": title,
        "updated": updated,
      };
}

///TagGiftConfig
class TagGiftConfig {
  String schema;
  int slotCount;
  int sortCount;
  String subTitle;
  String title;

  TagGiftConfig({
    required this.schema,
    required this.slotCount,
    required this.sortCount,
    required this.subTitle,
    required this.title,
  });

  factory TagGiftConfig.fromJson(Map<String, dynamic> json) => TagGiftConfig(
        schema: json["schema"],
        slotCount: json["slotCount"],
        sortCount: json["sortCount"],
        subTitle: json["subTitle"],
        title: json["title"],
      );

  Map<String, dynamic> toJson() => {
        "schema": schema,
        "slotCount": slotCount,
        "sortCount": sortCount,
        "subTitle": subTitle,
        "title": title,
      };
}

///TagConfig
class TagConfig {
  dynamic activity;
  String avatar;
  String bkgImg;
  dynamic brandAd;
  String content;
  String digest;
  int id;
  String image;
  dynamic notice;
  List<String> posts;
  String relatedTags;
  String tag;

  TagConfig({
    required this.activity,
    required this.avatar,
    required this.bkgImg,
    required this.brandAd,
    required this.content,
    required this.digest,
    required this.id,
    required this.image,
    required this.notice,
    required this.posts,
    required this.relatedTags,
    required this.tag,
  });

  factory TagConfig.fromJson(Map<String, dynamic> json) => TagConfig(
        activity: json["activity"],
        avatar: json["avatar"] ?? "",
        bkgImg: json["bkgImg"] ?? "",
        brandAd: json["brandAd"],
        content: json["content"] ?? "",
        digest: json["digest"] ?? "",
        id: json["id"],
        image: json["image"] ?? "",
        notice: json["notice"] ?? "",
        posts: json["posts"] != null
            ? List<String>.from(json["posts"].map((x) => x))
            : [],
        relatedTags: json["relatedTags"] ?? "",
        tag: json["tag"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "activity": activity,
        "avatar": avatar,
        "bkgImg": bkgImg,
        "brandAd": brandAd,
        "content": content,
        "digest": digest,
        "id": id,
        "image": image,
        "notice": notice,
        "posts": List<dynamic>.from(posts.map((x) => x)),
        "relatedTags": relatedTags,
        "tag": tag,
      };
}

///TagRank
class TagRanksNew {
  String? name;
  int? type;
  String? url;

  TagRanksNew({
    this.name,
    this.type,
    this.url,
  });

  factory TagRanksNew.fromJson(Map<String, dynamic> json) => TagRanksNew(
        name: json["name"],
        type: json["type"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "type": type,
        "url": url,
      };
}

///TagTreeInfo
class TagTreeInfo {
  int categoryId;
  int categoryLevel;
  int parentCategoryId;
  dynamic tagAlias;

  TagTreeInfo({
    required this.categoryId,
    required this.categoryLevel,
    required this.parentCategoryId,
    required this.tagAlias,
  });

  factory TagTreeInfo.fromJson(Map<String, dynamic> json) => TagTreeInfo(
        categoryId: json["categoryId"],
        categoryLevel: json["categoryLevel"],
        parentCategoryId: json["parentCategoryId"],
        tagAlias: json["tagAlias"],
      );

  Map<String, dynamic> toJson() => {
        "categoryId": categoryId,
        "categoryLevel": categoryLevel,
        "parentCategoryId": parentCategoryId,
        "tagAlias": tagAlias,
      };
}

///SimpleCollectionInfo
class SimpleCollectionInfo {
  int blogId;
  int collectionType;
  String coverUrl;
  int id;
  int lastPublishTime;
  String name;
  int onlyVideo;
  int postCollectionHot;
  int postCount;
  String reason;
  int subscribedCount;
  List<String> tagList;
  int viewCount;

  SimpleCollectionInfo({
    required this.blogId,
    required this.collectionType,
    required this.coverUrl,
    required this.id,
    required this.lastPublishTime,
    required this.name,
    required this.onlyVideo,
    required this.postCollectionHot,
    required this.postCount,
    required this.reason,
    required this.subscribedCount,
    required this.tagList,
    required this.viewCount,
  });

  factory SimpleCollectionInfo.fromJson(Map<String, dynamic> json) =>
      SimpleCollectionInfo(
        blogId: json["blogId"],
        collectionType: json["collectionType"],
        coverUrl: json["coverUrl"],
        id: json["id"],
        lastPublishTime: json["lastPublishTime"],
        name: json["name"],
        onlyVideo: json["onlyVideo"],
        postCollectionHot: json["postCollectionHot"] ?? 0,
        postCount: json["postCount"],
        reason: json["reason"] ?? "",
        subscribedCount: json["subscribedCount"],
        tagList: List<String>.from(json["tagList"].map((x) => x)),
        viewCount: json["viewCount"],
      );

  Map<String, dynamic> toJson() => {
        "blogId": blogId,
        "collectionType": collectionType,
        "coverUrl": coverUrl,
        "id": id,
        "lastPublishTime": lastPublishTime,
        "name": name,
        "onlyVideo": onlyVideo,
        "postCollectionHot": postCollectionHot,
        "postCount": postCount,
        "reason": reason,
        "subscribedCount": subscribedCount,
        "tagList": List<dynamic>.from(tagList.map((x) => x)),
        "viewCount": viewCount,
      };
}

///SimpleGrainInfo
class SimpleGrainInfo {
  int addPostTime;
  String coverUrl;
  int createTime;
  String description;
  int endTime;
  int exposure;
  int greatLevel;
  int hotCount;
  int hotPlanType;
  int id;
  int joinCount;
  int lastSubscribeTime;
  String name;
  int planStatus;
  int postCount;
  int status;
  int subscribedCount;
  List<String> tags;
  int type;
  int updateTime;
  int userId;
  int viewCount;

  SimpleGrainInfo({
    required this.addPostTime,
    required this.coverUrl,
    required this.createTime,
    required this.description,
    required this.endTime,
    required this.exposure,
    required this.greatLevel,
    required this.hotCount,
    required this.hotPlanType,
    required this.id,
    required this.joinCount,
    required this.lastSubscribeTime,
    required this.name,
    required this.planStatus,
    required this.postCount,
    required this.status,
    required this.subscribedCount,
    required this.tags,
    required this.type,
    required this.updateTime,
    required this.userId,
    required this.viewCount,
  });

  factory SimpleGrainInfo.fromJson(Map<String, dynamic> json) =>
      SimpleGrainInfo(
        addPostTime: json["addPostTime"],
        coverUrl: json["coverUrl"],
        createTime: json["createTime"],
        description: json["description"] ?? "",
        endTime: json["endTime"],
        exposure: json["exposure"],
        greatLevel: json["greatLevel"],
        hotCount: json["hotCount"],
        hotPlanType: json["hotPlanType"],
        id: json["id"],
        joinCount: json["joinCount"],
        lastSubscribeTime: json["lastSubscribeTime"],
        name: json["name"],
        planStatus: json["planStatus"],
        postCount: json["postCount"],
        status: json["status"],
        subscribedCount: json["subscribedCount"],
        tags: List<String>.from(json["tags"].map((x) => x)),
        type: json["type"],
        updateTime: json["updateTime"],
        userId: json["userId"],
        viewCount: json["viewCount"],
      );

  Map<String, dynamic> toJson() => {
        "addPostTime": addPostTime,
        "coverUrl": coverUrl,
        "createTime": createTime,
        "description": description,
        "endTime": endTime,
        "exposure": exposure,
        "greatLevel": greatLevel,
        "hotCount": hotCount,
        "hotPlanType": hotPlanType,
        "id": id,
        "joinCount": joinCount,
        "lastSubscribeTime": lastSubscribeTime,
        "name": name,
        "planStatus": planStatus,
        "postCount": postCount,
        "status": status,
        "subscribedCount": subscribedCount,
        "tags": List<dynamic>.from(tags.map((x) => x)),
        "type": type,
        "updateTime": updateTime,
        "userId": userId,
        "viewCount": viewCount,
      };
}
