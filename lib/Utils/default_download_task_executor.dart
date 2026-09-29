import 'dart:io';

import 'package:dio/dio.dart';

import '../Models/download_task.dart';
import 'background_download_task_executor.dart';
import 'dio_download_task_executor.dart';
import 'download_task_executor.dart';

/// Selects the most capable downloader available on the current platform.
///
/// Android downloads are delegated to WorkManager so they can continue while
/// the Flutter process is suspended. Desktop keeps the proven Dio-based
/// implementation and its byte-range resume support.
class DefaultDownloadTaskExecutor extends DownloadTaskExecutor {
  DefaultDownloadTaskExecutor({Dio? dio})
      : _delegate = Platform.isAndroid
            ? BackgroundDownloadTaskExecutor()
            : DioDownloadTaskExecutor(dio: dio);

  final DownloadTaskExecutor _delegate;

  @override
  Future<void> initialize() => _delegate.initialize();

  @override
  Future<DownloadTaskResult> run(
    DownloadTask task, {
    required CancelToken cancelToken,
    required DownloadProgressCallback onProgress,
  }) {
    return _delegate.run(
      task,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
  }

  @override
  Future<bool> pause(DownloadTask task) => _delegate.pause(task);

  @override
  Future<void> cancel(DownloadTask task) => _delegate.cancel(task);

  @override
  Future<void> onNetworkAvailable() => _delegate.onNetworkAvailable();

  @override
  Future<void> deleteTemporaryFiles(DownloadTask task) {
    return _delegate.deleteTemporaryFiles(task);
  }
}
