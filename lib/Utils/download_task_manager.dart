import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path_util;

import '../Models/download_task.dart';
import 'default_download_task_executor.dart';
import 'download_task_executor.dart';
import 'hive_util.dart';

export 'download_task_executor.dart';

void _logDownloadError(
  String message,
  Object error,
  StackTrace stackTrace,
) {
  try {
    ILogger.error(message, error, stackTrace);
  } catch (_) {
    // A logging backend must never turn a recoverable download error into an
    // uncaught failure (for example before platform plugins are available).
  }
}

abstract class DownloadTaskStore {
  Future<List<DownloadTask>> read();

  Future<void> write(List<DownloadTask> tasks);
}

class HiveDownloadTaskStore implements DownloadTaskStore {
  const HiveDownloadTaskStore();

  @override
  Future<List<DownloadTask>> read() async {
    final records = ChewieHiveUtil.getList(
          HiveUtil.downloadTasksKey,
          defaultValue: const <dynamic>[],
        ) ??
        const <dynamic>[];
    final tasks = <DownloadTask>[];
    for (final record in records) {
      try {
        final task = DownloadTask.fromJson(
          Map<String, dynamic>.from(record as Map),
        );
        if (task.id.isNotEmpty && task.url.isNotEmpty) tasks.add(task);
      } catch (error, stackTrace) {
        _logDownloadError(
          'Failed to restore a download task',
          error,
          stackTrace,
        );
      }
    }
    return tasks;
  }

  @override
  Future<void> write(List<DownloadTask> tasks) {
    return ChewieHiveUtil.put(
      HiveUtil.downloadTasksKey,
      tasks.map((task) => task.toJson()).toList(growable: false),
    );
  }
}

class DownloadTaskManager extends ChangeNotifier {
  DownloadTaskManager({
    DownloadTaskStore? store,
    DownloadTaskExecutor? executor,
    Future<List<ConnectivityResult>> Function()? connectivityCheck,
    Stream<List<ConnectivityResult>>? connectivityChanges,
    DownloadErrorLogger errorLogger = _logDownloadError,
    this.maxConcurrentTasks = 2,
    this.monitorConnectivity = false,
  })  : assert(maxConcurrentTasks > 0),
        _store = store ?? const HiveDownloadTaskStore(),
        _executor = executor ?? DefaultDownloadTaskExecutor(),
        _connectivityCheck =
            connectivityCheck ?? Connectivity().checkConnectivity,
        _connectivityChanges =
            connectivityChanges ?? Connectivity().onConnectivityChanged,
        _errorLogger = errorLogger;

  static final DownloadTaskManager instance = DownloadTaskManager(
    monitorConnectivity: true,
  );

