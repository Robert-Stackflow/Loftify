import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Download/batch_download_screen.dart';
import 'package:loftify/Screens/Info/like_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/PostItem/loftify_post_archive_grid.dart';
import 'package:loftify/generated/app_localizations.dart';

class _Cookies extends Fake implements CookieManager {}

void main() {
  final pending = <RequestInterceptorHandler>[];
  final options = <RequestOptions>[];

  setUpAll(() async {
    final dir = Directory('build/test_hive/like_batch_loading');
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
    appProvider.token = 'like-batch-test-account';
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
    InfoMode infoMode = InfoMode.me,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: chewieProvider.globalNavigatorKey,
      locale: locale,
      theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
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
        return LikeScreen(infoMode: infoMode, blogName: 'author');
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

  Future<BatchDownloadScreen> openBatchDownload(WidgetTester tester) async {
    tester.widget<ShadowIconButton>(find.byType(ShadowIconButton)).onTap!();
    await frames(tester);
    final label = AppLocalizations.of(
      tester.element(find.byType(LikeScreen)),
    )!
        .batchDownload;
    await tester.tap(find.text(label));
    await frames(tester);
    return tester.widget<BatchDownloadScreen>(find.byType(BatchDownloadScreen));
  }

  for (final size in [const Size(280, 480), const Size(720, 320)]) {
    for (final locale in [
      const Locale('en'),
      const Locale('zh'),
      const Locale('zh', 'TW'),
    ]) {
      testWidgets('like batch entry fits $size $locale at 2x text',
          (tester) async {
        await mount(tester, size: size, locale: locale, textScale: 2);
        respond(0, {
          'meta': {'status': 200},
          'response': {
            'count': 1,
            'items': [post(1)]
          },
        });
        await frames(tester);
        expect(tester.takeException(), isNull);
        final batch = await openBatchDownload(tester);
        expect(batch.initialItems.map((item) => item.postId), [1]);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('failed like batch page retries without returning a partial set',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 3,
        'items': [post(1)]
      },
    });
    await frames(tester);
    final batch = await openBatchDownload(tester);
    expect(batch.initialItems, hasLength(1));
    final failed = expectLater(batch.loadAllItems!(), throwsStateError);
    await frames(tester);
    expect(options[1].queryParameters['offset'], 1);
    respond(1, {
      'meta': {'status': 503, 'msg': 'Unavailable'}
    });
    await frames(tester);
    await failed;
    final retry = batch.loadAllItems!();
    await frames(tester);
    expect(options[2].queryParameters['offset'], 1);
    respond(2, {
      'meta': {'status': 200},
      'response': {
        'count': 3,
        'items': [post(2), post(3)]
      },
    });
    await frames(tester);
    expect((await retry).map((item) => item.postId), [1, 2, 3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('early empty like page is not considered fully loaded',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 3,
        'items': [post(1)]
      },
    });
    await frames(tester);
    final batch = await openBatchDownload(tester);
    final failed = expectLater(batch.loadAllItems!(), throwsStateError);
    await frames(tester);
    respond(1, {
      'meta': {'status': 200},
      'response': {'count': 3, 'items': []},
    });
    await frames(tester);
    await failed;
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate like page is not considered fully loaded',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 3,
        'items': [post(1)]
      },
    });
    await frames(tester);
    final batch = await openBatchDownload(tester);
    final failed = expectLater(batch.loadAllItems!(), throwsStateError);
    await frames(tester);
    respond(1, {
      'meta': {'status': 200},
      'response': {
        'count': 3,
        'items': [post(1), post(2)]
      },
    });
    await frames(tester);
    await failed;
    expect(tester.takeException(), isNull);
  });

  testWidgets('other authors likes do not offer current account cleanup',
      (tester) async {
    await mount(tester, infoMode: InfoMode.other);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 1,
        'items': [post(1)]
      },
    });
    await frames(tester);
    tester.widget<ShadowIconButton>(find.byType(ShadowIconButton)).onTap!();
    await frames(tester);
    final labels =
        AppLocalizations.of(tester.element(find.byType(LikeScreen)))!;
    expect(find.text(labels.batchDownload), findsOneWidget);
    expect(find.text(labels.clearInvalidContent), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late cleanup response from old account does not mutate likes',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 1,
        'items': [<String, dynamic>{}],
      },
    });
    await frames(tester);
    expect(
      tester
          .widget<LoftifyPostArchiveSliverGrid>(
            find.byType(LoftifyPostArchiveSliverGrid),
          )
          .itemCount,
      1,
    );
    tester.widget<ShadowIconButton>(find.byType(ShadowIconButton)).onTap!();
    await frames(tester);
    final clearLabel = AppLocalizations.of(
      tester.element(find.byType(LikeScreen)),
    )!
        .clearInvalidContent;
    await tester.tap(find.text(clearLabel));
    await frames(tester);
    expect(options[1].path, '/v2.0/batchData.api');
    appProvider.token = 'another-account';
    respond(1, {
      'meta': {'status': 200}
    });
    await frames(tester);
    expect(
      tester
          .widget<LoftifyPostArchiveSliverGrid>(
            find.byType(LoftifyPostArchiveSliverGrid),
          )
          .itemCount,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cleanup does not restore items from an older page request',
      (tester) async {
    await mount(tester);
    respond(0, {
      'meta': {'status': 200},
      'response': {
        'count': 3,
        'items': [<String, dynamic>{}, post(2)],
      },
    });
    await frames(tester);
    final refresh = tester.widget<EasyRefresh>(find.byType(EasyRefresh));
    final stalePage = Future.sync(refresh.onLoad!);
    await frames(tester);
    expect(pending, hasLength(2));
    tester.widget<ShadowIconButton>(find.byType(ShadowIconButton)).onTap!();
    await frames(tester);
    final clearLabel = AppLocalizations.of(
      tester.element(find.byType(LikeScreen)),
    )!
        .clearInvalidContent;
    await tester.tap(find.text(clearLabel));
    await frames(tester);
    expect(options[2].path, '/v2.0/batchData.api');
    respond(2, {
      'meta': {'status': 200}
    });
    await frames(tester);
    respond(1, {
      'meta': {'status': 200},
      'response': {
        'count': 3,
        'items': [post(3)]
      },
    });
    await frames(tester);
    expect(await stalePage, IndicatorResult.none);
    expect(
      tester
          .widget<LoftifyPostArchiveSliverGrid>(
            find.byType(LoftifyPostArchiveSliverGrid),
          )
          .itemCount,
      1,
    );
    expect(tester.takeException(), isNull);
  });
}
