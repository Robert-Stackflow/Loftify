import 'package:loftify/Models/recommend_response.dart';

import '../Utils/utils.dart';
import 'account_response.dart';

///FullBlogData
class TotalBlogData {
  int answerCount;
  int askBoxShow;
  bool askOpen;
  Blogcover blogcover;
  BlogInfoWithHot blogInfo;
  String blogLink;
  Blogsetting blogsetting;
  dynamic chatClickUrl;
  int collectionCount;
  int enableClipboard;
  List<String> exclSubBlogs;
  bool follower;
  bool following;
  int hideCommentLike;
  bool isBlackBlog;
  bool isBlackedUser;
  bool isPasswordAccessOn;
  bool isSelfBlog;
  int isShieldRecom;
  bool mainblog;
  int recordHistory;
  bool shieldUserTimeline;
  int showFans;
  int showFollow;
  int showFoods;
  int showHot;
  int showLike;
  int showMember;
  int showPersonal;
  int showShare;
  int showSubBlog;
  int showSupport;
  bool specialfollowing;

  TotalBlogData({
    required this.answerCount,
    required this.askBoxShow,
    required this.askOpen,
    required this.blogcover,
    required this.blogInfo,
    required this.blogLink,
    required this.blogsetting,
    required this.chatClickUrl,
    required this.collectionCount,
    required this.enableClipboard,
    required this.exclSubBlogs,
    required this.follower,
    required this.following,
    required this.hideCommentLike,
    required this.isBlackBlog,
    required this.isBlackedUser,
    required this.isPasswordAccessOn,
    required this.isSelfBlog,
    required this.isShieldRecom,
    required this.mainblog,
    required this.recordHistory,
    required this.shieldUserTimeline,
    required this.showFans,
    required this.showFollow,
    required this.showFoods,
    required this.showHot,
    required this.showLike,
    required this.showMember,
    required this.showPersonal,
    required this.showShare,
    required this.showSubBlog,
    required this.showSupport,
    required this.specialfollowing,
  });

//fromjsontojson
  factory TotalBlogData.fromJson(Map<String, dynamic> json) {
    return TotalBlogData(
      answerCount: json['answerCount'],
      askBoxShow: json['askBoxShow'],
      askOpen: json['askOpen'],
      blogcover: Blogcover.fromJson(json['blogcover']),
      blogInfo: BlogInfoWithHot.fromJson(json['blogInfo']),
      blogLink: json['blogLink'],
      blogsetting: Blogsetting.fromJson(json['blogsetting']),
      chatClickUrl: json['chatClickUrl'],
      collectionCount: json['collectionCount'] ?? 0,
      enableClipboard: json['enableClipboard'] ?? 0,
      exclSubBlogs:
          (json['exclSubBlogs'] as List).map((e) => e.toString()).toList(),
      follower: json['follower'],
      following: json['following'],
      hideCommentLike: json['hideCommentLike'],
      isBlackBlog: json['isBlackBlog'],
      isBlackedUser: json['isBlackedUser'],
      isPasswordAccessOn: json['isPasswordAccessOn'],
      isSelfBlog: json['isSelfBlog'],
      isShieldRecom: json['isShieldRecom'],
      mainblog: json['mainblog'],
      recordHistory: json['recordHistory'],
      shieldUserTimeline: json['shieldUserTimeline'],
      showFans: json['showFans'],
      showFollow: json['showFollow'],
      showFoods: json['showFoods'],
      showHot: json['showHot'],
      showLike: json['showLike'],
      showMember: json['showMember'],
      showPersonal: json['showPersonal'],
      showShare: json['showShare'],
      showSubBlog: json['showSubBlog'],
      showSupport: json['showSupport'],
      specialfollowing: json['specialfollowing'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['answerCount'] = answerCount;
    data['askBoxShow'] = askBoxShow;
    data['askOpen'] = askOpen;
    data['blogcover'] = blogcover.toJson();
    data['blogInfo'] = blogInfo.toJson();
    data['blogLink'] = blogLink;
    data['blogsetting'] = blogsetting.toJson();
    data['chatClickUrl'] = chatClickUrl;
    data['collectionCount'] = collectionCount;
    data['enableClipboard'] = enableClipboard;
    data['exclSubBlogs'] = exclSubBlogs;
    return data;
  }
}

///BlogInfoWithHot
class BlogInfoWithHot {
  int acceptGift;
  int acceptReward;
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
  BlogStat blogStat;
  int commentRank;
  int extraBits;
  int gendar;
  String homePageUrl;
  BlogHot hot;
  bool imageDigitStamp;
  bool imageProtected;
  bool imageStamp;
  String ipLocation;
  bool isOriginalAuthor;
  String keyTag;
  bool novisible;
  int postAddTime;
  int postModTime;
  String remarkName;
  int rssFileId;
  int rssGenTime;
  String selfIntro;
  bool signAuth;

  BlogInfoWithHot({
    required this.acceptGift,
    required this.acceptReward,
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
    required this.blogStat,
    required this.commentRank,
    required this.extraBits,
    required this.gendar,
    required this.homePageUrl,
    required this.hot,
    required this.imageDigitStamp,
    required this.imageProtected,
    required this.imageStamp,
    required this.ipLocation,
    required this.isOriginalAuthor,
    required this.keyTag,
    required this.novisible,
    required this.postAddTime,
    required this.postModTime,
    required this.remarkName,
    required this.rssFileId,
    required this.rssGenTime,
    required this.selfIntro,
    required this.signAuth,
  });

  factory BlogInfoWithHot.fromJson(Map<String, dynamic> json) {
    return BlogInfoWithHot(
      acceptGift: json['acceptGift'],
      acceptReward: json['acceptReward'],
      auths: json['auths'].cast<String>(),
      avatarBoxId: json['avatarBoxId'],
      avatarBoxImage: json['avatarBoxImage'],
      avatarBoxName: json['avatarBoxName'],
      avaUpdateTime: json['avaUpdateTime'],
      bigAvaImg: json['bigAvaImg'],
      birthday: json['birthday'],
      blogCreateTime: json['blogCreateTime'],
      blogId: json['blogId'],
      blogName: json['blogName'],
      blogNickName: json['blogNickName'],
      blogStat: BlogStat.fromJson(json['blogStat']),
      commentRank: json['commentRank'],
      extraBits: json['extraBits'],
      gendar: json['gendar'],
      homePageUrl: json['homePageUrl'],
      hot: BlogHot.fromJson(json['hot']),
      imageDigitStamp: json['imageDigitStamp'],
      imageProtected: json['imageProtected'],
      imageStamp: json['imageStamp'],
      ipLocation: json['ipLocation'],
      isOriginalAuthor: json['isOriginalAuthor'],
      keyTag: json['keyTag'] ?? "",
      novisible: json['novisible'],
      postAddTime: json['postAddTime'],
      postModTime: json['postModTime'],
      remarkName: json['remarkName'],
      rssFileId: json['rssFileId'],
      rssGenTime: json['rssGenTime'],
      selfIntro: json['selfIntro'],
      signAuth: json['signAuth'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['acceptGift'] = acceptGift;
    data['acceptReward'] = acceptReward;
    data['auths'] = auths;
    data['avatarBoxId'] = avatarBoxId;
    data['avatarBoxImage'] = avatarBoxImage;
    data['avatarBoxName'] = avatarBoxName;
    data['avaUpdateTime'] = avaUpdateTime;
    data['bigAvaImg'] = bigAvaImg;
    data['birthday'] = birthday;
    data['blogCreateTime'] = blogCreateTime;
    data['blogId'] = blogId;
    data['blogName'] = blogName;
    data['blogNickName'] = blogNickName;
    data['blogStat'] = blogStat.toJson();
    data['commentRank'] = commentRank;
    data['extraBits'] = extraBits;
    data['gendar'] = gendar;
    data['homePageUrl'] = homePageUrl;
    data['hot'] = hot.toJson();
    data['imageDigitStamp'] = imageDigitStamp;
    data['imageProtected'] = imageProtected;
    data['imageStamp'] = imageStamp;
    data['ipLocation'] = ipLocation;
    data['isOriginalAuthor'] = isOriginalAuthor;
    data['keyTag'] = keyTag;
    data['novisible'] = novisible;
    data['postAddTime'] = postAddTime;
    data['postModTime'] = postModTime;
    data['remarkName'] = remarkName;
    data['rssFileId'] = rssFileId;
    data['rssGenTime'] = rssGenTime;
    data['selfIntro'] = selfIntro;
    data['signAuth'] = signAuth;
    return data;
  }
}

///BlogStat
class BlogStat {
  int blogId;
  int followedCount;
  int followingCount;
  int grainCount;
  int likedCount;
  int likingCount;
  int memberCount;
  int postQueueCount;
  int privatePostCount;
  int publicPostCount;
  int shareCount;
  int shareSubscribeFolderCount;
  int supporterCount;
  int uappInstallCount;

  BlogStat({
    required this.blogId,
    required this.followedCount,
    required this.followingCount,
    required this.grainCount,
    required this.likedCount,
    required this.likingCount,
    required this.memberCount,
    required this.postQueueCount,
    required this.privatePostCount,
    required this.publicPostCount,
    required this.shareCount,
    required this.shareSubscribeFolderCount,
    required this.supporterCount,
    required this.uappInstallCount,
  });

  factory BlogStat.fromJson(Map<String, dynamic> json) {
    return BlogStat(
      blogId: json['blogId'],
      followedCount: json['followedCount'],
      followingCount: json['followingCount'],
      grainCount: json['grainCount'],
      likedCount: json['likedCount'],
      likingCount: json['likingCount'],
      memberCount: json['memberCount'],
      postQueueCount: json['postQueueCount'],
      privatePostCount: json['privatePostCount'],
      publicPostCount: json['publicPostCount'],
      shareCount: json['shareCount'],
      shareSubscribeFolderCount: json['shareSubscribeFolderCount'],
      supporterCount: json['supporterCount'],
      uappInstallCount: json['uappInstallCount'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['followedCount'] = followedCount;
    data['followingCount'] = followingCount;
    data['grainCount'] = grainCount;
    data['likedCount'] = likedCount;
    data['likingCount'] = likingCount;
    data['memberCount'] = memberCount;
    data['postQueueCount'] = postQueueCount;
    data['privatePostCount'] = privatePostCount;
    data['publicPostCount'] = publicPostCount;
    data['shareCount'] = shareCount;
    data['shareSubscribeFolderCount'] = shareSubscribeFolderCount;
    data['supporterCount'] = supporterCount;
    data['uappInstallCount'] = uappInstallCount;
    return data;
  }
}

///BlogHot
class BlogHot {
  int endDay;
  int favoriteCount;
  int hotCount;
  int reblogCount;
  int shareCount;
  int subscribeCount;
  int tagChatFavoriteCount;

  BlogHot({
    required this.endDay,
    required this.favoriteCount,
    required this.hotCount,
    required this.reblogCount,
    required this.shareCount,
    required this.subscribeCount,
    required this.tagChatFavoriteCount,
  });

  factory BlogHot.fromJson(Map<String, dynamic> json) {
    return BlogHot(
      endDay: json['endDay'],
      favoriteCount: json['favoriteCount'],
      hotCount: json['hotCount'],
      reblogCount: json['reblogCount'],
      shareCount: json['shareCount'],
      subscribeCount: json['subscribeCount'],
      tagChatFavoriteCount: json['tagChatFavoriteCount'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['endDay'] = endDay;
    data['favoriteCount'] = favoriteCount;
    data['hotCount'] = hotCount;
    data['reblogCount'] = reblogCount;
    data['shareCount'] = shareCount;
    data['subscribeCount'] = subscribeCount;
    data['tagChatFavoriteCount'] = tagChatFavoriteCount;
    return data;
  }
}

///BlogCover
class Blogcover {
  int authorId;
  String authorName;
  int id;
  String url;
  String? customBlogCover;

  Blogcover({
    required this.authorId,
    required this.authorName,
    required this.id,
    required this.url,
    this.customBlogCover,
  });

  factory Blogcover.fromJson(Map<String, dynamic> json) {
    return Blogcover(
      authorId: json['authorId'],
      authorName: json['authorName'],
      id: json['id'],
      url: json['url'],
      customBlogCover: json['customBlogCover'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['authorId'] = authorId;
    data['authorName'] = authorName;
    data['id'] = id;
    data['url'] = url;
    data['customBlogCover'] = customBlogCover;
    return data;
  }
}

///BlogSetting
class Blogsetting {
  String archiveSetting;
  int blogId;
  int commentRank;
  int contributePostRank;
  bool hideCommentLike;
  String interestDomainIds;
  List<int> interestDomainIdSet;
  String interests;
  int locationFlag;
  int msgRank;
  bool noSearch;
  bool passAccessOn;
  int phoneThemeId;
  int postCountPerPage;
  int securityRank;
  bool showFans;
  int themeId;
  int themeUserId;

  Blogsetting({
    required this.archiveSetting,
    required this.blogId,
    required this.commentRank,
    required this.contributePostRank,
    required this.hideCommentLike,
    required this.interestDomainIds,
    required this.interestDomainIdSet,
    required this.interests,
    required this.locationFlag,
    required this.msgRank,
    required this.noSearch,
    required this.passAccessOn,
    required this.phoneThemeId,
    required this.postCountPerPage,
    required this.securityRank,
    required this.showFans,
    required this.themeId,
    required this.themeUserId,
  });

  factory Blogsetting.fromJson(Map<String, dynamic> json) {
    return Blogsetting(
      archiveSetting: json['archiveSetting'] ?? "",
      blogId: json['blogId'],
      commentRank: json['commentRank'],
      contributePostRank: json['contributePostRank'],
      hideCommentLike: json['hideCommentLike'],
      interestDomainIds: json['interestDomainIds'] ?? "",
      interestDomainIdSet: (json['interestDomainIdSet'] as List)
          .map((e) => Utils.parseToInt(e))
          .toList(),
      interests: json['interests'] ?? "",
      locationFlag: json['locationFlag'] ?? 0,
      msgRank: json['msgRank'],
      noSearch: json['noSearch'],
      passAccessOn: json['passAccessOn'],
      phoneThemeId: json['phoneThemeId'],
      postCountPerPage: json['postCountPerPage'],
      securityRank: json['securityRank'],
      showFans: json['showFans'],
      themeId: json['themeId'],
      themeUserId: json['themeUserId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['archiveSetting'] = archiveSetting;
    data['blogId'] = blogId;
    data['commentRank'] = commentRank;
    data['contributePostRank'] = contributePostRank;
    data['hideCommentLike'] = hideCommentLike;
    data['interestDomainIds'] = interestDomainIds;
    data['interestDomainIdSet'] = interestDomainIdSet;
    data['interests'] = interests;
    data['locationFlag'] = locationFlag;
    data['msgRank'] = msgRank;
    data['noSearch'] = noSearch;
    data['passAccessOn'] = passAccessOn;
    data['phoneThemeId'] = phoneThemeId;
    data['postCountPerPage'] = postCountPerPage;
    data['securityRank'] = securityRank;
    data['showFans'] = showFans;
    data['themeId'] = themeId;
    data['themeUserId'] = themeUserId;
    return data;
  }
}

///FollowingUserItem
class FollowingUserItem {
  int blogId;
  FullBlogInfo blogInfo;
  bool follower;
  bool following;
  int followTime;
  int hotCount;
  int id;
  int lastPublishTime;
  int lastVisitTime;
  int responseCount;
  int score;
  bool specialFollow;
  int userId;

  FollowingUserItem({
    required this.blogId,
    required this.blogInfo,
    required this.follower,
    required this.followTime,
    required this.hotCount,
    required this.id,
    required this.following,
    required this.lastPublishTime,
    required this.lastVisitTime,
    required this.responseCount,
    required this.score,
    required this.specialFollow,
    required this.userId,
  });

  factory FollowingUserItem.fromJson(Map<String, dynamic> json) {
    return FollowingUserItem(
      blogId: json['blogId'],
      blogInfo: FullBlogInfo.fromJson(json['blogInfo']),
      follower: json['follower'],
      following: json['following'] ?? true,
      followTime: json['followTime'] ?? 0,
      hotCount: json['hotCount'] ?? 0,
      id: json['id'] ?? 0,
      lastPublishTime: json['lastPublishTime'] ?? 0,
      lastVisitTime: json['lastVisitTime'] ?? 0,
      responseCount: json['responseCount'] ?? 0,
      score: json['score'] ?? 0,
      specialFollow: json['specialFollow'] ?? false,
      userId: json['userId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogId'] = blogId;
    data['blogInfo'] = blogInfo.toJson();
    data['follower'] = follower;
    data['followTime'] = followTime;
    data['hotCount'] = hotCount;
    data['id'] = id;
    data['lastPublishTime'] = lastPublishTime;
    data['lastVisitTime'] = lastVisitTime;
    data['responseCount'] = responseCount;
    data['score'] = score;
    data['specialFollow'] = specialFollow;
    data['userId'] = userId;
    return data;
  }
}

class SupporterItem {
  SimpleBlogInfo blogInfo;
  int score;

  SupporterItem({
    required this.blogInfo,
    required this.score,
  });

  factory SupporterItem.fromJson(Map<String, dynamic> json) {
    return SupporterItem(
      blogInfo: SimpleBlogInfo.fromJson(json['blogInfo']),
      score: json['score'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blogInfo'] = blogInfo.toJson();
    data['score'] = score;
    return data;
  }
}

class BlacklistItem {
  int blacklistBlogId;
  FullBlogInfo blogInfo;
  int createTime;
  int id;
  int userId;

  BlacklistItem({
    required this.blacklistBlogId,
    required this.blogInfo,
    required this.createTime,
    required this.id,
    required this.userId,
  });

  factory BlacklistItem.fromJson(Map<String, dynamic> json) {
    return BlacklistItem(
      blacklistBlogId: json['blacklistBlogId'],
      blogInfo: FullBlogInfo.fromJson(json['blogInfo']),
      createTime: json['createTime'],
      id: json['id'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blacklistBlogId'] = blacklistBlogId;
    data['blogInfo'] = blogInfo.toJson();
    data['createTime'] = createTime;
    data['id'] = id;
    data['userId'] = userId;
    return data;
  }
}
