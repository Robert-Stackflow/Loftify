import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackingScrollController extends ScrollController {
  int added = 0;
  int removed = 0;

  @override
  void addListener(VoidCallback listener) {
    added++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    removed++;
    super.removeListener(listener);
  }
}

void main() {
  testWidgets('ScrollToHide moves and releases controller listeners',
      (tester) async {
    final first = _TrackingScrollController();
    final second = _TrackingScrollController();
    final visibility = ScrollToHideController();

    Widget build(ScrollController controller) {
      return MaterialApp(
        home: ScrollToHide(
          scrollController: controller,
          hideDirection: Axis.vertical,
          controller: visibility,
          child: const SizedBox(height: 40),
        ),
      );
    }

    await tester.pumpWidget(build(first));
    expect(first.added, 1);
    expect(visibility.doHide, isNotNull);

    await tester.pumpWidget(build(second));
    expect(first.removed, 1);
    expect(second.added, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(second.removed, 1);
    expect(visibility.doShow, isNull);
    expect(visibility.doHide, isNull);

    first.dispose();
    second.dispose();
  });

  testWidgets(
      'multi controller reacts only to the controller that actually scrolls',
      (tester) async {
    final first = ScrollController();
    final second = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: first,
                  itemExtent: 60,
                  itemCount: 40,
                  itemBuilder: (_, index) => Text('First $index'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: second,
                  itemExtent: 60,
                  itemCount: 40,
                  itemBuilder: (_, index) => Text('Second $index'),
                ),
              ),
            ],
          ),
          bottomNavigationBar: ScrollToHide.multi(
            scrollControllers: [first, second],
            hideDirection: Axis.vertical,
            child: const SizedBox(height: 60),
          ),
        ),
      ),
    );

    final opacityFinder = find.byKey(
      const ValueKey('scroll-to-hide-opacity'),
    );
    await tester.drag(find.text('Second 0'), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(opacityFinder).opacity, 0);

    await tester.drag(find.text('Second 6'), const Offset(0, 240));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(opacityFinder).opacity, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    first.dispose();
    second.dispose();
  });

  testWidgets('multi controller swaps active registrations without stale input',
      (tester) async {
    final first = _TrackingScrollController();
    final second = _TrackingScrollController();
    final visibility = ScrollToHideController();
    var useFirst = true;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            final active = useFirst ? first : second;
            return Scaffold(
              body: ListView.builder(
                key: ValueKey(useFirst),
                controller: active,
                itemExtent: 60,
                itemCount: 40,
                itemBuilder: (_, index) => Text('Item $index'),
              ),
              bottomNavigationBar: ScrollToHide.multi(
                controller: visibility,
                scrollControllers: [active],
                hideDirection: Axis.vertical,
                child: const SizedBox(height: 60),
              ),
            );
          },
        ),
      ),
    );

    expect(first.added, 1);
    await tester.drag(find.text('Item 0'), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('scroll-to-hide-opacity')),
          )
          .opacity,
      0,
    );

    rebuild(() => useFirst = false);
    await tester.pumpAndSettle();
    expect(first.removed, 1);
    expect(second.added, 1);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('scroll-to-hide-opacity')),
          )
          .opacity,
      1,
    );

    await tester.drag(find.text('Item 0'), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('scroll-to-hide-opacity')),
          )
          .opacity,
      0,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    expect(second.removed, 1);
    first.dispose();
    second.dispose();
  });
}
