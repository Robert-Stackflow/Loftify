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

  testWidgets('notification item reflows on narrow large-text screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return const Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: Size(280, 480),
                  textScaler: TextScaler.linear(2),
                ),
                child: SingleChildScrollView(
                  child: SystemNoticeMessageTile(
                    nickname: 'A very long creator name',
                    message:
                        'A very long creator name recommended your illustrated story',
                    timestamp: 1724918400000,
                    avatarUrl: '',
                    thumbnailUrl: '',
                    onTap: _noop,
                    onAvatarTap: _noop,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getRect(find.byKey(const Key('system-notice-message'))).right,
      lessThanOrEqualTo(280),
    );
    expect(
      tester.getRect(find.byKey(const Key('system-notice-thumbnail'))).right,
      lessThanOrEqualTo(280),
    );
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
