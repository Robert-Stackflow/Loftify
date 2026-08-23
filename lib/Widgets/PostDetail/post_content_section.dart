import 'dart:convert';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

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
        _renderedContent = const SizedBox.shrink();
      } else {
        final escapedTitle = const HtmlEscape().convert(plainTitle);
        final htmlTitle = escapedTitle.isEmpty
            ? ''
            : "<p id='title'><strong>$escapedTitle</strong></p>";
        _renderedContent = Padding(
          key: ValueKey(_revision),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: RepaintBoundary(
            child: CustomHtmlWidget(
              content: '$htmlTitle${widget.content}',
              style: widget.style,
              onDownloadSuccess: widget.onDownloadSuccess,
            ),
          ),
        );
      }
      _renderError = null;
      _renderStackTrace = null;
    } catch (error, stackTrace) {
      _renderedContent = null;
      _renderError = error;
      _renderStackTrace = stackTrace;
      ILogger.error('Failed to render post content', error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_renderedContent != null) return _renderedContent!;
    assert(_renderError != null && _renderStackTrace != null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: ContainerItem(
        radius: 14,
        roundTop: true,
        roundBottom: true,
        backgroundColor: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.article_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                chewieLocalizations.loadFailed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              RoundIconTextButton(
                text: chewieLocalizations.retry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: () {
                  setState(() {
                    _revision++;
                    _prepareContent();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
