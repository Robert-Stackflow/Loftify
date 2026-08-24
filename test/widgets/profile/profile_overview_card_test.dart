import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Widgets/Design/loftify_surfaces.dart';
import 'package:loftify/Widgets/Profile/profile_overview_card.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/profile_overview_card',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('four long profile statistics stay bounded and clickable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var tapCount = 0;

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
              body: Center(
                child: SizedBox(
                  width: 288,
                  child: ProfileOverviewCard(
                    statistics: [
                      ProfileStatisticData(
                        title: 'Following accounts',
                        count: 123456,
                        onTap: () => tapCount++,
                      ),
                      const ProfileStatisticData(
                        title: 'Followers',
                        count: 987654,
                      ),
                      const ProfileStatisticData(
                        title: 'Total popularity',
                        count: 13579,
                      ),
                      const ProfileStatisticData(
                        title: 'Supporters',
                        count: null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final card = find.byType(ProfileOverviewCard);
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.byType(InkWell)),
      findsNWidgets(4),
    );
    final surface = tester.widget<LoftifyCard>(
      find.descendant(of: card, matching: find.byType(LoftifyCard)),
    );
    expect(surface.radius, 14);
    expect(find.text('123 K', findRichText: true), findsOneWidget);
    expect(find.text('988 K', findRichText: true), findsOneWidget);
    expect(find.text('13.6 K', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Following accounts'));
    await tester.pump();
    expect(tapCount, 1);
    expect(tester.takeException(), isNull);
  });
}
