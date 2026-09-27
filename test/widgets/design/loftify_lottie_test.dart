import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Widgets/Navigation/loftify_glass_navigation_bar.dart';
import 'package:lottie/lottie.dart';

Finder _assetLottie(String asset) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is LottieBuilder &&
        widget.lottie is AssetLottie &&
        (widget.lottie as AssetLottie).assetName == asset,
  );
}

Widget _lottieHost({
  required Widget child,
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF16AFA8),
    brightness: brightness,
  );
  final theme = ThemeData(brightness: brightness, colorScheme: colorScheme);
  return MaterialApp(
    theme: theme,
    darkTheme: theme,
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Center(child: child),
    ),
  );
}

void main() {
  test('every Lottie JSON has a registered source canvas and valid viewport',
      () {
    final files = Directory('assets/lottie')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    final assets = files.map((file) => file.path.replaceAll('\\', '/')).toSet();

    expect(LottieFiles.specs.keys.toSet(), assets);
    for (final file in files) {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final asset = file.path.replaceAll('\\', '/');
      final spec = LottieFiles.specFor(asset);
      expect(spec.sourceSize.width, (json['w'] as num).toDouble());
      expect(spec.sourceSize.height, (json['h'] as num).toDouble());
      expect(spec.effectiveContentBounds.width, greaterThan(0));
      expect(spec.effectiveContentBounds.height, greaterThan(0));
      final sourceBounds = Offset.zero & spec.sourceSize;
      final viewport = spec.effectiveContentBounds;
      expect(viewport.left, greaterThanOrEqualTo(sourceBounds.left));
      expect(viewport.top, greaterThanOrEqualTo(sourceBounds.top));
      expect(viewport.right, lessThanOrEqualTo(sourceBounds.right));
      expect(viewport.bottom, lessThanOrEqualTo(sourceBounds.bottom));
    }
  });

  test('new navigation assets share one canvas and settle into a bold frame',
      () {
    for (final asset in <String>[
      LottieFiles.navHome,
      LottieFiles.navSearch,
      LottieFiles.navHeart,
      LottieFiles.navUser,
    ]) {
      final json =
          jsonDecode(File(asset).readAsStringSync()) as Map<String, dynamic>;
      final layers = (json['layers'] as List).cast<Map<String, dynamic>>();
      expect(json['w'], 48, reason: asset);
      expect(json['h'], 48, reason: asset);
      expect(json['fr'], 30, reason: asset);
      expect(json['op'], 24, reason: asset);
      expect(layers.any((layer) => (layer['nm'] as String).contains('Outline')),
          isTrue,
          reason: asset);
      expect(
          layers.any((layer) => (layer['shapes'] as List).cast<Map>().any(
              (shape) =>
                  shape['ty'] == 'fl' ||
                  (shape['nm'] as String).contains('Bold'))),
          isTrue,
          reason: asset);
      final spec = LottieFiles.specFor(asset);
      expect(spec.effectiveContentBounds, const Rect.fromLTWH(4, 4, 40, 40));
      expect(spec.opticalFill, 0.9);

      List<dynamic> opacityFrames(Map<String, dynamic> layer) {
        final transform = layer['ks'] as Map<String, dynamic>;
        final opacity = transform['o'] as Map<String, dynamic>;
        return opacity['k'] as List;
      }

      final outlineOpacity = opacityFrames(layers
          .firstWhere((layer) => (layer['nm'] as String).contains('Outline')));
      final fillOpacity = opacityFrames(layers
          .firstWhere((layer) => !(layer['nm'] as String).contains('Outline')));
      expect(
        ((outlineOpacity.first as Map)['s'] as List).first,
        100,
        reason: asset,
      );
      expect(
        ((outlineOpacity.last as Map)['s'] as List).first,
        0,
        reason: asset,
      );
      expect(
        ((fillOpacity.first as Map)['s'] as List).first,
        0,
        reason: asset,
      );
      expect(
        ((fillOpacity.last as Map)['s'] as List).first,
        100,
        reason: asset,
      );
    }
    final home = jsonDecode(File(LottieFiles.navHome).readAsStringSync())
        as Map<String, dynamic>;
    expect(home['nm'], contains('house'));
  });

  testWidgets(
      'icon assets expose one exact optical canvas at any requested size',
      (tester) async {
    await tester.pumpWidget(
      _lottieHost(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LottieFiles.buildAnimation(
              LottieFiles.collectionBigNormalLight,
              size: 20,
            ),
            LottieFiles.buildAnimation(
              LottieFiles.likeMediumLight,
              size: 24,
            ),
            LottieFiles.buildAnimation(
              LottieFiles.recommendVideoNormal,
              size: 32,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(
        find.byKey(
          const ValueKey(
            'loftify-lottie-icon-assets/lottie/collection_big_normal_light.json',
          ),
        ),
      ),
      const Size.square(20),
    );
    expect(
      tester.getSize(
        find.byKey(
          const ValueKey(
            'loftify-lottie-icon-assets/lottie/like_medium_light.json',
          ),
        ),
      ),
      const Size.square(24),
    );
    expect(
      tester.getSize(
        find.byKey(
          const ValueKey(
            'loftify-lottie-icon-assets/lottie/recommend_video_normal.json',
          ),
        ),
      ),
      const Size.square(32),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('all newly drawn navigation assets render', (tester) async {
    await tester.pumpWidget(_lottieHost(
      disableAnimations: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final asset in [
            LottieFiles.navHome,
            LottieFiles.navSearch,
            LottieFiles.navHeart,
            LottieFiles.navUser,
          ])
            LottieFiles.buildAnimation(asset, size: 22),
        ],
      ),
    ));
    await tester.pump();
    expect(find.byType(LottieBuilder), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme tint and reduced motion use semantic runtime state',
      (tester) async {
    Future<LottieBuilder> pump(Brightness brightness) async {
      await tester.pumpWidget(
        _lottieHost(
          brightness: brightness,
          disableAnimations: true,
          child: LottieFiles.buildLoadingAnimation(24, false),
        ),
      );
      await tester.pumpAndSettle();
      return tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    }

    final light = await pump(Brightness.light);
    expect(
      (light.lottie as AssetLottie).assetName,
      LottieFiles.loadingLight,
    );
    final lightPrimary = ColorScheme.fromSeed(
      seedColor: const Color(0xFF16AFA8),
    ).primary;
    expect(light.animate, isFalse);
    expect(light.repeat, isFalse);
    final lightPalette = light.delegates!.values!
        .map((delegate) => delegate.value)
        .cast<Color>()
        .toList();
    expect(lightPalette, hasLength(3));
    expect(lightPalette.first, lightPrimary);
    expect(lightPalette.toSet(), hasLength(3));

    final dark = await pump(Brightness.dark);
    expect((dark.lottie as AssetLottie).assetName, LottieFiles.loadingDark);
    final darkPrimary = ColorScheme.fromSeed(
      seedColor: const Color(0xFF16AFA8),
      brightness: Brightness.dark,
    ).primary;
    final darkPalette = dark.delegates!.values!
        .map((delegate) => delegate.value)
        .cast<Color>()
        .toList();
    expect(darkPalette, hasLength(3));
    expect(darkPalette.first, darkPrimary);
    expect(darkPalette.toSet(), hasLength(3));
    expect(darkPrimary, isNot(lightPrimary));
    expect(darkPalette, isNot(lightPalette));
  });

  testWidgets('navigation keeps a clear idle frame and plays selection once',
      (tester) async {
    Widget host(bool selected, {bool reduceMotion = false}) {
      return _lottieHost(
        disableAnimations: reduceMotion,
        child: LoftifyNavigationLottieIcon(
          key: const ValueKey('nav-search'),
          asset: LottieFiles.navSearch,
          selected: selected,
          color: const Color(0xFF16AFA8),
        ),
      );
    }

    await tester.pumpWidget(host(false));
    await tester.pump();
    var lottie = tester.widget<LottieBuilder>(
      _assetLottie(LottieFiles.navSearch),
    );
    var controller = lottie.controller! as AnimationController;
    expect(controller.value, 0);
    expect(controller.isAnimating, isFalse);

    await tester.pumpWidget(host(true));
    await tester.pump();
    lottie = tester.widget<LottieBuilder>(_assetLottie(LottieFiles.navSearch));
    controller = lottie.controller! as AnimationController;
    expect(controller.isAnimating, isTrue);

    await tester.pump(const Duration(milliseconds: 180));
    expect(controller.value, greaterThan(0));
    expect(controller.value, lessThan(1));
    await tester.pump(const Duration(seconds: 1));
    expect(controller.value, 1);
    expect(controller.isAnimating, isFalse);

    await tester.pumpWidget(host(false));
    await tester.pump();
    expect(controller.value, 0);
    await tester.pumpWidget(host(true, reduceMotion: true));
    await tester.pump();
    expect(controller.value, 1);
    expect(controller.isAnimating, isFalse);
    expect(tester.takeException(), isNull);
  });
}
