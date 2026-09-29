import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    final hiveDirectory = Directory(
      '${Directory.current.path}/build/test_hive/dynamic_tool_button',
    );
    await hiveDirectory.create(recursive: true);
    Hive.init(hiveDirectory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('dynamic desktop tool button forwards its tap callback',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: appProvider,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                chewieProvider.setRootContext(context);
                return ItemBuilder.buildDynamicToolButton(
                  context: context,
                  iconBuilder: (_) => const Icon(Icons.dark_mode_outlined),
                  onTap: () => tapCount++,
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ToolButton));
    await tester.pumpAndSettle();

    expect(tapCount, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
