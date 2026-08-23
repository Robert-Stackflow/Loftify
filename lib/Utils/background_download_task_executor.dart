import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:background_downloader/background_downloader.dart' as background;
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path_util;

import '../Models/download_task.dart';
import 'download_task_executor.dart';
import 'hive_util.dart';

class BackgroundDownloadTaskExecutor implements DownloadTaskExecutor {
  static const String _group = 'loftify_downloads';
  static const String _groupNotificationId = 'loftify_download_group';

  final background.FileDownloader _downloader = background.FileDownloader();
  final Map<String, _BackgroundDownloadOperation> _operations = {};
  StreamSubscription<background.TaskUpdate>? _updatesSubscription;
  Future<void>? _initialization;
  bool _notificationPermissionRequested = false;

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    await _downloader.ready;
    _updatesSubscription ??= _downloader.updates.listen(
      _handleUpdate,
      onError: (Object error, StackTrace stackTrace) {
        _logError(
            'Background download update stream failed', error, stackTrace);
      },
    );
    _downloader.configureNotificationForGroup(
      _group,
      running: const background.TaskNotification(
        'Loftify 正在下载',
        '{numFinished}/{numTotal} · {progress}',
      ),
      complete: const background.TaskNotification(
        'Loftify 下载完成',
        '已完成 {numTotal} 个下载任务',
      ),
      error: const background.TaskNotification(
        'Loftify 下载遇到问题',
        '{numFailed}/{numTotal} 个任务失败，可在下载管理中重试',
      ),
      paused: const background.TaskNotification(
        'Loftify 下载已暂停',
        '可在下载管理中继续',
      ),
      progressBar: true,
      groupNotificationId: _groupNotificationId,
    );
    await _downloader.configure(
      globalConfig: (
        background.Config.holdingQueue,
        (2, 2, 2),
      ),
      androidConfig: <(String, dynamic)>[
        (
          background.Config.runInForeground,
          background.Config.always,
        ),
        (background.Config.useCacheDir, background.Config.never),
      ],
    );
    await _downloader.start(
      doTrackTasks: true,
      markDownloadedComplete: true,
      doRescheduleKilledTasks: true,
      autoCleanDatabase: false,
    );
  }

  @override
  Future<DownloadTaskResult> run(
    DownloadTask task, {
    required CancelToken cancelToken,
    required DownloadProgressCallback onProgress,
  }) async {
    await initialize();
    await _requestNotificationPermissionOnce();
    final nativeTask = _toNativeTask(task);
    final operation = _BackgroundDownloadOperation(
      appTask: task,
      nativeTask: nativeTask,
      onProgress: onProgress,
    );
    _operations[task.id] = operation;
    unawaited(cancelToken.whenCancel.then((_) {
      if (!operation.completer.isCompleted) {
        return _stopFromCancelToken(operation, cancelToken);
      }
    }));

    try {
      await _startOrReconcile(operation);
      return await operation.completer.future;
    } finally {
      if (identical(_operations[task.id], operation)) {
        _operations.remove(task.id);
      }
    }
  }

  Future<void> _startOrReconcile(
    _BackgroundDownloadOperation operation,
  ) async {
    final record = await _downloader.database.recordForId(operation.appTask.id);
    if (record == null) {
      await _enqueue(operation.nativeTask);
      return;
    }
    final recordTask = record.task;
    final nativeTask = recordTask is background.DownloadTask
        ? recordTask
        : operation.nativeTask;
    operation.nativeTask = nativeTask;
    switch (record.status) {
      case background.TaskStatus.complete:
        unawaited(_completeOperation(operation, nativeTask));
      case background.TaskStatus.paused:
        if (!await _downloader.resume(nativeTask)) {
          await _restart(operation);
        }
      case background.TaskStatus.enqueued:
      case background.TaskStatus.running:
      case background.TaskStatus.waitingToRetry:
        return;
      case background.TaskStatus.failed:
        if (!await _downloader.resume(nativeTask)) {
          await _restart(operation);
        }
      case background.TaskStatus.notFound:
      case background.TaskStatus.canceled:
        await _restart(operation);
    }
  }

  Future<void> _enqueue(background.DownloadTask task) async {
    if (!await _downloader.enqueue(task)) {
      throw const DownloadExecutionException(
        message: '无法将任务加入系统下载队列',
        kind: DownloadFailureKind.unknown,
      );
    }
  }

  Future<void> _restart(_BackgroundDownloadOperation operation) async {
    await _deleteNativeArtifacts(operation.appTask, deleteDatabaseRecord: true);
    operation.nativeTask = _toNativeTask(operation.appTask);
    await _enqueue(operation.nativeTask);
  }

  void _handleUpdate(background.TaskUpdate update) {
    if (update.task.group != _group) return;
    final operation = _operations[update.task.taskId];
    if (operation == null || operation.completer.isCompleted) return;
    if (update is background.TaskProgressUpdate) {
      if (update.progress < 0 || update.progress > 1) return;
      final total = update.hasExpectedFileSize ? update.expectedFileSize : 0;
      final received = total > 0 ? (total * update.progress).round() : 0;
      operation.onProgress(received, total);
      return;
    }
    if (update is! background.TaskStatusUpdate) return;
    final nativeTask = update.task is background.DownloadTask
        ? update.task as background.DownloadTask
        : operation.nativeTask;
    operation.nativeTask = nativeTask;
    switch (update.status) {
      case background.TaskStatus.complete:
        unawaited(_completeOperation(operation, nativeTask));
      case background.TaskStatus.notFound:
        operation.completeError(
          const DownloadExecutionException(
            message: '下载资源不存在或已失效',
            kind: DownloadFailureKind.server,
          ),
        );
      case background.TaskStatus.failed:
        operation.completeError(_exceptionFromUpdate(update));
      case background.TaskStatus.canceled:
        operation.completeError(
          DioException.requestCancelled(
            requestOptions: RequestOptions(path: operation.appTask.url),
            reason: operation.stopReason ?? 'cancelled',
          ),
        );
      case background.TaskStatus.enqueued:
      case background.TaskStatus.running:
      case background.TaskStatus.waitingToRetry:
      case background.TaskStatus.paused:
        return;
    }
  }

  DownloadExecutionException _exceptionFromUpdate(
    background.TaskStatusUpdate update,
  ) {
    final exception = update.exception;
    if (exception is background.TaskConnectionException) {
      return const DownloadExecutionException(
        message: '网络连接中断，恢复网络后将自动继续',
        kind: DownloadFailureKind.network,
      );
    }
    if (exception is background.TaskFileSystemException) {
      return const DownloadExecutionException(
        message: '文件保存失败，请检查剩余空间和保存路径',
        kind: DownloadFailureKind.storage,
      );
    }
    if (exception is background.TaskHttpException ||
        exception is background.TaskUrlException) {
      return const DownloadExecutionException(
        message: '下载地址不可用，请稍后重试',
        kind: DownloadFailureKind.server,
      );
    }
    return DownloadExecutionException(
      message: exception?.description.trim().isNotEmpty == true
          ? exception!.description.trim()
          : '系统后台下载失败，请稍后重试',
    );
  }

  Future<void> _completeOperation(
    _BackgroundDownloadOperation operation,
    background.DownloadTask nativeTask,
  ) async {
    if (operation.finishing || operation.completer.isCompleted) return;
    operation.finishing = true;
    try {
      final source = File(await nativeTask.filePath());
      final downloadedBytes = await source.exists() ? await source.length() : 0;
      final savedPath = await _export(operation.appTask, nativeTask);
      await _downloader.database.deleteRecordWithId(operation.appTask.id);
      await _deleteNativeDirectory(operation.appTask, nativeTask);
      if (downloadedBytes > 0) {
        operation.onProgress(downloadedBytes, downloadedBytes);
      }
      if (!operation.completer.isCompleted) {
        operation.completer.complete(DownloadTaskResult(savedPath: savedPath));
      }
    } catch (error, stackTrace) {
      _logError('Failed to export background download', error, stackTrace);
      operation.completeError(
        error is DownloadExecutionException
            ? error
            : const DownloadExecutionException(
                message: '文件保存失败，请检查剩余空间和保存路径',
                kind: DownloadFailureKind.storage,
              ),
        stackTrace,
      );
    }
  }

  Future<String> _export(
    DownloadTask task,
    background.DownloadTask nativeTask,
  ) async {
    final configuredPath = ChewieHiveUtil.getString(HiveUtil.savePathKey);
    if (ResponsiveUtil.isMobile() && configuredPath.nullOrEmpty) {
      await _requestSharedStoragePermissionIfNeeded();
      final destination = switch (task.mediaType) {
        DownloadMediaType.image => background.SharedStorage.images,
        DownloadMediaType.video => background.SharedStorage.video,
        DownloadMediaType.file => background.SharedStorage.downloads,
      };
      final result = await _downloader.moveToSharedStorage(
        nativeTask,
        destination,
      );
      if (result == null || result.isEmpty) {
        throw const DownloadExecutionException(
          message: '无法写入系统相册或下载目录',
          kind: DownloadFailureKind.storage,
        );
      }
      return result;
    }
    if (configuredPath.nullOrEmpty) {
      throw const DownloadExecutionException(
        message: '请先在图片设置中选择下载路径',
        kind: DownloadFailureKind.storage,
      );
    }
    final source = File(await nativeTask.filePath());
    if (!await source.exists()) {
      throw const DownloadExecutionException(
        message: '后台下载文件已被系统清理，请重试',
        kind: DownloadFailureKind.storage,
      );
    }
    final directory = Directory(configuredPath!);
    await directory.create(recursive: true);
    final target = await _availableTarget(directory, task.fileName);
    await source.copy(target.path);
    return target.path;
  }

  Future<File> _availableTarget(Directory directory, String fileName) async {
    final requested = File(path_util.join(directory.path, fileName));
    if (!await requested.exists()) return requested;
    final extension = path_util.extension(fileName);
    final stem = path_util.basenameWithoutExtension(fileName);
    for (var index = 1; index < 10000; index++) {
      final candidate = File(
        path_util.join(directory.path, '$stem ($index)$extension'),
      );
      if (!await candidate.exists()) return candidate;
    }
    throw const DownloadExecutionException(
      message: '同名文件过多，无法生成可用文件名',
      kind: DownloadFailureKind.storage,
    );
  }

  @override
  Future<bool> pause(DownloadTask task) async {
    await initialize();
    final operation = _operations[task.id];
    final nativeTask = operation?.nativeTask ?? _toNativeTask(task);
    operation?.stopReason = 'paused';
    final paused = await _downloader.pause(nativeTask);
    if (!paused) await _downloader.cancelTaskWithId(task.id);
    operation?.completeStopped();
    return true;
  }

  @override
  Future<void> cancel(DownloadTask task) async {
    await initialize();
    final operation = _operations[task.id];
    operation?.stopReason = 'cancelled';
    await _downloader.cancelTaskWithId(task.id);
    operation?.completeStopped();
  }

  Future<void> _stopFromCancelToken(
    _BackgroundDownloadOperation operation,
    CancelToken cancelToken,
  ) async {
    final reason = cancelToken.cancelError?.error?.toString() ?? 'cancelled';
    if (reason.contains('paused')) {
      await pause(operation.appTask);
    } else {
      await cancel(operation.appTask);
    }
  }

  @override
  Future<void> onNetworkAvailable() async {
    await initialize();
    await _downloader.resumeFromBackground();
    for (final operation in List.of(_operations.values)) {
      if (operation.completer.isCompleted || operation.stopReason != null) {
        continue;
      }
      final record =
          await _downloader.database.recordForId(operation.appTask.id);
      if (record?.status == background.TaskStatus.paused &&
          record?.task is background.DownloadTask) {
        await _downloader.resume(record!.task as background.DownloadTask);
      }
    }
  }

  @override
  Future<void> deleteTemporaryFiles(DownloadTask task) {
    return _deleteNativeArtifacts(task, deleteDatabaseRecord: true);
  }

  Future<void> _deleteNativeArtifacts(
    DownloadTask task, {
    required bool deleteDatabaseRecord,
  }) async {
    try {
      await initialize();
      final record = await _downloader.database.recordForId(task.id);
      final nativeTask = record?.task is background.DownloadTask
          ? record!.task as background.DownloadTask
          : _toNativeTask(task);
      await _deleteNativeDirectory(task, nativeTask);
      if (deleteDatabaseRecord) {
        await _downloader.database.deleteRecordWithId(task.id);
      }
    } catch (error, stackTrace) {
      _logError('Failed to clean background download files', error, stackTrace);
    }
  }

  Future<void> _deleteNativeDirectory(
    DownloadTask task,
    background.DownloadTask nativeTask,
  ) async {
    final file = File(await nativeTask.filePath());
    final taskDirectory = file.parent;
    final isExpectedDirectory = path_util.basename(taskDirectory.path) ==
            task.id &&
        path_util.basename(taskDirectory.parent.path) == 'loftify_downloads';
    if (isExpectedDirectory && await taskDirectory.exists()) {
      await taskDirectory.delete(recursive: true);
    } else if (await file.exists()) {
      await file.delete();
    }
  }

  background.DownloadTask _toNativeTask(DownloadTask task) {
    final displayName = (task.title?.trim().isNotEmpty == true
            ? task.title!.trim()
            : task.fileName)
        .replaceAll(RegExp(r'[\r\n]+'), ' ');
    return background.DownloadTask(
      taskId: task.id,
      url: task.url,
      filename: task.fileName,
      directory: path_util.join('loftify_downloads', task.id),
      baseDirectory: background.BaseDirectory.applicationSupport,
      group: _group,
      updates: background.Updates.statusAndProgress,
      retries: 5,
      allowPause: true,
      priority: 0,
      metaData: task.mediaType.name,
      displayName: displayName.length <= 80
          ? displayName
          : '${displayName.substring(0, 79)}…',
      creationTime: task.createdAt,
    );
  }

  Future<void> _requestNotificationPermissionOnce() async {
    if (_notificationPermissionRequested) return;
    _notificationPermissionRequested = true;
    try {
      final permissions = _downloader.permissions;
      final current = await permissions.status(
        background.PermissionType.notifications,
      );
      if (current != background.PermissionStatus.granted) {
        await permissions.request(background.PermissionType.notifications);
      }
    } catch (error, stackTrace) {
      _logError('Failed to request download notification permission', error,
          stackTrace);
    }
  }

  Future<void> _requestSharedStoragePermissionIfNeeded() async {
    final permissions = _downloader.permissions;
    final current = await permissions.status(
      background.PermissionType.androidSharedStorage,
    );
    if (current == background.PermissionStatus.granted) return;
    final requested = await permissions.request(
      background.PermissionType.androidSharedStorage,
    );
    if (requested != background.PermissionStatus.granted) {
      throw const DownloadExecutionException(
        message: '没有相册或下载目录写入权限',
        kind: DownloadFailureKind.storage,
      );
    }
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    try {
      ILogger.error(message, error, stackTrace);
    } catch (_) {}
  }
}

class _BackgroundDownloadOperation {
  _BackgroundDownloadOperation({
    required this.appTask,
    required this.nativeTask,
    required this.onProgress,
  });

  final DownloadTask appTask;
  background.DownloadTask nativeTask;
  final DownloadProgressCallback onProgress;
  final Completer<DownloadTaskResult> completer = Completer();
  String? stopReason;
  bool finishing = false;

  void completeStopped() {
    if (completer.isCompleted) return;
    completer.completeError(
      DioException.requestCancelled(
        requestOptions: RequestOptions(path: appTask.url),
        reason: stopReason ?? 'cancelled',
      ),
    );
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    if (completer.isCompleted) return;
    completer.completeError(error, stackTrace);
  }
}
