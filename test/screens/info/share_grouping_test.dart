import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/share_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/Widgets/PostItem/general_post_item_builder.dart';
import 'package:loftify/Widgets/PostItem/loftify_post_archive_grid.dart';
import 'package:loftify/generated/app_localizations.dart';

class _Cookies extends Fake implements CookieManager {}

void main() {
  final pending = <RequestInterceptorHandler>[];
  final options = <RequestOptions>[];
  setUpAll(() async {
    final dir = Directory('build/test_hive/share_grouping');
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
    appProvider.token = 'share-test-account';
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

  Future<void> mount(WidgetTester tester,
      {bool nested = false,
      Size size = const Size(390, 844),
      Locale locale = const Locale('en'),
      double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      locale: locale,
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return ShareScreen(nested: nested);
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
        }
      };

  for (final size in [const Size(280, 480), const Size(720, 320)]) {
    for (final locale in [
      const Locale('en'),
      const Locale('zh'),
      const Locale('zh', 'TW')
    ]) {
      testWidgets('recommend states fit $size $locale', (tester) async {
        await mount(tester, size: size, locale: locale, textScale: 2);
        expect(tester.takeException(), isNull);
        respond(0, {
          'meta': {'status': 503, 'msg': 'Unavailable'}
        });
        await frames(tester);
        final error =
            tester.widget<LoftifyStateView>(find.byType(LoftifyStateView));
        expect(error.visual, LoftifyStateVisual.error);
        expect(tester.takeException(), isNull);
        final retry = find.text(error.actionLabel!);
        await tester.ensureVisible(retry);
        await frames(tester);
        await tester.tap(retry);
        await frames(tester);
        respond(1, {
          'meta': {'status': 200},
          'response': {
            'count': 1,
            'items': [post(1)]
          },
        });
        await frames(tester);
        expect(find.byType(GridPostItemWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('equal monthly counts keep distinct month headings',
      (tester) async {
    await mount(tester);
    expect(pending, hasLength(1));
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 2,
        'archives': [
          {
            'year': 2024,
            'monthCount': [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          },
        ],
        'items': [post(1), post(2)],
      },
    });
    await frames(tester);
    final localizations =
        AppLocalizations.of(tester.element(find.byType(ShareScreen)))!;
    expect(
        find.textContaining(localizations.yearAndMonth(1, 2024),
            findRichText: true),
        findsOneWidget);
    expect(
        find.textContaining(localizations.yearAndMonth(2, 2024),
            findRichText: true),
        findsOneWidget);
    expect(find.byType(GridPostItemWidget), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing archive metadata still shows returned posts',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 2,
        'items': [post(1), post(2)]
      },
    });
    await frames(tester);
    expect(find.byType(GridPostItemWidget), findsNWidgets(2));
    expect(find.byType(LoftifyPostArchiveSliverGrid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short archive metadata leaves later posts visible',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 3,
        'archives': [
          {
            'year': 2024,
            'monthCount': [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          },
        ],
        'items': [post(1), post(2)],
      },
    });
    await frames(tester);
    expect(find.byType(GridPostItemWidget), findsNWidgets(2));
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final load = Future.sync(refresh.onLoad!);
    await frames(tester);
    respond(1, {
      'meta': {'status': 200},
      'response': {
        'count': 3,
        'items': [post(3)]
      },
    });
    await frames(tester);
    expect(await load, IndicatorResult.noMore);
    expect(find.byType(GridPostItemWidget), findsNWidgets(3));
    expect(
        tester
            .widgetList<LoftifyPostArchiveSliverGrid>(
              find.byType(LoftifyPostArchiveSliverGrid),
            )
            .map((grid) => grid.itemCount),
        [1, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large recommend group builds only nearby cells', (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 300,
        'archives': [
          {
            'year': 2024,
            'monthCount': [300, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          },
        ],
        'items': [for (var id = 1; id <= 300; id++) post(id)],
      },
    });
    await frames(tester);
    expect(find.byType(GridPostItemWidget).evaluate().length, lessThan(60));
    expect(
        tester
            .widget<LoftifyPostArchiveSliverGrid>(
              find.byType(LoftifyPostArchiveSliverGrid),
            )
            .itemCount,
        300);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recommend timeout retries in the same refresh container',
      (tester) async {
    await mount(tester);
    final original = tester.state(find.byType(EasyRefresh));
    expect(
        tester.widget<LoftifyStateView>(find.byType(LoftifyStateView)).visual,
        LoftifyStateVisual.loading);
    pending[0].reject(DioException(
        requestOptions: options[0], type: DioExceptionType.connectionTimeout));
    await frames(tester);
    final error =
        tester.widget<LoftifyStateView>(find.byType(LoftifyStateView));
    expect(error.visual, LoftifyStateVisual.error);
    await tester.tap(find.text(error.actionLabel!));
    await frames(tester);
    expect(pending, hasLength(2));
    respond(1, {
      'meta': {'status': 200},
      'response': {'count': 0, 'archives': [], 'items': []},
    });
    await frames(tester);
    expect(tester.state(find.byType(EasyRefresh)), same(original));
    expect(find.byType(EmptyPlaceholder), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('malformed refresh preserves existing recommendations',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 2,
        'items': [post(1), post(2)]
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final retry = Future.sync(refresh.onRefresh!);
    await frames(tester);
    respond(1, {
      'meta': {'status': 200},
      'response': {
        'count': 3,
        'items': [post(3), 42]
      },
    });
    await frames(tester);
    expect(await retry, IndicatorResult.fail);
    expect(
        tester
            .widgetList<GridPostItemWidget>(find.byType(GridPostItemWidget))
            .map((item) => item.item.postId),
        [1, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nested recommend view starts one request and retries',
      (tester) async {
    await mount(tester, nested: true);
    expect(pending, hasLength(1));
    respond(0, {
      'meta': {'status': 503, 'msg': 'Unavailable'}
    });
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
        'count': 1,
        'items': [post(1)]
      },
    });
    await frames(tester);
    expect(find.byType(GridPostItemWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recommend response from old account is discarded',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 1,
        'items': [post(1)]
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final result = Future.sync(refresh.onRefresh!);
    await frames(tester);
    appProvider.token = 'other-account';
    respond(1, {
      'meta': {'status': 200},
      'response': {
        'count': 1,
        'items': [post(9)]
      },
    });
    await frames(tester);
    expect(await result, IndicatorResult.none);
    expect(find.byType(GridPostItemWidget), findsNothing);
    expect(
        tester.widget<LoftifyStateView>(find.byType(LoftifyStateView)).visual,
        LoftifyStateVisual.error);
    expect(tester.takeException(), isNull);
  });
}
