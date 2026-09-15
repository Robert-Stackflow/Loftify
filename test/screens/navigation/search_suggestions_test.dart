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
  setUpAll(() async {
    final dir = Directory('build/test_hive/search_suggestions');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    RequestUtil.cookieManager = _UnusedCookieManager();
  });
  setUp(() {
    pending.clear();
    RequestUtil.instance.dio.interceptors.clear();
    RequestUtil.instance.dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) {
        if (options.path.endsWith('/sug.json')) {
          pending.add((options, handler));
        } else {
          handler.resolve(Response(requestOptions: options, data: {
            'code': 0,
            'data': <String, dynamic>{},
          }));
        }
      }),
    );
  });
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
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

  Future<void> respond(WidgetTester tester, int index, String label) async {
    final (options, handler) = pending[index];
    handler.resolve(Response(requestOptions: options, data: {
      'code': 0,
      'data': {
        'items': [
          {
            'type': 1,
            'tagInfo': {
              'tagName': label,
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
