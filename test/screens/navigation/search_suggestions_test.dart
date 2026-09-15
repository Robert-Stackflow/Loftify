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
      {int joinCount = -1,
      bool ranked = false,
      String? rankName = 'Popular creative community'}) async {
    final (options, handler) = pending[index];
    handler.resolve(Response(requestOptions: options, data: {
      'code': 0,
      'data': {
        'items': [
          {
            'type': ranked ? 0 : 1,
            'tagInfo': {
              'tagName': label,
              'joinCount': joinCount,
              'subscribed': ranked,
              'rankName': ranked ? rankName : null,
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
    for (final width in [280.0, 720.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
            'user statistics remain visible at $width / $scale / $locale',
            (tester) async {
          await mount(tester,
              size: Size(width, 480), textScale: scale, locale: locale);
          await type(tester, 'author');
          final (options, handler) = pending.single;
          handler.resolve(Response(requestOptions: options, data: {
            'code': 0,
            'data': {
              'items': [
                {
                  'type': 2,
                  'blogData': {
                    'blogInfo': {
                      'blogName': 'a-very-long-creative-author-identifier',
                      'blogNickName':
                          'A creative author with a very long display name',
                    },
                    'blogCount': {
                      'publicPostCount': 123456789,
                      'followerCount': 987654321
                    },
                    'recommendReport': {'algInfo': '', 'recId': ''},
                  },
                }
              ]
            },
          }));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          final l10n =
              AppLocalizations.of(tester.element(find.byType(SearchScreen)))!;
          final followers = find.text('${l10n.follower}: 987654321');
          final posts = find.text('${l10n.article}: 123456789');
          expect(posts, findsOneWidget);
          expect(followers, findsOneWidget);
          await tester.ensureVisible(followers);
          await tester.pump();
          expect(followers.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
    testWidgets('ranked subscribed tag fits narrow large text in $locale',
        (tester) async {
      await mount(tester,
          size: const Size(280, 480), textScale: 2, locale: locale);
      await type(tester, 'art');
      await respond(tester, 0, 'Long creative tag name',
          joinCount: 123456789, ranked: true);
      expect(find.text('#Long creative tag name'), findsOneWidget);
      final context = tester.element(find.byType(SearchScreen));
      final enter = find.text(AppLocalizations.of(context)!.enter);
      await tester.ensureVisible(enter);
      await tester.pump();
      expect(enter.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
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

  testWidgets(
      'normal-sized ranked suggestion keeps the action beside its content',
      (tester) async {
    await mount(tester);
    await type(tester, 'art');
    await respond(tester, 0, 'art',
        joinCount: 15269, ranked: true, rankName: null);
    final title = find.text('#art');
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SearchScreen)))!;
    final action = find.text(l10n.enter);
    expect(
        tester.getRect(action).left, greaterThan(tester.getRect(title).right));
    expect(tester.getRect(action).bottom - tester.getRect(title).top,
        lessThan(90));
    expect(tester.takeException(), isNull);
  });

  testWidgets('suggestion scrolling reaches the navigation scroll listeners',
      (tester) async {
    await mount(tester);
    await type(tester, 'art');
    final (options, handler) = pending.single;
    handler.resolve(Response(requestOptions: options, data: {
      'code': 0,
      'data': {
        'items': List.generate(
            30,
            (index) => {
                  'type': 1,
                  'tagInfo': {
                    'tagName': 'Suggestion $index',
                    'subscribed': false,
                    'recommendReport': {'algInfo': '', 'recId': ''},
                  },
                })
      },
    }));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final state = tester.state<SearchScreenState>(find.byType(SearchScreen));
    var scrollUpdates = 0;
    void onScroll() => scrollUpdates++;
    final controllers = state.getScrollControllers();
    expect(controllers, hasLength(1));
    final navigation = OverlayEntry(
        builder: (_) => Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ScrollToHide.multi(
                scrollControllers: controllers,
                hideDirection: Axis.vertical,
                child:
                    const SizedBox(height: 50, child: Text('Navigation test')),
              ),
            ));
    Overlay.of(tester.element(find.byType(SearchScreen))).insert(navigation);
    await tester.pump();
    for (final controller in controllers) {
      controller.addListener(onScroll);
    }
    await tester.drag(find.text('Suggestion 1'), const Offset(0, -350));
    await tester.pump(const Duration(seconds: 1));
    expect(scrollUpdates, greaterThan(0));
    final visibility =
        tester.state<ScrollToHideState>(find.byType(ScrollToHide));
    expect(visibility.isShown, isFalse);
    await tester.drag(find.byType(ListView), const Offset(0, 100));
    await tester.pump(const Duration(seconds: 1));
    expect(visibility.isShown, isTrue);
    for (final controller in controllers) {
      controller.removeListener(onScroll);
    }
    navigation.remove();
    await tester.pump();
    navigation.dispose();
    await type(tester, '');
    expect(state.getScrollControllers(), hasLength(1));
    expect(
        state.getScrollControllers().single, isNot(same(controllers.single)));
    expect(tester.takeException(), isNull);
  });

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
