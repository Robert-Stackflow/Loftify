import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/Profile/profile_header_components.dart';
import 'package:loftify/Widgets/Profile/profile_overview_card.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/profile_header_components',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('identity grows safely for narrow two-times text',
      (tester) async {
    var descriptionTaps = 0;
    var displayNameCopies = 0;
    var idCopies = 0;
    await tester.pumpWidget(
      _TestApp(
        width: 280,
        textScaler: const TextScaler.linear(2),
        child: ColoredBox(
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LoftifyProfileIdentity(
              avatar: const SizedBox.square(
                dimension: 72,
                child: ColoredBox(color: Colors.white),
              ),
              displayName: 'A very long localized creator display name',
              idLabel: 'ID: an_equally_long_creator_identifier',
              metadata: 'Gender: private · Location: a long place name',
              descriptionLabel: 'Read full introduction',
              onDescriptionPressed: () => descriptionTaps++,
              onDisplayNameLongPress: () => displayNameCopies++,
              onIdLongPress: () => idCopies++,
              trailing: const Icon(LoftifyIcons.moreVertical),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final identity = find.byType(LoftifyProfileIdentity);
    expect(tester.getSize(identity).height, greaterThan(150));
    await tester.tap(find.text('Read full introduction'));
    await tester.longPress(
      find.text('A very long localized creator display name'),
    );
    await tester.longPress(
      find.text('ID: an_equally_long_creator_identifier'),
    );
    expect(descriptionTaps, 1);
    expect(displayNameCopies, 1);
    expect(idCopies, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary follow action remains content-sized and clickable',
      (tester) async {
    var taps = 0;
    for (final dark in <bool>[false, true]) {
      await tester.pumpWidget(
        _TestApp(
          width: 320,
          dark: dark,
          child: LoftifyProfileAction(
            label: 'Follow this creator',
            icon: LoftifyIcons.follow,
            emphasized: true,
            onPressed: () => taps++,
          ),
        ),
      );
      await tester.pump();

      final action = find.byKey(const ValueKey('loftify-profile-action'));
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      final design = LoftifyDesignThemeData.of(tester.element(action));
      final decoration = tester
          .widget<AnimatedContainer>(
            find.descendant(
              of: action,
              matching: find.byType(AnimatedContainer),
            ),
          )
          .decoration! as BoxDecoration;
      final effectiveBackground = Color.alphaBlend(
        decoration.color!,
        design.colors.page,
      );
      final label = tester.widget<Text>(find.text('Follow this creator'));
      expect(
        _contrastRatio(label.style!.color!, effectiveBackground),
        greaterThanOrEqualTo(4.5),
      );
      await tester.tap(find.text('Follow this creator'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    expect(taps, 2);
  });

  testWidgets('header uses columns on phones and two panes on wide windows',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget header() => const LoftifyProfileHeaderLayout(
          summary: SizedBox(height: 120, child: ColoredBox(color: Colors.red)),
          showcase:
              SizedBox(height: 100, child: ColoredBox(color: Colors.blue)),
        );

    await tester.pumpWidget(_TestApp(width: 1000, child: header()));
    await tester.pump();
    final summary = find.byKey(const ValueKey('loftify-profile-summary'));
    final showcase = find.byKey(const ValueKey('loftify-profile-showcase'));
    expect(tester.getTopLeft(showcase).dx,
        greaterThan(tester.getTopLeft(summary).dx));
    expect(tester.getTopLeft(showcase).dy, tester.getTopLeft(summary).dy);

    await tester.pumpWidget(_TestApp(width: 320, child: header()));
    await tester.pump();
    expect(
      tester.getTopLeft(showcase).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(summary).dy + 12),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile statistics reflow to two rows for accessible text',
      (tester) async {
    await tester.pumpWidget(
      _TestApp(
        width: 240,
        textScaler: const TextScaler.linear(2),
        child: const ProfileOverviewCard(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black54,
          statistics: [
            ProfileStatisticData(title: 'Following accounts', count: 123),
            ProfileStatisticData(title: 'Followers', count: 456),
            ProfileStatisticData(title: 'Total popularity', count: 7890),
            ProfileStatisticData(title: 'Supporters', count: 42),
          ],
        ),
      ),
    );
    await tester.pump();

    final statistics = find.byType(ProfileOverviewCard);
    expect(tester.getSize(statistics).height, greaterThan(120));
    expect(find.byType(InkWell), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
    required this.width,
    this.textScaler = TextScaler.noScaling,
    this.dark = false,
  });

  final Widget child;
  final double width;
  final TextScaler textScaler;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: LoftifyTheme.build(
        dark
            ? ChewieThemeColorData.defaultDarkThemes.first
            : ChewieThemeColorData.defaultLightThemes.first,
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: textScaler,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
