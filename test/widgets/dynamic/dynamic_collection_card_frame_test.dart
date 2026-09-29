import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Dynamic/dynamic_collection_card_frame.dart';

void main() {
  test('collection grids keep breathing room across phone and wide layouts',
      () {
    expect(
      DynamicCollectionGridLayout.paddingFor(390),
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
    expect(DynamicCollectionGridLayout.spacingFor(390), 10);
    expect(
      DynamicCollectionGridLayout.paddingFor(900),
      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
    expect(DynamicCollectionGridLayout.spacingFor(900), 12);
  });

  Widget buildFrame({
    required double width,
    required double textScale,
    required Widget child,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: DynamicCollectionCardFrame(
                key: const ValueKey('frame'),
                cover: const ColoredBox(color: Colors.teal),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses the 100px cover as the compact minimum height',
      (tester) async {
    await tester.pumpWidget(
      buildFrame(
        width: 560,
        textScale: 1,
        child: const Text('合集'),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('frame'))).height, 116);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grows for narrow layouts, long copy and large text',
      (tester) async {
    await tester.pumpWidget(
      buildFrame(
        width: 280,
        textScale: 2,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '很长很长的合集标题与更新状态',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 3),
            Text(
              '发布了很多图片\n发布了很多图片\n发布了很多图片',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text('继续阅读'),
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('frame'))).height,
      greaterThan(116),
    );
    expect(tester.takeException(), isNull);
  });
}
