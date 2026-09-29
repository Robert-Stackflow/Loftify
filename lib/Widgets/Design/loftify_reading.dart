import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';

/// Centers reading-oriented content without allowing long lines on wide
/// windows. The horizontal inset follows the responsive page grid while the
/// actual text measure remains capped independently from the surrounding UI.
class LoftifyReadingFrame extends StatelessWidget {
  const LoftifyReadingFrame({
    super.key,
    required this.child,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.applyHorizontalPadding = true,
    this.maximumContentWidth,
  });

  final Widget child;
  final double topPadding;
  final double bottomPadding;
  final bool applyHorizontalPadding;
  final double? maximumContentWidth;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final horizontalPadding = design.grid.pagePaddingFor(viewportWidth);
        final contentWidth =
            maximumContentWidth ?? design.grid.maximumReadingWidth;
        final frameWidth = contentWidth + horizontalPadding * 2;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            key: const ValueKey('loftify-reading-frame'),
            constraints: BoxConstraints(maxWidth: frameWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                applyHorizontalPadding ? horizontalPadding : 0,
                topPadding,
                applyHorizontalPadding ? horizontalPadding : 0,
                bottomPadding,
              ),
              child: SizedBox(
                key: const ValueKey('loftify-reading-content'),
                width: double.infinity,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
