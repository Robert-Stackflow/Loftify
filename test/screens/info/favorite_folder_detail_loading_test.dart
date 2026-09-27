import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/favorite_folder_detail_screen.dart';
import 'package:loftify/Screens/Download/batch_download_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/Widgets/PostItem/general_post_item_builder.dart';
import 'package:loftify/Widgets/PostItem/loftify_post_archive_grid.dart';
import 'package:loftify/Widgets/loftify_icons.dart';
import 'package:loftify/l10n/l10n.dart';

class _Cookies extends Fake implements CookieManager {}

void main() {
  final pending = <RequestInterceptorHandler>[];
  final options = <RequestOptions>[];
  setUpAll(() async {
    final dir = Directory('build/test_hive/favorite_folder_detail_loading');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    RequestUtil.cookieManager = _Cookies();
    chewieProvider.stateWidgetBuilder = LoftifyStateView.fromChewie;
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
    appProvider.token = 'favorite-detail-test-account';
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
      {Size size = const Size(390, 844),
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
        return const FavoriteFolderDetailScreen(favoriteFolderId: 42);
      }),
    ));
    await frames(tester);
  }

  void respond(int index, Map<String, dynamic> data) => pending[index]
      .resolve(Response(requestOptions: options[index], data: data));

  Map<String, dynamic> post(int id, int opTime) => {
        'liked': false,
        'opTime': opTime,
        'postData': {
          'postView': {
            'id': id,
            'blogId': 1,
            'publisherUserId': 1,
            'type': 1,
            'title': 'Story $id',
          },
          'postCountView': <String, dynamic>{},
          'blogInfo': {
            'blogId': 1,
            'blogName': 'author',
            'blogNickName': 'Author',
            'bigAvaImg': '',
          },
        },
      };

  Map<String, dynamic> success(List<Map<String, dynamic>> posts,
          {int total = 3}) =>
      {
        'code': 0,
        'data': {
          'folder': {
            'id': 42,
            'name': 'Reading list',
            'postCount': total,
            'tags': <String>[],
            'themes': <String>[],
          },
          'posts': posts,
        },
      };

  for (final size in [const Size(280, 480), const Size(720, 320)]) {
    for (final locale in [
      const Locale('en'),
      const Locale('zh'),
      const Locale('zh', 'TW')
    ]) {
      testWidgets('detail states fit $size $locale', (tester) async {
        await mount(tester, size: size, locale: locale, textScale: 2);
        expect(tester.takeException(), isNull);
        respond(0, {'code': 503, 'msg': 'Unavailable'});
        await frames(tester);
        final error =
            tester.widget<LoftifyStateView>(find.byType(LoftifyStateView));
        expect(error.visual, LoftifyStateVisual.error);
        final retry = find.text(error.actionLabel!);
        await tester.ensureVisible(retry);
        await frames(tester);
        await tester.tap(retry);
        await frames(tester);
        respond(1, success([post(1, 1704067200)], total: 1));
        await frames(tester);
        expect(find.byType(GridPostItemWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('detail retries timeout and keeps refresh widget',
      (tester) async {
    await mount(tester);
    final refreshState = tester.state(find.byType(EasyRefresh));
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
    respond(1, success([], total: 0));
    await frames(tester);
    expect(tester.state(find.byType(EasyRefresh)), same(refreshState));
    expect(find.byType(EmptyPlaceholder), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail keeps month labels aligned through paging and refresh',
      (tester) async {
    await mount(tester);
    respond(0, success([post(1, 1704067200), post(2, 1706745600)]));
    await frames(tester);
    final january = formatLocalizedYearMonth(1704067200);
    final february = formatLocalizedYearMonth(1706745600);
    expect(
        tester.getTopLeft(find.textContaining(january, findRichText: true)).dy,
        lessThan(tester
            .getTopLeft(find.textContaining(february, findRichText: true))
            .dy));
    expect(find.byType(GridPostItemWidget), findsNWidgets(2));
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final load = Future.sync(refresh.onLoad!);
    await frames(tester);
    expect(options[1].queryParameters['offset'], '2');
    respond(1, success([post(2, 1706745600), post(3, 1706745600)]));
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
    final failedRefresh = Future.sync(refresh.onRefresh!);
    await frames(tester);
    respond(2, {'code': 503, 'msg': 'Unavailable'});
    await frames(tester);
    expect(await failedRefresh, IndicatorResult.fail);
    expect(find.byType(GridPostItemWidget), findsNWidgets(3));
    final fresh = Future.sync(refresh.onRefresh!);
    await frames(tester);
    respond(3, success([post(4, 1706745600)], total: 1));
    await frames(tester);
    expect(await fresh, IndicatorResult.success);
    expect(find.byType(GridPostItemWidget), findsOneWidget);
    expect(find.textContaining(january, findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail ignores response after leaving', (tester) async {
    await mount(tester);
    await tester.pumpWidget(const SizedBox());
    respond(0, success([post(1, 1704067200)]));
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail discards old account response', (tester) async {
    await mount(tester);
    respond(0, success([post(1, 1704067200)], total: 1));
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final result = Future.sync(refresh.onRefresh!);
    await frames(tester);
    appProvider.token = 'other-account';
    respond(1, success([post(9, 1706745600)], total: 1));
    await frames(tester);
    expect(await result, IndicatorResult.none);
    expect(find.byType(GridPostItemWidget), findsNothing);
    expect(
        tester.widget<LoftifyStateView>(find.byType(LoftifyStateView)).visual,
        LoftifyStateVisual.error);
    expect(tester.takeException(), isNull);
  });

  testWidgets('batch load fails visibly and retries remaining posts',
      (tester) async {
    await mount(tester);
    respond(0, success([post(1, 1704067200)]));
    await frames(tester);
    tester
        .widget<ChewieIconButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ChewieIconButton &&
                widget.icon == LoftifyIcons.download,
          ),
        )
        .onPressed!();
    await frames(tester);
    final batch = tester.widget<BatchDownloadScreen>(
      find.byType(BatchDownloadScreen),
    );
    expect(batch.initialItems, hasLength(1));
    final failedLoad = expectLater(batch.loadAllItems!(), throwsStateError);
    await frames(tester);
    expect(options[1].queryParameters['offset'], '1');
    respond(1, {'code': 503, 'msg': 'Unavailable'});
    await frames(tester);
    await failedLoad;
    final retry = batch.loadAllItems!();
    await frames(tester);
    expect(options[2].queryParameters['offset'], '1');
    respond(2, success([post(2, 1706745600), post(3, 1706745600)]));
    await frames(tester);
    expect((await retry).map((item) => item.postId), [1, 2, 3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('batch load rejects an incomplete server page', (tester) async {
    await mount(tester);
    respond(0, success([post(1, 1704067200)]));
    await frames(tester);
    tester
        .widget<ChewieIconButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ChewieIconButton &&
                widget.icon == LoftifyIcons.download,
          ),
        )
        .onPressed!();
    await frames(tester);
    final batch = tester.widget<BatchDownloadScreen>(
      find.byType(BatchDownloadScreen),
    );
    final result = expectLater(batch.loadAllItems!(), throwsStateError);
    await frames(tester);
    respond(1, success([]));
    await frames(tester);
    await result;
    expect(tester.takeException(), isNull);
  });
}
