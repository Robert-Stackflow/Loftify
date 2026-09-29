import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('divider follows the nearest light or dark theme',
      (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final dividerColor = brightness == Brightness.light
          ? const Color(0xFFE4E7E6)
          : const Color(0xFF383E3D);
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness, dividerColor: dividerColor),
        home: const Scaffold(body: MyDivider(key: ValueKey('divider'))),
      ));
      await tester.pumpAndSettle();
      final container = tester.widget<Container>(find.descendant(
        of: find.byKey(const ValueKey('divider')),
        matching: find.byType(Container),
      ));
      expect((container.decoration! as BoxDecoration).color, dividerColor);
    }
  });
}
