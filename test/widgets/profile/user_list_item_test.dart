import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/account_response.dart';
import 'package:loftify/Models/user_response.dart';
import 'package:loftify/Widgets/Item/loftify_item_builder.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/user_list_item',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('relation card keeps long identity content bounded on phones',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final item = FollowingUserItem(
      blogId: 7,
      blogInfo: FullBlogInfo.fromJson({
        'blogId': 7,
        'blogName': 'a_very_long_user_identifier_for_layout_verification',
        'blogNickName': 'A very long creator nickname that must not overflow',
        'bigAvaImg': '',
        'homePageUrl': '',
        'imageDigitStamp': false,
        'imageProtected': false,
        'imageStamp': false,
        'isOriginalAuthor': false,
        'selfIntro':
            'A long two-line introduction used to verify that the relation card remains bounded.',
      }),
      follower: true,
      following: true,
      followTime: 0,
      hotCount: 0,
      id: 1,
      lastPublishTime: 0,
      lastVisitTime: 0,
      responseCount: 0,
      score: 0,
      specialFollow: false,
      userId: 7,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          ChewieLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            chewieProvider.setRootContext(context);
            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: LoftifyItemBuilder.buildFollowerOrFollowingItem(
                  context,
                  0,
                  item,
                ),
              ),
            );
          },
        ),
      ),
    );

    final material = tester
        .widgetList<Material>(find.byType(Material))
        .firstWhere((widget) => widget.shape is RoundedRectangleBorder);
    final shape = material.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(14));
    expect(find.byType(InkWell), findsWidgets);
    expect(find.textContaining('ID:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
