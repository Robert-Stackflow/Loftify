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

  for (final size in [const Size(280, 480), const Size(720, 360)]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        for (final nickname in [
          'Long creator name with several interests',
          '很长的创作者昵称与兴趣描述',
          '很長的創作者暱稱與興趣描述'
        ]) {
          testWidgets(
              'notification actions fit $size scale=$scale dark=$dark $nickname',
              (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            var profileTaps = 0;
            var postTaps = 0;
            await tester.pumpWidget(MaterialApp(
              theme: (dark
                      ? ChewieThemeColorData.defaultDarkThemes.first
                      : ChewieThemeColorData.defaultLightThemes.first)
                  .toThemeData(),
              home: Builder(builder: (context) {
                chewieProvider.setRootContext(context);
                return Scaffold(
                    body: MediaQuery(
                  data: MediaQueryData(
                      size: size, textScaler: TextScaler.linear(scale)),
                  child: SingleChildScrollView(
                      child: SystemNoticeMessageTile(
                    nickname: nickname,
                    message:
                        '$nickname recommended your illustrated story / 推荐了你的作品 / 推薦了你的作品',
                    timestamp: 1724918400000,
                    avatarUrl: '',
                    thumbnailUrl: '',
                    onTap: () => postTaps++,
                    onAvatarTap: () => profileTaps++,
                  )),
                ));
              }),
            ));
            final action = find.byKey(const Key('system-notice-avatar-action'));
            final semantics = tester.ensureSemantics();
            expect(
                tester.getSemantics(action),
                matchesSemantics(
                  label: nickname,
                  isButton: true,
                  hasTapAction: true,
                ));
            semantics.dispose();
            final actionRect = tester.getRect(action);
            expect(actionRect.width, greaterThanOrEqualTo(48));
            expect(actionRect.height, greaterThanOrEqualTo(48));
            // The newly available bottom-right edge opens the author, not the post.
            await tester.tapAt(actionRect.bottomRight - const Offset(1, 1));
            expect(profileTaps, 1);
            expect(postTaps, 0);
            final message = find.byKey(const Key('system-notice-message'));
            expect(
                tester.getRect(message).right, lessThanOrEqualTo(size.width));
            final thumbnail = find.byKey(const Key('system-notice-thumbnail'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(thumbnail);
            await tester.pumpAndSettle();
            expect(
                tester.getRect(thumbnail).right, lessThanOrEqualTo(size.width));
            await tester.tap(thumbnail);
            expect(postTaps, 1);
            expect(profileTaps, 1);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

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
