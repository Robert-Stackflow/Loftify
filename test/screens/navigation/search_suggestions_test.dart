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
  final pending = <(RequestOptions, RequestInterceptorHandler)>[];
  final initial = <(RequestOptions, RequestInterceptorHandler)>[];
  bool holdInitial = false;
  setUpAll(() async {
    final dir = Directory('build/test_hive/search_suggestions');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    RequestUtil.cookieManager = _UnusedCookieManager();
  });
  setUp(() {
    pending.clear();
    initial.clear();
    holdInitial = false;
    RequestUtil.instance.dio.interceptors.clear();
    RequestUtil.instance.dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) {
        if (options.path.endsWith('/sug.json')) {
          pending.add((options, handler));
        } else if (holdInitial) {
          initial.add((options, handler));
        } else {
          handler.resolve(Response(requestOptions: options, data: {
            'code': 0,
            'data': <String, dynamic>{},
          }));
        }
      }),
    );
  });
  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      navigatorKey: chewieProvider.globalNavigatorKey,
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return const SearchScreen();
      }),
    ));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> type(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextField), value);
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> respond(WidgetTester tester, int index, String label,
      {int joinCount = -1}) async {
    final (options, handler) = pending[index];
    handler.resolve(Response(requestOptions: options, data: {
      'code': 0,
      'data': {
        'items': [
          {
            'type': 1,
            'tagInfo': {
              'tagName': label,
              'joinCount': joinCount,
              'subscribed': false,
              'recommendReport': {'algInfo': '', 'recId': ''},
            }
          },
        ]
      },
    }));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'TW')
  ]) {
    testWidgets('long tag suggestion fits narrow large-text layout in $locale',
        (tester) async {
      await mount(tester,
          size: const Size(280, 480), textScale: 2, locale: locale);
      await type(tester, 'art');
      const label = 'A long creative community tag with multiple interests';
      await respond(tester, 0, label, joinCount: 123456789);
      expect(find.text(label).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('late suggestion cannot replace the newer query', (tester) async {
    await mount(tester);
    await type(tester, 'old');
    await type(tester, 'new');
    expect(pending.length, 2);
    await respond(tester, 1, 'new result');
    expect(find.text('new result'), findsOneWidget);
    await respond(tester, 0, 'old result');
    expect(find.text('new result'), findsOneWidget);
    expect(find.text('old result'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial requests completing after disposal do not create tabs',
      (tester) async {
    holdInitial = true;
    await mount(tester);
    expect(initial.length, 2);
    await tester.pumpWidget(const SizedBox());
    for (final (options, handler) in initial) {
      handler.resolve(Response(requestOptions: options, data: {
        'code': 0,
        'data': {'guessKeywords': [], 'rankList': [], 'configList': []},
      }));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed initial requests can be retried successfully',
      (tester) async {
    holdInitial = true;
    await mount(tester);
    for (final (options, handler) in initial) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      ));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    final state = tester.state<SearchScreenState>(find.byType(SearchScreen));
    final retries =
        Future.wait([state.fetchGuessList(), state.fetchRankList()]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(initial.length, 4);
    for (final (options, handler) in initial.skip(2)) {
      handler.resolve(Response(requestOptions: options, data: {
        'code': 0,
        'data': {'guessKeywords': [], 'rankList': [], 'configList': []},
      }));
    }
    await tester.pump(const Duration(milliseconds: 100));
    await retries;
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
  testWidgets('clearing and retyping invalidates even the same query',
      (tester) async {
    await mount(tester);
    await type(tester, 'same');
    await type(tester, '');
    await type(tester, 'same');
    await respond(tester, 0, 'stale result');
    expect(find.text('stale result'), findsNothing);
    await respond(tester, 1, 'fresh result');
    expect(find.text('fresh result'), findsOneWidget);
    await type(tester, '');
    expect(find.text('fresh result'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'cleared query ignores late failure and accepts subsequent results',
      (tester) async {
    await mount(tester);
    await type(tester, 'obsolete');
    await type(tester, '');
    final (options, handler) = pending.single;
    handler.reject(DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await type(tester, 'retry');
    await respond(tester, 1, 'retry result');
    expect(find.text('retry result'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('selection does not request again and disposal ignores response',
      (tester) async {
    await mount(tester);
    await type(tester, 'query');
    final field = tester.widget<TextField>(find.byType(TextField));
    field.controller!.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(pending.length, 1);
    await tester.pumpWidget(const SizedBox());
    await respond(tester, 0, 'late result');
    expect(tester.takeException(), isNull);
  });
}
