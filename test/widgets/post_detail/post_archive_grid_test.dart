import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/PostItem/loftify_post_archive_grid.dart';

void main() {
  testWidgets('archive grid reports the true cell after horizontal padding',
      (tester) async {
    final extents = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: LoftifyPostArchiveGrid(
              itemCount: 3,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              itemBuilder: (context, index, tileExtent) {
                extents.add(tileExtent);
                return ColoredBox(
                  key: ValueKey('archive-tile-$index'),
                  color: Colors.teal,
                );
              },
            ),
          ),
        ),
      ),
    );

    final expected = (320 - 24 - 12) / 3;
    expect(extents, isNotEmpty);
    expect(
        extents.every((extent) => (extent - expected).abs() < 0.001), isTrue);
    expect(
      tester.getSize(find.byKey(const ValueKey('archive-tile-0'))),
      Size.square(expected),
    );
    expect(tester.takeException(), isNull);
  });

  test('all archive page families use the shared real-width grid', () {
    for (final path in <String>[
      'lib/Widgets/BottomSheet/collection_bottom_sheet.dart',
      'lib/Screens/Info/post_screen.dart',
      'lib/Screens/Info/share_screen.dart',
      'lib/Screens/Post/grain_detail_screen.dart',
      'lib/Screens/Post/collection_detail_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('LoftifyPostArchiveGrid('), reason: path);
      expect(source, contains('wh: tileExtent'), reason: path);
      expect(source, isNot(contains('GridView.extent(')), reason: path);
      expect(source, isNot(contains('wh: 160')), reason: path);
    }
  });
}
