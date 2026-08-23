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

  test('settings and login primitives have no legacy glyphs', () {
    final files = <File>[
      ...Directory('lib/Screens/Setting')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      File('lib/Widgets/Item/setting_management_item.dart'),
      File('lib/Widgets/Item/login_input_item.dart'),
    ];
    final violations = files
        .where(
          (file) => RegExp(r'\b(?:Icons|CupertinoIcons)\.')
              .hasMatch(file.readAsStringSync()),
        )
        .map((file) => file.path)
        .toList();

    expect(violations, isEmpty);
  });

  test('shared content item builders use semantic Lucide icons', () {
    final files = <File>[
      File('lib/Widgets/Item/item_builder.dart'),
      File('lib/Widgets/Item/loftify_item_builder.dart'),
    ];
    final legacyGlyph = RegExp(r'\b(?:Icons|CupertinoIcons)\.');
    final legacyInterfaceAsset = RegExp(
      r'AssetUtil\.(?:hotIcon|searchLightIcon|searchDarkIcon|'
      r'likeFilledIcon|likeLightIcon)',
    );
    final violations = files
        .where((file) {
          final source = file.readAsStringSync();
          return legacyGlyph.hasMatch(source) ||
              legacyInterfaceAsset.hasMatch(source);
        })
        .map((file) => file.path)
        .toList();

    expect(violations, isEmpty);

    final source = File(
      'lib/Widgets/Item/loftify_item_builder.dart',
    ).readAsStringSync();
    expect(source, contains('ChewieIcon(\n            LoftifyIcons.favorite,'));
    expect(
        source, contains('ChewieIcon(\n            LoftifyIcons.recommend,'));
  });

  test('business bottom sheets use semantic Lucide icons', () {
    final files = Directory('lib/Widgets/BottomSheet')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final legacyGlyph = RegExp(r'\b(?:Icons|CupertinoIcons)\.');
    final legacyInterfaceAsset = RegExp(
      r'AssetUtil\.(?:orderDownDarkIcon|orderUpDarkIcon)',
    );
    final violations = files
        .where((file) {
          final source = file.readAsStringSync();
          return legacyGlyph.hasMatch(source) ||
              legacyInterfaceAsset.hasMatch(source);
        })
        .map((file) => file.path)
        .toList();

    expect(violations, isEmpty);

    final subscribeSource = File(
      'lib/Widgets/BottomSheet/subscribe_post_bottom_sheet.dart',
    ).readAsStringSync();
    expect(RegExp(r'icon:\s*LoftifyIcons\.select').allMatches(subscribeSource),
        hasLength(1));
  });

  test('content management menus use semantic Lucide icons', () {
    const paths = <String>[
      'lib/Screens/Info/share_screen.dart',
      'lib/Screens/Info/like_screen.dart',
      'lib/Screens/Info/history_screen.dart',
      'lib/Screens/Info/favorite_folder_list_screen.dart',
      'lib/Screens/Info/supporter_screen.dart',
    ];
    final legacyGlyph = RegExp(r'\b(?:Icons|CupertinoIcons)\.');
    final violations = paths
        .map(File.new)
        .where((file) => legacyGlyph.hasMatch(file.readAsStringSync()))
        .map((file) => file.path)
        .toList();

    expect(violations, isEmpty);

    for (final path in paths.take(3)) {
      final source = File(path).readAsStringSync();
      expect(source, contains('LoftifyIcons.moreVertical'));
      expect(source, contains('status: MenuItemStatus.error'));
    }
  });

  test('profile detail uses semantic Lucide icons and stable follow glyph', () {
    final source = File(
      'lib/Screens/Info/user_detail_screen.dart',
    ).readAsStringSync();

    expect(RegExp(r'\b(?:Icons|CupertinoIcons)\.').hasMatch(source), isFalse);
    expect(source.contains('AssetUtil.collectionWhiteIcon'), isFalse);
    expect(
      RegExp(r'LoftifyIcons\.following|LoftifyIcons\.followed')
          .hasMatch(source),
      isFalse,
    );
    expect(source, contains('LoftifyIcons.follow'));
    expect(source, contains('status: MenuItemStatus.error'));
  });
}
