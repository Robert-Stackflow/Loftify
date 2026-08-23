import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AutoImage extends StatefulWidget {
  final String imageUrl;
  final String? baseUrl;
  final BoxFit? fit;
  final bool showLoading;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final double? placeholderHeight;
  final Color? placeholderBackground;
  final double topPadding;
  final double bottomPadding;
  final bool simpleError;

  const AutoImage({
    super.key,
    required this.imageUrl,
    this.baseUrl,
    this.fit,
    this.showLoading = true,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholderHeight,
    this.placeholderBackground,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.simpleError = false,
  });

  @override
  State<AutoImage> createState() => _AutoImageState();
}

class _AutoImageState extends State<AutoImage> {
  late Future<Widget> _imageFuture;

  static const _maxSvgCheckCacheEntries = 200;
  static final LinkedHashMap<String, bool> _svgCheckCache = LinkedHashMap();

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(covariant AutoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.baseUrl != widget.baseUrl ||
        oldWidget.fit != widget.fit ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.memCacheWidth != widget.memCacheWidth ||
        oldWidget.memCacheHeight != widget.memCacheHeight ||
        oldWidget.showLoading != widget.showLoading ||
        oldWidget.placeholderHeight != widget.placeholderHeight ||
        oldWidget.placeholderBackground != widget.placeholderBackground ||
        oldWidget.topPadding != widget.topPadding ||
        oldWidget.bottomPadding != widget.bottomPadding ||
        oldWidget.simpleError != widget.simpleError) {
      _imageFuture = _loadImage();
    }
  }

  bool hasCommonImageExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      const commonImageExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
      return commonImageExtensions.any((ext) => path.endsWith(ext));
    } catch (_) {
      return false;
    }
  }

  Future<Widget> _loadImage() async {
    final fullUrl = widget.imageUrl;

    if (fullUrl.startsWith('data:image')) {
      final uriRegex = RegExp(r'data:image/[^;]+;base64,');
      final match = uriRegex.firstMatch(fullUrl);
      if (match != null) {
        try {
          final base64Str = fullUrl.substring(match.end);
          final bytes = base64Decode(base64Str);
          return Padding(
            padding: EdgeInsets.only(
              top: widget.topPadding,
              bottom: widget.bottomPadding,
            ),
            child: Image.memory(
              bytes,
              fit: widget.fit,
              width: widget.width,
              height: widget.height,
            ),
          );
        } catch (_) {
          return const Icon(LucideIcons.imageOff);
        }
      }
    }

    if (hasCommonImageExtension(fullUrl)) {
      return _buildCachedImage();
    }

    bool isSvg = false;
    if (_svgCheckCache.containsKey(fullUrl)) {
      isSvg = _svgCheckCache.remove(fullUrl)!;
      _svgCheckCache[fullUrl] = isSvg;
    } else {
      try {
        final response = await http
            .head(Uri.parse(fullUrl))
            .timeout(const Duration(seconds: 5));
        final contentType = response.headers['content-type'];
        isSvg = contentType != null && contentType.contains('image/svg+xml');
        _rememberSvgType(fullUrl, isSvg);
      } catch (e) {
        isSvg = false;
      }
    }

    if (isSvg) {
      return Padding(
        padding: EdgeInsets.only(
          top: widget.topPadding,
          bottom: widget.bottomPadding,
        ),
        child: SvgPicture.network(
          fullUrl,
          colorFilter: widget.fit == BoxFit.cover
              ? ColorFilter.mode(
                  ChewieTheme.bodyMedium.color!,
                  BlendMode.srcIn,
                )
              : null,
          height: 56,
          fit: BoxFit.contain,
          placeholderBuilder: widget.showLoading
              ? (context) => buildLoadingWidget()
              : SvgPicture.defaultPlaceholderBuilder,
        ),
      );
    }

    return _buildCachedImage();
  }

  void _rememberSvgType(String url, bool isSvg) {
    _svgCheckCache.remove(url);
    _svgCheckCache[url] = isSvg;
    while (_svgCheckCache.length > _maxSvgCheckCacheEntries) {
      _svgCheckCache.remove(_svgCheckCache.keys.first);
    }
  }

  Widget _buildCachedImage() {
    return MyCachedNetworkImage(
      imageUrl: widget.imageUrl,
      baseUrl: widget.baseUrl,
      fit: widget.fit,
      width: widget.width,
      simpleError: widget.simpleError,
      height: widget.height,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      placeholderHeight: widget.placeholderHeight,
      placeholderBackground: widget.placeholderBackground,
      topPadding: widget.topPadding,
      bottomPadding: widget.bottomPadding,
      showLoading: widget.showLoading,
    );
  }

  buildLoadingWidget() {
    return LoadingWidget(
      topPadding: widget.placeholderHeight != null
          ? (widget.placeholderHeight! - 20) / 2
          : widget.topPadding,
      bottomPadding: widget.placeholderHeight != null
          ? (widget.placeholderHeight! - 20) / 2
          : widget.bottomPadding,
      showText: false,
      size: 40,
      background: widget.placeholderBackground,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const Icon(LucideIcons.cloudAlert);
        }
        return snapshot.data ?? const SizedBox.shrink();
      },
    );
  }
}
