import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/panel_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    final directory = Directory('build/test_hive/panel_restore');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
  });

  test('hiding search preserves the logical page indices', () {
    expect(
      visiblePanelChoices(hideSearch: false),
      SideBarChoice.values,
    );
    final choices = visiblePanelChoices(hideSearch: true);
    expect(choices, [
      SideBarChoice.Home,
      SideBarChoice.Dynamic,
      SideBarChoice.Mine,
    ]);
    expect(choices[1].index, SideBarChoice.Dynamic.index);
    expect(choices[2].index, SideBarChoice.Mine.index);
    expect(choices.indexOf(SideBarChoice.Search), -1);
    expect(visiblePanelPageIndex(SideBarChoice.Home, hideSearch: true), 0);
    expect(visiblePanelPageIndex(SideBarChoice.Search, hideSearch: true), -1);
    expect(visiblePanelPageIndex(SideBarChoice.Dynamic, hideSearch: true), 1);
    expect(visiblePanelPageIndex(SideBarChoice.Mine, hideSearch: true), 2);
  });

  testWidgets('system back delegates to the nested panel when root pop is off',
      (tester) async {
    var nestedPopCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PanelBackScope(
          canRootPop: false,
          onNestedPop: () => nestedPopCount++,
          child: const SizedBox.expand(),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(nestedPopCount, 1);
  });

  testWidgets('completed root pop does not run nested panel cleanup',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var nestedPopCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Text('root'),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => PanelBackScope(
          canRootPop: true,
          onNestedPop: () => nestedPopCount++,
          child: const Text('nested route'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('nested route'), findsNothing);
    expect(find.text('root'), findsOneWidget);
    expect(nestedPopCount, 0);
  });

  for (final hideSearch in [false, true]) {
    testWidgets(
        'restored navigation page matches selected item (hide search: $hideSearch)',
        (tester) async {
      appProvider.hideSearchNavigation = hideSearch;
      appProvider.sidebarChoice = SideBarChoice.Dynamic;
      addTearDown(() {
        appProvider.sidebarChoice = SideBarChoice.Home;
        appProvider.hideSearchNavigation = false;
      });

      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: appProvider,
        child: MaterialApp(
          theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
          localizationsDelegates: const [
            ChewieLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) {
            chewieProvider.setRootContext(context);
            return const PanelScreen();
          }),
        ),
      ));
      final controller =
          tester.widget<PageView>(find.byType(PageView)).controller!;
      // Desktop always keeps the search page, regardless of the mobile setting.
      const expectedIndex = 2;
      expect(controller.initialPage, expectedIndex);
      await tester.pump();
      expect(controller.page, expectedIndex.toDouble());
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('layout changes restore search without changing the selected tab',
      (tester) async {
    var landscape = false;
    final originalProvider = appProvider;
    appProvider = AppProvider(isLandscapeLayout: () => landscape);
    appProvider.hideSearchNavigation = true;
    appProvider.sidebarChoice = SideBarChoice.Dynamic;
    addTearDown(() {
      appProvider.hideSearchNavigation = false;
      appProvider.sidebarChoice = SideBarChoice.Home;
      appProvider.dispose();
      appProvider = originalProvider;
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: appProvider,
      child: MaterialApp(
        theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
        localizationsDelegates: const [
          ChewieLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          chewieProvider.setRootContext(context);
          return const PanelScreen();
        }),
      ),
    ));
    await tester.pump();
    PageController controller() =>
        tester.widget<PageView>(find.byType(PageView)).controller!;
    expect(controller().page, 1);

    landscape = true;
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    await tester.pump();
    expect(controller().page, 2);
    expect(appProvider.sidebarChoice, SideBarChoice.Dynamic);
    expect(appProvider.hideSearchNavigation, isTrue);
    expect(appProvider.shouldHideSearchNavigation, isFalse);

    landscape = false;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    await tester.pump();
    expect(controller().page, 1);
    expect(appProvider.sidebarChoice, SideBarChoice.Dynamic);
    expect(appProvider.shouldHideSearchNavigation, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
