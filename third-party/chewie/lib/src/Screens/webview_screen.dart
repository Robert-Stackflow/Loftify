import 'dart:async';
import 'dart:collection';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({
    super.key,
    required this.url,
    required this.processUri,
    this.showTitleBar = true,
    this.showProgressBar = true,
    this.onLoadingProgressChanged,
    this.onTitleChanged,
    this.onReadingProgressChanged,
    this.onWebViewCreated,
    this.onLoadUrlEnded,
  });

  final String url;
  final bool processUri;
  final bool showTitleBar;
  final bool showProgressBar;
  final Function(double)? onLoadingProgressChanged;
  final Function(String)? onTitleChanged;
  final Function(double)? onReadingProgressChanged;
  final Function(InAppWebViewController)? onWebViewCreated;
  final Function(String)? onLoadUrlEnded;

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends BaseDynamicState<WebviewScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, RefreshMixin {
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

  _buildMoreButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          chewieLocalizations.refresh,
          iconData: ChewieIcons.refresh,
          onPressed: () async {
            webViewController?.reload();
          },
        ),
        FlutterContextMenuItem(
          chewieLocalizations.copyLink,
          iconData: ChewieIcons.copy,
          onPressed: () {
            ChewieUtils.copy(context, widget.url);
          },
        ),
        FlutterContextMenuItem(
          chewieLocalizations.openWithBrowser,
          iconData: ChewieIcons.openExternal,
          onPressed: () {
            UriUtil.openExternal(widget.url);
          },
        ),
        FlutterContextMenuItem(
          chewieLocalizations.shareToOtherApps,
          iconData: ChewieIcons.share,
          onPressed: () {
            UriUtil.share(widget.url);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (_, __) {
        showError = false;
        webViewController?.canGoBack().then((canGoBack) {
          webViewController?.goBack();
        });
      },
      child: Scaffold(
        appBar: widget.showTitleBar
            ? ResponsiveAppBar(
                titleLeftMargin: 10,
                showBack: true,
                title: title,
                showBorder: true,
                onTapBack: () {
                  DialogNavigatorHelper.responsivePopPage();
                },
                actions: [
                  CircleIconButton(
                    icon: Icon(
                      LucideIcons.ellipsisVertical,
                      color: ChewieTheme.iconColor,
                    ),
                    onTap: () {
                      BottomSheetBuilder.showContextMenu(
                          context, _buildMoreButtons());
                    },
                  ),
                ],
                desktopActions: [
                  ToolButton(
                    context: context,
                    icon: LucideIcons.ellipsisVertical,
                    buttonSize: const Size(32, 32),
                    onPressed: () {
                      BottomSheetBuilder.showContextMenu(
                          context, _buildMoreButtons());
                    },
                  ),
                ],
              )
            : null,
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialUserScripts: UnmodifiableListView<UserScript>([]),
              initialSettings: settings,
              contextMenu: contextMenu,
              onWebViewCreated: (controller) async {
                webViewController = controller;
                widget.onWebViewCreated?.call(controller);
              },
              onTitleChanged: (controller, title) {
                setState(() {
                  this.title = title ?? "";
                });
                widget.onTitleChanged?.call(title ?? "");
              },
              onLoadStart: (controller, url) async {
                setState(() {
                  this.url = url.toString();
                });
              },
              onScrollChanged: (controller, x, y) async {
                int height = await controller.getContentHeight() ?? 0;
                widget.onReadingProgressChanged?.call(
                  height > 0 ? y / height : 0.0,
                );
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT);
              },
              onDownloadStartRequest: (controller, url) async {
                IToast.showTop(chewieLocalizations.jumpToBrowserDownload);
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
                widget.onLoadUrlEnded?.call(url.toString());
              },
              onReceivedError: (controller, request, error) {
                currentError = error;
                setState(() {});
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  this.progress = progress / 100;
                });
                widget.onLoadingProgressChanged?.call(progress / 100);
              },
              onUpdateVisitedHistory: (controller, url, isReload) {
                setState(() {
                  this.url = url.toString();
                });
                webViewController!.canGoBack().then((value) => canPop = !value);
              },
              onConsoleMessage: (controller, consoleMessage) {},
            ),
            progress < 1.0 && widget.showProgressBar
                ? LinearProgressIndicator(
                    value: progress,
                    color: ChewieTheme.primaryColor,
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
          color: ChewieTheme.getBackground(context),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 100),
              Icon(
                LucideIcons.triangleAlert,
                size: 50,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(height: 10),
              Text(
                chewieLocalizations.loadFailed,
                style: ChewieTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                chewieLocalizations.loadErrorType(currentError != null
                    ? currentError?.type ?? ""
                    : chewieLocalizations.loadUnkownError),
                style: ChewieTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Container(
                width: 180,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: RoundIconTextButton(
                  text: chewieLocalizations.reload,
                  onPressed: () {
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

  @override
  bool get wantKeepAlive => true;

  @override
  ScrollController? getScrollController() => null;

  @override
  FutureOr refresh() {}

  @override
  FutureOr scrollToTop() {}
}
