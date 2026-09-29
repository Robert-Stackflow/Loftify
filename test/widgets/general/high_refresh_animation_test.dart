import 'dart:async';

import 'package:awesome_chewie/src/Utils/System/route_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('page transition progress is independent of frame cadence',
      (tester) async {
    Future<double> measureAt(int refreshRate) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final pageKey = ValueKey<String>('page-$refreshRate');
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey<int>(refreshRate),
          navigatorKey: navigatorKey,
          home: const SizedBox.shrink(),
        ),
      );
      unawaited(
        navigatorKey.currentState!.push<void>(
          RouteUtil.getFadeRoute(
            ColoredBox(key: pageKey, color: Colors.white),
            duration: const Duration(milliseconds: 300),
          ),
        ),
      );
      await tester.pump();
      await _pumpAtCadence(
        tester,
        refreshRate: refreshRate,
        elapsed: const Duration(milliseconds: 150),
      );

      final transition = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.byKey(pageKey),
          matching: find.byType(FadeTransition),
        ),
      );
      return transition.opacity.value;
    }

    final progress60 = await measureAt(60);
    final progress90 = await measureAt(90);
    final progress120 = await measureAt(120);

    expect(progress60, closeTo(progress90, 0.001));
    expect(progress90, closeTo(progress120, 0.001));
    expect(progress120, closeTo(0.5, 0.01));
  });
}

Future<void> _pumpAtCadence(
  WidgetTester tester, {
  required int refreshRate,
  required Duration elapsed,
}) async {
  final frame = Duration(
    microseconds: (Duration.microsecondsPerSecond / refreshRate).round(),
  );
  var remaining = elapsed;
  while (remaining > Duration.zero) {
    final step = remaining < frame ? remaining : frame;
    await tester.pump(step);
    remaining -= step;
  }
}
