import 'dart:async';
import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'photo_view_dismiss_metrics.dart';

enum DownloadState { none, loading, succeed, failed }

String resolvePhotoViewOriginalUrl(String url) {
  final imageViewIndex = url.indexOf('?imageView');
  return imageViewIndex < 0 ? url : url.substring(0, imageViewIndex);
}

class HeroPhotoViewScreen extends StatefulWidget {
  HeroPhotoViewScreen({
    super.key,
    required this.imageUrls,
    this.initialScale = PhotoViewComputedScale.contained,
    this.minScale = PhotoViewComputedScale.contained,
    this.maxScale,
    this.initIndex,
    this.useMainColor = true,
    this.captions,
    this.onIndexChanged,
    this.title,
    this.tagPrefix,
    this.tagSuffix,
    this.mainColors,
    this.onDownloadSuccess,
  }) : assert(imageUrls.isNotEmpty);

  final String? title;
  final String? tagPrefix;
  final String? tagSuffix;
  final List<String> imageUrls;
  final List<String>? captions;
  final dynamic initialScale;
  final dynamic minScale;
  final dynamic maxScale;
  final int? initIndex;
  final bool useMainColor;
  final List<Color>? mainColors;
  final Function(int)? onIndexChanged;
  final Function()? onDownloadSuccess;

  @override
  State<HeroPhotoViewScreen> createState() => HeroPhotoViewScreenState();
}

enum UrlType { string, photoLink, illust }

