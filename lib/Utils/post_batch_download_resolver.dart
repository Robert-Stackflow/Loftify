import 'package:awesome_chewie/awesome_chewie.dart';

import '../Api/post_api.dart';
import '../Models/download_task.dart';
import '../Models/illust.dart';
import '../Models/post_detail_response.dart';
import '../Widgets/PostItem/general_post_item.dart';
import 'package:loftify/Utils/enums.dart';
import 'loftify_file_util.dart';
import 'package:loftify/Utils/utils.dart';

typedef PostDetailLoader = Future<dynamic> Function({
  required int postId,
  required int blogId,
  required String blogName,
});

class PostDownloadResolution {
  const PostDownloadResolution({
    required this.postId,
    required this.requests,
    this.failed = false,
  });

  final int postId;
  final List<DownloadRequest> requests;
  final bool failed;
}

/// Resolves a post card into original image or video resources understood by
/// the persistent download queue.
class PostBatchDownloadResolver {
  PostBatchDownloadResolver({PostDetailLoader? detailLoader})
      : _detailLoader = detailLoader ?? PostApi.getDetail;

  final PostDetailLoader _detailLoader;

  Future<PostDownloadResolution> resolve(GeneralPostItem item) async {
    if (item.type == PostType.invalid || item.postId <= 0 || item.blogId <= 0) {
      return PostDownloadResolution(
        postId: item.postId,
        requests: const <DownloadRequest>[],
        failed: true,
      );
    }

    try {
      if (item.type == PostType.image && item.photoLinks.isNotEmpty) {
        return PostDownloadResolution(
          postId: item.postId,
          requests: _imageRequests(
            item,
            item.photoLinks.map((photo) => photo.middle),
          ),
        );
      }

      if (item.type == PostType.article) {
        final inlineImages = HtmlUtil.extractImagesFromHtml(item.content)
            .where((url) => url.trim().isNotEmpty)
            .toList(growable: false);
        if (inlineImages.isNotEmpty) {
          return PostDownloadResolution(
            postId: item.postId,
            requests: _imageRequests(item, inlineImages),
          );
        }
      }

      final detail = await _loadDetail(item);
      final post = detail?.post;
      if (post == null ||
          post.valid == 0 ||
          (post.needPay && !post.payingView)) {
        return PostDownloadResolution(
          postId: item.postId,
          requests: const <DownloadRequest>[],
          failed: true,
        );
      }

      final detailedItem = _metadataItem(item, post);
      if (post.type == 4) {
        final info = post.videoInfo ?? post.videoPostView?.videoInfo;
        final videoUrl = _firstValidUrl(<String>[
          info?.originUrl ?? '',
          info?.h265Url ?? '',
          info?.flashurl ?? '',
        ]);
        if (videoUrl == null) {
          return PostDownloadResolution(
            postId: item.postId,
            requests: const <DownloadRequest>[],
            failed: true,
          );
        }
        return PostDownloadResolution(
          postId: item.postId,
          requests: <DownloadRequest>[
            _requestForUrl(
              detailedItem,
              videoUrl,
              part: 0,
              mediaType: DownloadMediaType.video,
            ),
          ],
        );
      }

      final urls = <String>[
        ..._photoUrls(post.photoLinks),
        ...HtmlUtil.extractImagesFromHtml(post.content),
      ];
      final requests = _imageRequests(detailedItem, urls);
      return PostDownloadResolution(
        postId: item.postId,
        requests: requests,
        failed: requests.isEmpty,
      );
    } catch (error, stackTrace) {
      try {
        ILogger.error('Failed to resolve post downloads', error, stackTrace);
      } catch (_) {}
      return PostDownloadResolution(
        postId: item.postId,
        requests: const <DownloadRequest>[],
        failed: true,
      );
    }
  }

