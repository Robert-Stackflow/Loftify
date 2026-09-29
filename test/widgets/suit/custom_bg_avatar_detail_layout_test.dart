import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/BottomSheet/custom_bg_avatar_detail_bottom_sheet.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/custom_bg_avatar_detail_layout',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('detail panel keeps footer reachable on a short large-text phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: LoftifyTheme.build(
          ChewieThemeColorData.defaultLightThemes.first,
        ),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            padding: EdgeInsets.only(top: 24),
            textScaler: TextScaler.linear(2),
          ),
          child: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: CustomBgAvatarDetailPanel(
                title: 'Decoration details with a long localized title',
                body: Column(
                  children: [
                    SizedBox(height: 700),
                    Text('End of preview details'),
                  ],
                ),
                footer: SizedBox(height: 150, child: Text('Footer actions')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final panel = find.byKey(
      const ValueKey('custom-bg-avatar-detail-panel'),
    );
    expect(tester.getSize(panel).height, lessThanOrEqualTo(544));
    expect(find.text('Footer actions'), findsOneWidget);
    expect(find.byKey(const ValueKey('loftify-panel-handle')), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('custom-bg-avatar-detail-scrolling-footer'),
      ),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('custom-bg-avatar-detail-scroll')),
      const Offset(0, -600),
    );
    await tester.pump();
    expect(find.text('End of preview details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('real detail sheet uses responsive Loftify buttons', () {
    final source = File(
      'lib/Widgets/BottomSheet/custom_bg_avatar_detail_bottom_sheet.dart',
    ).readAsStringSync();
    expect(source, contains('CustomBgAvatarDetailPanel('));
    expect(source, contains("LoftifyButton("));
    expect(source, contains('custom-bg-avatar-detail-actions-vertical'));
    expect(source, contains('custom-bg-avatar-detail-actions-horizontal'));
  });
}
