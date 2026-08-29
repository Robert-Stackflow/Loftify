import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Models/download_task.dart';
import 'package:loftify/Utils/download_task_manager.dart';

class _MemoryDownloadTaskStore implements DownloadTaskStore {
  _MemoryDownloadTaskStore([
    List<DownloadTask> initial = const [],
    List<DownloadGroup> initialGroups = const [],
  ])  : records = List<DownloadTask>.from(initial),
        groupRecords = List<DownloadGroup>.from(initialGroups);

  List<DownloadTask> records;
  List<DownloadGroup> groupRecords;
  int writeCount = 0;
  int groupWriteCount = 0;

  @override
  Future<List<DownloadTask>> read() async => List<DownloadTask>.from(records);

  @override
  Future<void> write(List<DownloadTask> tasks) async {
    writeCount++;
    records = tasks
        .map((task) => DownloadTask.fromJson(task.toJson()))
        .toList(growable: false);
  }

  @override
  Future<List<DownloadGroup>> readGroups() async =>
      List<DownloadGroup>.from(groupRecords);

  @override
  Future<void> writeGroups(List<DownloadGroup> groups) async {
    groupWriteCount++;
    groupRecords = groups
        .map((group) => DownloadGroup.fromJson(group.toJson()))
        .toList(growable: false);
  }
}

class _ControlledDownloadTaskExecutor extends DownloadTaskExecutor {
  final Map<String, Completer<DownloadTaskResult>> _completers = {};
  final Map<String, DownloadProgressCallback> _progressCallbacks = {};
  final List<String> starts = [];
  final List<String> cleaned = [];
  final List<String> paused = [];
  final List<String> cancelled = [];
  int initializeCount = 0;
  int networkAvailableCount = 0;

  @override
  Future<void> initialize() async {
    initializeCount++;
  }

  @override
  Future<DownloadTaskResult> run(
    DownloadTask task, {
    required CancelToken cancelToken,
    required DownloadProgressCallback onProgress,
  }) {
    starts.add(task.id);
    _progressCallbacks[task.id] = onProgress;
    final completer = Completer<DownloadTaskResult>();
    _completers[task.id] = completer;
    cancelToken.whenCancel.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          DioException.requestCancelled(
            requestOptions: RequestOptions(path: task.url),
            reason: cancelToken.cancelError,
          ),
        );
      }
    });
    return completer.future;
  }

  void emitProgress(String taskId, int received, int total) {
    _progressCallbacks[taskId]?.call(received, total);
  }

  void complete(String taskId) {
    final completer = _completers[taskId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(
        DownloadTaskResult(savedPath: '/downloads/$taskId'),
      );
    }
  }

  void fail(String taskId) {
    final completer = _completers[taskId];
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        DioException.connectionError(
          requestOptions: RequestOptions(path: taskId),
          reason: 'offline',
        ),
      );
    }
  }

  @override
  Future<bool> pause(DownloadTask task) async {
    paused.add(task.id);
    return true;
  }

  @override
  Future<void> cancel(DownloadTask task) async {
    cancelled.add(task.id);
  }

  @override
  Future<void> onNetworkAvailable() async {
    networkAvailableCount++;
  }

  @override
  Future<void> deleteTemporaryFiles(DownloadTask task) async {
    cleaned.add(task.id);
  }
}