  final DownloadTaskStore _store;
  final DownloadTaskExecutor _executor;
  final Future<List<ConnectivityResult>> Function() _connectivityCheck;
  final Stream<List<ConnectivityResult>> _connectivityChanges;
  final DownloadErrorLogger _errorLogger;
  final int maxConcurrentTasks;
  final bool monitorConnectivity;
  final List<DownloadTask> _tasks = <DownloadTask>[];
  final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};
  final Map<String, DateTime> _lastProgressNotification = <String, DateTime>{};
  final Map<String, DateTime> _lastProgressPersistence = <String, DateTime>{};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void> _persistenceQueue = Future<void>.value();
  Future<void>? _initialization;
  bool _initialized = false;
  bool _wasOffline = false;

  List<DownloadTask> get tasks => List<DownloadTask>.unmodifiable(_tasks);

  int get activeCount => _tasks.where((task) => task.isActive).length;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    await _executor.initialize();
    final restored = await _store.read();
    _tasks
      ..clear()
      ..addAll(restored.map((task) {
        if (task.status != DownloadTaskStatus.downloading) return task;
        return task.copyWith(
          status: DownloadTaskStatus.queued,
          errorMessage: null,
          failureKind: null,
        );
      }));
    _initialized = true;
    if (monitorConnectivity) await _startConnectivityMonitor();
    await _persist();
    notifyListeners();
    _pump();
  }

  Future<DownloadTask> enqueue({
    required String url,
    required String fileName,
    required DownloadMediaType mediaType,
    String? title,
    String? thumbnailUrl,
  }) async {
    await initialize();
    final normalizedUrl = url.trim();
    final existingIndex =
        _tasks.indexWhere((task) => task.url == normalizedUrl);
    if (existingIndex >= 0) {
      final existing = _tasks[existingIndex];
      if (existing.status == DownloadTaskStatus.failed ||
          existing.status == DownloadTaskStatus.cancelled ||
          existing.status == DownloadTaskStatus.paused) {
        _replace(
          existing.copyWith(
            status: DownloadTaskStatus.queued,
            errorMessage: null,
            failureKind: null,
          ),
        );
        await _persist();
        _pump();
        return _taskById(existing.id)!;
      }
      return existing;
    }

    final now = DateTime.now();
    final task = DownloadTask(
      id: '${now.microsecondsSinceEpoch}_${normalizedUrl.hashCode.abs()}',
      url: normalizedUrl,
      fileName: _sanitizeFileName(fileName),
      title: title,
      thumbnailUrl: thumbnailUrl,
      mediaType: mediaType,
      status: DownloadTaskStatus.queued,
      createdAt: now,
      updatedAt: now,
    );
    _tasks.insert(0, task);
    notifyListeners();
    await _persist();
    _pump();
    return task;
  }

  /// Adds a group of resources with one state notification and one persisted
  /// snapshot. The URL is the stable identity across batches.
  ///
  /// Active and completed resources are skipped. Failed, cancelled and paused
  /// records are reset and requeued. This is intentionally a skip policy for
  /// already downloaded files: batch actions never overwrite or create a
  /// second copy of a completed resource.
  Future<DownloadBatchResult> enqueueBatch(
    Iterable<DownloadRequest> requests,
  ) async {
    await initialize();
    final requestList = requests.toList(growable: false);
    final seenUrls = <String>{};
    final affectedTasks = <DownloadTask>[];
    var queuedCount = 0;
    var skippedCount = 0;
    var invalidCount = 0;
    var requeuedCount = 0;
    var sequence = 0;

    for (final request in requestList) {
      final normalizedUrl = request.url.trim();
      if (!_isValidDownloadUrl(normalizedUrl)) {
        invalidCount++;
        continue;
      }
      if (!seenUrls.add(normalizedUrl)) {
        skippedCount++;
        continue;
      }

      final existingIndex =
          _tasks.indexWhere((task) => task.url == normalizedUrl);
      if (existingIndex >= 0) {
        final existing = _tasks[existingIndex];
        if (existing.status == DownloadTaskStatus.failed ||
            existing.status == DownloadTaskStatus.cancelled ||
            existing.status == DownloadTaskStatus.paused) {
          final requeued = existing.copyWith(
            status: DownloadTaskStatus.queued,
            progress: 0,
            receivedBytes: 0,
            totalBytes: 0,
            savedPath: null,
            errorMessage: null,
            failureKind: null,
          );
          _tasks[existingIndex] = requeued;
          affectedTasks.add(requeued);
          queuedCount++;
          requeuedCount++;
        } else {
          affectedTasks.add(existing);
          skippedCount++;
        }
        continue;
      }

      final now = DateTime.now();
      final task = DownloadTask(
        id: '${now.microsecondsSinceEpoch}_${sequence++}_'
            '${normalizedUrl.hashCode.abs()}',
        url: normalizedUrl,
        fileName: _sanitizeFileName(request.fileName),
        title: request.title,
        thumbnailUrl: request.thumbnailUrl,
        mediaType: request.mediaType,
        status: DownloadTaskStatus.queued,
        createdAt: now,
        updatedAt: now,
      );
      _tasks.add(task);
      affectedTasks.add(task);
      queuedCount++;
    }

    if (queuedCount > 0) {
      notifyListeners();
      await _persist();
      _pump();
    }
    return DownloadBatchResult(
      requestedCount: requestList.length,
      queuedCount: queuedCount,
      skippedCount: skippedCount,
      invalidCount: invalidCount,
      requeuedCount: requeuedCount,
      tasks: List<DownloadTask>.unmodifiable(affectedTasks),
    );
  }

  Future<bool> waitForCompletion(
    String taskId, {
    DownloadProgressCallback? onProgress,
  }) async {
    final initial = _taskById(taskId);
    if (initial == null) return false;
    if (initial.isTerminal) {
      return initial.status == DownloadTaskStatus.completed;
    }
    final completer = Completer<bool>();
    void listener() {
      final current = _taskById(taskId);
      if (current == null) {
        if (!completer.isCompleted) completer.complete(false);
        return;
      }
      onProgress?.call(current.receivedBytes, current.totalBytes);
      if (current.isTerminal && !completer.isCompleted) {
        completer.complete(current.status == DownloadTaskStatus.completed);
      }
    }

    addListener(listener);
    listener();
    try {
      return await completer.future;
    } finally {
      removeListener(listener);
    }
  }

  Future<void> pause(String taskId) async {
    final task = _taskById(taskId);
    if (task == null ||
        (task.status != DownloadTaskStatus.queued &&
            task.status != DownloadTaskStatus.downloading)) {
      return;
    }
    final wasDownloading = task.status == DownloadTaskStatus.downloading;
    _replace(task.copyWith(status: DownloadTaskStatus.paused));
    try {
      if (wasDownloading) await _executor.pause(task);
    } catch (error, stackTrace) {
      _errorLogger('Failed to pause native download task', error, stackTrace);
    } finally {
      _cancelTokens[taskId]?.cancel('paused');
    }
    await _persist();
    _pump();
  }

  Future<void> resume(String taskId) async {
    final task = _taskById(taskId);
    if (task == null || task.status != DownloadTaskStatus.paused) return;
    _replace(task.copyWith(
      status: DownloadTaskStatus.queued,
      errorMessage: null,
      failureKind: null,
    ));
    await _persist();
    _pump();
  }

  Future<void> cancel(String taskId) async {
    final task = _taskById(taskId);
    if (task == null || task.isTerminal) return;
    _replace(task.copyWith(status: DownloadTaskStatus.cancelled));
    try {
      await _executor.cancel(task);
    } catch (error, stackTrace) {
      _errorLogger('Failed to cancel native download task', error, stackTrace);
    } finally {
      _cancelTokens[taskId]?.cancel('cancelled');
    }
    await _persist();
    await _executor.deleteTemporaryFiles(task);
    _pump();
  }

  Future<void> retry(String taskId) async {
    final task = _taskById(taskId);
    if (task == null ||
        (task.status != DownloadTaskStatus.failed &&
            task.status != DownloadTaskStatus.cancelled)) {
      return;
    }
    _replace(task.copyWith(
      status: DownloadTaskStatus.queued,
      errorMessage: null,
      failureKind: null,
      savedPath: null,
    ));
    await _persist();
    _pump();
  }

  Future<void> remove(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0 || !_tasks[index].isTerminal) return;
    final task = _tasks.removeAt(index);
    await _executor.deleteTemporaryFiles(task);
    notifyListeners();
    await _persist();
  }

  Future<void> clearFinished() async {
    final removed = _tasks.where((task) => task.isTerminal).toList();
    if (removed.isEmpty) return;
    _tasks.removeWhere((task) => task.isTerminal);
    for (final task in removed) {
      await _executor.deleteTemporaryFiles(task);
    }
    notifyListeners();
    await _persist();
  }

  void _pump() {
    if (!_initialized) return;
    while (_cancelTokens.length < maxConcurrentTasks) {
      final queued = _tasks.cast<DownloadTask?>().firstWhere(
            (task) => task?.status == DownloadTaskStatus.queued,
            orElse: () => null,
          );
      if (queued == null) return;
      final cancelToken = CancelToken();
      _cancelTokens[queued.id] = cancelToken;
      _replace(queued.copyWith(
        status: DownloadTaskStatus.downloading,
        errorMessage: null,
        failureKind: null,
      ));
      unawaited(_execute(queued.id, cancelToken));
    }
  }

  Future<void> _execute(String taskId, CancelToken cancelToken) async {
    final task = _taskById(taskId);
    if (task == null) return;
    await _persist();
    try {
      final result = await _executor.run(
        task,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          final current = _taskById(taskId);
          if (current == null ||
              current.status != DownloadTaskStatus.downloading) {
            return;
          }
          final now = DateTime.now();
          final lastNotification = _lastProgressNotification[taskId];
          final isComplete = total > 0 && received >= total;
          if (!isComplete &&
              lastNotification != null &&
              now.difference(lastNotification) <
                  const Duration(milliseconds: 80)) {
            return;
          }
          _lastProgressNotification[taskId] = now;
          final progress = total > 0 ? received / total : current.progress;
          _replace(current.copyWith(
            progress: progress.clamp(0.0, 1.0).toDouble(),
            receivedBytes: received,
            totalBytes: total,
          ));
          final lastPersistence = _lastProgressPersistence[taskId];
          if (lastPersistence == null ||
              now.difference(lastPersistence) >= const Duration(seconds: 1)) {
            _lastProgressPersistence[taskId] = now;
            unawaited(_persist());
          }
        },
      );
      final current = _taskById(taskId);
      if (current?.status == DownloadTaskStatus.downloading) {
        _replace(current!.copyWith(
          status: DownloadTaskStatus.completed,
          progress: 1,
          savedPath: result.savedPath,
          errorMessage: null,
          failureKind: null,
        ));
      }
    } catch (error, stackTrace) {
      final current = _taskById(taskId);
      final wasIntentionallyStopped =
          current?.status == DownloadTaskStatus.paused ||
              current?.status == DownloadTaskStatus.cancelled;
      if (!wasIntentionallyStopped && current != null) {
        _errorLogger('Download task failed', error, stackTrace);
        final failure = _friendlyFailure(error);
        _replace(current.copyWith(
          status: DownloadTaskStatus.failed,
          errorMessage: failure.message,
          failureKind: failure.kind,
        ));
      }
    } finally {
      _cancelTokens.remove(taskId);
      _lastProgressNotification.remove(taskId);
      _lastProgressPersistence.remove(taskId);
      final current = _taskById(taskId);
      if (current?.status == DownloadTaskStatus.cancelled) {
        await _executor.deleteTemporaryFiles(current!);
      }
      await _persist();
      _pump();
    }
  }

  ({String message, DownloadFailureKind kind}) _friendlyFailure(Object error) {
    if (error is DownloadExecutionException) {
      return (message: error.message, kind: error.kind);
    }
    if (error is FileSystemException) {
      final message = error.message.trim();
      return (
        message: message.isNotEmpty ? message : '文件保存失败，请检查剩余空间和保存路径',
        kind: DownloadFailureKind.storage,
      );
    }
    if (error is DioException) {
      if (error.response?.statusCode ==
          HttpStatus.requestedRangeNotSatisfiable) {
        return (
          message: '服务器不支持继续下载，请清理记录后重试',
          kind: DownloadFailureKind.server,
        );
      }
      if (error.type == DioExceptionType.badResponse) {
        return (
          message: '下载地址不可用，请稍后重试',
          kind: DownloadFailureKind.server,
        );
      }
      return (
        message: '网络连接中断，恢复网络后将自动继续',
        kind: DownloadFailureKind.network,
      );
    }
    return (
      message: '下载失败，请稍后重试',
      kind: DownloadFailureKind.unknown,
    );
  }

  Future<void> _startConnectivityMonitor() async {
    try {
      final initial = await _connectivityCheck();
      _wasOffline = _isOffline(initial);
      _connectivitySubscription ??= _connectivityChanges.listen(
        (results) => unawaited(_handleConnectivityChange(results)),
        onError: (Object error, StackTrace stackTrace) {
          _errorLogger(
            'Download connectivity monitor failed',
            error,
            stackTrace,
          );
        },
      );
    } catch (error, stackTrace) {
      _errorLogger(
        'Unable to start download connectivity monitor',
        error,
        stackTrace,
      );
    }
  }

  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
  }

  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) async {
    final offline = _isOffline(results);
    if (offline) {
      _wasOffline = true;
      return;
    }
    if (!_wasOffline) return;
    _wasOffline = false;
    try {
      await _executor.onNetworkAvailable();
    } catch (error, stackTrace) {
      _errorLogger(
        'Failed to wake native downloads after connectivity returned',
        error,
        stackTrace,
      );
    }

    var requeued = false;
    for (var index = 0; index < _tasks.length; index++) {
      final task = _tasks[index];
      if (task.status != DownloadTaskStatus.failed ||
          task.failureKind != DownloadFailureKind.network) {
        continue;
      }
      _tasks[index] = task.copyWith(
        status: DownloadTaskStatus.queued,
        errorMessage: null,
        failureKind: null,
      );
      requeued = true;
    }
    if (!requeued) return;
    notifyListeners();
    await _persist();
    _pump();
  }

  DownloadTask? _taskById(String taskId) {
    for (final task in _tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  void _replace(DownloadTask task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    _tasks[index] = task;
    notifyListeners();
  }

  Future<void> _persist() {
    final snapshot = List<DownloadTask>.from(_tasks);
    _persistenceQueue = _persistenceQueue
        .catchError((_) {})
        .then((_) => _store.write(snapshot));
    return _persistenceQueue;
  }

  String _sanitizeFileName(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'[\u0000-\u001f]'), '')
        .trim();
    if (sanitized.isEmpty) return 'download';
    const maxLength = 180;
    if (sanitized.length <= maxLength) return sanitized;
    final extension = path_util.extension(sanitized);
    final keepLength =
        (maxLength - extension.length).clamp(1, maxLength).toInt();
    return '${sanitized.substring(0, keepLength)}$extension';
  }

  bool _isValidDownloadUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    super.dispose();
  }
}
