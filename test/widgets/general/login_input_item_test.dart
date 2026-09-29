import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Item/login_input_item.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

void main() {
  testWidgets('login clear action uses Lucide and a 48px touch target',
      (tester) async {
    final controller = TextEditingController(text: 'content');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        LoginInputItem(
          controller: controller,
          tailingConfig: InputItemLeadingTailingConfig(
            type: InputItemLeadingTailingType.clear,
          ),
        ),
      ),
    );

    final icon = find.byIcon(LoftifyIcons.clear);
    expect(icon, findsOneWidget);
    final touchTarget = find.ancestor(
      of: icon,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 48 && widget.height == 48,
      ),
    );
    expect(touchTarget, findsOneWidget);

    await tester.tap(icon);
    expect(controller.text, isEmpty);
  });

  testWidgets('password action changes meaning without leaving Lucide',
      (tester) async {
    final controller = TextEditingController(text: 'secret');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        LoginInputItem(
          controller: controller,
          tailingConfig: InputItemLeadingTailingConfig(
            type: InputItemLeadingTailingType.password,
          ),
        ),
      ),
    );

    expect(find.byIcon(LoftifyIcons.visible), findsOneWidget);
    await tester.tap(find.byIcon(LoftifyIcons.visible));
    await tester.pump();
    expect(find.byIcon(LoftifyIcons.hidden), findsOneWidget);
  });

  testWidgets('captcha action stays on one line in a narrow login field',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        LoginInputItem(
          controller: controller,
          hint: '输入短信验证码',
          leadingConfig: InputItemLeadingTailingConfig(
            type: InputItemLeadingTailingType.icon,
            icon: LoftifyIcons.verification,
          ),
          tailingConfig: InputItemLeadingTailingConfig(
            type: InputItemLeadingTailingType.text,
            text: '获取验证码',
          ),
        ),
      ),
    );

    final action = tester.widget<Text>(find.text('获取验证码'));
    expect(action.maxLines, 1);
    expect(tester.takeException(), isNull);
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      extensions: const <ThemeExtension<dynamic>>[
        ChewieIconThemeData.standard,
      ],
    ),
    home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
  );
}
