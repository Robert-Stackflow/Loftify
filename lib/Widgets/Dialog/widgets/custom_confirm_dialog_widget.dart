import 'package:flutter/material.dart';

import '../../../Utils/asset_util.dart';
import '../colors.dart';
import '../custom_dialog.dart';
import '../widgets/custom_dialog_button.dart';

class CustomConfirmDialogWidget extends StatelessWidget {
  final String? title;
  final String message;
  final String? imagePath;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onTapConfirm;
  final VoidCallback onTapCancel;
  final CustomDialogType customDialogType;
  final Color? color;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? buttonTextColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;

  final bool noImage;

  final Alignment align;

  const CustomConfirmDialogWidget({
    super.key,
    this.title,
    required this.message,
    required this.confirmButtonText,
    required this.cancelButtonText,
    required this.onTapConfirm,
    required this.onTapCancel,
    required this.customDialogType,
    this.color,
    this.backgroundColor,
    this.textColor = const Color(0xFF707070),
    this.buttonTextColor = Colors.white,
    this.imagePath,
    this.padding = const EdgeInsets.all(24),
    this.margin = const EdgeInsets.all(24),
    required this.noImage,
    this.borderRadius = 24,
    this.align = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Align(
      alignment: align,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 340,
          ),
          margin: margin ?? const EdgeInsets.all(24),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.canvasColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: title == null ? 20 : 0,
              ),
              if (!noImage)
                Image.asset(
                  imagePath ?? AssetUtil.confirmIcon,
                  width: 84,
                  height: 84,
                  color: imagePath != null
                      ? null
                      : CustomDialogColors.getBgColor(
                          context,
                          customDialogType,
                          color,
                        ),
                ),
              if (!noImage)
                const SizedBox(
                  height: 24,
                ),
              if (title != null)
                Text(
                  title ?? "",
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (title != null)
                const SizedBox(
                  height: 15,
                ),
              Text(
                message,
                style: TextStyle(
                  color: textColor,
                  height: 1.5,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: title == null ? 40 : 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomDialogButton(
                      onTap: onTapCancel,
                      text: cancelButtonText,
                      bgColor: CustomDialogColors.getBgColor(
                        context,
                        customDialogType,
                        color ?? Theme.of(context).primaryColor,
                      ),
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(
                    width: 24,
                  ),
                  Expanded(
                    flex: 1,
                    child: CustomDialogButton(
                      buttonTextColor: buttonTextColor ?? Colors.white,
                      onTap: onTapConfirm,
                      text: confirmButtonText,
                      bgColor: CustomDialogColors.getBgColor(
                        context,
                        customDialogType,
                        color ?? Theme.of(context).primaryColor,
                      ),
                      isOutlined: false,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
