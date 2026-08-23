import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Widgets/Item/loftify_item_builder.dart';
import 'package:loftify/Widgets/PostDetail/comment_item.dart';
import 'package:loftify/Widgets/PostDetail/detail_bottom_bar.dart';
import 'package:loftify/Widgets/PostDetail/post_content_section.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/detail_components',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  Widget buildApp(Widget home) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          chewieProvider.setRootContext(context);
          return home;
        },
      ),
    );
  }

  test('post detail parsing tolerates missing and loosely typed fields', () {
    final data = PostDetailData.fromJson({
      'liked': 1,
      'shared': 'true',
      'post': {
        'id': '42',
        'blogId': 7.0,
        'publishTime': '123',
        'publisherUserId': null,
        'type': '1',
        'cited': 0,
        'firstImageWh': ['120', 240.5],
        'tagList': [1, 'tag'],
        'postCount': {
          'favoriteCount': '9',
          'responseCount': null,
        },
      },
    });

    expect(data.liked, isTrue);
    expect(data.shared, isTrue);
    expect(data.post?.id, 42);
    expect(data.post?.blogId, 7);
    expect(data.post?.publishTime, 123);
    expect(data.post?.firstImageWh, [120, 240]);
    expect(data.post?.tagList, ['1', 'tag']);
    expect(data.post?.postCount?.favoriteCount, 9);
    expect(data.post?.postCount?.responseCount, 0);
  });

  test('malformed comment metadata falls back to a renderable item', () {
    final comment = Comment.fromJson({
      'id': '5',
      'liked': 0,
      'content': null,
      'publisherBlogInfo': const <String, dynamic>{},
      'l2Comments': [
        <String, dynamic>{
          'publisherBlogInfo': const <String, dynamic>{},
        },
      ],
    });

    expect(comment.id, 5);
    expect(comment.content, isEmpty);
    expect(comment.publisherBlogInfo.blogId, 0);
    expect(comment.l2Comments, hasLength(1));
  });

  testWidgets('four detail actions stay separated above the safe area',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var taps = 0;

    await tester.pumpWidget(
      buildApp(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            padding: EdgeInsets.only(bottom: 24),
            viewPadding: EdgeInsets.only(bottom: 24),
          ),
          child: Scaffold(
            bottomNavigationBar: DetailBottomBar(
              children: [
                DetailActionButton(
                  icon: const Icon(Icons.favorite_outline_rounded),
                  label: 'Likes with a long label',
                  onTap: () => taps++,
                ),
                DetailActionButton(
                  icon: const Icon(Icons.thumb_up_outlined),
                  label: 'Recommendations',
                  onTap: () => taps++,
                ),
                DetailActionButton(
                  icon: const Icon(Icons.comment_outlined),
                  label: '123456 comments',
                  onTap: () => taps++,
                ),
                DetailActionButton(
                  icon: const Icon(Icons.star_border_rounded),
                  label: 'Favorites with a very long label',
                  onTap: () => taps++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DetailActionButton), findsNWidgets(4));
    expect(
      tester.getSize(find.byType(DetailBottomBar)).height,
      greaterThanOrEqualTo(88),
    );
    await tester.tap(find.text('Favorites with a very long label'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long comments and nested replies keep a bounded hierarchy',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var taps = 0;

    Widget item({required bool nested, List<Widget> replies = const []}) {
      return CommentItem(
        nested: nested,
        onTap: () => taps++,
        avatar: CircleAvatar(radius: nested ? 14 : 19),
        header: Row(
          children: [
            const Expanded(
              child: Text(
                'An exceptionally long author name that must stay bounded',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              child: const Text('Author'),
            ),
          ],
        ),
        content: const Text(
          'A long comment body that wraps over several lines without pushing '
          'the like action or nested replies outside the card boundary.',
        ),
        metadata: const Wrap(
          spacing: 4,
          children: [
            Text('2026-08-23 12:00:00'),
            Text('·'),
            Text('A very long IP location'),
          ],
        ),
        trailing: const Icon(Icons.favorite_border_rounded, size: 18),
        replies: replies,
      );
    }

    await tester.pumpWidget(
      buildApp(
        Scaffold(
          body: ListView(
            children: [
              item(nested: false, replies: [item(nested: true)]),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CommentItem), findsNWidgets(2));
    expect(find.byType(ContainerItem), findsNothing);
    expect(
      tester.getCenter(find.textContaining('An exceptionally').first).dy,
      closeTo(tester.getCenter(find.byType(CircleAvatar).first).dy, 3),
    );
    await tester.tap(find.textContaining('A long comment body').first);
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reply target is placed below the vertically centered nickname',
      (tester) async {
    final reply = Comment.fromJson({
      'id': 9,
      'content': 'Nested reply body',
      'publisherBlogInfo': {
        'blogId': 2,
        'blogName': 'alice',
        'blogNickName': 'Alice',
      },
      'replyBlogInfo': {
        'blogId': 3,
        'blogName': 'bob',
        'blogNickName': 'Bob',
      },
    });

    await tester.pumpWidget(
      buildApp(
        Scaffold(
          body: Builder(
            builder: (context) => LoftifyItemBuilder.buildL2CommentRow(
              context,
              reply,
              writerId: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Reply to Bob'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Reply to Bob')).dy,
      greaterThan(tester.getTopLeft(find.text('Alice')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('article parsing failure remains local and retryable',
      (tester) async {
    var attempts = 0;
    String failingExtractor(String _) {
      attempts++;
      throw const FormatException('broken article');
    }

    await tester.pumpWidget(
      buildApp(
        Scaffold(
          body: Column(
            children: [
              const Text('Author information remains visible'),
              PostContentSection(
                title: 'Broken article',
                content: '<broken>',
                textExtractor: failingExtractor,
              ),
              const Text('Recommendations remain visible'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Author information remains visible'), findsOneWidget);
    expect(find.text('Recommendations remain visible'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(attempts, 1);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('article extraction is cached across unrelated parent rebuilds',
      (tester) async {
    var attempts = 0;
    var content = '<p>First version</p>';
    late StateSetter rebuildParent;
    String extractor(String value) {
      attempts++;
      return value;
    }

    await tester.pumpWidget(
      buildApp(
        StatefulBuilder(
          builder: (context, setState) {
            rebuildParent = setState;
            return PostContentSection(
              title: 'Cached article',
              content: content,
              textExtractor: extractor,
            );
          },
        ),
      ),
    );
    expect(attempts, 1);

    rebuildParent(() {});
    await tester.pump();
    expect(attempts, 1);

    content = '<p>Second version</p>';
    rebuildParent(() {});
    await tester.pump();
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
}
