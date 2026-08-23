import 'package:awesome_chewie/awesome_chewie.dart';

import '../../Models/grain_response.dart';
import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/post_sequence_source.dart';

class GeneralPostItem {
  GeneralPostItem({
    this.showLikeButton = true,
    this.showArticle = true,
    this.showVideo = true,
    this.tagPrefix,
    this.photoCount,
    this.shareInfo,
    this.followed,
    this.shared = false,
    this.shareCount = 0,
    this.commentCount = 0,
    required this.type,
    required this.photoLinks,
    required this.blogId,
    required this.postId,
    required this.permalink,
    required this.collectionId,
    required this.liked,
    required this.blogName,
    required this.blogNickName,
    required this.title,
    required this.digest,
    required this.content,
    required this.firstImageUrl,
    required this.duration,
    required this.likeCount,
    required this.tags,
    required this.bigAvaImg,
    this.excludeTag,
    this.publishTime = 0,
    this.opTime = 0,
    this.showMoreButton = false,
    this.onShieldTag,
    this.onShieldContent,
    this.onShieldUser,
    this.onLikeChanged,
    this.sequenceSource,
  });

  PostType type;
  List<PhotoLink> photoLinks;
  int blogId;
  int publishTime;
  int opTime;
  int postId;
  String permalink;
  int collectionId;
  bool liked;
  bool shared;
  bool? followed;
  String blogName;
  String blogNickName;
  String title;
  String digest;
  String content;
  String firstImageUrl;
  int duration;
  int likeCount;
  int shareCount;
  int commentCount;
  List<String> tags;
  String bigAvaImg;
  int? photoCount;
  String? tagPrefix;
  bool? showVideo;
  bool? showArticle;
  bool? showLikeButton;
  String? excludeTag;
  bool showMoreButton;
  ShareInfo? shareInfo;
  final Function(String tag)? onShieldTag;
  final Function()? onShieldContent;
  final Function()? onShieldUser;
  final void Function(bool liked)? onLikeChanged;
  final PostSequenceSource? sequenceSource;

  bool get hasTitleOrContent {
    final normalizedTitle = StringUtil.clearBlank(title);
    final normalizedContent =
        StringUtil.clearBlank(HtmlUtil.extractTextFromHtml(content));
    final normalizedDigest =
        StringUtil.clearBlank(HtmlUtil.extractTextFromHtml(digest));
    return StringUtil.isNotEmpty(normalizedTitle) ||
        StringUtil.isNotEmpty(normalizedContent) ||
        StringUtil.isNotEmpty(normalizedDigest);
  }

  String get processedTitle {
    final normalizedTitle = StringUtil.clearBlank(title);
    final normalizedDigest =
        StringUtil.clearBlank(HtmlUtil.extractTextFromHtml(digest));
    final normalizedContent =
        StringUtil.clearBlank(HtmlUtil.extractTextFromHtml(content));
    return StringUtil.isNotEmpty(normalizedTitle)
        ? normalizedTitle
        : StringUtil.isNotEmpty(normalizedDigest)
            ? normalizedDigest
            : normalizedContent;
  }
}
