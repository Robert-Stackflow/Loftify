import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/Design/loftify_reading.dart';
import 'package:loftify/Widgets/Item/loftify_item_builder.dart';
import 'package:loftify/Widgets/PostDetail/comment_item.dart';
import 'package:loftify/Widgets/PostDetail/comment_content.dart';
import 'package:loftify/Widgets/PostDetail/detail_bottom_bar.dart';
import 'package:loftify/Widgets/PostDetail/post_content_section.dart';
import 'package:loftify/Widgets/PostDetail/post_download_action_icon.dart';
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

  Widget buildApp(Widget home, {bool dark = false}) {
    return MaterialApp(
      key: ValueKey(dark),
      theme: LoftifyTheme.build(
        dark
            ? ChewieThemeColorData.defaultDarkThemes.first
            : ChewieThemeColorData.defaultLightThemes.first,
      ),
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

  test('missing image base URL does not create an invalid empty scheme', () {
    expect(WebUtil.getBaseUrl('').toString(), isEmpty);
    expect(WebUtil.getBaseUrl('relative/path').toString(), isEmpty);
    expect(WebUtil.getBaseUrl('://').toString(), isEmpty);
    expect(
      WebUtil.getBaseUrl('https://yyxzzhxb.lofter.com/post/1ece729f_2b4802463')
          .toString(),
      'https://yyxzzhxb.lofter.com',
    );
  });

  testWidgets('post body image does not replace content with a URI error',
      (tester) async {
    await tester.pumpWidget(buildApp(
      const Scaffold(
        body: SingleChildScrollView(
          child: PostContentSection(
            title: 'Image post',
            content: '<p>Before image</p><img src="https://example.com/a.png">',
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.textContaining('Error rendering content'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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

  test('incomplete emoji metadata does not discard its comment', () {
    final comment = Comment.fromJson({
      'content': 'Text [smile]',
      'emotes': [
        {'id': '10000', 'name': '[smile]', 'url': '//example.com/smile.png'},
        {'name': null, 'url': null},
      ],
    });
    expect(comment.emotes.first.id, 10000);
    expect(comment.emotes.first.sizeType, 0);
    expect(comment.emotes.last.name, isEmpty);
  });

  testWidgets('comment mentions stay on the text baseline and keep navigation',
      (tester) async {
    const url = 'https://www.lofter.com/mentionredirect.do?blogId=2923652384';
    final processUrl = UriUtil.processUrl;
    String? openedUrl;
    UriUtil.processUrl =
        (context, url, {bool pass = false, bool quiet = false}) async {
      openedUrl = url;
      return true;
    };
    addTearDown(() => UriUtil.processUrl = processUrl);
    final comment = Comment.fromJson({
      'content': '前文<a loftermentionblogid="2923652384" href="$url" '
          'class="f-atbox s-fc2" target="_blank">@Z-尘</a>后文',
    });
    await tester.pumpWidget(buildApp(Scaffold(
      body: SizedBox(width: 280, child: CommentContent(comment: comment)),
    )));
    await tester.pump();
    final text = find.byWidgetPredicate((widget) =>
        widget is RichText && widget.text.toPlainText() == '前文@Z-尘后文');
    expect(text, findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    final paragraph = tester.renderObject<RenderParagraph>(text);
    final before = paragraph
        .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 2))
        .first;
    final mention = paragraph
        .getBoxesForSelection(
            const TextSelection(baseOffset: 2, extentOffset: 6))
        .first;
    expect(mention.top, closeTo(before.top, 1));
    expect(mention.bottom, closeTo(before.bottom, 1));
    expect(tester.getSize(find.byType(CustomHtmlWidget)).height, lessThan(32));
    await tester.tapAt(paragraph.localToGlobal(mention.toRect().center));
    await tester.pump();
    expect(openedUrl, url);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'long comment links wrap within narrow content at large text scale',
      (tester) async {
    final comment = Comment.fromJson({
      'content': '前文<a href="https://example.com">这是一条很长的链接文字需要在评论区域自然换行</a>后文',
    });
    await tester.pumpWidget(buildApp(Scaffold(
      body: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: SizedBox(width: 160, child: CommentContent(comment: comment)),
      ),
    )));
    await tester.pump();
    expect(tester.getSize(find.byType(CustomHtmlWidget)).width, 160);
    expect(
        tester.getSize(find.byType(CustomHtmlWidget)).height, greaterThan(40));
    expect(find.byType(Icon), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('comment picture placeholders use a full rounded themed surface',
      (tester) async {
    final comment = Comment.fromJson({
      'content': '[图片]',
      'images': [
        {'orign': 'https://example.com/placeholder.png', 'ow': 400, 'oh': 200}
      ],
    });
    for (final dark in [false, true]) {
      await tester.pumpWidget(buildApp(
          Scaffold(
            body: CommentContent(comment: comment),
          ),
          dark: dark));
      final placeholder =
          find.byKey(const ValueKey('comment-image-placeholder'));
      expect(placeholder, findsOneWidget);
      expect(tester.getSize(placeholder), const Size(200, 100));
      final box =
          tester.widget<DecoratedBox>(placeholder).decoration as BoxDecoration;
      final context = tester.element(placeholder);
      expect(
          box.color,
          Theme.of(context)
              .extension<LoftifyDesignThemeData>()!
              .colors
              .surfaceMuted);
      expect(box.borderRadius, BorderRadius.circular(8));
      expect(find.byIcon(Icons.image_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  // Shape returned by /comment/l1/hotnew.json for comment 7131656534.
  const stickerUrl = 'https://imglf3.lf127.net/img/7e4fb8d0ab6d9e4f/'
      'SmFTRmhPQ2N4cVdaYmUxR1Btb2VCNGoveThSdmZmZ0YxQU1qdklVeHFIND0.jpg';
  Map<String, dynamic> uploadedStickerFixture() => {
        'id': 7131656534,
        'content': '三只我都要了！[表情]',
        'images': [
          {'orign': stickerUrl, 'ow': 198, 'oh': 142, 'raw': null, 'type': 1},
        ],
      };

  test('uploaded stickers survive parsing and serialization without emotes',
      () {
    final comment = Comment.fromJson(uploadedStickerFixture());
    expect(comment.emotes, isEmpty);
    expect(comment.images.single.url, stickerUrl);
    expect(comment.images.single.ow, 198);
    expect(comment.images.single.oh, 142);
    expect(comment.images.single.raw, isEmpty);
    final restored = Comment.fromJson(comment.toJson());
    expect(restored.images.single.url, stickerUrl);
    expect(restored.images.single.type, 1);
    expect(
        Comment.fromJson({
          'images': [null, false]
        }).images,
        isEmpty);
    expect(Comment.fromJson({'images': null}).images, isEmpty);
  });

  testWidgets('real uploaded sticker replaces placeholder in comment and reply',
      (tester) async {
    final comment = Comment.fromJson({
      ...uploadedStickerFixture(),
      'l2Count': 1,
      'l2Comments': [uploadedStickerFixture()],
    });
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp(Scaffold(
      body: SingleChildScrollView(
        child: Builder(
          builder: (context) => LoftifyItemBuilder.buildCommentRow(
            context,
            comment,
            writerId: 1,
          ),
        ),
      ),
    )));
    await tester.pump();
    final stickers = find.byWidgetPredicate((widget) =>
        widget is CachedNetworkImage && widget.imageUrl == stickerUrl);
    expect(stickers, findsNWidgets(2));
    for (final element in stickers.evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.width, 120);
      expect(size.height, closeTo(120 * 142 / 198, 0.01));
    }
    for (final widget in tester.widgetList<CustomHtmlWidget>(
      find.byType(CustomHtmlWidget),
    )) {
      expect(widget.content, contains('三只我都要了！<img'));
      expect(widget.content, contains('data-comment-sticker="true"'));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'mixed attachments and named emotes keep order and missing markers',
      (tester) async {
    final comment = Comment.fromJson({
      'content': 'Missing[图片]A[图片]B[smile]C[表情]D[图片]',
      'emotes': [
        {'name': '[smile]', 'url': 'https://example.com/smile.png'}
      ],
      'images': [
        {'orign': '://'},
        {'orign': '//example.com/photo.png', 'ow': '800', 'oh': 400},
        {
          'raw': 'https://example.com/sticker.gif',
          'ow': 100,
          'oh': 100,
          'type': 1
        },
      ],
    });
    await tester.pumpWidget(buildApp(Scaffold(
      body: CommentContent(comment: comment),
    )));
    await tester.pump();
    final html = tester.widget<CustomHtmlWidget>(find.byType(CustomHtmlWidget));
    expect(html.content, contains('A<img'));
    expect(html.content, startsWith('Missing[图片]A<img'));
    expect(html.content, contains('B<img'));
    expect(html.content, contains('C<img'));
    expect(html.content, endsWith('D[图片]'));
    final images = tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .toList();
    expect(images.map((image) => image.imageUrl), [
      'https://example.com/photo.png',
      'https://example.com/smile.png',
      'https://example.com/sticker.gif',
    ]);
    expect(images.first.width, 200);
    expect(images.first.height, 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'attachments without markers render while invalid ones preserve text',
      (tester) async {
    final comment = Comment.fromJson({
      'content': 'Attachment',
      'images': [
        {'orign': stickerUrl, 'type': 1}
      ],
    });
    await tester
        .pumpWidget(buildApp(Scaffold(body: CommentContent(comment: comment))));
    await tester.pump();
    expect(find.byType(CachedNetworkImage), findsOneWidget);
    final invalid = Comment.fromJson({
      'content': 'Keep [表情]',
      'images': [
        {'orign': '://'},
        {'orign': null}
      ],
    });
    await tester
        .pumpWidget(buildApp(Scaffold(body: CommentContent(comment: invalid))));
    await tester.pump();
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(
        tester.widget<CustomHtmlWidget>(find.byType(CustomHtmlWidget)).content,
        'Keep [表情]');
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 1000.0]) {
    testWidgets('comment and reply media stay visible and bounded at $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Map<String, dynamic> fixture(int id) => {
            'id': id,
            'content': 'Before [smile] after [smile]'
                '<img src="" data-src="//example.com/comment.png" alt="photo">',
            'emotes': [
              {
                'name': '[smile]',
                'url': '//example.com/smile.png',
                'sizeType': 1,
              },
              {'name': '', 'url': 'https://example.com/unused.png'},
            ],
          };
      final comment = Comment.fromJson({
        ...fixture(1),
        'l2Count': 1,
        'l2Comments': [fixture(2)],
      });
      await tester.pumpWidget(buildApp(Scaffold(
        body: SingleChildScrollView(
          child: Builder(
            builder: (context) => LoftifyItemBuilder.buildCommentRow(
              context,
              comment,
              writerId: 1,
            ),
          ),
        ),
      )));
      await tester.pump();
      final emoji = find.byWidgetPredicate((widget) =>
          widget is CachedNetworkImage &&
          widget.imageUrl == 'https://example.com/smile.png');
      final photos = find.byWidgetPredicate((widget) =>
          widget is CachedNetworkImage &&
          widget.imageUrl == 'https://example.com/comment.png');
      expect(emoji, findsNWidgets(4));
      expect(photos, findsNWidgets(2));
      for (final element in emoji.evaluate()) {
        expect(
            tester.getSize(find.byWidget(element.widget)), const Size(38, 38));
        expect(
          element.findAncestorWidgetOfExactType<Padding>()?.padding,
          const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        );
      }
      for (final element in photos.evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, lessThanOrEqualTo(200));
        expect(size.height, 200);
      }
      expect(find.textContaining('Error rendering content'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('emoji replacement preserves HTML attributes and bad media text',
      (tester) async {
    final comment = Comment.fromJson({
      'content': '<a href="https://example.com/[smile]">[smile]</a>'
          '<img src="://" alt="[bad image]"> [unknown]',
      'emotes': [
        {'name': '[smile]', 'url': 'https://example.com/smile.png?a=1&b=2'},
        {'name': '[unknown]', 'url': ''},
      ],
    });
    await tester.pumpWidget(buildApp(Scaffold(
      body: CommentContent(comment: comment),
    )));
    await tester.pump();
    final rendered =
        tester.widget<CustomHtmlWidget>(find.byType(CustomHtmlWidget));
    expect(rendered.content, contains('href="https://example.com/[smile]"'));
    expect(rendered.content, contains('a=1&amp;b=2'));
    expect(rendered.content, contains('[unknown]'));
    expect(find.text('[bad image]'), findsOneWidget);
    expect(find.textContaining('Error rendering content'), findsNothing);
    expect(tester.takeException(), isNull);
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

  testWidgets('reading content keeps a comfortable measure on every width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildApp(
        Scaffold(
          body: Builder(
            builder: (context) => PostContentSection(
              title: 'A deliberately long article title',
              content: '<p>Reading body</p>',
              url: 'https://yyxzzhxb.lofter.com/post/1ece729f_2b4802463',
              style: context.design.typography.readingBody,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LoftifyReadingFrame), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('loftify-reading-frame'))).width,
      768,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('loftify-reading-content')))
          .width,
      720,
    );
    final html = tester.widget<CustomHtmlWidget>(find.byType(CustomHtmlWidget));
    expect(html.url, 'https://yyxzzhxb.lofter.com/post/1ece729f_2b4802463');
    expect(html.style?.fontSize, 17);
    expect(html.style?.height, 1.8);
    expect(html.heightDelta, 0);
    expect(html.letterSpacingDelta, 0);

    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey('loftify-reading-frame'))).width,
      320,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('loftify-reading-content')))
          .width,
      296,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating detail actions use the raised token surface',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        const Scaffold(
          body: Center(
            child: DetailFloatingActionRail(
              children: [
                DetailActionButton(
                  icon: Icon(Icons.favorite_outline_rounded),
                  label: 'Like',
                ),
                DetailActionButton(
                  icon: Icon(Icons.comment_outlined),
                  label: 'Comment',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('detail-floating-action-rail')),
    );
    final decoration = surface.decoration as BoxDecoration;
    final design = LoftifyTheme.build(
      ChewieThemeColorData.defaultLightThemes.first,
    ).extension<LoftifyDesignThemeData>()!;
    expect(decoration.color, design.colors.surfaceRaised);
    expect(decoration.borderRadius, BorderRadius.circular(design.radii.panel));
    expect(decoration.border!.top.color, design.colors.outline);
    expect(decoration.border!.top.width, design.borders.hairline);
    expect(decoration.boxShadow, design.shadows.floating);
    expect(find.byType(DetailActionButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      buildApp(
        const Scaffold(
          body: Center(
            child: DetailFloatingActionRail(
              children: [
                DetailActionButton(
                  icon: Icon(Icons.favorite_outline_rounded),
                  label: 'Like',
                ),
              ],
            ),
          ),
        ),
        dark: true,
      ),
    );
    await tester.pump();
    final darkDecoration = tester
        .widget<DecoratedBox>(
          find.byKey(const ValueKey('detail-floating-action-rail')),
        )
        .decoration as BoxDecoration;
    final darkDesign = LoftifyTheme.build(
      ChewieThemeColorData.defaultDarkThemes.first,
    ).extension<LoftifyDesignThemeData>()!;
    expect(darkDecoration.color, darkDesign.colors.surfaceRaised);
    expect(darkDecoration.border!.top.color, darkDesign.colors.outline);
    expect(darkDecoration.boxShadow, darkDesign.shadows.floating);
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

  testWidgets(
      'post download action reports determinate progress without Lottie',
      (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        buildApp(
          const Center(
            child: PostDownloadActionIcon(
              state: DownloadState.loading,
              progress: 0.42,
              semanticLabel: 'Downloading',
            ),
          ),
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(PostDownloadActionIcon)),
        const Size.square(PostDownloadActionIcon.visualSize),
      );
      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progress.value, closeTo(0.42, 0.001));
      expect(progress.strokeWidth, PostDownloadActionIcon.progressStrokeWidth);
      expect(tester.getSize(find.byType(CircularProgressIndicator)),
          const Size.square(18));
      expect(find.byType(ChewieIcon), findsNothing);
      expect(
          find.byKey(const ValueKey('post-download-progress')), findsOneWidget);
      final semantics = tester.getSemantics(
        find.byKey(const ValueKey('post-download-semantics')),
      );
      expect(semantics.label, 'Downloading');
      expect(semantics.value, '42%');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('post download action keeps every terminal state in one viewport',
      (tester) async {
    const cases = <DownloadState, Key>{
      DownloadState.none: ValueKey('post-download-idle'),
      DownloadState.succeed: ValueKey('post-download-success'),
      DownloadState.failed: ValueKey('post-download-failed'),
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(
        buildApp(
          Center(
            child: PostDownloadActionIcon(
              state: entry.key,
              semanticLabel: entry.key.name,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(entry.value), findsOneWidget);
      expect(
        tester.getSize(find.byType(PostDownloadActionIcon)),
        const Size.square(PostDownloadActionIcon.visualSize),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
