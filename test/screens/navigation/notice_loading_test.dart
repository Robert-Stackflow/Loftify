import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/system_notice_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/generated/app_localizations.dart';

class _UnusedCookieManager extends Fake implements CookieManager {}

void main() => noticeLoadingTests('all');

void noticeLoadingTests(String tab, {bool missingCache = false}) {
  setUpAll(() async {
    final dir =
        Directory('build/test_hive/notice_loading_${tab}_$missingCache');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    RequestUtil.cookieManager = _UnusedCookieManager();
    appProvider.token = 'test-account';
  });

  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return const SystemNoticeScreen();
      }),
    ));
    await pumpFrames(tester);
  }

  group(tab, () {
    setUpAll(() async {
      await ChewieHiveUtil.put(HiveUtil.systemNoticeTabIdKey, tab);
      await ChewieHiveUtil.put(
          HiveUtil.userInfoKey,
          missingCache
              ? <String, dynamic>{}
              : {
                  'blogId': 1,
                  'bigAvaImg': '',
                  'homePageUrl': '',
                  'imageDigitStamp': false,
                  'imageProtected': false,
                  'imageStamp': false,
                  'isOriginalAuthor': false,
                });
    });

    if (missingCache) {
      testWidgets('missing user cache ends refresh and releases loading lock',
          (tester) async {
        var requests = 0;
        RequestUtil.instance.dio.interceptors.clear();
        RequestUtil.instance.dio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            requests++;
            handler.reject(DioException(requestOptions: options));
          },
        ));
        await mount(tester);
        final refresh =
            tester.widget<EasyRefresh>(find.byType(EasyRefresh).first);
        for (var attempt = 0; attempt < 2; attempt++) {
          final result = Future.sync(refresh.onRefresh!);
          await pumpFrames(tester);
          expect(await result, IndicatorResult.fail);
        }
        expect(requests, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
      });
      return;
    }

    testWidgets('timeout releases loading lock and allows refresh',
        (tester) async {
      var requests = 0;
      RequestUtil.instance.dio.interceptors.clear();
      RequestUtil.instance.dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          requests++;
          expectSync(options.queryParameters['method'],
              tab == 'like' ? 'getNewLikeList' : 'getSystemNoticeList');
          if (requests == 1) {
            handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
            ));
          } else {
            handler.resolve(Response(requestOptions: options, data: {
              'meta': {'status': 200},
              'response': [],
            }));
          }
        },
      ));
      await mount(tester);
      expect(requests, 1);
      expect(tester.takeException(), isNull);
      final refresh =
          tester.widget<EasyRefresh>(find.byType(EasyRefresh).first);
      final result = Future.sync(refresh.onRefresh!);
      await pumpFrames(tester);
      expect(await result, IndicatorResult.success);
      expect(requests, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('response after dispose is ignored', (tester) async {
      late RequestInterceptorHandler pending;
      late RequestOptions options;
      RequestUtil.instance.dio.interceptors.clear();
      RequestUtil.instance.dio.interceptors.add(InterceptorsWrapper(
        onRequest: (request, handler) {
          pending = handler;
          options = request;
        },
      ));
      await mount(tester);
      await tester.pumpWidget(const SizedBox());
      pending.resolve(Response(requestOptions: options, data: {
        'meta': {'status': 503, 'desc': 'Unavailable'},
      }));
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    });
  });
}
