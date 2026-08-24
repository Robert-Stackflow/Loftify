import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Widgets/BottomSheet/newest_filter_bottom_sheet.dart';
import 'package:loftify/Widgets/Design/loftify_controls.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/newest_filter_panel',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('filter panel keeps long English choices scrollable and visible',
      (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final params = GetTagPostListParams(tag: 'design');

    await tester.pumpWidget(_host(params));
    await tester.pumpAndSettle();

    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Not Viewed in the Last 7 Days'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    expect(params.tagRangeType, TagRangeType.follow);

    await tester.scrollUntilVisible(
      find.text('Tag Protection').last,
      140,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Tag Protection').last);
    await tester.pumpAndSettle();
    expect(params.protectedFlag, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter reset restores every choice without controller drift', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final params = GetTagPostListParams(
      tag: 'design',
      tagRangeType: TagRangeType.follow,
      postTypes: TagPostType.image,
      recentDayType: TagRecentDayType.oneMonth,
      protectedFlag: true,
    );

    await tester.pumpWidget(_host(params));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(params.tagRangeType, TagRangeType.noLimit);
    expect(params.postTypes, TagPostType.noLimit);
    expect(params.recentDayType, TagRecentDayType.noLimit);
    expect(params.protectedFlag, isFalse);
    expect(find.byType(LoftifyTag), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Widget _host(GetTagPostListParams params) {
  return MaterialApp(
    locale: const Locale('en'),
    navigatorKey: chewieProvider.globalNavigatorKey,
    theme: LoftifyTheme.build(ChewieThemeColorData.defaultLightThemes.first),
    localizationsDelegates: const [
      ChewieLocalizations.delegate,
      ...AppLocalizations.localizationsDelegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        chewieProvider.setRootContext(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: NewestFilterBottomSheet(params: params),
            ),
          ),
        );
      },
    ),
  );
}
