import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

void main() {
  for (final height in <double>[48, 56]) {
    testWidgets('shared search hint is centered at height $height',
        (tester) async {
      const hint = '多个搜索词以空格隔开';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                key: const ValueKey('search-bar-host'),
                width: 360,
                height: height,
                child: Builder(
                  builder: (context) => ItemBuilder.buildSearchBar(
                    context: context,
                    hintText: hint,
                    onSubmitted: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final field = find.byType(TextField);
      final bar = find.byKey(const ValueKey('search-bar-host'));
      final placeholder = find.text(hint);
      expect(field, findsOneWidget);
      expect(placeholder, findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        (tester.getCenter(placeholder).dy - tester.getCenter(bar).dy).abs(),
        lessThan(2),
      );
    });
  }
}
