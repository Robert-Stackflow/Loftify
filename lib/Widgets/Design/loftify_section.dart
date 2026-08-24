import 'package:flutter/material.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

enum LoftifyEntryVisualState {
  normal,
  selected,
  loading,
  success,
  warning,
  error,
}

/// Token-driven list entry used by settings, management and personal-center
/// sections. It deliberately grows with text scale instead of fixing row height.
class LoftifyEntryItem extends StatelessWidget {
  const LoftifyEntryItem({
    super.key,
    required this.title,
    this.description = '',
    this.tip = '',
    this.leading,
    this.leadingWidget,
    this.trailing,
    this.showLeading = false,
    this.showTrailing = true,
    this.onTap,
    this.enabled = true,
    this.visualState = LoftifyEntryVisualState.normal,
    this.density = LoftifyDensityRole.controlComfortable,
    this.semanticLabel,
  });

  final String title;
  final String description;
  final String tip;
  final IconData? leading;
  final Widget? leadingWidget;
  final Widget? trailing;
  final bool showLeading;
  final bool showTrailing;
  final VoidCallback? onTap;
  final bool enabled;
  final LoftifyEntryVisualState visualState;
  final LoftifyDensityRole density;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final colors = design.colors;
    final effectiveEnabled =
        enabled && visualState != LoftifyEntryVisualState.loading;
    final foreground = _foregroundColor(colors);
    final opacity = effectiveEnabled ? 1.0 : design.icons.disabledOpacity;
    final background = switch (visualState) {
      LoftifyEntryVisualState.selected => colors.accentContainer,
      LoftifyEntryVisualState.success =>
        Color.alphaBlend(colors.success.withAlpha(20), Colors.transparent),
      LoftifyEntryVisualState.warning =>
        Color.alphaBlend(colors.warning.withAlpha(20), Colors.transparent),
      LoftifyEntryVisualState.error =>
        Color.alphaBlend(colors.danger.withAlpha(20), Colors.transparent),
      LoftifyEntryVisualState.normal ||
      LoftifyEntryVisualState.loading =>
        Colors.transparent,
    };

