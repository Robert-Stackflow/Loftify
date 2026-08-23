import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../Models/illust.dart';
import 'constant.dart';
import 'enums.dart';
import 'hive_util.dart';

class LoftifyFileUtil {
  static Future<bool> saveIllust(
    BuildContext context,
    Illust illust, {
    bool showToast = true,
  }) {
    return FileUtil.saveImage(
      context,
      illust.url,
      fileName: getFileNameByIllust(illust),
      showToast: showToast,
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
    return FileUtil.saveVideo(
      context,
      illust.url,
      fileName: getFileNameByIllust(illust),
      showToast: showToast,
      onReceiveProgress: onReceiveProgress,
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
