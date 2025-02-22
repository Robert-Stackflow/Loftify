import 'dart:collection';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/uri_util.dart';

import '../../Utils/constant.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({
    super.key,
    required this.url,
    required this.processUri,
  });

  static const String routeName = "/webview";
  final String url;
  final bool processUri;

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen>
    with TickerProviderStateMixin {
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
    allowsLinkPreview: false,
    useOnDownloadStart: true,
  );
  late ContextMenu contextMenu;
  String url = "";
  String title = "";
  bool canPop = true;
  bool showError = false;
  WebResourceError? currentError;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    contextMenu = ContextMenu(
      settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: false),
      onCreateContextMenu: (hitTestResult) async {},
      onHideContextMenu: () {},
      onContextMenuActionItemClicked: (contextMenuItemClicked) async {},
    );
  }

  initCookie() async {
    CookieManager cookieManager = CookieManager.instance();
    final expiresDate =
        DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch;
    final url = WebUri(widget.url);
    Map map = HiveUtil.getCookie();
    map.forEach((k, v) async {
      await cookieManager.setCookie(
        url: url,
        name: k,
        value: v,
        expiresDate: expiresDate,
        isSecure: true,
      );
    });
    webViewController?.addUserScript(
      userScript: UserScript(
          source:
              'if(document.querySelector("html").classList.contains("lofter-page"))',
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END),
    );
  }

  _buildMoreButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          S.current.refresh,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () async {
            webViewController?.reload();
          },
        ),
        ContextMenuButtonConfig(
          S.current.copyLink,
          icon: const Icon(Icons.copy_rounded),
          onPressed: () {
            Utils.copy(context, widget.url);
          },
        ),
        ContextMenuButtonConfig(
          S.current.openWithBrowser,
          icon: const Icon(Icons.open_in_browser_rounded),
          onPressed: () {
            UriUtil.openExternal(widget.url);
          },
        ),
        ContextMenuButtonConfig(
          S.current.shareToOtherApps,
          icon: const Icon(Icons.share_rounded),
          onPressed: () {
            UriUtil.share(context, widget.url);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (_, __) {
        showError = false;
        webViewController?.canGoBack().then((canGoBack) {
          webViewController?.goBack();
        });
      },
      child: Scaffold(
        backgroundColor: MyTheme.getBackground(context),
        appBar: ItemBuilder.buildSimpleAppBar(
          context: context,
          leadingIcon: Icons.close_rounded,
          titleLeftMargin: 10,
          titleRightMargin: 10,
          centerTitle: true,
          title: title,
          actions: [
            ItemBuilder.buildIconButton(
              context: context,
              icon: Icon(Icons.more_vert_rounded,
                  color: Theme.of(context).iconTheme.color),
              onTap: () {
                BottomSheetBuilder.showContextMenu(
                    context, _buildMoreButtons());
              },
            ),
            const SizedBox(width: 5),
          ],
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialUserScripts: UnmodifiableListView<UserScript>([]),
              initialSettings: settings,
              contextMenu: contextMenu,
              onWebViewCreated: (controller) async {
                webViewController = controller;
                initCookie();
              },
              onTitleChanged: (controller, title) {
                setState(() {
                  this.title = title ?? "";
                });
              },
              onLoadStart: (controller, url) async {
                setState(() {
                  this.url = url.toString();
                });
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT);
              },
              onDownloadStartRequest: (controller, url) async {
                IToast.showTop(S.current.jumpToBrowserDownload);
                Future.delayed(const Duration(milliseconds: 300), () {
                  UriUtil.openExternalUri(url.url);
                });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url!;
                if (![
                  "http",
                  "https",
                  "file",
                  "chrome",
                  "data",
                  "javascript",
                  "about",
                  "lofter",
                ].contains(uri.scheme)) {
                  if (await UriUtil.canLaunchUri(uri)) {
                    UriUtil.launchUri(uri);
                    return NavigationActionPolicy.CANCEL;
                  }
                }
                bool processed = widget.processUri
                    ? await UriUtil.processUrl(
                        context,
                        uri.toString(),
                        quiet: true,
                        pass: true,
                      )
                    : false;
                if (processed) return NavigationActionPolicy.CANCEL;
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  this.url = url.toString();
                });
                await controller.evaluateJavascript(
                    source:
                        'javascript:!function(){function t(e){e.stopPropagation(),e.stopImmediatePropagation&&e.stopImmediatePropagation()}document.querySelectorAll("*").forEach(e=>{"none"===window.getComputedStyle(e,null).getPropertyValue("user-select")&&e.style.setProperty("user-select","text","important")}),["copy","cut","contextmenu","selectstart","mousedown","mouseup","mousemove","keydown","keypress","keyup"].forEach(function(e){document.documentElement.addEventListener(e,t,{capture:!0})})}();');
                if (Utils.isDark(context)) {
                  await controller.evaluateJavascript(
                      source:
                          'document.querySelector("html").classList.add("nw-dark-mode");document.querySelector("html").classList.remove("nw-light-mode");');
                } else {
                  await controller.evaluateJavascript(
                      source:
                          'document.querySelector("html").classList.add("nw-light-mode");document.querySelector("html").classList.remove("nw-dark-mode");');
                }
                // String html = await controller.getHtml() ?? "";
                // if (html.contains('<html lang="zh" class="lofter-page')) {
                //   setState(() {
                //     showAppBar = false;
                //   });
                // }
              },
              onReceivedError: (controller, request, error) {
                currentError = error;
                // if (error.type != WebResourceErrorType.UNSUPPORTED_SCHEME) {
                //   showError = true;
                // }
                setState(() {});
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  this.progress = progress / 100;
                });
              },
              onUpdateVisitedHistory: (controller, url, isReload) {
                setState(() {
                  this.url = url.toString();
                });
                webViewController!.canGoBack().then((value) => canPop = !value);
              },
              onConsoleMessage: (controller, consoleMessage) {},
            ),
            progress < 1.0
                ? LinearProgressIndicator(
                    value: progress,
                    color: Theme.of(context).primaryColor,
                    backgroundColor: Colors.transparent,
                    minHeight: 2,
                  )
                : emptyWidget,
            _buildErrorPage(),
          ],
        ),
      ),
    );
  }

  _buildErrorPage() {
    return Visibility(
      visible: showError,
      child: Container(
        height: MediaQuery.sizeOf(context).height - 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: MyTheme.getBackground(context),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 100),
              Icon(
                Icons.dangerous_rounded,
                size: 50,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(height: 10),
              Text(
                S.current.loadFailed,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                S.current.loadErrorType(currentError != null
                    ? currentError?.type ?? ""
                    : S.current.loadUnkownError),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Container(
                width: 180,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: ItemBuilder.buildRoundButton(
                  context,
                  text: S.current.reload,
                  onTap: () {
                    webViewController?.reload();
                  },
                  fontSizeDelta: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
