import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Navigation/loftify_floating_navigation_header.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

Widget _host({
  MediaQueryData mediaQuery = const MediaQueryData(size: Size(360, 720)),
  bool enableBlur = true,
  ScrollController? scrollController,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: mediaQuery,
      child: Scaffold(
        body: Stack(
          children: [
            ListView(
              controller: scrollController,
              padding: EdgeInsets.only(
                top: mediaQuery.padding.top +
                    LoftifyFloatingNavigationHeader.topGap +
                    LoftifyFloatingNavigationHeader.height +
                    LoftifyFloatingNavigationHeader.contentGap,
              ),
              children: List.generate(
                20,
                (index) => SizedBox(
                  key: ValueKey('item-$index'),
                  height: 48,
                  child: Text('Item $index'),
                ),
              ),
            ),
            LoftifyFloatingNavigationHeader(
              child: Align(
                alignment: Alignment.centerLeft,
                child: LoftifyFloatingHeaderAction(
                  icon: LoftifyIcons.search,
                  tooltip: 'Search',
                  enableBlur: enableBlur,
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('uses safe-area geometry and a full-radius shadow capsule', (
    tester,
  ) async {
    const media = MediaQueryData(
      size: Size(360, 720),
      padding: EdgeInsets.only(top: 24),
    );
    await tester.pumpWidget(_host(mediaQuery: media));

    final header = tester.widget<Positioned>(
      find.descendant(
        of: find.byType(LoftifyFloatingNavigationHeader),
        matching: find.byType(Positioned),
      ),
    );
    expect(header.top, 30);
    expect(header.height, LoftifyFloatingNavigationHeader.height);

    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('loftify-floating-capsule-surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(999));
    expect(find.byType(BackdropFilter), findsOneWidget);

    final shadowContainer = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(LoftifyFloatingCapsule),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      shadowContainer.any(
        (box) =>
            (box.decoration as BoxDecoration).boxShadow?.isNotEmpty == true,
      ),
      isTrue,
    );
  });

  testWidgets('keeps the header fixed while its initial content inset scrolls',
      (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(scrollController: controller));

    final headerTopBefore = tester.getTopLeft(
      find.byType(LoftifyFloatingHeaderAction),
    );
    final itemTopBefore =
        tester.getTopLeft(find.byKey(const ValueKey('item-0')));
    expect(itemTopBefore.dy, 62);

    controller.jumpTo(80);
    await tester.pump();

    expect(
      tester.getTopLeft(find.byType(LoftifyFloatingHeaderAction)),
      headerTopBefore,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('item-0'))).dy,
      lessThan(itemTopBefore.dy),
    );
  });

  testWidgets('uses an opaque fallback when blur is disabled or inaccessible', (
    tester,
  ) async {
    for (final configuration in <({MediaQueryData media, bool enabled})>[
      (
        media: const MediaQueryData(size: Size(360, 720)),
        enabled: false,
      ),
      (
        media: const MediaQueryData(
          size: Size(360, 720),
          highContrast: true,
        ),
        enabled: true,
      ),
    ]) {
      await tester.pumpWidget(
        _host(
          mediaQuery: configuration.media,
          enableBlur: configuration.enabled,
        ),
      );

      expect(find.byType(BackdropFilter), findsNothing);
      final surface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('loftify-floating-capsule-surface')),
      );
      expect((surface.decoration as BoxDecoration).color!.a, 1);
    }
  });

  testWidgets('center title keeps a compact single-line capsule', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: LoftifyFloatingNavigationHeader.height,
              child: LoftifyFloatingHeaderTitle(
                title: 'A deliberately long Loftify title',
                enableBlur: false,
              ),
            ),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(
      find.text('A deliberately long Loftify title'),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(find.byType(LoftifyFloatingCapsule), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
