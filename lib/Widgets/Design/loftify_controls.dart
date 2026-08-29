import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

enum LoftifyControlStatus { idle, loading, success, warning, error }

enum LoftifyButtonVariant { primary, secondary, tonal, ghost, danger }

enum LoftifyButtonSize { compact, regular, large }

enum LoftifyFieldStatus { normal, success, warning, error }

/// Token-driven action button. Its visual height may grow for localized text,
/// while every size keeps at least a 48 px interaction target.
class LoftifyButton extends StatelessWidget {
  const LoftifyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailing,
    this.variant = LoftifyButtonVariant.primary,
    this.size = LoftifyButtonSize.regular,
    this.status = LoftifyControlStatus.idle,
    this.expand = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? trailing;
  final LoftifyButtonVariant variant;
  final LoftifyButtonSize size;
  final LoftifyControlStatus status;
  final bool expand;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final colors = design.colors;
    final highContrast = MediaQuery.highContrastOf(context);
    final enabled = onPressed != null && status != LoftifyControlStatus.loading;
    final statusColor = switch (status) {
      LoftifyControlStatus.success => colors.success,
      LoftifyControlStatus.warning => colors.warning,
      LoftifyControlStatus.error => colors.danger,
      LoftifyControlStatus.idle || LoftifyControlStatus.loading => null,
    };
    final solid = statusColor != null ||
        variant == LoftifyButtonVariant.primary ||
        variant == LoftifyButtonVariant.danger;
    final baseColor = statusColor ??
        switch (variant) {
          LoftifyButtonVariant.primary => colors.accent,
          LoftifyButtonVariant.danger => colors.danger,
          LoftifyButtonVariant.tonal => colors.accentContainer,
          LoftifyButtonVariant.secondary => colors.surfaceRaised,
          LoftifyButtonVariant.ghost => Colors.transparent,
        };
    final foreground = solid
        ? _contrastForeground(baseColor)
        : variant == LoftifyButtonVariant.tonal
            ? colors.onAccentContainer
            : colors.textPrimary;
    final borderColor = switch (variant) {
      LoftifyButtonVariant.secondary => colors.outlineStrong,
      LoftifyButtonVariant.ghost => Colors.transparent,
      LoftifyButtonVariant.primary ||
      LoftifyButtonVariant.tonal ||
      LoftifyButtonVariant.danger =>
        highContrast ? foreground.withValues(alpha: 0.68) : Colors.transparent,
    };
    final verticalPadding = switch (size) {
      LoftifyButtonSize.compact => design.spacing.md,
      LoftifyButtonSize.regular => design.spacing.lg,
      LoftifyButtonSize.large => design.spacing.xl,
    };
    final horizontalPadding = switch (size) {
      LoftifyButtonSize.compact => design.spacing.lg,
      LoftifyButtonSize.regular => design.spacing.xl,
      LoftifyButtonSize.large => design.spacing.xxl,
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled
            ? 1
            : highContrast
                ? 0.56
                : design.icons.disabledOpacity,
        child: AnimatedContainer(
          duration: design.motion.effective(context, design.motion.state),
          curve: design.motion.enterCurve,
          width: expand ? double.infinity : null,
          constraints: BoxConstraints(
            minHeight: design.icons.minimumTapTarget,
            minWidth: design.icons.minimumTapTarget,
          ),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(design.radii.control),
            border: Border.all(
              color: borderColor,
              width:
                  highContrast ? design.borders.focus : design.borders.regular,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(design.radii.control),
            child: InkWell(
              onTap: enabled ? onPressed : null,
              splashFactory: NoSplash.splashFactory,
              borderRadius: BorderRadius.circular(design.radii.control),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                final overlayBase = solid ? foreground : colors.accent;
                if (states.contains(WidgetState.pressed)) {
                  return overlayBase.withValues(
                    alpha: design.icons.pressedOpacity,
                  );
                }
                if (states.contains(WidgetState.focused)) {
                  return overlayBase.withValues(
                    alpha: design.icons.focusOpacity,
                  );
                }
                if (states.contains(WidgetState.hovered)) {
                  return overlayBase.withValues(
                    alpha: design.icons.hoverOpacity,
                  );
                }
                return Colors.transparent;
              }),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: AnimatedSwitcher(
                  duration:
                      design.motion.effective(context, design.motion.state),
                  switchInCurve: design.motion.enterCurve,
                  switchOutCurve: design.motion.exitCurve,
                  child: _buildContent(context, foreground, solid),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color foreground, bool solid) {
    final design = context.design;
    final stateIcon = switch (status) {
      LoftifyControlStatus.success => LoftifyIcons.check,
      LoftifyControlStatus.warning ||
      LoftifyControlStatus.error =>
        LoftifyIcons.warning,
      LoftifyControlStatus.idle || LoftifyControlStatus.loading => null,
    };
    final leading = status == LoftifyControlStatus.loading
        ? SizedBox.square(
            dimension: design.icons.large,
            child: ExcludeSemantics(
              child: LottieFiles.buildLoadingAnimation(
                design.icons.large,
                solid,
              ),
            ),
          )
        : stateIcon != null
            ? Icon(stateIcon, size: design.icons.regular, color: foreground)
            : icon != null
                ? Icon(icon, size: design.icons.regular, color: foreground)
                : null;
    return Row(
      key: ValueKey(status),
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading,
          SizedBox(width: design.spacing.md),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: design.typography.label.copyWith(color: foreground),
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: design.spacing.md),
          trailing!,
        ],
      ],
    );
  }
}

