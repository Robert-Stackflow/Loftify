import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

void main() {
  testWidgets('desktop search hint and caret stay centered with compact theme',
      (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    const hint = '搜标签、合集、文章、讨论、粮单、用户';
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        platform: TargetPlatform.windows,
        visualDensity: VisualDensity.compact,
        textTheme: const TextTheme(
          titleSmall: TextStyle(fontSize: 15, height: 1.2),
        ),
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: const ValueKey('desktop-search-bar'),
            width: 500,
            height: 36,
            child: Builder(
              builder: (context) => ItemBuilder.buildSearchBar(
                context: context,
                hintText: hint,
                focusNode: focusNode,
                controller: controller,
                onSubmitted: (_) {},
              ),
            ),
          ),
        ),
      ),
    ));
    focusNode.requestFocus();
    await tester.pump();

    final centerY =
        tester.getCenter(find.byKey(const ValueKey('desktop-search-bar'))).dy;
    expect((tester.getCenter(find.text(hint)).dy - centerY).abs(), lessThan(1));
    for (final text in ['', '搜索文字 Abc']) {
      controller.text = text;
      await tester.pump();
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final caret =
          editable.getLocalRectForCaret(const TextPosition(offset: 0));
      expect((editable.localToGlobal(caret.center).dy - centerY).abs(),
          lessThan(1),
          reason: 'Text: $text');
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    focusNode.dispose();
  });

  for (final height in <double>[28, 36, 48, 56]) {
    testWidgets('shared search hint is centered at height $height',
        (tester) async {
      const hint = '多个搜索词以空格隔开';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                key: const ValueKey('search-bar-host'),
                width: 360,
                height: height,
                child: Builder(
                  builder: (context) => ItemBuilder.buildSearchBar(
                    context: context,
                    hintText: hint,
                    onSubmitted: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final field = find.byType(TextField);
      final bar = find.byKey(const ValueKey('search-bar-host'));
      final placeholder = find.text(hint);
      expect(field, findsOneWidget);
      expect(placeholder, findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        (tester.getCenter(placeholder).dy - tester.getCenter(bar).dy).abs(),
        lessThan(2),
      );
    });
  }
}
