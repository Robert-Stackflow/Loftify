import 'dart:math';

import 'package:flutter/material.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

import '../../../Utils/route_util.dart';

GlobalKey<NavigatorState> dialogNavigatorKey = GlobalKey<NavigatorState>();

class DialogWrapperWidget extends StatelessWidget {
  final Widget child;
  final double? preferMinWidth;
  final double? preferMinHeight;
  final bool showClose;

  const DialogWrapperWidget({
    super.key,
    required this.child,
    this.preferMinWidth,
    this.preferMinHeight,
    this.showClose = true,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width - 60;
    double height = MediaQuery.sizeOf(context).height - 60;
    double preferWidth = min(width, preferMinWidth ?? 540);
    double preferHeight = min(width, preferMinHeight ?? 500);
    double preferHorizontalMargin =
        width > preferWidth ? (width - preferWidth) / 2 : 0;
    double preferVerticalMargin =
        height > preferHeight ? (height - preferHeight) / 2 : 0;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: preferHorizontalMargin, vertical: preferVerticalMargin),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Navigator(
                  key: dialogNavigatorKey,
                  onGenerateRoute: (settings) => RouteUtil.getFadeRoute(child),
                ),
                if (showClose)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: ItemBuilder.buildIconButton(
                        context: context,
                        icon: const Icon(Icons.close_rounded),
                        onTap: () {
                          if (dialogNavigatorKey.currentState!.canPop()) {
                            dialogNavigatorKey.currentState?.pop();
                          } else {
                            Navigator.pop(context);
                          }
                        }),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
