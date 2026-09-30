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

  for (final width in [390.0, 985.0, 1440.0]) {
    for (final showBack in [false, true]) {
      testWidgets(
          'search bar uses responsive placement at $width (back: $showBack)',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
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
        final bar = find.byKey(const ValueKey('search-navigation-bar'));
        if (ResponsiveUtil.isLandscapeLayout()) {
          expect(
              find.ancestor(of: bar, matching: find.byType(ResponsiveAppBar)),
              findsNothing);
          expect(barWidth, lessThanOrEqualTo(1180));
          expect(tester.getCenter(bar).dx, closeTo(width / 2, 1));
          expect(
              tester.getTopLeft(bar).dy,
              greaterThanOrEqualTo(
                  tester.getBottomLeft(find.byType(ResponsiveAppBar)).dy));
          if (width == 1440) expect(barWidth, 1180);
        } else {
          final trailingSpace =
              ResponsiveUtil.isDesktop() ? desktopWindowControlsWidth : 0.0;
          final leadingSpace = showBack ? 52.0 : 0.0;
          expect(rightEdge, closeTo(width - trailingSpace, 1));
          expect(barWidth, closeTo(width - trailingSpace - leadingSpace, 1));
          expect(
              find.ancestor(of: bar, matching: find.byType(ResponsiveAppBar)),
              findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}
