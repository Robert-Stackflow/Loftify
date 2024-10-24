import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../Resources/colors.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/constant.dart';
import '../../Utils/responsive_util.dart';
import './mouse_state_builder.dart';

typedef WindowButtonIconBuilder = Widget Function(
    WindowButtonContext buttonContext);
typedef WindowButtonBuilder = Widget Function(
    WindowButtonContext buttonContext, Widget icon);

class WindowButtonContext {
  BuildContext context;
  MouseState mouseState;
  Color? backgroundColor;
  Color iconColor;

  WindowButtonContext({
    required this.context,
    required this.mouseState,
    this.backgroundColor,
    required this.iconColor,
  });
}

class WindowButtonColors {
  late Color normal;
  late Color selected;
  late Color mouseOver;
  late Color mouseDown;
  late Color iconNormal;
  late Color iconSelected;
  late Color iconMouseOver;
  late Color iconMouseDown;

  WindowButtonColors({
    Color? normal,
    Color? selected,
    Color? mouseOver,
    Color? mouseDown,
    Color? iconNormal,
    Color? iconSelected,
    Color? iconMouseOver,
    Color? iconMouseDown,
  }) {
    this.normal = normal ?? _defaultButtonColors.normal;
    this.selected = selected ?? _defaultButtonColors.selected;
    this.mouseOver = mouseOver ?? _defaultButtonColors.mouseOver;
    this.mouseDown = mouseDown ?? _defaultButtonColors.mouseDown;
    this.iconNormal = iconNormal ?? _defaultButtonColors.iconNormal;
    this.iconSelected = iconSelected ?? _defaultButtonColors.iconSelected;
    this.iconMouseOver = iconMouseOver ?? _defaultButtonColors.iconMouseOver;
    this.iconMouseDown = iconMouseDown ?? _defaultButtonColors.iconMouseDown;
  }
}

final _defaultButtonColors = WindowButtonColors(
  normal: Colors.transparent,
  iconNormal: const Color(0xFF805306),
  mouseOver: const Color(0xFF404040),
  mouseDown: const Color(0xFF202020),
  iconMouseOver: const Color(0xFFFFFFFF),
  iconMouseDown: const Color(0xFFF0F0F0),
  selected: const Color(0xFF202020),
  iconSelected: const Color(0xFF805306),
);

class WindowButton extends StatelessWidget {
  final WindowButtonBuilder? builder;
  final WindowButtonIconBuilder? iconBuilder;
  late final WindowButtonColors colors;
  final bool animate;
  final EdgeInsets? padding;
  final VoidCallback? onPressed;
  final BorderRadius? borderRadius;
  final double rotateAngle;
  final bool selected;
  final Size buttonSize;

  WindowButton({
    super.key,
    WindowButtonColors? colors,
    this.builder,
    @required this.iconBuilder,
    this.padding,
    this.selected = false,
    this.onPressed,
    this.buttonSize = const Size(36, 36),
    this.borderRadius,
    this.animate = true,
    this.rotateAngle = 0,
  }) {
    this.colors = colors ?? _defaultButtonColors;
  }

  Color getBackgroundColor(MouseState mouseState) {
    if (mouseState.isMouseDown) return colors.mouseDown;
    if (mouseState.isMouseOver) return colors.mouseOver;
    if (selected) return colors.selected;
    return colors.normal;
  }

  Color getIconColor(MouseState mouseState) {
    if (selected) return colors.iconSelected;
    if (mouseState.isMouseDown) return colors.iconMouseDown;
    if (mouseState.isMouseOver) return colors.iconMouseOver;
    return colors.iconNormal;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return emptyWidget;
    } else {
      if (Platform.isMacOS) {
        return emptyWidget;
      }
    }
    return MouseStateBuilder(
      builder: (context, mouseState) {
        WindowButtonContext buttonContext = WindowButtonContext(
            mouseState: mouseState,
            context: context,
            backgroundColor: getBackgroundColor(mouseState),
            iconColor: getIconColor(mouseState));

        var icon =
            (iconBuilder != null) ? iconBuilder!(buttonContext) : emptyWidget;
        double borderSize = 0;
        double defaultPadding = (30 - borderSize) / 3 - (borderSize / 2);
        var fadeOutColor =
            getBackgroundColor(MouseState()..isMouseOver = true).withOpacity(0);
        var padding = this.padding ?? EdgeInsets.all(defaultPadding);
        var animationMs =
            mouseState.isMouseOver ? (animate ? 50 : 0) : (animate ? 100 : 0);
        Widget iconWithPadding = Padding(
          padding: padding,
          child: Transform.rotate(
            angle: rotateAngle,
            child: icon,
          ),
        );
        iconWithPadding = AnimatedContainer(
            curve: Curves.easeOut,
            duration: Duration(milliseconds: animationMs),
            color: buttonContext.backgroundColor ?? fadeOutColor,
            child: iconWithPadding);
        var button =
            (builder != null) ? builder!(buttonContext, icon) : iconWithPadding;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(0),
            child: SizedBox(
              width: buttonSize.width,
              height: max(buttonSize.height, buttonSize.width),
              child: button,
            ),
          ),
        );
      },
      onPressed: () {
        if (onPressed != null) onPressed!();
      },
    );
  }
}

