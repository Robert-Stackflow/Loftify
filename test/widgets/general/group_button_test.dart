import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/group_button',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('group button expands past its minimum width for long labels',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return Scaffold(
              body: SizedBox(
                width: 320,
                child: ChewieItemBuilder.buildGroupButtons(
                  buttons: const ['不限', '最近七天没有访问过'],
                ),
              ),
            );
          },
        ),
      ),
    );

    final longButton = find.ancestor(
      of: find.text('最近七天没有访问过'),
      matching: find.byType(RoundIconTextButton),
    );
    expect(longButton, findsOneWidget);
    expect(tester.getSize(longButton).width, greaterThan(80));
    expect(tester.takeException(), isNull);
  });
}
