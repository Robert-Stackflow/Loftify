import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/Design/loftify_controls.dart';
import 'package:loftify/Widgets/Tag/tag_detail_components.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/tag_detail_components',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('tag hero stacks actions safely on narrow large-text layouts',
      (tester) async {
    var subscriptionTaps = 0;
    await tester.pumpWidget(
      _TestApp(
        width: 320,
        textScaler: const TextScaler.linear(2),
        child: LoftifyTagHero(
          tag: 'A deliberately long localized discovery tag',
          metrics: const [
            LoftifyTagMetric('Top discovery topic', emphasized: true),
            LoftifyTagMetric('4.5 million views'),
          ],
          subscribed: false,
          subscribeLabel: 'Subscribe to this tag',
          subscribedLabel: 'Subscribed',
          onSubscriptionPressed: () => subscriptionTaps++,
        ),
      ),
    );
    await tester.pump();

    final hero = find.byKey(const ValueKey('loftify-tag-hero'));
    expect(hero, findsOneWidget);
    expect(tester.getSize(hero).width, 320);
    expect(tester.getSize(hero).height, greaterThan(150));
    expect(find.text('Top discovery topic'), findsOneWidget);

    await tester.tap(find.text('Subscribe to this tag'));
    await tester.pump();
    expect(subscriptionTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unsubscribed and subscribed actions keep restrained states',
      (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: LoftifyTagHero(
          tag: 'Photography',
          metrics: const [],
          subscribed: false,
          subscribeLabel: 'Subscribe',
          subscribedLabel: 'Subscribed',
          onSubscriptionPressed: _noop,
        ),
      ),
    );
    await tester.pump();

    final lightDesign = LoftifyTheme.build(
      ChewieThemeColorData.defaultLightThemes.first,
    ).extension<LoftifyDesignThemeData>()!;
    final tonalDecoration = _buttonDecoration(tester, 'Subscribe');
    expect(tonalDecoration.color, lightDesign.colors.accentContainer);

    await tester.pumpWidget(
      _TestApp(
        child: LoftifyTagHero(
          tag: 'Photography',
          metrics: const [],
          subscribed: true,
          subscribeLabel: 'Subscribe',
          subscribedLabel: 'Subscribed',
          onSubscriptionPressed: _noop,
        ),
      ),
    );
    await tester.pump();
    final subscribedDecoration = _buttonDecoration(tester, 'Subscribed');
    expect(subscribedDecoration.color, lightDesign.colors.surfaceRaised);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discovery entrances grow for two-line localized descriptions',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _TestApp(
        width: 240,
        textScaler: const TextScaler.linear(2),
        child: Align(
          child: LoftifyTagDiscoveryCard(
            title: 'Related collections',
            description:
                'A long localized description that needs two complete lines',
            illustration: const ColoredBox(color: Colors.blue),
            onTap: () => taps++,
          ),
        ),
      ),
    );
    await tester.pump();

    final card = find.byKey(
      const ValueKey('loftify-tag-discovery-card-Related collections'),
    );
    expect(tester.getSize(card).width, 220);
    expect(tester.getSize(card).height, greaterThan(140));
    await tester.tap(card);
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}

BoxDecoration _buttonDecoration(WidgetTester tester, String label) {
  return tester
      .widget<AnimatedContainer>(
        find
            .descendant(
              of: find.widgetWithText(LoftifyButton, label),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      )
      .decoration! as BoxDecoration;
}

void _noop() {}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
    this.width = 390,
    this.textScaler = TextScaler.noScaling,
  });

  final Widget child;
  final double width;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: textScaler,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
