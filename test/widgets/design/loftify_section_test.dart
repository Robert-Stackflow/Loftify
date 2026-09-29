import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/Design/loftify_section.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/loftify_section',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('entry grows for long localized text at 2x scale',
      (tester) async {
    await tester.pumpWidget(
      _TestApp(
        width: 280,
        textScaler: const TextScaler.linear(2),
        child: LoftifySection(
          title: 'Content center with a deliberately long localized heading',
          children: const <Widget>[
            LoftifyEntryItem(
              key: Key('long-entry'),
              title: 'Download management with a long title that must wrap',
              description:
                  'Completed files and active tasks stay available here.',
              showLeading: true,
              leading: LoftifyIcons.download,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const Key('long-entry'))).height,
        greaterThan(56));
    expect(tester.takeException(), isNull);
  });

  testWidgets('section expands and collapses with an accessible tap target', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: LoftifySection(
          title: '内容中心',
          children: <Widget>[
            LoftifyEntryItem(title: '下载管理'),
          ],
        ),
      ),
    );

    expect(find.text('下载管理'), findsOneWidget);
    final headerInkWell =
        tester.widgetList<InkWell>(find.byType(InkWell)).first;
    expect(headerInkWell.onTap, isNotNull);
    expect(headerInkWell.splashFactory, NoSplash.splashFactory);

    final entryInkWell = tester.widgetList<InkWell>(find.byType(InkWell)).last;
    expect(entryInkWell.splashFactory, NoSplash.splashFactory);

    await tester.tap(find.text('内容中心'));
    await tester.pumpAndSettle();
    expect(find.text('下载管理'), findsNothing);

    await tester.tap(find.text('内容中心'));
    await tester.pumpAndSettle();
    expect(find.text('下载管理'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entry exposes selected, disabled and status states',
      (tester) async {
    await tester.pumpWidget(
      const _TestApp(
        child: LoftifySection(
          title: '状态',
          children: <Widget>[
            LoftifyEntryItem(
              title: 'Selected',
              visualState: LoftifyEntryVisualState.selected,
            ),
            LoftifyEntryItem(
              title: 'Disabled',
              enabled: false,
            ),
            LoftifyEntryItem(
              title: 'Success',
              visualState: LoftifyEntryVisualState.success,
            ),
            LoftifyEntryItem(
              title: 'Warning',
              visualState: LoftifyEntryVisualState.warning,
            ),
            LoftifyEntryItem(
              title: 'Error',
              visualState: LoftifyEntryVisualState.error,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(LoftifyIcons.check), findsOneWidget);
    expect(find.byIcon(LoftifyIcons.warning), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
    this.width = 390,
    this.textScaler = TextScaler.noScaling,
  });

  final Widget child;
  final double width;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: LoftifyTheme.build(ChewieThemeColorData.defaultLightThemes.first),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: textScaler,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
