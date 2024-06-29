///AccountResponse
class AccountResponse {
  int acceptGiftFlag;
  int accountBindTip;
  String akAos;
  String akIos;
  bool anchorOpen;
  bool appImageProtection;
  bool appImageStamp;
  bool appIndexActActive;
  bool appVideoProtect;
  Map<String, dynamic> archiveSettings;
  String authApplyUrl;
  Map<String, dynamic> blogCovers;
  List<FullBlogData> blogs;
  bool checkVerifyBlog;
  List<FullBlogCount> counts;
  int curtime;
  List<DefaultAuditTime> defaultAuditTime;
  Map<String, dynamic> domains;
  String email;
  int giftAccountStatus;
  int giftAccountType;
  bool hasNewSelection;
  dynamic homeimageurl;
  int imgProtectedType;
  bool isTradePayAuthor;
  String liveUrl;
  int locationflag;
  String loftInToken;
  int loginType;
  String mainBlogId;
  List<String> manageTags;
  int msgCountUpdateTime;
  bool needShowAd;
  int newFollowingUAppCount;
  int newfriendcount;
  int noticeCountUpdateTime;
  String openShortFilm;
  String pushVersion;
  Randomrecoms randomrecoms;
  RecConf recConf;
  List<String> recommendSearchKeys;
  String scoreMallUrl;
  String shortFilmTagMap;
  bool showAuthApply;
  bool showGiftAct;
  int showGiftChangeStatus;
  int showGuide;
  bool showLoftIn;
  bool showLuckyBoy;
  bool showScoreMall;
  int showSkip;
  int siteType;
  int subscribeCollectionCount;
  bool subscribeRedShow;
  Map<String, dynamic> thirdpartyApps;
  Tipsetting tipsetting;
  int unReadEventsCount;
  bool usedToYouthMode;
  String userId;
  UserGrainConfigInfo userGrainConfigInfo;
  BlogStatistic userStatistic;
  List<String> watermarkActivities;
  bool webImageStamp;
  List<WhiteNoiseMusic> whiteNoiseMusicList;
  bool youthMode;

  AccountResponse({
    required this.acceptGiftFlag,
    required this.accountBindTip,
    required this.akAos,
    required this.akIos,
    required this.anchorOpen,
    required this.appImageProtection,
    required this.appImageStamp,
    required this.appIndexActActive,
    required this.appVideoProtect,
    required this.archiveSettings,
    required this.authApplyUrl,
    required this.blogCovers,
    required this.blogs,
    required this.checkVerifyBlog,
    required this.counts,
    required this.curtime,
    required this.defaultAuditTime,
    required this.domains,
    required this.email,
    required this.giftAccountStatus,
    required this.giftAccountType,
    required this.hasNewSelection,
    required this.homeimageurl,
    required this.imgProtectedType,
    required this.isTradePayAuthor,
    required this.liveUrl,
    required this.locationflag,
    required this.loftInToken,
    required this.loginType,
    required this.mainBlogId,
    required this.manageTags,
    required this.msgCountUpdateTime,
    required this.needShowAd,
    required this.newFollowingUAppCount,
    required this.newfriendcount,
    required this.noticeCountUpdateTime,
    required this.openShortFilm,
    required this.pushVersion,
    required this.randomrecoms,
    required this.recConf,
    required this.recommendSearchKeys,
    required this.scoreMallUrl,
    required this.shortFilmTagMap,
    required this.showAuthApply,
    required this.showGiftAct,
    required this.showGiftChangeStatus,
    required this.showGuide,
    required this.showLoftIn,
    required this.showLuckyBoy,
    required this.showScoreMall,
    required this.showSkip,
    required this.siteType,
    required this.subscribeCollectionCount,
    required this.subscribeRedShow,
    required this.thirdpartyApps,
    required this.tipsetting,
    required this.unReadEventsCount,
    required this.usedToYouthMode,
    required this.userId,
    required this.userGrainConfigInfo,
    required this.userStatistic,
    required this.watermarkActivities,
    required this.webImageStamp,
    required this.whiteNoiseMusicList,
    required this.youthMode,
  });

