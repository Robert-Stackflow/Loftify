import 'dart:io';

import 'package:hive/hive.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:awesome_chewie/src/Widgets/Module/FlutterContextMenu/core/utils/helpers.dart'
    as context_menu;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final directory = Directory('build/test_hive/desktop_context_menu');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
  });
  testWidgets('window controls end eight pixels from the window edge',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [ChewieLocalizations.delegate],
      builder: (context, child) {
        chewieProvider.setRootContext(context);
        return child!;
      },
      home: Scaffold(
          body: Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: desktopWindowControlsWidth,
          child: WindowTitleWrapper(
            backgroundColor: Colors.white,
            isStayOnTop: false,
            isMaximized: false,
            onStayOnTopTap: () {},
          ),
        ),
      )),
    ));
    expect(
        tester.getRect(find.byType(WindowTitleWrapper)).right -
            tester.getRect(find.byType(CloseWindowButton)).right,
        closeTo(8, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop app bar leaves room for window controls',
      (tester) async {
    tester.view.physicalSize = const Size(985, 891);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: ResponsiveAppBar(
            backgroundColor: Colors.white,
            titleWidget: ColoredBox(
              key: Key('search-field'),
              color: Colors.grey,
              child: SizedBox(height: 40),
            ),
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byKey(const Key('search-field'))).right,
        lessThanOrEqualTo(985 - desktopWindowControlsWidth));
  });

  testWidgets('a menu in the desktop panel stays inside the panel viewport',
      (tester) async {
    tester.view.physicalSize = const Size(985, 891);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            const SizedBox(width: 72),
            Expanded(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: Align(
                      alignment: Alignment.bottomRight,
                      child: Builder(
                        builder: (panelContext) => TextButton(
                          onPressed: () {
                            context_menu.showContextMenu<void>(
                              panelContext,
                              contextMenu: FlutterContextMenu(
                                position: const Offset(970, 870),
                                entries: const [
                                  FlutterContextMenuItem('Desktop action'),
                                ],
                              ),
                            );
                          },
                          child: const Text('Open menu'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Open menu'));
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.text('Desktop action'));
    expect(itemRect.left, greaterThan(600));
    expect(itemRect.left, greaterThanOrEqualTo(72));
    expect(itemRect.right, lessThanOrEqualTo(985));
    expect(itemRect.bottom, lessThanOrEqualTo(891));
  });
}
