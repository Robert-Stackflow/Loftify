import 'package:flutter/material.dart';

import '../Design/loftify_surfaces.dart';

/// Page-level rhythm shared by subscribed and suggested collection grids.
abstract final class DynamicCollectionGridLayout {
  static EdgeInsets paddingFor(double width) => EdgeInsets.symmetric(
        horizontal: width < 600 ? 12 : 16,
        vertical: 6,
      );

  static double spacingFor(double width) => width < 600 ? 10 : 12;
}

/// Shared responsive frame for collection cards in the dynamic feed.
///
/// The card deliberately has no fixed height: translated copy, large text and
/// badges may make the information column taller than the cover. The row then
/// grows with its content instead of clipping or overflowing at the bottom.
class DynamicCollectionCardFrame extends StatelessWidget {
  const DynamicCollectionCardFrame({
    super.key,
    required this.cover,
    required this.child,
    this.onTap,
    this.coverSize = 100,
    this.gap = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final Widget cover;
  final Widget child;
  final VoidCallback? onTap;
  final double coverSize;
  final double gap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LoftifyCard(
      onTap: onTap,
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: coverSize),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: coverSize,
              child: cover,
            ),
            SizedBox(width: gap),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
