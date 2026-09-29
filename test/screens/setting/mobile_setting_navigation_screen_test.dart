import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Setting/mobile_setting_navigation_screen.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/mobile_settings_navigation',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('mobile settings use the shared borderless scaffold',
      (tester) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
        navigatorKey: chewieProvider.globalNavigatorKey,
        localizationsDelegates: const [
          ChewieLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return const MediaQuery(
              data: MediaQueryData(
                size: Size(280, 480),
                textScaler: TextScaler.linear(2),
              ),
              child: MobileSettingNavigationScreen(),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final appBar = tester.widget<ResponsiveAppBar>(
      find.byType(ResponsiveAppBar),
    );
    expect(appBar.showBorder, isFalse);
    expect(find.byType(BlankIconButton), findsNothing);
    expect(find.byType(EntryItem), findsNWidgets(5));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
