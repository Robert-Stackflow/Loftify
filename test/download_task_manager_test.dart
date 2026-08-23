import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Models/download_task.dart';
import 'package:loftify/Utils/download_task_manager.dart';

class _MemoryDownloadTaskStore implements DownloadTaskStore {
  _MemoryDownloadTaskStore([List<DownloadTask> initial = const []])
      : records = List<DownloadTask>.from(initial);

  List<DownloadTask> records;
  int writeCount = 0;

  @override
  Future<List<DownloadTask>> read() async => List<DownloadTask>.from(records);

  @override
  Future<void> write(List<DownloadTask> tasks) async {
    writeCount++;
    records = tasks
        .map((task) => DownloadTask.fromJson(task.toJson()))
        .toList(growable: false);
  }
}

class _ControlledDownloadTaskExecutor implements DownloadTaskExecutor {
  final Map<String, Completer<DownloadTaskResult>> _completers = {};
  final Map<String, DownloadProgressCallback> _progressCallbacks = {};
  final List<String> starts = [];
  final List<String> cleaned = [];

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
    expect(restored.progress, 0.45);
    expect(restored.receivedBytes, 45);
    expect(restored.totalBytes, 100);
    expect(restored.isActive, isTrue);
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
    expect(executor.cleaned, contains(failed.id));
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
}
