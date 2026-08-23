import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Widgets/PostItem/general_post_item_builder.dart';
import 'package:loftify/Widgets/PostItem/recommend_flow_item_builder.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/general_post_item',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
  });

  PhotoLink buildPhoto({
    int width = 120,
    int height = 120,
    String url = 'https://invalid.localhost/post.png',
  }) {
    return PhotoLink(
      orign: url,
      raw: url,
      small: url,
      middle: url,
      rw: width,
      rh: height,
      ow: width,
      oh: height,
    );
  }

  GeneralPostItem buildArticle({
    PostType type = PostType.article,
    List<PhotoLink> photoLinks = const [],
    String title = 'Title',
    String digest = 'Content',
    String content = 'Content',
    List<String> tags = const [],
  }) {
    return GeneralPostItem(
      type: type,
      photoLinks: photoLinks,
      blogId: 1,
      postId: 2,
      permalink: '',
      collectionId: 0,
      liked: false,
      blogName: 'tester',
      blogNickName: 'Tester',
      title: title,
      digest: digest,
      content: content,
      firstImageUrl: '',
      duration: 0,
      likeCount: 0,
      tags: tags,
      bigAvaImg: '',
      showLikeButton: false,
    );
  }

  Widget buildHost(Widget child) {
    return MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          chewieProvider.setRootContext(context);
          return Scaffold(body: child);
        },
      ),
    );
  }

  testWidgets('waterfall text posts keep all four rounded corners',
      (tester) async {
    await tester.pumpWidget(
      buildHost(WaterfallFlowPostItemWidget(item: buildArticle())),
    );
    await tester.pumpAndSettle();

    final card = tester.widget<ContainerItem>(find.byType(ContainerItem));
    expect(card.roundTop, isTrue);
    expect(card.roundBottom, isTrue);
    expect(card.radius, 12);
    expect(find.byType(InkWell), findsNothing);
    expect(
      find.ancestor(
        of: find.text('Title'),
        matching: find.byType(ContainerItem),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Tester'),
        matching: find.byType(ContainerItem),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('grid text posts keep all four rounded corners', (tester) async {
    await tester.pumpWidget(
      buildHost(
        GridPostItemWidget(
          item: buildArticle(),
          wh: 160,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = tester.widget<ContainerItem>(find.byType(ContainerItem));
    expect(card.roundTop, isTrue);
    expect(card.roundBottom, isTrue);
    expect(card.radius, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing image media falls back to the text card safely',
      (tester) async {
    await tester.pumpWidget(
      buildHost(
        WaterfallFlowPostItemWidget(
          item: buildArticle(type: PostType.image),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ContainerItem), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing media without text shows the same invalid card',
      (tester) async {
    final invalidMedia = buildArticle(
      type: PostType.image,
      title: '',
      digest: '',
      content: '',
    );
    final layouts = <Widget>[
      WaterfallFlowPostItemWidget(item: invalidMedia),
      GridPostItemWidget(item: invalidMedia, wh: 160),
      TilePostItemWidget(item: invalidMedia),
    ];

    for (final layout in layouts) {
      await tester.pumpWidget(buildHost(layout));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      final card = tester.widget<ContainerItem>(find.byType(ContainerItem));
      expect(card.roundTop, isTrue);
      expect(card.roundBottom, isTrue);
      expect(card.radius, 12);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('malformed recommendation remains a visible fallback card',
      (tester) async {
    final malformed = PostListItem(
      favorite: false,
      following: false,
      groupInfo: null,
      itemId: 42,
      itemType: 1,
      postCollection: null,
    );

    final generalItem = RecommendFlowItemBuilder.getGeneralPostItem(malformed);
    expect(generalItem.type, PostType.invalid);
    expect(generalItem.postId, 42);

    await tester.pumpWidget(
      buildHost(
        Builder(
          builder: (context) =>
              RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
            context,
            malformed,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey(42)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long titles and empty tags stay bounded in every card layout',
      (tester) async {
    final longTitle = List.filled(80, 'LongTitle').join(' ');
    final sparsePost = buildArticle(
      title: longTitle,
      digest: '',
      content: '',
      tags: const [],
    );

    await tester.pumpWidget(
      buildHost(WaterfallFlowPostItemWidget(item: sparsePost)),
    );
    await tester.pump();
    expect(tester.widget<Text>(find.text(longTitle)).maxLines, 3);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      buildHost(GridPostItemWidget(item: sparsePost, wh: 160)),
    );
    await tester.pump();
    expect(tester.widget<Text>(find.textContaining('LongTitle')).maxLines, 2);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      buildHost(
        SingleChildScrollView(
          child: TilePostItemWidget(item: sparsePost, isFirst: true),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(longTitle), findsOneWidget);
    expect(find.byType(SelectionArea), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bad ratios and failed image loads keep finite card geometry',
      (tester) async {
    final badPhoto = buildPhoto(width: 0, height: -1);
    final mediaPost = buildArticle(
      type: PostType.image,
      photoLinks: [badPhoto],
      title: '',
      digest: '',
      content: '',
    );
    final layouts = <Widget>[
      WaterfallFlowPostItemWidget(item: mediaPost),
      GridPostItemWidget(item: mediaPost, wh: 160),
      TilePostItemWidget(item: mediaPost),
    ];

    for (final layout in layouts) {
      await tester.pumpWidget(buildHost(layout));
      await tester.pump(const Duration(milliseconds: 100));

      final size = tester.getSize(find.byWidget(layout));
      expect(size.width.isFinite, isTrue);
      expect(size.height.isFinite, isTrue);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('card state follows replacement items during layout reuse',
      (tester) async {
    final first = buildArticle(title: 'First card');
    final second = buildArticle(title: 'Second card');

    await tester.pumpWidget(
      buildHost(
        WaterfallFlowPostItemWidget(
          key: const ValueKey('waterfall-card'),
          item: first,
        ),
      ),
    );
    await tester.pumpWidget(
      buildHost(
        WaterfallFlowPostItemWidget(
          key: const ValueKey('waterfall-card'),
          item: second,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Second card'), findsOneWidget);
    expect(find.text('First card'), findsNothing);

    await tester.pumpWidget(
      buildHost(
        GridPostItemWidget(
          key: const ValueKey('grid-card'),
          item: first,
          wh: 160,
        ),
      ),
    );
    await tester.pumpWidget(
      buildHost(
        GridPostItemWidget(
          key: const ValueKey('grid-card'),
          item: second,
          wh: 160,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Second card'), findsOneWidget);
    expect(find.textContaining('First card'), findsNothing);

    await tester.pumpWidget(
      buildHost(
        SingleChildScrollView(
          child: TilePostItemWidget(
            key: const ValueKey('tile-card'),
            item: first,
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      buildHost(
        SingleChildScrollView(
          child: TilePostItemWidget(
            key: const ValueKey('tile-card'),
            item: second,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Second card'), findsOneWidget);
    expect(find.text('First card'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first and following list cards retain rounded tap boundaries',
      (tester) async {
    await tester.pumpWidget(
      buildHost(
        SingleChildScrollView(
          child: Column(
            children: [
              TilePostItemWidget(item: buildArticle(), isFirst: true),
              TilePostItemWidget(item: buildArticle(title: 'Following card')),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    for (final widget in tester.widgetList<TilePostItemWidget>(
      find.byType(TilePostItemWidget),
    )) {
      final cardFinder = find.descendant(
        of: find.byWidget(widget),
        matching: find.byType(InkWell),
      );
      final roundedInkWell = tester.widgetList<InkWell>(cardFinder).where(
          (inkWell) => inkWell.borderRadius == BorderRadius.circular(12));
      expect(roundedInkWell, isNotEmpty);
    }
    expect(tester.takeException(), isNull);
  });
}