  factory AccountResponse.fromJson(Map<String, dynamic> json) {
    return AccountResponse(
        acceptGiftFlag: json['acceptGiftFlag'],
        accountBindTip: json['accountBindTip'],
        akAos: json['ak_aos'],
        akIos: json['ak_ios'],
        anchorOpen: json['anchorOpen'],
        appImageProtection: json['appImageProtection'],
        appImageStamp: json['appImageStamp'],
        appIndexActActive: json['appIndexActActive'],
        appVideoProtect: json['appVideoProtect'],
        archiveSettings: json['archiveSettings'],
        authApplyUrl: json['authApplyUrl'],
        blogCovers: json['blogCovers'],
        blogs: (json['blogs'] as List)
            .map((e) => FullBlogData.fromJson(e))
            .toList(),
        checkVerifyBlog: json['checkVerifyBlog'],
        counts: (json['counts'] as List)
            .map((e) => FullBlogCount.fromJson(e))
            .toList(),
        curtime: json['curtime'],
        defaultAuditTime: (json['defaultAuditTime'] as List)
            .map((e) => DefaultAuditTime.fromJson(e))
            .toList(),
        domains: json['domains'],
        email: json['email'],
        giftAccountStatus: json['giftAccountStatus'],
        giftAccountType: json['giftAccountType'],
        hasNewSelection: json['hasNewSelection'],
        homeimageurl: json['homeimageurl'],
        imgProtectedType: json['imgProtectedType'],
        isTradePayAuthor: json['isTradePayAuthor'],
        liveUrl: json['liveUrl'],
        locationflag: json['locationflag'],
        loftInToken: json['loftInToken'],
        loginType: json['loginType'],
        mainBlogId: json['main_blog_id'],
        manageTags:
            (json['manageTags'] as List).map((e) => e.toString()).toList(),
        msgCountUpdateTime: json['msgCountUpdateTime'],
        needShowAd: json['needShowAd'],
        newFollowingUAppCount: json['newFollowingUAppCount'],
        newfriendcount: json['newfriendcount'],
        noticeCountUpdateTime: json['noticeCountUpdateTime'],
        openShortFilm: json['openShortFilm'],
        pushVersion: json['pushVersion'],
        randomrecoms: Randomrecoms.fromJson(json['randomrecoms']),
        recConf: RecConf.fromJson(json['recConf']),
        recommendSearchKeys: (json['recommendSearchKeys'] as List)
            .map((e) => e.toString())
            .toList(),
        scoreMallUrl: json['scoreMallUrl'],
        shortFilmTagMap: json['shortFilmTagMap'],
        showAuthApply: json['showAuthApply'],
        showGiftAct: json['showGiftAct'],
        showGiftChangeStatus: json['showGiftChangeStatus'],
        showGuide: json['showGuide'],
        showLoftIn: json['showLoftIn'],
        showLuckyBoy: json['showLuckyBoy'],
        showScoreMall: json['showScoreMall'],
        showSkip: json['showSkip'],
        siteType: json['siteType'],
        subscribeCollectionCount: json['subscribeCollectionCount'],
        subscribeRedShow: json['subscribeRedShow'],
        thirdpartyApps: json['thirdpartyApps'],
        tipsetting: Tipsetting.fromJson(json['tipsetting']),
        unReadEventsCount: json['unReadEventsCount'],
        usedToYouthMode: json['usedToYouthMode'],
        userId: json['user_id'],
        userGrainConfigInfo:
            UserGrainConfigInfo.fromJson(json['userGrainConfigInfo']),
        userStatistic: BlogStatistic.fromJson(json['userStatistic']),
        watermarkActivities: (json['watermarkActivities'] as List)
            .map((e) => e.toString())
            .toList(),
        webImageStamp: json['webImageStamp'],
        whiteNoiseMusicList: (json['whiteNoiseMusicList'] as List)
            .map((e) => WhiteNoiseMusic.fromJson(e))
            .toList(),
        youthMode: json['youthMode']);
  }

