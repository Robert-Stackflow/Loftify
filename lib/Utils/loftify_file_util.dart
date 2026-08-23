import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../Models/download_task.dart';
import '../Models/illust.dart';
import 'constant.dart';
import 'download_task_manager.dart';
import 'enums.dart';
import 'hive_util.dart';

class LoftifyFileUtil {
  static void configureDownloadDelegates() {
    FileUtil.saveImageDelegate = saveImage;
    FileUtil.saveVideoDelegate = saveVideo;
  }

  static Future<bool> saveImage(
    BuildContext context,
    String imageUrl, {
    bool showToast = true,
    String? fileName,
  }) {
    return _enqueueAndWait(
      context,
      url: imageUrl,
      fileName: fileName ?? FileUtil.extractFileNameFromUrl(imageUrl),
      mediaType: DownloadMediaType.image,
      showToast: showToast,
    );
  }

  static Future<bool> saveVideo(
    BuildContext context,
    String videoUrl, {
    bool showToast = true,
    String? fileName,
    Function(int, int)? onReceiveProgress,
  }) {
    return _enqueueAndWait(
      context,
      url: videoUrl,
      fileName: fileName ?? FileUtil.extractFileNameFromUrl(videoUrl),
      mediaType: DownloadMediaType.video,
      showToast: showToast,
      onReceiveProgress: onReceiveProgress,
    );
  }

  static Future<bool> _enqueueAndWait(
    BuildContext context, {
    required String url,
    required String fileName,
    required DownloadMediaType mediaType,
    required bool showToast,
    Function(int, int)? onReceiveProgress,
    String? title,
    String? thumbnailUrl,
  }) async {
    try {
      if (ResponsiveUtil.isDesktop()) {
        final saveDirectory = await FileUtil.checkSaveDirectory(context);
        if (saveDirectory.nullOrEmpty) {
          if (showToast) IToast.showTop('下载失败，请先选择保存路径');
          return false;
        }
      }
      final task = await DownloadTaskManager.instance.enqueue(
        url: url,
        fileName: fileName,
        mediaType: mediaType,
        title: title,
        thumbnailUrl: thumbnailUrl,
      );
      final success = await DownloadTaskManager.instance.waitForCompletion(
        task.id,
        onProgress: onReceiveProgress,
      );
      if (showToast) {
        IToast.showTop(success ? '下载完成' : '下载失败，请在下载管理中重试');
      }
      return success;
    } catch (error, stackTrace) {
      ILogger.error('Failed to enqueue download', error, stackTrace);
      if (showToast) IToast.showTop('下载失败，请重试');
      return false;
    }
  }

  static Future<bool> saveIllust(
    BuildContext context,
    Illust illust, {
    bool showToast = true,
  }) {
    return _enqueueAndWait(
      context,
      url: illust.url,
      fileName: getFileNameByIllust(illust),
      mediaType: DownloadMediaType.image,
      showToast: showToast,
      title: illust.postTitle,
      thumbnailUrl: illust.url,
    );
  }

  static Future<bool> saveIllusts(
    BuildContext context,
    List<Illust> illusts, {
    bool showToast = true,
  }) async {
    try {
      final status = await Future.wait(
        illusts.map(
          (illust) => saveIllust(context, illust, showToast: false),
        ),
      );
      final success = status.every((saved) => saved);
      if (showToast) {
        IToast.showTop(success ? "所有图片已保存" : "保存失败，请重试");
      }
      return success;
    } catch (error, stackTrace) {
      ILogger.error("Failed to save illustrations", error, stackTrace);
      if (showToast) {
        IToast.showTop("保存失败，请重试");
      }
      return false;
    }
  }

  static Future<bool> saveVideoByIllust(
    BuildContext context,
    Illust illust, {
    bool showToast = true,
    Function(int, int)? onReceiveProgress,
  }) {
    return _enqueueAndWait(
      context,
      url: illust.url,
      fileName: getFileNameByIllust(illust),
      mediaType: DownloadMediaType.video,
      showToast: showToast,
      onReceiveProgress: onReceiveProgress,
      title: illust.postTitle,
      thumbnailUrl: illust.url,
    );
  }

  static String getFileNameByIllust(Illust illust) {
    final format = ChewieHiveUtil.getString(
          HiveUtil.filenameFormatKey,
          defaultValue: defaultFilenameFormat,
        ) ??
        defaultFilenameFormat;
    final originalName =
        illust.originalName.replaceAll(".${illust.extension}", "");
    final fileName = format
        .replaceAll(FilenameField.originalName.format, originalName)
        .replaceAll(FilenameField.blogId.format, illust.blogId.toString())
        .replaceAll(FilenameField.blogLofterId.format, illust.blogLofterId)
        .replaceAll(FilenameField.blogNickName.format, illust.blogNickName)
        .replaceAll(FilenameField.postId.format, illust.postId.toString())
        .replaceAll(
          FilenameField.postTitle.format,
          StringUtil.isNotEmpty(illust.postTitle) ? illust.postTitle : "无标题",
        )
        .replaceAll(
          FilenameField.postTags.format,
          illust.tags.isNotEmpty ? illust.tags.join(",") : "无标签",
        )
        .replaceAll(
          FilenameField.postPublishTime.format,
          TimeUtil.formatAll(illust.publishTime),
        )
        .replaceAll(FilenameField.part.format, illust.part.toString())
        .replaceAll(
          FilenameField.currentTime.format,
          TimeUtil.formatAll(DateTime.now().millisecondsSinceEpoch),
        )
        .replaceAll(
          FilenameField.timestamp.format,
          DateTime.now().millisecondsSinceEpoch.toString(),
        )
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    return '$fileName.${illust.extension}';
  }
}
