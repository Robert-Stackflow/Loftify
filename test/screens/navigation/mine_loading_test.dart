import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Navigation/mine_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/cloud_control_provider.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:provider/provider.dart';

// RequestUtil requires a cookie interceptor at construction. These tests replace
// all interceptors before making requests, so no cookie storage is used.
class _UnusedCookieManager extends Fake implements CookieManager {}

void main() {
  late RequestInterceptorHandler pending;
  late RequestOptions options;
  late int requests;

  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/mine_loading',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    RequestUtil.cookieManager = _UnusedCookieManager();
  });

  setUp(() {
    appProvider.token = 'test-account';
    requests = 0;
    RequestUtil.instance.dio.interceptors.clear();
    RequestUtil.instance.dio.interceptors.add(
      InterceptorsWrapper(onRequest: (request, handler) {
        requests++;
        options = request;
        pending = handler;
      }),
    );
  });

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controlProvider,
        child: MaterialApp(
          locale: const Locale('en'),
          navigatorKey: chewieProvider.globalNavigatorKey,
          theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
          localizationsDelegates: const [
            ChewieLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) {
            chewieProvider.setRootContext(context);
            return const MineScreen();
          }),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(requests, 1);
    expect(options.path, '/v1.1/usercounts.api');
  }

  testWidgets(
      'fixed actions remain available while profile is pending or fails',
      (tester) async {
    await mount(tester);
    final label = AppLocalizations.of(
      tester.element(find.byType(MineScreen)),
    )!
        .downloadManagement;
    expect(find.text(label), findsOneWidget);
    pending.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: {
        'meta': {'status': 503, 'desc': 'Unavailable'}
      },
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(label), findsOneWidget);
    expect(requests, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('network timeout ends refresh and permits another attempt',
      (tester) async {
    await mount(tester);
    pending.reject(DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final result = refresh.onRefresh!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(requests, 2);
    pending.reject(DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    ));
    await tester.pump();
    expect(await result, IndicatorResult.fail);
    final retry = refresh.onRefresh!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(requests, 3);
    pending.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: {
        'meta': {'status': 503, 'desc': 'Unavailable'}
      },
    ));
    await tester.pump();
    expect(await retry, IndicatorResult.fail);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });

  for (final changeAccount in [false, true]) {
    testWidgets(
      'late response is ignored after ${changeAccount ? 'account changes' : 'disposal'}',
      (tester) async {
        await mount(tester);
        if (changeAccount) {
          appProvider.token = 'different-test-account';
        } else {
          await tester.pumpWidget(const SizedBox.shrink());
        }
        // A malformed successful payload must never be parsed once obsolete.
        pending.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'meta': {'status': 200},
            'response': null
          },
        ));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(requests, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 5));
      },
    );
  }
}
