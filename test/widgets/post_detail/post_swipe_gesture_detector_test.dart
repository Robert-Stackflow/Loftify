import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/PostDetail/post_swipe_gesture_detector.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
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
