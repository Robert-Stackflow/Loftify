import 'package:flutter/material.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:loftify/Widgets/General/Animation/animated_fade.dart';

import 'custom_dialog.dart';

class DialogBuilder {
  static showConfirmDialog(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
    required String confirmButtonText,
    required String cancelButtonText,
    required VoidCallback onTapConfirm,
    required VoidCallback onTapCancel,
    required CustomDialogType customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
    bool responsive = true,
  }) {
    if (responsive && ResponsiveUtil.isLandscape()) {
      CustomConfirmDialog.show(
        context,
        message: message,
        imagePath: imagePath,
        title: title,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        noImage: noImage,
        align: Alignment.center,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
        onTapConfirm: onTapConfirm,
        onTapCancel: onTapCancel,
        customDialogType: customDialogType,
      );
    } else {
      CustomConfirmDialog.showAnimatedFromBottom(
        context,
        message: message,
        imagePath: imagePath,
        title: title,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        noImage: noImage,
        align: Alignment.bottomCenter,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
        onTapConfirm: onTapConfirm,
        onTapCancel: onTapCancel,
        customDialogType: customDialogType,
      );
    }
  }

  static showInfoDialog(
    BuildContext context, {
    String? title,
    String? message,
    Widget? messageChild,
    String? imagePath,
    required String buttonText,
    required VoidCallback onTapDismiss,
    required CustomDialogType customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
    bool responsive = true,
  }) {
    if (responsive && ResponsiveUtil.isLandscape()) {
      CustomInfoDialog.show(
        context,
        buttonText: buttonText,
        message: message,
        messageChild: messageChild,
        imagePath: imagePath,
        title: title,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        noImage: noImage,
        align: Alignment.center,
        customDialogType: customDialogType,
        onTapDismiss: onTapDismiss,
      );
    } else {
      CustomInfoDialog.showAnimatedFromBottom(
        context,
        buttonText: buttonText,
        message: message,
        messageChild: messageChild,
        imagePath: imagePath,
        title: title,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        noImage: noImage,
        align: Alignment.bottomCenter,
        customDialogType: customDialogType,
        onTapDismiss: onTapDismiss,
      );
    }
  }

  static showPageDialog(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
    bool showClose = true,
  }) {
    showGeneralDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedFade(
          animation: animation,
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) =>
          DialogWrapperWidget(showClose: showClose, child: child),
    );
  }
}
