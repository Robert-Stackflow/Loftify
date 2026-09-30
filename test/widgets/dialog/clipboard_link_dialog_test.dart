import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/clipboard_link_controller.dart';
import 'package:loftify/Widgets/Dialog/clipboard_link_dialog.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final directory =
        await Directory.systemTemp.createTemp('loftify_clipboard_ui_');
    Hive.init(directory.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
  });

  testWidgets('dialog distinguishes both buttons, barrier and back dismissal',
      (tester) async {
    const url = 'https://ruiiiiii.lofter.com/post/1dd2a51a_34f468525';
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    ClipboardLinkDecision? result;
    await tester.pumpWidget(MaterialApp(
      theme: LoftifyTheme.build(ChewieThemeColorData.defaultLightThemes.first),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return Scaffold(
            body: TextButton(
          onPressed: () async =>
              result = await ClipboardLinkDialog.show(context, url),
          child: const Text('Show'),
        ));
      }),
    ));
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('Loftify link found'), findsOneWidget);
    expect(find.byType(CustomConfirmDialogWidget), findsOneWidget);
    expect(find.byIcon(LucideIcons.link), findsOneWidget);
    expect(find.byType(BackdropFilter), findsWidgets);
    final route =
        ModalRoute.of(tester.element(find.byType(ClipboardLinkDialog)))!;
    expect(route.barrierColor, ChewieTheme.barrierColor);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(result, ClipboardLinkDecision.dismiss);
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open link'));
    await tester.pumpAndSettle();
    expect(result, ClipboardLinkDecision.open);
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