/// Content-driven text field with one semantic state model for login and
/// settings forms.
class LoftifyTextField extends StatefulWidget {
  const LoftifyTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.statusText,
    this.status = LoftifyFieldStatus.normal,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.backgroundColor,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.contextMenuBuilder,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? statusText;
  final LoftifyFieldStatus status;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final Color? backgroundColor;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final String? semanticLabel;

  @override
  State<LoftifyTextField> createState() => _LoftifyTextFieldState();
}

class _LoftifyTextFieldState extends State<LoftifyTextField> {
  FocusNode? _ownedFocusNode;
  bool _hovered = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant LoftifyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)
          ?.removeListener(_handleFocusChanged);
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
      _focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final colors = design.colors;
    final highContrast = MediaQuery.highContrastOf(context);
    final focused = _focusNode.hasFocus;
    final stateColor = switch (widget.status) {
      LoftifyFieldStatus.success => colors.success,
      LoftifyFieldStatus.warning => colors.warning,
      LoftifyFieldStatus.error => colors.danger,
      LoftifyFieldStatus.normal => null,
    };
    final borderColor = stateColor ??
        (focused
            ? colors.accentForeground
            : _hovered
                ? colors.outlineStrong
                : colors.outline);
    final borderWidth =
        focused || highContrast ? design.borders.focus : design.borders.regular;
    final supportingText = widget.statusText ?? widget.helperText;

    return Semantics(
      textField: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.labelText != null) ...[
            Padding(
              padding: EdgeInsets.only(
                left: design.spacing.xs,
                bottom: design.spacing.sm,
              ),
              child: Text(
                widget.labelText!,
                style: design.typography.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
          MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: AnimatedContainer(
              duration: design.motion.effective(context, design.motion.state),
              curve: design.motion.enterCurve,
              constraints: BoxConstraints(
                minHeight: design.density.minimumHeight(
                  LoftifyDensityRole.controlComfortable,
                ),
              ),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? widget.backgroundColor ?? colors.surface
                    : colors.surfaceMuted,
                borderRadius: BorderRadius.circular(design.radii.control),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                obscureText: widget.obscureText,
                enableSuggestions: !widget.obscureText,
                autocorrect: !widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                autofillHints: widget.autofillHints,
                inputFormatters: widget.inputFormatters,
                minLines: widget.obscureText ? 1 : widget.minLines,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                onTap: widget.onTap,
                style: design.typography.body.copyWith(
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: design.typography.body.copyWith(
                    color: colors.textMuted,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: design.spacing.xl,
                    vertical: design.spacing.lg,
                  ),
                  prefixIcon: widget.prefix,
                  prefixIconConstraints: BoxConstraints(
                    minWidth: design.icons.minimumTapTarget,
                    minHeight: design.icons.minimumTapTarget,
                  ),
                  suffixIcon: widget.suffix,
                  suffixIconConstraints: BoxConstraints(
                    minWidth: design.icons.minimumTapTarget,
                    minHeight: design.icons.minimumTapTarget,
                  ),
                ),
                contextMenuBuilder: widget.contextMenuBuilder,
              ),
            ),
          ),
          if (supportingText != null && supportingText.isNotEmpty) ...[
            SizedBox(height: design.spacing.sm),
            AnimatedDefaultTextStyle(
              duration: design.motion.effective(context, design.motion.state),
              style: design.typography.metadata.copyWith(
                color: stateColor ?? colors.textSecondary,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stateColor != null) ...[
                    Icon(
                      widget.status == LoftifyFieldStatus.success
                          ? LoftifyIcons.check
                          : LoftifyIcons.warning,
                      size: design.icons.small,
                      color: stateColor,
                    ),
                    SizedBox(width: design.spacing.sm),
                  ],
                  Expanded(child: Text(supportingText)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A filter/tag control with explicit selected state and no ripple animation.
class LoftifyTag extends StatelessWidget {
  const LoftifyTag({
    super.key,
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.onPressed,
    this.leading,
    this.showSelectedIcon = true,
    this.maxWidth,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;
  final IconData? leading;
  final bool showSelectedIcon;
  final double? maxWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final colors = design.colors;
    final highContrast = MediaQuery.highContrastOf(context);
    final effectiveEnabled = enabled && onPressed != null;
    final foreground = selected
        ? colors.onAccentContainer
        : effectiveEnabled
            ? colors.textSecondary
            : colors.textMuted;
    final background = selected ? colors.accentContainer : colors.surface;
    final borderColor = selected
        ? colors.accentForeground
        : highContrast
            ? colors.outlineStrong
            : colors.outline;

    return Semantics(
      button: true,
      selected: selected,
      enabled: effectiveEnabled,
      label: semanticLabel,
      child: Opacity(
        opacity: effectiveEnabled
            ? 1
            : highContrast
                ? 0.56
                : design.icons.disabledOpacity,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: design.icons.minimumTapTarget,
            maxWidth: maxWidth ?? double.infinity,
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedContainer(
              duration: design.motion.effective(context, design.motion.state),
              curve: design.motion.enterCurve,
              constraints: const BoxConstraints(minHeight: 36),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(design.radii.control),
                border: Border.all(
                  color: borderColor,
                  width: highContrast || selected
                      ? design.borders.focus
                      : design.borders.regular,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(design.radii.control),
                child: InkWell(
                  onTap: effectiveEnabled ? onPressed : null,
                  splashFactory: NoSplash.splashFactory,
                  borderRadius: BorderRadius.circular(design.radii.control),
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return colors.accent.withValues(
                        alpha: design.icons.pressedOpacity,
                      );
                    }
                    if (states.contains(WidgetState.focused)) {
                      return colors.accent.withValues(
                        alpha: design.icons.focusOpacity,
                      );
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return colors.accent.withValues(
                        alpha: design.icons.hoverOpacity,
                      );
                    }
                    return Colors.transparent;
                  }),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: design.spacing.lg,
                      vertical: design.spacing.md,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (leading != null ||
                            (selected && showSelectedIcon)) ...[
                          Icon(
                            selected && showSelectedIcon
                                ? LoftifyIcons.check
                                : leading,
                            size: design.icons.small,
                            color: foreground,
                          ),
                          SizedBox(width: design.spacing.sm),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: design.typography.label.copyWith(
                              color: foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoftifyChoiceGroup<T> extends StatelessWidget {
  const LoftifyChoiceGroup({
    super.key,
    required this.values,
    required this.labelBuilder,
    required this.selectedValue,
    required this.onSelected,
    this.enabled = true,
    this.spacing,
    this.runSpacing,
  });

  final List<T> values;
  final String Function(T value) labelBuilder;
  final T? selectedValue;
  final ValueChanged<T> onSelected;
  final bool enabled;
  final double? spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : design.grid.minimumCardWidth * 2;
        return Wrap(
          spacing: spacing ?? design.spacing.md,
          runSpacing: runSpacing ?? design.spacing.xs,
          children: [
            for (final value in values)
              LoftifyTag(
                label: labelBuilder(value),
                selected: value == selectedValue,
                enabled: enabled,
                maxWidth: maxWidth,
                onPressed: () => onSelected(value),
              ),
          ],
        );
      },
    );
  }
}

Color _contrastForeground(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : const Color(0xFF151815);
}
