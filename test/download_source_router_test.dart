import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Models/download_task.dart';
import 'package:loftify/Screens/Info/favorite_folder_detail_screen.dart';
import 'package:loftify/Screens/Info/like_screen.dart';
import 'package:loftify/Screens/Info/share_screen.dart';
import 'package:loftify/Screens/Post/collection_detail_screen.dart';
import 'package:loftify/Screens/Post/grain_detail_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Utils/download_source_router.dart';

void main() {
  test('post source resolves decimal persisted ids to post meta hex ids', () {
    final destination = DownloadSourceRouter.destinationFor(
      const DownloadSourceDescriptor(
        type: DownloadSourceType.postAll,
        sourceId: '16',
        title: 'Post',
        metadata: <String, String>{
          'postId': '16',
          'blogId': '32',
          'blogName': 'creator',
        },
      ),
    );

    expect(destination, isA<PostDetailScreen>());
    final screen = destination! as PostDetailScreen;
    expect(screen.meta, <String, String>{
      'postId': '10',
      'blogId': '20',
      'blogName': 'creator',
    });
  });

  test('collection grain and favorite sources keep their business ids', () {
    final collection = DownloadSourceRouter.destinationFor(
      const DownloadSourceDescriptor(
        type: DownloadSourceType.collection,
        sourceId: '42',
        title: 'Collection',
        metadata: <String, String>{
          'postId': '11',
          'blogId': '12',
          'blogName': 'creator',
        },
      ),
    )! as CollectionDetailScreen;
    final grain = DownloadSourceRouter.destinationFor(
      const DownloadSourceDescriptor(
        type: DownloadSourceType.grain,
        sourceId: '88',
        title: 'Grain',
        metadata: <String, String>{'blogId': '99'},
      ),
    )! as GrainDetailScreen;
    final favorite = DownloadSourceRouter.destinationFor(
      const DownloadSourceDescriptor(
        type: DownloadSourceType.favoriteFolder,
        sourceId: '66',
        title: 'Folder',
      ),
    )! as FavoriteFolderDetailScreen;

    expect(collection.collectionId, 42);
    expect(collection.postId, 11);
    expect(collection.blogId, 12);
    expect(collection.blogName, 'creator');
    expect(grain.grainId, 88);
    expect(grain.blogId, 99);
    expect(favorite.favoriteFolderId, 66);
  });

  test('self list sources resolve to the matching content lists', () {
    final likes = DownloadSourceRouter.destinationFor(
      const DownloadSourceDescriptor(
        type: DownloadSourceType.likes,
        sourceId: 'self',
        title: 'Likes',
      ),
    );
    final recommendations = DownloadSourceRouter.destinationFor(
      const DownloadSourceDescriptor(
        type: DownloadSourceType.recommendations,
        sourceId: 'self',
        title: 'Recommendations',
      ),
    );

    expect(likes, isA<LikeScreen>());
    expect(recommendations, isA<ShareScreen>());
  });

  test('invalid or unsupported source returns a local navigation failure', () {
    expect(
      DownloadSourceRouter.destinationFor(
        const DownloadSourceDescriptor(
          type: DownloadSourceType.postAll,
          sourceId: 'invalid',
          title: 'Invalid post',
        ),
      ),
      isNull,
    );
    expect(
      DownloadSourceRouter.destinationFor(
        const DownloadSourceDescriptor(
          type: DownloadSourceType.other,
          sourceId: 'other',
          title: 'Other',
        ),
      ),
      isNull,
    );
  });
}
