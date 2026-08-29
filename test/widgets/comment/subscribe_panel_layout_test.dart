import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/BottomSheet/subscribe_post_bottom_sheet.dart';

void main() {
  testWidgets('short large-text folder panel keeps every action reachable',
      (tester) async {
    var createTaps = 0;
    var confirmTaps = 0;
    await tester.pumpWidget(
      _host(
        size: const Size(320, 480),
        textScaler: const TextScaler.linear(2),
        child: LoftifySubscribePanelFrame(
          title: 'Select a favorite folder with a long title',
          createLabel: 'Create a new folder',
          onCreate: () => createTaps++,
          body: ListView(
            children: const [SizedBox(height: 600, child: Text('Folders'))],
          ),
          footer: LoftifyResponsivePanelActions(
            secondary: OutlinedButton(
              key: const ValueKey('cancel-folder'),
              onPressed: _noop,
              child: const Text('Cancel'),
            ),
            primary: FilledButton(
              key: const ValueKey('confirm-folder'),
              onPressed: () => confirmTaps++,
              child: const Text('Confirm selection'),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('loftify-panel-handle')), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm-folder')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Create a new folder'));
    await tester.tap(find.byKey(const ValueKey('confirm-folder')));
    expect(createTaps, 1);
    expect(confirmTaps, 1);
  });

  testWidgets('visible keyboard reduces folder panel height', (tester) async {
    await tester.pumpWidget(
      _host(
        size: const Size(360, 700),
        viewInsets: const EdgeInsets.only(bottom: 300),
        child: const LoftifySubscribePanelFrame(
          title: 'Folders',
          createLabel: 'New',
          onCreate: _noop,
          body: SizedBox.expand(),
          footer: SizedBox(height: 48),
        ),
      ),
    );

    final size = tester.getSize(
      find.byKey(const ValueKey('loftify-subscribe-panel')),
    );
    expect(size.height, closeTo((700 - 300) * 0.92, 0.01));
    expect(tester.takeException(), isNull);
  });

  test('live folder sheet no longer owns a custom panel shell', () {
    final source = File(
      'lib/Widgets/BottomSheet/subscribe_post_bottom_sheet.dart',
    ).readAsStringSync();
    expect(source, contains('LoftifyPanel('));
    expect(source, contains('LoftifyResponsivePanelActions('));
    expect(source, isNot(contains('RoundIconTextButton(')));
    expect(source, isNot(contains('MyDivider(')));
    expect(source, isNot(contains('Radius.circular(20)')));
  });
}

void _noop() {}

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
