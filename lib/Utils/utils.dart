import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/iprint.dart';
import 'package:loftify/Utils/notification_util.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Widgets/BottomSheet/slide_captcha_bottom_sheet.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restart_app/restart_app.dart';
import 'package:share_plus/share_plus.dart';

import '../Providers/global_provider.dart';
import '../Providers/provider_manager.dart';
import '../Screens/main_screen.dart';
import 'itoast.dart';

class Utils {
  static void restartApp() {
    Restart.restartApp();
  }

  static void returnToMainScreen(BuildContext context) {
    Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (context) => const MainScreen()),
        (route) => false);
  }

  static String processEmpty(String? str, {String defaultValue = ""}) {
    return isEmpty(str) ? defaultValue : str!;
  }

  static bool isEmpty(String? str) {
    return str == null || str.isEmpty;
  }

  static bool isNotEmpty(String? str) {
    return !isEmpty(str);
  }

  static String getHeroTag({
    String? tagPrefix,
    String? tagSuffix,
    String? url,
  }) {
    return "${processEmpty(tagPrefix)}-${Utils.removeImageParam(processEmpty(url))}-${processEmpty(tagSuffix)}";
  }

  static double getMaxHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeArea = MediaQuery.of(context).padding;
    final appBarHeight = AppBar().preferredSize.height;
    return screenHeight - appBarHeight - safeArea.top;
  }

  static String getRandomString({int length = 8}) {
    final random = Random();
    const availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    final randomString = List.generate(length,
            (index) => availableChars[random.nextInt(availableChars.length)])
        .join();
    return randomString;
  }

  static isDark(BuildContext context) {
    return (ProviderManager.globalProvider.themeMode ==
                ActiveThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark) ||
        ProviderManager.globalProvider.themeMode == ActiveThemeMode.dark;
  }

  static Color getDarkColor(Color color, {Color darkColor = Colors.black}) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? color
        : darkColor;
  }

  static String extractTextFromHtml(String html) {
    var document = parse(html);
    return document.body?.text ?? "";
  }

  static List<String> extractImagesFromHtml(String html) {
    var document = parse(html);
    var images = document.getElementsByTagName("img");
    return images.map((e) => e.attributes["src"] ?? "").toList();
  }

  static getIndexOfImage(String image, List<String> images) {
    return images.indexWhere((element) =>
        Utils.removeImageParam(element) == Utils.removeImageParam(image));
  }

  static String extractFileNameFromUrl(String imageUrl) {
    return Uri.parse(imageUrl).pathSegments.last;
  }

  static String replaceLineBreak(String str) {
    return str.replaceAll(RegExp(r"\r\n"), "<br/>");
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
      IToast.showTop(context, text: "分享成功");
    } else if (result.status == ShareResultStatus.dismissed) {
      IToast.showTop(context, text: "取消分享");
    } else {
      IToast.showTop(context, text: "分享失败");
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
      File copiedFile =
          await copyAndRenameFile(file, Utils.extractFileNameFromUrl(imageUrl));
      if (Utils.isMobile()) {
        var result = await ImageGallerySaver.saveFile(
          copiedFile.path,
          name: Utils.extractFileNameFromUrl(imageUrl),
        );
        bool success = result != null && result['isSuccess'];
        if (showToast) {
          if (success) {
            IToast.showTop(context, text: "图片已保存至相册");
          } else {
            IToast.showTop(context, text: "保存失败，请重试");
          }
        }
        return success;
      } else {
        String? saveDirectory = await checkSaveDirectory(context);
        if (Utils.isNotEmpty(saveDirectory)) {
          String newPath =
              '$saveDirectory/${Utils.extractFileNameFromUrl(imageUrl)}';
          await copiedFile.copy(newPath);
          if (showToast) {
            IToast.showTop(context, text: "图片已保存至$saveDirectory");
          }
          return true;
        } else {
          IToast.showTop(context, text: "保存失败，请设置图片保存路径");
          return false;
        }
      }
    } catch (e) {
      if (e is PathNotFoundException) {
        IToast.showTop(context, text: "保存路径不存在");
      }
      IToast.showTop(context, text: "保存失败，请重试");
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
          if (Utils.isMobile()) {
            IToast.showTop(context, text: "所有图片已保存至相册");
          } else {
            String? saveDirectory = await checkSaveDirectory(context);
            IToast.showTop(context, text: "所有图片已保存至$saveDirectory");
          }
        } else {
          IToast.showTop(context, text: "保存失败，请重试");
        }
      }
      return result;
    } catch (e) {
      IToast.showTop(context, text: "保存失败，请重试");
      return false;
    }
  }

  static Future<String?> checkSaveDirectory(BuildContext context) async {
    if (Utils.isDesktop()) {
      String? saveDirectory = HiveUtil.getString(key: HiveUtil.savePathKey);
      if (Utils.isEmpty(saveDirectory)) {
        await Future.delayed(const Duration(milliseconds: 300), () async {
          String? selectedDirectory =
              await FilePicker.platform.getDirectoryPath(
            dialogTitle: "选择图片/视频保存路径",
            lockParentWindow: true,
          );
          if (selectedDirectory != null) {
            saveDirectory = selectedDirectory;
            HiveUtil.put(key: HiveUtil.savePathKey, value: selectedDirectory);
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

  static Future<bool> saveVideo(
    BuildContext context,
    String videoUrl, {
    bool showToast = true,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      var appDocDir = await getTemporaryDirectory();
      String savePath = appDocDir.path + extractFileNameFromUrl(videoUrl);
      await Dio()
          .download(videoUrl, savePath, onReceiveProgress: onReceiveProgress);
      if (Utils.isMobile()) {
        var result = await ImageGallerySaver.saveFile(
          savePath,
          name: Utils.extractFileNameFromUrl(videoUrl),
        );
        bool success = result != null && result['isSuccess'];
        if (showToast) {
          if (success) {
            IToast.showTop(context, text: "视频已保存");
          } else {
            IToast.showTop(context, text: "保存失败，请重试");
          }
        }
        return success;
      } else {
        String? saveDirectory = await checkSaveDirectory(context);
        if (Utils.isNotEmpty(saveDirectory)) {
          String newPath =
              '$saveDirectory/demo/${Utils.extractFileNameFromUrl(videoUrl)}';
          await File(savePath).copy(newPath);
          if (showToast) {
            IToast.showTop(context, text: "视频已保存至$saveDirectory");
          }
          return true;
        } else {
          IToast.showTop(context, text: "保存失败，请设置视频保存路径");
          return false;
        }
      }
    } catch (e) {
      if (e is PathNotFoundException) {
        IToast.showTop(context, text: "保存路径不存在");
      }
      IToast.showTop(context, text: "保存失败，请重试");
      return false;
    }
  }

  static String removeWatermark(String str) {
    return str.split("watermark")[0];
  }

  static String removeImageParam(String str) {
    return str.split("?imageView")[0];
  }

  static bool isGIF(String str) {
    return str.contains(".gif");
  }

  static int hexToInt(String hex) {
    return int.parse(hex, radix: 16);
  }

  static String intToHex(int value) {
    return value.toRadixString(16);
  }

  static patchEnum(int index, int length, {int defaultValue = 0}) {
    return index < 0 || index > length - 1 ? defaultValue : index;
  }

  static String getUrlByQuality(
    String url,
    ImageQuality quality, {
    bool removeWatermark = true,
    bool smallest = false,
  }) {
    String qualitiedUrl = url;
    String rawUrl = removeImageParam(url);
    if (rawUrl.endsWith(".gif")) return rawUrl;
    switch (quality) {
      case ImageQuality.raw:
        qualitiedUrl = removeImageParam(url);
        break;
      case ImageQuality.origin:
        qualitiedUrl =
            "${removeImageParam(url)}?imageView&thumbnail=1680x0&quality=96";
        break;
      case ImageQuality.medium:
        qualitiedUrl =
            "${removeImageParam(url)}?imageView&thumbnail=500x0&quality=96";
        break;
      case ImageQuality.small:
        qualitiedUrl = smallest
            ? "${removeImageParam(url)}?imageView&thumbnail=64y64&quality=40"
            : "${removeImageParam(url)}?imageView&thumbnail=164y164&enlarge=1&quality=90";
        break;
    }
    return removeWatermark ? Utils.removeWatermark(qualitiedUrl) : qualitiedUrl;
  }

  static Future<EncodedImage> _getImagePixelsByUrl(String url) async {
    final Completer<EncodedImage> completer = Completer();
    final ImageStream stream =
        CachedNetworkImageProvider(url).resolve(const ImageConfiguration());
    final listener =
        ImageStreamListener((ImageInfo info, bool synchronousCall) async {
      final ByteData? data = await info.image.toByteData();
      if (data != null && !completer.isCompleted) {
        completer.complete(
            EncodedImage(data, width: 1, height: data.lengthInBytes ~/ 4));
      }
    });
    stream.addListener(listener);
    final EncodedImage encodedImage = await completer.future;
    stream.removeListener(listener);
    return encodedImage;
  }

  static Future<EncodedImage> _getImagePixelsByFile(File file) async {
    final Completer<EncodedImage> completer = Completer();
    final ImageStream stream =
        FileImage(file).resolve(const ImageConfiguration());
    final listener =
        ImageStreamListener((ImageInfo info, bool synchronousCall) async {
      final ByteData? data = await info.image.toByteData();
      if (data != null && !completer.isCompleted) {
        completer.complete(
            EncodedImage(data, width: 1, height: data.lengthInBytes ~/ 4));
      }
    });
    stream.addListener(listener);
    final EncodedImage encodedImage = await completer.future;
    stream.removeListener(listener);
    return encodedImage;
  }

  static FutureOr<PaletteGenerator> _getPaletteGenerator(
    EncodedImage encodedImage,
  ) async {
    final Completer<PaletteGenerator> completer = Completer();
    PaletteGenerator.fromByteData(encodedImage).then((paletteGenerator) {
      completer.complete(paletteGenerator);
    });
    return await completer.future;
  }

  static Future<PaletteGenerator> getPaletteGenerator(
    String imageUrl, {
    BuildContext? context,
    bool getByFile = true,
  }) async {
    late final EncodedImage encodedImage;
    if (getByFile && context != null) {
      File file = await getImageFile(context, imageUrl);
      encodedImage = await _getImagePixelsByFile(file);
    } else {
      encodedImage = await _getImagePixelsByUrl(imageUrl);
    }
    PaletteGenerator generator =
        await compute(_getPaletteGenerator, encodedImage);
    return generator;
  }

  static Future<List<Color>> getMainColors(
    BuildContext context,
    List<String> imageUrls, {
    Function()? onFinished,
  }) async {
    List<Color> mainColors = List.filled(imageUrls.length, Colors.black);
    for (var e in imageUrls) {
      int index = imageUrls.indexOf(e);
      String smallUrl = Utils.getUrlByQuality(
        e,
        ImageQuality.small,
        smallest: true,
      );
      await Utils.getPaletteGenerator(smallUrl, context: context)
          .then((paletteGenerator) {
        if (paletteGenerator.darkMutedColor != null) {
          mainColors[index] = paletteGenerator.darkMutedColor!.color;
        } else if (paletteGenerator.darkVibrantColor != null) {
          mainColors[index] = paletteGenerator.darkVibrantColor!.color;
        }
      });
    }
    return mainColors;
  }

  static String getBlogDomain(String? blogName) {
    return "$blogName.lofter.com";
  }

  static addSearchHistory(String str) {
    if (HiveUtil.getBool(
        key: HiveUtil.showSearchHistoryKey, defaultValue: true)) {
      while (ProviderManager.globalProvider.searchHistoryList.contains(str)) {
        ProviderManager.globalProvider.searchHistoryList.remove(str);
      }
      List<String> tmp =
          deepCopy(ProviderManager.globalProvider.searchHistoryList);
      tmp.insert(0, str);
      ProviderManager.globalProvider.searchHistoryList = tmp;
    }
  }

  static List<T> deepCopy<T>(List<T> list) {
    return List<T>.from(list);
  }

  static int parseToInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    } else {
      return 0;
    }
  }

  static Map formatCountToMap(int count) {
    if (count < 10000) {
      return {"count": count.toString()};
    } else {
      return {"count": (count / 10000).toStringAsFixed(1), "scale": "万"};
    }
  }

  static String formatCount(int count) {
    if (count < 10000) {
      return count.toString();
    } else {
      return "${(count / 10000).toStringAsFixed(1)}万";
    }
  }

  static String formatDuration(int duration) {
    var minutes = duration ~/ 60;
    var seconds = duration % 60;
    return "${minutes < 10 ? "0$minutes" : minutes}:${seconds < 10 ? "0$seconds" : seconds}";
  }

  static String limitString(String str, {int limit = 30}) {
    return str.length > limit ? str.substring(0, limit) : str;
  }

  static String clearBlank(String str, {bool keepOne = true}) {
    return str.trim().replaceAll(RegExp(r"\s+"), keepOne ? " " : "");
  }

  static void copy(
    BuildContext context,
    dynamic data, {
    String? toastText = "已复制到剪贴板",
  }) {
    Clipboard.setData(ClipboardData(text: data.toString())).then((value) {
      if (Utils.isNotEmpty(toastText)) {
        IToast.showTop(context, text: toastText ?? "");
      }
    });
    HapticFeedback.mediumImpact();
  }

  static String formatYearMonth(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateFormat = DateFormat("yyyy年MM月");
    return dateFormat.format(date);
  }

  static String formatTimestamp(int timestamp) {
    var now = DateTime.now();
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateFormat = DateFormat("yyyy-MM-dd");
    var dateFormat2 = DateFormat("MM-dd");
    var diff = now.difference(date);
    if (date.year != now.year) {
      return dateFormat.format(date);
    } else if (diff.inDays > 7) {
      return dateFormat2.format(date);
    } else if (diff.inDays > 0) {
      return "${diff.inDays + 1}天前";
    } else if (diff.inHours > 0) {
      return "${date.hour < 10 ? "0${date.hour}" : date.hour}:${date.minute < 10 ? "0${date.minute}" : date.minute}";
    } else {
      return "${date.minute}分钟前";
    }
  }

  //将json字符串解析为Map对象
  static Map<String, dynamic> parseJson(String jsonStr) {
    return json.decode(jsonStr);
  }

  static List<dynamic> parseJsonList(String jsonStr) {
    return json.decode(jsonStr);
  }

  ///
  /// 二分查找
  ///
  static int binarySearch<T>(
      List<T> sortedList, T value, int Function(T, T) compare) {
    var min = 0;
    var max = sortedList.length;
    while (min < max) {
      var mid = min + ((max - min) >> 1);
      var element = sortedList[mid];
      var comp = compare(element, value);
      if (comp == 0) return mid;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return min;
  }

  static final _urlRegex = RegExp(
    r"^https?://(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,63}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*$)",
    caseSensitive: false,
  );

  static bool isUrl(String url) => _urlRegex.hasMatch(url.trim());

  static bool notEmpty(String text) => text.trim().isNotEmpty;

  ///
  /// 获取某个网站的图标
  ///
  static Future<String?> fetchFavicon(String url) async {
    try {
      url = url.split("/").getRange(0, 3).join("/");
      var uri = Uri.parse(url);
      var result = await http.get(uri);
      if (result.statusCode == 200) {
        var htmlStr = result.body;
        var dom = parse(htmlStr);
        var links = dom.getElementsByTagName("link");
        for (var link in links) {
          var rel = link.attributes["rel"];
          if ((rel == "icon" || rel == "shortcut icon") &&
              link.attributes.containsKey("href")) {
            var href = link.attributes["href"]!;
            var parsedUrl = Uri.parse(url);
            if (href.startsWith("//")) {
              return "${parsedUrl.scheme}:$href";
            } else if (href.startsWith("/")) {
              return url + href;
            } else {
              return href;
            }
          }
        }
      }
      url = "$url/favicon.ico";
      if (await Utils.validateFavicon(url)) {
        return url;
      } else {
        return null;
      }
    } catch (exp) {
      return null;
    }
  }

  static Future<bool> validateFavicon(String url) async {
    var flag = false;
    var uri = Uri.parse(url);
    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var contentType =
          result.headers["Content-Type"] ?? result.headers["content-type"];
      if (contentType != null && contentType.startsWith("image")) flag = true;
    }
    return flag;
  }

  static void validSlideCaptcha(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const SlideCaptchaBottomSheet();
      },
    );
  }

  static bool isAndroid() {
    return Platform.isAndroid;
  }

  static bool isMobile() {
    return !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  }

  static bool isDesktop() {
    return !kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
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
      IToast.showTop(context, text: "请授予文件存储权限");
    }).onGrantedCallback(() async {
      if (Utils.isNotEmpty(apkUrl)) {
        double progressValue = 0.0;
        var appDocDir = await getTemporaryDirectory();
        String savePath =
            "${appDocDir.path}/${Utils.extractFileNameFromUrl(apkUrl)}";
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
      IToast.showTop(context, text: "已拒绝文件存储权限，将跳转到浏览器下载");
      UriUtil.openExternal(apkUrl);
    }).onRestrictedCallback(() {
      IToast.showTop(context, text: "请授予文件存储权限");
    }).onLimitedCallback(() {
      IToast.showTop(context, text: "请授予文件存储权限");
    }).onProvisionalCallback(() {
      IToast.showTop(context, text: "请授予文件存储权限");
    }).request();
  }
}
