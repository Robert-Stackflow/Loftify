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

import 'package:awesome_chewie/src/Widgets/Tile/expandable_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:html/dom.dart' as dom;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

enum RenderType {
  normal,
  inA,
  inStrong,
  inLi,
  inFigure,
  inBlockquote,
  inDetails,
  inH,
  inTableHeader,
  inTableBody,
}

class CustomHtmlWidget extends StatefulWidget {
  const CustomHtmlWidget({
    super.key,
    this.url,
    required this.content,
    this.style,
    this.parseImage = true,
    this.showLoading = true,
    this.onDownloadSuccess,
    this.heightDelta,
    this.letterSpacingDelta,
    this.placeholderBackgroundColor,
    this.anchors = const [],
    this.onAnchorTap,
    this.onHashtagTap,
    this.contextMenuItemsBuilder,
    this.maxHeaderLevel = 5,
    this.detectLanguage,
    this.selectable = true,
  });

  final int maxHeaderLevel;
  final String content;
  final TextStyle? style;
  final bool parseImage;
  final bool showLoading;
  final Function()? onDownloadSuccess;
  final double? heightDelta;
  final double? letterSpacingDelta;
  final Color? placeholderBackgroundColor;
  final List<Anchor> anchors;
  final Function(Anchor anchor)? onAnchorTap;
  final Function(String hashtag)? onHashtagTap;
  final LanguageDetector? detectLanguage;
  final bool selectable;
  final String? url;
  final List<FlutterContextMenuItem> Function(SelectableRegionState, String?)?
      contextMenuItemsBuilder;

  @override
  CustomHtmlWidgetState createState() => CustomHtmlWidgetState();
}

class CustomHtmlWidgetState extends State<CustomHtmlWidget> {
  // Timer? _hoverTimer;
  // String? _hoverUrl;

  // _startHoverTimer() {
  //   _hoverTimer = Timer(const Duration(milliseconds: 1000), () {
  //     if (_hoverUrl != null) {
  //       UrlPreviewHelper.showUrlPreviewOverlay(context, _hoverUrl!);
  //     }
  //   });
  // }
  //
  // void _cancelHoverTimer() {
  //   _hoverTimer?.cancel();
  // }

  double verticalMargin = 10;
  FocusNode? _selectionFocusNode;

  FocusNode get selectionFocusNode =>
      _selectionFocusNode ??= FocusNode(debugLabel: 'CustomHtmlWidget');

  @override
  void dispose() {
    _selectionFocusNode?.dispose();
    super.dispose();
  }

  LanguageDetector? get detectLanguage =>
      widget.detectLanguage ?? HtmlUtil.detectLanguage;

  @override
  Widget build(BuildContext context) {
    return _buildHtmlWidget(widget.content);
  }

