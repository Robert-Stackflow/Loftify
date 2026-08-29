import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/Design/loftify_content_reference.dart';
import 'package:loftify/Widgets/Design/loftify_surfaces.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/content_reference',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  Widget buildApp(
    Widget child, {
    bool dark = false,
    double textScale = 1,
  }) {
    return MaterialApp(
      theme: LoftifyTheme.build(
        dark
            ? ChewieThemeColorData.defaultDarkThemes.first
            : ChewieThemeColorData.defaultLightThemes.first,
      ),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets(
      'content reference grows on a narrow screen with large localized text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var actionTaps = 0;
    var disabledTaps = 0;

    await tester.pumpWidget(
      buildApp(
        Padding(
          padding: const EdgeInsets.all(16),
          child: LoftifyContentReferenceCard(
            icon: LoftifyIcons.collection,
            eyebrow: 'Included in this collection',
            title: 'A deliberately long collection title that must wrap safely',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Subscribed to collection'),
            ),
            actions: [
              LoftifyContentReferenceAction(
                label: 'Already at the first post',
                enabled: false,
                onPressed: () {},
                onDisabledPressed: () => disabledTaps++,
              ),
              LoftifyContentReferenceAction(
                label: 'Open the complete catalogue',
                emphasized: true,
                onPressed: () => actionTaps++,
              ),
              LoftifyContentReferenceAction(
                label: 'Continue to the next post',
                onPressed: () {},
              ),
            ],
          ),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('content-reference-header-stacked')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('content-reference-actions-stacked')),
      findsOneWidget,
    );
    expect(find.byType(LoftifyCard), findsOneWidget);
    await tester.ensureVisible(find.text('Open the complete catalogue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open the complete catalogue'));
    await tester.ensureVisible(find.text('Already at the first post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Already at the first post'));
    await tester.pump();
    expect(actionTaps, 1);
    expect(disabledTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('content reference uses inline actions and semantic token colors',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final dark in <bool>[false, true]) {
      await tester.pumpWidget(
        buildApp(
          const Padding(
            padding: EdgeInsets.all(16),
            child: LoftifyContentReferenceCard(
              icon: LoftifyIcons.grain,
              eyebrow: 'Included in',
              title: 'A compact grain title',
              actions: [
                LoftifyContentReferenceAction(
                  label: 'Previous',
                  onPressed: _noop,
                ),
                LoftifyContentReferenceAction(
                  label: 'Catalogue',
                  emphasized: true,
                  onPressed: _noop,
                ),
                LoftifyContentReferenceAction(
                  label: 'Next',
                  onPressed: _noop,
                ),
              ],
            ),
          ),
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('content-reference-actions-inline')),
        findsOneWidget,
      );
      final iconContainer = tester.widget<Container>(
        find.byKey(const ValueKey('loftify-content-reference-icon')),
      );
      final decoration = iconContainer.decoration! as BoxDecoration;
      final theme = LoftifyTheme.build(
        dark
            ? ChewieThemeColorData.defaultDarkThemes.first
            : ChewieThemeColorData.defaultLightThemes.first,
      ).extension<LoftifyDesignThemeData>()!;
      expect(decoration.color, theme.colors.accentContainer);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('AppBar context pill stays compact and remains tappable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var taps = 0;

    await tester.pumpWidget(
      buildApp(
        Align(
          alignment: Alignment.topRight,
          child: LoftifyContextPill(
            icon: LoftifyIcons.collection,
            label: 'Collection 123/999 with extra context',
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pill = find.byKey(const ValueKey('loftify-context-pill'));
    expect(tester.getSize(pill).width, lessThanOrEqualTo(180));
    expect(tester.getSize(pill).height, greaterThanOrEqualTo(36));
    await tester.tap(pill);
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
