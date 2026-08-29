import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Design/loftify_media_overlays.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

void main() {
  test('cover scrim keeps white content readable on the brightest artwork', () {
    final weakestBackground = Color.alphaBlend(
      LoftifyCoverScrim.topColor,
      Colors.white,
    );
    final secondary = Color.alphaBlend(
      LoftifyCoverScrim.secondaryForeground,
      weakestBackground,
    );

    expect(
      _contrastRatio(Colors.white, weakestBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(secondary, weakestBackground),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('top text scrim protects white preview content without hiding artwork',
      () {
    final protectedBackground = Color.alphaBlend(
      LoftifyTopTextScrim.protectedColor,
      Colors.white,
    );

    expect(
      _contrastRatio(Colors.white, protectedBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(LoftifyTopTextScrim.bottomColor.a, 0);
  });

  test('all artwork-backed detail headers use the shared cover scrim', () {
    for (final path in <String>[
      'lib/Screens/Info/user_detail_screen.dart',
      'lib/Screens/Post/collection_detail_screen.dart',
      'lib/Screens/Post/grain_detail_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('LoftifyCoverScrim()'), reason: path);
    }
  });

  test('wallpaper previews protect their white clock with a top scrim', () {
    final source = File(
      'lib/Screens/Suit/custom_bg_avatar_list_screen.dart',
    ).readAsStringSync();
    expect(source, contains('LoftifyTopTextScrim()'));
  });

  testWidgets('translucent media badges clamp weak requested opacity',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ItemBuilder.buildTranslucentTag(
              context,
              text: '123',
              opacity: 0.2,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final badge = tester.widget<Container>(
      find
          .ancestor(of: find.text('123'), matching: find.byType(Container))
          .first,
    );
    final decoration = badge.decoration! as BoxDecoration;
    final effectiveBackground = Color.alphaBlend(
      decoration.color!,
      Colors.white,
    );
    final foreground = tester.widget<Text>(find.text('123')).style!.color!;

    expect(decoration.color!.a, LoftifyCoverScrim.minimumBadgeOpacity);
    expect(
      _contrastRatio(foreground, effectiveBackground),
      greaterThanOrEqualTo(4.5),
    );
  });
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
