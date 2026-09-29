import 'dart:io';
import 'dart:convert';

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
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';

class _UnusedCookieManager extends Fake implements CookieManager {}

Map<String, dynamic> _message(int id) {
  final author = {
    'blogId': id,
    'blogNickName': 'Creator $id',
    'blogName': 'creator$id',
    'bigAvaImg': '',
    'homePageUrl': '',
    'imageDigitStamp': false,
    'imageProtected': false,
    'imageStamp': false,
    'isOriginalAuthor': false,
  };
  return {
    'actUserBlogInfo': author,
    'blogInfo': author,
    'actUserId': id,
    'blogId': id,
    'commentLikeType': 0,
    'id': id,
    'publishTime': 1724918400000,
    'thumbnail': '',
    'type': 0,
    'defString': 'Creator $id recommended your story',
    'content': jsonEncode({
      'postViewRank': 0,
      'postUrl': '',
      'bigAvaImg': '',
      'blogNickName': 'Creator $id',
      'blogName': 'creator$id',
      'postPermalink': '',
      'postId': id,
      'postTitle': 'Story $id',
      'postType': 1,
      'isReblog': 0,
    }),
  };
}

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
    // Match the application's refresh indicators instead of the package's
    // text-based defaults, which are not used by Loftify.
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

  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool dark = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      theme: (dark
              ? ChewieThemeColorData.defaultDarkThemes.first
              : ChewieThemeColorData.defaultLightThemes.first)
          .toThemeData(),
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

    for (final size in [const Size(280, 320), const Size(720, 360)]) {
      for (final dark in [false, true]) {
        testWidgets('loading failure retry and empty fit $size dark=$dark',
            (tester) async {
          final pending = <RequestInterceptorHandler>[];
          final options = <RequestOptions>[];
          RequestUtil.instance.dio.interceptors.clear();
          RequestUtil.instance.dio.interceptors.add(InterceptorsWrapper(
            onRequest: (request, handler) {
              options.add(request);
              pending.add(handler);
            },
          ));
          await mount(tester, size: size, textScale: 2, dark: dark);
          expect(
              tester
                  .widget<LoftifyStateView>(find.byType(LoftifyStateView))
                  .visual,
              LoftifyStateVisual.loading);
          pending.first.resolve(Response(requestOptions: options.first, data: {
            'meta': {'status': 503, 'desc': 'Unavailable'},
          }));
          await pumpFrames(tester);
          final error =
              tester.widget<LoftifyStateView>(find.byType(LoftifyStateView));
          expect(error.visual, LoftifyStateVisual.error);
          expect(find.byType(SystemNoticeTabPlaceholder), findsNothing);
          final retry = find.text(error.actionLabel!);
          await tester.ensureVisible(retry);
          await pumpFrames(tester);
          expect(retry.hitTestable(), findsOneWidget);
          await tester.tap(retry);
          await pumpFrames(tester);
          expect(pending.length, 2);
          expect(
              tester
                  .widget<LoftifyStateView>(find.byType(LoftifyStateView))
                  .visual,
              LoftifyStateVisual.loading);
          pending.last.resolve(Response(requestOptions: options.last, data: {
            'meta': {'status': 200},
            'response': [],
          }));
          await pumpFrames(tester);
          expect(find.byType(SystemNoticeTabPlaceholder), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 5));
        });
      }
    }

    testWidgets('loaded rows survive failures and refresh replaces pagination',
        (tester) async {
      final pending = <RequestInterceptorHandler>[];
      final options = <RequestOptions>[];
      RequestUtil.instance.dio.interceptors.clear();
      RequestUtil.instance.dio.interceptors.add(InterceptorsWrapper(
        onRequest: (request, handler) {
          options.add(request);
          pending.add(handler);
        },
      ));
      void respond(List<dynamic> rows) => pending.last.resolve(Response(
            requestOptions: options.last,
            data: {
              'meta': {'status': 200},
              'response': rows
            },
          ));
      List<String> visibleAuthors() => tester
          .widgetList<SystemNoticeMessageTile>(
            find.byType(SystemNoticeMessageTile),
          )
          .map((tile) => tile.nickname)
          .toList();
      Future<dynamic> request({bool refresh = false}) {
        final widget =
            tester.widget<EasyRefresh>(find.byType(EasyRefresh).first);
        return Future.sync(refresh ? widget.onRefresh! : widget.onLoad!);
      }

      await mount(tester);
      respond([_message(1)]);
      await pumpFrames(tester);
      expect(visibleAuthors(), ['Creator 1']);
      final failedPage = request();
      await pumpFrames(tester);
      expect(options.last.queryParameters['offset'], 1);
      // A partially valid page must not append its first row before parsing fails.
      respond([_message(2), <String, dynamic>{}]);
      await pumpFrames(tester);
      expect(await failedPage, IndicatorResult.fail);
      expect(visibleAuthors(), ['Creator 1']);
      final retryPage = request();
      await pumpFrames(tester);
      expect(options.last.queryParameters['offset'], 1);
      respond([_message(2)]);
      await pumpFrames(tester);
      expect(await retryPage, IndicatorResult.success);
      expect(visibleAuthors(), ['Creator 1', 'Creator 2']);
      final failedRefresh = request(refresh: true);
      await pumpFrames(tester);
      expect(options.last.queryParameters['offset'], 0);
      respond([<String, dynamic>{}]);
      await pumpFrames(tester);
      expect(await failedRefresh, IndicatorResult.fail);
      expect(visibleAuthors(), ['Creator 1', 'Creator 2']);
      expect(find.byType(LoftifyStateView), findsNothing);
      final fresh = request(refresh: true);
      await pumpFrames(tester);
      respond([_message(3)]);
      await pumpFrames(tester);
      expect(await fresh, IndicatorResult.success);
      expect(visibleAuthors(), ['Creator 3']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

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

    for (final oldResponseFirst in [false, true]) {
      testWidgets(
          'refresh supersedes pending pagination oldFirst=$oldResponseFirst',
          (tester) async {
        final pending = <RequestInterceptorHandler>[];
        final options = <RequestOptions>[];
        RequestUtil.instance.dio.interceptors.clear();
        RequestUtil.instance.dio.interceptors.add(InterceptorsWrapper(
          onRequest: (request, handler) {
            options.add(request);
            pending.add(handler);
          },
        ));
        void respond(int index) => pending[index].resolve(Response(
              requestOptions: options[index],
              data: {
                'meta': {'status': 200},
                'response': []
              },
            ));
        await mount(tester);
        respond(0);
        await pumpFrames(tester);
        final refresh =
            tester.widget<EasyRefresh>(find.byType(EasyRefresh).first);
        final oldLoad = Future.sync(refresh.onLoad!);
        await pumpFrames(tester);
        expect(pending.length, 2);
        final newRefresh = Future.sync(refresh.onRefresh!);
        await pumpFrames(tester);
        expect(pending.length, 3);
        if (oldResponseFirst) {
          respond(1);
          await pumpFrames(tester);
          expect(await oldLoad, IndicatorResult.none);
          // The obsolete request must not release the new refresh's lock.
          final duplicateLoad = Future.sync(refresh.onLoad!);
          await pumpFrames(tester);
          expect(await duplicateLoad, IndicatorResult.none);
          expect(pending.length, 3);
          respond(2);
        } else {
          respond(2);
          await pumpFrames(tester);
          respond(1);
        }
        await pumpFrames(tester);
        expect(await newRefresh, IndicatorResult.success);
        expect(await oldLoad, IndicatorResult.none);
        // Pagination can run again after the fresh first page has completed.
        final nextLoad = Future.sync(refresh.onLoad!);
        await pumpFrames(tester);
        expect(pending.length, 4);
        respond(3);
        await pumpFrames(tester);
        expect(await nextLoad, IndicatorResult.noMore);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
        expect(tester.takeException(), isNull);
      });
    }

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