Future<void> _settleManager() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('download task survives JSON persistence', () {
    final now = DateTime(2026, 8, 24, 10, 30);
    final source = DownloadTask(
      id: 'task-1',
      url: 'https://example.com/image.jpg',
      fileName: 'image.jpg',
      title: 'A post',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      mediaType: DownloadMediaType.image,
      status: DownloadTaskStatus.paused,
      failureKind: DownloadFailureKind.network,
      progress: 0.45,
      receivedBytes: 45,
      totalBytes: 100,
      createdAt: now,
      updatedAt: now.add(const Duration(seconds: 2)),
    );

    final restored = DownloadTask.fromJson(source.toJson());

    expect(restored.id, source.id);
    expect(restored.mediaType, DownloadMediaType.image);
    expect(restored.status, DownloadTaskStatus.paused);
    expect(restored.failureKind, DownloadFailureKind.network);
    expect(restored.progress, 0.45);
    expect(restored.receivedBytes, 45);
    expect(restored.totalBytes, 100);
    expect(restored.isActive, isTrue);
  });

  test('download group preserves source type metadata and aggregate status',
      () {
    final now = DateTime(2026, 8, 29, 10, 30);
    final source = DownloadGroup(
      id: 'group-1',
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.collection,
        sourceId: '42',
        title: 'Collection title',
        metadata: <String, String>{'collectionId': '42'},
      ),
      taskIds: const <String>['task-1', 'task-2'],
      requestedCount: 2,
      createdAt: now,
      updatedAt: now,
    );
    final restored = DownloadGroup.fromJson(source.toJson());
    final snapshot = restored.snapshot(<DownloadTask>[
      DownloadTask(
        id: 'task-1',
        url: 'https://example.com/1.jpg',
        fileName: '1.jpg',
        mediaType: DownloadMediaType.image,
        status: DownloadTaskStatus.completed,
        progress: 1,
        createdAt: now,
        updatedAt: now,
      ),
      DownloadTask(
        id: 'task-2',
        url: 'https://example.com/2.jpg',
        fileName: '2.jpg',
        mediaType: DownloadMediaType.image,
        status: DownloadTaskStatus.failed,
        progress: 0.5,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    expect(restored.source.stableKey, 'collection:42');
    expect(restored.source.metadata['collectionId'], '42');
    expect(snapshot.status, DownloadGroupStatus.partiallyFailed);
    expect(snapshot.progress, 0.75);
  });

  test('manager queues, pauses, resumes and completes a task', () async {
    final store = _MemoryDownloadTaskStore();
    final executor = _ControlledDownloadTaskExecutor();
    final manager = DownloadTaskManager(
      store: store,
      executor: executor,
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    expect(executor.initializeCount, 1);

    final task = await manager.enqueue(
      url: 'https://example.com/video.mp4',
      fileName: 'video.mp4',
      mediaType: DownloadMediaType.video,
    );
    await _settleManager();
    expect(executor.starts, <String>[task.id]);
    expect(manager.tasks.single.status, DownloadTaskStatus.downloading);

    executor.emitProgress(task.id, 25, 100);
    expect(manager.tasks.single.progress, 0.25);
    expect(manager.tasks.single.receivedBytes, 25);

    await manager.pause(task.id);
    await _settleManager();
    expect(manager.tasks.single.status, DownloadTaskStatus.paused);
    expect(executor.paused, <String>[task.id]);

    await manager.resume(task.id);
    await _settleManager();
    expect(executor.starts, <String>[task.id, task.id]);
    expect(manager.tasks.single.status, DownloadTaskStatus.downloading);

    final completion = manager.waitForCompletion(task.id);
    executor.complete(task.id);
    expect(await completion, isTrue);
    await _settleManager();
    expect(manager.tasks.single.status, DownloadTaskStatus.completed);
    expect(manager.tasks.single.progress, 1);
    expect(store.records.single.status, DownloadTaskStatus.completed);
  });

  test('manager limits concurrency and deduplicates completed resources',
      () async {
    final store = _MemoryDownloadTaskStore();
    final executor = _ControlledDownloadTaskExecutor();
    final manager = DownloadTaskManager(
      store: store,
      executor: executor,
      maxConcurrentTasks: 2,
    );
    await manager.initialize();

    final first = await manager.enqueue(
      url: 'https://example.com/1.jpg',
      fileName: '1.jpg',
      mediaType: DownloadMediaType.image,
    );
    final second = await manager.enqueue(
      url: 'https://example.com/2.jpg',
      fileName: '2.jpg',
      mediaType: DownloadMediaType.image,
    );
    final third = await manager.enqueue(
      url: 'https://example.com/3.jpg',
      fileName: '3.jpg',
      mediaType: DownloadMediaType.image,
    );
    await _settleManager();
    expect(executor.starts, hasLength(2));
    expect(executor.starts, containsAll(<String>[first.id, second.id]));

    executor.complete(first.id);
    await _settleManager();
    expect(executor.starts, contains(third.id));
    executor.complete(second.id);
    executor.complete(third.id);
    await _settleManager();

    final duplicate = await manager.enqueue(
      url: first.url,
      fileName: 'renamed.jpg',
      mediaType: DownloadMediaType.image,
    );
    expect(duplicate.id, first.id);
    expect(manager.tasks, hasLength(3));
    expect(executor.starts.where((id) => id == first.id), hasLength(1));
  });

  test('running tasks recover after restart and finished records are cleaned',
      () async {
    final now = DateTime(2026, 8, 24);
    final running = DownloadTask(
      id: 'running',
      url: 'https://example.com/running.jpg',
      fileName: 'running.jpg',
      mediaType: DownloadMediaType.image,
      status: DownloadTaskStatus.downloading,
      progress: 0.4,
      receivedBytes: 40,
      totalBytes: 100,
      createdAt: now,
      updatedAt: now,
    );
    final completed = DownloadTask(
      id: 'completed',
      url: 'https://example.com/completed.jpg',
      fileName: 'completed.jpg',
      mediaType: DownloadMediaType.image,
      status: DownloadTaskStatus.completed,
      progress: 1,
      receivedBytes: 100,
      totalBytes: 100,
      createdAt: now,
      updatedAt: now,
    );
    final store = _MemoryDownloadTaskStore(<DownloadTask>[running, completed]);
    final executor = _ControlledDownloadTaskExecutor();
    final manager = DownloadTaskManager(store: store, executor: executor);

    await manager.initialize();
    await _settleManager();
    expect(executor.starts, <String>['running']);
    expect(
      manager.tasks.firstWhere((task) => task.id == 'running').status,
      DownloadTaskStatus.downloading,
    );

    await manager.clearFinished();
    expect(manager.tasks.map((task) => task.id), isNot(contains('completed')));
    expect(executor.cleaned, contains('completed'));
  });

  test('failed tasks remain retryable and cancelled tasks clean partial data',
      () async {
    final executor = _ControlledDownloadTaskExecutor();
    final manager = DownloadTaskManager(
      store: _MemoryDownloadTaskStore(),
      executor: executor,
      errorLogger: (_, __, ___) {},
      maxConcurrentTasks: 1,
    );
    await manager.initialize();

    final failed = await manager.enqueue(
      url: 'https://example.com/failure.jpg',
      fileName: 'failure.jpg',
      mediaType: DownloadMediaType.image,
    );
    await _settleManager();
    executor.fail(failed.id);
    await _settleManager();
    expect(manager.tasks.single.status, DownloadTaskStatus.failed);
    expect(manager.tasks.single.errorMessage, isNotEmpty);

    await manager.retry(failed.id);
    await _settleManager();
    expect(executor.starts.where((id) => id == failed.id), hasLength(2));
    await manager.cancel(failed.id);
    await _settleManager();
    expect(manager.tasks.single.status, DownloadTaskStatus.cancelled);
    expect(executor.cancelled, contains(failed.id));
    expect(executor.cleaned, contains(failed.id));
  });

  test('network failures resume automatically after connectivity returns',
      () async {
    final changes = StreamController<List<ConnectivityResult>>.broadcast();
    final executor = _ControlledDownloadTaskExecutor();
    final manager = DownloadTaskManager(
      store: _MemoryDownloadTaskStore(),
      executor: executor,
      errorLogger: (_, __, ___) {},
      monitorConnectivity: true,
      connectivityCheck: () async => <ConnectivityResult>[
        ConnectivityResult.none,
      ],
      connectivityChanges: changes.stream,
    );
    await manager.initialize();

    final task = await manager.enqueue(
      url: 'https://example.com/reconnect.jpg',
      fileName: 'reconnect.jpg',
      mediaType: DownloadMediaType.image,
    );
    await _settleManager();
    executor.fail(task.id);
    await _settleManager();
    expect(manager.tasks.single.status, DownloadTaskStatus.failed);
    expect(
      manager.tasks.single.failureKind,
      DownloadFailureKind.network,
    );

    changes.add(<ConnectivityResult>[ConnectivityResult.wifi]);
    await _settleManager();
    expect(executor.networkAvailableCount, 1);
    expect(executor.starts.where((id) => id == task.id), hasLength(2));
    expect(manager.tasks.single.failureKind, isNull);

    manager.dispose();
    await changes.close();
  });

  test('unsafe and oversized file names are normalized before persistence',
      () async {
    final manager = DownloadTaskManager(
      store: _MemoryDownloadTaskStore(),
      executor: _ControlledDownloadTaskExecutor(),
    );
    await manager.initialize();

    final task = await manager.enqueue(
      url: 'https://example.com/name.jpg',
      fileName: '${'very-long:' * 30}image?.jpg',
      mediaType: DownloadMediaType.image,
    );

    expect(task.fileName.length, lessThanOrEqualTo(180));
    expect(task.fileName, endsWith('.jpg'));
    expect(task.fileName, isNot(contains(RegExp(r'[\\/:*?"<>|]'))));
  });

  test('batch enqueue deduplicates, validates and persists atomically',
      () async {
    final store = _MemoryDownloadTaskStore();
    final executor = _ControlledDownloadTaskExecutor();
    final manager = DownloadTaskManager(
      store: store,
      executor: executor,
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    final writesBeforeBatch = store.writeCount;

    final result = await manager.enqueueBatch(const <DownloadRequest>[
      DownloadRequest(
        url: 'https://example.com/a.jpg',
        fileName: 'a.jpg',
        mediaType: DownloadMediaType.image,
      ),
      DownloadRequest(
        url: ' https://example.com/a.jpg ',
        fileName: 'duplicate.jpg',
        mediaType: DownloadMediaType.image,
      ),
      DownloadRequest(
        url: '',
        fileName: 'invalid.jpg',
        mediaType: DownloadMediaType.image,
      ),
      DownloadRequest(
        url: 'ftp://example.com/file.zip',
        fileName: 'file.zip',
        mediaType: DownloadMediaType.file,
      ),
      DownloadRequest(
        url: 'https://example.com/b.mp4',
        fileName: 'b.mp4',
        mediaType: DownloadMediaType.video,
      ),
    ]);

    expect(result.requestedCount, 5);
    expect(result.queuedCount, 2);
    expect(result.newTaskCount, 2);
    expect(result.skippedCount, 1);
    expect(result.invalidCount, 2);
    expect(manager.tasks, hasLength(2));
    expect(store.writeCount, writesBeforeBatch + 1);
  });

  test('batch enqueue creates and restores one typed parent group', () async {
    final store = _MemoryDownloadTaskStore();
    final manager = DownloadTaskManager(
      store: store,
      executor: _ControlledDownloadTaskExecutor(),
      maxConcurrentTasks: 1,
    );
    await manager.initialize();

    final result = await manager.enqueueBatch(
      const <DownloadRequest>[
        DownloadRequest(
          url: 'https://example.com/group-a.jpg',
          fileName: 'group-a.jpg',
          mediaType: DownloadMediaType.image,
        ),
        DownloadRequest(
          url: 'https://example.com/group-b.jpg',
          fileName: 'group-b.jpg',
          mediaType: DownloadMediaType.image,
        ),
      ],
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.grain,
        sourceId: '88',
        title: 'A grain',
        metadata: <String, String>{'grainId': '88'},
      ),
      unavailableCount: 1,
    );

    expect(result.group, isNotNull);
    expect(manager.groups, hasLength(1));
    expect(manager.groups.single.taskIds, hasLength(2));
    expect(manager.groups.single.unavailableCount, 1);
    expect(store.groupRecords.single.source.type, DownloadSourceType.grain);

    final restored = DownloadTaskManager(
      store: store,
      executor: _ControlledDownloadTaskExecutor(),
      maxConcurrentTasks: 1,
    );
    await restored.initialize();
    expect(restored.groups.single.source.stableKey, 'grain:88');
    expect(restored.groups.single.taskIds, hasLength(2));
  });

  test('group controls pause resume cancel and retry matching child tasks',
      () async {
    final now = DateTime(2026, 8, 29, 16);
    DownloadTask task(String id, DownloadTaskStatus status) => DownloadTask(
          id: id,
          url: 'https://example.com/$id.jpg',
          fileName: '$id.jpg',
          mediaType: DownloadMediaType.image,
          status: status,
          createdAt: now,
          updatedAt: now,
        );

    final store = _MemoryDownloadTaskStore(
      <DownloadTask>[
        task('queued', DownloadTaskStatus.queued),
        task('paused', DownloadTaskStatus.paused),
        task('failed', DownloadTaskStatus.failed),
        task('standalone', DownloadTaskStatus.completed),
      ],
      <DownloadGroup>[
        DownloadGroup(
          id: 'group-controls',
          source: const DownloadSourceDescriptor(
            type: DownloadSourceType.collection,
            sourceId: '42',
            title: 'Group controls',
          ),
          taskIds: const <String>['paused', 'queued', 'failed'],
          requestedCount: 3,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    final executor = _ControlledDownloadTaskExecutor();
    final manager = DownloadTaskManager(
      store: store,
      executor: executor,
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    await _settleManager();

    expect(
      manager.tasksForGroup('group-controls').map((task) => task.id),
      <String>['paused', 'queued', 'failed'],
    );
    expect(manager.snapshotForGroup('missing'), isNull);

    await manager.pauseGroup('group-controls');
    await _settleManager();
    expect(
      manager
          .tasksForGroup('group-controls')
          .take(2)
          .map((task) => task.status),
      everyElement(DownloadTaskStatus.paused),
    );

    await manager.resumeGroup('group-controls');
    await _settleManager();
    expect(
      manager
          .tasksForGroup('group-controls')
          .take(2)
          .every((task) => task.isActive),
      isTrue,
    );

    await manager.cancelGroup('group-controls');
    await _settleManager();
    expect(
      manager
          .tasksForGroup('group-controls')
          .take(2)
          .map((task) => task.status),
      everyElement(DownloadTaskStatus.cancelled),
    );

    await manager.retryFailedGroup('group-controls');
    await _settleManager();
    expect(
      manager.tasksForGroup('group-controls').every((task) => task.isActive),
      isTrue,
    );
    expect(
      manager.tasks.firstWhere((task) => task.id == 'standalone').status,
      DownloadTaskStatus.completed,
    );
  });

  test('batch enqueue skips completed tasks and requeues failed tasks',
      () async {
    final now = DateTime(2026, 8, 24);
    final completed = DownloadTask(
      id: 'completed',
      url: 'https://example.com/completed.jpg',
      fileName: 'completed.jpg',
      mediaType: DownloadMediaType.image,
      status: DownloadTaskStatus.completed,
      progress: 1,
      createdAt: now,
      updatedAt: now,
    );
    final failed = DownloadTask(
      id: 'failed',
      url: 'https://example.com/failed.jpg',
      fileName: 'failed.jpg',
      mediaType: DownloadMediaType.image,
      status: DownloadTaskStatus.failed,
      progress: 0.6,
      receivedBytes: 60,
      totalBytes: 100,
      errorMessage: 'offline',
      failureKind: DownloadFailureKind.network,
      createdAt: now,
      updatedAt: now,
    );
    final executor = _ControlledDownloadTaskExecutor();
    final manager = DownloadTaskManager(
      store: _MemoryDownloadTaskStore(<DownloadTask>[completed, failed]),
      executor: executor,
      maxConcurrentTasks: 1,
    );
    await manager.initialize();

    final result = await manager.enqueueBatch(const <DownloadRequest>[
      DownloadRequest(
        url: 'https://example.com/completed.jpg',
        fileName: 'completed-again.jpg',
        mediaType: DownloadMediaType.image,
      ),
      DownloadRequest(
        url: 'https://example.com/failed.jpg',
        fileName: 'failed-again.jpg',
        mediaType: DownloadMediaType.image,
      ),
    ]);

    expect(result.queuedCount, 1);
    expect(result.requeuedCount, 1);
    expect(result.skippedCount, 1);
    final retried = manager.tasks.firstWhere((task) => task.id == 'failed');
    expect(retried.progress, 0);
    expect(retried.errorMessage, isNull);
    expect(retried.failureKind, isNull);
    await _settleManager();
    expect(executor.starts, contains('failed'));
  });
}
