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

  test('global navigation uses semantic icons without glyph swapping', () {
    final sources = <String, String>{
      'main': File('lib/Screens/main_screen.dart').readAsStringSync(),
      'panel': File('lib/Screens/panel_screen.dart').readAsStringSync(),
    };

    for (final entry in sources.entries) {
      expect(
        RegExp(r'\bIcons\.').hasMatch(entry.value),
        isFalse,
        reason: '${entry.key} navigation must not use Material icons',
      );
      expect(
        entry.value.contains('assets/icon/'),
        isFalse,
        reason: '${entry.key} navigation must not use legacy icon images',
      );
    }

    const semantics = <String>['home', 'search', 'activity', 'profile'];
    for (final semantic in semantics) {
      expect(
        RegExp(
          'icon:\\s*LoftifyIcons\\.$semantic,\\s*'
          'selectedIcon:\\s*LoftifyIcons\\.$semantic,',
        ).hasMatch(sources['main']!),
        isTrue,
      );
      expect(
        RegExp(
          'icon: const ChewieIcon\\(LoftifyIcons\\.$semantic, size: 24\\),'
          '[\\s\\S]*?activeIcon: const ChewieIcon\\('
          'LoftifyIcons\\.$semantic, size: 24\\),',
        ).hasMatch(sources['panel']!),
        isTrue,
      );
    }
  });

  test('reusable Chewie runtime has no Material or Cupertino glyphs', () {
    final violations = Directory('third-party/chewie/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .expand(
          (file) => file.readAsLinesSync().asMap().entries.where(
            (line) {
              final source = line.value.trimLeft();
              if (source.startsWith('//') || source.startsWith('*')) {
                return false;
              }
              return RegExp(r'\b(?:Icons|CupertinoIcons)\.').hasMatch(source);
            },
          ).map((line) => '${file.path}:${line.key + 1}'),
        )
        .toList();

    expect(violations, isEmpty);
  });
}
