import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filled dialog action stays readable for light accent colors', () {
    for (final accent in [
      const Color(0xFFFFB428),
      const Color(0xFF58BDB8),
      const Color(0xFFFF8B17),
    ]) {
      final fill = CustomDialogColors.readableActionFill(accent);
      final contrast = 1.05 / (fill.computeLuminance() + 0.05);
      expect(contrast, greaterThanOrEqualTo(4.5));
    }
  });
}
