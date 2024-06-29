import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class BottomSheetBuilder {
  static void showListBottomSheet(
    BuildContext context,
    WidgetBuilder builder, {
    Color? backgroundColor,
    ShapeBorder shape = const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
  }) {
    showMaterialModalBottomSheet(
      context: context,
      elevation: 0,
      backgroundColor: backgroundColor ?? Theme.of(context).canvasColor,
      shape: shape,
      builder: builder,
    );
  }
}
