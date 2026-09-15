import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sources = <String, String>{
    'home': File(
      'lib/Screens/Navigation/home_screen.dart',
    ).readAsStringSync(),
    'search': File(
      'lib/Screens/Navigation/search_screen.dart',
    ).readAsStringSync(),
    'dynamic': File(
      'lib/Screens/Navigation/dynamic_screen.dart',
    ).readAsStringSync(),
    'mine': File(
      'lib/Screens/Navigation/mine_screen.dart',
    ).readAsStringSync(),
  };

  test('primary pages use fixed responsive app bars', () {
    for (final source in sources.values) {
      expect(source, contains('appBar:'));
      expect(source, contains('ResponsiveAppBar('));
      expect(source, isNot(contains('LoftifyNavigationHeader')));
      expect(source, isNot(contains('LoftifyFloatingCapsule')));
      expect(
        source,
        isNot(contains('loftify_floating_navigation_header.dart')),
      );
    }
  });

  test('home and search restore their original top-bar structure', () {
    expect(sources['home'], contains('title: appLocalizations.home'));
    expect(
      sources['home'],
      isNot(contains('SliverToBoxAdapter(child: _buildNavigationHeader())')),
    );

    expect(sources['search'], contains('titleWidget: _buildSearchBar()'));
    expect(sources['search'], contains('borderRadius: 8'));
    expect(sources['search'], isNot(contains('search-navigation-avatar')));
  });

  test('dynamic restores the scrollable underline tab app bar', () {
    expect(
        sources['dynamic'], contains('appBar: appProvider.token.isNotEmpty'));
    expect(sources['dynamic'], contains('isScrollable: true'));
    expect(sources['dynamic'], contains('TabAlignment.start'));
    expect(sources['dynamic'], contains('UnderlinedTabIndicator('));
  });

  test('mine restores untitled app bar with its original actions', () {
    final appBar = sources['mine']!.split(
      'PreferredSizeWidget _buildAppBar()',
    )[1];
    expect(appBar, isNot(contains('title: appLocalizations.mine')));
    expect(appBar, contains('ItemBuilder.buildDynamicIconButton('));
    expect(appBar, contains('icon: LoftifyIcons.settings'));
    expect(appBar, contains('LoftifyIcons.notifications'));
    expect(appBar, contains('LoftifyIcons.dress'));
  });

  test('retired floating navigation header implementation is removed', () {
    expect(
      File(
        'lib/Widgets/Navigation/loftify_floating_navigation_header.dart',
      ).existsSync(),
      isFalse,
    );
  });
}
