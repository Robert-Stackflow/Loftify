import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:loftify/Widgets/Design/loftify_content_frame.dart';
import 'package:loftify/Widgets/PostDetail/post_swipe_gesture_detector.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets('split divider resizes without switching posts ($kind)',
        (tester) async {
      final bodyKey = GlobalKey();
      final recommendationsKey = GlobalKey();
      var postUpdates = 0;
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_host(LoftifyContentFrame(
          child: PostSwipeGestureDetector(
        activeRegion: bodyKey,
        onHorizontalDragUpdate: (_) => postUpdates++,
        child: ResizableContainer(
          direction: Axis.horizontal,
          children: [
            ResizableChild(
              size: const ResizableSize.ratio(0.6),
              divider: const ResizableDivider(padding: 12),
              child: ColoredBox(key: bodyKey, color: Colors.white),
            ),
            ResizableChild(
              child: ColoredBox(key: recommendationsKey, color: Colors.grey),
            ),
          ],
        ),
      ))));
      await tester.pumpAndSettle();
      final split = tester.getRect(find.byType(ResizableContainer));
      expect(split.width, 1180);
      expect(split.center.dx, 900);
      final initialBody = tester.getRect(find.byKey(bodyKey));
      final dividerStart = Offset(initialBody.right + 6, initialBody.center.dy);
      final gesture = await tester.startGesture(dividerStart, kind: kind);
      await gesture.moveBy(const Offset(30, 0));
      await gesture.moveBy(const Offset(70, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(bodyKey)).width,
          greaterThan(initialBody.width));
      expect(postUpdates, 0);

      // The entire drag belongs to the pane in which it began, even when it
      // crosses into the article. The outer screen edge must not bypass it.
      final right = tester.getRect(find.byKey(recommendationsKey));
      await tester.dragFrom(
          Offset(right.right - 8, right.center.dy), const Offset(-350, 0));
      expect(postUpdates, 0);
      await tester.drag(find.byKey(bodyKey), const Offset(100, 0));
      expect(postUpdates, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unmounted desktop pane keeps phone swipes enabled',
      (tester) async {
    var updates = 0;
    await tester.pumpWidget(_host(PostSwipeGestureDetector(
      activeRegion: GlobalKey(),
      onHorizontalDragUpdate: (_) => updates++,
      child: const SizedBox.expand(),
    )));
    await tester.dragFrom(const Offset(80, 400), const Offset(150, 0));
    expect(updates, greaterThan(0));
  });

  testWidgets('interactive horizontal child owns drags that start inside it', (
    tester,
  ) async {
    final excludedKey = GlobalKey();
    var outerUpdates = 0;
    var innerUpdates = 0;
    await tester.pumpWidget(
      _host(
        PostSwipeGestureDetector(
          excludedRegions: [excludedKey],
          onHorizontalDragUpdate: (_) => outerUpdates++,
          child: Center(
            child: GestureDetector(
              key: excludedKey,
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (_) => innerUpdates++,
              child: const SizedBox(width: 220, height: 180),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byKey(excludedKey), const Offset(-150, 0));

    expect(innerUpdates, greaterThan(0));
    expect(outerUpdates, 0);
  });

  testWidgets('post surface owns horizontal drags outside excluded children', (
    tester,
  ) async {
    final excludedKey = GlobalKey();
    var outerUpdates = 0;
    var innerUpdates = 0;
    await tester.pumpWidget(
      _host(
        PostSwipeGestureDetector(
          excludedRegions: [excludedKey],
          onHorizontalDragUpdate: (_) => outerUpdates++,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.white)),
              Align(
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  key: excludedKey,
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (_) => innerUpdates++,
                  child: const SizedBox(width: 220, height: 180),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.dragFrom(const Offset(80, 500), const Offset(180, 0));

    expect(outerUpdates, greaterThan(0));
    expect(innerUpdates, 0);
  });

  testWidgets('diagonal post swipe reports consistent horizontal drag details',
      (tester) async {
    final updates = <DragUpdateDetails>[];
    DragEndDetails? end;
    await tester.pumpWidget(_host(PostSwipeGestureDetector(
      onHorizontalDragUpdate: updates.add,
      onHorizontalDragEnd: (details) => end = details,
      child: const SizedBox.expand(),
    )));

    await tester.dragFrom(const Offset(80, 500), const Offset(180, 40));

    expect(updates, isNotEmpty);
    for (final update in updates) {
      expect(update.delta.dy, 0);
      expect(update.primaryDelta, update.delta.dx);
    }
    expect(end, isNotNull);
    expect(end!.velocity.pixelsPerSecond.dy, 0);
    expect(end!.primaryVelocity, end!.velocity.pixelsPerSecond.dx);
    expect(tester.takeException(), isNull);
  });

  testWidgets('screen edge remains reserved for post navigation', (
    tester,
  ) async {
    final excludedKey = GlobalKey();
    var outerUpdates = 0;
    var innerUpdates = 0;
    await tester.pumpWidget(
      _host(
        PostSwipeGestureDetector(
          excludedRegions: [excludedKey],
          onHorizontalDragUpdate: (_) => outerUpdates++,
          child: GestureDetector(
            key: excludedKey,
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (_) => innerUpdates++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.dragFrom(const Offset(8, 500), const Offset(180, 0));

    expect(outerUpdates, greaterThan(0));
    expect(innerUpdates, 0);
  });

  testWidgets('selectable article text does not block post swipes', (
    tester,
  ) async {
    var outerUpdates = 0;
    await tester.pumpWidget(
      _host(
        PostSwipeGestureDetector(
          onHorizontalDragUpdate: (_) => outerUpdates++,
          child: const SelectionArea(
            child: SizedBox.expand(
              child: Text(
                'Long-form article content remains selectable while a '
                'deliberate horizontal drag switches between posts.',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.dragFrom(const Offset(8, 500), const Offset(180, 0));

    expect(outerUpdates, greaterThan(0));
  });

  testWidgets('selectable HTML text accepts swipes from the middle',
      (tester) async {
    var outerUpdates = 0;
    await tester.pumpWidget(
      _host(
        PostSwipeGestureDetector(
          onHorizontalDragUpdate: (_) => outerUpdates++,
          child: const SelectionArea(
            child: Center(
              child: Text('Selectable post body content'),
            ),
          ),
        ),
      ),
    );

    await tester.drag(
        find.text('Selectable post body content'), const Offset(-180, 0));
    expect(outerUpdates, greaterThan(0));
  });

  testWidgets('vertical scrolling still wins the gesture arena', (
    tester,
  ) async {
    final controller = ScrollController();
    var outerUpdates = 0;
    await tester.pumpWidget(
      _host(
        PostSwipeGestureDetector(
          onHorizontalDragUpdate: (_) => outerUpdates++,
          child: ListView.builder(
            controller: controller,
            itemExtent: 80,
            itemCount: 40,
            itemBuilder: (context, index) => Text('Item $index'),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
    expect(outerUpdates, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
