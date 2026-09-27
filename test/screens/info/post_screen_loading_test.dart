import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/post_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/Widgets/PostItem/loftify_post_archive_grid.dart';
import 'package:loftify/Widgets/PostItem/general_post_item_builder.dart';
import 'package:loftify/generated/app_localizations.dart';

class _Cookies extends Fake implements CookieManager {}

void main() {
  final pending = <RequestInterceptorHandler>[];
  final options = <RequestOptions>[];

  setUpAll(() async {
    final dir = Directory('build/test_hive/post_screen_loading');
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
    appProvider.token = 'post-test-account';
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
        return PostScreen();
      }),
    ));
    await frames(tester);
  }

  void respond(int index, Map<String, dynamic> data) => pending[index]
      .resolve(Response(requestOptions: options[index], data: data));

  Map<String, dynamic> post(int id) => {
        'post': {
          'id': id,
          'blogId': 1,
          'publisherUserId': 1,
          'type': 1,
          'title': 'Story $id',
          'blogInfo': {
            'blogId': 1,
            'blogName': 'author',
            'blogNickName': 'Author',
            'bigAvaImg': '',
            'homePageUrl': '',
            'imageDigitStamp': false,
            'imageProtected': false,
            'imageStamp': false,
            'isOriginalAuthor': false,
          },
        },
      };

  testWidgets('first post request timeout shows retry and can recover',
      (tester) async {
    await mount(tester);
    expect(pending, hasLength(1));
    final refreshState = tester.state(find.byType(EasyRefresh));
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
      'meta': {'status': 200},
      'response': {
        'posts': [post(1)]
      },
    });
    await frames(tester);
    expect(tester.state(find.byType(EasyRefresh)), same(refreshState));
    expect(find.byType(LoftifyPostArchiveSliverGrid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('posts render when archive metadata is absent', (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'posts': [post(1)]
      },
    });
    await frames(tester);
    expect(find.byType(LoftifyPostArchiveSliverGrid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('equal monthly post counts keep separate headings',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'archives': [
          {
            'year': 2024,
            'monthCount': [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          }
        ],
        'posts': [post(1), post(2)]
      },
    });
    await frames(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(PostScreen)))!;
    expect(find.textContaining(l10n.yearAndMonth(1, 2024)), findsOneWidget);
    expect(find.textContaining(l10n.yearAndMonth(2, 2024)), findsOneWidget);
    expect(find.byType(LoftifyPostArchiveSliverGrid), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinned post is not duplicated and does not shift page offset',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'topPost': post(1),
        'archives': [
          {
            'year': 2024,
            'monthCount': [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          }
        ],
        'posts': [post(1), post(2)]
      },
    });
    await frames(tester);
    final grids = tester
        .widgetList<LoftifyPostArchiveSliverGrid>(
          find.byType(LoftifyPostArchiveSliverGrid),
        )
        .toList();
    expect(grids.map((grid) => grid.itemCount), [1, 1]);
    expect(find.byType(GridPostItemWidget), findsNWidgets(2));
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final load = Future.sync(refresh.onLoad!);
    await frames(tester);
    expect(options[1].queryParameters['offset'], 2);
    respond(1, {
      'meta': {'status': 200},
      'response': {
        'posts': [post(3)]
      },
    });
    await frames(tester);
    expect(await load, IndicatorResult.success);
    expect(find.byType(GridPostItemWidget), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed post refresh preserves existing content', (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'posts': [post(1)]
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final failed = Future.sync(refresh.onRefresh!);
    await frames(tester);
    respond(1, {
      'meta': {'status': 503, 'msg': 'Unavailable'}
    });
    await frames(tester);
    expect(await failed, IndicatorResult.fail);
    expect(find.byType(GridPostItemWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('post refresh supersedes unfinished pagination', (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'posts': [post(1)]
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final stale = Future.sync(refresh.onLoad!);
    await frames(tester);
    final fresh = Future.sync(refresh.onRefresh!);
    await frames(tester);
    expect(pending, hasLength(3));
    respond(2, {
      'meta': {'status': 200},
      'response': {
        'posts': [post(9)]
      },
    });
    await frames(tester);
    expect(await fresh, IndicatorResult.success);
    respond(1, {
      'meta': {'status': 200},
      'response': {
        'posts': [post(2)]
      },
    });
    await frames(tester);
    expect(await stale, IndicatorResult.none);
    expect(find.byType(GridPostItemWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('old account post response cannot replace a new account',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'posts': [post(1)]
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
      'meta': {'status': 200},
      'response': {
        'posts': [post(9)]
      },
    });
    await frames(tester);
    expect(await current, IndicatorResult.success);
    respond(1, {
      'meta': {'status': 200},
      'response': {
        'posts': [post(2)]
      },
    });
    await frames(tester);
    expect(await stale, IndicatorResult.none);
    expect(find.byKey(const ValueKey(9)), findsOneWidget);
    expect(find.byKey(const ValueKey(1)), findsNothing);
    expect(find.byKey(const ValueKey(2)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('post error and retry fit narrow dark large-text layout',
      (tester) async {
    await mount(tester,
        size: const Size(280, 480),
        locale: const Locale('zh', 'TW'),
        textScale: 2,
        dark: true);
    expect(tester.takeException(), isNull);
    respond(0, {
      'meta': {'status': 503, 'msg': 'Unavailable'}
    });
    await frames(tester);
    final error =
        tester.widget<LoftifyStateView>(find.byType(LoftifyStateView));
    expect(error.visual, LoftifyStateVisual.error);
    expect(find.text(error.actionLabel!).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large ungrouped post archive is lazily built', (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'posts': [for (var id = 1; id <= 300; id++) post(id)]
      },
    });
    await frames(tester);
    expect(find.byType(GridPostItemWidget).evaluate().length, lessThan(45));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(280, 480), const Size(720, 320)]) {
    for (final locale in [
      const Locale('en'),
      const Locale('zh'),
      const Locale('zh', 'TW'),
    ]) {
      for (final dark in [false, true]) {
        testWidgets('post states fit $size $locale dark=$dark at 2x text',
            (tester) async {
          await mount(tester,
              size: size, locale: locale, textScale: 2, dark: dark);
          expect(tester.takeException(), isNull);
          respond(0, {
            'meta': {'status': 200},
            'response': {
              'posts': [post(1)]
            },
          });
          await frames(tester);
          expect(find.byType(LoftifyPostArchiveSliverGrid), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
