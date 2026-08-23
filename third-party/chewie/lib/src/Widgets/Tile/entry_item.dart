import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EntryItem extends SearchableStatefulWidget {
  // Retained for source compatibility with Loftify's existing item builders.
  final BuildContext? context;
  final double radius;
  final bool roundTop;
  final bool roundBottom;
  final bool showLeading;
  final bool showTrailing;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? descriptionColor;
  final CrossAxisAlignment crossAxisAlignment;
  final IconData leading;
  final Widget? leadingWidget;
  final String tip;
  final Function()? onTap;
  final double? paddingVertical;
  final double? paddingHorizontal;
  // Legacy shorthand retained while callers migrate to axis-specific padding.
  final double? padding;
  final double trailingLeftMargin;
  final bool dividerPadding;
  final IconData trailing;
  final double tipWidth;
  final double minTipWidth;
  final Widget? tipWidget;
  final bool ink;

  const EntryItem({
    super.key,
    this.context,
    this.radius = 8,
    this.roundTop = false,
    this.roundBottom = false,
    this.showLeading = false,
    this.showTrailing = true,
    this.backgroundColor,
    this.titleColor,
    this.descriptionColor,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.leading = LucideIcons.house,
    this.leadingWidget,
    this.tip = "",
    this.onTap,
    this.paddingVertical,
    this.paddingHorizontal,
    this.padding,
    this.trailingLeftMargin = 5,
    this.dividerPadding = true,
    this.trailing = LucideIcons.chevronRight,
    this.tipWidth = 140,
    this.minTipWidth = 80,
    this.tipWidget,
    this.ink = true,
    required super.title,
    super.description,
    super.searchText,
    super.searchConfig,
  });

  @override
  List<String> get sentences => [title, description];

  @override
  State<EntryItem> createState() => EntryItemState();

  @override
  SearchableStatefulWidget copyWith({
    String? searchText,
    SearchConfig? searchConfig,
  }) {
    return EntryItem(
      context: context,
      searchConfig: searchConfig ?? this.searchConfig,
      title: title,
      description: description,
      searchText: searchText ?? this.searchText,
      radius: radius,
      roundTop: roundTop,
      roundBottom: roundBottom,
      showLeading: showLeading,
      showTrailing: showTrailing,
      backgroundColor: backgroundColor,
      titleColor: titleColor,
      descriptionColor: descriptionColor,
      crossAxisAlignment: crossAxisAlignment,
      leading: leading,
      leadingWidget: leadingWidget,
      tip: tip,
      onTap: onTap,
      paddingVertical: paddingVertical,
      paddingHorizontal: paddingHorizontal,
      padding: padding,
      trailingLeftMargin: trailingLeftMargin,
      dividerPadding: dividerPadding,
      trailing: trailing,
      tipWidth: tipWidth,
      minTipWidth: minTipWidth,
      tipWidget: tipWidget,
      ink: ink,
    );
  }
}

class EntryItemState extends SearchableState<EntryItem> {
  double get _paddingVertical => widget.paddingVertical ?? widget.padding ?? 14;

  double get _paddingHorizontal =>
      widget.paddingHorizontal ?? widget.padding ?? 6;

  Color get _leadingColor => widget.titleColor ?? ChewieTheme.primaryColor;

