import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:loftify/Utils/clipboard_link_controller.dart';
import 'package:loftify/Utils/clipboard_snapshot.dart';
import 'package:loftify/Utils/uri_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final directory =
        await Directory.systemTemp.createTemp('loftify_clipboard_test_');
    Hive.init(directory.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
  });
  setUp(() async => Hive.box(ChewieHiveUtil.settingsBox).clear());
  tearDownAll(Hive.close);
  const url = 'https://ruiiiiii.lofter.com/post/1dd2a51a_34f468525';
  ClipboardSnapshot snapshot(String text, {String? revision = '100'}) =>
      ClipboardSnapshot(
        text: text,
        platform: 'android',
        revision: revision,
        observedAtMs: 1000,
      );
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
      readSnapshot: () async => snapshot(text),
      confirm: (_) async {
        prompts++;
        return accepted
            ? ClipboardLinkDecision.open
            : ClipboardLinkDecision.dismiss;
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
    final read = Completer<ClipboardSnapshot?>();
    var prompts = 0;
    var reads = 0;
    final controller = ClipboardLinkController(
      canPrompt: () => true,
      readSnapshot: () {
        reads++;
        return read.future;
      },
      confirm: (_) async {
        prompts++;
        return ClipboardLinkDecision.open;
      },
      open: (_) async => fail('disposed controller must not navigate'),
    );
    final pending = controller.check();
    await controller.check();
    expect(reads, 1);
    controller.dispose();
    read.complete(snapshot(url));
    await pending;
    expect(prompts, 0);
  });

  test('locked state and permission denial are harmless', () async {
    var allowed = false;
    var reads = 0;
    final controller = ClipboardLinkController(
      canPrompt: () => allowed,
      readSnapshot: () async {
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

  for (final decision in ClipboardLinkDecision.values) {
    test('$decision persists across restart; recopying the URL prompts again',
        () async {
      var prompts = 0;
      var opens = 0;
      var revision = '100';
      ClipboardLinkController create() => ClipboardLinkController(
            canPrompt: () => true,
            readSnapshot: () async => snapshot(url, revision: revision),
            confirm: (_) async {
              prompts++;
              return decision;
            },
            open: (_) async {
              // The explicit choice must already be on disk before navigation.
              expect(ClipboardLinkStore().read(), isNotNull);
              opens++;
            },
          );
      final first = create();
      await first.check();
      first.dispose();
      await Hive.box(ChewieHiveUtil.settingsBox).close();
      await Hive.openBox(ChewieHiveUtil.settingsBox);
      final restarted = create();
      await restarted.check();
      expect(prompts, 1);
      expect(opens, decision == ClipboardLinkDecision.open ? 1 : 0);
      expect(ClipboardLinkStore().read().toString(), isNot(contains(url)));
      revision = '200';
      await restarted.check();
      expect(prompts, 2);
      restarted.dispose();
    });
  }

  test('no decision is not persisted or suppressed on next foreground check',
      () async {
    var prompts = 0;
    ClipboardLinkController create() => ClipboardLinkController(
          canPrompt: () => true,
          readSnapshot: () async => snapshot(url),
          confirm: (_) async {
            prompts++;
            return null;
          },
          open: (_) async => fail('must not open'),
        );
    final first = create();
    await first.check();
    await first.check();
    expect(prompts, 2);
    expect(ClipboardLinkStore().read(), isNull);
    first.dispose();
    final restarted = create();
    await restarted.check();
    expect(prompts, 3);
    restarted.dispose();
  });

  test('copy during a dialog does not mark the new clipboard as handled',
      () async {
    var revision = '100';
    var prompts = 0;
    final controller = ClipboardLinkController(
      canPrompt: () => true,
      readSnapshot: () async => snapshot(url, revision: revision),
      confirm: (_) async {
        prompts++;
        revision = '200';
        return ClipboardLinkDecision.dismiss;
      },
      open: (_) async => fail('must not open'),
    );
    await controller.check();
    await controller.check();
    await controller.check();
    expect(prompts, 2);
    controller.dispose();
  });

  test('missing metadata falls back to persisted URL fingerprint', () async {
    var prompts = 0;
    ClipboardLinkController create() => ClipboardLinkController(
          canPrompt: () => true,
          readSnapshot: () async => snapshot(url, revision: null),
          confirm: (_) async {
            prompts++;
            return ClipboardLinkDecision.dismiss;
          },
          open: (_) async => fail('must not open'),
        );
    final first = create();
    await first.check();
    first.dispose();
    final second = create();
    await second.check();
    expect(prompts, 1);
    second.dispose();
  });
}
