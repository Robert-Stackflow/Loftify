import 'package:tuple/tuple.dart';

import '../generated/l10n.dart';

enum ActiveThemeMode { system, light, dark }

enum TokenType {
  none,
  captchCode,
  password,
  lofterID,
}

enum ImageQuality { small, medium, origin, raw }

enum HistoryLayoutMode { waterFlow, nineGrid }

enum FavoriteFolderDetailLayoutMode { list, nineGrid, flow }

enum InfoMode { me, other }

enum FollowingMode { following, follower, timeline }

enum ShowDetailMode { not, avatar, avatarBox }

enum TagType {
  normal,
  hot,
  egg,
  catutu;

  bool get preventJump => this == TagType.egg || this == TagType.catutu;
}

enum RankListType { tag, tagRank, unset, post, collection }

enum PostType { image, article, video, grain, invalid }

enum TagPostType { noLimit, article, image }

enum TagRecentDayType { noLimit, oneDay, oneWeek, oneMonth }

enum TagRangeType { noLimit, follow, notViewInPastSevenDays }

enum TagPostResultType { newPost, newComment, total, date, week, month }

class EnumsLabelGetter {
  static String getTagPostTypeLabel(TagPostType type) {
    switch (type) {
      case TagPostType.noLimit:
        return S.current.noLimit;
      case TagPostType.image:
        return S.current.images;
      case TagPostType.article:
        return S.current.words;
    }
  }

  static String getTagRecentDayTypeLabel(TagRecentDayType type) {
    switch (type) {
      case TagRecentDayType.noLimit:
        return S.current.noLimit;
      case TagRecentDayType.oneDay:
        return S.current.inOneDay;
      case TagRecentDayType.oneWeek:
        return S.current.inOneWeek;
      case TagRecentDayType.oneMonth:
        return S.current.inOneMonth;
    }
  }

  static String getTagRangeTypeLabel(TagRangeType type) {
    switch (type) {
      case TagRangeType.noLimit:
        return S.current.noLimit;
      case TagRangeType.follow:
        return S.current.followingUser;
      case TagRangeType.notViewInPastSevenDays:
        return S.current.haveNotVisitRecentSevenDays;
    }
  }

  static List<Tuple2<String, ImageQuality>> getImageQualityLabels() {
    return [
      Tuple2(S.current.lowImageQuality, ImageQuality.small),
      Tuple2(S.current.middleImageQuality, ImageQuality.medium),
      Tuple2(S.current.rawImageQuality, ImageQuality.origin),
      Tuple2(S.current.originImageQuality, ImageQuality.raw),
    ];
  }

  static String getImageQualityLabel(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.small:
        return S.current.lowImageQuality;
      case ImageQuality.medium:
        return S.current.middleImageQuality;
      case ImageQuality.origin:
        return S.current.rawImageQuality;
      case ImageQuality.raw:
        return S.current.originImageQuality;
    }
  }
}

enum MultiWindowType { Main, Setting, Unknown }

extension Index on int {
  MultiWindowType get windowType {
    switch (this) {
      case 0:
        return MultiWindowType.Main;
      case 1:
        return MultiWindowType.Setting;
      default:
        return MultiWindowType.Unknown;
    }
  }
}

enum DoubleTapAction {
  none('none'),
  like('like'),
  recommend('recommend'),
  download('download'),
  downloadAll('downloadAll'),
  copyLink('copyLink');

  const DoubleTapAction(this.key);

  final String key;

  String get label {
    switch (this) {
      case none:
        return S.current.noOperation;
      case like:
        return S.current.like;
      case recommend:
        return S.current.recommend;
      case download:
        return S.current.downloadCurrentImage;
      case downloadAll:
        return S.current.downloadAllImages;
      case copyLink:
        return S.current.copyLink;
    }
  }
}

enum DownloadSuccessAction {
  none('none'),
  unlike('unlike'),
  unrecommend('unrecommend');

  const DownloadSuccessAction(this.key);

  final String key;

  String get label {
    switch (this) {
      case none:
        return S.current.noOperation;
      case unlike:
        return S.current.unlike;
      case unrecommend:
        return S.current.unrecommend;
    }
  }
}

extension DoubleTapEnumExtension on DoubleTapAction {
  List<Tuple2<String, DoubleTapAction>> get tuples {
    return DoubleTapAction.values.map((e) => Tuple2(e.label, e)).toList();
  }
}

extension DownloadSuccessEnumExtension on DownloadSuccessAction {
  List<Tuple2<String, DownloadSuccessAction>> get tuples {
    return DownloadSuccessAction.values.map((e) => Tuple2(e.label, e)).toList();
  }
}