  BorderRadius get _borderRadius => BorderRadius.vertical(
        top: widget.roundTop ? Radius.circular(widget.radius) : Radius.zero,
        bottom:
            widget.roundBottom ? Radius.circular(widget.radius) : Radius.zero,
      );

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();
    return InkAnimation(
      color: widget.backgroundColor ?? ChewieTheme.canvasColor,
      ink: widget.ink,
      borderRadius: _borderRadius,
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: _borderRadius,
        ),
        padding: EdgeInsets.only(
          top: _paddingVertical,
          bottom: _paddingVertical,
          left: _paddingHorizontal,
          right: _paddingHorizontal + 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _buildRowChildren(),
        ),
      ),
    );
  }

  List<Widget> _buildRowChildren() {
    final hasLeading = widget.showLeading || widget.leadingWidget != null;
    return [
      if (hasLeading) _buildLeadingIcon(),
      SizedBox(width: hasLeading ? 10 : 5),
      Expanded(child: _buildTextContent()),
      if (widget.tipWidget != null) const SizedBox(width: 10),
      if (widget.tipWidget != null) _buildCustomTipWidget(),
      if (widget.tipWidget == null) const SizedBox(width: 10),
      if (widget.tipWidget == null) _buildTipWidget(),
    ];
  }

  Widget _buildLeadingIcon() {
    if (widget.leadingWidget != null) {
      return Container(
        margin: const EdgeInsets.only(left: 4),
        child: widget.leadingWidget!,
      );
    }
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: _leadingColor.withAlpha(25),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(widget.leading, size: 15, color: _leadingColor),
    );
  }

  Widget _buildTextContent() {
    final titleStyle = ChewieTheme.titleMedium.apply(color: widget.titleColor);
    final descStyle =
        ChewieTheme.bodySmall.apply(color: widget.descriptionColor);
    final highlightTitleStyle = titleStyle.copyWith(
      color: ChewieTheme.warningColor,
      fontWeight: FontWeight.bold,
    );
    final highlightDescStyle = descStyle.copyWith(
      color: ChewieTheme.warningColor,
      fontWeight: FontWeight.bold,
    );
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
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

  Widget _buildTipWidget() {
    if (!widget.showTrailing && widget.tip.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.tip.isNotEmpty)
          Flexible(
            child: Text(
              widget.tip,
              style: ChewieTheme.bodyMedium.apply(
                color: ChewieTheme.bodySmall.color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        if (widget.tip.isNotEmpty && widget.showTrailing)
          const SizedBox(width: 6),
        if (widget.showTrailing)
          Icon(
            widget.trailing,
            size: 16,
            color: ChewieTheme.bodySmall.color,
          ),
      ],
    );
  }

  Widget _buildCustomTipWidget() {
    return Container(
      constraints: BoxConstraints(
        minWidth: widget.minTipWidth,
        maxWidth: widget.description.isNotEmpty
            ? widget.tipWidth
            : widget.tipWidth + 40,
      ),
      child: widget.tipWidget!,
    );
  }
}

class SearchableCaptionItem extends SearchableStatefulWidget {
  final EdgeInsetsGeometry? padding;
  final bool showDivider;
  final List<SearchableStatefulWidget> children;
  final bool initiallyExpanded;

  const SearchableCaptionItem({
    super.key,
    required super.title,
    this.padding,
    this.showDivider = true,
    this.children = const [],
    this.initiallyExpanded = true,
    super.searchText,
    super.description,
    super.searchConfig,
  });

  @override
  SearchableCaptionItemState createState() => SearchableCaptionItemState();

  @override
  List<String> get sentences =>
      children.map((c) => c.sentences).expand((e) => e).toList();

  @override
  SearchableStatefulWidget copyWith({
    String? searchText,
    SearchConfig? searchConfig,
  }) {
    return SearchableCaptionItem(
      title: title,
      padding: padding,
      showDivider: showDivider,
      initiallyExpanded: initiallyExpanded,
      searchText: searchText ?? this.searchText,
      searchConfig: searchConfig,
      children: children,
    );
  }
}

class SearchableCaptionItemState extends SearchableState<SearchableCaptionItem>
    with TickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _arrowAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _arrowAnimation = Tween<double>(begin: 0, end: 0.5).animate(_controller);

    if (_isExpanded) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: ChewieTheme.canvasColor,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _sizeAnimation,
                axisAlignment: -1.0,
                child: Column(children: _buildChildren()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggleExpansion,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Padding(
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ChewieTheme.textDarkGreyColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            RotationTransition(
              turns: _arrowAnimation,
              child: Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: ChewieTheme.textDarkGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChildren() {
    final children =
        widget.children.map((child) => _withUpdatedSearchText(child)).toList();
    final result = <Widget>[
      Container(
        height: 0.5,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: ChewieTheme.dividerColor,
      ),
    ];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        result.add(Container(
          height: 0.5,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: ChewieTheme.dividerColor,
        ));
      }
      result.add(children[i]);
    }
    return result;
  }

  SearchableStatefulWidget _withUpdatedSearchText(
      SearchableStatefulWidget child) {
    return child.copyWith(
      searchText: widget.searchText,
      searchConfig: widget.searchConfig,
    );
  }
}

class CaptionItem extends StatefulWidget {
  // Retained for source compatibility with existing Loftify screens.
  final BuildContext? context;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;
  final List<Widget> children;
  final bool initiallyExpanded;
  final String title;

  const CaptionItem({
    super.key,
    this.context,
    required this.title,
    this.padding,
    this.showDivider = true,
    this.children = const [],
    this.initiallyExpanded = true,
  });

  @override
  CaptionItemState createState() => CaptionItemState();
}

class CaptionItemState extends BaseDynamicState<CaptionItem>
    with TickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _arrowAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _arrowAnimation = Tween<double>(begin: 0, end: 0.5).animate(_controller);

    if (_isExpanded) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return Padding(
        padding: widget.padding ??
            const EdgeInsets.only(left: 12, right: 12, top: 20, bottom: 10),
        child: Text(
          widget.title,
          style: ChewieTheme.labelSmall.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: ChewieTheme.textDarkGreyColor,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: ChewieTheme.canvasColor,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _sizeAnimation,
                axisAlignment: -1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildChildren(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggleExpansion,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Padding(
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: ChewieTheme.labelSmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ChewieTheme.textDarkGreyColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            RotationTransition(
              turns: _arrowAnimation,
              child: Icon(
                LucideIcons.chevronDown,
                size: 20,
                color: ChewieTheme.textDarkGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChildren() {
    final result = <Widget>[
      Container(
        height: 0.5,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: ChewieTheme.dividerColor,
      ),
    ];
    for (int i = 0; i < widget.children.length; i++) {
      if (i > 0) {
        result.add(Container(
          height: 0.5,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: ChewieTheme.dividerColor,
        ));
      }
      result.add(widget.children[i]);
    }
    return result;
  }
}
