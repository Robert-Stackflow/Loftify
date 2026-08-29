import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Screens/panel_screen.dart';

void main() {
  testWidgets('system back delegates to the nested panel when root pop is off',
      (tester) async {
    var nestedPopCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PanelBackScope(
          canRootPop: false,
          onNestedPop: () => nestedPopCount++,
          child: const SizedBox.expand(),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(nestedPopCount, 1);
  });

  testWidgets('completed root pop does not run nested panel cleanup',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var nestedPopCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Text('root'),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => PanelBackScope(
          canRootPop: true,
          onNestedPop: () => nestedPopCount++,
          child: const Text('nested route'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('nested route'), findsNothing);
    expect(find.text('root'), findsOneWidget);
    expect(nestedPopCount, 0);
  });
}
