import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Screens/Post/video_detail_screen.dart';
import 'package:loftify/Screens/Post/video_list_controller.dart';
import 'package:loftify/Widgets/loftify_icons.dart';
import 'package:loftify/l10n/l10n.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVideoPlayerPlatform platform;

  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/video_list_controller',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  setUp(() {
    platform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = platform;
  });

  CustomVideoController createPlayer([String suffix = 'video']) {
    return CustomVideoController(
      builder: () => VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/$suffix.mp4'),
      ),
    );
  }

  test('pause before initialization does not allocate a native player',
      () async {
    final player = createPlayer();

    await player.pause(showPauseIcon: true);

    expect(platform.createCount, 0);
    expect(player.loadState, VideoLoadState.idle);
    expect(player.controllerOrNull, isNull);
    await player.close();
  });

  test('failed initialization releases resources and retry can autoplay',
      () async {
    platform.failNextInitialization = true;
    final player = createPlayer();

    await player.init();

    expect(player.loadState, VideoLoadState.failed);
    expect(player.controllerOrNull, isNull);
    expect(platform.disposedIds, contains(1));

    await player.retry(autoplay: true);

    expect(player.loadState, VideoLoadState.ready);
    expect(player.prepared, isTrue);
    expect(player.isPlaying, isTrue);
    expect(platform.playedIds, contains(2));
    await player.close();
    expect(platform.disposedIds, contains(2));
  });

  test('released controller can initialize a fresh native player', () async {
    final player = createPlayer();
    await player.init();
    final firstController = player.controllerOrNull;

    await player.release();
    await player.init();

    expect(platform.createCount, 2);
    expect(player.controllerOrNull, isNot(same(firstController)));
    expect(player.loadState, VideoLoadState.ready);
    await player.close();
  });

  test('player keeps looping and playback speed preferences across reloads',
      () async {
    final player = CustomVideoController(
      looping: false,
      playbackSpeed: 1.5,
      builder: () => VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/video.mp4'),
      ),
    );

    await player.init();
    expect(platform.loopingValues.last, isFalse);
    expect(player.controllerOrNull!.value.playbackSpeed, 1.5);
    await player.play();
    expect(platform.playbackSpeeds.last, 1.5);

    await player.setLooping(true);
    await player.setPlaybackSpeed(2);
    expect(platform.loopingValues.last, isTrue);
    expect(platform.playbackSpeeds.last, 2);

    await player.release();
    await player.init();
    expect(platform.loopingValues.last, isTrue);
    expect(player.controllerOrNull!.value.playbackSpeed, 2);
    await player.play();
    expect(platform.playbackSpeeds.last, 2);
    await player.close();
  });

  test('video list allows only the selected player to keep playing', () async {
    final first = createPlayer('first');
    final second = createPlayer('second');
    final list = VideoListController(preloadCount: 1);

    await list.init(
      initialList: [first, second],
      videoProvider: (_, __) async => const [],
    );
    await _waitUntil(() => second.prepared);
    expect(first.isPlaying, isTrue);
    expect(second.prepared, isTrue);
    expect(second.isPlaying, isFalse);

    await list.loadIndex(1);

    expect(first.isPlaying, isFalse);
    expect(second.isPlaying, isTrue);
    expect(list.currentPlayerOrNull, same(second));
    list.dispose();
    await Future<void>.delayed(Duration.zero);
  });

  testWidgets('long press expands the immersive scrubber and seeks smoothly',
      (tester) async {
    final player = createPlayer();
    await player.play();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 400,
              child: ImmersiveVideoProgressBar(
                player: player,
                canResume: () => true,
                semanticLabel: 'Video',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final progress = find.byType(ImmersiveVideoProgressBar);
    final playedTrack = find.byWidgetPredicate(
      (widget) => widget is ColoredBox && widget.color == Colors.white,
    );
    expect(tester.getSize(playedTrack).height, 3);
    final gesture = await tester.startGesture(tester.getCenter(progress));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pump();

    expect(player.isPlaying, isFalse);
    expect(find.text('0:15 / 0:30'), findsOneWidget);
    expect(tester.getSize(playedTrack), const Size(200, 7));

    await gesture.moveBy(const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 60));
    expect(
        platform.soughtPositions.last,
        greaterThan(
          const Duration(seconds: 20),
        ));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(player.isPlaying, isTrue);
    expect(find.textContaining(' / '), findsNothing);

    unawaited(player.pause());
    await tester.pump(const Duration(milliseconds: 100));
    expect(player.isPlaying, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('screen-edge long press temporarily accelerates playback',
      (tester) async {
    final player = createPlayer();
    await player.play();
    var menuOpens = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: VideoLongPressGesture(
            player: player,
            onOpenMenu: () => menuOpens++,
            child: const ColoredBox(color: Colors.black),
          ),
        ),
      ),
    );

    final edgeGesture = await tester.startGesture(const Offset(12, 240));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    expect(platform.playbackSpeeds.last, 2);
    expect(find.text('2x'), findsOneWidget);

    await edgeGesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(platform.playbackSpeeds.last, 1);
    expect(find.text('2x'), findsNothing);

    expect(menuOpens, 0);
    unawaited(player.pause());
    await tester.pump(const Duration(milliseconds: 100));
    expect(player.isPlaying, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('danmaku lanes do not overlap and pause with the video',
      (tester) async {
    final player = createPlayer();
    await player.play();
    final messages = List.generate(
      8,
      (index) => 'Long danmaku message $index that fills its lane safely',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 320,
            child: ColoredBox(
              color: Colors.black,
              child: DanmakuOverlay(messages: messages, player: player),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 4100));

    final firstRect = tester.getRect(find.byKey(const ValueKey('danmaku-0')));
    final nextRect = tester.getRect(find.byKey(const ValueKey('danmaku-4')));
    expect(firstRect.right, lessThan(nextRect.left));

    final beforePause = tester.getTopLeft(
      find.byKey(const ValueKey('danmaku-4')),
    );
    await player.pause();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final afterPause = tester.getTopLeft(
      find.byKey(const ValueKey('danmaku-4')),
    );
    expect(afterPause.dx, closeTo(beforePause.dx, 0.01));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('danmaku travel is independent of 60, 90 and 120Hz cadence',
      (tester) async {
    Future<double> measureAt(int refreshRate) async {
      final player = createPlayer();
      await player.play();
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey<int>(refreshRate),
          home: Center(
            child: SizedBox(
              width: 400,
              height: 320,
              child: ColoredBox(
                color: Colors.black,
                child: DanmakuOverlay(
                  messages: const ['Cadence-independent danmaku'],
                  player: player,
                ),
              ),
            ),
          ),
        ),
      );
      final frame = Duration(
        microseconds: (Duration.microsecondsPerSecond / refreshRate).round(),
      );
      var remaining = const Duration(seconds: 2);
      while (remaining > Duration.zero) {
        final step = remaining < frame ? remaining : frame;
        await tester.pump(step);
        remaining -= step;
      }
      final left = tester
          .getTopLeft(
            find.byKey(const ValueKey('danmaku-0')),
          )
          .dx;
      unawaited(player.pause());
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      return left;
    }

    final left60 = await measureAt(60);
    final left90 = await measureAt(90);
    final left120 = await measureAt(120);

    expect(left60, closeTo(left90, 0.25));
    expect(left90, closeTo(left120, 0.25));
  });

  testWidgets('followed video author does not show an avatar status badge',
      (tester) async {
    final author = SimpleBlogInfo(
      bigAvaImg: '',
      blogId: 1,
      blogName: 'author',
      blogNickName: 'Author',
      extraBits: 0,
    );

    Widget buildButtons({required bool following, int likeCount = 0}) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: VideoListButtonColumn(
            blogInfo: author,
            likeCount: likeCount,
            shareCount: 0,
            commentCount: 0,
            isFollowing: following,
            showDownloadButton: false,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildButtons(following: true));
    expect(find.byIcon(LoftifyIcons.check), findsNothing);
    expect(find.byIcon(LoftifyIcons.add), findsNothing);

    await tester.pumpWidget(buildButtons(following: false));
    expect(find.byIcon(LoftifyIcons.add), findsOneWidget);

    await tester.pumpWidget(
      buildButtons(following: true, likeCount: 29509),
    );
    expect(find.text('2.9w'), findsOneWidget);
    final compactCount = tester.widget<Text>(find.text('2.9w'));
    expect(compactCount.maxLines, 1);
    expect(compactCount.softWrap, isFalse);
  });

  testWidgets('author page follows the horizontal drag and handles back',
      (tester) async {
    var opened = 0;
    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: InteractiveAuthorSwipe(
            authorId: 1,
            onOpen: () => opened++,
            onClose: () => closed++,
            authorBuilder: (_) => const ColoredBox(
              color: Colors.white,
              child: Center(child: Text('Author page')),
            ),
            child: const ColoredBox(color: Colors.black),
          ),
        ),
      ),
    );

    final swipe = find.byType(InteractiveAuthorSwipe);
    final gesture = await tester.startGesture(
      tester.getTopRight(swipe) + const Offset(-10, 200),
    );
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();

    expect(find.text('Author page'), findsOneWidget);
    final authorSwipeState = tester.state<InteractiveAuthorSwipeState>(swipe);
    expect(authorSwipeState.isAuthorVisible, isTrue);
    final movingAuthor = tester.widget<Transform>(
      find.byKey(const ValueKey('interactive-author-pane')),
    );
    expect(
      movingAuthor.transform.getTranslation().x,
      inExclusiveRange(0, tester.getSize(swipe).width),
    );

    await gesture.moveBy(const Offset(-240, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('interactive-author-pane')),
          )
          .transform
          .getTranslation()
          .x,
      0,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(closed, 1);
    expect(authorSwipeState.isAuthorVisible, isFalse);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('interactive-video-pane')),
          )
          .transform
          .getTranslation()
          .x,
      0,
    );
  });

  testWidgets('changing author content preserves the video page position',
      (tester) async {
    var authorId = 1;
    late StateSetter updateHost;
    final pageController = PageController();
    addTearDown(pageController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return InteractiveAuthorSwipe(
              authorId: authorId,
              authorBuilder: (_) => const ColoredBox(color: Colors.white),
              child: PageView(
                controller: pageController,
                scrollDirection: Axis.vertical,
                children: const [
                  ColoredBox(color: Colors.black),
                  ColoredBox(color: Colors.blue),
                  ColoredBox(color: Colors.red),
                ],
              ),
            );
          },
        ),
      ),
    );

    pageController.jumpToPage(1);
    await tester.pump();
    expect(pageController.page, 1);

    updateHost(() => authorId = 2);
    await tester.pump();

    expect(pageController.page, 1);
  });

  testWidgets('video action sheet updates playback controls', (tester) async {
    bool? continuous;
    bool? danmaku;
    double? speed;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: chewieProvider.globalNavigatorKey,
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return VideoPlaybackActionsSheet(
              continuousPlayback: false,
              danmakuEnabled: false,
              playbackSpeed: 1,
              downloading: false,
              onContinuousPlaybackChanged: (value) => continuous = value,
              onDanmakuChanged: (value) => danmaku = value,
              onPlaybackSpeedChanged: (value) => speed = value,
              onShare: () {},
              onDownload: () {},
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('自动连播'));
    await tester.tap(find.text('弹幕'));
    await tester.tap(find.text('1.5x'));
    await tester.pump();

    expect(continuous, isTrue);
    expect(danmaku, isTrue);
    expect(speed, 1.5);
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 50 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _streams = {};
  final Set<int> disposedIds = {};
  final List<int> playedIds = [];
  final List<Duration> soughtPositions = [];
  final List<bool> loopingValues = [];
  final List<double> playbackSpeeds = [];
  int createCount = 0;
  bool failNextInitialization = false;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = ++createCount;
    _streams[id] = StreamController<VideoEvent>();
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final stream = _streams[playerId]!;
    final shouldFail = failNextInitialization;
    failNextInitialization = false;
    scheduleMicrotask(() {
      if (shouldFail) {
        stream.addError(PlatformException(
          code: 'video_test_error',
          message: 'Could not load video',
        ));
      } else {
        stream.add(VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 30),
          size: const Size(1080, 1920),
        ));
      }
    });
    return stream.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    disposedIds.add(playerId);
    await _streams.remove(playerId)?.close();
  }

  @override
  Future<void> play(int playerId) async {
    playedIds.add(playerId);
  }

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    loopingValues.add(looping);
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    soughtPositions.add(position);
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    playbackSpeeds.add(speed);
  }

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();
}
