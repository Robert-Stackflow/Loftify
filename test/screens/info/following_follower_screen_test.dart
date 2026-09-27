import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Info/following_follower_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Design/loftify_controls.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';
import 'package:loftify/Widgets/Design/loftify_surfaces.dart';
import 'package:loftify/generated/app_localizations.dart';

class _Cookies extends Fake implements CookieManager {}

void main() {
  final pending = <RequestInterceptorHandler>[];
  final options = <RequestOptions>[];

  setUpAll(() async {
    final directory = Directory('build/test_hive/following_follower_screen');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
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
    appProvider.token = 'relation-test-account';
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
    FollowingMode mode = FollowingMode.following,
    int total = 1,
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
        return FollowingFollowerScreen(total: total, followingMode: mode);
      }),
    ));
    await frames(tester);
  }

  void respond(int index, List<Map<String, dynamic>> users) =>
      pending[index].resolve(Response(requestOptions: options[index], data: {
        'meta': {'status': 200},
        'response': users,
      }));

  Map<String, dynamic> user(int id) => {
        'blogId': id,
        'blogInfo': {
          'blogId': id,
          'blogName': 'author$id',
          'blogNickName': 'Creator $id',
          'bigAvaImg': '',
          'homePageUrl': '',
          'imageDigitStamp': false,
          'imageProtected': false,
          'imageStamp': false,
          'isOriginalAuthor': false,
        },
        'follower': true,
        'following': true,
      };

  testWidgets('timeout shows retry inside the same refresh container',
      (tester) async {
    await mount(tester);
    final original = tester.state(find.byType(EasyRefresh));
    expect(options.single.path, contains('userfollowing.api'));
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
    respond(1, [user(1)]);
    await frames(tester);
    expect(tester.state(find.byType(EasyRefresh)), same(original));
    expect(find.text('Creator 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('follower mode uses its endpoint and empty result is stable',
      (tester) async {
    await mount(tester, mode: FollowingMode.follower, total: 0);
    expect(options.single.path, contains('blogfollower.api'));
    respond(0, []);
    await frames(tester);
    expect(find.byType(LoftifyStateView), findsNothing);
    expect(find.byType(EmptyPlaceholder), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone relation items keep the action beside user details',
      (tester) async {
    await mount(tester);
    respond(0, [user(1)]);
    await frames(tester);
    final card = find.byType(LoftifyCard);
    final action = find.byType(LoftifyCompactToggleButton);
    expect(card, findsOneWidget);
    expect(action, findsOneWidget);
    expect(tester.getSize(card).height, lessThan(150));
    expect(tester.getTopLeft(action).dx,
        greaterThan(tester.getTopLeft(find.text('Creator 1')).dx));
    expect(tester.getTopLeft(action).dy,
        lessThan(tester.getBottomLeft(card).dy - 40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate-only page advances the raw server offset',
      (tester) async {
    await mount(tester, total: 4);
    respond(0, [user(1)]);
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final firstLoad = Future.sync(refresh.onLoad!);
    await frames(tester);
    expect(options[1].queryParameters['offset'], 1);
    respond(1, [user(1)]);
    await frames(tester);
    expect(await firstLoad, IndicatorResult.success);
    final secondLoad = Future.sync(refresh.onLoad!);
    await frames(tester);
    expect(options[2].queryParameters['offset'], 2);
    respond(2, [user(2), user(3)]);
    await frames(tester);
    expect(await secondLoad, IndicatorResult.noMore);
    expect(find.text('Creator 1'), findsOneWidget);
    expect(find.text('Creator 2'), findsOneWidget);
    expect(find.text('Creator 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'new refresh supersedes a pending page and keeps old cards on error',
      (tester) async {
    await mount(tester, total: 3);
    respond(0, [user(1)]);
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final load = Future.sync(refresh.onLoad!);
    await frames(tester);
    final newRefresh = Future.sync(refresh.onRefresh!);
    await frames(tester);
    expect(options[2].queryParameters['offset'], 0);
    pending[2].reject(DioException(
      requestOptions: options[2],
      type: DioExceptionType.connectionTimeout,
    ));
    await frames(tester);
    expect(await newRefresh, IndicatorResult.fail);
    expect(find.text('Creator 1'), findsOneWidget);
    respond(1, [user(2)]);
    await frames(tester);
    expect(await load, IndicatorResult.none);
    expect(find.text('Creator 2'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading and empty states fit narrow dark large-text layout',
      (tester) async {
    await mount(tester,
        size: const Size(280, 480),
        locale: const Locale('zh', 'TW'),
        textScale: 2,
        dark: true);
    expect(tester.takeException(), isNull);
    respond(0, []);
    await frames(tester);
    expect(find.byType(EmptyPlaceholder), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