  Future<PostDetailData?> _loadDetail(GeneralPostItem item) async {
    final value = await _detailLoader(
      postId: item.postId,
      blogId: item.blogId,
      blogName: item.blogName,
    ).timeout(const Duration(seconds: 20));
    if (value is! Map || value['meta']?['status'] != 200) return null;
    final posts = value['response']?['posts'];
    if (posts is! List || posts.isEmpty || posts.first is! Map) return null;
    return PostDetailData.fromJson(
      Map<String, dynamic>.from(posts.first as Map),
    );
  }

  GeneralPostItem _metadataItem(GeneralPostItem item, PostDetail post) {
    return GeneralPostItem(
      type: post.type == 4
          ? PostType.video
          : post.photoLinks.isNotEmpty
              ? PostType.image
              : PostType.article,
      photoLinks: item.photoLinks,
      blogId: post.blogId,
      postId: post.id,
      permalink: post.permalink,
      collectionId: post.collectionId,
      liked: item.liked,
      blogName: post.blogInfo?.blogName ?? item.blogName,
      blogNickName: post.blogInfo?.blogNickName ?? item.blogNickName,
      title: post.title,
      digest: post.digest,
      content: post.content,
      firstImageUrl: post.firstImageUrl,
      duration: post.videoInfo?.duration ?? 0,
      likeCount: item.likeCount,
      tags: post.tagList,
      bigAvaImg: post.blogInfo?.bigAvaImg ?? item.bigAvaImg,
      publishTime: post.publishTime,
    );
  }

  List<String> _photoUrls(String encodedLinks) {
    final urls = <String>[];
    for (final raw in Utils.parseJsonList(encodedLinks)) {
      try {
        urls.add(PhotoLink.fromJson(raw).middle);
      } catch (_) {}
    }
    return urls;
  }

  List<DownloadRequest> _imageRequests(
    GeneralPostItem item,
    Iterable<String> urls,
  ) {
    final seen = <String>{};
    final requests = <DownloadRequest>[];
    var part = 0;
    for (final sourceUrl in urls) {
      final normalized = _normalizeUrl(sourceUrl);
      if (normalized == null) continue;
      final rawUrl = _normalizeUrl(
            Utils.getUrlByQuality(normalized, ImageQuality.raw),
          ) ??
          normalized;
      if (!seen.add(rawUrl)) continue;
      requests.add(_requestForUrl(
        item,
        rawUrl,
        part: part++,
        mediaType: DownloadMediaType.image,
      ));
    }
    return requests;
  }

  DownloadRequest _requestForUrl(
    GeneralPostItem item,
    String url, {
    required int part,
    required DownloadMediaType mediaType,
  }) {
    final defaultExtension =
        mediaType == DownloadMediaType.video ? 'mp4' : 'jpg';
    final parsedExtension = FileUtil.extractFileExtensionFromUrl(url).trim();
    final extension =
        parsedExtension.isEmpty ? defaultExtension : parsedExtension;
    final parsedName = FileUtil.extractFileNameFromUrl(url).trim();
    final originalName =
        parsedName.isEmpty ? '${item.postId}_$part.$extension' : parsedName;
    final illust = Illust(
      extension: extension,
      url: url,
      postId: item.postId,
      originalName: originalName,
      blogId: item.blogId,
      blogLofterId: item.blogName,
      blogNickName: item.blogNickName,
      part: part,
      postTitle: item.title,
      postDigest: item.digest,
      tags: item.tags,
      publishTime: item.publishTime,
    );
    return DownloadRequest(
      url: url,
      fileName: LoftifyFileUtil.getFileNameByIllust(illust),
      mediaType: mediaType,
      title: item.processedTitle,
      thumbnailUrl: mediaType == DownloadMediaType.image
          ? url
          : _normalizeUrl(
              item.photoLinks.isNotEmpty
                  ? item.photoLinks.first.middle
                  : item.firstImageUrl,
            ),
    );
  }

  String? _firstValidUrl(Iterable<String> urls) {
    for (final url in urls) {
      final normalized = _normalizeUrl(url);
      if (normalized != null) return normalized;
    }
    return null;
  }

  String? _normalizeUrl(String value) {
    var normalized = value.trim();
    if (normalized.startsWith('//')) normalized = 'https:$normalized';
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return normalized;
  }
}