  _buildLinkContextMenuButtons(String url) {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          "在浏览器打开",
          iconData: LucideIcons.globe,
          onPressed: () {
            UriUtil.processUrl(context, url);
          },
        ),
        FlutterContextMenuItem(
          chewieLocalizations.copyLink,
          iconData: LucideIcons.link,
          onPressed: () {
            ChewieUtils.copy(context, url);
          },
        ),
      ],
    );
  }

  _buildImageContextMenuButtons(String imageUrl) {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          "保存图片",
          iconData: LucideIcons.save,
          onPressed: () {
            FileUtil.saveImage(context, imageUrl, showToast: true);
          },
        ),
        FlutterContextMenuItem(
          "复制图片链接",
          iconData: LucideIcons.link,
          onPressed: () {
            ChewieUtils.copy(context, imageUrl);
          },
        ),
        FlutterContextMenuItem(
          "在浏览器打开",
          iconData: LucideIcons.globe,
          onPressed: () {
            UriUtil.openExternal(imageUrl);
          },
        ),
        FlutterContextMenuItem(
          "Google搜图",
          iconData: LucideIcons.searchSlash,
          onPressed: () {
            UriUtil.openExternal(
                "https://lens.google.com/uploadbyurl?url=$imageUrl");
          },
        ),
        FlutterContextMenuItem(
          "Bing识图",
          iconData: LucideIcons.searchSlash,
          onPressed: () {
            UriUtil.openExternal(
                "https://www.bing.com/images/searchbyimage?FORM=IRSBIQ&cbir=sbi&imgurl=$imageUrl");
          },
        )
      ],
    );
  }

  _buildHtmlWidget(String content) {
    final renderedContent = _render(content);
    if (!widget.selectable) return renderedContent;
    return SelectableAreaWrapper(
      focusNode: selectionFocusNode,
      // selectionNotifier: widget.selectionNotifier,
      contextMenuItemsBuilder: widget.contextMenuItemsBuilder,
      child: renderedContent,
    );
  }

  getImages() {
    return HtmlUtil.extractImagesFromHtml(widget.content)
        .map(
          (imageUrl) => WebUtil.resolveRelativeUrl(widget.url ?? "", imageUrl),
        )
        .toList();
  }

  getHeaderLocalNames() {
    return [
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
    ].sublist(0, widget.maxHeaderLevel);
  }

  _render(
    String content, {
    RenderType renderType = RenderType.normal,
    TextStyle? customStyle,
    double? heightDelta,
  }) {
    var style = customStyle ?? widget.style;
    if (style != null && style.letterSpacing != null) {
      style = style.apply(
        heightDelta: heightDelta ?? widget.heightDelta ?? -0.1,
        letterSpacingDelta: widget.letterSpacingDelta ?? -0.5,
      );
    }
    style ??= ChewieTheme.bodyMedium.apply(fontSizeDelta: 1, heightDelta: 0.1);

    int lastAnchorIndex = 0;
    return HtmlWidget(
      content,
      enableCaching: true,
      renderMode: RenderMode.column,
      textStyle: style,
      factoryBuilder: () => CustomImageFactory(),
      customWidgetBuilder: (element) {
        bool isElementEmpty = element.children.isEmpty && element.text.isEmpty;
        if (element.localName == 'a') {
          return _renderA(
            element,
            renderType: renderType,
            style: style,
          );
        } else if (element.localName == 'strong' || element.localName == 'b') {
          return _renderStrong(
            element,
            renderType: renderType,
            style: style,
          );
        } else if (element.localName == 'em' || element.localName == 'i') {
          return _renderItalic(
            element,
            renderType: renderType,
            style: style,
          );
        } else if (element.localName == 'img' && widget.parseImage) {
          return SelectionContainer.disabled(
            child: _renderImg(
              element,
              getImages(),
              onDownloadSuccess: widget.onDownloadSuccess,
            ),
          );
        } else if (element.localName == 'pre') {
          return _renderPre(
            element,
            style: style,
            renderType: renderType,
          );
        } else if (element.localName == 'code') {
          return _renderCode(
            element,
            style: style,
            renderType: renderType,
          );
        } else if (element.localName == 'br') {
          return Container(
            margin: EdgeInsets.symmetric(vertical: verticalMargin),
            child: const SizedBox.shrink(),
          );
        } else if (element.localName == 'table') {
          return _renderTable(
            element,
            style: style,
            renderType: renderType,
          );
        } else if (element.localName == 'tex' ||
            element.localName == 'inlinetex') {
          return _renderTex(
            element,
            style: style,
            renderType: renderType,
          );
        } else if (element.localName == 'li') {
          return element.parent?.localName == 'ul'
              ? _renderUlLi(
                  element,
                  style: style,
                  renderType: renderType,
                )
              : element.parent?.localName == 'ol'
                  ? _renderOlLi(
                      element,
                      style: style,
                      renderType: renderType,
                      index: element.parent!.children.indexOf(element),
                    )
                  : null;
        } else if (getHeaderLocalNames().contains(element.localName)) {
          List<String> titles = HtmlUtil.extractTitles(content);
          var res = _renderH(
            element,
            titles,
            lastIndex: lastAnchorIndex,
          );
          lastAnchorIndex = res[0];
          return res[1];
        } else if (element.localName == 'blockquote' ||
            element.localName == 'q' ||
            element.localName == 'cite') {
          return _renderBlockquote(
            element,
            style: style,
            renderType: renderType,
          );
        } else if (element.localName == 'hr') {
          return _renderHr(
            element,
            style: style,
            renderType: renderType,
          );
        } else if (element.localName == 'figure') {
          return _renderFigure(
            element,
            style: style,
            renderType: renderType,
          );
        } else if (element.localName == 'figcaption') {
          return _renderFigcaption(
            element,
            style: style,
            renderType: renderType,
          );
        } else if (element.localName == 'details') {
          return _renderDetailsWithSummary(
            element,
            style: style,
            renderType: renderType,
          );
        } else if (element.localName == 'span') {
          return null;
        } else if (isElementEmpty) {
          return const InlineCustomWidget(child: SizedBox.shrink());
        } else if (element.localName == 'p') {
          return _renderP(
            element,
            renderType: renderType,
            customStyle: style,
          );
        }
        return null;
      },
      customStylesBuilder: (e) {
        if (e.attributes.containsKey("data-f-id") &&
            e.attributes["data-f-id"] == "pbf") {
          return {
            'display': 'none',
          };
        }
        if (e.localName == 'custom-highlight') {
          // 浅蓝色背景
          return {
            // 'text-decoration': 'underline',
            // 'text-decoration-style': 'dashed',
            // 'text-decoration-color': 'red',
            'background-color':
                ColorUtil.isDark(context) ? '#2a2a2a' : '#e0f7fa',
          };
        }
        if (e.id == "title") {
          return {
            'font-weight': '700',
            'font-size': 'larger',
          };
        }
        if (e.localName == "ul" || e.localName == "ol") {
          var style = {
            'margin-left': '10px',
            'padding': '0',
          };
          if (renderType == RenderType.inLi) {
            style["margin-top"] = '0';
          }
          return style;
        }
        return null;
      },
      onTapUrl: (url) async {
        UriUtil.processUrl(context, url);
        return true;
      },
      onLoadingBuilder: widget.showLoading
          ? (context, _, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ChewieItemBuilder.buildLoadingDialog(
                  context: context,
                  text: chewieLocalizations.loading,
                  size: 40,
                  bottomPadding: 30,
                  topPadding: 30,
                  background: widget.placeholderBackgroundColor,
                ),
              );
            }
          : null,
      onErrorBuilder: (context, element, error) {
        return Container(
          padding: const EdgeInsets.all(16),
          margin:
              EdgeInsets.symmetric(horizontal: 10, vertical: verticalMargin),
          decoration: const BoxDecoration(
              color: Colors.red, borderRadius: ChewieDimens.borderRadius8),
          child: Text(
            'Error rendering content: $error',
            style: ChewieTheme.bodyMedium.apply(color: Colors.white),
          ),
        );
      },
    );
  }

  _renderStrong(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    return null;
    // return InlineCustomWidget(
    //   child: _render(
    //     element.innerHtml,
    //     renderType: RenderType.inStrong,
    //     customStyle: style?.apply(fontWeightDelta: 2),
    //   ),
    // );
  }

  _renderItalic(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    return InlineCustomWidget(
      child: _render(
        element.innerHtml,
        renderType: RenderType.inStrong,
        customStyle: style?.apply(fontStyle: FontStyle.italic),
      ),
    );
  }

  _renderTex(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    return InlineCustomWidget(
      child: Text(
        element.text,
        style: style?.apply(
              fontSizeDelta: 2,
              color: style.color ?? ChewieTheme.bodyMedium.color,
            ) ??
            ChewieTheme.bodyMedium.apply(fontSizeDelta: 2),
      ),
    );
  }

  Widget _renderDetailsWithSummary(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    dom.Element? summaryElement;
    final detailChildren = [];
    for (var child in element.children) {
      if (child.localName == 'summary') {
        summaryElement = child;
      } else {
        detailChildren.add(child);
      }
    }
    final summaryText = summaryElement?.innerHtml ?? '详情';
    final detailHtml = detailChildren.map((e) => e.outerHtml).join();

    return InlineCustomWidget(
      child: ExpandableItem(
        summary: _render(
          summaryText,
          renderType: RenderType.inDetails,
          customStyle: style?.apply(
            fontWeightDelta: 2,
          ),
        ),
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(ChewieDimens.borderRadius8.topLeft.x),
            ),
          ),
          child: _render(
            detailHtml,
            renderType: RenderType.inDetails,
            customStyle: style,
          ),
        ),
      ),
    );
  }

  _renderP(
    dom.Element element, {
    TextStyle? customStyle,
    RenderType renderType = RenderType.normal,
  }) {
    if (renderType == RenderType.inLi) {
      return _render(
        element.innerHtml,
        renderType: renderType,
        customStyle: customStyle,
      );
    }
  }

  bool _isCodeFigure(element) {
    final tables = element.getElementsByTagName('table');
    if (tables.isNotEmpty) {
      final preTags = tables.first.getElementsByTagName('pre');
      if (preTags.isNotEmpty) return true;
    }
    final preTags = element.getElementsByTagName('pre');
    if (preTags.isNotEmpty) return true;

    return false;
  }

  _renderFigure(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    if (_isCodeFigure(element)) {
      return _renderCodeFigure(
        element,
        style: style,
        renderType: RenderType.inFigure,
      );
    } else {
      return InlineCustomWidget(
        child: Container(
          margin:
              EdgeInsets.symmetric(vertical: verticalMargin, horizontal: 10),
          child: _render(
            element.innerHtml,
            customStyle: style,
            renderType: RenderType.inFigure,
          ),
        ),
      );
    }
  }

  Widget _renderCodeFigure(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    String code = '';
    for (var child in element.querySelectorAll('tr')) {
      var cells = child.querySelectorAll('td');
      if (cells.length == 2) {
        code += '${HtmlUtil.extractCodeFromPre(cells[1].children[0])}\n';
      } else {
        code += '${child.text.trim()}\n';
      }
    }
    dom.Element preElement = dom.Element.tag('pre');
    dom.Element codeElement = dom.Element.tag('code');
    codeElement.text = code.trim();
    preElement.children.add(codeElement);
    return _render(
      preElement.outerHtml,
      renderType: RenderType.inFigure,
      customStyle: style,
    );
  }

  _renderFigcaption(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    return InlineCustomWidget(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: verticalMargin, horizontal: 30),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Center(
          child: _render(
            element.innerHtml,
            heightDelta: -0.5,
            customStyle: style?.apply(
              fontSizeDelta: -2,
              color: style.color?.withAlpha(200),
            ),
          ),
        ),
      ),
    );
  }

  _renderHr(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32),
        width: 480,
        height: 1,
        decoration: BoxDecoration(
          borderRadius: ChewieDimens.borderRadius8,
          color: ChewieTheme.borderColor,
        ),
      ),
    );
  }

  _renderBlockquote(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    return InlineCustomWidget(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: verticalMargin),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
              left: BorderSide(color: ChewieTheme.markerColor, width: 3)),
        ),
        child: _render(
          element.innerHtml,
          customStyle: style,
          renderType: RenderType.inBlockquote,
        ),
      ),
    );
  }

  _renderH(
    dom.Element element,
    List<String> titles, {
    int lastIndex = 0,
  }) {
    var text = element.text.trim();
    late Anchor anchor;
    TextStyle style = ChewieTheme.titleLarge;
    try {
      var index = titles.indexOf(text, lastIndex);
      if (index != -1) {
        lastIndex = index + 1;
      } else {
        index = titles.indexOf(text);
      }
      if (index < 0 || index >= widget.anchors.length) {
        anchor = Anchor(AnchorType.fromString(element.localName!), text);
      } else {
        anchor = widget.anchors[index];
      }
    } catch (e, t) {
      ILogger.error(
          'render h error for ${element.localName} "$text" from $titles after $lastIndex',
          e,
          t);
    }
    switch (element.localName) {
      case 'h1':
        style = ChewieTheme.titleLarge.apply(fontSizeDelta: 4);
        break;
      case 'h2':
        style = ChewieTheme.titleLarge.apply(fontSizeDelta: 2);
        break;
      case 'h3':
        style = ChewieTheme.titleLarge;
        break;
      case 'h4':
        style = ChewieTheme.titleLarge.apply(fontSizeDelta: -1);
        break;
      case 'h5':
        style = ChewieTheme.titleLarge.apply(fontSizeDelta: -2);
        break;
      case 'h6':
        style = ChewieTheme.titleLarge.apply(fontSizeDelta: -3);
        break;
    }
    return [
      lastIndex,
      AnchorWidget(
        id: anchor.id,
        child: GestureDetector(
          onTap: () {
            if (widget.onAnchorTap != null) {
              widget.onAnchorTap!(anchor);
            }
          },
          child: MouseStateBuilder(
            builder: (context, state) => Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: verticalMargin),
              // decoration: BoxDecoration(
              //   color: ChewieTheme.cardColor,
              //   border: Border(
              //       left: BorderSide(color: ChewieTheme.primaryColor, width: 2)),
              // ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _render(
                      element.innerHtml,
                      customStyle: style,
                      renderType: RenderType.inH,
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: state.isMouseOver ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: ClickableGestureDetector(
                        onTap: () {
                          if (widget.onAnchorTap != null) {
                            widget.onAnchorTap!(anchor);
                          }
                        },
                        child: Icon(
                          LucideIcons.hash,
                          size: 20,
                          color: ChewieTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  _renderA(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
    double horizontalPadding = 6,
  }) {
    String url = element.attributes['href'] ?? "";
    String innerHtml = element.innerHtml.trim();
    String text = element.text.trim();
    bool hasImage = element.querySelector('img') != null;
    bool hasText = element.text.trim().isNotEmpty;
    bool isHashtag = WebUtil.isHashOnlyLink(url);
    var linkStyle = style?.apply(
      fontSizeDelta: -1,
      letterSpacingDelta: -1,
      fontWeightDelta: 2,
      color: ChewieColors.getLinkColor(context),
    );
    if (url.isEmpty || (isHashtag && renderType == RenderType.inH)) {
      return InlineCustomWidget(
          child: _render(innerHtml,
              renderType: renderType, customStyle: linkStyle));
    }

    return InlineCustomWidget(
      child: Wrap(
        children: [
          ToolTipWrapper(
            richMessage: TextSpan(
              children: [
                TextSpan(
                  text: url,
                  style: linkStyle?.apply(
                    color: ChewieColors.getLinkColor(context),
                  ),
                ),
              ],
            ),
            child: MouseStateBuilder(
              builder: (context, state) {
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onHover: (_) {
                    //   if (ResponsiveUtil.isLandscapeLayout()) {
                    //     _url = url;
                    //     _startHoverTimer();
                    //   }
                  },
                  onExit: (_) async {
                    //   _url = null;
                    //   _cancelHoverTimer();
                    //   await UrlPreviewHelper.remove();
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (isHashtag) {
                        if (widget.onHashtagTap != null) {
                          widget.onHashtagTap!(url.substring(1));
                        }
                      } else {
                        UriUtil.processUrl(context, url);
                      }
                    },
                    onSecondaryTap: () {
                      if (!isHashtag) {
                        BottomSheetBuilder.showContextMenu(
                            context, _buildLinkContextMenuButtons(url));
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: state.isMouseOver && !hasImage
                            ? ChewieTheme.cardColor
                            : null,
                        borderRadius: state.isMouseOver
                            ? ChewieDimens.borderRadius8
                            : BorderRadius.zero,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                                child: SizedBox(width: horizontalPadding)),
                            hasImage
                                ? WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: _render(
                                      innerHtml,
                                      renderType: RenderType.inA,
                                      customStyle: linkStyle,
                                    ),
                                  )
                                : hasText
                                    ? TextSpan(
                                        text: text,
                                        style: linkStyle,
                                      )
                                    : const TextSpan(),
                            if (!hasImage && !isHashtag) ...[
                              if (hasText)
                                const WidgetSpan(child: SizedBox(width: 4)),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  LucideIcons.externalLink,
                                  size: 16,
                                  color: ChewieColors.getLinkColor(context),
                                ),
                              ),
                            ],
                            if (isHashtag) ...[
                              if (hasText)
                                const WidgetSpan(child: SizedBox(width: 4)),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  LucideIcons.hash,
                                  size: 16,
                                  color: ChewieColors.getLinkColor(context),
                                ),
                              ),
                            ],
                            WidgetSpan(
                                child: SizedBox(width: horizontalPadding)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderUlLi(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    const bulletSize = 6.0;
    final fontSize = style?.fontSize ?? 14.0;
    final height = style?.height ?? 1.2;
    final baselineOffset = fontSize * height * 0.7;

    return InlineCustomWidget(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Baseline(
            baseline: baselineOffset,
            baselineType: TextBaseline.alphabetic,
            child: Container(
              width: bulletSize,
              height: bulletSize,
              decoration: BoxDecoration(
                color: ChewieTheme.markerColor,
                borderRadius: BorderRadius.circular(bulletSize / 2),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: _render(
              element.innerHtml,
              renderType: RenderType.inLi,
              customStyle: style,
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderOlLi(
    dynamic element, {
    required int index,
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    final fontSize = style?.fontSize ?? 14.0;
    final height = style?.height ?? 1.2;

    final baselineOffset = fontSize * height * 0.8;
    final dom.Element? parentElement = element.parent;
    int start = 1;
    if (parentElement != null && parentElement.localName == 'ol') {
      int? startValue = int.tryParse(
        parentElement.attributes['start'] ?? '0',
      );
      if (startValue != null && startValue > 0) {
        start = startValue;
      }
    }
    return InlineCustomWidget(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Baseline(
            baseline: baselineOffset,
            baselineType: TextBaseline.alphabetic,
            child: Container(
              width: 32,
              alignment: Alignment.centerRight,
              child: SelectionContainer.disabled(
                child: Text(
                  '${start + index}.',
                  style: style?.apply(
                        color: ChewieTheme.textLightGreyColor,
                        fontWeightDelta: 2,
                      ) ??
                      TextStyle(
                        fontSize: fontSize,
                        height: height,
                        color: ChewieTheme.textLightGreyColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _render(
              element.innerHtml,
              renderType: RenderType.inLi,
              customStyle: style,
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderTable(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    List<String> theader = [];
    List<List<String>> tbody = [];
    for (var child in element.children) {
      if (child.localName == 'thead') {
        for (var header in child.querySelectorAll('th')) {
          theader.add(header.innerHtml.trim());
        }
      } else if (child.localName == 'tbody') {
        for (var row in child.querySelectorAll('tr')) {
          List<String> cells = [];
          for (var cell in row.querySelectorAll('td')) {
            cells.add(cell.innerHtml.trim());
          }
          tbody.add(cells);
        }
      }
    }

    return InlineCustomWidget(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: verticalMargin),
        decoration: BoxDecoration(
          border: ChewieTheme.border,
          borderRadius: ChewieDimens.borderRadius8,
        ),
        child: Table(
          border: TableBorder.symmetric(
              inside: BorderSide(color: ChewieTheme.borderColor, width: 1)),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            if (theader.isNotEmpty)
              TableRow(
                decoration: BoxDecoration(
                    color: ChewieTheme.cardColor,
                    borderRadius:
                        const BorderRadius.vertical(top: ChewieDimens.radius8)),
                children: theader.map((headerText) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: _render(
                        headerText,
                        renderType: RenderType.inTableHeader,
                        customStyle: style?.apply(
                          fontWeightDelta: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ...tbody.map((row) {
              return TableRow(
                children: row.map((cellText) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: _render(
                        cellText,
                        renderType: RenderType.inTableBody,
                        customStyle: style,
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _renderImg(
    dom.Element element,
    List<String> images, {
    Function()? onDownloadSuccess,
  }) {
    String imageUrl =
        element.attributes['src'] ?? element.attributes['data-src'] ?? '';
    String caption = element.attributes['alt'] ??
        element.attributes['title'] ??
        element.attributes['data-caption'] ??
        '';
    imageUrl = WebUtil.resolveRelativeUrl(widget.url ?? "", imageUrl);
    if (imageUrl.isEmpty) {
      return const InlineCustomWidget(child: SizedBox.shrink());
    }
    var res = ClickableGestureDetector(
      onTap: () {
        if (imageUrl.isNotEmpty) {
          RouteUtil.pushDialogRoute(
            context,
            showClose: false,
            fullScreen: true,
            useFade: true,
            opaque: false,
            barrierDismissible: false,
            animation: false,
            HeroPhotoViewScreen(
              imageUrls: images,
              useMainColor: true,
              initIndex: images.indexOf(imageUrl),
              onDownloadSuccess: onDownloadSuccess,
            ),
          );
        }
      },
      onLongPress: () {
        BottomSheetBuilder.showContextMenu(
          context,
          _buildImageContextMenuButtons(imageUrl),
        );
      },
      onSecondaryTap: () {
        BottomSheetBuilder.showContextMenu(
          context,
          _buildImageContextMenuButtons(imageUrl),
        );
      },
      child: Hero(
        tag: ChewieUtils.getHeroTag(url: imageUrl),
        child: ClipRRect(
          borderRadius: ChewieDimens.borderRadius8,
          child: ChewieItemBuilder.buildCachedImage(
            context: context,
            imageUrl: imageUrl,
            baseUrl: WebUtil.getBaseUrl(widget.url ?? "").toString(),
            fit: BoxFit.cover,
            width: double.infinity,
            placeholderHeight: 300,
          ),
        ),
      ),
    );
    return ToolTipWrapper(
      message: caption,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: verticalMargin * 2),
        child: res,
      ),
    );
  }

  _renderPre(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    var radius = ChewieDimens.radius8;
    var code = HtmlUtil.extractTextFromHtml(element.outerHtml).trim();
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: verticalMargin, horizontal: 10),
      decoration: BoxDecoration(
        border: ChewieTheme.borderWithWidth(1),
        borderRadius: BorderRadius.all(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: ChewieTheme.appBarBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
              ),
              border: ChewieTheme.bottomBorderWithWidth(1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SelectionContainer.disabled(
                    child: Text(
                      HtmlUtil.detectLanguage(code).toUpperCase(),
                      style: ChewieTheme.titleMedium,
                    ),
                  ),
                ),
                ToggleIconButton(
                  iconA: const Icon(LucideIcons.copy, size: 16),
                  iconB: const Icon(LucideIcons.check, size: 16),
                  onPressed: () {
                    ChewieUtils.copy(context, code);
                  },
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: radius,
              bottomRight: radius,
            ),
            child: Selector<ChewieProvider, ActiveThemeMode>(
              selector: (context, chewieProvider) => chewieProvider.themeMode,
              builder: (context, themeMode, child) {
                final lines = code.split('\n');
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectionContainer.disabled(
                      child: Container(
                        color: ChewieTheme.appBarBackgroundColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(lines.length, (index) {
                            return Text(
                              '${index + 1}',
                              style: ChewieTheme.bodyMedium.apply(
                                fontSizeDelta: 1,
                                color: themeMode == ActiveThemeMode.light
                                    ? Colors.grey
                                    : Colors.grey[400],
                                heightDelta: -0.01,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CodeHighlightView(
                        code,
                        language: HtmlUtil.detectLanguage(code),
                        theme: themeMode == ActiveThemeMode.light
                            ? atomOneLightTheme
                            : atomOneDarkTheme,
                        padding: const EdgeInsets.all(12),
                        textStyle: ChewieTheme.bodyMedium.apply(
                          fontSizeDelta: 1,
                          letterSpacingDelta: 1.5,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _renderCode(
    dom.Element element, {
    TextStyle? style,
    RenderType renderType = RenderType.normal,
  }) {
    return InlineCustomWidget(
      child: GestureDetector(
        onLongPress: () {
          ChewieUtils.copy(context, element.text.trim());
        },
        child: Container(
          decoration: BoxDecoration(
            color: ChewieTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            element.text.trim(),
            style: style?.apply(
              fontSizeDelta: -2,
              fontWeightDelta: renderType == RenderType.inStrong ? 2 : 0,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomImageFactory extends WidgetFactory {
  @override
  Widget? buildImageWidget(BuildTree tree, ImageSource src) {
    final url = src.url;
    if (url.startsWith('asset:') ||
        url.startsWith('data:image/') ||
        url.startsWith('file:')) {
      return super.buildImageWidget(tree, src);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.fill,
      placeholder: (_, __) => emptyWidget,
      errorWidget: (_, __, ___) => emptyWidget,
    );
  }
}
