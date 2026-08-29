import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/Design/loftify_controls.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/loftify_controls',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('localized button labels grow instead of overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        width: 240,
        textScaler: const TextScaler.linear(2),
        child: LoftifyButton(
          key: const Key('long-button'),
          label: 'Confirm this deliberately long localized operation safely',
          onPressed: () {},
          expand: true,
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('long-button'))).height,
      greaterThan(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('button exposes loading, success, warning and disabled states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: Column(
          children: [
            LoftifyButton(
              label: 'Loading',
              status: LoftifyControlStatus.loading,
              onPressed: () {},
            ),
            LoftifyButton(
              label: 'Success',
              status: LoftifyControlStatus.success,
              onPressed: () {},
            ),
            LoftifyButton(
              label: 'Warning',
              status: LoftifyControlStatus.warning,
              onPressed: () {},
            ),
            const LoftifyButton(label: 'Disabled'),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(LoftifyIcons.check), findsOneWidget);
    expect(find.byIcon(LoftifyIcons.warning), findsOneWidget);
    final disabledInkWell = tester.widget<InkWell>(
      find
          .descendant(
            of: find.widgetWithText(LoftifyButton, 'Disabled'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(disabledInkWell.onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('field focus and validation share semantic token states', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _TestApp(
        width: 260,
        textScaler: const TextScaler.linear(1.6),
        child: LoftifyTextField(
          key: const Key('field'),
          focusNode: focusNode,
          hintText: 'Enter a value that may use a long translation',
          status: LoftifyFieldStatus.error,
          statusText:
              'This explanatory validation message must remain fully readable.',
        ),
      ),
    );
    await tester.pump();

    final decorationBefore = _fieldDecoration(tester);
    expect(decorationBefore.border!.top.width, 1);
    expect(find.byIcon(LoftifyIcons.warning), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final decorationAfter = _fieldDecoration(tester);
    expect(decorationAfter.border!.top.width, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long filter labels wrap and preserve selected state', (
    tester,
  ) async {
    var selected = 'all';
    late StateSetter rebuild;
    await tester.pumpWidget(
      _TestApp(
        width: 220,
        textScaler: const TextScaler.linear(2),
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return LoftifyChoiceGroup<String>(
              values: const ['all', 'following'],
              selectedValue: selected,
              labelBuilder: (value) => value == 'all'
                  ? 'No limit'
                  : 'Creators followed by this account recently',
              onSelected: (value) {
                selected = value;
                rebuild(() {});
              },
            );
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Creators followed by this account recently'));
    await tester.pump();
    expect(selected, 'following');
    expect(find.byIcon(LoftifyIcons.check), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short filter choices remain inline before wrapping', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        width: 390,
        child: LoftifyChoiceGroup<String>(
          values: const ['all', 'text', 'images'],
          selectedValue: 'all',
          labelBuilder: (value) => value,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    final tags = find.byType(LoftifyTag);
    expect(tags, findsNWidgets(3));
    expect(tester.getTopLeft(tags.at(0)).dy, tester.getTopLeft(tags.at(1)).dy);
    expect(tester.getTopLeft(tags.at(1)).dy, tester.getTopLeft(tags.at(2)).dy);
    expect(tester.takeException(), isNull);
  });

  testWidgets('high contrast strengthens borders and reduced motion is instant',
      (tester) async {
    await tester.pumpWidget(
      _TestApp(
        mediaQuery: const MediaQueryData(
          size: Size(320, 640),
          highContrast: true,
          disableAnimations: true,
        ),
        child: LoftifyTag(
          key: const Key('tag'),
          label: 'Selected',
          selected: true,
          onPressed: _noop,
        ),
      ),
    );
    await tester.pump();

    final animated = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byKey(const Key('tag')),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final decoration = animated.decoration! as BoxDecoration;
    final colors = LoftifyDesignThemeData.of(
      tester.element(find.byKey(const Key('tag'))),
    ).colors;
    expect(animated.duration, Duration.zero);
    expect(decoration.border!.top.width, 2);
    expect(decoration.border!.top.color, colors.accentForeground);
    expect(tester.takeException(), isNull);
  });

  testWidgets('buttons, fields and tags resolve dark semantic surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        dark: true,
        child: Column(
          children: [
            LoftifyButton(
              key: const Key('dark-button'),
              label: 'Secondary',
              variant: LoftifyButtonVariant.secondary,
              onPressed: _noop,
            ),
            const LoftifyTextField(
              key: Key('dark-field'),
              hintText: 'Dark input',
            ),
            const LoftifyTag(
              key: Key('dark-tag'),
              label: 'Dark tag',
              selected: true,
              onPressed: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    final buttonDecoration = tester
        .widget<AnimatedContainer>(
          find
              .descendant(
                of: find.byKey(const Key('dark-button')),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        )
        .decoration! as BoxDecoration;
    final fieldDecoration = tester
        .widget<AnimatedContainer>(
          find
              .descendant(
                of: find.byKey(const Key('dark-field')),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        )
        .decoration! as BoxDecoration;
    expect(buttonDecoration.color, const Color(0xFF202421));
    expect(fieldDecoration.color, const Color(0xFF191C1A));
    expect(find.text('Dark tag'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

BoxDecoration _fieldDecoration(WidgetTester tester) {
  final animated = tester.widget<AnimatedContainer>(
    find
        .descendant(
          of: find.byKey(const Key('field')),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return animated.decoration! as BoxDecoration;
}

void _noop() {}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
    this.width = 390,
    this.textScaler = TextScaler.noScaling,
    this.mediaQuery,
    this.dark = false,
  });

  final Widget child;
  final double width;
  final TextScaler textScaler;
  final MediaQueryData? mediaQuery;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final data = mediaQuery ??
        MediaQueryData(
          size: Size(width, 800),
          textScaler: textScaler,
        );
    return MaterialApp(
      theme: LoftifyTheme.build(
        dark
            ? ChewieThemeColorData.defaultDarkThemes.first
            : ChewieThemeColorData.defaultLightThemes.first,
      ),
      home: MediaQuery(
        data: data,
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
