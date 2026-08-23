import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponsiveUtil tablet breakpoint', () {
    test('requires both minimum logical dimensions', () {
      expect(ResponsiveUtil.isTabletSize(const Size(599, 1200)), isFalse);
      expect(ResponsiveUtil.isTabletSize(const Size(600, 899)), isFalse);
      expect(ResponsiveUtil.isTabletSize(const Size(600, 900)), isTrue);
    });

    test('is independent of orientation', () {
      expect(ResponsiveUtil.isTabletSize(const Size(640, 1428)), isTrue);
      expect(ResponsiveUtil.isTabletSize(const Size(1428, 640)), isTrue);
    });

    test('keeps phone-sized windows in portrait layout', () {
      expect(ResponsiveUtil.isTabletSize(const Size(426, 952)), isFalse);
      expect(ResponsiveUtil.isTabletSize(const Size(952, 426)), isFalse);
    });
  });
}
