import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Utils/file_util.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/utils.dart';
import '../General/PhotoView/photo_view.dart';
import '../General/PhotoView/photo_view_gallery.dart';
import '../Item/item_builder.dart';

enum DownloadState { none, loading, succeed, failed }

class HeroPhotoViewScreen extends StatefulWidget {
  const HeroPhotoViewScreen({
    super.key,
    required this.imageUrls,
    this.initialScale = PhotoViewComputedScale.contained,
    this.minScale = PhotoViewComputedScale.contained,
    this.maxScale,
    this.initIndex,
    this.useMainColor = true,
    this.captions,
    this.onIndexChanged,
    this.transparentBar = true,
    this.title,
    this.tagPrefix,
    this.tagSuffix,
    this.mainColors,
  });

  final String? title;
  final String? tagPrefix;
  final String? tagSuffix;
  final List<dynamic> imageUrls;
  final List<String>? captions;
  final dynamic initialScale;
  final dynamic minScale;
  final dynamic maxScale;
  final int? initIndex;
  final bool useMainColor;
  final List<Color>? mainColors;
  final bool transparentBar;
  final Function(int)? onIndexChanged;

  @override
  State<HeroPhotoViewScreen> createState() => HeroPhotoViewScreenState();
}

class HeroPhotoViewScreenState extends State<HeroPhotoViewScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final List<dynamic> imageUrls;
  late final List<String> captions;
  late final dynamic initialScale;
  late final dynamic minScale;
  late final dynamic maxScale;
  String currentUrl = "";
  int currentIndex = 0;
  List<Color> mainColors = [];
  late dynamic downloadIcon;
  late dynamic allDownloadIcon;
  DownloadState downloadState = DownloadState.none;
  DownloadState allDownloadState = DownloadState.none;
  late PageController _pageController;
  final List<PhotoViewController> _viewControllers = [];

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
    setDownloadState(DownloadState.none);
    setAllDownloadState(DownloadState.none);
    imageUrls = widget.imageUrls;
    _viewControllers.addAll(List.generate(imageUrls.length, (index) {
      return PhotoViewController();
    }));
    captions = widget.captions ?? [];
    minScale = widget.minScale;
    maxScale = widget.maxScale;
    initialScale = widget.initialScale;
    currentIndex = widget.initIndex ?? 0;
    currentIndex = max(0, min(currentIndex, imageUrls.length - 1));
    _pageController = PageController(initialPage: currentIndex);
    if (widget.mainColors != null &&
        widget.mainColors!.length >= imageUrls.length &&
        HiveUtil.getBool(key: HiveUtil.followMainColorKey)) {
      mainColors = widget.mainColors!;
    } else {
      mainColors = List.filled(imageUrls.length, Colors.black);
      if (widget.useMainColor &&
          HiveUtil.getBool(key: HiveUtil.followMainColorKey)) {
        Utils.getMainColors(
          context,
          imageUrls.map((e) => getUrl(imageUrls.indexOf(e))).toList(),
        ).then((value) {
          if (mounted) setState(() {});
          mainColors = value;
        });
      }
    }
    updateCurrentUrl();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _buildAppBar(),
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          imageUrls.length == 1 ? _buildSinglePage() : _buildMultiplePage(),
          if (getCaption(currentIndex).isNotEmpty)
            Positioned(
              bottom: 60,
              child: Center(
                child: ItemBuilder.buildTransparentTag(
                  context,
                  text: getCaption(currentIndex),
                  borderRadius: 8,
                  opacity: 0.4,
                  fontSizeDelta: 3,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ),
            ),
          if (imageUrls.length > 1 && ResponsiveUtil.isDesktop())
            Positioned(
              left: 16,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: currentIndex == 0
                      ? Colors.black.withOpacity(0.1)
                      : Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GestureDetector(
                  onTap: () {
                    _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  child: MouseRegion(
                    cursor: currentIndex == 0
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: const Icon(
                      Icons.keyboard_arrow_left_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (imageUrls.length > 1 && ResponsiveUtil.isDesktop())
            Positioned(
              right: 16,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: currentIndex == imageUrls.length - 1
                      ? Colors.black.withOpacity(0.1)
                      : Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GestureDetector(
                  onTap: () {
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  child: MouseRegion(
                    cursor: currentIndex == imageUrls.length - 1
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: const Icon(
                      Icons.keyboard_arrow_right_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String getUrl(int index) {
    return imageUrls[index] is PhotoLink
        ? imageUrls[index].orign
        : imageUrls[index];
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
    if (item is PhotoLink) {
      double preferHeight =
          MediaQuery.sizeOf(context).width * item.oh / item.ow;
      double scale = preferHeight / MediaQuery.sizeOf(context).height;
      // if (scale > 1 && ResponsiveUtil.isMobile()) {
      //   preferScale = PhotoViewComputedScale.covered;
      // }
    }
    return preferScale;
  }

  PointerSignalEventListener get onPointerSignal => (event) {
        if (event is PointerScrollEvent &&
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
          imageProvider: CachedNetworkImageProvider(Utils.getUrlByQuality(
              currentUrl,
              HiveUtil.getImageQuality(HiveUtil.imageDetailImageQualityKey))),
          initialScale: getPreferedScale(currentUrl),
          minScale: minScale,
          maxScale: maxScale,
          backgroundDecoration: BoxDecoration(
              color: Utils.getDarkColor(mainColors[currentIndex])),
          heroAttributes: PhotoViewHeroAttributes(
            tag: Utils.getHeroTag(
              tagSuffix: widget.tagSuffix,
              tagPrefix: widget.tagPrefix,
              url: currentUrl,
            ),
          ),
          loadingBuilder: (context, event) => _buildLoading(
            event,
            index: currentIndex,
          ),
          // onTapDown: (_, __, ___) {
          //   Navigator.pop(context);
          // },
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
        backgroundDecoration:
            BoxDecoration(color: Utils.getDarkColor(mainColors[currentIndex])),
        loadingBuilder: (context, event) => _buildLoading(
          event,
          index: currentIndex,
        ),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            controller: _viewControllers[index],
            imageProvider: CachedNetworkImageProvider(Utils.getUrlByQuality(
                getUrl(index),
                HiveUtil.getImageQuality(HiveUtil.imageDetailImageQualityKey))),
            initialScale: getPreferedScale(imageUrls[index]),
            minScale: minScale,
            maxScale: maxScale,
            heroAttributes: PhotoViewHeroAttributes(
              tag: Utils.getHeroTag(
                tagSuffix: widget.tagSuffix,
                tagPrefix: widget.tagPrefix,
                url: Utils.removeImageParam(getUrl(index)),
              ),
            ),
            filterQuality: FilterQuality.high,
            // onTapDown: (_, __, ___) {
            //   Navigator.pop(context);
            // },
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
          setDownloadState(DownloadState.none);
        },
      ),
    );
  }

  void setDownloadState(DownloadState state, {bool recover = true}) {
    switch (state) {
      case DownloadState.none:
        downloadIcon = AssetUtil.load(AssetUtil.downloadWhiteIcon);
        break;
      case DownloadState.loading:
        downloadIcon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
        break;
      case DownloadState.succeed:
        downloadIcon = const Icon(Icons.check_rounded, color: Colors.green);
        break;
      case DownloadState.failed:
        downloadIcon =
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent);
        break;
    }
    downloadState = state;
    if (mounted) setState(() {});
    if (recover) {
      Future.delayed(const Duration(seconds: 2), () {
        setDownloadState(DownloadState.none, recover: false);
      });
    }
  }

  void setAllDownloadState(DownloadState state, {bool recover = true}) {
    switch (state) {
      case DownloadState.none:
        allDownloadIcon =
            const Icon(Icons.done_all_rounded, color: Colors.white, size: 22);
        break;
      case DownloadState.loading:
        allDownloadIcon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
        break;
      case DownloadState.succeed:
        allDownloadIcon = const Icon(Icons.check_rounded, color: Colors.green);
        break;
      case DownloadState.failed:
        allDownloadIcon =
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent);
        break;
    }
    allDownloadState = state;
    if (mounted) setState(() {});
    if (recover) {
      Future.delayed(const Duration(seconds: 2), () {
        setAllDownloadState(DownloadState.none, recover: false);
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      backgroundColor: widget.transparentBar
          ? Colors.transparent
          : Utils.getDarkColor(mainColors[currentIndex]).withOpacity(0.5),
      leading: Icons.arrow_back_rounded,
      leadingColor: Colors.white,
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: imageUrls.length > 1
          ? Text(
              "${currentIndex + 1}/${imageUrls.length}",
              style: Theme.of(context).textTheme.titleLarge?.apply(
                    color: Colors.white,
                  ),
            )
          : widget.title != null
              ? Text(
                  widget.title!,
                  style: Theme.of(context).textTheme.titleLarge?.apply(
                        color: Colors.white,
                      ),
                )
              : Container(),
      actions: [
        ItemBuilder.buildIconButton(
          context: context,
          icon: AssetUtil.load(AssetUtil.linkWhiteIcon),
          onTap: () {
            Utils.copy(
              context,
              Utils.getUrlByQuality(
                  currentUrl,
                  HiveUtil.getImageQuality(
                      HiveUtil.tapLinkButtonImageQualityKey)),
              toastText: "已复制图片链接",
            );
          },
          onLongPress: () {
            Utils.copy(
              context,
              Utils.getUrlByQuality(
                  currentUrl,
                  HiveUtil.getImageQuality(
                      HiveUtil.longPressLinkButtonImageQualityKey)),
              toastText: "已复制图片链接",
            );
          },
        ),
        const SizedBox(width: 5),
        ItemBuilder.buildIconButton(
          context: context,
          icon: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
          onTap: () {
            FileUtil.shareImage(
              context,
              Utils.getUrlByQuality(
                currentUrl,
                ImageQuality.raw,
              ),
            );
          },
        ),
        const SizedBox(width: 5),
        ItemBuilder.buildIconButton(
          context: context,
          icon: downloadIcon,
          onTap: () {
            if (downloadState == DownloadState.none) {
              setDownloadState(DownloadState.loading);
              FileUtil.saveImage(
                context,
                Utils.getUrlByQuality(
                  currentUrl,
                  ImageQuality.raw,
                ),
              ).then((res) {
                if (res) {
                  setDownloadState(DownloadState.succeed);
                } else {
                  setDownloadState(DownloadState.failed);
                }
              });
            }
          },
        ),
        const SizedBox(width: 5),
        if (imageUrls.length > 1)
          ItemBuilder.buildIconButton(
            context: context,
            icon: allDownloadIcon,
            onTap: () {
              if (allDownloadState == DownloadState.none) {
                setAllDownloadState(DownloadState.loading);
                FileUtil.saveImages(
                  context,
                  imageUrls
                      .map(
                        (e) => Utils.getUrlByQuality(
                          getUrl(imageUrls.indexOf(e)),
                          ImageQuality.raw,
                        ),
                      )
                      .toList(),
                ).then((res) {
                  if (res) {
                    setAllDownloadState(DownloadState.succeed);
                  } else {
                    setAllDownloadState(DownloadState.failed);
                  }
                });
              }
            },
          ),
        if (imageUrls.length > 1) const SizedBox(width: 5),
        if (ResponsiveUtil.isLandscape())
          ItemBuilder.buildIconButton(
            context: context,
            icon:
                const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        if (ResponsiveUtil.isLandscape()) const SizedBox(width: 5),
      ],
    );
  }

  Widget _buildLoading(
    ImageChunkEvent? event, {
    int index = 0,
  }) {
    return ItemBuilder.buildLoadingDialog(
      context,
      bottomPadding: 0,
      showText: false,
      size: 40,
      forceDark: true,
      background: Colors.transparent,
    );
  }
}
