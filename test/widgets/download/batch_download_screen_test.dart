import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/download_task.dart';
import 'package:loftify/Screens/Download/batch_download_screen.dart';
import 'package:loftify/Utils/download_task_manager.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/post_batch_download_resolver.dart';
import 'package:loftify/Widgets/PostItem/general_post_item.dart';
import 'package:loftify/generated/app_localizations.dart';

class _FakeResolver extends PostBatchDownloadResolver {
  _FakeResolver()
      : super(
          detailLoader: (
                  {required postId,
                  required blogId,
                  required blogName}) async =>
              <String, dynamic>{},
        );

  @override
  Future<PostDownloadResolution> resolve(GeneralPostItem item) async {
    return PostDownloadResolution(
      postId: item.postId,
      requests: <DownloadRequest>[
        DownloadRequest(
          url: 'https://example.com/${item.postId}.jpg',
          fileName: '${item.postId}.jpg',
          mediaType: DownloadMediaType.image,
        ),
      ],
    );
  }
}

class _FakeManager extends DownloadTaskManager {
  List<DownloadRequest> requests = <DownloadRequest>[];
  DownloadSourceDescriptor? source;

  @override
  Future<DownloadBatchResult> enqueueBatch(
    Iterable<DownloadRequest> requests, {
    DownloadSourceDescriptor? source,
    int unavailableCount = 0,
  }) async {
    this.requests = requests.toList(growable: false);
    this.source = source;
    return DownloadBatchResult(
      requestedCount: this.requests.length,
      queuedCount: this.requests.length,
      skippedCount: 0,
      invalidCount: 0,
      requeuedCount: 0,
      tasks: const <DownloadTask>[],
    );
  }
}

GeneralPostItem _item(int id) => GeneralPostItem(
      type: PostType.article,
      photoLinks: const [],
      blogId: 1,
      postId: id,
      permalink: '',
      collectionId: 0,
      liked: false,
      blogName: 'author',
      blogNickName: 'Author',
      title: 'Post $id',
      digest: '',
      content: '',
      firstImageUrl: '',
      duration: 0,
      likeCount: 0,
      tags: const [],
      bigAvaImg: '',
    );

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('zh'),
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
      navigatorKey: chewieProvider.globalNavigatorKey,
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          chewieProvider.setRootContext(context);
          return child;
        },
      ),
    );

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/batch_download_screen',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('partial selection and select-all loading stay synchronized',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var loadAllCount = 0;

    await tester.pumpWidget(_host(BatchDownloadScreen(
      sourceTitle: '测试集合',
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.collection,
        sourceId: '42',
        title: '测试集合',
      ),
      initialItems: <GeneralPostItem>[_item(1), _item(2)],
      loadAllItems: () async {
        loadAllCount++;
        return <GeneralPostItem>[_item(1), _item(2), _item(3)];
      },
      resolver: _FakeResolver(),
      manager: _FakeManager(),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post 1'));
    await tester.pump();
    expect(find.textContaining('已选择 1 / 2'), findsWidgets);

    await tester.tap(find.byType(CheckboxItem));
    await tester.pumpAndSettle();
    expect(loadAllCount, 1);
    expect(find.text('Post 3'), findsOneWidget);
    expect(find.textContaining('已选择 3 / 3'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmed resources show an enqueue summary', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final manager = _FakeManager();
    await tester.pumpWidget(_host(BatchDownloadScreen(
      sourceTitle: '测试集合',
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.collection,
        sourceId: '42',
        title: '测试集合',
      ),
      initialItems: <GeneralPostItem>[_item(1), _item(2)],
      resolver: _FakeResolver(),
      manager: manager,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxItem));
    await tester.pump();
    await tester.tap(find.text('下载').last);
    await tester.pumpAndSettle();

    expect(manager.requests, hasLength(2));
    expect(manager.source?.stableKey, 'collection:42');
    expect(find.textContaining('已加入 2 项'), findsOneWidget);
    expect(find.text('下载管理'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
