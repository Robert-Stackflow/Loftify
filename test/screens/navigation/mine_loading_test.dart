import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Navigation/mine_screen.dart';
import 'package:loftify/Models/account_response.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/cloud_control_provider.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:provider/provider.dart';

// RequestUtil requires a cookie interceptor at construction. These tests replace
// all interceptors before making requests, so no cookie storage is used.
class _UnusedCookieManager extends Fake implements CookieManager {}

class _LongProfile extends Fake implements FullBlogInfo {
  @override
  String get blogNickName =>
      'A very long author name with several creative interests';
  @override
  String get blogName => 'a-very-long-author-id-with-many-characters';
  @override
  String get bigAvaImg => '';
  @override
  String get avatarBoxImage => '';
}

class _LargeCounts extends Fake implements MeInfoCount {
  @override
  int get hotCount => 987654321;
}

class _ProfileStatistics extends Fake implements MeInfoBlogInfo {
  @override
  int get attentionCount => 123456789;
  @override
  int get followerCount => 987654321;
  @override
  int get postCount => 123456789;
  @override
  MeInfoCount get hot => _LargeCounts();
}

class _LoadedStatistics extends Fake implements MeInfoData {
  @override
  MeInfoBlogInfo get blogInfo => _ProfileStatistics();
  @override
  int get collectionCount => 123456789;
}

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
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(40, false),
          hapticFeedback: true,
          triggerOffset: 56,
          maxOverOffset: 84,
          radius: 20,
        );
    EasyRefresh.defaultFooterBuilder = () => LottieCupertinoFooter(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(36, false),
          triggerOffset: 52,
          maxOverOffset: 76,
          infiniteOffset: 240,
          radius: 18,
        );
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

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    Locale locale = const Locale('en'),
    bool dark = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controlProvider,
        child: MaterialApp(
          locale: locale,
          navigatorKey: chewieProvider.globalNavigatorKey,
          theme: (dark
                  ? ChewieThemeColorData.defaultDarkThemes.first
                  : ChewieThemeColorData.defaultLightThemes.first)
              .toThemeData(),
          localizationsDelegates: const [
            ChewieLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
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

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'TW')
  ]) {
    for (final dark in [false, true]) {
      for (final size in [const Size(280, 480), const Size(720, 480)]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
              'loaded profile fits $size $locale dark=$dark at ${scale}x text',
              (tester) async {
            await mount(tester,
                size: size, textScale: scale, locale: locale, dark: dark);
            final dynamic state = tester.state(find.byType(MineScreen));
            state.setState(() {
              state.blogInfo = _LongProfile();
              state.meInfoData = _LoadedStatistics();
            });
            await tester.pump();
            expect(find.text(_LongProfile().blogNickName), findsOneWidget);
            final label =
                AppLocalizations.of(tester.element(find.byType(MineScreen)))!
                    .downloadManagement;
            await tester.scrollUntilVisible(find.text(label), 180,
                scrollable: find.byType(Scrollable).first);
            await tester.pump(const Duration(seconds: 1));
            await tester.ensureVisible(find.text(label));
            await tester.pump(const Duration(seconds: 1));
            expect(find.text(label).hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            pending.resolve(
                Response(requestOptions: options, statusCode: 200, data: {
              'meta': {'status': 503, 'desc': 'Unavailable'}
            }));
            await tester.pump(const Duration(seconds: 5));
          });
        }
      }
    }
  }

  testWidgets('narrow large-text profile keeps its actions reachable',
      (tester) async {
    await mount(tester, size: const Size(280, 480), textScale: 2);
    expect(tester.takeException(), isNull);
    final label = AppLocalizations.of(tester.element(find.byType(MineScreen)))!
        .downloadManagement;
    await tester.scrollUntilVisible(find.text(label), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.text(label));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(label).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.resolve(Response(requestOptions: options, statusCode: 200, data: {
      'meta': {'status': 503, 'desc': 'Unavailable'}
    }));
    await tester.pump(const Duration(seconds: 5));
  });

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
