import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loftify/Models/github_response.dart';
import 'package:loftify/Models/illust.dart';
import 'package:loftify/Screens/Setting/update_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/file_util.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Widgets/BottomSheet/slide_captcha_bottom_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:palette_generator/palette_generator.dart';

import '../Api/github_api.dart';
import '../Widgets/Dialog/custom_dialog.dart';
import '../Widgets/Dialog/dialog_builder.dart';
import '../generated/l10n.dart';
import 'app_provider.dart';
import 'constant.dart';
import 'ilogger.dart';
import 'itoast.dart';

class Utils {
  static getDownloadUrl(String version, String name) {
    return "$downloadPkgsUrl/$version/$name";
  }

  static String getFormattedDate(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd-HH-mm-ss").format(dateTime);
  }

  static Brightness currentBrightness(BuildContext context) {
    return appProvider.getBrightness() ??
        MediaQuery.of(context).platformBrightness;
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
    return (appProvider.themeMode == ActiveThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark) ||
        appProvider.themeMode == ActiveThemeMode.dark;
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

  static getIndexOfImage(String image, List<Illust> illusts) {
    return illusts.indexWhere((element) =>
        Utils.removeImageParam(element.url) == Utils.removeImageParam(image));
  }

  static String replaceLineBreak(String str) {
    return str.replaceAll(RegExp(r"\r\n"), "<br/>");
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
      File file = await FileUtil.getImageFile(context, imageUrl);
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
    return Utils.isNotEmpty(blogName) ? "$blogName.lofter.com" : "";
  }

  static addSearchHistory(String str) {
    if (HiveUtil.getBool(HiveUtil.showSearchHistoryKey, defaultValue: true)) {
      while (appProvider.searchHistoryList.contains(str)) {
        appProvider.searchHistoryList.remove(str);
      }
      List<String> tmp = deepCopy(appProvider.searchHistoryList);
      tmp.insert(0, str);
      appProvider.searchHistoryList = tmp;
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
      } catch (e, t) {
        ILogger.error("Failed to parse int $value", e, t);
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
        IToast.showTop(toastText ?? "");
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

  static Map<String, dynamic> parseJson(String jsonStr) {
    return json.decode(jsonStr);
  }

  static List<dynamic> parseJsonList(String jsonStr) {
    return json.decode(jsonStr);
  }

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

  static handleDownloadSuccessAction({
    Function()? onUnlike,
    Function()? onUnrecommend,
  }) {
    DownloadSuccessAction action = DownloadSuccessAction.values[Utils.patchEnum(
        HiveUtil.getInt(HiveUtil.downloadSuccessActionKey),
        DownloadSuccessAction.values.length)];
    switch (action) {
      case DownloadSuccessAction.none:
        break;
      case DownloadSuccessAction.unlike:
        onUnlike?.call();
        break;
      case DownloadSuccessAction.unrecommend:
        onUnrecommend?.call();
        break;
    }
  }

  static compareVersion(String a, String b) {
    if (Utils.isEmpty(a) || Utils.isEmpty(b)) {
      ILogger.warn("Version is empty, compare failed between $a and $b");
      return a.compareTo(b);
    }
    try {
      List<String> aList = a.split(".");
      List<String> bList = b.split(".");
      for (int i = 0; i < aList.length; i++) {
        if (int.parse(aList[i]) > int.parse(bList[i])) {
          return 1;
        } else if (int.parse(aList[i]) < int.parse(bList[i])) {
          return -1;
        }
      }
      return 0;
    } catch (e, t) {
      ILogger.error("Failed to compare version $a and $b", e, t);
      return a.compareTo(b);
    }
  }

  static getReleases({
    required BuildContext context,
    Function(String)? onGetCurrentVersion,
    Function(List<ReleaseItem>)? onGetReleases,
    Function(String, ReleaseItem)? onGetLatestRelease,
    Function(String, ReleaseItem)? onUpdate,
    bool showLoading = false,
    bool showUpdateDialog = true,
    bool showNoUpdateToast = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: "检查更新中...");
    }
    String currentVersion = (await PackageInfo.fromPlatform()).version;
    onGetCurrentVersion?.call(currentVersion);
    String latestVersion = "0.0.0";
    await GithubApi.getReleases("Robert-Stackflow", "Loftify")
        .then((releases) async {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
      if (releases.isEmpty) {
        if (showNoUpdateToast) IToast.showTop("检查更新失败");
        return;
      }
      onGetReleases?.call(releases);
      ReleaseItem? latestReleaseItem;
      for (var release in releases) {
        String tagName = release.tagName;
        tagName = tagName.replaceAll(RegExp(r'[a-zA-Z]'), '');
        if (compareVersion(latestVersion, tagName) <= 0) {
          latestVersion = tagName;
          latestReleaseItem = release;
        }
      }
      onGetLatestRelease?.call(latestVersion, latestReleaseItem!);
      if (compareVersion(latestVersion, currentVersion) > 0) {
        onUpdate?.call(latestVersion, latestReleaseItem!);
        if (showUpdateDialog && latestReleaseItem != null) {
          if (ResponsiveUtil.isMobile()) {
            DialogBuilder.showConfirmDialog(
              context,
              title: "发现新版本$latestVersion",
              message:
                  "是否立即更新？${Utils.isNotEmpty(latestReleaseItem.body) ? "更新日志如下：\n${latestReleaseItem.body}" : ""}",
              confirmButtonText: "立即下载",
              cancelButtonText: "暂不更新",
              onTapConfirm: () async {
                if (ResponsiveUtil.isAndroid()) {
                  ReleaseAsset androidAssset = await FileUtil.getAndroidAsset(
                      latestVersion, latestReleaseItem!);
                  ILogger.info("Get android asset: $androidAssset");
                  FileUtil.downloadAndUpdate(
                    context,
                    androidAssset.browserDownloadUrl,
                    latestReleaseItem.htmlUrl,
                    version: latestVersion,
                  );
                } else {
                  UriUtil.openExternal(latestReleaseItem!.htmlUrl);
                  return;
                }
              },
              onTapCancel: () {},
              customDialogType: CustomDialogType.normal,
            );
          } else {
            DialogBuilder.showPageDialog(
              context,
              child: UpdateScreen(
                currentVersion: currentVersion,
                latestReleaseItem: latestReleaseItem,
                latestVersion: latestVersion,
              ),
            );
          }
        }
      } else {
        if (showNoUpdateToast) {
          IToast.showTop(S.current.checkUpdatesAlreadyLatest);
        }
      }
    });
  }
}
