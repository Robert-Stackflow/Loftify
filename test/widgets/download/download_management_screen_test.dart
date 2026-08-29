import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/download_task.dart';
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

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('zh'),
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
    final manager = DownloadTaskManager(
      store: _MemoryStore(),
      executor: _PendingExecutor(),
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    await manager.enqueueBatch(
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
    expect(tester.takeException(), isNull);
  });
}
