import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Navigation/dynamic_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/generated/app_localizations.dart';

class _UnusedCookieManager extends Fake implements CookieManager {}

void main() {
  var requests = 0;
  setUpAll(() async {
    final dir = Directory('build/test_hive/dynamic_locale');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    await ChewieHiveUtil.put(HiveUtil.dynamicTabIdKey, 'grain');
    RequestUtil.cookieManager = _UnusedCookieManager();
    appProvider.token = 'test-account';
    RequestUtil.instance.dio.interceptors.clear();
    RequestUtil.instance.dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) {
      requests++;
      handler.resolve(
          Response(requestOptions: options, data: {'code': 0, 'data': {}}));
    }));
  });

  Future<void> mount(WidgetTester tester, Locale locale, bool dark) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      theme: (dark
              ? ChewieThemeColorData.defaultDarkThemes.first
              : ChewieThemeColorData.defaultLightThemes.first)
          .toThemeData(),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return const DynamicScreen();
      }),
    ));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
        'dynamic navigation relocalizes without recreating tabs or loading again dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, const Locale('en'), dark);
      final state = tester.state(find.byType(DynamicScreen));
      final tabs = tester.widget<TabBar>(find.byType(TabBar)).controller!;
      final loadedRequests = requests;
      for (final locale in [
        const Locale('zh'),
        const Locale('zh', 'TW'),
        const Locale('en')
      ]) {
        await mount(tester, locale, dark);
        final l10n =
            AppLocalizations.of(tester.element(find.byType(DynamicScreen)))!;
        for (final label in [
          l10n.follow,
          l10n.tag,
          l10n.collection,
          l10n.grain
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        expect(tester.state(find.byType(DynamicScreen)), same(state));
        expect(
            tester.widget<TabBar>(find.byType(TabBar)).controller, same(tabs));
        expect(tabs.index, 3);
        expect(requests, loadedRequests);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    });
  }
}
