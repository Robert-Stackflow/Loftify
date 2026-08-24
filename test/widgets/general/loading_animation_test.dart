import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:awesome_chewie/src/Widgets/Module/PhotoView/src/photo_view_default_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Widgets/Design/loftify_lottie.dart';
import 'package:lottie/lottie.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/loading_animation',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  setUp(() {
    chewieProvider.loadingWidgetBuilder = LottieFiles.buildLoadingAnimation;
  });

  testWidgets('loading animation follows light, dark and forced-dark surfaces',
      (tester) async {
    Future<String> pumpAndReadAsset({
      required ThemeData theme,
      required bool forceDark,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          themeAnimationDuration: Duration.zero,
          home: LottieFiles.buildLoadingAnimation(42, forceDark),
        ),
      );
      await tester.pump();
      final normalized = tester.widget<LoftifyLottie>(
        find.byType(LoftifyLottie),
      );
      final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
      expect(normalized.size, 42);
      expect(
        tester.getSize(
          find.byKey(
            ValueKey('loftify-lottie-icon-${normalized.spec.asset}'),
          ),
        ),
        const Size.square(42),
      );
      return (lottie.lottie as AssetLottie).assetName;
    }

    expect(
      await pumpAndReadAsset(theme: ThemeData.light(), forceDark: false),
      LottieFiles.loadingLight,
    );
    expect(
      await pumpAndReadAsset(theme: ThemeData.dark(), forceDark: false),
      LottieFiles.loadingDark,
    );
    expect(
      await pumpAndReadAsset(theme: ThemeData.light(), forceDark: true),
      LottieFiles.loadingDarkTransparent,
    );
  });

  testWidgets('LoadingWidget uses Lottie over a transparent page surface',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return const LoadingWidget(showText: false, size: 36);
          },
        ),
      ),
    );
    await tester.pump();

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(LoadingWidget),
        matching: find.byType(Container),
      ),
    );
    expect(container.color, Colors.transparent);
    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('photo viewer default loading state uses forced-dark Lottie',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const PhotoViewDefaultLoading(),
      ),
    );
    await tester.pump();

    final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    expect(
      (lottie.lottie as AssetLottie).assetName,
      LottieFiles.loadingDarkTransparent,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Lottie refresh indicators stay above content with bounded travel', () {
    const indicator = SizedBox(key: ValueKey('refresh-lottie'));
    const header = LottieCupertinoHeader(indicator: indicator);
    const footer = LottieCupertinoFooter(indicator: indicator);

    expect(header.position, IndicatorPosition.above);
    expect(header.triggerOffset, 48);
    expect(header.maxOverOffset, 72);
    expect(header.springRebound, isTrue);
    expect(header.radius, 15);
    expect(footer.position, IndicatorPosition.above);
    expect(footer.triggerOffset, 44);
    expect(footer.maxOverOffset, 64);
    expect(footer.infiniteOffset, 240);
    expect(footer.radius, 14);
  });

  test('nested refresh keeps a compact indicator without a short trigger', () {
    final header = buildNestedRefreshHeader() as LottieCupertinoHeader;

    expect(header.position, IndicatorPosition.above);
    expect(header.triggerOffset, 44);
    expect(header.maxOverOffset, 64);
    expect(header.radius, 14);
  });

  testWidgets('pulling reveals Lottie while the list follows the gesture',
      (tester) async {
    final refreshCompleter = Completer<IndicatorResult>();
    const firstItemKey = ValueKey('first-refresh-item');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EasyRefresh.builder(
            header: const LottieCupertinoHeader(
              indicator: SizedBox(
                key: ValueKey('visible-refresh-lottie'),
                width: 44,
                height: 44,
              ),
            ),
            onRefresh: () => refreshCompleter.future,
            childBuilder: (context, physics) => ListView(
              physics: physics,
              children: const [
                SizedBox(key: firstItemKey, height: 80),
                SizedBox(height: 900),
              ],
            ),
          ),
        ),
      ),
    );

    final initialTop = tester.getTopLeft(find.byKey(firstItemKey)).dy;
    final gesture = await tester.startGesture(const Offset(200, 120));
    await gesture.moveBy(const Offset(0, 8));
    await tester.pump();

    expect(
        find.byKey(const ValueKey('visible-refresh-lottie')), findsOneWidget);
    double indicatorScale() => tester
        .widget<Transform>(find.byKey(const ValueKey('indicatorPullScale')))
        .transform
        .storage[0];
    final firstScale = indicatorScale();
    final firstGap =
        tester.getTopLeft(find.byKey(firstItemKey)).dy - initialTop;
    expect(30 * firstScale, lessThanOrEqualTo(firstGap + 0.01));
    await gesture.moveBy(const Offset(0, 32));
    await tester.pump();
    final secondScale = indicatorScale();
    final secondGap =
        tester.getTopLeft(find.byKey(firstItemKey)).dy - initialTop;
    expect(firstScale, lessThan(secondScale));
    expect(secondScale, lessThanOrEqualTo(1));
    expect(30 * secondScale, lessThanOrEqualTo(secondGap + 0.01));
    expect(tester.getTopLeft(find.byKey(firstItemKey)).dy,
        greaterThan(initialTop));
    expect(tester.takeException(), isNull);

    await gesture.up();
    refreshCompleter.complete(IndicatorResult.success);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'programmatic refresh uses the supplied nested position before any drag',
      (tester) async {
    final refreshCompleter = Completer<IndicatorResult>();
    final refreshController = EasyRefreshController();
    final scrollController = ScrollController();
    addTearDown(refreshController.dispose);
    addTearDown(scrollController.dispose);
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EasyRefresh.builder(
            controller: refreshController,
            header: const LottieCupertinoHeader(
              triggerOffset: 52,
              indicator: SizedBox(key: ValueKey('programmatic-lottie')),
            ),
            onRefresh: () {
              refreshCount++;
              return refreshCompleter.future;
            },
            childBuilder: (context, physics) => ListView(
              controller: scrollController,
              physics: physics,
              children: const [SizedBox(height: 900)],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    unawaited(
      refreshController.callRefresh(
        overOffset: 28,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scrollController: scrollController,
        jumpToEdge: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('programmatic-lottie')), findsOneWidget);
    expect(refreshCount, 1);
    expect(tester.takeException(), isNull);

    refreshCompleter.complete(IndicatorResult.success);
    await tester.pumpAndSettle();
  });

  testWidgets('footer prefetches before the list reaches its hard edge',
      (tester) async {
    var loads = 0;
    double? extentAfterAtLoad;
    final loadCompleter = Completer<IndicatorResult>();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EasyRefresh(
            footer: const LottieCupertinoFooter(
              infiniteOffset: 240,
              indicator: SizedBox(width: 32, height: 32),
            ),
            onLoad: () {
              loads++;
              extentAfterAtLoad = controller.position.extentAfter;
              return loadCompleter.future;
            },
            child: ListView.builder(
              controller: controller,
              itemExtent: 100,
              itemCount: 12,
              itemBuilder: (_, index) => Text('Item $index'),
            ),
          ),
        ),
      ),
    );

    await tester.timedDrag(
      find.byType(ListView),
      const Offset(0, -520),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();

    expect(loads, 1);
    expect(
      extentAfterAtLoad,
      greaterThan(0),
      reason: 'load should start before the list is dragged past its end',
    );
    loadCompleter.complete(IndicatorResult.success);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('sliver empty state does not request viewport intrinsics',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return const Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(expandedHeight: 180),
                  SliverEmptyPlaceholder(text: 'No content'),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No content'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
