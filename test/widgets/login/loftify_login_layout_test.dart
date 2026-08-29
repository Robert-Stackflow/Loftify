import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Login/loftify_login_layout.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

void main() {
  testWidgets('short large-text phone keeps every login action scrollable',
      (tester) async {
    var primaryTaps = 0;
    var methodTaps = 0;
    await tester.pumpWidget(
      _host(
        size: const Size(320, 360),
        textScaler: const TextScaler.linear(2),
        child: LoftifyLoginLayout(
          formChildren: const [
            TextField(decoration: InputDecoration(hintText: 'Account')),
            SizedBox(height: 10),
            TextField(decoration: InputDecoration(hintText: 'Password')),
            SizedBox(height: 120),
          ],
          primaryAction: ElevatedButton(
            key: const ValueKey('login-primary'),
            onPressed: () => primaryTaps++,
            child: const Text('Sign in'),
          ),
          alternativeTitle: 'Other sign-in methods can have a long title',
          alternativeMethods: [
            LoftifyLoginMethod(
              label: 'SMS code login',
              icon: LoftifyIcons.phone,
              onPressed: () => methodTaps++,
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('loftify-login-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const ValueKey('login-primary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('login-primary')));
    expect(primaryTaps, 1);

    final method = find.byTooltip('SMS code login');
    await tester.ensureVisible(method);
    await tester.pumpAndSettle();
    await tester.tap(method);
    expect(methodTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide login form is capped instead of stretching edge to edge',
      (tester) async {
    await tester.pumpWidget(
      _host(
        size: const Size(1000, 700),
        child: LoftifyLoginLayout(
          formChildren: const [TextField()],
          primaryAction: const SizedBox(height: 48),
          alternativeTitle: 'Other methods',
          alternativeMethods: [
            LoftifyLoginMethod(
              label: 'Password login',
              icon: LoftifyIcons.password,
              onPressed: _noop,
            ),
          ],
        ),
      ),
    );

    final fieldWidth = tester.getSize(find.byType(TextField)).width;
    expect(fieldWidth, lessThanOrEqualTo(520));
    expect(tester.takeException(), isNull);
  });

  test('all login screens use the shared non-overlay layout', () {
    for (final path in <String>[
      'lib/Screens/Login/login_by_captcha_screen.dart',
      'lib/Screens/Login/login_by_password_screen.dart',
      'lib/Screens/Login/login_by_lofterid_screen.dart',
      'lib/Screens/Login/login_by_mail_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('LoftifyLoginLayout('), reason: path);
      expect(source, isNot(contains('Positioned(')), reason: path);
      expect(source, isNot(contains('ToolButton(')), reason: path);
    }
  });
}

void _noop() {}

Widget _host({
  required Size size,
  required Widget child,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    home: Scaffold(
      body: Center(
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    ),
  );
}