  Map<String, dynamic> toJson() => {
        'acceptGiftFlag': acceptGiftFlag,
        'accountBindTip': accountBindTip,
        'akAos': akAos,
        'akIos': akIos,
        'anchorOpen': anchorOpen,
        'appImageProtection': appImageProtection,
        'appImageStamp': appImageStamp,
        'appIndexActActive': appIndexActActive,
        'appVideoProtect': appVideoProtect,
        'archiveSettings': archiveSettings,
        'authApplyUrl': authApplyUrl,
        'blogCovers': blogCovers,
        'blogs': blogs.map((e) => e.toJson()).toList(),
        'checkVerifyBlog': checkVerifyBlog,
        'counts': counts.map((e) => e.toJson()).toList(),
        'curtime': curtime,
        'defaultAuditTime': defaultAuditTime.map((e) => e.toJson()).toList(),
        'domains': domains,
        'email': email,
        'giftAccountStatus': giftAccountStatus,
        'giftAccountType': giftAccountType,
        'hasNewSelection': hasNewSelection,
        'homeimageurl': homeimageurl,
        'imgProtectedType': imgProtectedType,
        'isTradePayAuthor': isTradePayAuthor,
        'liveUrl': liveUrl,
        'locationflag': locationflag,
        'loftInToken': loftInToken,
        'loginType': loginType,
        'mainBlogId': mainBlogId,
        'manageTags': manageTags,
        'msgCountUpdateTime': msgCountUpdateTime,
        'needShowAd': needShowAd,
        'newFollowingUAppCount': newFollowingUAppCount,
        'newfriendcount': newfriendcount,
        'noticeCountUpdateTime': noticeCountUpdateTime,
        'openShortFilm': openShortFilm,
        'pushVersion': pushVersion,
        'randomrecoms': randomrecoms.toJson(),
        'recConf': recConf.toJson(),
        'recommendSearchKeys': recommendSearchKeys,
        'scoreMallUrl': scoreMallUrl,
        'shortFilmTagMap': shortFilmTagMap,
        'showAuthApply': showAuthApply,
        'showGiftAct': showGiftAct,
        'showGiftChangeStatus': showGiftChangeStatus,
        'showGuide': showGuide,
        'showLoftIn': showLoftIn,
        'showLuckyBoy': showLuckyBoy,
        'showScoreMall': showScoreMall,
        'showSkip': showSkip,
        'siteType': siteType,
        'subscribeCollectionCount': subscribeCollectionCount,
        'subscribeRedShow': subscribeRedShow,
        'thirdpartyApps': thirdpartyApps,
        'tipsetting': tipsetting.toJson(),
        'unReadEventsCount': unReadEventsCount,
        'usedToYouthMode': usedToYouthMode,
        'userId': userId,
        'userGrainConfigInfo': userGrainConfigInfo.toJson(),
        'userStatistic': userStatistic.toJson(),
        'watermarkActivities': watermarkActivities,
        'webImageStamp': webImageStamp,
        'whiteNoiseMusicList':
            whiteNoiseMusicList.map((e) => e.toJson()).toList(),
        'youthMode': youthMode,
      };
}

///FullBlogData
class FullBlogData {
  int? blogId;
  FullBlogInfo? blogInfo;
  int? id;
  int? joinTime;
  int? newActivityTagNoticeCount;
  int? newArtNoticeCount;
  int? newFollowingUAppCount;
  int? newFriendCount;
  int? newMessageCount;
  int? newNoticeCount;
  int? newPropEmoteCommentCount;
  int? newRecommendNoticeCount;
  int? newResponseNoticeCount;
  int? noticeCountUpdateTime;
  int? role;
  int? userId;

  FullBlogData({
    this.blogId,
    this.blogInfo,
    this.id,
    this.joinTime,
    this.newActivityTagNoticeCount,
    this.newArtNoticeCount,
    this.newFollowingUAppCount,
    this.newFriendCount,
    this.newMessageCount,
    this.newNoticeCount,
    this.newPropEmoteCommentCount,
    this.newRecommendNoticeCount,
    this.newResponseNoticeCount,
    this.noticeCountUpdateTime,
    this.role,
    this.userId,
  });

  factory FullBlogData.fromJson(Map<String, dynamic> json) {
    return FullBlogData(
        blogId: json['blogId'],
        blogInfo: FullBlogInfo.fromJson(json['blogInfo']),
        id: json['id'],
        joinTime: json['joinTime'],
        newActivityTagNoticeCount: json['newActivityTagNoticeCount'],
        newArtNoticeCount: json['newArtNoticeCount'],
        newFollowingUAppCount: json['newFollowingUAppCount'],
        newFriendCount: json['newFriendCount'],
        newMessageCount: json['newMessageCount'],
        newNoticeCount: json['newNoticeCount'],
        newPropEmoteCommentCount: json['newPropEmoteCommentCount'],
        newRecommendNoticeCount: json['newRecommendNoticeCount'],
        newResponseNoticeCount: json['newResponseNoticeCount'],
        noticeCountUpdateTime: json['noticeCountUpdateTime'],
        role: json['role'],
        userId: json['userId']);
  }

  Map<String, dynamic> toJson() => {
        'blogId': blogId,
        'blogInfo': blogInfo?.toJson(),
        'id': id,
        'joinTime': joinTime,
        'newActivityTagNoticeCount': newActivityTagNoticeCount,
        'newArtNoticeCount': newArtNoticeCount,
        'newFollowingUAppCount': newFollowingUAppCount,
        'newFriendCount': newFriendCount,
        'newMessageCount': newMessageCount,
        'newNoticeCount': newNoticeCount,
        'newPropEmoteCommentCount': newPropEmoteCommentCount,
        'newRecommendNoticeCount': newRecommendNoticeCount,
        'newResponseNoticeCount': newResponseNoticeCount,
        'noticeCountUpdateTime': noticeCountUpdateTime,
        'role': role,
        'userId': userId
      };
}

