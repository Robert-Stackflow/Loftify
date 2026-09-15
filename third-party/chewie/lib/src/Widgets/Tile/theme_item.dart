import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

class ThemeItem extends StatefulWidget {
  final ChewieThemeColorData themeColorData;
  final int index;
  final int groupIndex;
  final Function(int?)? onChanged;
  final VoidCallback? onLongPress;

  const ThemeItem({
    super.key,
    required this.themeColorData,
    required this.index,
    required this.groupIndex,
    required this.onChanged,
    this.onLongPress,
  });

  @override
  State<ThemeItem> createState() => _ThemeItemState();
}

class _ThemeItemState extends State<ThemeItem> {
  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final responsiveHeight = 166.4 + 24 * (textScale - 1).clamp(0.0, 2.0);
    final selected = widget.index == widget.groupIndex;
    void selectTheme() => widget.onChanged?.call(widget.index);
    return Semantics(
      container: true,
      excludeSemantics: true,
      selected: selected,
      button: true,
      label: widget.themeColorData.i18nName,
      onTap: selectTheme,
      onLongPress: widget.onLongPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onLongPress: widget.onLongPress,
        onTap: selectTheme,
        child: Container(
          width: 107.3,
          height: responsiveHeight,
          margin: EdgeInsets.only(left: widget.index == 0 ? 10 : 0, right: 10),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(
                      top: 10, bottom: 0, left: 8, right: 8),
                  decoration: BoxDecoration(
                    color: widget.themeColorData.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: ChewieTheme.border,
                  ),
                  child: Column(
                    children: [
                      _buildCardRow(widget.themeColorData),
                      const SizedBox(height: 5),
                      _buildCardRow(widget.themeColorData),
                      const SizedBox(height: 15),
                      SizedBox.square(
                        dimension: 48,
                        child: Center(
                          child: ChewieSelectionIndicator(
                            key: ValueKey('theme-selection-${widget.index}'),
                            selected: selected,
                            selectedColor: widget.themeColorData.primaryColor,
                            unselectedColor:
                                widget.themeColorData.textLightGreyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.themeColorData.i18nName,
                style: ChewieTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardRow(ChewieThemeColorData themeColorData) {
    return Container(
      height: 35,
      width: 90,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: themeColorData.canvasColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 22,
            width: 22,
            decoration: BoxDecoration(
              color: themeColorData.splashColor,
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 5,
                width: 45,
                decoration: BoxDecoration(
                  color: themeColorData.textColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 5,
                width: 35,
                decoration: BoxDecoration(
                  color: themeColorData.textLightGreyColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyThemeItem extends StatefulWidget {
  final Function()? onTap;

  const EmptyThemeItem({
    super.key,
    required this.onTap,
  });

  @override
  State<EmptyThemeItem> createState() => _EmptyThemeItemState();
}

class _EmptyThemeItemState extends State<EmptyThemeItem> {
  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final responsiveHeight = 166.4 + 24 * (textScale - 1).clamp(0.0, 2.0);
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: chewieLocalizations.newTheme,
      onTap: widget.onTap,
      child: ClickableGestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 107.3,
          height: responsiveHeight,
          margin: const EdgeInsets.only(right: 10),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: 107.3,
                  padding: const EdgeInsets.only(
                      top: 10, bottom: 0, left: 8, right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: ChewieTheme.border,
                  ),
                  child: Icon(
                    ChewieIcons.add,
                    size: 30,
                    color: ChewieTheme.bodySmall.color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                chewieLocalizations.newTheme,
                style: ChewieTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
