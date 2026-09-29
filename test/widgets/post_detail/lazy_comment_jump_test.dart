import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/PostDetail/lazy_comment_jump.dart';

void main() {
  for (final startInRecommendations in <bool>[false, true]) {
    testWidgets(
      'comment jump finds lazy heading from ${startInRecommendations ? 'recommendations' : 'article'}',
      (tester) async {
        final controller = ScrollController();
        final anchorKey = GlobalKey();
        final contentKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                controller: controller,
                slivers: [
                  SliverList.list(
                    key: contentKey,
                    children: [
                      const SizedBox(height: 2200, child: Text('Article')),
                      SizedBox(
                        key: anchorKey,
                        height: 56,
                        child: const Text('Comments'),
                      ),
                      const SizedBox(height: 500, child: Text('Replies')),
                      const SizedBox(height: 56, child: Text('More')),
                    ],
                  ),
                  SliverList.builder(
                    itemCount: 60,
                    itemBuilder: (_, index) => SizedBox(
                      height: 100,
                      child: Text('Recommendation $index'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        controller.jumpTo(startInRecommendations ? 4300 : 100);
        await tester.pump();
        expect(anchorKey.currentContext, isNull);
        final contentSliver =
            contentKey.currentContext!.findRenderObject()! as RenderSliver;
        final jump = revealLazyComment(
          controller: controller,
          anchorKey: anchorKey,
          contentExtent: contentSliver.geometry!.scrollExtent,
          isActive: () => true,
        );
        for (var frame = 0; frame < 50; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await jump;

        expect(anchorKey.currentContext, isNotNull);
        final heading = tester.getRect(find.text('Comments'));
        expect(heading.top, greaterThanOrEqualTo(0));
        expect(heading.top, lessThan(tester.view.physicalSize.height));
        expect(tester.takeException(), isNull);
        controller.dispose();
      },
    );
  }
}
