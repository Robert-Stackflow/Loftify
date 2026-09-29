import 'package:dio/dio.dart';

import '../Models/download_task.dart';

typedef DownloadProgressCallback = void Function(int received, int total);
typedef DownloadErrorLogger = void Function(
  String message,
  Object error,
  StackTrace stackTrace,
);

class DownloadTaskResult {
  const DownloadTaskResult({required this.savedPath});

  final String savedPath;
}

class DownloadExecutionException implements Exception {
  const DownloadExecutionException({
    required this.message,
    this.kind = DownloadFailureKind.unknown,
  });

  final String message;
  final DownloadFailureKind kind;

  @override
  String toString() => message;
}

abstract class DownloadTaskExecutor {
  Future<void> initialize() async {}

  Future<DownloadTaskResult> run(
    DownloadTask task, {
    required CancelToken cancelToken,
    required DownloadProgressCallback onProgress,
  });

  Future<bool> pause(DownloadTask task) async => false;

  Future<void> cancel(DownloadTask task) async {}

  Future<void> onNetworkAvailable() async {}

  Future<void> deleteTemporaryFiles(DownloadTask task);
}
