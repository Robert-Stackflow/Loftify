import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Widgets/BottomSheet/slide_captcha_bottom_sheet.dart';
import 'package:loftify/l10n/l10n.dart';

void main() {
  const sourceSize = Size(352, 160);
  const puzzleSourceWidth = 44.0;

  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/slide_captcha_geometry',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  test('nominal captcha geometry preserves source coordinates', () {
    final geometry = SlideCaptchaGeometry.calculate(
      availableWidth: 400,
      sourceSize: sourceSize,
      puzzleSourceWidth: puzzleSourceWidth,
    );

    expect(geometry.panelWidth, 352);
    expect(geometry.contentWidth, 320);
    expect(geometry.sourceScale, closeTo(1.1, 0.0001));
    expect(geometry.puzzleWidth, closeTo(40, 0.0001));
    expect(geometry.handleTravel, closeTo(280, 0.0001));
    expect(geometry.puzzleTravel, closeTo(280, 0.0001));
    expect(geometry.sourceOffset(1), closeTo(308, 0.0001));
  });

  test('narrow layouts scale image and submission travel together', () {
    final geometry = SlideCaptchaGeometry.calculate(
      availableWidth: 320,
      sourceSize: sourceSize,
      puzzleSourceWidth: puzzleSourceWidth,
    );

    expect(
      geometry.panelWidth + SlideCaptchaGeometry.outerPadding * 2,
      lessThanOrEqualTo(320),
    );
    expect(geometry.contentWidth, 256);
    expect(geometry.sourceScale, closeTo(1.375, 0.0001));
    expect(geometry.sourceOffset(0.5), closeTo(154, 0.0001));
    expect(geometry.puzzleOffset(1), closeTo(224, 0.0001));
    expect(geometry.handleOffset(1), closeTo(216, 0.0001));
  });

  test('wide and landscape layouts never upscale the captcha', () {
    final geometry = SlideCaptchaGeometry.calculate(
      availableWidth: 1200,
      sourceSize: sourceSize,
      puzzleSourceWidth: puzzleSourceWidth,
    );

    expect(geometry.panelWidth, sourceSize.width);
    expect(geometry.sourceScale, greaterThanOrEqualTo(1));
    expect(geometry.imageHeight, lessThanOrEqualTo(sourceSize.height));
  });

  test('server offset is independent of physical pixel density', () {
    final geometry = SlideCaptchaGeometry.calculate(
      availableWidth: 360,
      sourceSize: sourceSize,
      puzzleSourceWidth: puzzleSourceWidth,
    );

    for (final devicePixelRatio in <double>[1, 2, 3, 3.5, 4]) {
      final physicalDelta = geometry.handleTravel * 0.4 * devicePixelRatio;
      final logicalDelta = physicalDelta / devicePixelRatio;
      final progress = geometry.progressAfterDelta(0, logicalDelta);
      expect(geometry.sourceOffset(progress), closeTo(123.2, 0.0001));
    }
  });

  test('extreme constraints and drag deltas stay finite and clamped', () {
    final geometry = SlideCaptchaGeometry.calculate(
      availableWidth: 48,
      sourceSize: sourceSize,
      puzzleSourceWidth: puzzleSourceWidth,
    );

    expect(geometry.panelWidth, greaterThan(0));
    expect(geometry.contentWidth, greaterThan(0));
    expect(geometry.imageHeight.isFinite, isTrue);
    expect(geometry.progressAfterDelta(0.5, -10000), 0);
    expect(geometry.progressAfterDelta(0.5, 10000), 0);
    expect(geometry.sourceOffset(-1), 0);
    expect(geometry.sourceOffset(2), geometry.sourceTravel);
  });

  testWidgets(
      'panel layout and submitted source coordinate stay aligned across devices',
      (tester) async {
    const backgroundSourceSize = Size(1125, 222);
    const puzzleSourceSize = Size(72, 72);
    final assets = await tester.runAsync(() async => [
          await File('assets/mess/tag_row_bg.png').readAsBytes(),
          await _buildSquarePng(72),
        ]);
    final background = assets![0];
    final puzzle = assets[1];
    const accent = Color(0xFFE91E63);
    final captchaTheme = ChewieThemeColorData.defaultLightThemes.first
        .copyWith(primaryColor: accent)
        .toThemeData();
    final originalPhysicalSize = tester.view.physicalSize;
    final originalDevicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(() {
      tester.view.physicalSize = originalPhysicalSize;
      tester.view.devicePixelRatio = originalDevicePixelRatio;
    });

    const variants = <({Size logicalSize, double pixelRatio})>[
      (logicalSize: Size(280, 560), pixelRatio: 1),
      (logicalSize: Size(360, 800), pixelRatio: 4),
      (logicalSize: Size(1024, 600), pixelRatio: 2),
    ];

    for (final variant in variants) {
      tester.view.devicePixelRatio = variant.pixelRatio;
      tester.view.physicalSize = Size(
        variant.logicalSize.width * variant.pixelRatio,
        variant.logicalSize.height * variant.pixelRatio,
      );
      double? submittedOffset;

      await tester.pumpWidget(
        MaterialApp(
          theme: captchaTheme,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              chewieProvider.setRootContext(context);
              return Scaffold(
                body: SlideCaptchaBottomSheet(
                  challengeLoader: () async => {
                    'code': 0,
                    'data': {
                      'id': 'layout-test',
                      'bg': base64Encode(background),
                      'front': base64Encode(puzzle),
                    },
                  },
                  challengeVerifier: ({
                    required id,
                    required offset,
                    required rawKey,
                    required rawIv,
                  }) {
                    submittedOffset = offset;
                    final encrypted = CryptUtil.encryptDataByAES(
                      {
                        'code': 0,
                        'data': {'success': false},
                      },
                      rawKey,
                      rawIv,
                    );
                    return Future<dynamic>.value(base64Decode(encrypted));
                  },
                ),
              );
            },
          ),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('slideCaptchaHandle')),
      );

      final panel = find.byKey(const ValueKey('slideCaptchaPanel'));
      final backgroundFinder =
          find.byKey(const ValueKey('slideCaptchaBackground'));
      final puzzleFinder = find.byKey(const ValueKey('slideCaptchaPuzzle'));
      final track = find.byKey(const ValueKey('slideCaptchaTrack'));
      final progress = find.byKey(const ValueKey('slideCaptchaProgress'));
      final handle = find.byKey(const ValueKey('slideCaptchaHandle'));
      final panelWidth = tester.getSize(panel).width;
      final trackWidth = tester.getSize(track).width;
      final imageSize = tester.getSize(backgroundFinder);
      final expectedPanelWidth =
          (variant.logicalSize.width - 32).clamp(1.0, 1125.0);

      expect(panelWidth, closeTo(expectedPanelWidth, 0.01));
      expect(trackWidth, closeTo(panelWidth - 32, 0.01));
      expect(imageSize.width, closeTo(trackWidth, 0.01));
      expect(
        imageSize.height,
        closeTo(
          trackWidth * backgroundSourceSize.height / backgroundSourceSize.width,
          0.01,
        ),
      );
      expect(tester.getSize(puzzleFinder).width,
          closeTo(trackWidth * 72 / 1125, 0.01));
      final progressDecoration =
          tester.widget<Container>(progress).decoration! as BoxDecoration;
      final handleDecoration =
          tester.widget<Container>(handle).decoration! as BoxDecoration;
      expect(progressDecoration.color, accent.withValues(alpha: 0.14));
      expect(handleDecoration.color, accent);
      expect(tester.takeException(), isNull);

      final trackRect = tester.getRect(track);
      final dragDistance = (trackWidth - SlideCaptchaGeometry.handleWidth) / 2;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(Offset(dragDistance, 0));
      await tester.pump();

      final handleOffset = tester.getRect(handle).left - trackRect.left;
      final puzzleOffset = tester.getRect(puzzleFinder).left -
          tester.getRect(backgroundFinder).left;
      expect(handleOffset, closeTo(dragDistance, 0.5));
      expect(
        puzzleOffset,
        closeTo(
          (trackWidth -
                  trackWidth *
                      puzzleSourceSize.width /
                      backgroundSourceSize.width) /
              2,
          0.5,
        ),
      );

      await gesture.up();
      await tester.pump();
      expect(
        submittedOffset,
        closeTo(
          (backgroundSourceSize.width - puzzleSourceSize.width) / 2,
          0.5,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}

Future<Uint8List> _buildSquarePng(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final image = await recorder.endRecording().toImage(size, size);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30 && finder.evaluate().isEmpty; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(finder, findsOneWidget);
}
