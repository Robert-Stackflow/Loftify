import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/download_task.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/post_batch_download_resolver.dart';
import 'package:loftify/Widgets/PostItem/general_post_item.dart';

GeneralPostItem _post({
  PostType type = PostType.image,
  List<PhotoLink> photos = const <PhotoLink>[],
  String content = '',
  int postId = 7,
}) {
  return GeneralPostItem(
    type: type,
    photoLinks: photos,
    blogId: 3,
    postId: postId,
    permalink: '',
    collectionId: 0,
    liked: false,
    blogName: 'author',
    blogNickName: 'Author',
    title: 'Post',
    digest: '',
    content: content,
    firstImageUrl: '',
    duration: 0,
    likeCount: 0,
    tags: const <String>[],
    bigAvaImg: '',
    publishTime: 1,
  );
}

PhotoLink _photo(String url) => PhotoLink(
      orign: url,
      raw: url,
      small: url,
      middle: url,
      rw: 100,
      rh: 100,
      ow: 100,
      oh: 100,
    );

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/batch_download_resolver',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  test('image cards resolve original URLs and remove duplicates', () async {
    final resolver = PostBatchDownloadResolver(
      detailLoader: ({required postId, required blogId, required blogName}) {
        fail('Image cards with media must not fetch post details');
      },
    );

    final resolution = await resolver.resolve(_post(photos: <PhotoLink>[
      _photo('//img.example.com/a.jpg?imageView&thumbnail=200x200'),
      _photo('//img.example.com/a.jpg?imageView&thumbnail=200x200'),
      _photo('https://img.example.com/b.png'),
    ]));

    expect(resolution.failed, isFalse);
    expect(resolution.requests, hasLength(2));
    expect(resolution.requests.first.url, startsWith('https://'));
    expect(resolution.requests.map((request) => request.url).toSet(),
        hasLength(2));
  });

  test('article cards resolve inline images without a detail request',
      () async {
    final resolver = PostBatchDownloadResolver(
      detailLoader: ({required postId, required blogId, required blogName}) {
        fail('Complete article HTML must not fetch post details');
      },
    );

    final resolution = await resolver.resolve(_post(
      type: PostType.article,
      content: '<p>Text</p><img src="https://img.example.com/inline.webp">',
    ));

    expect(resolution.failed, isFalse);
    expect(resolution.requests, hasLength(1));
    expect(resolution.requests.single.fileName, endsWith('.webp'));
  });

  test('invalid cards are reported without creating queue requests', () async {
    final resolver = PostBatchDownloadResolver();
    final resolution = await resolver.resolve(_post(
      type: PostType.invalid,
      postId: 0,
    ));

    expect(resolution.failed, isTrue);
    expect(resolution.requests, isEmpty);
  });

  test('video cards fetch the playable source before enqueueing', () async {
    var detailRequests = 0;
    final resolver = PostBatchDownloadResolver(
      detailLoader: (
          {required postId, required blogId, required blogName}) async {
        detailRequests++;
        return <String, dynamic>{
          'meta': <String, dynamic>{'status': 200},
          'response': <String, dynamic>{
            'posts': <dynamic>[
              <String, dynamic>{
                'post': <String, dynamic>{
                  'id': postId,
                  'blogId': blogId,
                  'publisherUserId': 9,
                  'type': 4,
                  'valid': 1,
                  'title': 'Video post',
                  'embed':
                      '{"originUrl":"https://video.example.com/source.mp4"}',
                },
              },
            ],
          },
        };
      },
    );

    final resolution = await resolver.resolve(_post(type: PostType.video));

    expect(detailRequests, 1);
    expect(resolution.failed, isFalse);
    expect(resolution.requests, hasLength(1));
    expect(resolution.requests.single.mediaType, DownloadMediaType.video);
    expect(resolution.requests.single.url, endsWith('source.mp4'));
  });
}
