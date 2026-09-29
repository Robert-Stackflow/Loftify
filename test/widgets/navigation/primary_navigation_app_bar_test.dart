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

  test('primary pages retain responsive app bars', () {
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

  test('home supports optional floating top bar and search action', () {
    expect(sources['home'], contains('title: appLocalizations.home'));
    expect(sources['home'], contains('appBar: hideAppBar ? null'));
    expect(sources['home'], contains('SliverAppBar('));
    expect(sources['home'], contains('ExtendedNestedScrollView('));
    expect(sources['home'], contains('floatHeaderSlivers: true'));
    expect(sources['home'], contains('onlyOneScrollInBody: true'));
    expect(sources['home'], contains('PrimaryScrollController.of(context)'));
    expect(
        sources['home'], isNot(contains('SafeArea(\n        top: hideAppBar')));
    expect(sources['home'], contains('safeArea: false'));
    expect(sources['home'], contains('refreshOnStart: true'));
    expect(sources['home'], contains('clamping: true'));
    expect(sources['home'], contains('await _triggerRefresh()'));
    expect(sources['home'],
        contains('distanceFromTop <= MediaQuery.sizeOf(context).height / 2'));
    expect(sources['home'], isNot(contains('_refreshFeedDirectly')));
    expect(sources['home'], contains('floating: true'));
    expect(sources['home'], contains('snap: true'));
    expect(sources['home'], contains('hideSearchNavigation'));
    expect(sources['home'], contains('SearchScreen(showBack: true)'));
    expect(
      sources['home'],
      isNot(contains('SliverToBoxAdapter(child: _buildNavigationHeader())')),
    );

    expect(sources['search'], contains('titleWidget: _buildSearchBar()'));
    expect(sources['search'], contains('showBack: widget.showBack'));
  });

  test('search keeps its original top-bar structure', () {
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
    expect(appBar, contains('_MineThemeModeButton('));
    expect(appBar, contains('LottieFiles.sunLight'));
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
