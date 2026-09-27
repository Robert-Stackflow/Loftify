import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/favorite_folder_list_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/Widgets/Favorite/favorite_folder_card.dart';
import 'package:loftify/generated/app_localizations.dart';

class _Cookies extends Fake implements CookieManager {}

void main() {
  final pending = <RequestInterceptorHandler>[];
  final options = <RequestOptions>[];

  setUpAll(() async {
    final dir = Directory('build/test_hive/favorite_folder_loading');
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
    appProvider.token = 'favorite-test-account';
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
      bool dark = false,
      double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      locale: locale,
      theme: (dark
              ? ChewieThemeColorData.defaultDarkThemes
              : ChewieThemeColorData.defaultLightThemes)
          .first
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
        return const FavoriteFolderListScreen();
      }),
    ));
    await frames(tester);
  }

  void respond(int index, Map<String, dynamic> data) => pending[index]
      .resolve(Response(requestOptions: options[index], data: data));

  Map<String, dynamic> folder(int id) => {
        'id': id,
        'name': 'Folder $id',
        'coverUrl': '',
        'postCount': 1,
        'isDefault': 0,
        'tags': <String>[],
        'themes': <String>[],
      };
  Map<String, dynamic> success(List<int> ids, {int total = 3}) => {
        'code': 0,
        'data': {
          'createCount': total,
          'folders': ids.map(folder).toList(),
        },
      };

  for (final size in [const Size(280, 480), const Size(720, 320)]) {
    for (final locale in [
      const Locale('en'),
      const Locale('zh'),
      const Locale('zh', 'TW')
    ]) {
      testWidgets('folder states fit $size $locale', (tester) async {
        await mount(tester, size: size, locale: locale, textScale: 2);
        expect(tester.takeException(), isNull);
        respond(0, {'code': 503, 'msg': 'Unavailable'});
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
        respond(1, success([1], total: 1));
        await frames(tester);
        expect(find.byType(LoftifyFavoriteFolderCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('folder paging appends, deduplicates, and refresh replaces',
      (tester) async {
    await mount(tester);
    expect(pending, hasLength(1));
    respond(0, success([1, 2]));
    await frames(tester);
    expect(find.byType(LoftifyFavoriteFolderCard), findsNWidgets(2));
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final load = Future.sync(refresh.onLoad!);
    await frames(tester);
    expect(pending, hasLength(2));
    expect(options[1].data, containsPair('offset', '2'));
    respond(1, success([2, 3]));
    await frames(tester);
    expect(await load, IndicatorResult.noMore);
    expect(find.byType(LoftifyFavoriteFolderCard), findsNWidgets(3));
    final failedRefresh = Future.sync(refresh.onRefresh!);
    await frames(tester);
    respond(2, {'code': 503, 'msg': 'Unavailable'});
    await frames(tester);
    expect(await failedRefresh, IndicatorResult.fail);
    expect(find.byType(LoftifyFavoriteFolderCard), findsNWidgets(3));
    final fresh = Future.sync(refresh.onRefresh!);
    await frames(tester);
    respond(3, success([4], total: 1));
    await frames(tester);
    expect(await fresh, IndicatorResult.success);
    expect(find.byType(LoftifyFavoriteFolderCard), findsOneWidget);
    expect(find.text('Folder 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('folder initial failure retries in the same refresh widget',
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
    respond(1, success([], total: 0));
    await frames(tester);
    expect(tester.state(find.byType(EasyRefresh)), same(original));
    expect(find.byType(EmptyPlaceholder), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('folder ignores late response after leaving', (tester) async {
    await mount(tester);
    await tester.pumpWidget(const SizedBox());
    respond(0, success([1]));
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('folder discards old account response', (tester) async {
    await mount(tester);
    respond(0, success([1], total: 1));
    await frames(tester);
    expect(find.byType(LoftifyFavoriteFolderCard), findsOneWidget);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final result = Future.sync(refresh.onRefresh!);
    await frames(tester);
    appProvider.token = 'other-account';
    respond(1, success([9], total: 1));
    await frames(tester);
    expect(await result, IndicatorResult.none);
    expect(find.byType(LoftifyFavoriteFolderCard), findsNothing);
    expect(
        tester.widget<LoftifyStateView>(find.byType(LoftifyStateView)).visual,
        LoftifyStateVisual.error);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed edit keeps the original folder name', (tester) async {
    await mount(tester);
    respond(0, success([1], total: 1));
    await frames(tester);
    tester
        .widget<LoftifyFavoriteFolderCard>(
          find.byType(LoftifyFavoriteFolderCard),
        )
        .onEdit();
    await frames(tester);
    final sheet =
        tester.widget<InputBottomSheet>(find.byType(InputBottomSheet));
    sheet.onConfirm!('Renamed folder');
    await frames(tester);
    expect(pending, hasLength(2));
    expect(find.text('Folder 1'), findsWidgets);
    respond(1, {'code': 503, 'msg': 'Unavailable'});
    await frames(tester);
    expect(find.text('Folder 1'), findsWidgets);
    expect(find.text('Renamed folder'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('successful edit changes only the matching folder',
      (tester) async {
    await mount(tester);
    respond(0, success([1, 2], total: 2));
    await frames(tester);
    tester
        .widgetList<LoftifyFavoriteFolderCard>(
          find.byType(LoftifyFavoriteFolderCard),
        )
        .first
        .onEdit();
    await frames(tester);
    final sheet =
        tester.widget<InputBottomSheet>(find.byType(InputBottomSheet));
    sheet.onConfirm!('Renamed folder');
    await frames(tester);
    expect(pending, hasLength(2));
    respond(1, {'code': 0, 'data': {}});
    await frames(tester);
    expect(find.text('Renamed folder'), findsOneWidget);
    expect(find.text('Folder 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deletion removes the card after server success', (tester) async {
    await mount(tester);
    respond(0, success([1, 2], total: 2));
    await frames(tester);
    tester
        .widgetList<LoftifyFavoriteFolderCard>(
          find.byType(LoftifyFavoriteFolderCard),
        )
        .first
        .onDelete!();
    await frames(tester);
    tester
        .widget<CustomConfirmDialogWidget>(
            find.byType(CustomConfirmDialogWidget))
        .onTapConfirm();
    await frames(tester);
    expect(pending, hasLength(2));
    expect(find.text('Folder 1'), findsWidgets);
    respond(1, {'code': 0, 'data': {}});
    await frames(tester);
    expect(find.text('Folder 1'), findsNothing);
    expect(find.text('Folder 2'), findsOneWidget);
    expect(pending, hasLength(3));
    respond(2, success([2], total: 1));
    await frames(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed creation can be retried without duplicate requests',
      (tester) async {
    await mount(tester);
    respond(0, success([], total: 0));
    await frames(tester);
    final dynamic state = tester.state(find.byType(FavoriteFolderListScreen));
    state.handleAdd();
    await frames(tester);
    final sheet =
        tester.widget<InputBottomSheet>(find.byType(InputBottomSheet));
    sheet.onConfirm!('New folder');
    sheet.onConfirm!('New folder');
    await frames(tester);
    expect(pending, hasLength(2));
    respond(1, {'code': 503, 'msg': 'Unavailable'});
    await frames(tester);
    expect(find.byType(EmptyPlaceholder), findsOneWidget);
    sheet.onConfirm!('New folder');
    await frames(tester);
    expect(pending, hasLength(3));
    respond(2, {'code': 0, 'data': {}});
    await frames(tester);
    expect(pending, hasLength(4));
    respond(3, success([3], total: 1));
    await frames(tester);
    expect(find.text('Folder 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
