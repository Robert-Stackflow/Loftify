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

  testWidgets('discovery entrances preserve the compact illustration ratio',
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
    final size = tester.getSize(card);
    expect(size.height, inInclusiveRange(70, 96));
    expect(
      size.aspectRatio,
      moreOrLessEquals(
        LoftifyTagDiscoveryCard.illustrationAspectRatio,
        epsilon: 0.01,
      ),
    );
    final surface = tester.widget<AnimatedContainer>(
      find.descendant(of: card, matching: find.byType(AnimatedContainer)).first,
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, Colors.transparent);
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isEmpty);
    await tester.tap(card);
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discovery entrance stays compact and semantic in dark mode',
      (tester) async {
    await tester.pumpWidget(
      _TestApp(
        dark: true,
        child: Align(
          child: LoftifyTagDiscoveryCard(
            title: 'Related dress',
            description: '12 available looks',
            illustration: const ColoredBox(color: Colors.indigo),
            onTap: _noop,
          ),
        ),
      ),
    );
    await tester.pump();

    final card = find.byKey(
      const ValueKey('loftify-tag-discovery-card-Related dress'),
    );
    final size = tester.getSize(card);
    expect(size.height, LoftifyTagDiscoveryCard.minimumHeight);
    expect(size.width, lessThan(190));
    expect(find.text('Related dress'), findsOneWidget);
    expect(find.text('12 available looks'), findsOneWidget);
    final buttonSemantics = tester
        .widgetList<Semantics>(
          find.descendant(of: card, matching: find.byType(Semantics)),
        )
        .where((widget) => widget.properties.button == true);
    expect(buttonSemantics, hasLength(1));
    expect(buttonSemantics.single.properties.enabled, isTrue);
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
    this.dark = false,
  });

  final Widget child;
  final double width;
  final TextScaler textScaler;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: LoftifyTheme.build(
        dark
            ? ChewieThemeColorData.defaultDarkThemes.first
            : ChewieThemeColorData.defaultLightThemes.first,
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
