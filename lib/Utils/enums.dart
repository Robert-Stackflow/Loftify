import 'package:tuple/tuple.dart';

import '../l10n/l10n.dart';

enum TokenType {
  none,
  captchCode,
  password,
  lofterID,
}

enum ImageQuality { small, medium, origin, raw }

enum HistoryLayoutMode { waterFlow, nineGrid }

enum NavigationBarDisplayStyle {
  iconAndText('iconAndText'),
  iconOnly('iconOnly'),
  textOnly('textOnly');

  const NavigationBarDisplayStyle(this.key);

  final String key;

  static NavigationBarDisplayStyle fromKey(String? key) {
    return NavigationBarDisplayStyle.values.firstWhere(
      (style) => style.key == key,
      orElse: () => NavigationBarDisplayStyle.iconOnly,
    );
  }

  String get label => switch (this) {
        NavigationBarDisplayStyle.iconAndText =>
          appLocalizations.navigationBarIconAndText,
        NavigationBarDisplayStyle.iconOnly =>
          appLocalizations.navigationBarIconOnly,
        NavigationBarDisplayStyle.textOnly =>
          appLocalizations.navigationBarTextOnly,
      };
}

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
        return appLocalizations.noLimit;
      case TagPostType.image:
        return appLocalizations.images;
      case TagPostType.article:
        return appLocalizations.words;
    }
  }

  static String getTagRecentDayTypeLabel(TagRecentDayType type) {
    switch (type) {
      case TagRecentDayType.noLimit:
        return appLocalizations.noLimit;
      case TagRecentDayType.oneDay:
        return appLocalizations.inOneDay;
      case TagRecentDayType.oneWeek:
        return appLocalizations.inOneWeek;
      case TagRecentDayType.oneMonth:
        return appLocalizations.inOneMonth;
    }
  }

  static String getTagRangeTypeLabel(TagRangeType type) {
    switch (type) {
      case TagRangeType.noLimit:
        return appLocalizations.noLimit;
      case TagRangeType.follow:
        return appLocalizations.followingUser;
      case TagRangeType.notViewInPastSevenDays:
        return appLocalizations.haveNotVisitRecentSevenDays;
    }
  }

  static List<Tuple2<String, ImageQuality>> getImageQualityLabels() {
    return [
      Tuple2(appLocalizations.lowImageQuality, ImageQuality.small),
      Tuple2(appLocalizations.middleImageQuality, ImageQuality.medium),
      Tuple2(appLocalizations.rawImageQuality, ImageQuality.origin),
      Tuple2(appLocalizations.originImageQuality, ImageQuality.raw),
    ];
  }

  static String getImageQualityLabel(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.small:
        return appLocalizations.lowImageQuality;
      case ImageQuality.medium:
        return appLocalizations.middleImageQuality;
      case ImageQuality.origin:
        return appLocalizations.rawImageQuality;
      case ImageQuality.raw:
        return appLocalizations.originImageQuality;
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
        return appLocalizations.noOperation;
      case like:
        return appLocalizations.like;
      case recommend:
        return appLocalizations.recommend;
      case download:
        return appLocalizations.downloadCurrentImage;
      case downloadAll:
        return appLocalizations.downloadAllImages;
      case copyLink:
        return appLocalizations.copyLink;
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
        return appLocalizations.noOperation;
      case unlike:
        return appLocalizations.unlike;
      case unrecommend:
        return appLocalizations.unrecommend;
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
        return appLocalizations.fieldOriginalNameExample;
      case blogId:
        return appLocalizations.fieldBlogIdExample;
      case blogLofterId:
        return appLocalizations.fieldBlogLofterIdExample;
      case blogNickName:
        return appLocalizations.fieldBlogNickNameExample;
      case postId:
        return appLocalizations.fieldPostIdExample;
      case postTitle:
        return appLocalizations.fieldPostTitleExample;
      case postTags:
        return appLocalizations.fieldPostTagsExample;
      case postPublishTime:
        return appLocalizations.fieldPostPublishTimeExample;
      case part:
        return appLocalizations.fieldPartExample;
      case timestamp:
        return appLocalizations.fieldTimestampExample;
      case currentTime:
        return appLocalizations.fieldCurrentTimeExample;
      case underline:
        return appLocalizations.fieldUnderlineExample;
      case slack:
        return appLocalizations.fieldSlackExample;
    }
  }

  String get description {
    switch (this) {
      case originalName:
        return appLocalizations.fieldOriginalNameDescription;
      case blogId:
        return appLocalizations.fieldBlogIdDescription;
      case blogLofterId:
        return appLocalizations.fieldBlogLofterIdDescription;
      case blogNickName:
        return appLocalizations.fieldBlogNickNameDescription;
      case postId:
        return appLocalizations.fieldPostIdDescription;
      case postTitle:
        return appLocalizations.fieldPostTitleDescription;
      case postTags:
        return appLocalizations.fieldPostTagsDescription;
      case postPublishTime:
        return appLocalizations.fieldPostPublishTimeDescription;
      case part:
        return appLocalizations.fieldPartDescription;
      case timestamp:
        return appLocalizations.fieldTimestampDescription;
      case currentTime:
        return appLocalizations.fieldCurrentTimeDescription;
      case underline:
        return appLocalizations.fieldUnderlineDescription;
      case slack:
        return appLocalizations.fieldSlackDescription;
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
        return appLocalizations.noneCopyright;
      case by:
        return appLocalizations.byCopyright;
      case byNd:
        return appLocalizations.byNdCopyright;
      case byNc:
        return appLocalizations.byNcCopyright;
      case bySa:
        return appLocalizations.bySaCopyright;
      case byNcNd:
        return appLocalizations.byNcNdCopyright;
      case byNcSa:
        return appLocalizations.byNcSaCopyright;
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
