import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:loftify/Screens/Navigation/webview_screen.dart';
import 'package:loftify/Screens/Post/collection_detail_screen.dart';
import 'package:loftify/Screens/Post/grain_detail_screen.dart';
import 'package:loftify/Screens/Post/tag_detail_screen.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/request_header_util.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Utils/route_util.dart';
import 'package:loftify/Utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Screens/Info/user_detail_screen.dart';
import '../Screens/Post/post_detail_screen.dart';
import '../Widgets/Dialog/custom_dialog.dart';
import '../generated/l10n.dart';
import 'ilogger.dart';

class UriUtil {
  static String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  static Future<bool> launchEmailUri(BuildContext context, String email,
      {String subject = "", String body = ""}) async {
    try {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: email,
        query: encodeQueryParameters(<String, String>{
          'subject': subject,
          'body': body,
        }),
      );
      if (!await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      )) {
        if (ResponsiveUtil.isIOS()) {
          IToast.showTop(S.current.noEmailClient);
        }
        Clipboard.setData(ClipboardData(text: email));
      }
    } catch (e, t) {
      ILogger.error("Failed to launch email app", e, t);
      IToast.showTop(S.current.noEmailClient);
    }
    return true;
  }

  static share(BuildContext context, String str) {
    Share.share(str).then((shareResult) {
      if (shareResult.status == ShareResultStatus.success) {
        IToast.showTop(S.current.shareSuccess);
      } else if (shareResult.status == ShareResultStatus.dismissed) {
        IToast.showTop(S.current.cancelShare);
      } else {
        IToast.showTop(S.current.shareFailed);
      }
    });
  }

  static void launchUrlUri(BuildContext context, String url) async {
    if (HiveUtil.getBool(HiveUtil.inappWebviewKey)) {
      openInternal(context, url);
    } else {
      openExternal(url);
    }
    // if (!await launchUrl(Uri.parse(url),
    //     mode: LaunchMode.externalApplication)) {
    //   Clipboard.setData(ClipboardData(text: url));
    // }
  }

  static Future<bool> canLaunchUri(Uri uri) async {
    return await canLaunchUrl(uri);
  }

  static void launchUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static bool isShortLinkUrl(String url) {
    var reg = RegExp(r"(http|https|lofter)://s\.lofter\.com/-s/[0-9a-zA-Z]+");
    return reg.hasMatch(url);
  }

  static bool isMentionBlogIdUrl(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/mentionredirect\.do\?blogId=\d+");
    return reg.hasMatch(url);
  }

  static String extractMentionBlogId(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/mentionredirect\.do\?blogId=(\d+)");
    var match = reg.firstMatch(url);
    return match?.group(2) ?? "";
  }

  static bool isPostUrl(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://([\w-]+)\.lofter\.com/post/([0-9a-fA-F]+)_([0-9a-fA-F]+)");
    return reg.hasMatch(url);
  }

  static Map<String, String> extractPostInfo(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://([\w-]+)\.lofter\.com/post/([0-9a-fA-F]+)_([0-9a-fA-F]+)");
    var match = reg.firstMatch(url);
    if (match != null) {
      return {
        "blogName": match.group(2)!,
        "blogId": match.group(3)!,
        "postId": match.group(4)!,
      };
    } else {
      return {};
    }
  }

  static bool isVideoUrl(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/videoDetail\?permalink=[0-9a-fA-F]+_[0-9a-fA-F]+");
    return reg.hasMatch(url);
  }

  static Map<String, String> extractVideoInfo(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/videoDetail\?permalink=([0-9a-fA-F]+)_([0-9a-fA-F]+)");
    var match = reg.firstMatch(url);
    if (match != null) {
      return {
        "permalink": "${match.group(2)!}_${match.group(3)!}",
        "blogId": match.group(2)!,
        "postId": match.group(3)!,
      };
    } else {
      return {};
    }
  }

  static bool isCollectionUrl(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/front/blog/collection/share\?collectionId=\d+");
    return reg.hasMatch(url);
  }

  static int extractCollectionId(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/front/blog/collection/share\?collectionId=(\d+)");
    var match = reg.firstMatch(url);
    if (match != null) {
      return int.parse(match.group(2)!);
    } else {
      return 0;
    }
  }

  //判断是否符合lofter://www.lofter.com/collection/BLOGNAME/?op=collectionDetail&collectionId=COLLECTIONID，
  // 其中BLOGNAME为包含字母、数字和-字符的字符串，COLLECTIONID是纯数字
  static bool isCollectionShareUrl(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/collection/([-\w]+)?/\?op=collectionDetail&collectionId=(\d+)");
    return reg.hasMatch(url);
  }

  static Map extractCollectionShareInfo(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/collection/([-\w]+)?/\?op=collectionDetail&collectionId=(\d+)");
    var match = reg.firstMatch(url);
    if (match != null) {
      return {
        "blogName": match.group(2)!,
        "collectionId": int.parse(match.group(3)!),
      };
    } else {
      return {};
    }
  }

  static bool isGrainShareUrl(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/(front/blog/)?grain/detail\?grainId=(\d+)&grainUserId=(\d+)&incantation=([\w-]+)");
    return reg.hasMatch(url);
  }

  static Map extractGrainShareInfo(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/(front/blog/)?grain/detail\?grainId=(\d+)&grainUserId=(\d+)&incantation=([\w-]+)");
    var match = reg.firstMatch(url);
    if (match != null) {
      return {
        "grainId": int.parse(match.group(3)!),
        "grainUserId": int.parse(match.group(4)!),
      };
    } else {
      return {};
    }
  }

  static bool isLiveUrl(String url) {
    var reg =
        RegExp(r"(http|https|lofter)://www\.lofter\.com/live\?roomId=(\d+)");
    return reg.hasMatch(url);
  }

  static bool isTagUrl(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/(front/blog/)?tag/([-\w\u4e00-\u9fa5]+)");
    return reg.hasMatch(url);
  }

  static String extractTagName(String url) {
    var reg = RegExp(
        r"(http|https|lofter)://www\.lofter\.com/(front/blog/)?tag/([-\w\u4e00-\u9fa5]+)");
    var match = reg.firstMatch(url);
    return match?.group(3) ?? "";
  }

  static bool isHomePageUrl(String url) {
    var reg = RegExp(
        r"^(http|https|lofter)://(?!www\.$)[a-zA-Z0-9-]+\.lofter\.com/?$");
    return reg.hasMatch(url);
  }

  static String extractHomePageName(String url) {
    var reg = RegExp(
        r"^(http|https|lofter)://(?!www\.$)([a-zA-Z0-9-]+)\.lofter\.com/?$");
    var match = reg.firstMatch(url);
    return match?.group(2) ?? "";
  }

  static Future<dynamic> getRedirectUrl(String url) async {
    Response res = await RequestUtil.get(
      url.split(RequestUtil.shortUrl)[1],
      domainType: DomainType.short,
      getFullResponse: true,
      options: Options(
        headers: {
          "Connection": "keep-alive",
          "Referer": url,
          "Cookie":
              "LofterInnerBrowser=true; usertrack=c+53cWcJ4o0X34ckM2x8Ag==; JSESSIONID-WLF-XXD=ecd0454e54d08cc79a37e4ed1ce3c70349c5823c155570d49dbd03af344ace8dd4316050803ce43791c8da46634edf356eed65c1de8139ad682f77dd9bc4b477cd191c9391f5f3dd3ab39dd2c5298237423d222cd09c997a8541a23134c7e3108bef67ba167957690ed53d42fd77d3c723bca305e1cfb4ed53cbb56a05867f68c7014f32; regtoken=2000; reglogin_isLoginFlag=1; ${RequestHeaderUtil.getShortHeader()}",
          "x-requested-with": "com.lofter.android",
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0",
        },
      ),
    );
    ILogger.info("Get Redirects: ${res.redirects}");
    if (res.redirects.isNotEmpty) {
      List<String> redirects =
          res.redirects.map((e) => e.location.toString()).toList();
      redirects = redirects.where((e) => !e.contains("front/login")).toList();
      if (redirects.isNotEmpty) url = redirects.last;
    } else {
      url = res.realUri.toString();
    }
    return url;
  }

  static Future<bool> processUrl(
    BuildContext context,
    String url, {
    bool pass = true,
    bool quiet = false,
  }) async {
    try {
      if (!quiet) CustomLoadingDialog.showLoading(title: S.current.loading);
      url = Uri.decodeComponent(url);
      if (UriUtil.isShortLinkUrl(url)) {
        var tmp = url;
        url = await UriUtil.getRedirectUrl(url);
        ILogger.info("Redirect from $tmp to $url");
      }
      if (UriUtil.isMentionBlogIdUrl(url)) {
        String blogId = extractMentionBlogId(url);
        if (!quiet) await CustomLoadingDialog.dismissLoading();
        RouteUtil.pushPanelCupertinoRoute(
          context,
          UserDetailScreen(
            blogId: Utils.parseToInt(blogId),
            blogName: "",
          ),
        );
        return true;
      } else if (UriUtil.isPostUrl(url)) {
        Map<String, String> map = UriUtil.extractPostInfo(url);
        if (!quiet) await CustomLoadingDialog.dismissLoading();
        RouteUtil.pushPanelCupertinoRoute(
          context,
          PostDetailScreen(
            meta: map,
            isArticle: false,
          ),
        );
        return true;
      } else if (UriUtil.isTagUrl(url)) {
        String tag = UriUtil.extractTagName(url);
        if (!quiet) await CustomLoadingDialog.dismissLoading();
        RouteUtil.pushPanelCupertinoRoute(context, TagDetailScreen(tag: tag));
        return true;
      } else if (UriUtil.isCollectionShareUrl(url)) {
        Map collectionInfo = UriUtil.extractCollectionShareInfo(url);
        if (!quiet) await CustomLoadingDialog.dismissLoading();
        RouteUtil.pushPanelCupertinoRoute(
          context,
          CollectionDetailScreen(
            blogName: collectionInfo['blogName'],
            postId: 0,
            blogId: 0,
            collectionId: collectionInfo['collectionId'],
          ),
        );
        return true;
      } else if (UriUtil.isGrainShareUrl(url)) {
        Map grainInfo = UriUtil.extractGrainShareInfo(url);
        if (!quiet) await CustomLoadingDialog.dismissLoading();
        RouteUtil.pushPanelCupertinoRoute(
          context,
          GrainDetailScreen(
            grainId: grainInfo['grainId'],
            blogId: grainInfo['grainUserId'],
          ),
        );
        return true;
      } else if (UriUtil.isHomePageUrl(url)) {
        String blogName = UriUtil.extractHomePageName(url);
        if (!quiet) await CustomLoadingDialog.dismissLoading();
        RouteUtil.pushPanelCupertinoRoute(
          context,
          UserDetailScreen(
            blogName: blogName,
            blogId: 0,
          ),
        );
        return true;
      } else if (isLiveUrl(url)) {
        if (!quiet) await CustomLoadingDialog.dismissLoading();
        IToast.showTop("直播功能已下线");
        return false;
      } else {
        if (!quiet) await CustomLoadingDialog.dismissLoading();
        if (!quiet) {
          if (pass) {
            if (HiveUtil.getBool(HiveUtil.inappWebviewKey,
                defaultValue: true)) {
              UriUtil.openInternal(context, url);
            } else {
              UriUtil.openExternal(url);
            }
          } else {
            IToast.showTop("不支持的URI：$url");
            ILogger.info("不支持的URI：$url");
          }
        }
        return false;
      }
    } catch (e, t) {
      ILogger.error("Failed to resolve url $url", e, t);
      if (!quiet) await CustomLoadingDialog.dismissLoading();
      if (!quiet) Share.share(url);
      return false;
    }
  }

  static void openInternal(
    BuildContext context,
    String url, {
    bool processUri = true,
  }) {
    if (ResponsiveUtil.isMobile()) {
      RouteUtil.pushPanelCupertinoRoute(
          context, WebviewScreen(url: url, processUri: processUri));
    } else {
      openExternal(url);
    }
  }

  static Future<void> openExternal(String url) async {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalNonBrowserApplication,
    );
  }

  static Future<void> openExternalUri(WebUri uri) async {
    await launchUrl(
      uri,
      mode: LaunchMode.externalNonBrowserApplication,
    );
  }

  static String getPostUrlByPermalink(String blogName, String permalink) {
    return "https://$blogName.lofter.com/post/$permalink";
  }

  static String getPostUrlById(String blogName, int postId, int blogId) {
    return "https://$blogName.lofter.com/post/${Utils.intToHex(blogId)}_${Utils.intToHex(postId)}";
  }

  static String getTagUrlByTagName(String tagName, {bool isNew = true}) {
    return "https://www.lofter.com/${isNew ? "front/blog/" : ""}tag/$tagName";
  }

  static String getCollectionUrlByCollectionInfo(
      String blogName, int collectionId) {
    return "https://www.lofter.com/collection/$blogName?op=collectionDetail&collectionId=$collectionId";
  }
}
