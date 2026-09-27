import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/grain_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/generated/app_localizations.dart';

class _Cookies extends Fake implements CookieManager {}

void main() {
  final pending = <RequestInterceptorHandler>[];
  final options = <RequestOptions>[];

  setUpAll(() async {
    final dir = Directory('build/test_hive/grain_screen_loading');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    await ChewieHiveUtil.put(HiveUtil.userInfoKey, {
      'blogId': 1,
      'blogName': 'author',
      'bigAvaImg': '',
      'homePageUrl': '',
      'imageDigitStamp': false,
      'imageProtected': false,
      'imageStamp': false,
      'isOriginalAuthor': false,
    });
    RequestUtil.cookieManager = _Cookies();
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(40, false),
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
    appProvider.token = 'grain-test-account';
    pending.clear();
    options.clear();
    RequestUtil.instance.dio.interceptors.clear();
    RequestUtil.instance.dio.interceptors.add(
      InterceptorsWrapper(onRequest: (request, handler) {
        options.add(request);
        pending.add(handler);
      }),
    );
  });

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    Locale locale = const Locale('en'),
    double textScale = 1,
    bool dark = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      locale: locale,
      theme: (dark
              ? ChewieThemeColorData.defaultDarkThemes.first
              : ChewieThemeColorData.defaultLightThemes.first)
          .toThemeData(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return GrainScreen();
      }),
    ));
    await frames(tester);
  }

  void respond(int index, Map<String, dynamic> data) => pending[index]
      .resolve(Response(requestOptions: options[index], data: data));

  Map<String, dynamic> grain(int id) => {
        'addPostTime': 0,
        'coverUrl': '',
        'createTime': 0,
        'endTime': 0,
        'exposure': 0,
        'greatLevel': 0,
        'hotCount': 0,
        'hotPlanType': 0,
        'id': id,
        'joinCount': 0,
        'lastSubscribeTime': 0,
        'name': 'A very long collection of stories $id',
        'planStatus': 0,
        'postCount': 120,
        'status': 0,
        'subscribedCount': 0,
        'tags': ['long-tag-name', 'another-long-tag-name'],
        'type': 0,
        'updateTime': 0,
        'userId': 1,
        'viewCount': 0,
      };

  testWidgets('first load timeout shows retry without replacing refresh state',
      (tester) async {
    await mount(tester);
    final original = tester.state(find.byType(EasyRefresh));
    expect(
      tester.widget<LoftifyStateView>(find.byType(LoftifyStateView)).visual,
      LoftifyStateVisual.loading,
    );
    pending[0].reject(DioException(
      requestOptions: options[0],
      type: DioExceptionType.connectionTimeout,
    ));
    await frames(tester);
    final error =
        tester.widget<LoftifyStateView>(find.byType(LoftifyStateView));
    expect(error.visual, LoftifyStateVisual.error);
    await tester.tap(find.text(error.actionLabel!));
    await frames(tester);
    expect(pending, hasLength(2));
    respond(1, {
      'code': 0,
      'data': {
        'total': 1,
        'grains': [grain(1)]
      },
    });
    await frames(tester);
    expect(tester.state(find.byType(EasyRefresh)), same(original));
    expect(find.text('A very long collection of stories 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grain loading and retry fit narrow dark large-text layout',
      (tester) async {
    await mount(tester,
        size: const Size(280, 480),
        locale: const Locale('zh', 'TW'),
        textScale: 2,
        dark: true);
    expect(tester.takeException(), isNull);
    pending[0].reject(DioException(
      requestOptions: options[0],
      type: DioExceptionType.connectionTimeout,
    ));
    await frames(tester);
    final error =
        tester.widget<LoftifyStateView>(find.byType(LoftifyStateView));
    expect(error.visual, LoftifyStateVisual.error);
    expect(find.text(error.actionLabel!).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed refresh keeps grain cards until a successful retry',
      (tester) async {
    await mount(tester);
    respond(0, {
      'code': 0,
      'data': {
        'total': 2,
        'grains': [grain(1)]
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final failed = Future.sync(refresh.onRefresh!);
    await frames(tester);
    respond(1, {'code': 503, 'msg': 'Unavailable'});
    await frames(tester);
    expect(await failed, IndicatorResult.fail);
    expect(find.text('A very long collection of stories 1'), findsOneWidget);
    final retry = Future.sync(refresh.onRefresh!);
    await frames(tester);
    respond(2, {
      'code': 0,
      'data': {
        'total': 1,
        'grains': [grain(2)]
      },
    });
    await frames(tester);
    expect(await retry, IndicatorResult.success);
    expect(find.text('A very long collection of stories 1'), findsNothing);
    expect(find.text('A very long collection of stories 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grain pagination advances raw offset and deduplicates IDs',
      (tester) async {
    await mount(tester);
    respond(0, {
      'code': 0,
      'data': {
        'total': 3,
        'grains': [grain(1)]
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final load = Future.sync(refresh.onLoad!);
    await frames(tester);
    expect(options[1].queryParameters['offset'], 1);
    respond(1, {
      'code': 0,
      'data': {
        'total': 3,
        'grains': [grain(1), grain(2)]
      },
    });
    await frames(tester);
    expect(await load, IndicatorResult.noMore);
    expect(find.text('A very long collection of stories 1'), findsOneWidget);
    expect(find.text('A very long collection of stories 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate-only grain page still advances to the next offset',
      (tester) async {
    await mount(tester);
    respond(0, {
      'code': 0,
      'data': {
        'total': 4,
        'grains': [grain(1)]
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final duplicatePage = Future.sync(refresh.onLoad!);
    await frames(tester);
    respond(1, {
      'code': 0,
      'data': {
        'total': 4,
        'grains': [grain(1)]
      },
    });
    await frames(tester);
    expect(await duplicatePage, IndicatorResult.success);
    final nextPage = Future.sync(refresh.onLoad!);
    await frames(tester);
    expect(options[2].queryParameters['offset'], 2);
    respond(2, {
      'code': 0,
      'data': {
        'total': 4,
        'grains': [grain(2), grain(3)]
      },
    });
    await frames(tester);
    expect(await nextPage, IndicatorResult.noMore);
    expect(find.text('A very long collection of stories 1'), findsOneWidget);
    expect(find.text('A very long collection of stories 2'), findsOneWidget);
    expect(find.text('A very long collection of stories 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh supersedes an unfinished grain pagination request',
      (tester) async {
    await mount(tester);
    respond(0, {
      'code': 0,
      'data': {
        'total': 3,
        'grains': [grain(1)]
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final stalePage = Future.sync(refresh.onLoad!);
    await frames(tester);
    final fresh = Future.sync(refresh.onRefresh!);
    await frames(tester);
    expect(pending, hasLength(3));
    expect(options[2].queryParameters['offset'], 0);
    respond(2, {
      'code': 0,
      'data': {
        'total': 1,
        'grains': [grain(9)]
      },
    });
    await frames(tester);
    expect(await fresh, IndicatorResult.success);
    respond(1, {
      'code': 0,
      'data': {
        'total': 3,
        'grains': [grain(2)]
      },
    });
    await frames(tester);
    expect(await stalePage, IndicatorResult.none);
    expect(find.text('A very long collection of stories 9'), findsOneWidget);
    expect(find.text('A very long collection of stories 2'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new account can load while the previous account is pending',
      (tester) async {
    await mount(tester);
    respond(0, {
      'code': 0,
      'data': {
        'total': 1,
        'grains': [grain(1)]
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final stale = Future.sync(refresh.onRefresh!);
    await frames(tester);
    appProvider.token = 'second-account';
    final current = Future.sync(refresh.onRefresh!);
    await frames(tester);
    expect(pending, hasLength(3));
    respond(2, {
      'code': 0,
      'data': {
        'total': 1,
        'grains': [grain(9)]
      },
    });
    await frames(tester);
    expect(await current, IndicatorResult.success);
    respond(1, {
      'code': 0,
      'data': {
        'total': 1,
        'grains': [grain(2)]
      },
    });
    await frames(tester);
    expect(await stale, IndicatorResult.none);
    expect(find.text('A very long collection of stories 1'), findsNothing);
    expect(find.text('A very long collection of stories 9'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grain response from old account is discarded', (tester) async {
    await mount(tester);
    respond(0, {
      'code': 0,
      'data': {
        'total': 1,
        'grains': [grain(1)]
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final stale = Future.sync(refresh.onRefresh!);
    await frames(tester);
    appProvider.token = 'another-account';
    respond(1, {
      'code': 0,
      'data': {
        'total': 1,
        'grains': [grain(9)]
      },
    });
    await frames(tester);
    expect(await stale, IndicatorResult.none);
    expect(find.text('A very long collection of stories 9'), findsNothing);
    expect(find.byType(LoftifyStateView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large grain list builds only nearby rows', (tester) async {
    await mount(tester);
    respond(0, {
      'code': 0,
      'data': {
        'total': 300,
        'grains': [for (var id = 1; id <= 300; id++) grain(id)],
      },
    });
    await frames(tester);
    expect(
      find
          .textContaining('A very long collection of stories')
          .evaluate()
          .length,
      lessThan(60),
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(280, 480), const Size(720, 320)]) {
    for (final locale in [
      const Locale('en'),
      const Locale('zh'),
      const Locale('zh', 'TW'),
    ]) {
      for (final dark in [false, true]) {
        testWidgets('grain card fits $size $locale dark=$dark at 2x text',
            (tester) async {
          await mount(tester,
              size: size, locale: locale, textScale: 2, dark: dark);
          respond(0, {
            'code': 0,
            'data': {
              'total': 1,
              'grains': [grain(1)]
            },
          });
          await frames(tester);
          expect(
              find.text('A very long collection of stories 1'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
