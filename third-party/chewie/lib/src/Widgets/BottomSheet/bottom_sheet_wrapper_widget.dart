import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class BottomSheetWrapperWidget extends StatelessWidget {
  final Widget child;
  final double? preferMinWidth;
  final bool useVerticalMargin;

  const BottomSheetWrapperWidget({
    super.key,
    required this.child,
    this.preferMinWidth,
    this.useVerticalMargin = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isLandScape = ResponsiveUtil.isWideDevice();
    double width = MediaQuery.sizeOf(context).width - 60;
    double height = MediaQuery.sizeOf(context).height - 60;
    double preferWidth = min(width, preferMinWidth ?? 540);
    double preferHeight = min(height, 500);
    final panel = ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: ChewieDimens.defaultRadius,
        bottom: useVerticalMargin || isLandScape
            ? ChewieDimens.defaultRadius
            : Radius.zero,
      ),
      child: ColoredBox(
        color: ChewieTheme.scaffoldBackgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: child),
            if (!isLandScape &&
                MediaQuery.of(context).viewInsets.bottom <= 0 &&
                MediaQuery.of(context).viewPadding.bottom > 0)
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );

    if (useVerticalMargin) {
      return BackdropFilter(
        filter: ResponsiveUtil.isDesktop()
            ? ImageFilter.blur(sigmaX: 2, sigmaY: 2)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: preferWidth,
              maxWidth: preferWidth,
              maxHeight: preferHeight,
            ),
            child: panel,
          ),
        ),
      );
    }

    double preferHorizontalMargin = isLandScape
        ? width > preferWidth
            ? (width - preferWidth) / 2
            : 0
        : 0;
    return BackdropFilter(
      filter: ResponsiveUtil.isDesktop()
          ? ImageFilter.blur(sigmaX: 2, sigmaY: 2)
          : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
      child: Container(
        margin: EdgeInsets.only(
          left: preferHorizontalMargin,
          right: preferHorizontalMargin,
          top: ResponsiveUtil.isLandscapeLayout() ? 0 : 100,
        ),
        child: panel,
      ),
    );
  }
}
