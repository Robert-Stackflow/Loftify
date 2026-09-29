/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class MyCachedNetworkImage extends StatefulWidget {
  const MyCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.baseUrl,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholderHeight,
    this.fit,
    this.showLoading = false,
    this.placeholderBackground,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.simpleError = false,
  });

  final String imageUrl;
  final String? baseUrl;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final double? placeholderHeight;
  final BoxFit? fit;
  final bool showLoading;
  final bool simpleError;
  final Color? placeholderBackground;
  final double topPadding;
  final double bottomPadding;

  @override
  State<MyCachedNetworkImage> createState() => _MyCachedNetworkImageState();
}

class _MyCachedNetworkImageState extends State<MyCachedNetworkImage> {
  final _rebuildValueNotifier = ValueNotifier('');
  final int _maxRetries = 3;
  int _currentRetries = 0;
  Timer? _retryTimer;

  String get _imageUrl => HtmlUtil.unscape(widget.imageUrl);

  void _scheduleRetry() {
    if (!mounted ||
        _currentRetries >= _maxRetries ||
        (_retryTimer?.isActive ?? false)) {
      return;
    }
    _currentRetries++;
    ILogger.debug(
        'Retrying to load image: $_imageUrl, attempt: $_currentRetries');
    _retryTimer = Timer(
      Duration(milliseconds: 300 * _currentRetries),
      () {
        if (!mounted) return;
        _rebuildValueNotifier.value = MockUtil.getRandomString();
      },
    );
  }

  void _retryManually() {
    if (!mounted) return;
    _retryTimer?.cancel();
    _currentRetries = 0;
    _rebuildValueNotifier.value = MockUtil.getRandomString();
  }

  @override
  void didUpdateWidget(covariant MyCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.baseUrl != widget.baseUrl) {
      _retryTimer?.cancel();
      _currentRetries = 0;
      _rebuildValueNotifier.value = '';
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _rebuildValueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        // Supplying both dimensions to ResizeImage can decode the bitmap into
        // the box aspect ratio before BoxFit is applied. Prefer width (the
        // bounded axis for feeds and grids), or height when width is unknown,
        // so the source aspect ratio is always preserved.
        final cacheWidth = _validCacheDimension(widget.memCacheWidth) ??
            _cacheDimension(
              widget.width,
              constraints.hasBoundedWidth ? constraints.maxWidth : null,
              pixelRatio,
            );
        final cacheHeight = cacheWidth == null
            ? _validCacheDimension(widget.memCacheHeight) ??
                _cacheDimension(
                  widget.height,
                  constraints.hasBoundedHeight ? constraints.maxHeight : null,
                  pixelRatio,
                )
            : null;
        return ValueListenableBuilder<String>(
          valueListenable: _rebuildValueNotifier,
          builder: (context, value, child) {
            return CachedNetworkImage(
              key: value.isEmpty ? null : ValueKey(value),
              imageUrl: _imageUrl,
              fit: widget.fit,
              width: widget.width,
              height: widget.height,
              memCacheWidth: cacheWidth,
              memCacheHeight: cacheHeight,
              filterQuality: FilterQuality.medium,
              httpHeaders: {
                'Referer': widget.baseUrl ?? '',
                "User-Agent":
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0',
              },
              placeholder: widget.showLoading
                  ? (context, url) => LoadingWidget(
                        topPadding: widget.placeholderHeight != null
                            ? (widget.placeholderHeight! - 20) / 2
                            : widget.topPadding,
                        bottomPadding: widget.placeholderHeight != null
                            ? (widget.placeholderHeight! - 20) / 2
                            : widget.bottomPadding,
                        showText: false,
                        size: 40,
                        background: widget.placeholderBackground,
                      )
                  : (context, url) => Container(
                        color: widget.placeholderBackground ??
                            Theme.of(context).cardColor,
                        width: widget.width,
                        height: widget.placeholderHeight ?? widget.height,
                      ),
              errorWidget: widget.simpleError
                  ? _simpleErrorWidget
                  : _currentRetries < _maxRetries
                      ? _defaultErrorWidget
                      : _maxRetryReachedWidget,
              errorListener: (error) {
                _scheduleRetry();
              },
            );
          },
        );
      },
    );
  }

  int? _cacheDimension(
    double? requestedLogicalSize,
    double? constrainedLogicalSize,
    double pixelRatio,
  ) {
    final logicalSize = requestedLogicalSize?.isFinite == true
        ? requestedLogicalSize
        : constrainedLogicalSize?.isFinite == true
            ? constrainedLogicalSize
            : null;
    if (logicalSize == null || logicalSize <= 0 || pixelRatio <= 0) {
      return null;
    }
    return (logicalSize * pixelRatio).ceil().clamp(1, 4096);
  }

  int? _validCacheDimension(int? dimension) {
    if (dimension == null || dimension <= 0) return null;
    return dimension.clamp(1, 4096);
  }

  Widget _simpleErrorWidget(BuildContext context, String url, dynamic error) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 40,
        minWidth: 40,
        maxWidth: 40,
        maxHeight: 40,
      ),
      child: CircleIconButton(
        icon: const ChewieIcon(ChewieIcons.retry),
        onTap: _retryManually,
      ),
    );
  }

  Widget _defaultErrorWidget(BuildContext context, String url, dynamic error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChewieIcon(ChewieIcons.error),
          const SizedBox(height: 8),
          RoundIconTextButton(
            onPressed: _retryManually,
            text: '重新加载',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
        ],
      ),
    );
  }

  Widget _maxRetryReachedWidget(
      BuildContext context, String url, dynamic error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ChewieIcon(ChewieIcons.error),
          SizedBox(height: 8),
          Text(
            '无法加载图片，请稍后重试',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
