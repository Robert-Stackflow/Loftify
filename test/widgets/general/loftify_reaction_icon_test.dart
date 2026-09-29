import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/loftify_icons.dart';
import 'package:loftify/Widgets/loftify_reaction_icon.dart';

void main() {
  testWidgets('selected reactions are tintable vector silhouettes',
      (tester) async {
    for (final kind in LoftifyReactionKind.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: LoftifyReactionIcon(
              kind: kind,
              selected: true,
              size: 28,
            ),
          ),
        ),
      );

      final paint = tester.widget<CustomPaint>(find.descendant(
        of: find.byType(LoftifyReactionIcon),
        matching: find.byType(CustomPaint),
      ));
      final painter = paint.painter! as LoftifyReactionIconPainter;
      expect(painter.kind, kind);
      expect(painter.color, LoftifyReactionColors.forKind(kind));
      expect(
          tester.getSize(find.byType(LoftifyReactionIcon)), const Size(28, 28));
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: LoftifyReactionIcon(
            kind: LoftifyReactionKind.bookmark,
            selected: true,
            color: Colors.purple,
          ),
        ),
      ),
    );
    final custom = tester.widget<CustomPaint>(find.descendant(
      of: find.byType(LoftifyReactionIcon),
      matching: find.byType(CustomPaint),
    ));
    expect(
        (custom.painter! as LoftifyReactionIconPainter).color, Colors.purple);
  });

  testWidgets('idle reactions keep matching Lucide outlines', (tester) async {
    const icons = {
      LoftifyReactionKind.like: LoftifyIcons.favorite,
      LoftifyReactionKind.recommend: LoftifyIcons.recommend,
      LoftifyReactionKind.bookmark: LoftifyIcons.bookmark,
    };
    for (final entry in icons.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: LoftifyReactionIcon(kind: entry.key, selected: false),
          ),
        ),
      );
      expect(find.byIcon(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
