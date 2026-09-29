import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/post_sequence_source.dart';

PostSequenceEntry entry(int id, {PostType type = PostType.article}) =>
    PostSequenceEntry(
      postId: id,
      blogId: 10 + id,
      blogName: 'blog-$id',
      type: type,
    );

void main() {
  test('sequence keeps unique image and article posts in display order', () {
    final source = PostSequenceSource();
    source.synchronize(
      [
        entry(1),
        entry(2, type: PostType.video),
        entry(3, type: PostType.image),
        entry(1),
        entry(4, type: PostType.invalid),
      ],
      hasMore: false,
    );

    expect(source.entries.map((item) => item.postId), [1, 3]);
    expect(source.canNavigateFrom(1, previous: true), isFalse);
    expect(source.canNavigateFrom(1, previous: false), isTrue);
  });

  test('sequence resolves previous and next around the current post', () async {
    final source = PostSequenceSource()
      ..synchronize([entry(11), entry(12), entry(13)], hasMore: false);

    expect(
      (await source.adjacentTo(12, previous: true))?.postId,
      11,
    );
    expect(
      (await source.adjacentTo(12, previous: false))?.postId,
      13,
    );
    expect(await source.adjacentTo(13, previous: false), isNull);
  });

  test('concurrent next lookups share one pagination request', () async {
    final release = Completer<void>();
    var loadCount = 0;
    late PostSequenceSource source;
    source = PostSequenceSource(
      loadMore: () async {
        loadCount++;
        await release.future;
        source.synchronize(
          [entry(21), entry(22)],
          hasMore: false,
        );
      },
    )..synchronize([entry(21)], hasMore: true);

    final first = source.adjacentTo(21, previous: false);
    final second = source.adjacentTo(21, previous: false);
    release.complete();

    expect((await first)?.postId, 22);
    expect((await second)?.postId, 22);
    expect(loadCount, 1);
  });

  test('a pagination miss remains retryable', () async {
    var loadCount = 0;
    late PostSequenceSource source;
    source = PostSequenceSource(
      loadMore: () async {
        loadCount++;
        if (loadCount == 2) {
          source.synchronize([entry(31), entry(32)], hasMore: false);
        }
      },
    )..synchronize([entry(31)], hasMore: true);

    expect(await source.adjacentTo(31, previous: false), isNull);
    expect(
      (await source.adjacentTo(31, previous: false))?.postId,
      32,
    );
    expect(loadCount, 2);
  });
}
