import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' as path_util;
import 'package:path_provider/path_provider.dart';

import '../Models/download_task.dart';
import 'download_task_executor.dart';
import 'hive_util.dart';

class DioDownloadTaskExecutor extends DownloadTaskExecutor {
  DioDownloadTaskExecutor({Dio? dio}) : _dio = dio ?? Dio();

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
      if (!await candidate.exists()) return candidate;
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
      _logError(
        'Failed to clean download temporary files',
        error,
        stackTrace,
      );
    }
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    try {
      ILogger.error(message, error, stackTrace);
    } catch (_) {}
  }
}