///FullBlogInfo
class FullBlogInfo {
  int? acceptGift;
  int? acceptReward;
  int? allowGift;
  int? allowReward;
  List<String> auths;
  int avatarBoxId;
  String avatarBoxImage;
  String avatarBoxName;
  int avaUpdateTime;
  String bigAvaImg;
  int birthday;
  int blogCreateTime;
  int blogId;
  String blogName;
  String blogNickName;
  int commentRank;
  int extraBits;
  int gendar;
  String homePageUrl;
  bool imageDigitStamp;
  bool imageProtected;
  bool imageStamp;
  bool isOriginalAuthor;
  String keyTag;
  bool novisible;
  int postAddTime;
  int postModTime;
  int rssFileId;
  int rssGenTime;
  String selfIntro;
  bool signAuth;

  FullBlogInfo({
    this.acceptGift,
    this.acceptReward,
    this.allowGift,
    this.allowReward,
    required this.auths,
    required this.avatarBoxId,
    required this.avatarBoxImage,
    required this.avatarBoxName,
    required this.avaUpdateTime,
    required this.bigAvaImg,
    required this.birthday,
    required this.blogCreateTime,
    required this.blogId,
    required this.blogName,
    required this.blogNickName,
    required this.commentRank,
    required this.extraBits,
    required this.gendar,
    required this.homePageUrl,
    required this.imageDigitStamp,
    required this.imageProtected,
    required this.imageStamp,
    required this.isOriginalAuthor,
    required this.keyTag,
    required this.novisible,
    required this.postAddTime,
    required this.postModTime,
    required this.rssFileId,
    required this.rssGenTime,
    required this.selfIntro,
    required this.signAuth,
  });

