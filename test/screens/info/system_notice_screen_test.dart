import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/system_notice_screen.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/system_notice_screen',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('notification placeholder fills and remains scrollable', (
    tester,
  ) async {
    final previousBuilder = chewieProvider.stateWidgetBuilder;
    chewieProvider.stateWidgetBuilder = LoftifyStateView.fromChewie;
    addTearDown(() {
      chewieProvider.stateWidgetBuilder = previousBuilder;
    });
    await tester.binding.setSurfaceSize(const Size(390, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return const Scaffold(
              body: SystemNoticeTabPlaceholder(text: 'No notifications'),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final scrollView = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
    expect(tester.getSize(find.byType(CustomScrollView)).height, 568);
    expect(find.text('No notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
