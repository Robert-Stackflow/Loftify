import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Utils/clipboard_link_controller.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Widgets/Dialog/clipboard_link_dialog.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final directory = Directory('build/test_hive/clipboard_links');
    await directory.create(recursive: true);
    Hive.init(directory.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
  });
  const url = 'https://ruiiiiii.lofter.com/post/1dd2a51a_34f468525';
  test('extract only supported Loftify URLs from copied share text', () {
    for (final input in [url, '分享给你：$url。', '[$url]($url)', '查看 <$url>']) {
      expect(LoftifyUriUtil.extractSupportedClipboardUrl(input), url);
    }
    for (final input in [
      'hello',
      'https://example.com',
      'https://ruiiiiii.lofter.com.evil.test/post/1dd2a51a_34f468525',
      'https://evil.test/?next=$url',
      'https://www.lofter.com/login',
      'https://www.lofter.com/path?next=$url',
      'https://attacker@ruiiiiii.lofter.com/post/1dd2a51a_34f468525'
    ]) {
      expect(LoftifyUriUtil.extractSupportedClipboardUrl(input), isNull);
    }
    for (final input in [
      'lofter://ruiiiiii.lofter.com/post/1dd2a51a_34f468525',
      'https://www.lofter.com/videoDetail?permalink=1dd2a51a_34f468525',
      'https://www.lofter.com/front/blog/collection/share?collectionId=123',
      'https://www.lofter.com/collection/blog/?op=collectionDetail&collectionId=123',
      'https://www.lofter.com/front/blog/grain/detail?grainId=1&grainUserId=2&incantation=abc',
      'https://www.lofter.com/mentionredirect.do?blogId=123',
      'https://www.lofter.com/tag/原神',
      'https://www.lofter.com/tag/%E5%8E%9F%E7%A5%9E',
      'https://ruiiiiii.lofter.com/',
      'https://s.lofter.com/-s/abc123',
    ]) {
      expect(LoftifyUriUtil.extractSupportedClipboardUrl(input), input);
    }
  });

  test('dismiss and accept are both deduplicated, with no automatic navigation',
      () async {
    var prompts = 0;
    var opens = 0;
    var accepted = false;
    var text = url;
    final controller = ClipboardLinkController(
      canPrompt: () => true,
      readText: () async => text,
      confirm: (_) async {
        prompts++;
        return accepted;
      },
      open: (_) async {
        opens++;
      },
    );
    await controller.check();
    await controller.check();
    expect(prompts, 1);
    expect(opens, 0);
    accepted = true;
    text = 'https://other.lofter.com/';
    await controller.check();
    await controller.check();
    expect(prompts, 2);
    expect(opens, 1);
    controller.dispose();
  });

  test('overlapping resume events and disposal cannot open duplicate dialogs',
      () async {
    final read = Completer<String?>();
    var prompts = 0;
    var reads = 0;
    final controller = ClipboardLinkController(
      canPrompt: () => true,
      readText: () {
        reads++;
        return read.future;
      },
      confirm: (_) async {
        prompts++;
        return true;
      },
      open: (_) async => fail('disposed controller must not navigate'),
    );
    final pending = controller.check();
    await controller.check();
    expect(reads, 1);
    controller.dispose();
    read.complete(url);
    await pending;
    expect(prompts, 0);
  });

  test('locked state and permission denial are harmless', () async {
    var allowed = false;
    var reads = 0;
    final controller = ClipboardLinkController(
      canPrompt: () => allowed,
      readText: () async {
        reads++;
        throw PlatformException(code: 'denied');
      },
      confirm: (_) async => fail('no prompt expected'),
      open: (_) async => fail('no navigation expected'),
    );
    await controller.check();
    expect(reads, 0);
    allowed = true;
    await controller.check();
    expect(reads, 1);
    controller.dispose();
  });

  testWidgets('clipboard dialog stays bounded and cancel returns false',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bool? result;
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
          onPressed: () async {
            result = await ClipboardLinkDialog.show(context, url);
          },
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
    expect(result, isFalse);
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open link'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