enum FilenameField {
  originalName('original_name', '{original_name}'),
  blogId('blog_id', '{blog_id}'),
  blogLofterId('blog_lofter_id', '{blog_lofter_id}'),
  blogNickName('blog_nick_name', '{blog_nick_name}'),
  postId('post_id', '{post_id}'),
  postTitle('post_title', '{post_title}'),
  postTags('post_tags', '{post_tags}'),
  postPublishTime('post_publish_time', '{post_publish_time}'),
  part('part', '{part}'),
  timestamp('timestamp', '{timestamp}'),
  currentTime('current_time', '{current_time}'),
  underline('_', '_'),
  slack('/', '/');

  const FilenameField(this.label, this.format);

  final String format;
  final String label;

  String get example {
    switch (this) {
      case originalName:
        return S.current.fieldOriginalNameExample;
      case blogId:
        return S.current.fieldBlogIdExample;
      case blogLofterId:
        return S.current.fieldBlogLofterIdExample;
      case blogNickName:
        return S.current.fieldBlogNickNameExample;
      case postId:
        return S.current.fieldPostIdExample;
      case postTitle:
        return S.current.fieldPostTitleExample;
      case postTags:
        return S.current.fieldPostTagsExample;
      case postPublishTime:
        return S.current.fieldPostPublishTimeExample;
      case part:
        return S.current.fieldPartExample;
      case timestamp:
        return S.current.fieldTimestampExample;
      case currentTime:
        return S.current.fieldCurrentTimeExample;
      case underline:
        return S.current.fieldUnderlineExample;
      case slack:
        return S.current.fieldSlackExample;
      default:
        return "";
    }
  }

  String get description {
    switch (this) {
      case originalName:
        return S.current.fieldOriginalNameDescription;
      case blogId:
        return S.current.fieldBlogIdDescription;
      case blogLofterId:
        return S.current.fieldBlogLofterIdDescription;
      case blogNickName:
        return S.current.fieldBlogNickNameDescription;
      case postId:
        return S.current.fieldPostIdDescription;
      case postTitle:
        return S.current.fieldPostTitleDescription;
      case postTags:
        return S.current.fieldPostTagsDescription;
      case postPublishTime:
        return S.current.fieldPostPublishTimeDescription;
      case part:
        return S.current.fieldPartDescription;
      case timestamp:
        return S.current.fieldTimestampDescription;
      case currentTime:
        return S.current.fieldCurrentTimeDescription;
      case underline:
        return S.current.fieldUnderlineDescription;
      case slack:
        return S.current.fieldSlackDescription;
      default:
        return "";
    }
  }
}

enum InitPhase {
  haveNotConnected,
  connecting,
  successful,
  failed;
}

enum Copyright {
  none,
  by,
  byNd,
  byNc,
  bySa,
  byNcNd,
  byNcSa;

  static Copyright fromInt(int index) {
    switch (index) {
      case 0:
        return none;
      case 1:
        return by;
      case 2:
        return byNd;
      case 3:
        return byNc;
      case 4:
        return bySa;
      case 5:
        return byNcNd;
      case 6:
        return byNcSa;
      default:
        return none;
    }
  }

  String get label {
    switch (this) {
      case none:
        return S.current.noneCopyright;
      case by:
        return S.current.byCopyright;
      case byNd:
        return S.current.byNdCopyright;
      case byNc:
        return S.current.byNcCopyright;
      case bySa:
        return S.current.bySaCopyright;
      case byNcNd:
        return S.current.byNcNdCopyright;
      case byNcSa:
        return S.current.byNcSaCopyright;
      default:
        return S.current.noneCopyright;
    }
  }
}

enum TrayKey {
  displayApp("displayApp"),
  lockApp("lockApp"),
  setting("setting"),
  officialWebsite("officialWebsite"),
  githubRepository("githubRepository"),
  about("about"),
  launchAtStartup("launchAtStartup"),
  checkUpdates("checkUpdates"),
  shortcutHelp("shortcutHelp"),
  exitApp("exitApp");

  final String key;

  const TrayKey(this.key);
}

enum SideBarChoice {
  Home("home"),
  Search("search"),
  Dynamic("dynamic"),
  Mine("mine");

  final String key;

  const SideBarChoice(this.key);

  static fromString(String string) {
    switch (string) {
      case "home":
        return SideBarChoice.Home;
      case "search":
        return SideBarChoice.Search;
      case "dynamic":
        return SideBarChoice.Dynamic;
      case "mine":
        return SideBarChoice.Mine;
      default:
        return SideBarChoice.Home;
    }
  }

  static fromInt(int index) {
    switch (index) {
      case 0:
        return SideBarChoice.Home;
      case 1:
        return SideBarChoice.Search;
      case 2:
        return SideBarChoice.Dynamic;
      case 3:
        return SideBarChoice.Mine;
      default:
        return SideBarChoice.Home;
    }
  }
}
