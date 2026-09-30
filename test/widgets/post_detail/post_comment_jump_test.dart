import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/PostDetail/post_content_sliver.dart';

void main() {
  for (final wide in [false, true]) {
    for (final startBelow in [false, true]) {
      testWidgets(
        '${wide ? 'two pane' : 'single pane'} jumps directly from '
        '${startBelow ? 'below comments' : 'long article'} without reversing',
        (tester) async {
          final controller = ScrollController();
          final recommendations = ScrollController();
          final anchorKey = GlobalKey();
          final viewportKey = GlobalKey();
          var recommendationBuilds = 0;
          var articleHeight = 2600.0;
          late StateSetter updateLayout;

          Widget recommendationSliver() => SliverList.builder(
                itemCount: 100,
                itemBuilder: (_, index) {
                  recommendationBuilds++;
                  return SizedBox(
                    height: 100,
                    child: Text('Recommendation $index'),
                  );
                },
              );

          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Post')),
              body: StatefulBuilder(builder: (context, setState) {
                updateLayout = setState;
                final post = CustomScrollView(
                  key: viewportKey,
                  controller: controller,
                  slivers: [
                    PostContentSliver(children: [
                      SizedBox(
                          height: articleHeight, child: const Text('Article')),
                      SizedBox(
                        key: anchorKey,
                        height: 56,
                        child: const Text('Comments'),
                      ),
                      const SizedBox(height: 1700, child: Text('Replies')),
                    ]),
                    if (!wide) recommendationSliver(),
                  ],
                );
                return wide
                    ? Row(children: [
                        Expanded(child: post),
                        Expanded(
                          child: CustomScrollView(
                            controller: recommendations,
                            slivers: [recommendationSliver()],
                          ),
                        ),
                      ])
                    : post;
              }),
            ),
          ));
          // The exact anchor must exist before scrolling. The large article
          // must not cause eager building of all recommendation cards.
          expect(anchorKey.currentContext, isNotNull);
          expect(recommendationBuilds, lessThan(20));
          if (wide) recommendations.jumpTo(1000);

          // Image loading or pane resizing can change the article's height;
          // the jump must use current layout, not a previously cached offset.
          updateLayout(() => articleHeight = 3100);
          await tester.pump();
          final start = startBelow ? (wide ? 4000.0 : 5500.0) : 100.0;
          controller.jumpTo(start);
          await tester.pump();
          final actualStart = controller.offset;
          final samples = <double>[actualStart];
          controller.addListener(() => samples.add(controller.offset));
          final jump = revealPostComment(
            controller: controller,
            anchorKey: anchorKey,
          );
          await tester.pumpAndSettle(const Duration(milliseconds: 16));
          await jump;

          expect(controller.offset, closeTo(articleHeight, 0.01));
          expect(tester.getTopLeft(find.byKey(anchorKey)).dy,
              closeTo(tester.getTopLeft(find.byKey(viewportKey)).dy, 0.01));
          expect(samples.length, greaterThan(2));
          for (var i = 1; i < samples.length; i++) {
            if (startBelow) {
              expect(samples[i], lessThanOrEqualTo(samples[i - 1]));
              expect(samples[i], greaterThanOrEqualTo(articleHeight - 0.01));
            } else {
              expect(samples[i], greaterThanOrEqualTo(samples[i - 1]));
              expect(samples[i], lessThanOrEqualTo(articleHeight + 0.01));
            }
          }
          if (wide) expect(recommendations.offset, 1000);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
          recommendations.dispose();
        },
      );
    }
  }

  testWidgets('short or empty comments clamp to bottom without overscroll',
      (tester) async {
    final controller = ScrollController();
    final anchorKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: CustomScrollView(
        controller: controller,
        slivers: [
          PostContentSliver(children: [
            const SizedBox(height: 1800),
            SizedBox(
                key: anchorKey, height: 56, child: const Text('No comments')),
          ]),
        ],
      ),
    ));
    final jump =
        revealPostComment(controller: controller, anchorKey: anchorKey);
    await tester.pumpAndSettle();
    await jump;
    expect(controller.offset, controller.position.maxScrollExtent);
    expect(tester.getBottomLeft(find.byKey(anchorKey)).dy, closeTo(600, 0.01));
    await revealPostComment(controller: controller, anchorKey: anchorKey);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    // Disposed routes / unavailable anchors must not start a search loop.
    await revealPostComment(controller: controller, anchorKey: anchorKey);
    controller.dispose();
    expect(tester.takeException(), isNull);
  });
}
