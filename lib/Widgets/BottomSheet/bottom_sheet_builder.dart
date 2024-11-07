import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../Custom/floating_modal.dart';
import 'generic_context_menu_bottom_sheet.dart';

class BottomSheetBuilder {
  static void showContextMenu(BuildContext context, GenericContextMenu menu) {
    if (ResponsiveUtil.isLandscape()) {
      context.contextMenuOverlay.show(menu);
    } else {
      showBottomSheet(
          context, (context) => GenericContextMenuBottomSheet(menu: menu));
    }
  }

  static void showBottomSheet(
    BuildContext context,
    WidgetBuilder builder, {
    bool enableDrag = true,
    bool responsive = false,
    bool useWideLandscape = true,
    Color? backgroundColor,
    double? preferMinWidth,
    bool useVerticalMargin = false,
    ShapeBorder shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  }) {
    bool isLandScape = useWideLandscape
        ? ResponsiveUtil.isWideLandscape()
        : ResponsiveUtil.isWideLandscape();
    preferMinWidth ??= responsive && isLandScape ? 450 : null;
    if (responsive && isLandScape) {
      showDialog(
        context: context,
        builder: (context) {
          return FloatingModal(
            preferMinWidth: preferMinWidth,
            useWideLandscape: useWideLandscape,
            useVerticalMargin: useVerticalMargin,
            child: builder(context),
          );
        },
      );
    } else {
      showCustomModalBottomSheet(
        context: context,
        elevation: 0,
        enableDrag: enableDrag,
        backgroundColor: backgroundColor ?? Theme.of(context).canvasColor,
        shape: shape,
        builder: builder,
        containerWidget: (_, animation, child) => FloatingModal(
          preferMinWidth: preferMinWidth,
          useWideLandscape: useWideLandscape,
          child: child,
        ),
      );
    }
  }

  static void showListBottomSheet(
    BuildContext context,
    WidgetBuilder builder, {
    Color? backgroundColor,
    ShapeBorder shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
  }) {
    showCustomModalBottomSheet(
      context: context,
      elevation: 0,
      backgroundColor: backgroundColor ?? Theme.of(context).canvasColor,
      shape: shape,
      builder: builder,
      containerWidget: (_, animation, child) => child,
    );
  }
}
