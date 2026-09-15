import 'dart:io';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/history_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:loftify/Widgets/PostItem/general_post_item_builder.dart';
import 'package:loftify/Widgets/PostItem/loftify_post_archive_grid.dart';

class _Cookies extends Fake implements CookieManager {}

void main() {
  final pending = <RequestInterceptorHandler>[];
  final options = <RequestOptions>[];
  setUpAll(() async {
    final dir = Directory('build/test_hive/history_loading');
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
    appProvider.token = 'test-account';
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(40, false),
          triggerOffset: 56,
          maxOverOffset: 84,
          radius: 20,
        );
  });
  setUp(() {
    pending.clear();
    options.clear();
    RequestUtil.instance.dio.interceptors.clear();
    RequestUtil.instance.dio.interceptors
        .add(InterceptorsWrapper(onRequest: (request, handler) {
      options.add(request);
      pending.add(handler);
    }));
  });
  Future<void> frames(WidgetTester tester) async {
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
        ...AppLocalizations.localizationsDelegates
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return const HistoryScreen();
      }),
    ));
    await frames(tester);
  }

  void respond(int index, Map<String, dynamic> data) => pending[index]
      .resolve(Response(requestOptions: options[index], data: data));
  for (final categoryCounts in [
    <int>[],
    [1],
    [2, 1]
  ]) {
    testWidgets('history retains all rows with categories $categoryCounts',
        (tester) async {
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
                'isOriginalAuthor': false
              },
            }
          };
      Map<String, dynamic> response(List<int> ids,
              {bool includeCategories = true}) =>
          {
            'meta': {'status': 200},
            'response': {
              'count': 3,
              'recordHistory': 1,
              if (includeCategories)
                'archiveData': [
                  for (var i = 0; i < categoryCounts.length; i++)
                    {
                      'count': categoryCounts[i],
                      'desc': 'Category $i',
                      'startTime': 0,
                      'endTime': 1
                    }
                ],
              'items': ids.map(post).toList(),
            },
          };
      List<int> visibleIds() => tester
          .widgetList<GridPostItemWidget>(find.byType(GridPostItemWidget))
          .map((item) => item.item.postId)
          .toList();
      await mount(tester);
      respond(0, response([1, 2]));
      await frames(tester);
      expect(visibleIds(), [1, 2]);
      expect(
          tester
              .widgetList<LoftifyPostArchiveGrid>(
                  find.byType(LoftifyPostArchiveGrid))
              .every((grid) => grid.itemCount > 0),
          isTrue);
      final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
      final load = Future.sync(refresh.onLoad!);
      await frames(tester);
      expect(pending, hasLength(2));
      respond(1, response([3], includeCategories: false));
      await frames(tester);
      expect(await load, IndicatorResult.noMore);
      expect(visibleIds(), [1, 2, 3]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }

  for (final withCategories in [false, true]) {
    testWidgets(
        'clearing invalid history preserves categories present=$withCategories',
        (tester) async {
      await mount(tester);
      respond(0, {
        'meta': {'status': 200},
        'response': {
          'count': 4,
          'recordHistory': 1,
          'archiveData': withCategories
              ? [
                  for (var i = 0; i < 2; i++)
                    {
                      'count': 2,
                      'desc': 'Category $i',
                      'startTime': 0,
                      'endTime': 1
                    }
                ]
              : [],
          'items': [
            {
              'post': {'id': 1}
            },
            {
              'post': {'id': 2}
            },
            for (final id in [3, 4])
              {
                'post': {
                  'id': id,
                  'blogId': 1,
                  'publisherUserId': 1,
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
                    'isOriginalAuthor': false
                  },
                }
              },
          ],
        }
      });
      await frames(tester);
      final dynamic state = tester.state(find.byType(HistoryScreen));
      // Exercise local cleanup only; do not invoke the server's delete API.
      state.clearInvalidHistory();
      await frames(tester);
      expect(
          tester
              .widgetList<GridPostItemWidget>(find.byType(GridPostItemWidget))
              .map((widget) => widget.item.postId),
          [3, 4]);
      if (withCategories) {
        expect(find.textContaining('Category 0', findRichText: true),
            findsNothing);
        expect(find.textContaining('Category 1', findRichText: true),
            findsOneWidget);
      }
      state.clearInvalidHistory();
      await frames(tester);
      expect(
          tester
              .widgetList<LoftifyPostArchiveGrid>(
                  find.byType(LoftifyPostArchiveGrid))
              .map((grid) => grid.itemCount),
          [2]);
      expect(pending, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }

  for (final timeout in [false, true]) {
    testWidgets(
        'history retries without restarting initial refresh timeout=$timeout',
        (tester) async {
      await mount(tester);
      final refreshState = tester.state(find.byType(EasyRefresh));
      expect(
          tester.widget<LoftifyStateView>(find.byType(LoftifyStateView)).visual,
          LoftifyStateVisual.loading);
      expect(pending, hasLength(1));
      if (timeout) {
        pending.first.reject(DioException(
            requestOptions: options.first,
            type: DioExceptionType.connectionTimeout));
      } else {
        respond(0, {
          'meta': {'status': 503, 'desc': 'Unavailable'}
        });
      }
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
          'count': 0,
          'recordHistory': 1,
          'archiveData': [],
          'items': []
        }
      });
      await frames(tester);
      expect(tester.state(find.byType(EasyRefresh)), same(refreshState));
      expect(pending, hasLength(2));
      expect(find.byType(EmptyPlaceholder), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
  testWidgets('history ignores response after leaving', (tester) async {
    await mount(tester);
    await tester.pumpWidget(const SizedBox());
    respond(0, {
      'meta': {'status': 503, 'desc': 'Unavailable'}
    });
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
