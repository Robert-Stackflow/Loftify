import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('product icon semantics never encode a visual state variant', () {
    final source = File('lib/Widgets/loftify_icons.dart').readAsStringSync();
    final declarations = RegExp(
      r'static const IconData\s+([A-Za-z0-9_]+)',
    ).allMatches(source);
    final visualVariant = RegExp(
      r'(active|inactive|selected|unselected|filled|outlined)',
      caseSensitive: false,
    );

    final violations = declarations
        .map((match) => match.group(1)!)
        .where(visualVariant.hasMatch)
        .toList();

    expect(violations, isEmpty);
  });

  test('there are no unregistered paired SVG interface icons', () {
    const excludedBrandAssets = <String>{'assets/logo.svg'};
    final interfaceSvgAssets = Directory('assets')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll('\\', '/'))
        .where((path) => path.endsWith('.svg'))
        .where((path) => !excludedBrandAssets.contains(path))
        .toList();

    expect(
      interfaceSvgAssets,
      isEmpty,
      reason: 'Register every paired SVG exception in Icon_Migration_Map.md '
          'and this allowlist before using it.',
    );
  });
}
