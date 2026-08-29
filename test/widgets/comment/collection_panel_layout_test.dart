import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/BottomSheet/collection_bottom_sheet.dart';
import 'package:loftify/Widgets/PostItem/loftify_post_archive_grid.dart';

void main() {
  testWidgets('short large-text collection panel preserves one scroll viewport',
      (tester) async {
    await tester.pumpWidget(
      _host(
        size: const Size(320, 420),
        textScaler: const TextScaler.linear(2),
        child: LoftifyCollectionPanelFrame(
          body: ListView.builder(
            itemCount: 12,
            itemBuilder: (context, index) => SizedBox(
              height: 60,
              child: Text('Collection post $index'),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('loftify-panel-handle')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Collection post 11'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Collection post 11'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('collection grid keeps three true square columns on phones', () {
    final geometry = LoftifyArchiveGridGeometry.calculate(296);
    expect(geometry.columnCount, 3);
    expect(geometry.tileExtent, closeTo((296 - 12) / 3, 0.001));

    final wide = LoftifyArchiveGridGeometry.calculate(1000);
    expect(wide.columnCount, 6);
    expect(wide.tileExtent, closeTo((1000 - 30) / 6, 0.001));
  });

  test('live collection sheet uses semantic panel and real cell extent', () {
    final source = File(
      'lib/Widgets/BottomSheet/collection_bottom_sheet.dart',
    ).readAsStringSync();
    expect(source, contains('LoftifyCollectionPanelFrame('));
    expect(source, contains('LoftifyPanel('));
    expect(source, contains('LoftifyPostArchiveGrid('));
    expect(source, contains('wh: tileExtent'));
    expect(source, isNot(contains('GridView.extent(')));
    expect(source, isNot(contains('Radius.circular(20)')));
  });
}

Widget _host({
  required Size size,
  required Widget child,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: Align(alignment: Alignment.bottomCenter, child: child),
      ),
    ),
  );
}
