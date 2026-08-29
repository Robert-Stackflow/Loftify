import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Design/loftify_media_overlays.dart';

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
