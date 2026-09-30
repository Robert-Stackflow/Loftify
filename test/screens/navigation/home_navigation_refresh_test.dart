import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Navigation/home_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/lottie_files.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _UnusedCookieManager extends Fake implements CookieManager {}

void main() {
  var landscapeLayout = false;
  setUpAll(() async {
    final directory = Directory('build/test_hive/home_navigation_refresh');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    // Exercise both layout policies independently of the test host platform.
    appProvider = AppProvider(isLandscapeLayout: () => landscapeLayout);
    RequestUtil.cookieManager = _UnusedCookieManager();
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: Colors.transparent,
          indicator: LottieFiles.buildLoadingAnimation(40, false),
          hapticFeedback: true,
          triggerOffset: 56,
          maxOverOffset: 84,
          radius: 20,
        );
  });

  for (final config in [
    (landscape: false, preference: false),
    (landscape: false, preference: true),
    (landscape: true, preference: true),
  ]) {
    final hideAppBar = !config.landscape && config.preference;
    for (final startDistance in [250.0, 600.0]) {
      testWidgets(
          'home navigation from $startDistance px ($config)',
          (tester) async {
        landscapeLayout = config.landscape;
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        appProvider.hideHomeAppBarOnScroll = config.preference;
        addTearDown(() => appProvider.hideHomeAppBarOnScroll = false);

        var requests = 0;
        RequestUtil.instance.dio.interceptors.clear();
        RequestUtil.instance.dio.interceptors.add(
          InterceptorsWrapper(onRequest: (options, handler) {
            requests++;
            handler.resolve(Response(
              requestOptions: options,
              data: {
                'code': 0,
                'data': {
                  'offset': 0,
                  'list': List.generate(
                      30,
                      (index) => {
                            'itemId': index + 1,
                            'itemType': 1,
                            'favorite': false,
                            'following': false,
                            'postData': {
                              'postView': {
                                'blogId': 1,
                                'digest': 'Story content $index',
                                'forbidShare': 0,
                                'id': index + 1,
                                'permalink': '',
                                'photoCount': 0,
                                'postPageUrl': '',
                                'publishTime': 0,
                                'tagList': <String>[],
                                'title': 'Story $index',
                                'type': 1,
                              },
                            },
                          }),
                },
              },
            ));
          }),
        );

        final haptics = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments.toString());
          }
          return null;
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: appProvider,
          child: MaterialApp(
            theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
            localizationsDelegates: const [
              ChewieLocalizations.delegate,
              ...AppLocalizations.localizationsDelegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(builder: (context) {
              chewieProvider.setRootContext(context);
              return const HomeScreen();
            }),
          ),
        ));
        for (var frame = 0; frame < 8; frame++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(requests, 1);
        expect(haptics, isEmpty);
        expect(find.byKey(const ValueKey('home-floating-app-bar')),
            hideAppBar ? findsOneWidget : findsNothing);

        final state = tester.state<HomeScreenState>(find.byType(HomeScreen));
        if (hideAppBar) {
          final appBar = tester.renderObject<RenderSliver>(
            find.byKey(const ValueKey('home-floating-app-bar'),
                skipOffstage: false),
          );
          expect(
              state.getScrollControllers().first.offset, lessThanOrEqualTo(1));
          expect(appBar.geometry!.paintExtent, greaterThan(0));
          expect(
            tester
                .getSize(
                    find.byKey(const ValueKey('refresh-indicator-viewport')))
                .height,
            0,
          );
        }
        final feedController = state.getScrollControllers().last;
        expect(feedController.hasClients, isTrue);
        if (hideAppBar) {
          await tester.drag(
              find.byType(CustomScrollView), Offset(0, -startDistance));
          for (var frame = 0; frame < 8; frame++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(state.getScrollControllers().first.offset, greaterThan(1));
        } else {
          feedController.jumpTo(startDistance);
          await tester.pump();
        }
        expect(feedController.offset, greaterThan(1));
        final outerController = state.getScrollControllers().first;
        final distanceFromTop =
            feedController.offset + (hideAppBar ? outerController.offset : 0.0);
        if (startDistance < 422) {
          expect(distanceFromTop, lessThan(422));
        } else {
          expect(distanceFromTop, greaterThan(422));
        }

        final scrollToTop = state.onTapBottomNavigation();
        for (var frame = 0; frame < 20; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await scrollToTop;
        expect(feedController.offset, lessThanOrEqualTo(1));
        expect(state.getScrollControllers().first.offset, lessThanOrEqualTo(1));
        if (hideAppBar) {
          final appBar = tester.renderObject<RenderSliver>(
            find.byKey(const ValueKey('home-floating-app-bar')),
          );
          expect(appBar.geometry!.paintExtent, greaterThan(0));
        }
        expect(requests, startDistance < 422 ? 2 : 1);

        if (startDistance > 422) {
          final refresh = state.onTapBottomNavigation();
          for (var frame = 0; frame < 10; frame++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          await refresh;
        }
        for (var frame = 0; frame < 16; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(requests, 2);
        expect(haptics, ['HapticFeedbackType.mediumImpact']);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('refresh-indicator-viewport')))
              .height,
          0,
        );
        if (hideAppBar) {
          final appBar = tester.renderObject<RenderSliver>(
            find.byKey(const ValueKey('home-floating-app-bar'),
                skipOffstage: false),
          );
          expect(appBar.geometry!.paintExtent, greaterThan(0));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
