import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class BottomSheetBuilder {
  static Future showContextMenu(BuildContext context, FlutterContextMenu menu) {
    if (ResponsiveUtil.isDesktop()) {
      return menu.showAtMousePosition(context, chewieProvider.mousePosition);
    } else {
      return showBottomSheet(
          responsive: true,
          context,
          (context) => ContextMenuBottomSheet(menu: menu));
    }
  }

  static void showGenericContextMenu(BuildContext context, Widget menu) {
    context.genericContextMenuOverlay.show(menu);
  }

  static Future showBottomSheet(
    BuildContext context,
    WidgetBuilder builder, {
    bool enableDrag = true,
    bool responsive = false,
    Color? backgroundColor,
    double? preferMinWidth,
  }) {
    final navigatorContext = chewieProvider.navigatorContextOf(context);
    bool isLandScape = ResponsiveUtil.isWideDevice();
    preferMinWidth ??= responsive && isLandScape ? 450 : null;
    if (responsive && isLandScape) {
      return showGeneralDialog(
        context: navigatorContext,
        barrierDismissible: true,
        barrierColor: ChewieTheme.barrierColor,
        barrierLabel:
            MaterialLocalizations.of(navigatorContext).modalBarrierDismissLabel,
        transitionDuration: ChewieTheme.animationDuration,
        pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return DialogAnimation(
            animation: animation,
            child: BottomSheetWrapperWidget(
              preferMinWidth: preferMinWidth,
              useVerticalMargin: true,
              child: builder(context),
            ),
          );
        },
      );
    } else {
      return showCustomModalBottomSheet(
        context: navigatorContext,
        elevation: 0,
        enableDrag: enableDrag,
        barrierColor: ChewieTheme.barrierColor,
        duration: ChewieTheme.animationDuration,
        backgroundColor: backgroundColor ?? ChewieTheme.canvasColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: ChewieDimens.defaultRadius),
        ),
        builder: builder,
        containerWidget: (_, animation, child) => BottomSheetWrapperWidget(
          preferMinWidth: preferMinWidth,
          child: child,
        ),
      );
    }
  }

  static Future showListBottomSheet(
    BuildContext context,
    WidgetBuilder builder, {
    Color? backgroundColor,
    ShapeBorder shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: ChewieDimens.defaultRadius),
    ),
  }) {
    final navigatorContext = chewieProvider.navigatorContextOf(context);
    return showCustomModalBottomSheet(
      context: navigatorContext,
      elevation: 0,
      backgroundColor:
          backgroundColor ?? Theme.of(navigatorContext).canvasColor,
      shape: shape,
      builder: builder,
      containerWidget: (_, animation, child) =>
          BottomSheetWrapperWidget(child: child),
    );
  }
}
