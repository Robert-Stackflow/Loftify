import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class CheckboxItem extends SearchableStatefulWidget {
  // Retained for Loftify source compatibility.
  final BuildContext? context;
  final double radius;
  final bool roundTop;
  final bool roundBottom;
  final bool value;
  final Color? titleColor;
  final bool showLeading;
  final IconData leading;
  final Color? leadingColor;
  final Function()? onTap;
  final double trailingLeftMargin;
  final double padding;
  final bool disabled;
  final bool ink;

  const CheckboxItem({
    super.key,
    this.context,
    this.ink = true,
    this.radius = 8,
    this.roundTop = false,
    this.roundBottom = false,
    required this.value,
    this.titleColor,
    this.showLeading = false,
    this.leading = LucideIcons.square,
    this.leadingColor,
    required super.title,
    super.description = "",
    super.searchText = "",
    this.onTap,
    this.trailingLeftMargin = 5,
    this.padding = 12,
    this.disabled = false,
    super.searchConfig,
  });

  @override
  SearchableStatefulWidget copyWith({
    String? searchText,
    SearchConfig? searchConfig,
  }) {
    return CheckboxItem(
      context: context,
      searchConfig: searchConfig ?? this.searchConfig,
      searchText: searchText ?? this.searchText,
      title: title,
      description: description,
      radius: radius,
      roundTop: roundTop,
      roundBottom: roundBottom,
      value: value,
      titleColor: titleColor,
      showLeading: showLeading,
      leading: leading,
      leadingColor: leadingColor,
      onTap: onTap,
      trailingLeftMargin: trailingLeftMargin,
      padding: padding,
      disabled: disabled,
      ink: ink,
    );
  }

  @override
  State<CheckboxItem> createState() => CheckboxItemState();
}

class CheckboxItemState extends SearchableState<CheckboxItem> {
  double get _effectivePadding =>
      widget.description.isNotEmpty ? widget.padding : widget.padding - 3;

  BorderRadius get _borderRadius => BorderRadius.vertical(
        top: widget.roundTop ? Radius.circular(widget.radius) : Radius.zero,
        bottom:
            widget.roundBottom ? Radius.circular(widget.radius) : Radius.zero,
      );

  @override
  Widget build(BuildContext context) {
    assert(widget.padding > 5);
    if (!shouldShow) return const SizedBox.shrink();
    return InkAnimation(
      borderRadius: _borderRadius,
      ink: widget.ink,
      color: ChewieTheme.canvasColor,
      onTap: widget.disabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap?.call();
            },
      child: Padding(
        padding: EdgeInsets.only(
          top: _effectivePadding,
          bottom: _effectivePadding,
          left: 10,
          right: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _buildRowChildren(),
        ),
      ),
    );
  }

  List<Widget> _buildRowChildren() {
    return [
      if (widget.showLeading) _buildLeadingIcon(),
      const SizedBox(width: 5),
      Expanded(child: _buildTextContent()),
      SizedBox(width: widget.trailingLeftMargin),
      _buildSwitch(),
    ];
  }

  Widget _buildLeadingIcon() {
    final color = widget.leadingColor ?? ChewieTheme.primaryColor;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(widget.leading, size: 15, color: color),
    );
  }

  Widget _buildTextContent() {
    final titleStyle = ChewieTheme.titleMedium.apply(color: widget.titleColor);
    final descStyle = ChewieTheme.bodySmall;
    final highlightTitleStyle = titleStyle.copyWith(
      color: ChewieTheme.warningColor,
      fontWeight: FontWeight.bold,
    );
    final highlightDescStyle = descStyle.copyWith(
      color: ChewieTheme.warningColor,
      fontWeight: FontWeight.bold,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: highlightText(
            widget.title,
            widget.searchText,
            titleStyle,
            highlightTitleStyle,
            searchConfig: widget.searchConfig,
          ),
        ),
        if (widget.description.isNotEmpty) const SizedBox(height: 3),
        if (widget.description.isNotEmpty)
          RichText(
            text: highlightText(
              widget.description,
              widget.searchText,
              descStyle,
              highlightDescStyle,
              searchConfig: widget.searchConfig,
            ),
          ),
      ],
    );
  }

  Widget _buildSwitch({
    double scale = 0.75,
  }) {
    return Opacity(
      opacity: widget.disabled ? 0.2 : 1,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.centerRight,
        child: Switch(
          value: widget.value,
          onChanged: widget.disabled
              ? null
              : (_) {
                  HapticFeedback.lightImpact();
                  widget.onTap?.call();
                },
        ),
      ),
    );
  }
}