class HeroPhotoViewScreenState extends State<HeroPhotoViewScreen>
    with TickerProviderStateMixin {
  late final List<String> imageUrls;
  late final List<String> _heroUrls;
  late final List<String> captions;
  late final dynamic initialScale;
  late final dynamic minScale;
  late final dynamic maxScale;
  String currentUrl = "";
  int currentIndex = 0;
  List<Color> mainColors = [];
  late dynamic downloadIcon;
  DownloadState downloadState = DownloadState.none;
  late dynamic allDownloadIcon;
  DownloadState allDownloadState = DownloadState.none;
  late PageController _pageController;
  final List<PhotoViewController> _viewControllers = [];
  final List<PhotoViewScaleStateController> _scaleStateControllers = [];
  late final List<int> _imageRetryTokens;
  late final AnimationController _dismissAnimationController;
  final Set<String> _prefetchedImageUrls = <String>{};
  final Set<int> _activePointers = <int>{};
  Timer? _downloadRecoveryTimer;
  Timer? _allDownloadRecoveryTimer;
  VelocityTracker? _dismissVelocityTracker;
  Offset? _dismissStartPosition;
  int? _dismissPointer;
  double _dismissOffset = 0;
  bool _dismissCandidate = false;
  bool _isDraggingToDismiss = false;
  bool _isDismissing = false;
  double _dismissAnimationStart = 0;
  double _dismissAnimationEnd = 0;

  @override
  void initState() {
    super.initState();
    _dismissAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(_handleDismissAnimationTick);
    setDownloadState(DownloadState.none, recover: false);
    setAllDownloadState(DownloadState.none, recover: false);
    _heroUrls = List.unmodifiable(widget.imageUrls);
    imageUrls = List.unmodifiable(
      widget.imageUrls.map(resolvePhotoViewOriginalUrl),
    );
    _viewControllers.addAll(List.generate(imageUrls.length, (index) {
      return PhotoViewController();
    }));
    _scaleStateControllers.addAll(List.generate(imageUrls.length, (index) {
      return PhotoViewScaleStateController();
    }));
    _imageRetryTokens = List.filled(imageUrls.length, 0);
    captions = List.unmodifiable(widget.captions ?? const <String>[]);
    minScale = widget.minScale;
    maxScale = widget.maxScale;
    initialScale = widget.initialScale;
    currentIndex = widget.initIndex ?? 0;
    currentIndex = max(0, min(currentIndex, imageUrls.length - 1));
    _pageController = PageController(initialPage: currentIndex);
    if (widget.mainColors != null &&
        widget.mainColors!.length >= imageUrls.length &&
        ChewieHiveUtil.getBool(ChewieHiveUtil.followMainColorKey)) {
      mainColors = List.unmodifiable(widget.mainColors!);
    } else {
      mainColors = List.filled(imageUrls.length, Colors.black);
      if (widget.useMainColor &&
          ChewieHiveUtil.getBool(ChewieHiveUtil.followMainColorKey)) {
        ColorUtil.getMainColors(
          context,
          List.generate(imageUrls.length, getUrl),
        ).then((value) {
          if (!mounted) return;
          setState(() {
            mainColors = List.generate(
              imageUrls.length,
              (index) => index < value.length ? value[index] : Colors.black,
            );
          });
        });
      }
    }
    updateCurrentUrl();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prefetchAround(currentIndex);
    });
  }

  @override
  void dispose() {
    _downloadRecoveryTimer?.cancel();
    _allDownloadRecoveryTimer?.cancel();
    _dismissAnimationController.dispose();
    _pageController.dispose();
    for (final controller in _viewControllers) {
      controller.dispose();
    }
    for (final controller in _scaleStateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final dismissProgress = PhotoViewDismissMetrics.progress(
      _dismissOffset,
      viewportHeight,
    );
    final backgroundColor = ColorUtil.getDarkColor(mainColors[currentIndex]);

    return ColoredBox(
      color: backgroundColor.withValues(
        alpha: PhotoViewDismissMetrics.backgroundOpacity(dismissProgress),
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: IgnorePointer(
            ignoring: dismissProgress > 0.4,
            child: Opacity(
              opacity: PhotoViewDismissMetrics.appBarOpacity(dismissProgress),
              child: Stack(
                children: [
                  _buildAppBar(),
                  if (ResponsiveUtil.isDesktop()) const WindowMoveHandle(),
                ],
              ),
            ),
          ),
        ),
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Transform.translate(
          offset: Offset(0, _dismissOffset),
          child: Transform.scale(
            scale: PhotoViewDismissMetrics.scale(dismissProgress),
            child: Opacity(
              opacity: PhotoViewDismissMetrics.contentOpacity(dismissProgress),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerUp,
                onPointerCancel: _handlePointerCancel,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    imageUrls.length == 1
                        ? _buildSinglePage()
                        : _buildMultiplePage(),
                    if (getCaption(currentIndex).isNotEmpty)
                      Positioned(
                        bottom: 60,
                        child: Center(
                          child: TranslucentTag(
                            text: getCaption(currentIndex),
                            borderRadius: 8,
                            opacity: 0.4,
                            fontSizeDelta: 3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                          ),
                        ),
                      ),
                    if (imageUrls.length > 1 && ResponsiveUtil.isDesktop())
                      _buildDesktopPageButton(isPrevious: true),
                    if (imageUrls.length > 1 && ResponsiveUtil.isDesktop())
                      _buildDesktopPageButton(isPrevious: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopPageButton({required bool isPrevious}) {
    final disabled =
        isPrevious ? currentIndex == 0 : currentIndex == imageUrls.length - 1;
    return Positioned(
      left: isPrevious ? 16 : null,
      right: isPrevious ? null : 16,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: disabled ? 0.1 : 0.4),
          borderRadius: ChewieDimens.defaultBorderRadius,
        ),
        child: GestureDetector(
          onTap: disabled
              ? null
              : () {
                  final targetPage = currentIndex + (isPrevious ? -1 : 1);
                  _pageController.animateToPage(
                    targetPage,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
          child: MouseRegion(
            cursor:
                disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: Icon(
              isPrevious ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  bool get _canDragCurrentImage {
    final scaleState = _scaleStateControllers[currentIndex].scaleState;
    final isAtBaseScale = scaleState == PhotoViewScaleState.initial ||
        scaleState == PhotoViewScaleState.zoomedOut;
    return isAtBaseScale &&
        _viewControllers[currentIndex].position.distanceSquared <= 9;
  }

  bool _supportsDragDismiss(PointerDownEvent event) {
    return event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    if (_isDismissing || !_supportsDragDismiss(event)) return;
    if (_activePointers.length > 1) {
      _cancelDismissGesture(immediate: true);
      return;
    }
    if (!_canDragCurrentImage) return;

    _dismissAnimationController.stop();
    _dismissPointer = event.pointer;
    _dismissStartPosition = event.position;
    _dismissVelocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
    _dismissCandidate = true;
    _isDraggingToDismiss = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_dismissCandidate ||
        event.pointer != _dismissPointer ||
        _activePointers.length != 1) {
      return;
    }
    final startPosition = _dismissStartPosition;
    if (startPosition == null) return;

    _dismissVelocityTracker?.addPosition(event.timeStamp, event.position);
    final delta = event.position - startPosition;
    if (!_isDraggingToDismiss) {
      if (delta.distance < 10) return;
      if (delta.dy <= 0 || delta.dy < delta.dx.abs() * 1.25) {
        _dismissCandidate = false;
        return;
      }
      _isDraggingToDismiss = true;
    }

    final nextOffset = max(0.0, delta.dy);
    if (nextOffset == _dismissOffset || !mounted) return;
    setState(() => _dismissOffset = nextOffset);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer == _dismissPointer) {
      _dismissVelocityTracker?.addPosition(event.timeStamp, event.position);
      final velocity =
          _dismissVelocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0;
      if (_isDraggingToDismiss) {
        _finishDismissGesture(velocity);
      } else {
        _clearDismissPointer();
      }
    }
    _activePointers.remove(event.pointer);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _dismissPointer) {
      _cancelDismissGesture();
    }
    _activePointers.remove(event.pointer);
  }

  void _finishDismissGesture(double velocity) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final shouldDismiss = PhotoViewDismissMetrics.shouldDismiss(
      distance: _dismissOffset,
      velocity: velocity,
      viewportHeight: viewportHeight,
    );
    _clearDismissPointer();
    if (shouldDismiss) {
      _isDismissing = true;
      _animateDismissOffset(viewportHeight * 1.08);
    } else {
      _animateDismissOffset(0);
    }
  }

  void _cancelDismissGesture({bool immediate = false}) {
    _clearDismissPointer();
    if (_dismissOffset <= 0) return;
    if (immediate) {
      _dismissAnimationController.stop();
      if (mounted) setState(() => _dismissOffset = 0);
    } else {
      _animateDismissOffset(0);
    }
  }

  void _clearDismissPointer() {
    _dismissPointer = null;
    _dismissStartPosition = null;
    _dismissVelocityTracker = null;
    _dismissCandidate = false;
    _isDraggingToDismiss = false;
  }

  void _animateDismissOffset(double target) {
    _dismissAnimationStart = _dismissOffset;
    _dismissAnimationEnd = target;
    _dismissAnimationController
      ..duration = Duration(
        milliseconds: _isDismissing ? 220 : 300,
      )
      ..forward(from: 0);
  }

  void _handleDismissAnimationTick() {
    if (!mounted) return;
    final curve = _isDismissing ? Curves.easeInCubic : Curves.easeOutBack;
    final value = curve.transform(_dismissAnimationController.value);
    setState(() {
      _dismissOffset = _dismissAnimationStart +
          ((_dismissAnimationEnd - _dismissAnimationStart) * value);
    });
    if (_dismissAnimationController.isCompleted && _isDismissing) {
      _isDismissing = false;
      _popViewer();
    }
  }

  void _popViewer() {
    if (!mounted) return;
    Navigator.maybePop(context);
    chewieProvider.panelScreenState?.updateStatusBar();
  }

  CachedNetworkImageProvider _imageProvider(int index) {
    final url = getUrl(index);
    final retryToken = _imageRetryTokens[index];
    return CachedNetworkImageProvider(
      url,
      cacheKey: retryToken == 0 ? url : '$url#retry-$retryToken',
    );
  }

  Future<void> _retryImage(int index) async {
    await _imageProvider(index).evict();
    if (!mounted) return;
    setState(() => _imageRetryTokens[index]++);
  }

  void _prefetchAround(int index) {
    if (imageUrls.length < 2) return;
    for (final candidate in <int>[index - 1, index + 1]) {
      if (candidate < 0 || candidate >= imageUrls.length) continue;
      final url = getUrl(candidate);
      if (!_prefetchedImageUrls.add(url)) continue;
      unawaited(_warmImageFile(url));
    }
  }

  Future<void> _warmImageFile(String url) async {
    try {
      await CachedNetworkImageProvider.defaultCacheManager.getSingleFile(url);
    } catch (_) {
      _prefetchedImageUrls.remove(url);
    }
  }

  Widget _buildImageError(int index) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.imageOff,
            color: Colors.white70,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            chewieLocalizations.loadFailed,
            style: ChewieTheme.bodyMedium.apply(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _retryImage(index),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(chewieLocalizations.retry),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  String getUrl(int index) {
    return imageUrls[index];
  }

  getCaption(index) {
    if (index > captions.length - 1) return "";
    return captions[index];
  }

  updateCurrentUrl() {
    currentUrl = getUrl(currentIndex);
  }

  getPreferedScale(dynamic item) {
    dynamic preferScale = initialScale;
    return preferScale;
  }

  PointerSignalEventListener get onPointerSignal => (event) {
        if (!_isDismissing &&
            event is PointerScrollEvent &&
            currentIndex >= 0 &&
            currentIndex < imageUrls.length) {
          final delta = event.scrollDelta.dy;
          final scale = _viewControllers[currentIndex].scale ?? 1.0;
          final newScale = scale - delta / 1000;
          _viewControllers[currentIndex].scale = newScale.clamp(0.1, 10.0);
        }
      };

  Widget _buildSinglePage() {
    return Container(
      constraints: BoxConstraints.expand(
        height: MediaQuery.sizeOf(context).height,
      ),
      child: Listener(
        onPointerSignal: onPointerSignal,
        child: PhotoView(
          controller: _viewControllers[0],
          scaleStateController: _scaleStateControllers[0],
          imageProvider: _imageProvider(0),
          initialScale: getPreferedScale(currentUrl),
          minScale: minScale,
          maxScale: maxScale,
          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          heroAttributes: PhotoViewHeroAttributes(
            tag: ChewieUtils.getHeroTag(
              tagSuffix: widget.tagSuffix,
              tagPrefix: widget.tagPrefix,
              url: _heroUrls[0],
            ),
          ),
          loadingBuilder: (context, event) => _buildLoading(
            event,
            index: currentIndex,
          ),
          errorBuilder: (context, error, stackTrace) => _buildImageError(0),
        ),
      ),
    );
  }

  Widget _buildMultiplePage() {
    return Listener(
      onPointerSignal: onPointerSignal,
      child: PhotoViewGallery.builder(
        scrollPhysics: const ClampingScrollPhysics(),
        pageController: _pageController,
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        wantKeepAlive: true,
        gaplessPlayback: true,
        allowImplicitScrolling: true,
        loadingBuilder: (context, event) =>
            _buildLoading(event, index: currentIndex),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            controller: _viewControllers[index],
            scaleStateController: _scaleStateControllers[index],
            imageProvider: _imageProvider(index),
            initialScale: getPreferedScale(imageUrls[index]),
            minScale: minScale,
            maxScale: maxScale,
            heroAttributes: PhotoViewHeroAttributes(
              tag: ChewieUtils.getHeroTag(
                tagSuffix: widget.tagSuffix,
                tagPrefix: widget.tagPrefix,
                url: _heroUrls[index],
              ),
            ),
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) =>
                _buildImageError(index),
          );
        },
        itemCount: imageUrls.length,
        onPageChanged: (index) async {
          if (widget.onIndexChanged != null) {
            widget.onIndexChanged!(index);
          }
          setState(() {
            currentIndex = index;
            updateCurrentUrl();
          });
          setDownloadState(DownloadState.none, recover: false);
          _prefetchAround(index);
        },
      ),
    );
  }

  void setDownloadState(DownloadState state, {bool recover = true}) {
    _downloadRecoveryTimer?.cancel();
    switch (state) {
      case DownloadState.none:
        downloadIcon =
            const Icon(LucideIcons.download, color: Colors.white, size: 20);
        break;
      case DownloadState.loading:
        downloadIcon = Container(
          width: 20,
          height: 20,
          padding: const EdgeInsets.all(2),
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
        break;
      case DownloadState.succeed:
        downloadIcon = Icon(
          LucideIcons.check,
          color: ChewieTheme.successColor,
          size: 20,
        );
        break;
      case DownloadState.failed:
        downloadIcon = Icon(
          LucideIcons.triangleAlert,
          color: ChewieTheme.errorColor,
          size: 20,
        );
        break;
    }
    downloadState = state;
    if (mounted) setState(() {});
    if (recover) {
      _downloadRecoveryTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setDownloadState(DownloadState.none, recover: false);
      });
    }
  }

  void setAllDownloadState(DownloadState state, {bool recover = true}) {
    _allDownloadRecoveryTimer?.cancel();
    switch (state) {
      case DownloadState.none:
        allDownloadIcon = const Icon(
          LucideIcons.checkCheck,
          color: Colors.white,
          size: 20,
        );
        break;
      case DownloadState.loading:
        allDownloadIcon = Container(
          width: 20,
          height: 20,
          padding: const EdgeInsets.all(2),
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
        break;
      case DownloadState.succeed:
        allDownloadIcon = Icon(
          LucideIcons.check,
          color: ChewieTheme.successColor,
          size: 20,
        );
        break;
      case DownloadState.failed:
        allDownloadIcon = Icon(
          LucideIcons.triangleAlert,
          color: ChewieTheme.errorColor,
          size: 20,
        );
        break;
    }
    allDownloadState = state;
    if (mounted) setState(() {});
    if (recover) {
      _allDownloadRecoveryTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setAllDownloadState(DownloadState.none, recover: false);
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBarWrapper(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      titleLeftMargin: ResponsiveUtil.isLandscapeLayout() ? 15 : 5,
      leadingIcon:
          ResponsiveUtil.isLandscapeLayout() ? null : LucideIcons.arrowLeft,
      leadingColor: Colors.white,
      onLeadingTap: _popViewer,
      title: imageUrls.length > 1
          ? Text(
              "${currentIndex + 1}/${imageUrls.length}",
              style: ChewieTheme.titleLarge.apply(
                color: Colors.white,
              ),
            )
          : widget.title != null
              ? Text(
                  widget.title!,
                  style: ChewieTheme.titleLarge.apply(
                    color: Colors.white,
                  ),
                )
              : emptyWidget,
      actions: [
        ToolButton(
          context: context,
          iconBuilder: (_) =>
              const Icon(LucideIcons.link, color: Colors.white, size: 20),
          padding: const EdgeInsets.all(8.0),
          onPressed: () {
            ChewieUtils.copy(context, currentUrl);
          },
        ),
        const SizedBox(width: 5),
        ToolButton(
          context: context,
          iconBuilder: (_) =>
              const Icon(LucideIcons.share2, color: Colors.white, size: 20),
          onPressed: () {
            FileUtil.shareImage(context, currentUrl);
          },
        ),
        const SizedBox(width: 5),
        ...[
          ToolButton(
            context: context,
            iconBuilder: (_) => downloadIcon,
            padding: const EdgeInsets.all(8.0),
            onPressed: () {
              if (downloadState == DownloadState.none) {
                setDownloadState(DownloadState.loading, recover: false);
                FileUtil.saveImage(
                  context,
                  currentUrl,
                ).then((res) {
                  if (!mounted) return;
                  if (res) {
                    widget.onDownloadSuccess?.call();
                    setDownloadState(DownloadState.succeed);
                  } else {
                    setDownloadState(DownloadState.failed);
                  }
                });
              }
            },
          ),
          if (imageUrls.length > 1 || ResponsiveUtil.isLandscapeLayout())
            const SizedBox(width: 5),
        ],
        if (imageUrls.length > 1) ...[
          ToolButton(
            context: context,
            iconBuilder: (_) => allDownloadIcon,
            padding: const EdgeInsets.all(8.0),
            onPressed: () {
              if (allDownloadState == DownloadState.none) {
                setAllDownloadState(DownloadState.loading, recover: false);
                FileUtil.saveImages(
                  context,
                  imageUrls,
                ).then((res) {
                  if (!mounted) return;
                  if (res) {
                    widget.onDownloadSuccess?.call();
                    setAllDownloadState(DownloadState.succeed);
                  } else {
                    setAllDownloadState(DownloadState.failed);
                  }
                });
              }
            },
          ),
          if (ResponsiveUtil.isLandscapeLayout()) const SizedBox(width: 5),
        ],
        if (ResponsiveUtil.isLandscapeLayout())
          ToolButton(
            context: context,
            iconBuilder: (_) =>
                const Icon(LucideIcons.x, color: Colors.white, size: 20),
            onPressed: () {
              DialogNavigatorHelper.popPage();
              chewieProvider.panelScreenState?.updateStatusBar();
            },
          ),
      ],
    );
  }

  Widget _buildLoading(
    ImageChunkEvent? event, {
    int index = 0,
  }) {
    return const LoadingWidget(
      bottomPadding: 0,
      showText: false,
      size: 40,
      forceDark: true,
      background: Colors.transparent,
    );
  }
}
