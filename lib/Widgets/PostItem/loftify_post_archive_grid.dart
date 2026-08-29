import 'dart:math';

import 'package:flutter/material.dart';

typedef LoftifyArchiveGridItemBuilder = Widget Function(
  BuildContext context,
  int index,
  double tileExtent,
);

/// A square archive grid whose media extent always matches the real cell.
///
/// Phone layouts retain the product's familiar three-column archive. Wider
/// viewports add columns around a 160 px target instead of stretching covers.
class LoftifyPostArchiveGrid extends StatelessWidget {
  const LoftifyPostArchiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.only(top: 12),
    this.spacing = 6,
  });

  final int itemCount;
  final LoftifyArchiveGridItemBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding = padding.resolve(Directionality.of(context));
        final contentWidth = max(
          1.0,
          constraints.maxWidth - resolvedPadding.horizontal,
        );
        final geometry = LoftifyArchiveGridGeometry.calculate(
          contentWidth,
          spacing: spacing,
        );
        return GridView.builder(
          padding: padding,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: geometry.columnCount,
            mainAxisSpacing: geometry.spacing,
            crossAxisSpacing: geometry.spacing,
          ),
          itemBuilder: (context, index) => itemBuilder(
            context,
            index,
            geometry.tileExtent,
          ),
        );
      },
    );
  }
}

@immutable
class LoftifyArchiveGridGeometry {
  const LoftifyArchiveGridGeometry._({
    required this.columnCount,
    required this.tileExtent,
    required this.spacing,
  });

  factory LoftifyArchiveGridGeometry.calculate(
    double contentWidth, {
    double spacing = 6,
  }) {
    final safeWidth = contentWidth.isFinite
        ? contentWidth.clamp(1.0, double.infinity).toDouble()
        : 1.0;
    final columns =
        safeWidth < 600 ? 3 : (safeWidth / 160).floor().clamp(3, 8).toInt();
    return LoftifyArchiveGridGeometry._(
      columnCount: columns,
      spacing: spacing,
      tileExtent: (safeWidth - spacing * (columns - 1)) / columns,
    );
  }

  final int columnCount;
  final double tileExtent;
  final double spacing;
}
