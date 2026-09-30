import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUpAll(() async {
    final dir = Directory('build/test_hive/update_log_layout');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    PackageInfo.setMockInitialValues(
      appName: 'Loftify',
      packageName: 'com.test.loftify',
      version: '3.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('changelog app bar back only pops the nested page',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final nestedNavigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
      localizationsDelegates: const [ChewieLocalizations.delegate],
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return Scaffold(
          body: Navigator(
            key: nestedNavigator,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('About page')),
            ),
          ),
        );
      }),
    ));
    for (var i = 0; i < 2; i++) {
      nestedNavigator.currentState!
          .push(RouteUtil.getFadeRoute(const UpdateLogScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(nestedNavigator.currentState!.canPop(), isTrue);
      await tester.tap(find.byWidgetPredicate((widget) =>
          widget is ChewieIconButton && widget.icon == ChewieIcons.back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(UpdateLogScreen), findsNothing);
      expect(find.text('About page'), findsOneWidget);
      expect(nestedNavigator.currentState!.canPop(), isFalse);
      expect(chewieProvider.globalNavigatorKey.currentState, isNotNull);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  for (final width in [390.0, 1000.0]) {
    testWidgets('selectable changelog timeline lays out at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
        localizationsDelegates: const [ChewieLocalizations.delegate],
        home: Builder(builder: (context) {
          chewieProvider.setRootContext(context);
          return const Scaffold(body: Text('About'));
        }),
      ));
      navigator.currentState!.push(RouteUtil.getFadeRoute(Scaffold(
        body: ListView(children: [
          UpdateLogTimeline(
            isLast: false,
            marker: const SizedBox(width: 14, height: 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('3.0.0'),
              SelectableAreaWrapper(
                focusNode: focus,
                child: CustomMarkdownWidget(
                  '# Changelog\n\n- A feature with enough text to wrap on a narrow screen.\n'
                  '- Another feature\n\n```dart\nfinal version = "3.0.0";\n```\n',
                ),
              ),
            ]),
          ),
          const UpdateLogTimeline(
            isLast: true,
            marker: SizedBox(width: 14, height: 14),
            child: Text('2.0.0'),
          ),
        ]),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final timeline = find.byType(UpdateLogTimeline).first;
      final line = find
          .descendant(of: timeline, matching: find.byType(Positioned))
          .first;
      expect(tester.getBottomLeft(line).dy, tester.getBottomLeft(timeline).dy);
      expect(tester.getSize(timeline).height, greaterThan(100));

      tester.view.physicalSize = Size(width + 180, 760);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
