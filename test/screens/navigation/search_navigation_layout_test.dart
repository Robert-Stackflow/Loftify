import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Navigation/search_screen.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/generated/app_localizations.dart';

class _UnusedCookieManager extends Fake implements CookieManager {}

void main() {
  setUpAll(() async {
    final directory = Directory('build/test_hive/search_navigation_layout');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    RequestUtil.cookieManager = _UnusedCookieManager();
  });

  for (final showBack in [false, true]) {
    testWidgets(
        'search bar fills the available app bar width (back: $showBack)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      RequestUtil.instance.dio.interceptors.clear();
      RequestUtil.instance.dio.interceptors.add(
        InterceptorsWrapper(onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            data: {
              'code': 0,
              'data': {
                'guessKeywords': <Object>[],
                'rankList': <Object>[],
                'configList': <Object>[],
              },
            },
          ));
        }),
      );

      await tester.pumpWidget(MaterialApp(
        theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
        localizationsDelegates: const [
          ChewieLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          chewieProvider.setRootContext(context);
          return SearchScreen(showBack: showBack);
        }),
      ));
      await tester.pump(const Duration(seconds: 1));

      final rightEdge = tester
          .getTopRight(find.byKey(const ValueKey('search-navigation-bar')))
          .dx;
      final barWidth = tester
          .getSize(find.byKey(const ValueKey('search-navigation-bar')))
          .width;
      // Desktop app bars reserve a 44px trailing window-control area; compact
      // search bars should fill every remaining pixel instead of subtracting
      // another fixed-width action slot.
      final trailingSpace = ResponsiveUtil.isLandscapeLayout() ? 44.0 : 0.0;
      final leadingSpace = showBack ? 52.0 : 0.0;
      expect(rightEdge, greaterThanOrEqualTo(390 - trailingSpace - 1));
      expect(
          barWidth, greaterThanOrEqualTo(390 - trailingSpace - leadingSpace));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
