import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/BottomSheet/comment_bottom_sheet.dart';

void main() {
  testWidgets('short large-text panel keeps header stable and list scrollable',
      (tester) async {
    await tester.pumpWidget(
      _host(
        size: const Size(320, 300),
        textScaler: const TextScaler.linear(2),
        child: LoftifyCommentPanel(
          title: 'Latest comments with a long localized title',
          body: ListView.builder(
            key: const ValueKey('comment-list'),
            physics: const ClampingScrollPhysics(),
            itemCount: 12,
            itemBuilder: (context, index) => SizedBox(
              height: 64,
              child: Text('Comment $index'),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('loftify-panel-handle')), findsOneWidget);
    expect(find.textContaining('Latest comments'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Comment 11'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Comment 11'), findsOneWidget);
    expect(find.textContaining('Latest comments'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard inset reduces comment panel instead of hiding it',
      (tester) async {
    await tester.pumpWidget(
      _host(
        size: const Size(360, 640),
        viewInsets: const EdgeInsets.only(bottom: 280),
        child: const LoftifyCommentPanel(
          title: 'Latest comments',
          body: SizedBox.expand(),
        ),
      ),
    );

    final panel = tester.getSize(
      find.byKey(const ValueKey('loftify-comment-panel')),
    );
    expect(panel.height, closeTo((640 - 280) * 0.82, 0.01));
    expect(tester.takeException(), isNull);
  });

  test('live comment sheet uses the shared panel without a list header clone',
      () {
    final source = File(
      'lib/Widgets/BottomSheet/comment_bottom_sheet.dart',
    ).readAsStringSync();
    expect(source, contains('LoftifyCommentPanel('));
    expect(source, contains('LoftifyPanel('));
    expect(source, isNot(contains('SliverPersistentHeader(')));
    expect(source, isNot(contains('Radius.circular(16)')));
  });
}

Widget _host({
  required Size size,
  required Widget child,
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  return MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: textScaler,
          viewInsets: viewInsets,
        ),
        child: Align(alignment: Alignment.bottomCenter, child: child),
      ),
    ),
  );
}
