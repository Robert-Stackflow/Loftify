import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' as path_util;
import 'package:path_provider/path_provider.dart';

import '../Models/download_task.dart';
import 'hive_util.dart';

typedef DownloadProgressCallback = void Function(int received, int total);
typedef DownloadErrorLogger = void Function(
  String message,
  Object error,
  StackTrace stackTrace,
);

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

class DownloadTaskResult {
  const DownloadTaskResult({required this.savedPath});

  final String savedPath;
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

abstract class DownloadTaskExecutor {
  Future<DownloadTaskResult> run(
    DownloadTask task, {
    required CancelToken cancelToken,
    required DownloadProgressCallback onProgress,
  });

  Future<void> deleteTemporaryFiles(DownloadTask task);
}

class DefaultDownloadTaskExecutor implements DownloadTaskExecutor {
  DefaultDownloadTaskExecutor({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<DownloadTaskResult> run(
    DownloadTask task, {
    required CancelToken cancelToken,
    required DownloadProgressCallback onProgress,
  }) {
    return _run(
      task,
      cancelToken: cancelToken,
      onProgress: onProgress,
      allowPartialReset: true,
    );
  }

  Future<DownloadTaskResult> _run(
    DownloadTask task, {
    required CancelToken cancelToken,
    required DownloadProgressCallback onProgress,
    required bool allowPartialReset,
  }) async {
    final temporaryFile = await _temporaryFile(task);
    await temporaryFile.parent.create(recursive: true);
    var existingBytes =
        await temporaryFile.exists() ? await temporaryFile.length() : 0;
    final headers = <String, dynamic>{};
    if (existingBytes > 0) {
      headers[HttpHeaders.rangeHeader] = 'bytes=$existingBytes-';
    }

    final response = await _dio.get<ResponseBody>(
      task.url,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: headers,
        followRedirects: true,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    final statusCode = response.statusCode ?? 0;
    if (statusCode == HttpStatus.requestedRangeNotSatisfiable &&
        existingBytes > 0) {
      final serverLength = _totalBytesFromContentRange(
        response.headers.value(HttpHeaders.contentRangeHeader),
      );
      if (serverLength != null && existingBytes == serverLength) {
        final savedPath = await _export(task, temporaryFile);
        await deleteTemporaryFiles(task);
        return DownloadTaskResult(savedPath: savedPath);
      }
      if (allowPartialReset) {
        await deleteTemporaryFiles(task);
        return _run(
          task,
          cancelToken: cancelToken,
          onProgress: onProgress,
          allowPartialReset: false,
        );
      }
    }
    if (statusCode < 200 || statusCode >= 300 || response.data == null) {
      throw DioException.badResponse(
        statusCode: statusCode,
        requestOptions: response.requestOptions,
        response: response,
      );
    }

    final canAppend =
        statusCode == HttpStatus.partialContent && existingBytes > 0;
    if (!canAppend) existingBytes = 0;
    final contentLength = int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        -1;
    final totalBytes = _resolveTotalBytes(
      response.headers.value(HttpHeaders.contentRangeHeader),
      existingBytes,
      contentLength,
    );
    var receivedBytes = existingBytes;
    onProgress(receivedBytes, totalBytes);

    final sink = temporaryFile.openWrite(
      mode: canAppend ? FileMode.append : FileMode.write,
    );
    try {
      await for (final chunk in response.data!.stream) {
        if (cancelToken.isCancelled) {
          throw DioException.requestCancelled(
            requestOptions: response.requestOptions,
            reason: cancelToken.cancelError,
          );
        }
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes, totalBytes);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    final savedPath = await _export(task, temporaryFile);
    await deleteTemporaryFiles(task);
    return DownloadTaskResult(savedPath: savedPath);
  }

  int _resolveTotalBytes(
    String? contentRange,
    int existingBytes,
    int contentLength,
  ) {
    final totalFromRange = _totalBytesFromContentRange(contentRange);
    if (totalFromRange != null && totalFromRange > 0) return totalFromRange;
    if (contentLength > 0) return existingBytes + contentLength;
    return 0;
  }

  int? _totalBytesFromContentRange(String? contentRange) {
    if (contentRange == null || !contentRange.contains('/')) return null;
    return int.tryParse(contentRange.split('/').last.trim());
  }

  Future<String> _export(DownloadTask task, File temporaryFile) async {
    final configuredPath = ChewieHiveUtil.getString(HiveUtil.savePathKey);
    if (ResponsiveUtil.isMobile() && configuredPath.nullOrEmpty) {
      final result = await ImageGallerySaver.saveFile(
        temporaryFile.path,
        name: task.fileName,
      );
      if (result == null || result['isSuccess'] != true) {
        throw const FileSystemException('无法写入系统相册');
      }
      return result['filePath']?.toString() ?? 'gallery://${task.fileName}';
    }
    if (configuredPath.nullOrEmpty) {
      throw const FileSystemException('请先在图片设置中选择下载路径');
    }
    final directory = Directory(configuredPath!);
    await directory.create(recursive: true);
    final target = await _availableTarget(directory, task.fileName);
    await temporaryFile.copy(target.path);
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
      if (!await candidate.exists()) {
        return candidate;
      }
    }
    throw const FileSystemException('同名文件过多，无法生成可用文件名');
  }

  Future<File> _temporaryFile(DownloadTask task) async {
    final temporaryDirectory = await getTemporaryDirectory();
    return File(
      path_util.join(
        temporaryDirectory.path,
        'loftify_downloads',
        task.id,
        task.fileName,
      ),
    );
  }

  @override
  Future<void> deleteTemporaryFiles(DownloadTask task) async {
    try {
      final file = await _temporaryFile(task);
      final taskDirectory = file.parent;
      if (await taskDirectory.exists()) {
        await taskDirectory.delete(recursive: true);
      }
    } catch (error, stackTrace) {
      _logDownloadError(
        'Failed to clean download temporary files',
        error,
        stackTrace,
      );
    }
  }
}

class DownloadTaskManager extends ChangeNotifier {
  DownloadTaskManager({
    DownloadTaskStore? store,
    DownloadTaskExecutor? executor,
    DownloadErrorLogger errorLogger = _logDownloadError,
    this.maxConcurrentTasks = 2,
  })  : assert(maxConcurrentTasks > 0),
        _store = store ?? const HiveDownloadTaskStore(),
        _executor = executor ?? DefaultDownloadTaskExecutor(),
        _errorLogger = errorLogger;

  static final DownloadTaskManager instance = DownloadTaskManager();

  final DownloadTaskStore _store;
  final DownloadTaskExecutor _executor;
  final DownloadErrorLogger _errorLogger;
  final int maxConcurrentTasks;
  final List<DownloadTask> _tasks = <DownloadTask>[];
  final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};
  final Map<String, DateTime> _lastProgressNotification = <String, DateTime>{};
  final Map<String, DateTime> _lastProgressPersistence = <String, DateTime>{};
  Future<void> _persistenceQueue = Future<void>.value();
  bool _initialized = false;

  List<DownloadTask> get tasks => List<DownloadTask>.unmodifiable(_tasks);

  int get activeCount => _tasks.where((task) => task.isActive).length;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final restored = await _store.read();
    _tasks
      ..clear()
      ..addAll(restored.map((task) {
        if (task.status != DownloadTaskStatus.downloading) return task;
        return task.copyWith(
          status: DownloadTaskStatus.queued,
          errorMessage: null,
        );
      }));
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
    _replace(task.copyWith(status: DownloadTaskStatus.paused));
    _cancelTokens[taskId]?.cancel('paused');
    await _persist();
    _pump();
  }

  Future<void> resume(String taskId) async {
    final task = _taskById(taskId);
    if (task == null || task.status != DownloadTaskStatus.paused) return;
    _replace(task.copyWith(
      status: DownloadTaskStatus.queued,
      errorMessage: null,
    ));
    await _persist();
    _pump();
  }

  Future<void> cancel(String taskId) async {
    final task = _taskById(taskId);
    if (task == null || task.isTerminal) return;
    _replace(task.copyWith(status: DownloadTaskStatus.cancelled));
    _cancelTokens[taskId]?.cancel('cancelled');
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
        ));
      }
    } catch (error, stackTrace) {
      final current = _taskById(taskId);
      final wasIntentionallyStopped =
          current?.status == DownloadTaskStatus.paused ||
              current?.status == DownloadTaskStatus.cancelled;
      if (!wasIntentionallyStopped && current != null) {
        _errorLogger('Download task failed', error, stackTrace);
        _replace(current.copyWith(
          status: DownloadTaskStatus.failed,
          errorMessage: _friendlyError(error),
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

  String _friendlyError(Object error) {
    if (error is FileSystemException) {
      final message = error.message.trim();
      if (message.isNotEmpty) return message;
      return '文件保存失败，请检查剩余空间和保存路径';
    }
    if (error is DioException) {
      if (error.response?.statusCode ==
          HttpStatus.requestedRangeNotSatisfiable) {
        return '服务器不支持继续下载，请清理记录后重试';
      }
      return '网络连接中断，可保留进度后重试';
    }
    return '下载失败，请稍后重试';
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
}