  factory FullBlogInfo.fromJson(Map<String, dynamic> json) {
    return FullBlogInfo(
      acceptGift: json['acceptGift'],
      acceptReward: json['acceptReward'],
      allowGift: json['allowGift'],
      allowReward: json['allowReward'],
      auths: json['auths'] != null
          ? (json['auths'] as List).map((e) => e.toString()).toList()
          : [],
      avatarBoxId: json['avatarBoxId'] ?? 0,
      avatarBoxImage: json['avatarBoxImage'] ?? "",
      avatarBoxName: json['avatarBoxName'] ?? "",
      avaUpdateTime: json['avaUpdateTime'] ?? 0,
      bigAvaImg: json['bigAvaImg'],
      birthday: json['birthday'] ?? 0,
      blogCreateTime: json['blogCreateTime'] ?? 0,
      blogId: json['blogId'],
      blogName: json['blogName'] ?? "",
      blogNickName: json['blogNickName'] ?? "",
      commentRank: json['commentRank'] ?? 0,
      extraBits: json['extraBits'] ?? 0,
      gendar: json['gendar'] ?? 0,
      homePageUrl: json['homePageUrl'],
      imageDigitStamp: json['imageDigitStamp'],
      imageProtected: json['imageProtected'],
      imageStamp: json['imageStamp'],
      isOriginalAuthor: json['isOriginalAuthor'],
      keyTag: json['keyTag'] ?? "",
      novisible: json['novisible'] ?? false,
      postAddTime: json['postAddTime'] ?? 0,
      postModTime: json['postModTime'] ?? 0,
      rssFileId: json['rssFileId'] ?? 0,
      rssGenTime: json['rssGenTime'] ?? 0,
      selfIntro: json['selfIntro'] ?? "",
      signAuth: json['signAuth'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'acceptGift': acceptGift,
        'acceptReward': acceptReward,
        'allowGift': allowGift,
        'allowReward': allowReward,
        'auths': auths,
        'avatarBoxId': avatarBoxId,
        'avatarBoxImage': avatarBoxImage,
        'avatarBoxName': avatarBoxName,
        'avaUpdateTime': avaUpdateTime,
        'bigAvaImg': bigAvaImg,
        'birthday': birthday,
        'blogCreateTime': blogCreateTime,
        'blogId': blogId,
        'blogName': blogName,
        'blogNickName': blogNickName,
        'commentRank': commentRank,
        'extraBits': extraBits,
        'gendar': gendar,
        'homePageUrl': homePageUrl,
        'imageDigitStamp': imageDigitStamp,
        'imageProtected': imageProtected,
        'imageStamp': imageStamp,
        'isOriginalAuthor': isOriginalAuthor,
        'keyTag': keyTag,
        'novisible': novisible,
        'postAddTime': postAddTime,
        'postModTime': postModTime,
        'rssFileId': rssFileId,
        'rssGenTime': rssGenTime,
        'selfIntro': selfIntro,
        'signAuth': signAuth
      };
}

///FullBlogCount
class FullBlogCount {
  int? activityTagNoticeCount;
  int? askCount;
  int? blogId;
  int? creatorNoticeCount;
  int? draftPostCount;
  int? followerCount;
  int? followingCount;
  int? memberCount;
  int? messageUserCount;
  int? newActivityTagNoticeCount;
  int? newFollowerCount;
  int? newLikeCount;
  int? newPropEmoteCommentCount;
  int? newQuestionCount;
  int? newRecommendNoticeCount;
  int? newResponseNoticeCount;
  int? noticeCount;
  int? postCount;
  int? recommendNoticeCount;
  int? responseNoticeCount;
  int? systemNoticeCount;
  int? undoContributeCount;
  int? unReadAskCount;
  int? unReadContributeCount;
  int? unReadGroupMsgCount;
  int? unReadMsgCount;
  int? unReadNoticeCount;

  FullBlogCount({
    this.activityTagNoticeCount,
    this.askCount,
    this.blogId,
    this.creatorNoticeCount,
    this.draftPostCount,
    this.followerCount,
    this.followingCount,
    this.memberCount,
    this.messageUserCount,
    this.newActivityTagNoticeCount,
    this.newFollowerCount,
    this.newLikeCount,
    this.newPropEmoteCommentCount,
    this.newQuestionCount,
    this.newRecommendNoticeCount,
    this.newResponseNoticeCount,
    this.noticeCount,
    this.postCount,
    this.recommendNoticeCount,
    this.responseNoticeCount,
    this.systemNoticeCount,
    this.undoContributeCount,
    this.unReadAskCount,
    this.unReadContributeCount,
    this.unReadGroupMsgCount,
    this.unReadMsgCount,
    this.unReadNoticeCount,
  });

  factory FullBlogCount.fromJson(Map<String, dynamic> json) {
    return FullBlogCount(
        activityTagNoticeCount: json['activityTagNoticeCount'],
        askCount: json['askCount'],
        blogId: json['blogId'],
        creatorNoticeCount: json['creatorNoticeCount'],
        draftPostCount: json['draftPostCount'],
        followerCount: json['followerCount'],
        followingCount: json['followingCount'],
        memberCount: json['memberCount'],
        messageUserCount: json['messageUserCount'],
        newActivityTagNoticeCount: json['newActivityTagNoticeCount'],
        newFollowerCount: json['newFollowerCount'],
        newLikeCount: json['newLikeCount'],
        newPropEmoteCommentCount: json['newPropEmoteCommentCount'],
        newQuestionCount: json['newQuestionCount'],
        newRecommendNoticeCount: json['newRecommendNoticeCount'],
        newResponseNoticeCount: json['newResponseNoticeCount'],
        noticeCount: json['noticeCount'],
        postCount: json['postCount'],
        recommendNoticeCount: json['recommendNoticeCount'],
        responseNoticeCount: json['responseNoticeCount'],
        systemNoticeCount: json['systemNoticeCount'],
        undoContributeCount: json['undoContributeCount'],
        unReadAskCount: json['unReadAskCount'],
        unReadContributeCount: json['unReadContributeCount'],
        unReadGroupMsgCount: json['unReadGroupMsgCount'],
        unReadMsgCount: json['unReadMsgCount'],
        unReadNoticeCount: json['unReadNoticeCount']);
  }

  Map<String, dynamic> toJson() => {
        'activityTagNoticeCount': activityTagNoticeCount,
        'askCount': askCount,
        'blogId': blogId,
        'creatorNoticeCount': creatorNoticeCount,
        'draftPostCount': draftPostCount,
        'followerCount': followerCount,
        'followingCount': followingCount,
        'memberCount': memberCount,
        'messageUserCount': messageUserCount,
        'newActivityTagNoticeCount': newActivityTagNoticeCount,
        'newFollowerCount': newFollowerCount,
        'newLikeCount': newLikeCount,
        'newPropEmoteCommentCount': newPropEmoteCommentCount,
        'newQuestionCount': newQuestionCount,
        'newRecommendNoticeCount': newRecommendNoticeCount,
        'newResponseNoticeCount': newResponseNoticeCount,
        'noticeCount': noticeCount,
        'postCount': postCount,
        'recommendNoticeCount': recommendNoticeCount,
        'responseNoticeCount': responseNoticeCount,
        'systemNoticeCount': systemNoticeCount,
        'undoContributeCount': undoContributeCount,
        'unReadAskCount': unReadAskCount,
        'unReadContributeCount': unReadContributeCount,
        'unReadGroupMsgCount': unReadGroupMsgCount,
        'unReadMsgCount': unReadMsgCount,
        'unReadNoticeCount': unReadNoticeCount
      };
}

class DefaultAuditTime {
  int auditTime;
  int endTime;
  int startTime;

  DefaultAuditTime({
    required this.auditTime,
    required this.endTime,
    required this.startTime,
  });

  factory DefaultAuditTime.fromJson(Map<String, dynamic> json) {
    return DefaultAuditTime(
        auditTime: json['auditTime'] as int,
        endTime: json['endTime'] as int,
        startTime: json['startTime'] as int);
  }

  Map<String, dynamic> toJson() =>
      {'auditTime': auditTime, 'endTime': endTime, 'startTime': startTime};
}

class Randomrecoms {
  List<String> blogs;
  List<String> tags;

  Randomrecoms({
    required this.blogs,
    required this.tags,
  });

  factory Randomrecoms.fromJson(Map<String, dynamic> json) {
    return Randomrecoms(
        blogs: (json['blogs'] as List).map((e) => e.toString()).toList(),
        tags: (json['tags'] as List).map((e) => e.toString()).toList());
  }

  Map<String, dynamic> toJson() => {'blogs': blogs, 'tags': tags};
}

class RecConf {
  List<JoinSwitch> joinSwitchs;

  RecConf({
    required this.joinSwitchs,
  });

  factory RecConf.fromJson(Map<String, dynamic> json) {
    return RecConf(
        joinSwitchs: (json['joinSwitchs'] as List)
            .map((e) => JoinSwitch.fromJson(e))
            .toList());
  }

  Map<String, dynamic> toJson() => {'joinSwitchs': joinSwitchs};
}

class JoinSwitch {
  String? scene;
  int? status;
  int? viewTime;

  JoinSwitch({
    this.scene,
    this.status,
    this.viewTime,
  });

  factory JoinSwitch.fromJson(Map<String, dynamic> json) {
    return JoinSwitch(
        scene: json['scene'],
        status: json['status'],
        viewTime: json['viewTime']);
  }

  Map<String, dynamic> toJson() =>
      {'scene': scene, 'status': status, 'viewTime': viewTime};
}

///TipSetting
class Tipsetting {
  int benefitOrder;
  int dailyTipCount;
  String followerCount;
  String followMsg;
  String messageCount;
  String noticeMsg;
  String orderMsg;
  String responseCount;
  int specialFollow;
  int yinOrder;

  Tipsetting({
    required this.benefitOrder,
    required this.dailyTipCount,
    required this.followerCount,
    required this.followMsg,
    required this.messageCount,
    required this.noticeMsg,
    required this.orderMsg,
    required this.responseCount,
    required this.specialFollow,
    required this.yinOrder,
  });

  factory Tipsetting.fromJson(Map<String, dynamic> json) {
    return Tipsetting(
        benefitOrder: json['benefitOrder'] as int,
        dailyTipCount: json['dailyTipCount'] as int,
        followerCount: json['followerCount'],
        followMsg: json['followMsg'],
        messageCount: json['messageCount'],
        noticeMsg: json['noticeMsg'],
        orderMsg: json['orderMsg'],
        responseCount: json['responseCount'],
        specialFollow: json['specialFollow'],
        yinOrder: json['yinOrder']);
  }

  Map<String, dynamic> toJson() => {
        'benefitOrder': benefitOrder,
        'dailyTipCount': dailyTipCount,
        'followerCount': followerCount,
        'followMsg': followMsg,
        'messageCount': messageCount,
        'noticeMsg': noticeMsg,
        'orderMsg': orderMsg,
        'responseCount': responseCount,
        'specialFollow': specialFollow,
        'yinOrder': yinOrder
      };
}

class UserGrainConfigInfo {
  int grainAddLimit;
  int grainPostLimit;

  UserGrainConfigInfo({
    required this.grainAddLimit,
    required this.grainPostLimit,
  });

  factory UserGrainConfigInfo.fromJson(Map<String, dynamic> json) {
    return UserGrainConfigInfo(
        grainAddLimit: json['grainAddLimit'] as int,
        grainPostLimit: json['grainPostLimit'] as int);
  }

  Map<String, dynamic> toJson() =>
      {'grainAddLimit': grainAddLimit, 'grainPostLimit': grainPostLimit};
}

///BlogStatistic
class BlogStatistic {
  int appLoginCount;
  int avatarBoxId;
  String avatarBoxImage;
  int blacklistCount;
  int blogCount;
  int bulletinLoadTime;
  int favoritePostCount;
  int favoriteTagCount;
  int followingCount;
  int inviteCodeCount;
  String lastLoginIp;
  int lastLoginTime;
  int loginCount;
  int postResponseCount;
  int publishPostCount;
  int questionBoxFetchTime;
  int recommendCount;
  int robotLikeTime;
  int sharePostCount;
  int subscribeCollectionViewTime;
  int subscribePostCount;
  int uploadDiyMusicSize;
  int userId;
  int userRemotePort;

  BlogStatistic({
    required this.appLoginCount,
    required this.avatarBoxId,
    required this.avatarBoxImage,
    required this.blacklistCount,
    required this.blogCount,
    required this.bulletinLoadTime,
    required this.favoritePostCount,
    required this.favoriteTagCount,
    required this.followingCount,
    required this.inviteCodeCount,
    required this.lastLoginIp,
    required this.lastLoginTime,
    required this.loginCount,
    required this.postResponseCount,
    required this.publishPostCount,
    required this.questionBoxFetchTime,
    required this.recommendCount,
    required this.robotLikeTime,
    required this.sharePostCount,
    required this.subscribeCollectionViewTime,
    required this.subscribePostCount,
    required this.uploadDiyMusicSize,
    required this.userId,
    required this.userRemotePort,
  });

  factory BlogStatistic.fromJson(Map<String, dynamic> json) {
    return BlogStatistic(
        appLoginCount: json['appLoginCount'] as int,
        avatarBoxId: json['avatarBoxId'],
        avatarBoxImage: json['avatarBoxImage'],
        blacklistCount: json['blacklistCount'],
        blogCount: json['blogCount'],
        bulletinLoadTime: json['bulletinLoadTime'],
        favoritePostCount: json['favoritePostCount'],
        favoriteTagCount: json['favoriteTagCount'],
        followingCount: json['followingCount'],
        inviteCodeCount: json['inviteCodeCount'],
        lastLoginIp: json['lastLoginIp'],
        lastLoginTime: json['lastLoginTime'],
        loginCount: json['loginCount'],
        postResponseCount: json['postResponseCount'],
        publishPostCount: json['publishPostCount'],
        questionBoxFetchTime: json['questionBoxFetchTime'],
        recommendCount: json['recommendCount'],
        robotLikeTime: json['robotLikeTime'],
        sharePostCount: json['sharePostCount'],
        subscribeCollectionViewTime: json['subscribeCollectionViewTime'],
        subscribePostCount: json['subscribePostCount'],
        uploadDiyMusicSize: json['uploadDiyMusicSize'],
        userId: json['userId'],
        userRemotePort: json['userRemotePort']);
  }

  Map<String, dynamic> toJson() => {
        'appLoginCount': appLoginCount,
        'avatarBoxId': avatarBoxId,
        'avatarBoxImage': avatarBoxImage,
        'blacklistCount': blacklistCount,
        'blogCount': blogCount,
        'bulletinLoadTime': bulletinLoadTime,
        'favoritePostCount': favoritePostCount,
        'favoriteTagCount': favoriteTagCount,
        'followingCount': followingCount,
        'inviteCodeCount': inviteCodeCount,
        'lastLoginIp': lastLoginIp,
        'lastLoginTime': lastLoginTime,
        'loginCount': loginCount,
        'postResponseCount': postResponseCount,
        'publishPostCount': publishPostCount,
        'questionBoxFetchTime': questionBoxFetchTime,
        'recommendCount': recommendCount,
        'robotLikeTime': robotLikeTime,
        'sharePostCount': sharePostCount,
        'subscribeCollectionViewTime': subscribeCollectionViewTime,
        'subscribePostCount': subscribePostCount,
        'uploadDiyMusicSize': uploadDiyMusicSize,
        'userId': userId,
        'userRemotePort': userRemotePort
      };
}

///WhiteNoiseMusic
class WhiteNoiseMusic {
  int id;
  String img;
  List<String> intros;
  String title;
  String url;

  WhiteNoiseMusic({
    required this.id,
    required this.img,
    required this.intros,
    required this.title,
    required this.url,
  });

  factory WhiteNoiseMusic.fromJson(Map<String, dynamic> json) {
    return WhiteNoiseMusic(
        id: json['id'] as int,
        img: json['img'],
        intros: Transformer<String>().transform(json['intros']),
        title: json['title'],
        url: json['url']);
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'img': img, 'intros': intros, 'title': title, 'url': url};
}

class Transformer<T> {
  List<T> transform(List<dynamic> list) {
    List<T> res = [];
    for (var item in list) {
      res.add(item as T);
    }
    return res;
  }
}

///MeInfoData
class MeInfoData {
  bool askOpen;
  MeInfoBlogInfo blogInfo;
  int collectionCount;
  int enableReward;
  String feedback;
  String feedbackUrl;
  String gameImage;
  int gameOpen;
  String gameTxt;
  String gameUrl;
  int kefuOpen;
  String signAuthUrl;
  String signProtocol;
  String yinDefaultContent;
  dynamic yinInfo;

  MeInfoData({
    required this.askOpen,
    required this.blogInfo,
    required this.collectionCount,
    required this.enableReward,
    required this.feedback,
    required this.feedbackUrl,
    required this.gameImage,
    required this.gameOpen,
    required this.gameTxt,
    required this.gameUrl,
    required this.kefuOpen,
    required this.signAuthUrl,
    required this.signProtocol,
    required this.yinDefaultContent,
    required this.yinInfo,
  });

  factory MeInfoData.fromJson(Map<String, dynamic> json) {
    return MeInfoData(
        askOpen: json['askOpen'],
        blogInfo: MeInfoBlogInfo.fromJson(json['blogInfo']),
        collectionCount: json['collectionCount'],
        enableReward: json['enableReward'],
        feedback: json['feedback'],
        feedbackUrl: json['feedbackUrl'],
        gameImage: json['gameImage'],
        gameOpen: json['gameOpen'],
        gameTxt: json['gameTxt'],
        gameUrl: json['gameUrl'],
        kefuOpen: json['kefuOpen'],
        signAuthUrl: json['signAuthUrl'],
        signProtocol: json['signProtocol'],
        yinDefaultContent: json['yinDefaultContent'],
        yinInfo: json['yinInfo']);
  }

  Map<String, dynamic> toJson() => {
        'askOpen': askOpen,
        'blogInfo': blogInfo.toJson(),
        'collectionCount': collectionCount,
        'enableReward': enableReward,
        'feedback': feedback,
        'feedbackUrl': feedbackUrl,
        'gameImage': gameImage,
        'gameOpen': gameOpen,
        'gameTxt': gameTxt,
        'gameUrl': gameUrl,
        'kefuOpen': kefuOpen,
        'signAuthUrl': signAuthUrl,
        'signProtocol': signProtocol,
        'yinDefaultContent': yinDefaultContent,
        'yinInfo': yinInfo
      };
}

///MeInfoBlogInfo
class MeInfoBlogInfo {
  int attentionCount;
  String avatarBoxImage;
  int followerCount;
  MeInfoCount hot;
  MeInfoCount hotDelta;
  int likeCount;
  int newSubscribeCount;
  int postCount;
  int questionCount;
  int shareCount;
  bool signAuth;
  int subscribeCollectionCount;
  int subscribeCount;
  bool subscribeRedShow;

  MeInfoBlogInfo({
    required this.attentionCount,
    required this.avatarBoxImage,
    required this.followerCount,
    required this.hot,
    required this.hotDelta,
    required this.likeCount,
    required this.newSubscribeCount,
    required this.postCount,
    required this.questionCount,
    required this.shareCount,
    required this.signAuth,
    required this.subscribeCollectionCount,
    required this.subscribeCount,
    required this.subscribeRedShow,
  });

//生成fromjson和tojson函数
  factory MeInfoBlogInfo.fromJson(Map<String, dynamic> json) {
    return MeInfoBlogInfo(
        attentionCount: json['attentionCount'],
        avatarBoxImage: json['avatarBoxImage'],
        followerCount: json['followerCount'],
        hot: MeInfoCount.fromJson(json['hot']),
        hotDelta: MeInfoCount.fromJson(json['hotDelta']),
        likeCount: json['likeCount'],
        newSubscribeCount: json['newSubscribeCount'],
        postCount: json['postCount'],
        questionCount: json['questionCount'],
        shareCount: json['shareCount'],
        signAuth: json['signAuth'],
        subscribeCollectionCount: json['subscribeCollectionCount'],
        subscribeCount: json['subscribeCount'],
        subscribeRedShow: json['subscribeRedShow']);
  }

  Map<String, dynamic> toJson() => {
        'attentionCount': attentionCount,
        'avatarBoxImage': avatarBoxImage,
        'followerCount': followerCount,
        'hot': hot.toJson(),
        'hotDelta': hotDelta.toJson(),
        'likeCount': likeCount,
        'newSubscribeCount': newSubscribeCount,
        'postCount': postCount,
        'questionCount': questionCount,
        'shareCount': shareCount,
        'signAuth': signAuth,
        'subscribeCollectionCount': subscribeCollectionCount,
        'subscribeCount': subscribeCount,
        'subscribeRedShow': subscribeRedShow
      };
}

///MeInfoCount
class MeInfoCount {
  int endDay;
  int favoriteCount;
  int hotCount;
  int reblogCount;
  int shareCount;
  int subscribeCount;
  int tagChatFavoriteCount;

  MeInfoCount({
    required this.endDay,
    required this.favoriteCount,
    required this.hotCount,
    required this.reblogCount,
    required this.shareCount,
    required this.subscribeCount,
    required this.tagChatFavoriteCount,
  });

  factory MeInfoCount.fromJson(Map<String, dynamic> json) {
    return MeInfoCount(
        endDay: json['endDay'],
        favoriteCount: json['favoriteCount'],
        hotCount: json['hotCount'],
        reblogCount: json['reblogCount'],
        shareCount: json['shareCount'],
        subscribeCount: json['subscribeCount'],
        tagChatFavoriteCount: json['tagChatFavoriteCount']);
  }

  Map<String, dynamic> toJson() => {
        'endDay': endDay,
        'favoriteCount': favoriteCount,
        'hotCount': hotCount,
        'reblogCount': reblogCount,
        'shareCount': shareCount,
        'subscribeCount': subscribeCount,
        'tagChatFavoriteCount': tagChatFavoriteCount
      };
}
