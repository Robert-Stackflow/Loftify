import 'dart:math';

import 'package:flutter/material.dart';
import 'package:loftify/Utils/responsive_util.dart';

class FloatingModal extends StatelessWidget {
  final Widget child;
  final double? preferMinWidth;
  final bool useVerticalMargin;
  final bool useWideLandscape;

  const FloatingModal({
    super.key,
    required this.child,
    this.preferMinWidth,
    this.useWideLandscape = true,
    this.useVerticalMargin = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isLandScape = useWideLandscape
        ? ResponsiveUtil.isWideLandscape()
        : ResponsiveUtil.isLandscape();
    double width = MediaQuery.sizeOf(context).width - 60;
    double height = MediaQuery.sizeOf(context).height - 60;
    double preferWidth = min(width, preferMinWidth ?? 540);
    double preferHeight = min(width, 500);
    double preferHorizontalMargin = isLandScape
        ? width > preferWidth
            ? (width - preferWidth) / 2
            : 0
        : 0;
    double preferVerticalMargin =
        height > preferHeight ? (height - preferHeight) / 2 : 0;
    return Container(
      margin: EdgeInsets.only(
        left: preferHorizontalMargin,
        right: preferHorizontalMargin,
        top: useVerticalMargin
            ? preferVerticalMargin
            : ResponsiveUtil.isLandscape()
                ? 0
                : 100,
        bottom: useVerticalMargin ? preferVerticalMargin : 0,
      ),
      child: child,
    );
  }
}
