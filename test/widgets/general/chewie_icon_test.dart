import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/loftify_icons.dart';
import 'package:lucide_icons/lucide_icons.dart';

Widget _host(Widget child, {ChewieIconThemeData? iconTheme}) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      extensions: <ThemeExtension<dynamic>>[
        iconTheme ?? ChewieIconThemeData.standard,
      ],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('shared Lucide primitives keep optical and touch sizes separate',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ChewieIconButton(
          icon: LucideIcons.search,
          tooltip: 'Search',
          onPressed: () => taps++,
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.search));
    expect(icon.size, 20);
    expect(tester.getSize(find.byType(IconButton)), const Size.square(44));
    expect(find.bySemanticsLabel('Search'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    expect(taps, 1);
  });

  testWidgets('custom specification controls all shared measurements',
      (tester) async {
    const specification = ChewieIconThemeData(
      regularSize: 22,
      minimumTapTarget: 48,
      cornerRadius: 14,
    );
    await tester.pumpWidget(
      _host(
        ChewieIconButton(
          icon: LucideIcons.settings,
          onPressed: () {},
        ),
        iconTheme: specification,
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.settings));
    expect(icon.size, 22);
    expect(tester.getSize(find.byType(IconButton)), const Size.square(48));
  });

  testWidgets('selected and disabled states retain one Lucide glyph',
      (tester) async {
    await tester.pumpWidget(
      _host(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ChewieIconButton(
              icon: LucideIcons.heart,
              selected: true,
              tooltip: 'Selected',
              onPressed: _emptyCallback,
            ),
            ChewieIconButton(
              icon: LucideIcons.heart,
              foregroundColor: Colors.red,
              tooltip: 'Disabled',
              onPressed: null,
            ),
          ],
        ),
      ),
    );

    final icons = tester.widgetList<Icon>(find.byIcon(LucideIcons.heart));
    expect(icons, hasLength(2));
    expect(icons.first.color,
        Theme.of(tester.element(find.byType(Row))).colorScheme.primary);
    expect(icons.last.color!.a, closeTo(0.38, 0.01));
    expect(find.byIcon(LucideIcons.heart), findsNWidgets(2));
  });

  test('theme extension copies and interpolates icon measurements', () {
    const start = ChewieIconThemeData();
    final end = start.copyWith(regularSize: 24, minimumTapTarget: 48);
    final middle = start.lerp(end, 0.5);

    expect(middle.regularSize, 22);
    expect(middle.minimumTapTarget, 46);
    expect(end.disabledOpacity, start.disabledOpacity);
  });

  test('product semantic icons all come from the Lucide font', () {
    const icons = <IconData>[
      LoftifyIcons.generalSettings,
      LoftifyIcons.appearance,
      LoftifyIcons.image,
      LoftifyIcons.basicSettings,
      LoftifyIcons.experiment,
      LoftifyIcons.about,
      LoftifyIcons.download,
      LoftifyIcons.file,
      LoftifyIcons.video,
      LoftifyIcons.pause,
      LoftifyIcons.play,
      LoftifyIcons.retry,
      LoftifyIcons.close,
      LoftifyIcons.delete,
    ];

    expect(icons.every((icon) => icon.fontFamily == 'Lucide'), isTrue);
    expect(icons.every((icon) => icon.fontPackage == 'lucide_icons'), isTrue);
  });

  test('application pages do not import icon fonts directly', () {
    final violations = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => !file.path.replaceAll('\\', '/').endsWith(
                'lib/Widgets/loftify_icons.dart',
              ),
        )
        .where(
          (file) => file.readAsStringSync().contains(
                'package:lucide_icons/lucide_icons.dart',
              ),
        )
        .map((file) => file.path)
        .toList();

    expect(violations, isEmpty);
  });
}

void _emptyCallback() {}
