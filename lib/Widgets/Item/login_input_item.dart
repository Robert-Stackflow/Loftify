import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

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
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              autofillHints: widget.autofillHints,
              obscureText: _isPassword && _obscurePassword,
              enableSuggestions: !_isPassword,
              autocorrect: !_isPassword,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.hint,
                contentPadding: EdgeInsets.only(
                  top: leading != null ? 13 : 0,
                  left: leading == null ? 10 : 0,
                ),
                hintStyle: Theme.of(context).textTheme.titleSmall,
                prefixIcon: leading,
              ),
              contextMenuBuilder: (contextMenuContext, details) =>
                  ChewieItemBuilder.editTextContextMenuBuilder(
                contextMenuContext,
                details,
                context: context,
              ),
            ),
          ),
          if (tailing != null) tailing,
        ],
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
        child = Icon(
          Icons.clear_rounded,
          color: iconColor?.withAlpha(120),
        );
        defaultAction = widget.controller.clear;
        break;
      case InputItemLeadingTailingType.password:
        child = Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: iconColor?.withAlpha(120),
        );
        defaultAction = () {
          setState(() => _obscurePassword = !_obscurePassword);
        };
        break;
      case InputItemLeadingTailingType.icon:
        if (config.icon == null) return null;
        child = Icon(config.icon, color: iconColor);
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
        child = Icon(config.icon, color: iconColor);
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: child,
          ),
        ),
      ),
    );
  }
}