class ToolButton extends WindowButton {
  ToolButton({
    super.key,
    required BuildContext context,
    super.selected,
    WindowButtonColors? colors,
    required VoidCallback onTap,
    bool? animate,
    EdgeInsets? padding,
    WindowButtonIconBuilder? iconBuilder,
    IconData? icon,
    IconData? selectedIcon,
    double iconSize = 22,
    Size? buttonSize,
    double? rotateAngle,
  }) : super(
          animate: animate ?? true,
          buttonSize: buttonSize ?? const Size(38, 38),
          padding: padding ?? EdgeInsets.zero,
          colors: colors ?? MyColors.getNormalButtonColors(context),
          borderRadius: BorderRadius.circular(8),
          iconBuilder: iconBuilder ??
              (buttonContext) => Transform.rotate(
                    angle: rotateAngle ?? 0,
                    child: Icon(
                      selected ? selectedIcon ?? icon : icon,
                      color: buttonContext.iconColor,
                      size: iconSize,
                    ),
                  ),
          onPressed: onTap,
        );
}

class StayOnTopWindowButton extends WindowButton {
  StayOnTopWindowButton({
    super.key,
    super.colors,
    super.onPressed,
    super.borderRadius,
    required BuildContext context,
    bool? animate,
    double? rotateAngle,
  }) : super(
          animate: animate ?? false,
          padding: EdgeInsets.zero,
          rotateAngle: rotateAngle ?? 0,
          iconBuilder: (buttonContext) => Container(
            padding: const EdgeInsets.all(8),
            child: AssetUtil.loadDouble(
              context,
              AssetUtil.pinLightIcon,
              AssetUtil.pinDarkIcon,
              fit: BoxFit.cover,
            ),
          ),
        );
}

class MinimizeWindowButton extends WindowButton {
  MinimizeWindowButton({
    super.key,
    super.colors,
    VoidCallback? onPressed,
    super.borderRadius,
    bool? animate,
  }) : super(
            animate: animate ?? false,
            padding: EdgeInsets.zero,
            iconBuilder: (buttonContext) => Icon(Icons.horizontal_rule_rounded,
                color: buttonContext.iconColor),
            onPressed: onPressed ?? () => windowManager.minimize());
}

class MaximizeWindowButton extends WindowButton {
  MaximizeWindowButton({
    super.key,
    super.colors,
    VoidCallback? onPressed,
    super.borderRadius,
    bool? animate,
  }) : super(
            padding: EdgeInsets.zero,
            animate: animate ?? false,
            iconBuilder: (buttonContext) => Icon(
                Icons.check_box_outline_blank_rounded,
                size: 19,
                color: buttonContext.iconColor),
            onPressed: onPressed ?? () => ResponsiveUtil.maximizeOrRestore());
}

class RestoreWindowButton extends WindowButton {
  RestoreWindowButton({
    super.key,
    super.colors,
    VoidCallback? onPressed,
    super.borderRadius,
    bool? animate,
  }) : super(
            padding: EdgeInsets.zero,
            animate: animate ?? false,
            iconBuilder: (buttonContext) => Icon(Icons.fullscreen_exit_rounded,
                color: buttonContext.iconColor),
            onPressed: onPressed ?? () => ResponsiveUtil.maximizeOrRestore());
}

final _defaultCloseButtonColors = WindowButtonColors(
    mouseOver: const Color(0xFFD32F2F),
    mouseDown: const Color(0xFFB71C1C),
    iconNormal: const Color(0xFF805306),
    iconMouseOver: const Color(0xFFFFFFFF));

class CloseWindowButton extends WindowButton {
  CloseWindowButton({
    super.key,
    WindowButtonColors? colors,
    VoidCallback? onPressed,
    super.borderRadius,
    bool? animate,
  }) : super(
            colors: colors ?? _defaultCloseButtonColors,
            padding: EdgeInsets.zero,
            animate: animate ?? false,
            iconBuilder: (buttonContext) => Icon(Icons.close_rounded,
                size: 24, color: buttonContext.iconColor),
            onPressed: onPressed ?? () => windowManager.close());
}
