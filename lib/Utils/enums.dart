import 'package:tuple/tuple.dart';

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
  originalName('original_name', '{original_name}', '图片原文件名称'),
  postId('post_id', '{post_id}', '帖子ID'),
  postTitle('post_title', '{post_title}', '帖子标题，若没有标题则忽略该字段'),
  timestamp('timestamp', '{timestamp}', '时间戳'),
  blogId('blog_id', '{blog_id}', '作者ID'),
  blogLofterId('blog_lofter_id', '{blog_lofter_id}', '作者Lofter ID'),
  blogNickName('blog_nick_name', '{blog_nick_name}', '作者昵称'),
  part('part', '{part}', '图片序号'),
  underline('_', '_', '下划线');

  const FilenameField(this.label, this.format, this.description);

  final String format;
  final String label;
  final String description;
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
