import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/tooltip_lifecycle',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('tooltips survive resize, deactivation and recreation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var showTooltips = true;
    late StateSetter setHostState;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setHostState = setState;
                  return showTooltips
                      ? const Row(
                          children: [
                            MyTooltip(message: 'First', child: Text('first')),
                            MyTooltip(
                              message: 'Second',
                              child: Text('second'),
                            ),
                          ],
                        )
                      : const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.longPress(find.text('first'));
    await tester.pump(const Duration(milliseconds: 50));
    setHostState(() => showTooltips = false);
    await tester.pump();
    await tester.tapAt(const Offset(20, 20));
    await tester.binding.setSurfaceSize(const Size(800, 400));
    await tester.pump();

    setHostState(() => showTooltips = true);
    await tester.pump();
    await tester.longPress(find.text('second'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
  });
}
