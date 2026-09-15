import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Setting/blacklist_setting_screen.dart';
import 'package:loftify/Screens/Setting/tagshield_setting_screen.dart';
import 'package:loftify/Screens/Setting/userdynamicshield_setting_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/generated/app_localizations.dart';

class _UnusedCookieManager extends Fake implements CookieManager {}

void main() {
  setUpAll(() async {
    final dir = Directory('build/test_hive/management_loading');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    RequestUtil.cookieManager = _UnusedCookieManager();
    appProvider.token = 'test-account';
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(40, false),
          hapticFeedback: true,
          triggerOffset: 56,
          maxOverOffset: 84,
          radius: 20,
        );
  });

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> mount(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return screen;
      }),
    ));
    await frames(tester);
  }

  for (final screen in [
    const BlacklistSettingScreen(),
    const TagShieldSettingScreen(),
    const UserDynamicShieldSettingScreen()
  ]) {
    testWidgets('${screen.runtimeType} ignores failed response after leaving',
        (tester) async {
      late RequestInterceptorHandler pending;
      late RequestOptions options;
      RequestUtil.instance.dio.interceptors.clear();
      RequestUtil.instance.dio.interceptors
          .add(InterceptorsWrapper(onRequest: (request, handler) {
        pending = handler;
        options = request;
      }));
      await mount(tester, screen);
      await tester.pumpWidget(const SizedBox());
      pending.resolve(Response(requestOptions: options, data: {
        'meta': {'status': 503, 'desc': 'Unavailable'},
        'code': 503,
        'desc': 'Unavailable',
      }));
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('${screen.runtimeType} can refresh after timeout',
        (tester) async {
      var requests = 0;
      RequestUtil.instance.dio.interceptors.clear();
      RequestUtil.instance.dio.interceptors
          .add(InterceptorsWrapper(onRequest: (options, handler) {
        requests++;
        if (requests == 1) {
          handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout));
        } else {
          handler.resolve(Response(requestOptions: options, data: {
            'meta': {'status': 200},
            'response': {'blogs': [], 'list': []},
            'code': 0,
            'data': {'blogInfos': []},
          }));
        }
      }));
      await mount(tester, screen);
      expect(requests, 1);
      final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
      final result = Future.sync(refresh.onRefresh!);
      await frames(tester);
      expect(await result, IndicatorResult.success);
      expect(requests, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
