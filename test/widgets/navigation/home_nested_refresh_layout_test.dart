import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('floating app bar leaves the pull indicator below the toolbar',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var refreshes = 0;
    late ScrollController innerController;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(top: 24),
        ),
        child: Scaffold(
          body: ExtendedNestedScrollView(
            onlyOneScrollInBody: true,
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, _) => [
              const SliverAppBar(
                key: ValueKey('toolbar'),
                floating: true,
                snap: true,
                toolbarHeight: 48,
                title: Text('Home'),
              ),
            ],
            body: Builder(
              builder: (context) {
                innerController = PrimaryScrollController.of(context);
                return EasyRefresh.builder(
                  scrollController: innerController,
                  header: const LottieCupertinoHeader(
                    safeArea: false,
                    clamping: true,
                    indicator: SizedBox(width: 40, height: 40),
                  ),
                  onRefresh: () async => refreshes++,
                  childBuilder: (context, physics) => CustomScrollView(
                    controller: innerController,
                    physics: physics,
                    slivers: [
                      SliverList.builder(
                        itemCount: 30,
                        itemBuilder: (context, index) => SizedBox(
                          height: 100,
                          child: Text('Item $index'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    final feedElement = tester.element(find.byType(CustomScrollView));

    const toolbarBottom = 24.0 + 48.0;
    final firstItemTop = tester.getTopLeft(find.text('Item 0')).dy;
    expect(firstItemTop, greaterThanOrEqualTo(toolbarBottom));

    await tester.drag(find.text('Item 0'), const Offset(0, 350));
    await tester.pump();
    expect(
        identical(tester.element(find.byType(CustomScrollView)), feedElement),
        isTrue);
    final indicatorTop = tester
        .getTopLeft(find.byKey(const ValueKey('refresh-indicator-viewport')))
        .dy;
    expect(indicatorTop, greaterThanOrEqualTo(toolbarBottom));
    final indicatorBottom = indicatorTop +
        tester
            .getSize(find.byKey(const ValueKey('refresh-indicator-viewport')))
            .height;
    expect(tester.getTopLeft(find.text('Item 0')).dy,
        greaterThanOrEqualTo(indicatorBottom));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(
        identical(tester.element(find.byType(CustomScrollView)), feedElement),
        isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Item 0'), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(
        identical(tester.element(find.byType(CustomScrollView)), feedElement),
        isTrue);
    expect(tester.getTopLeft(find.byType(CustomScrollView)).dy, lessThan(24));
    innerController.jumpTo(0);
    await tester.pumpAndSettle();
    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 30));
      await tester.pumpAndSettle();
      expect(
          identical(tester.element(find.byType(CustomScrollView)), feedElement),
          isTrue);
    }
    expect(refreshes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('programmatic nested refresh uses the real header and haptics',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final haptics = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments.toString());
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final refreshController = EasyRefreshController();
    late ScrollController innerController;
    var refreshes = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExtendedNestedScrollView(
          onlyOneScrollInBody: true,
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, _) => [
            const SliverAppBar(floating: true, snap: true, title: Text('Home')),
          ],
          body: Builder(builder: (context) {
            innerController = PrimaryScrollController.of(context);
            return EasyRefresh.builder(
              controller: refreshController,
              scrollController: innerController,
              refreshOnStart: true,
              header: const LottieCupertinoHeader(
                safeArea: false,
                clamping: true,
                hapticFeedback: true,
                indicator: SizedBox(width: 40, height: 40),
              ),
              onRefresh: () async {
                refreshes++;
                return IndicatorResult.success;
              },
              childBuilder: (context, physics) => CustomScrollView(
                controller: innerController,
                physics: physics,
                slivers: [
                  SliverList.builder(
                    itemCount: 30,
                    itemBuilder: (context, index) => SizedBox(
                      height: 100,
                      child: Text('Item $index'),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(haptics, isEmpty);

    final refreshFuture = refreshController.callRefresh(
      scrollController: innerController,
    );
    await tester.pumpAndSettle();
    await refreshFuture;

    expect(refreshes, 2);
    expect(haptics, contains('HapticFeedbackType.mediumImpact'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    refreshController.dispose();
  });
}
