import 'dart:convert';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../Design/loftify_reading.dart';
import '../Design/loftify_state_view.dart';

class PostContentSection extends StatefulWidget {
  const PostContentSection({
    super.key,
    required this.title,
    required this.content,
    this.style,
    this.onDownloadSuccess,
    this.textExtractor,
  });

  final String title;
  final String content;
  final TextStyle? style;
  final VoidCallback? onDownloadSuccess;
  final String Function(String content)? textExtractor;

  @override
  State<PostContentSection> createState() => _PostContentSectionState();
}

class _PostContentSectionState extends State<PostContentSection> {
  int _revision = 0;
  Widget? _renderedContent;
  Object? _renderError;
  StackTrace? _renderStackTrace;
  bool _contentIsEmpty = false;

  @override
  void initState() {
    super.initState();
    _prepareContent();
  }

  @override
  void didUpdateWidget(covariant PostContentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.content != widget.content ||
        oldWidget.style != widget.style ||
        oldWidget.onDownloadSuccess != widget.onDownloadSuccess ||
        oldWidget.textExtractor != widget.textExtractor) {
      _prepareContent();
    }
  }

  void _prepareContent() {
    try {
      final extractor = widget.textExtractor ?? HtmlUtil.extractTextFromHtml;
      final plainTitle = widget.title.trim();
      final plainContent = extractor(widget.content).trim();
      if (plainTitle.isEmpty && plainContent.isEmpty) {
        _contentIsEmpty = true;
        _renderedContent = const SizedBox.shrink();
      } else {
        _contentIsEmpty = false;
        final escapedTitle = const HtmlEscape().convert(plainTitle);
        final htmlTitle = escapedTitle.isEmpty
            ? ''
            : "<p id='title'><strong>$escapedTitle</strong></p>";
        _renderedContent = RepaintBoundary(
          key: ValueKey(_revision),
          child: CustomHtmlWidget(
            content: '$htmlTitle${widget.content}',
            style: widget.style,
            heightDelta: 0,
            letterSpacingDelta: 0,
            onDownloadSuccess: widget.onDownloadSuccess,
          ),
        );
      }
      _renderError = null;
      _renderStackTrace = null;
    } catch (error, stackTrace) {
      _contentIsEmpty = false;
      _renderedContent = null;
      _renderError = error;
      _renderStackTrace = stackTrace;
      ILogger.error('Failed to render post content', error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    if (_contentIsEmpty) return const SizedBox.shrink();
    if (_renderedContent != null) {
      return LoftifyReadingFrame(
        topPadding: design.spacing.xl,
        bottomPadding: design.spacing.md,
        child: _renderedContent!,
      );
    }
    assert(_renderError != null && _renderStackTrace != null);
    return LoftifyReadingFrame(
      topPadding: design.spacing.xl,
      bottomPadding: design.spacing.md,
      child: LoftifyStateView(
        visual: LoftifyStateVisual.error,
        title: chewieLocalizations.loadFailed,
        actionLabel: chewieLocalizations.retry,
        padding: EdgeInsets.all(design.spacing.xl),
        onAction: () {
          setState(() {
            _revision++;
            _prepareContent();
          });
        },
      ),
    );
  }
}
