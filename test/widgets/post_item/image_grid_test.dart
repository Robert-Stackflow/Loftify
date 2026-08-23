import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/PostItem/image_grid.dart';

void main() {
  Widget buildGrid(
    int count, {
    List<double>? ratios,
    void Function(int index, BorderRadius radius)? onBuildItem,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            child: ImageGrid(
              itemCount: count,
              ratios: ratios ?? List<double>.filled(count, 1),
              itemBuilder: (context, index, radius) {
                onBuildItem?.call(index, radius);
                return ClipRRect(
                  key: ValueKey('image-$index'),
                  borderRadius: radius,
                  child: ColoredBox(
                    color: Colors.green.shade100,
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders and updates layouts for one through nine images',
      (tester) async {
    for (var count = 1; count <= 9; count++) {
      await tester.pumpWidget(buildGrid(count));
      await tester.pump();

      expect(tester.takeException(), isNull, reason: '$count image layout');
      for (var index = 0; index < count; index++) {
        expect(find.byKey(ValueKey('image-$index')), findsOneWidget);
      }
    }
  });

  testWidgets('falls back safely for missing and invalid image ratios',
      (tester) async {
    await tester.pumpWidget(
      buildGrid(
        9,
        ratios: const [double.nan, 0, -1, double.infinity],
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    for (var index = 0; index < 9; index++) {
      expect(find.byKey(ValueKey('image-$index')), findsOneWidget);
    }
  });

  testWidgets('one through nine image layouts preserve every outer corner',
      (tester) async {
    for (var count = 1; count <= 9; count++) {
      final radii = <int, BorderRadius>{};
      await tester.pumpWidget(
        buildGrid(
          count,
          onBuildItem: (index, radius) => radii[index] = radius,
        ),
      );
      await tester.pump();

      expect(radii.length, count, reason: '$count image radii');
      expect(
        radii.values.where((radius) => radius.topLeft.x > 0),
        hasLength(1),
        reason: '$count image top-left corner',
      );
      expect(
        radii.values.where((radius) => radius.topRight.x > 0),
        hasLength(1),
        reason: '$count image top-right corner',
      );
      expect(
        radii.values.where((radius) => radius.bottomLeft.x > 0),
        hasLength(1),
        reason: '$count image bottom-left corner',
      );
      expect(
        radii.values.where((radius) => radius.bottomRight.x > 0),
        hasLength(1),
        reason: '$count image bottom-right corner',
      );

      final size = tester.getSize(find.byType(ImageGrid));
      expect(size.width, lessThanOrEqualTo(360));
      expect(size.height, greaterThan(0));
      expect(size.height.isFinite, isTrue);
      expect(tester.takeException(), isNull, reason: '$count image layout');
    }
  });

  testWidgets(
      'layout updates keep finite geometry when count and ratios change',
      (tester) async {
    await tester.pumpWidget(
      buildGrid(7, ratios: const [0.2, 4, 1, 1, 1, 1, 1]),
    );
    await tester.pump();
    final sevenImageSize = tester.getSize(find.byType(ImageGrid));

    await tester.pumpWidget(
      buildGrid(
        8,
        ratios: const [double.nan, 0, -1, double.infinity],
      ),
    );
    await tester.pump();
    final eightImageSize = tester.getSize(find.byType(ImageGrid));

    expect(sevenImageSize.width, eightImageSize.width);
    expect(sevenImageSize.height.isFinite, isTrue);
    expect(eightImageSize.height.isFinite, isTrue);
    expect(find.byKey(const ValueKey('image-7')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
