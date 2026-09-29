import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Lock/pin_change_screen.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/generated/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
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
          return MediaQuery(
            data: const MediaQueryData(
              size: Size(280, 480),
              textScaler: TextScaler.linear(2),
            ),
            child: child,
          );
        },
      ),
    );

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/pin_screen_layout',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  setUp(() async {
    await ChewieHiveUtil.put(HiveUtil.guesturePasswdKey, '');
    await ChewieHiveUtil.put(HiveUtil.enableBiometricKey, false);
  });

  testWidgets('gesture lock creation fits a narrow large-text screen',
      (tester) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const PinChangeScreen()));
    await tester.pump();

    expect(find.byType(GestureUnlockView), findsOneWidget);
    final gestureSize = tester.getSize(find.byType(GestureUnlockView));
    expect(gestureSize.width, greaterThanOrEqualTo(200));
    expect(
      gestureSize.width,
      moreOrLessEquals(gestureSize.height, epsilon: 0.5),
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
