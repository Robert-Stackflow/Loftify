import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/download_task.dart';
import 'package:loftify/Screens/Download/download_group_detail_screen.dart';
import 'package:loftify/Screens/Download/download_management_screen.dart';
import 'package:loftify/Utils/download_task_manager.dart';
import 'package:loftify/generated/app_localizations.dart';

class _MemoryStore implements DownloadTaskStore {
  List<DownloadTask> tasks = <DownloadTask>[];
  List<DownloadGroup> groups = <DownloadGroup>[];

  @override
  Future<List<DownloadTask>> read() async => tasks;

  @override
  Future<List<DownloadGroup>> readGroups() async => groups;

  @override
  Future<void> write(List<DownloadTask> value) async {
    tasks = List<DownloadTask>.from(value);
  }

  @override
  Future<void> writeGroups(List<DownloadGroup> value) async {
    groups = List<DownloadGroup>.from(value);
  }
}

class _PendingExecutor extends DownloadTaskExecutor {
  @override
  Future<DownloadTaskResult> run(
    DownloadTask task, {
    required CancelToken cancelToken,
    required DownloadProgressCallback onProgress,
  }) {
    return Completer<DownloadTaskResult>().future;
  }

  @override
  Future<void> deleteTemporaryFiles(DownloadTask task) async {}
}

Widget _host(
  Widget child, {
  Locale locale = const Locale('zh'),
}) =>
    MaterialApp(
      locale: locale,
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
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
      '${Directory.current.path}/build/test_hive/download_management_screen',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('download manager shows one parent instead of flat child tasks',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manager = DownloadTaskManager(
      store: _MemoryStore(),
      executor: _PendingExecutor(),
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    final result = await manager.enqueueBatch(
      const <DownloadRequest>[
        DownloadRequest(
          url: 'https://example.com/first.jpg',
          fileName: 'first.jpg',
          mediaType: DownloadMediaType.image,
          title: 'First child',
        ),
        DownloadRequest(
          url: 'https://example.com/second.jpg',
          fileName: 'second.jpg',
          mediaType: DownloadMediaType.image,
          title: 'Second child',
        ),
      ],
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.collection,
        sourceId: '42',
        title: 'Parent collection',
      ),
    );

    await tester.pumpWidget(
      _host(DownloadManagementScreen(manager: manager)),
    );
    await tester.pump();

    expect(find.text('Parent collection'), findsOneWidget);
    expect(find.text('合集'), findsOneWidget);
    expect(find.text('First child'), findsNothing);
    expect(find.text('Second child'), findsNothing);
    expect(find.text('first.jpg'), findsNothing);
    expect(find.text('second.jpg'), findsNothing);
    expect(find.textContaining('/ 2'), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(
            find.byKey(ValueKey('download-group-${result.group!.id}')),
          )
          .onTap,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('group detail shows child progress and controls on narrow phones',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manager = DownloadTaskManager(
      store: _MemoryStore(),
      executor: _PendingExecutor(),
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    final result = await manager.enqueueBatch(
      const <DownloadRequest>[
        DownloadRequest(
          url: 'https://example.com/detail-first.jpg',
          fileName: 'detail-first.jpg',
          mediaType: DownloadMediaType.image,
          title: 'First child',
        ),
        DownloadRequest(
          url: 'https://example.com/detail-second.jpg',
          fileName: 'detail-second.jpg',
          mediaType: DownloadMediaType.image,
          title: 'Second child',
        ),
      ],
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.collection,
        sourceId: '42',
        title: 'Parent collection',
      ),
    );

    await tester.pumpWidget(
      _host(
        DownloadGroupDetailScreen(
          groupId: result.group!.id,
          manager: manager,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('下载任务详情'), findsOneWidget);
    expect(find.text('查看原内容'), findsOneWidget);
    expect(find.text('First child'), findsOneWidget);
    expect(find.text('Second child'), findsOneWidget);
    expect(find.text('资源列表'), findsOneWidget);
    expect(find.byKey(const Key('download-group-pause')), findsOneWidget);
    expect(find.byKey(const Key('download-group-cancel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('download tiles remain usable at two-times text scale',
      (tester) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manager = DownloadTaskManager(
      store: _MemoryStore(),
      executor: _PendingExecutor(),
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    await manager.enqueueBatch(
      const <DownloadRequest>[
        DownloadRequest(
          url: 'https://example.com/large-text-group.jpg',
          fileName: 'large-text-group.jpg',
          mediaType: DownloadMediaType.image,
          title: 'A very long child title for the grouped download',
        ),
      ],
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.favoriteFolder,
        sourceId: 'large-text',
        title: 'A very long favorite folder download title',
      ),
    );
    await manager.enqueue(
      url: 'https://example.com/large-text-standalone.mp4',
      fileName: 'a-very-long-standalone-video-file-name.mp4',
      mediaType: DownloadMediaType.video,
      title: 'A very long standalone download title',
    );

    await tester.pumpWidget(
      _host(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(280, 480),
            textScaler: TextScaler.linear(2),
          ),
          child: DownloadManagementScreen(manager: manager),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();

    expect(find.text('A very long favorite folder download title'),
        findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('download-group-status'))).right,
      lessThanOrEqualTo(280),
    );
    await tester.scrollUntilVisible(
      find.text('A very long standalone download title'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('download-task-actions')),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    expect(find.text('A very long standalone download title'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('download-task-status'))).right,
      lessThanOrEqualTo(280),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('download-task-actions'))).right,
      lessThanOrEqualTo(280),
    );
    expect(tester.takeException(), isNull);
  });
}