    return Semantics(
      button: onTap != null,
      enabled: effectiveEnabled,
      selected: visualState == LoftifyEntryVisualState.selected,
      label: semanticLabel,
      child: AnimatedContainer(
        duration: design.motion.effective(context, design.motion.state),
        curve: design.motion.enterCurve,
        color: background,
        constraints: BoxConstraints(
          minHeight: design.density.minimumHeight(density),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: effectiveEnabled ? onTap : null,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return colors.accent.withAlpha(
                  (design.icons.pressedOpacity * 255).round(),
                );
              }
              if (states.contains(WidgetState.focused)) {
                return colors.accent.withAlpha(
                  (design.icons.focusOpacity * 255).round(),
                );
              }
              if (states.contains(WidgetState.hovered)) {
                return colors.accent.withAlpha(
                  (design.icons.hoverOpacity * 255).round(),
                );
              }
              return Colors.transparent;
            }),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: design.spacing.xl,
                vertical: design.density.verticalPadding(density),
              ),
              child: Opacity(
                opacity: opacity,
                child: Row(
                  crossAxisAlignment: description.isEmpty
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    if (showLeading || leadingWidget != null) ...[
                      _buildLeading(context, foreground),
                      SizedBox(width: design.spacing.lg),
                    ],
                    Expanded(child: _buildText(context, foreground)),
                    if (_hasTrailing) ...[
                      SizedBox(width: design.spacing.lg),
                      _buildTrailing(context, foreground),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasTrailing =>
      trailing != null ||
      tip.isNotEmpty ||
      showTrailing ||
      visualState != LoftifyEntryVisualState.normal;

  Color _foregroundColor(LoftifyColorTokens colors) => switch (visualState) {
        LoftifyEntryVisualState.success => colors.success,
        LoftifyEntryVisualState.warning => colors.warning,
        LoftifyEntryVisualState.error => colors.danger,
        LoftifyEntryVisualState.normal ||
        LoftifyEntryVisualState.selected ||
        LoftifyEntryVisualState.loading =>
          colors.accent,
      };

  Widget _buildLeading(BuildContext context, Color foreground) {
    final design = context.design;
    if (leadingWidget != null) {
      return SizedBox.square(
        dimension: design.icons.minimumTapTarget - design.spacing.xl,
        child: Center(child: leadingWidget),
      );
    }
    return Container(
      width: design.icons.minimumTapTarget - design.spacing.xl,
      height: design.icons.minimumTapTarget - design.spacing.xl,
      decoration: BoxDecoration(
        color: foreground.withAlpha(
          (design.icons.selectedContainerOpacity * 255).round(),
        ),
        borderRadius: BorderRadius.circular(design.radii.control),
      ),
      alignment: Alignment.center,
      child: Icon(
        leading ?? LoftifyIcons.info,
        size: design.icons.regular,
        color: foreground,
      ),
    );
  }

  Widget _buildText(BuildContext context, Color foreground) {
    final design = context.design;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: design.typography.cardTitle.copyWith(
            color: visualState == LoftifyEntryVisualState.error
                ? foreground
                : design.colors.textPrimary,
          ),
        ),
        if (description.isNotEmpty) ...[
          SizedBox(height: design.spacing.xs),
          Text(
            description,
            style: design.typography.metadata.copyWith(
              color: design.colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing(BuildContext context, Color foreground) {
    final design = context.design;
    final stateWidget = switch (visualState) {
      LoftifyEntryVisualState.loading =>
        LottieFiles.buildLoadingAnimation(design.icons.large, false),
      LoftifyEntryVisualState.success => Icon(
          LoftifyIcons.check,
          size: design.icons.regular,
          color: foreground,
        ),
      LoftifyEntryVisualState.warning || LoftifyEntryVisualState.error => Icon(
          LoftifyIcons.warning,
          size: design.icons.regular,
          color: foreground,
        ),
      LoftifyEntryVisualState.normal ||
      LoftifyEntryVisualState.selected =>
        null,
    };
    if (stateWidget != null) return stateWidget;
    if (trailing != null) return trailing!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tip.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              tip,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: design.typography.metadata.copyWith(
                color: design.colors.textSecondary,
              ),
            ),
          ),
        if (tip.isNotEmpty && showTrailing) SizedBox(width: design.spacing.sm),
        if (showTrailing)
          Icon(
            LoftifyIcons.next,
            size: design.icons.small,
            color: design.colors.textMuted,
          ),
      ],
    );
  }
}

/// A low-noise section surface with tokenized rhythm and optional expansion.
class LoftifySection extends StatefulWidget {
  const LoftifySection({
    super.key,
    required this.title,
    this.children = const <Widget>[],
    this.initiallyExpanded = true,
    this.collapsible = true,
    this.margin,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool collapsible;
  final EdgeInsetsGeometry? margin;

  @override
  State<LoftifySection> createState() => _LoftifySectionState();
}

class _LoftifySectionState extends State<LoftifySection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant LoftifySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    if (widget.children.isEmpty) {
      return Padding(
        padding: widget.margin ??
            EdgeInsets.only(
              top: design.spacing.xxl,
              left: design.spacing.xl,
              right: design.spacing.xl,
              bottom: design.spacing.md,
            ),
        child: Text(widget.title, style: design.typography.sectionTitle),
      );
    }

    return Padding(
      padding: widget.margin ?? EdgeInsets.only(top: design.spacing.sectionTop),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(design.radii.card),
        child: ColoredBox(
          color: design.colors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              AnimatedSize(
                duration: design.motion.effective(context, design.motion.state),
                curve: design.motion.enterCurve,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Column(children: _childrenWithDividers(context))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final design = context.design;
    return Semantics(
      button: widget.collapsible,
      expanded: _expanded,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.collapsible
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: design.icons.minimumTapTarget,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: design.spacing.xl,
                vertical: design.spacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: design.typography.sectionTitle,
                    ),
                  ),
                  if (widget.collapsible) ...[
                    SizedBox(width: design.spacing.md),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: design.motion.effective(
                        context,
                        design.motion.state,
                      ),
                      curve: design.motion.enterCurve,
                      child: Icon(
                        LoftifyIcons.expand,
                        size: design.icons.regular,
                        color: design.colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _childrenWithDividers(BuildContext context) {
    final design = context.design;
    final result = <Widget>[];
    for (var index = 0; index < widget.children.length; index++) {
      result.add(
        Divider(
          height: design.borders.hairline,
          thickness: design.borders.hairline,
          indent: design.spacing.xl,
          endIndent: design.spacing.xl,
          color: design.colors.outline,
        ),
      );
      result.add(widget.children[index]);
    }
    return result;
  }
}
