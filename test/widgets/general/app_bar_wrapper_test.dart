import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/app_bar_wrapper',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('responsive app bar extends its color through one safe area',
      (tester) async {
    const background = Color(0xFF17202A);
    await tester.pumpWidget(
      _buildHost(
        (context) => Scaffold(
          appBar: const ResponsiveAppBar(
            title: 'Details',
            showBack: true,
            backgroundColor: background,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final responsiveAppBar = find.byType(ResponsiveAppBar);
    final coloredBox = tester.widget<ColoredBox>(
      find
          .descendant(of: responsiveAppBar, matching: find.byType(ColoredBox))
          .first,
    );
    final annotatedRegion =
        tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find
          .descendant(
            of: responsiveAppBar,
            matching: find.byWidgetPredicate(
              (widget) => widget is AnnotatedRegion<SystemUiOverlayStyle>,
            ),
          )
          .first,
    );

    expect(coloredBox.color, background);
    expect(annotatedRegion.value.statusBarColor, Colors.transparent);
    expect(annotatedRegion.value.statusBarIconBrightness, Brightness.light);
    expect(
      find.descendant(of: responsiveAppBar, matching: find.byType(SafeArea)),
      findsOneWidget,
    );
    expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
    final iconButton = find.byType(IconButton);
    final toolButton = find.byType(ToolButton);
    final target = iconButton.evaluate().isNotEmpty ? iconButton : toolButton;
    expect(tester.getSize(target), const Size.square(44));
    expect(
      tester.getSize(
        find.byKey(const ValueKey('chewie-icon-button-visual')),
      ),
      const Size.square(34),
    );
    expect(
      tester.widget<Icon>(find.byIcon(LucideIcons.arrowLeft)).size,
      18,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('app bar caps explicit actions without shrinking tap targets',
      (tester) async {
    await tester.pumpWidget(
      _buildHost(
        (context) => Scaffold(
          appBar: ResponsiveAppBar(
            title: 'Actions',
            showBack: true,
            actions: [
              ChewieIconButton(
                icon: LucideIcons.ellipsis,
                iconSize: 24,
                style: ChewieIconButtonStyle.soft,
                tooltip: 'More',
                onPressed: () {},
              ),
            ],
            landscapeActions: [
              ChewieIconButton(
                icon: LucideIcons.ellipsis,
                iconSize: 24,
                style: ChewieIconButtonStyle.soft,
                tooltip: 'More',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    for (final button in find.byType(IconButton).evaluate()) {
      expect(
        tester.getSize(find.byWidget(button.widget)),
        const Size.square(44),
      );
    }
    for (final visual
        in find.byKey(const ValueKey('chewie-icon-button-visual')).evaluate()) {
      expect(
        tester.getSize(find.byWidget(visual.widget)),
        const Size.square(34),
      );
    }
    expect(
      tester.widget<Icon>(find.byIcon(LucideIcons.ellipsis)).size,
      18,
    );
    expect(find.bySemanticsLabel('More'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('responsive app bar never paints a bottom divider',
      (tester) async {
    await tester.pumpWidget(
      _buildHost(
        (context) => const Scaffold(
          appBar: ResponsiveAppBar(
            title: 'Divider free',
            showBorder: true,
          ),
        ),
      ),
    );

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('responsive-app-bar-surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.border, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark app bar background uses light status icons',
      (tester) async {
    const background = Color(0xFF17202A);
    await tester.pumpWidget(
      _buildHost(
        (context) => const Scaffold(
          appBar: AppBarWrapper(
            title: Text('Details'),
            backgroundColor: background,
          ),
        ),
      ),
    );

    final appBar = tester.widget<MyAppBar>(find.byType(MyAppBar));
    expect(appBar.backgroundColor, background);
    expect(appBar.systemOverlayStyle?.statusBarColor, Colors.transparent);
    expect(
      appBar.systemOverlayStyle?.statusBarIconBrightness,
      Brightness.light,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('translucent app bar color uses its composited brightness',
      (tester) async {
    const tint = Color.fromARGB(30, 0, 120, 70);
    await tester.pumpWidget(
      _buildHost(
        (context) => const Scaffold(
          appBar: AppBarWrapper(
            title: Text('Tinted'),
            backgroundColor: tint,
          ),
        ),
      ),
    );

    final appBar = tester.widget<MyAppBar>(find.byType(MyAppBar));
    expect(
      appBar.systemOverlayStyle?.statusBarIconBrightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('image-backed sliver app bar defaults to light status icons',
      (tester) async {
    await tester.pumpWidget(
      _buildHost(
        (context) => Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBarWrapper(
                context: context,
                backgroundWidget: const ColoredBox(color: Colors.black),
                title: const Text('Profile'),
                actions: [
                  ChewieIconButton(
                    icon: LucideIcons.ellipsis,
                    tooltip: 'More',
                    onPressed: () {},
                  ),
                ],
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 600)),
            ],
          ),
        ),
      ),
    );

    final appBar = tester.widget<MySliverAppBar>(find.byType(MySliverAppBar));
    expect(
      appBar.systemOverlayStyle?.statusBarIconBrightness,
      Brightness.light,
    );
    expect(appBar.systemOverlayStyle?.statusBarColor, Colors.transparent);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('chewie-icon-button-visual')),
      ),
      const Size.square(34),
    );
    expect(tester.takeException(), isNull);
  });

  test('global system bar style follows theme brightness', () {
    final lightStyle = AppBarWrapper.systemUiOverlayStyleForBrightness(
      Brightness.light,
      includeNavigationBar: true,
    );
    final darkStyle = AppBarWrapper.systemUiOverlayStyleForBrightness(
      Brightness.dark,
      includeNavigationBar: true,
    );

    expect(lightStyle.statusBarIconBrightness, Brightness.dark);
    expect(lightStyle.systemNavigationBarIconBrightness, Brightness.dark);
    expect(darkStyle.statusBarIconBrightness, Brightness.light);
    expect(darkStyle.systemNavigationBarIconBrightness, Brightness.light);
    expect(lightStyle.statusBarColor, Colors.transparent);
    expect(lightStyle.systemNavigationBarColor, Colors.transparent);
  });
}

Widget _buildHost(Widget Function(BuildContext context) builder) {
  return MaterialApp(
    theme: ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
    ),
    home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: Builder(
        builder: (context) {
          chewieProvider.setRootContext(context);
          return builder(context);
        },
      ),
    ),
  );
}
