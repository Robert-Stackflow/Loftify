import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:loftify/Models/github_response.dart';
import 'package:loftify/Utils/constant.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Utils/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../Models/Illust.dart';
import '../Widgets/Dialog/custom_dialog.dart';
import '../Widgets/Item/item_builder.dart';
import '../generated/l10n.dart';
import 'hive_util.dart';
import 'ilogger.dart';
import 'iprint.dart';
import 'itoast.dart';
import 'notification_util.dart';

class FileUtil {
  static Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
        lockParentWindow: lockParentWindow,
        onFileLoading: onFileLoading,
        allowCompression: allowCompression,
        compressionQuality: compressionQuality,
        allowMultiple: allowMultiple,
        withData: withData,
        withReadStream: withReadStream,
        readSequential: readSequential,
      );
    } catch (e, t) {
      ILogger.error("Failed to pick files", e, t);
      IToast.showTop(S.current.pleaseGrantFilePermission);
    }
    return result;
  }

  static Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    String? result;
    try {
      result = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
        lockParentWindow: lockParentWindow,
        bytes: bytes,
        fileName: fileName,
      );
    } catch (e, t) {
      ILogger.error("Failed to save file", e, t);
      IToast.showTop(S.current.pleaseGrantFilePermission);
    }
    return result;
  }

  static Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    bool lockParentWindow = false,
  }) async {
    String? result;
    try {
      result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        lockParentWindow: lockParentWindow,
      );
    } catch (e, t) {
      ILogger.error("Failed to get directory path", e, t);
      IToast.showTop(S.current.pleaseGrantFilePermission);
    }
    return result;
  }

  static exportLogs({
    bool showLoading = true,
  }) async {
    if (!(await FileOutput.haveLogs())) {
      IToast.showTop(S.current.noLog);
      return;
    }
    if (ResponsiveUtil.isDesktop()) {
      String? filePath = await FileUtil.saveFile(
        dialogTitle: S.current.exportLog,
        fileName: "CloudOTP-Logs-${Utils.getFormattedDate(DateTime.now())}.zip",
        type: FileType.custom,
        allowedExtensions: ['zip'],
        lockParentWindow: true,
      );
      if (filePath != null) {
        if (showLoading) {
          CustomLoadingDialog.showLoading(title: S.current.exporting);
        }
        try {
          Uint8List? data = await FileOutput.getArchiveData();
          if (data != null) {
            File file = File(filePath);
            await file.writeAsBytes(data);
            IToast.showTop(S.current.exportSuccess);
          } else {
            IToast.showTop(S.current.exportFailed);
          }
        } catch (e, t) {
          ILogger.error("Failed to zip logs", e, t);
          IToast.showTop(S.current.exportFailed);
        } finally {
          if (showLoading) {
            CustomLoadingDialog.dismissLoading();
          }
        }
      }
    } else {
      if (showLoading) {
        CustomLoadingDialog.showLoading(title: S.current.exporting);
      }
      try {
        Uint8List? data = await FileOutput.getArchiveData();
        if (data == null) {
          IToast.showTop(S.current.exportFailed);
          return;
        }
        String? filePath = await FileUtil.saveFile(
          dialogTitle: S.current.exportLog,
          fileName:
              "CloudOTP-Logs-${Utils.getFormattedDate(DateTime.now())}.zip",
          type: FileType.custom,
          allowedExtensions: ['zip'],
          lockParentWindow: true,
          bytes: data,
        );
        if (filePath != null) {
          IToast.showTop(S.current.exportSuccess);
        }
      } catch (e, t) {
        ILogger.error("Failed to zip logs", e, t);
        IToast.showTop(S.current.exportFailed);
      } finally {
        if (showLoading) {
          CustomLoadingDialog.dismissLoading();
        }
      }
    }
  }

  static Future<String> getApplicationDir() async {
    final dir = await getApplicationDocumentsDirectory();
    var appName = (await PackageInfo.fromPlatform()).appName;
    if (kDebugMode) {
      appName += "-Debug";
    }
    String path = join(dir.path, appName);
    Directory directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return path;
  }

  static Future<String> getFontDir() async {
    Directory directory = Directory(join(await getApplicationDir(), "Fonts"));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<String> getBackupDir() async {
    Directory directory = Directory(join(await getApplicationDir(), "Backup"));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<String> getScreenshotDir() async {
    Directory directory =
        Directory(join(await getApplicationDir(), "Screenshots"));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<String> getLogDir() async {
    Directory directory = Directory(join(await getApplicationDir(), "Logs"));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<String> getHiveDir() async {
    Directory directory = Directory(join(await getApplicationDir(), "Hive"));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<String> getDatabaseDir() async {
    Directory directory =
        Directory(join(await getApplicationDir(), "Database"));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static String getFileNameWithExtension(String imageUrl) {
    return Uri.parse(imageUrl).pathSegments.last;
  }

  static String getFileExtension(String imageUrl) {
    return getFileNameWithExtension(imageUrl).split('.').last;
  }

  static String getFileName(String imageUrl) {
    return getFileNameWithExtension(imageUrl).split('.').first;
  }

  static String extractFileNameFromUrl(String imageUrl) {
    return Uri.parse(imageUrl).pathSegments.last;
  }

  static String extractFileExtensionFromUrl(String imageUrl) {
    return extractFileNameFromUrl(imageUrl).split('.').last;
  }

  static Future<void> downloadAndUpdate(
    BuildContext context,
    String apkUrl,
    String htmlUrl, {
    String? version,
    bool isUpdate = true,
    Function(double)? onReceiveProgress,
  }) async {
    await Permission.storage.onDeniedCallback(() {
      IToast.showTop("请授予文件存储权限");
    }).onGrantedCallback(() async {
      if (Utils.isNotEmpty(apkUrl)) {
        double progressValue = 0.0;
        var appDocDir = await getTemporaryDirectory();
        String savePath =
            "${appDocDir.path}/${FileUtil.extractFileNameFromUrl(apkUrl)}";
        try {
          await Dio().download(
            apkUrl,
            savePath,
            onReceiveProgress: (count, total) {
              final value = count / total;
              if (progressValue != value) {
                if (progressValue < 1.0) {
                  progressValue = count / total;
                } else {
                  progressValue = 0.0;
                }
                NotificationUtil.sendProgressNotification(
                  0,
                  (progressValue * 100).toInt(),
                  title: isUpdate
                      ? '正在下载新版本安装包...'
                      : '正在下载版本${version ?? ""}的安装包...',
                  payload: version ?? "",
                );
                onReceiveProgress?.call(progressValue);
              }
            },
          ).then((response) async {
            if (response.statusCode == 200) {
              NotificationUtil.closeNotification(0);
              NotificationUtil.sendInfoNotification(
                1,
                "下载完成",
                isUpdate
                    ? "新版本安装包已经下载完成，点击立即安装"
                    : "版本${version ?? ""}的安装包已经下载完成，点击立即安装",
                payload: savePath,
              );
            } else {
              UriUtil.openExternal(htmlUrl);
            }
          });
        } catch (e) {
          IPrint.debug(e);
          NotificationUtil.closeNotification(0);
          NotificationUtil.sendInfoNotification(
            2,
            "下载失败，请重试",
            "新版本安装包下载失败，请重试",
          );
        }
      } else {
        UriUtil.openExternal(htmlUrl);
      }
    }).onPermanentlyDeniedCallback(() {
      IToast.showTop("已拒绝文件存储权限，将跳转到浏览器下载");
      UriUtil.openExternal(apkUrl);
    }).onRestrictedCallback(() {
      IToast.showTop("请授予文件存储权限");
    }).onLimitedCallback(() {
      IToast.showTop("请授予文件存储权限");
    }).onProvisionalCallback(() {
      IToast.showTop("请授予文件存储权限");
    }).request();
  }

  static Future<ShareResultStatus> shareImage(
    BuildContext context,
    String imageUrl, {
    bool showToast = true,
    String? message,
  }) async {
    CachedNetworkImage image =
        ItemBuilder.buildCachedImage(imageUrl: imageUrl, context: context);
    BaseCacheManager manager = image.cacheManager ?? DefaultCacheManager();
    Map<String, String> headers = image.httpHeaders ?? {};
    File file = await manager.getSingleFile(
      image.imageUrl,
      headers: headers,
    );
    final result = await Share.shareXFiles([XFile(file.path)], text: message);
    if (result.status == ShareResultStatus.success) {
      IToast.showTop("分享成功");
    } else if (result.status == ShareResultStatus.dismissed) {
      IToast.showTop("取消分享");
    } else {
      IToast.showTop("分享失败");
    }
    return result.status;
  }

  static Future<File> getImageFile(
    BuildContext context,
    String imageUrl, {
    bool showToast = true,
  }) async {
    CachedNetworkImage image =
        ItemBuilder.buildCachedImage(imageUrl: imageUrl, context: context);
    BaseCacheManager manager = image.cacheManager ?? DefaultCacheManager();
    Map<String, String> headers = image.httpHeaders ?? {};
    return await manager.getSingleFile(
      image.imageUrl,
      headers: headers,
    );
  }

  static Future<File> copyAndRenameFile(File file, String newFileName) async {
    String dir = file.parent.path;
    String newPath = '$dir/$newFileName';
    File copiedFile = await file.copy(newPath);
    await copiedFile.rename(newPath);
    return copiedFile;
  }

  static Future<bool> saveImage(
    BuildContext context,
    String imageUrl, {
    bool showToast = true,
    String? fileName,
  }) async {
    try {
      CachedNetworkImage image =
          ItemBuilder.buildCachedImage(imageUrl: imageUrl, context: context);
      BaseCacheManager manager = image.cacheManager ?? DefaultCacheManager();
      Map<String, String> headers = image.httpHeaders ?? {};
      File file = await manager.getSingleFile(
        image.imageUrl,
        headers: headers,
      );
      File copiedFile = await copyAndRenameFile(
          file, fileName ?? FileUtil.extractFileNameFromUrl(imageUrl));
      if (ResponsiveUtil.isMobile()) {
        var result = await ImageGallerySaver.saveFile(
          copiedFile.path,
          name: fileName ?? FileUtil.extractFileNameFromUrl(imageUrl),
        );
        bool success = result != null && result['isSuccess'];
        if (showToast) {
          if (success) {
            IToast.showTop("图片已保存至相册");
          } else {
            IToast.showTop("保存失败，请重试");
          }
        }
        return success;
      } else {
        String? saveDirectory = await checkSaveDirectory(context);
        if (Utils.isNotEmpty(saveDirectory)) {
          String newPath =
              '$saveDirectory/${fileName ?? FileUtil.extractFileNameFromUrl(imageUrl)}';
          await copiedFile.copy(newPath);
          if (showToast) {
            IToast.showTop("图片已保存至$saveDirectory");
          }
          return true;
        } else {
          IToast.showTop("保存失败，请设置图片保存路径");
          return false;
        }
      }
    } catch (e) {
      if (e is PathNotFoundException) {
        IToast.showTop("保存路径不存在");
      }
      IToast.showTop("保存失败，请重试");
      return false;
    }
  }

  static Future<bool> saveImages(
    BuildContext context,
    List<String> imageUrls, {
    bool showToast = true,
  }) async {
    try {
      List<bool> statusList = await Future.wait(imageUrls.map((e) async {
        return await saveImage(context, e, showToast: false);
      }).toList());
      bool result = statusList.every((element) => element);
      if (showToast) {
        if (result) {
          if (ResponsiveUtil.isMobile()) {
            IToast.showTop("所有图片已保存至相册");
          } else {
            String? saveDirectory = await checkSaveDirectory(context);
            IToast.showTop("所有图片已保存至$saveDirectory");
          }
        } else {
          IToast.showTop("保存失败，请重试");
        }
      }
      return result;
    } catch (e) {
      IToast.showTop("保存失败，请重试");
      return false;
    }
  }

  static Future<bool> saveIllust(
    BuildContext context,
    Illust illust, {
    bool showToast = true,
  }) async {
    return saveImage(context, illust.url,
        fileName: getFileNameByIllust(illust), showToast: showToast);
  }

  static getFileNameByIllust(Illust illust) {
    String fileNameFormat = HiveUtil.getString(HiveUtil.filenameFormatKey,
            defaultValue: defaultFilenameFormat) ??
        defaultFilenameFormat;
    illust.originalName =
        illust.originalName.replaceAll(".${illust.extension}", "");
    String fileName = fileNameFormat
        .replaceAll(FilenameField.blogNickName.format, illust.blogNickName)
        .replaceAll(FilenameField.blogId.format, illust.blogId.toString())
        .replaceAll(FilenameField.blogLofterId.format, illust.blogLofterId)
        .replaceAll(FilenameField.originalName.format, illust.originalName)
        .replaceAll(FilenameField.part.format, illust.part.toString())
        .replaceAll(FilenameField.postId.format, illust.postId.toString())
        .replaceAll(FilenameField.timestamp.format,
            DateTime.now().millisecondsSinceEpoch.toString());
    return '$fileName.${illust.extension}';
  }

  static Future<bool> saveIllusts(
    BuildContext context,
    List<Illust> illusts, {
    bool showToast = true,
  }) async {
    try {
      List<bool> statusList = await Future.wait(illusts.map((e) async {
        return await saveIllust(context, e, showToast: false);
      }).toList());
      bool result = statusList.every((element) => element);
      if (showToast) {
        if (result) {
          if (ResponsiveUtil.isMobile()) {
            IToast.showTop("所有图片已保存至相册");
          } else {
            String? saveDirectory = await checkSaveDirectory(context);
            IToast.showTop("所有图片已保存至$saveDirectory");
          }
        } else {
          IToast.showTop("保存失败，请重试");
        }
      }
      return result;
    } catch (e) {
      IToast.showTop("保存失败，请重试");
      return false;
    }
  }

  static Future<String?> checkSaveDirectory(BuildContext context) async {
    if (ResponsiveUtil.isDesktop()) {
      String? saveDirectory = HiveUtil.getString(HiveUtil.savePathKey);
      if (Utils.isEmpty(saveDirectory)) {
        await Future.delayed(const Duration(milliseconds: 300), () async {
          String? selectedDirectory =
              await FilePicker.platform.getDirectoryPath(
            dialogTitle: "选择图片/视频保存路径",
            lockParentWindow: true,
          );
          if (selectedDirectory != null) {
            saveDirectory = selectedDirectory;
            HiveUtil.put(HiveUtil.savePathKey, selectedDirectory);
          }
        });
      }
      if (Utils.isNotEmpty(saveDirectory)) {
        Directory(saveDirectory!).createSync(recursive: true);
      }
      return saveDirectory;
    }
    return null;
  }

  static Future<bool> saveVideoByIllust(
    BuildContext context,
    Illust illust, {
    bool showToast = true,
    Function(int, int)? onReceiveProgress,
  }) async {
    return saveVideo(
      context,
      illust.url,
      fileName: getFileNameByIllust(illust),
      showToast: showToast,
      onReceiveProgress: onReceiveProgress,
    );
  }

  static Future<bool> saveVideo(
    BuildContext context,
    String videoUrl, {
    bool showToast = true,
    String? fileName,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      var appDocDir = await getTemporaryDirectory();
      String savePath = appDocDir.path + extractFileNameFromUrl(videoUrl);
      await Dio()
          .download(videoUrl, savePath, onReceiveProgress: onReceiveProgress);
      if (ResponsiveUtil.isMobile()) {
        var result = await ImageGallerySaver.saveFile(
          savePath,
          name: fileName ?? FileUtil.extractFileNameFromUrl(videoUrl),
        );
        bool success = result != null && result['isSuccess'];
        if (showToast) {
          if (success) {
            IToast.showTop("视频已保存");
          } else {
            IToast.showTop("保存失败，请重试");
          }
        }
        return success;
      } else {
        String? saveDirectory = await checkSaveDirectory(context);
        if (Utils.isNotEmpty(saveDirectory)) {
          String newPath =
              '$saveDirectory/${fileName ?? FileUtil.extractFileNameFromUrl(videoUrl)}';
          await File(savePath).copy(newPath);
          if (showToast) {
            IToast.showTop("视频已保存至$saveDirectory");
          }
          return true;
        } else {
          IToast.showTop("保存失败，请设置视频保存路径");
          return false;
        }
      }
    } catch (e) {
      if (e is PathNotFoundException) {
        IToast.showTop("保存路径不存在");
      }
      IToast.showTop("保存失败，请重试");
      return false;
    }
  }

  static Future<ReleaseAsset> getAndroidAsset(
      String latestVersion, ReleaseItem item) async {
    List<ReleaseAsset> assets = item.assets
        .where((element) =>
    element.contentType == "application/vnd.android.package-archive" &&
        element.name.endsWith(".apk"))
        .toList();
    ReleaseAsset generalAsset = assets.firstWhere(
            (element) => element.name == "CloudOTP-$latestVersion.apk",
        orElse: () => assets.first);
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      List<String> supportedAbis =
      androidInfo.supportedAbis.map((e) => e.toLowerCase()).toList();
      for (var asset in assets) {
        String abi =
            asset.name.split("CloudOTP-$latestVersion-").last.split(".").first;
        if (supportedAbis.contains(abi.toLowerCase())) {
          return asset;
        }
      }
    } finally {}
    return generalAsset;
  }

  static ReleaseAsset getWindowsPortableAsset(ReleaseItem item) {
    return item.assets.firstWhere((element) =>
    element.contentType == "application/x-zip-compressed" &&
        element.name.endsWith(".zip"));
  }

  static ReleaseAsset getWindowsInstallerAsset(ReleaseItem item) {
    return item.assets.firstWhere((element) =>
    element.contentType == "application/x-msdownload" &&
        element.name.endsWith(".exe"));
  }
}
