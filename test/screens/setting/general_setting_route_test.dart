import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Setting/general_setting_screen.dart';
import 'package:loftify/Screens/Setting/mobile_setting_navigation_screen.dart';
import 'package:loftify/Screens/Setting/setting_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
// Test-only fake for the platform interface supplied by path_provider.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';

class _TestPaths extends PathProviderPlatform {
  @override
  Future<String> getApplicationSupportPath() async =>
      Directory('build/test_hive/general_setting_routes/support').absolute.path;
}

void main() {
  setUpAll(() async {
    final directory = Directory('build/test_hive/general_setting_routes');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    final previousPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TestPaths();
    addTearDown(() => PathProviderPlatform.instance = previousPaths);
    PackageInfo.setMockInitialValues(
      appName: 'Loftify',
      packageName: 'com.test.loftify',
      version: '3.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final mobileEntry in [false, true]) {
    testWidgets('general settings routes own separate state ($mobileEntry)',
        (tester) async {
      final settings = Hive.box(ChewieHiveUtil.settingsBox);
      settings.put(HiveUtil.launchAtStartupKey, false);
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: appProvider,
        child: MaterialApp(
          navigatorKey: navigator,
          locale: const Locale('en'),
          theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            ChewieLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          home: Builder(builder: (context) {
            chewieProvider.setRootContext(context);
            return mobileEntry
                ? const MobileSettingNavigationScreen()
                : const SettingScreen();
          }),
        ),
      ));
      final openGeneral = tester
          .widget<EntryItem>(find.byWidgetPredicate(
              (widget) => widget is EntryItem && widget.title == 'General'))
          .onTap!;

      Future<void> open() async {
        openGeneral();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      }

      await open();
      final firstState = tester
          .state<GeneralSettingScreenState>(find.byType(GeneralSettingScreen));
      await open();
      final states = tester
          .stateList<GeneralSettingScreenState>(
              find.byType(GeneralSettingScreen, skipOffstage: false))
          .toList();
      expect(states, hasLength(2));
      expect(identical(states[0], states[1]), isFalse);
      expect(states, contains(firstState));

      // The tray writes this same setting. Both retained routes must observe it.
      settings.put(HiveUtil.launchAtStartupKey, true);
      await tester.pump();
      expect(states.every((state) => state.launchAtStartup), isTrue);

      // Reopen while the previous route's reverse transition is still mounted.
      navigator.currentState!.pop();
      await tester.pump(const Duration(milliseconds: 20));
      await open();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
      settings.put(HiveUtil.launchAtStartupKey, false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
