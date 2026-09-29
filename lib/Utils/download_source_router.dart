import 'package:flutter/widgets.dart';
import 'package:loftify/Utils/enums.dart';

import '../Models/download_task.dart';
import '../Screens/Info/favorite_folder_detail_screen.dart';
import '../Screens/Info/like_screen.dart';
import '../Screens/Info/share_screen.dart';
import '../Screens/Post/collection_detail_screen.dart';
import '../Screens/Post/grain_detail_screen.dart';
import '../Screens/Post/post_detail_screen.dart';

/// Resolves the persisted business source of a grouped download without
/// coupling the download model to route widgets.
abstract final class DownloadSourceRouter {
  static Widget? destinationFor(DownloadSourceDescriptor source) {
    final metadata = source.metadata;
    return switch (source.type) {
      DownloadSourceType.postAll => _postDestination(metadata),
      DownloadSourceType.collection => _collectionDestination(source),
      DownloadSourceType.grain => _grainDestination(source),
      DownloadSourceType.likes => _likeDestination(source),
      DownloadSourceType.recommendations => _recommendationDestination(source),
      DownloadSourceType.favoriteFolder => _favoriteDestination(source),
      DownloadSourceType.other => null,
    };
  }

  static Widget? _postDestination(Map<String, String> metadata) {
    final postId = int.tryParse(metadata['postId'] ?? '');
    final blogId = int.tryParse(metadata['blogId'] ?? '');
    final blogName = metadata['blogName']?.trim() ?? '';
    if (postId == null ||
        postId <= 0 ||
        blogId == null ||
        blogId <= 0 ||
        blogName.isEmpty) {
      return null;
    }
    return PostDetailScreen(
      meta: <String, String>{
        'postId': postId.toRadixString(16),
        'blogId': blogId.toRadixString(16),
        'blogName': blogName,
      },
      isArticle: false,
    );
  }

  static Widget? _collectionDestination(DownloadSourceDescriptor source) {
    final collectionId = int.tryParse(
      source.metadata['collectionId'] ?? source.sourceId,
    );
    if (collectionId == null || collectionId <= 0) return null;
    return CollectionDetailScreen(
      collectionId: collectionId,
      postId: int.tryParse(source.metadata['postId'] ?? '') ?? 0,
      blogId: int.tryParse(source.metadata['blogId'] ?? '') ?? 0,
      blogName: source.metadata['blogName'] ?? '',
    );
  }

  static Widget? _grainDestination(DownloadSourceDescriptor source) {
    final grainId = int.tryParse(source.metadata['grainId'] ?? source.sourceId);
    final blogId = int.tryParse(source.metadata['blogId'] ?? '');
    if (grainId == null || grainId <= 0 || blogId == null || blogId <= 0) {
      return null;
    }
    return GrainDetailScreen(grainId: grainId, blogId: blogId);
  }

  static Widget? _likeDestination(DownloadSourceDescriptor source) {
    if (source.sourceId == 'self') return LikeScreen();
    final blogId = int.tryParse(source.metadata['blogId'] ?? source.sourceId);
    final blogName = source.metadata['blogName']?.trim() ?? '';
    if (blogId == null || blogId <= 0 || blogName.isEmpty) return null;
    return LikeScreen(
      infoMode: InfoMode.other,
      blogId: blogId,
      blogName: blogName,
    );
  }

  static Widget? _recommendationDestination(
    DownloadSourceDescriptor source,
  ) {
    if (source.sourceId == 'self') return ShareScreen();
    final blogId = int.tryParse(source.metadata['blogId'] ?? source.sourceId);
    final blogName = source.metadata['blogName']?.trim() ?? '';
    if (blogId == null || blogId <= 0 || blogName.isEmpty) return null;
    return ShareScreen(
      infoMode: InfoMode.other,
      blogId: blogId,
      blogName: blogName,
    );
  }

  static Widget? _favoriteDestination(DownloadSourceDescriptor source) {
    final folderId = int.tryParse(
      source.metadata['favoriteFolderId'] ?? source.sourceId,
    );
    if (folderId == null || folderId <= 0) return null;
    return FavoriteFolderDetailScreen(favoriteFolderId: folderId);
  }
}
