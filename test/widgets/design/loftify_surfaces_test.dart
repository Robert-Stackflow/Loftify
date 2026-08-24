import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/BottomSheet/list_bottom_sheet.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/Widgets/Design/loftify_surfaces.dart';
import 'package:loftify/Widgets/Suit/dress_preview_card.dart';
import 'package:loftify/Widgets/loftify_icons.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:tuple/tuple.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/loftify_surfaces',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('card state matrix is token driven and ripple free', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _TestApp(
        width: 280,
        textScaler: const TextScaler.linear(2),
        mediaQuery: const MediaQueryData(
          size: Size(280, 800),
          textScaler: TextScaler.linear(2),
          highContrast: true,
          disableAnimations: true,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              LoftifyCard(
                key: const Key('normal-card'),
                onTap: () => taps++,
                child: const Text(
                  'A deliberately long English card title that must grow',
                ),
              ),
              const LoftifyCard(
                key: Key('selected-card'),
                status: LoftifySurfaceStatus.selected,
                child: Text('Selected'),
              ),
              const LoftifyCard(
                status: LoftifySurfaceStatus.success,
                child: Text('Success'),
              ),
              const LoftifyCard(
                status: LoftifySurfaceStatus.warning,
                child: Text('Warning'),
              ),
              const LoftifyCard(
                status: LoftifySurfaceStatus.error,
                child: Text('Error'),
              ),
              LoftifyCard(
                key: const Key('disabled-card'),
                status: LoftifySurfaceStatus.disabled,
                onTap: () {},
                child: const Text('Disabled'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LoftifyCard), findsNWidgets(6));
    final normalInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('normal-card')),
        matching: find.byType(InkWell),
      ),
    );
    expect(normalInkWell.splashFactory, NoSplash.splashFactory);
    expect(
      find.descendant(
        of: find.byKey(const Key('disabled-card')),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    final selectedDecoration = tester
        .widget<AnimatedContainer>(
          find.descendant(
            of: find.byKey(const Key('selected-card')),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .decoration! as BoxDecoration;
    expect(selectedDecoration.border!.top.width, 2);
    expect(
      tester
          .widget<AnimatedContainer>(
            find.descendant(
              of: find.byKey(const Key('selected-card')),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .duration,
      Duration.zero,
    );
    await tester.tap(
        find.text('A deliberately long English card title that must grow'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu rows preserve long copy, statuses and selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        width: 280,
        textScaler: const TextScaler.linear(2),
        child: SingleChildScrollView(
          child: Column(
            children: [
              LoftifyMenuItem(
                key: const Key('selected-menu'),
                label: 'Selected item with a long localized title',
                description:
                    'Supporting information remains below the title and wraps.',
                selected: true,
                onTap: _noop,
              ),
              LoftifyMenuItem(
                label: 'Danger',
                status: LoftifyMenuStatus.danger,
                showTrailing: false,
                onTap: _noop,
              ),
              const LoftifyMenuItem(
                key: Key('disabled-menu'),
                label: 'Disabled',
                showTrailing: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(LoftifyIcons.check), findsOneWidget);
    expect(find.byIcon(LoftifyIcons.next), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('selected-menu'))).height,
      greaterThan(48),
    );
    final disabledInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('disabled-menu')),
        matching: find.byType(InkWell),
      ),
    );
    expect(disabledInkWell.onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('panel corner and handle policy responds to window width', (
    tester,
  ) async {
    Future<BorderRadius> pump(double width) async {
      await tester.pumpWidget(
        _TestApp(
          width: width,
          child: const LoftifyPanel(
            title: 'Panel title',
            subtitle: 'A panel subtitle',
            body: Text('Body'),
          ),
        ),
      );
      await tester.pump();
      return tester
          .widget<ClipRRect>(
            find.descendant(
              of: find.byType(LoftifyPanel),
              matching: find.byType(ClipRRect),
            ),
          )
          .borderRadius as BorderRadius;
    }

    final compact = await pump(390);
    expect(find.byKey(const ValueKey('loftify-panel-handle')), findsOneWidget);
    expect(compact.bottomLeft.x, 0);
    final wide = await pump(700);
    expect(find.byKey(const ValueKey('loftify-panel-handle')), findsNothing);
    expect(wide.bottomLeft.x, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chewie page states share custom app feedback and retry', (
    tester,
  ) async {
    final previous = chewieProvider.stateWidgetBuilder;
    chewieProvider.stateWidgetBuilder = LoftifyStateView.fromChewie;
    addTearDown(() => chewieProvider.stateWidgetBuilder = previous);
    var retries = 0;

    await tester.pumpWidget(
      const _TestApp(
        child: LoadingWidget(size: 28, bottomPadding: 0),
      ),
    );
    await tester.pump();
    expect(find.byType(LoftifyStateView), findsOneWidget);
    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(
      _TestApp(
        child: EmptyPlaceholder(
          text: 'No saved works',
          topPadding: 24,
          onTap: () => retries++,
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(LoftifyIcons.empty), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();

    await tester.pumpWidget(
      _TestApp(
        child: CustomErrorWidget(
          text: 'Unable to load',
          onTap: () => retries++,
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(LoftifyIcons.error), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retries, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'state visuals cover non-loading feedback without system spinners', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        locale: Locale('zh', 'TW'),
        child: SingleChildScrollView(
          child: Column(
            children: [
              LoftifyStateView(
                visual: LoftifyStateVisual.empty,
                title: '暫無內容',
              ),
              LoftifyStateView(
                visual: LoftifyStateVisual.error,
                title: '載入失敗',
              ),
              LoftifyStateView(
                visual: LoftifyStateVisual.success,
                title: '操作成功',
              ),
              LoftifyStateView(
                visual: LoftifyStateVisual.warning,
                title: '請注意',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LoftifyStateView), findsNWidgets(4));
    expect(find.byIcon(LoftifyIcons.empty), findsOneWidget);
    expect(find.byIcon(LoftifyIcons.error), findsOneWidget);
    expect(find.byIcon(LoftifyIcons.check), findsOneWidget);
    expect(find.byIcon(LoftifyIcons.warning), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real dress card and option panel remain responsive on Windows', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    dynamic selected;
    await tester.pumpWidget(
      _TestApp(
        width: 320,
        textScaler: const TextScaler.linear(1.6),
        child: Builder(
          builder: (context) => SingleChildScrollView(
            child: Column(
              children: [
                const DressPreviewCard(
                  title: 'A responsive appearance preview card',
                  subtitle:
                      'Long descriptions remain readable across window sizes.',
                  badge: 'Preview',
                  previewHeight: 80,
                  preview: ColoredBox(color: Colors.teal),
                ),
                TileList.fromOptions(
                  const [Tuple2('Normal option', 1), Tuple2('Remove', 2)],
                  (value) => selected = value,
                  context: context,
                  selected: 1,
                  redOptions: const [2],
                  title: 'Options',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LoftifyCard), findsOneWidget);
    expect(find.byType(LoftifyPanel), findsOneWidget);
    expect(find.byType(LoftifyMenuItem), findsNWidgets(2));
    await tester.tap(find.text('Remove'));
    await tester.pump();
    expect(selected, 2);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('dark Android surfaces keep every semantic state distinct', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      const _TestApp(
        dark: true,
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            children: [
              LoftifyCard(
                key: Key('dark-flat'),
                child: Text('Flat'),
              ),
              LoftifyCard(
                key: Key('dark-outlined'),
                variant: LoftifyCardVariant.outlined,
                child: Text('Outlined'),
              ),
              LoftifyCard(
                key: Key('dark-raised'),
                variant: LoftifyCardVariant.raised,
                child: Text('Raised'),
              ),
              LoftifyCard(
                key: Key('dark-muted'),
                variant: LoftifyCardVariant.muted,
                child: Text('Muted'),
              ),
              LoftifyStateView(
                visual: LoftifyStateVisual.warning,
                title: 'Warning',
              ),
              LoftifyPanel(
                title: 'Actions',
                body: LoftifyMenuItem(
                  label: 'Destructive action',
                  status: LoftifyMenuStatus.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(Theme.of(tester.element(find.text('Flat'))).brightness,
        Brightness.dark);
    final decorations = <String, BoxDecoration>{
      for (final key in const [
        'dark-flat',
        'dark-outlined',
        'dark-raised',
        'dark-muted',
      ])
        key: tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration! as BoxDecoration,
    };
    expect(decorations['dark-outlined']!.border, isNotNull);
    expect(decorations['dark-raised']!.boxShadow, isNotEmpty);
    expect(decorations['dark-flat']!.color,
        isNot(decorations['dark-muted']!.color));
    expect(find.byKey(const ValueKey('loftify-panel-handle')), findsOneWidget);
    expect(find.byIcon(LoftifyIcons.warning), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}

void _noop() {}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
    this.width = 390,
    this.textScaler = TextScaler.noScaling,
    this.mediaQuery,
    this.locale = const Locale('en'),
    this.dark = false,
  });

  final Widget child;
  final double width;
  final TextScaler textScaler;
  final MediaQueryData? mediaQuery;
  final Locale locale;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final data = mediaQuery ??
        MediaQueryData(
          size: Size(width, 800),
          textScaler: textScaler,
        );
    final source = dark
        ? ChewieThemeColorData.defaultDarkThemes.first
        : ChewieThemeColorData.defaultLightThemes.first;
    return MaterialApp(
      locale: locale,
      theme: LoftifyTheme.build(source),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          chewieProvider.setRootContext(context);
          return MediaQuery(
            data: data,
            child: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(width: width, child: child),
              ),
            ),
          );
        },
      ),
    );
  }
}
