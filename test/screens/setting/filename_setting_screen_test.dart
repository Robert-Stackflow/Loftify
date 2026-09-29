import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Setting/filename_setting_screen.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/filename_setting_screen',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('filename settings fit a narrow large-text screen',
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
              child: FilenameSettingScreen(showTitleBar: false),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(InputItem), findsOneWidget);
    expect(find.byType(CircleIconButton), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('filename-field-originalName')),
      findsOneWidget,
    );
    expect(find.byType(Table), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
