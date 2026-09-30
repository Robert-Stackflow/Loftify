import 'dart:math' as math;

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import '../../Models/post_detail_response.dart';
import '../../Theme/loftify_design_theme.dart';

/// Comment media is compact; emoji must remain inline with the surrounding text.
class CommentContent extends StatelessWidget {
  const CommentContent({super.key, required this.comment});

  final Comment comment;

  static String? _imageUrl(String value) {
    var url = value.trim();
    if (url.startsWith('//')) url = 'https:$url';
    final uri = Uri.tryParse(url);
    return uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty
        ? url
        : null;
  }

  String _prepareContent() {
    final fragment = html.parseFragment(comment.content);
    final emotes = {
      for (final emote in comment.emotes)
        if (emote.name.isNotEmpty && emote.url.trim().isNotEmpty)
          emote.name: emote.url,
    };
    // These placeholders refer to ordered attachments, not named emotes.
    final attachments = comment.images;
    var attachmentIndex = 0;
    dom.Element attachmentElement(CommentImage image, String marker) =>
        dom.Element.tag('img')
          ..attributes['src'] = image.url
          ..attributes['alt'] = marker
          ..attributes['width'] = '${image.ow}'
          ..attributes['height'] = '${image.oh}'
          ..attributes['data-comment-sticker'] = '${marker == '[表情]'}';

    final names = {
      ...emotes.keys,
      if (attachments.isNotEmpty) ...['[表情]', '[图片]'],
    }.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (names.isEmpty) return fragment.outerHtml;
    final pattern = RegExp(names.map(RegExp.escape).join('|'));

    void replaceEmotes(dom.Node node) {
      // Replace only text, never attributes, URLs or already-rendered images.
      for (final child in node.nodes.toList()) {
        if (child is dom.Text) {
          final replacements = <dom.Node>[];
          var offset = 0;
          for (final match in pattern.allMatches(child.data)) {
            replacements
                .add(dom.Text(child.data.substring(offset, match.start)));
            final marker = match[0]!;
            if ((marker == '[表情]' || marker == '[图片]') &&
                attachmentIndex < attachments.length) {
              final attachment = attachments[attachmentIndex++];
              replacements.add(
                _imageUrl(attachment.url) == null
                    ? dom.Text(marker)
                    : attachmentElement(attachment, marker),
              );
            } else if (emotes.containsKey(marker)) {
              replacements.add(dom.Element.tag('img')
                ..attributes['src'] = emotes[marker]!
                ..attributes['alt'] = marker
                ..attributes['data-comment-emote'] = 'true');
            } else {
              replacements.add(dom.Text(marker));
            }
            offset = match.end;
          }
          if (replacements.isNotEmpty) {
            replacements.add(dom.Text(child.data.substring(offset)));
            final index = node.nodes.indexOf(child);
            child.remove();
            node.nodes.insertAll(index, replacements);
          }
        } else {
          replaceEmotes(child);
        }
      }
    }

    replaceEmotes(fragment);
    // Some responses supply attachments without placeholders in content.
    for (final image in attachments.skip(attachmentIndex)) {
      if (_imageUrl(image.url) == null) continue;
      fragment.nodes.add(attachmentElement(
        image,
        image.type == 1 ? '[表情]' : '[图片]',
      ));
    }
    return fragment.outerHtml;
  }

  @override
  Widget build(BuildContext context) {
    return CustomHtmlWidget(
      content: _prepareContent(),
      showLoading: false,
      inlineLinks: true,
      heightDelta: 0,
      letterSpacingDelta: 0,
      style: Theme.of(context).textTheme.bodyMedium,
      imageBuilder: (context, element) {
        var url = element.attributes['src']?.trim() ?? '';
        if (url.isEmpty) url = element.attributes['data-src']?.trim() ?? '';
        final resolvedUrl = _imageUrl(url);
        final isEmote = element.attributes['data-comment-emote'] == 'true';
        final fallback = Text(element.attributes['alt'] ?? '[图片]');
        if (resolvedUrl == null) return InlineCustomWidget(child: fallback);
        url = resolvedUrl;
        final isSticker = element.attributes['data-comment-sticker'] == 'true';
        final limit = isSticker ? 120.0 : 200.0;
        final width = double.tryParse(element.attributes['width'] ?? '') ?? 0;
        final height = double.tryParse(element.attributes['height'] ?? '') ?? 0;
        final hasSize =
            width > 0 && height > 0 && width.isFinite && height.isFinite;
        final scale =
            hasSize ? math.min(1.0, limit / math.max(width, height)) : 1.0;
        final placeholderColor = Theme.of(context)
                .extension<LoftifyDesignThemeData>()
                ?.colors
                .surfaceMuted ??
            Theme.of(context).colorScheme.surfaceContainerHighest;

        Widget placeholder({bool failed = false}) => DecoratedBox(
              key: ValueKey(
                  failed ? 'comment-image-error' : 'comment-image-placeholder'),
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox.expand(
                child: failed ? Center(child: fallback) : null,
              ),
            );

        final image = CachedNetworkImage(
          imageUrl: url,
          width: isEmote ? 38 : (hasSize ? width * scale : limit),
          height: isEmote ? 38 : (hasSize ? height * scale : limit),
          fit: BoxFit.contain,
          placeholder: (_, __) => placeholder(),
          errorWidget: (_, __, ___) => placeholder(failed: true),
        );
        if (isEmote) {
          return InlineCustomWidget(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: SelectionContainer.disabled(child: image),
            ),
          );
        }
        return SelectionContainer.disabled(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ClickableGestureDetector(
                onTap: () => RouteUtil.pushDialogRoute(
                  context,
                  HeroPhotoViewScreen(imageUrls: [url], initIndex: 0),
                  showClose: false,
                  fullScreen: true,
                  useFade: true,
                  opaque: false,
                  barrierDismissible: false,
                  animation: false,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
