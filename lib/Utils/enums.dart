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
        return "不限";
      case TagPostType.image:
        return "图片";
      case TagPostType.article:
        return "文字";
    }
  }

  static String getTagRecentDayTypeLabel(TagRecentDayType type) {
    switch (type) {
      case TagRecentDayType.noLimit:
        return "不限";
      case TagRecentDayType.oneDay:
        return "一天内";
      case TagRecentDayType.oneWeek:
        return "一周内";
      case TagRecentDayType.oneMonth:
        return "一个月内";
    }
  }

  static String getTagRangeTypeLabel(TagRangeType type) {
    switch (type) {
      case TagRangeType.noLimit:
        return "不限";
      case TagRangeType.follow:
        return "关注的人";
      case TagRangeType.notViewInPastSevenDays:
        return "近7日未看";
    }
  }

  static List<Tuple2<String, ImageQuality>> getImageQualityLabels() {
    return [
      const Tuple2("低质量", ImageQuality.small),
      const Tuple2("中等质量", ImageQuality.medium),
      const Tuple2("高质量", ImageQuality.origin),
      const Tuple2("原图", ImageQuality.raw),
    ];
  }

  static String getImageQualityLabel(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.small:
        return "低质量";
      case ImageQuality.medium:
        return "中等质量";
      case ImageQuality.origin:
        return "高质量";
      case ImageQuality.raw:
        return "原图";
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
  none('none', '无操作'),
  like('like', '喜欢'),
  recommend('recommend', '推荐'),
  download('download', '下载当前图片'),
  downloadAll('downloadAll', '下载所有图片'),
  copyLink('copyLink', '复制帖子链接');

  const DoubleTapAction(this.key, this.label);

  final String key;
  final String label;
}

enum DownloadSuccessAction {
  none('none', '无操作'),
  unlike('unlike', '取消喜欢'),
  unrecommend('unrecommend', '取消推荐');

  const DownloadSuccessAction(this.key, this.label);

  final String key;
  final String label;
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
  none('不声明'),
  by('署名'),
  byNd('署名-禁止演绎'),
  byNc('署名-非商业性使用'),
  bySa("署名-相同方式共享"),
  byNcNd('署名-非商业性使用-禁止演绎'),
  byNcSa('署名-非商业性使用-相同方式共享');

  const Copyright(this.label);

  final String label;

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
