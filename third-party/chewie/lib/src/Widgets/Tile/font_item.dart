import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FontItem extends StatefulWidget {
  final CustomFont font;
  final CustomFont currentFont;
  final Function(CustomFont?)? onChanged;
  final Function(CustomFont?)? onDelete;
  final bool showDelete;
  final double width;
  final double height;

  const FontItem({
    super.key,
    required this.font,
    required this.currentFont,
    required this.onChanged,
    this.onDelete,
    this.showDelete = false,
    this.width = 110,
    this.height = 154,
  });

  @override
  FontItemState createState() => FontItemState();
}

class FontItemState extends State<FontItem> {
  bool exist = true;

  @override
  Widget build(BuildContext context) {
    final selected = widget.font == widget.currentFont;
    return Semantics(
      container: true,
      selected: selected,
      button: true,
      label: widget.font.intlFontName,
      onTap: () => widget.onChanged?.call(widget.font),
      child: ClickableGestureDetector(
        onTap: () => widget.onChanged?.call(widget.font),
        child: SizedBox(
          width: widget.width,
          child: Column(
            children: [
              Container(
                width: widget.width,
                height: widget.height,
                padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
                decoration: BoxDecoration(
                  color: ChewieTheme.canvasColor,
                  border: selected
                      ? Border.all(color: ChewieTheme.primaryColor, width: 1.5)
                      : ChewieTheme.border,
                  borderRadius: ChewieDimens.borderRadius8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: widget.height - 72,
                      child: MediaQuery.withNoTextScaling(
                        child: FutureBuilder(
                          future: Future<CustomFont>.sync(() async {
                            exist =
                                await CustomFont.isFontFileExist(widget.font);
                            return widget.font;
                          }),
                          builder: (context, snapshot) {
                            return exist
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AutoSizeText(
                                        "AaBbCcDd",
                                        style: ChewieTheme.bodyMedium.apply(
                                          fontFamily: widget.font.fontFamily,
                                          letterSpacingDelta: 1,
                                        ),
                                        maxLines: 1,
                                      ),
                                      AutoSizeText(
                                        "AaBbCcDd",
                                        style: ChewieTheme.bodyMedium.apply(
                                          fontWeightDelta: 2,
                                          fontFamily: widget.font.fontFamily,
                                          letterSpacingDelta: 1,
                                        ),
                                        maxLines: 1,
                                      ),
                                      AutoSizeText(
                                        "你好世界",
                                        style: ChewieTheme.bodyMedium.apply(
                                          fontFamily: widget.font.fontFamily,
                                          letterSpacingDelta: 1,
                                        ),
                                        maxLines: 1,
                                      ),
                                      AutoSizeText(
                                        "你好世界",
                                        style: ChewieTheme.bodyMedium.apply(
                                          fontWeightDelta: 2,
                                          fontFamily: widget.font.fontFamily,
                                          letterSpacingDelta: 1,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  )
                                : Text(
                                    chewieLocalizations.fontFileNotExist,
                                    style: ChewieTheme.bodyMedium.apply(
                                      fontFamily: widget.font.fontFamily,
                                      fontWeightDelta: 0,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          selected
                              ? LucideIcons.circleCheck
                              : LucideIcons.circle,
                          size: 18,
                          color: selected
                              ? ChewieTheme.primaryColor
                              : ChewieTheme.bodySmall.color,
                        ),
                        if (widget.showDelete) const SizedBox(width: 4),
                        if (widget.showDelete)
                          IconButton(
                            key: ValueKey(
                              'font-delete-${widget.font.fontFamily}',
                            ),
                            icon: Icon(
                              LucideIcons.trash2,
                              color: ChewieTheme.errorColor,
                              size: 17,
                            ),
                            constraints: const BoxConstraints.tightFor(
                              width: 48,
                              height: 48,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              widget.onDelete?.call(widget.font);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.font.intlFontName,
                style: ChewieTheme.bodySmall.apply(
                  fontFamily: widget.font.fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyFontItem extends StatefulWidget {
  final Function()? onTap;
  final double width;
  final double height;

  const EmptyFontItem({
    super.key,
    this.onTap,
    this.width = 110,
    this.height = 154,
  });

  @override
  EmptyFontItemState createState() => EmptyFontItemState();
}

class EmptyFontItemState extends State<EmptyFontItem> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: chewieLocalizations.loadFontFamily,
      onTap: widget.onTap,
      child: ClickableGestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          child: Column(
            children: [
              Container(
                width: widget.width,
                height: widget.height,
                padding: const EdgeInsets.only(
                    top: 5, bottom: 5, left: 10, right: 10),
                decoration: BoxDecoration(
                  color: ChewieTheme.canvasColor,
                  border: ChewieTheme.border,
                  borderRadius: ChewieDimens.borderRadius8,
                ),
                child: Icon(
                  LucideIcons.plus,
                  size: 40,
                  color: ChewieTheme.labelSmall.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                chewieLocalizations.loadFontFamily,
                style: ChewieTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
