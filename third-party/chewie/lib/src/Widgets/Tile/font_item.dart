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
  late Future<bool> _fontExists;

  @override
  void initState() {
    super.initState();
    _fontExists = CustomFont.isFontFileExist(widget.font);
  }

  @override
  void didUpdateWidget(covariant FontItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.font != widget.font) {
      _fontExists = CustomFont.isFontFileExist(widget.font);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.font == widget.currentFont;
    final labelHeight = MediaQuery.textScalerOf(context).scale(36);
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
                decoration: BoxDecoration(
                  color: selected
                      ? ChewieTheme.primaryColor.withValues(alpha: 0.06)
                      : ChewieTheme.canvasColor,
                  border: selected
                      ? Border.all(color: ChewieTheme.primaryColor, width: 1.5)
                      : ChewieTheme.border,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 40),
                      child: MediaQuery.withNoTextScaling(
                        child: FutureBuilder<bool>(
                          future: _fontExists,
                          builder: (context, snapshot) {
                            return snapshot.data != false
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
                                    style: ChewieTheme.bodySmall,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  );
                          },
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: ChewieTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              LucideIcons.check,
                              size: 12,
                              color:
                                  ChewieTheme.primaryColor.computeLuminance() >
                                          0.5
                                      ? Colors.black
                                      : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (widget.showDelete)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: IconButton(
                          key:
                              ValueKey('font-delete-${widget.font.fontFamily}'),
                          icon: Icon(
                            LucideIcons.trash2,
                            color: ChewieTheme.errorColor,
                            size: 17,
                          ),
                          constraints: const BoxConstraints.tightFor(
                            width: 40,
                            height: 40,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () => widget.onDelete?.call(widget.font),
                        ),
                      ),
                    if (!widget.showDelete)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          width: 22,
                          height: 3,
                          decoration: BoxDecoration(
                            color: selected
                                ? ChewieTheme.primaryColor
                                : ChewieTheme.borderColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: labelHeight,
                child: Center(
                  child: Text(
                    widget.font.intlFontName,
                    style: ChewieTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
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
    final labelHeight = MediaQuery.textScalerOf(context).scale(36);
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.plus,
                  size: 30,
                  color: ChewieTheme.labelSmall.color,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: labelHeight,
                child: Center(
                  child: Text(
                    chewieLocalizations.loadFontFamily,
                    style: ChewieTheme.bodySmall,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
