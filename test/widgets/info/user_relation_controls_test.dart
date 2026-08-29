import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Design/loftify_controls.dart';
import 'package:loftify/Widgets/Item/loftify_item_builder.dart';

void main() {
  testWidgets('relation control keeps a full target with large text',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(280, 320),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Builder(
              builder: (context) => Align(
                alignment: Alignment.topLeft,
                child: LoftifyItemBuilder.buildFramedDoubleButton(
                  context: context,
                  isFollowed: false,
                  negtiveText: 'Follow this creator',
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(LoftifyButton)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('Follow this creator'));
    expect(taps, 1);
  });

  test('following cards and controls use responsive design components', () {
    final source = File(
      'lib/Widgets/Item/loftify_item_builder.dart',
    ).readAsStringSync();
    final cardStart =
        source.indexOf('static Widget buildFollowerOrFollowingItem');
    final cardEnd = source.indexOf('static Widget buildLikedButton', cardStart);
    final cardSource = source.substring(cardStart, cardEnd);
    expect(cardSource, contains('LayoutBuilder('));
    expect(cardSource, contains('LoftifyCard('));
    expect(cardSource, contains('constraints.maxWidth < 420'));

    final buttonStart = source.indexOf('static Widget buildFramedDoubleButton');
    final buttonEnd =
        source.indexOf('static buildUnLoginMainBody', buttonStart);
    final buttonSource = source.substring(buttonStart, buttonEnd);
    expect(buttonSource, contains('LoftifyButton('));
    expect(buttonSource, contains('LoftifyButtonSize.compact'));
    expect(buttonSource, isNot(contains('InkWell(')));
  });
}
