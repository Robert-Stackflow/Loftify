import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../Design/loftify_controls.dart';
import '../loftify_icons.dart';

/// 登录流程使用的一体式输入框。
///
/// 登录页原本将图标、输入区和操作区放在同一块背景中。通用 InputItem
/// 更适合设置表单，因此这里保留登录页的视觉和键盘交互语义。
class LoginInputItem extends StatefulWidget {
  const LoginInputItem({
    super.key,
    required this.controller,
    this.hint,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.leadingConfig,
    this.tailingConfig,
    this.autofillHints,
    this.backgroundColor,
  });

  final TextEditingController controller;
  final String? hint;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final InputItemLeadingTailingConfig? leadingConfig;
  final InputItemLeadingTailingConfig? tailingConfig;
  final Iterable<String>? autofillHints;
  final Color? backgroundColor;

  @override
  State<LoginInputItem> createState() => _LoginInputItemState();
}

class _LoginInputItemState extends State<LoginInputItem> {
  late bool _obscurePassword;

  bool get _isPassword =>
      widget.tailingConfig?.type == InputItemLeadingTailingType.password;

  @override
  void initState() {
    super.initState();
    _obscurePassword = _isPassword;
  }

  @override
  void didUpdateWidget(covariant LoginInputItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasPassword =
        oldWidget.tailingConfig?.type == InputItemLeadingTailingType.password;
    if (!wasPassword && _isPassword) {
      _obscurePassword = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final leading = _buildAccessory(widget.leadingConfig, isTrailing: false);
    final tailing = _buildAccessory(widget.tailingConfig, isTrailing: true);
    return Padding(
      padding: EdgeInsets.only(top: context.design.spacing.sectionTop),
      child: LoftifyTextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        obscureText: _isPassword && _obscurePassword,
        hintText: widget.hint,
        prefix: leading,
        suffix: tailing,
        backgroundColor: widget.backgroundColor,
        contextMenuBuilder: (contextMenuContext, details) =>
            ChewieItemBuilder.editTextContextMenuBuilder(
          contextMenuContext,
          details,
          context: context,
        ),
      ),
    );
  }

  Widget? _buildAccessory(
    InputItemLeadingTailingConfig? config, {
    required bool isTrailing,
  }) {
    if (config == null || !config.show) return null;
    final iconColor = Theme.of(context).iconTheme.color;
    Widget? child;
    VoidCallback? defaultAction;
    switch (config.type) {
      case InputItemLeadingTailingType.none:
        return null;
      case InputItemLeadingTailingType.clear:
        child = ChewieIcon(
          LoftifyIcons.clear,
          color: iconColor?.withAlpha(120),
        );
        defaultAction = widget.controller.clear;
        break;
      case InputItemLeadingTailingType.password:
        child = ChewieIcon(
          _obscurePassword ? LoftifyIcons.visible : LoftifyIcons.hidden,
          color: iconColor?.withAlpha(120),
        );
        defaultAction = () {
          setState(() => _obscurePassword = !_obscurePassword);
        };
        break;
      case InputItemLeadingTailingType.icon:
        if (config.icon == null) return null;
        child = ChewieIcon(config.icon!, color: iconColor);
        break;
      case InputItemLeadingTailingType.text:
        if (config.text == null) return null;
        child = Text(
          config.text!,
          style: Theme.of(context).textTheme.titleSmall?.apply(
                color: config.enable
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.labelSmall?.color,
                fontWeightDelta: 2,
              ),
        );
        break;
      case InputItemLeadingTailingType.widget:
        child = config.widget;
        break;
      default:
        if (config.icon == null) return null;
        child = ChewieIcon(config.icon!, color: iconColor);
    }
    if (child == null) return null;
    if (!isTrailing) return child;
    return Semantics(
      button: config.enable,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: config.enable
            ? () {
                config.onTap?.call();
                defaultAction?.call();
              }
            : null,
        child: MouseRegion(
          cursor: config.enable
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: SizedBox.square(
            dimension: context.design.icons.minimumTapTarget,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
