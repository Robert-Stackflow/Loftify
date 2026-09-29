import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/tab_bar_wrapper',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('many tabs scroll and keep every label on one line',
      (tester) async {
    await tester.pumpWidget(
      const _TabHarness(
        width: 320,
        labels: ['综合', '标签', '合集', '粮单', '文章', '使用者'],
      ),
    );

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.isScrollable, isTrue);
    expect(tabBar.tabAlignment, TabAlignment.start);

    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('three tabs fill available width', (tester) async {
    await tester.pumpWidget(
      const _TabHarness(
        width: 360,
        labels: ['推荐', '最新', '最热'],
      ),
    );

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.isScrollable, isFalse);
    expect(tabBar.tabAlignment, TabAlignment.fill);
    expect(tester.takeException(), isNull);
  });

  testWidgets('six compact result tabs can be forced to fill one row',
      (tester) async {
    await tester.pumpWidget(
      const _TabHarness(
        width: 390,
        labels: ['综合', '标签', '合集', '粮单', '文章', '用户'],
        forceFill: true,
      ),
    );

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.isScrollable, isFalse);
    expect(tabBar.tabAlignment, TabAlignment.fill);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab strip keeps underline styling without ripple feedback',
      (tester) async {
    const background = Color(0xFFFFFFFF);
    const primary = Color(0xFF14C2BB);
    await tester.pumpWidget(
      const _TabHarness(
        width: 360,
        labels: ['推荐', '最新', '最热'],
        background: background,
        primary: primary,
      ),
    );

    final wrapper = find.byKey(const ValueKey('tab-wrapper'));
    final material = tester.widget<Material>(
      find.descendant(of: wrapper, matching: find.byType(Material)).first,
    );
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    final pressedColor = tabBar.overlayColor!.resolve({WidgetState.pressed});

    expect(material.color, background);
    expect(pressedColor, Colors.transparent);
    expect(tabBar.splashFactory, NoSplash.splashFactory);
    expect(tabBar.indicator, isA<UnderlinedTabIndicator>());
    expect(
      (tabBar.indicator! as UnderlinedTabIndicator).borderColor,
      primary,
    );
  });

  testWidgets('tab strip does not restore an app bar divider', (tester) async {
    await tester.pumpWidget(
      const _TabHarness(
        width: 360,
        labels: ['推荐', '最新', '最热'],
        showBorder: true,
      ),
    );

    final wrapper = find.byKey(const ValueKey('tab-wrapper'));
    final decoratedContainers = tester
        .widgetList<Container>(
          find.descendant(of: wrapper, matching: find.byType(Container)),
        )
        .where((container) => container.decoration is BoxDecoration);
    expect(
      decoratedContainers.every(
        (container) => (container.decoration! as BoxDecoration).border == null,
      ),
      isTrue,
    );
  });
}

class _TabHarness extends StatefulWidget {
  const _TabHarness({
    required this.width,
    required this.labels,
    this.background = const Color(0xFFFFFFFF),
    this.primary = const Color(0xFF14C2BB),
    this.forceFill = false,
    this.showBorder = false,
  });

  final double width;
  final List<String> labels;
  final Color background;
  final Color primary;
  final bool forceFill;
  final bool showBorder;

  @override
  State<_TabHarness> createState() => _TabHarnessState();
}

class _TabHarnessState extends State<_TabHarness>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: widget.labels.length, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: widget.background,
        colorScheme: ColorScheme.fromSeed(seedColor: widget.primary).copyWith(
          primary: widget.primary,
        ),
      ),
      home: Builder(
        builder: (context) {
          chewieProvider.setRootContext(context);
          return Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: widget.width,
                child: TabBarWrapper(
                  key: const ValueKey('tab-wrapper'),
                  tabController: _controller,
                  isScrollable: widget.forceFill ? false : null,
                  showBorder: widget.showBorder,
                  tabs: widget.labels
                      .asMap()
                      .entries
                      .map(
                        (entry) => ItemBuilder.buildAnimatedTab(
                          context,
                          selected: entry.key == _controller.index,
                          text: entry.value,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
