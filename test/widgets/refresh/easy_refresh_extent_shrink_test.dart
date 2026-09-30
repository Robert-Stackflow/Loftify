import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wide wheel scrolling loads near the end once until completion',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var loads = 0;
    final pending = Completer<IndicatorResult>();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: EasyRefresh(
        footer: const LottieCupertinoFooter(
          infiniteOffset: 240,
          indicator: SizedBox.square(dimension: 36),
        ),
        onLoad: () {
          loads++;
          return pending.future;
        },
        child: ListView.builder(
          controller: controller,
          itemCount: 20,
          itemExtent: 100,
          itemBuilder: (_, index) => Text('Item $index'),
        ),
      ),
    )));
    await tester.pumpAndSettle();
    Future<void> wheel(double dy) async {
      await tester.sendEventToBinding(PointerScrollEvent(
        position: const Offset(400, 300),
        scrollDelta: Offset(0, dy),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    await wheel(1250);
    expect(controller.position.extentAfter, lessThan(240));
    expect(loads, 1);
    await wheel(100);
    expect(loads, 1);
    pending.complete(IndicatorResult.noMore);
    await tester.pumpAndSettle();
    await wheel(100);
    expect(loads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'refresh physics allows a ballistic move back after content extent shrinks',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var itemCount = 10;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return EasyRefresh(
                header: const LottieCupertinoHeader(
                  maxOverOffset: 84,
                  indicator: SizedBox.square(dimension: 40),
                ),
                footer: const LottieCupertinoFooter(
                  maxOverOffset: 76,
                  indicator: SizedBox.square(dimension: 36),
                ),
                onRefresh: () async {},
                child: ListView.builder(
                  controller: controller,
                  itemExtent: 100,
                  itemCount: itemCount,
                  itemBuilder: (context, index) => Text('Item $index'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(387);
    rebuild(() => itemCount = 8);
    await tester.pump();

    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    await tester.pumpAndSettle();

    expect(controller.offset, closeTo(0, 0.1));
    expect(tester.takeException(), isNull);
  });
}
