import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/clipboard_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const url = 'https://example.lofter.com/';
  for (final platform in ['windows', 'iOS', 'macOS']) {
    test(
        '$platform handles restart, recopy, counter reset and uncertain clocks',
        () {
      ClipboardSnapshot sample(
              {String revision = '20',
              int time = 100000,
              int? uptime = 50000}) =>
          ClipboardSnapshot(
              text: url,
              platform: platform,
              revision: revision,
              observedAtMs: time,
              uptimeMs: uptime);
      final saved = sample().handledRecord(url);
      expect(
          sample(time: 200000, uptime: 150000).wasHandled(url, saved), isTrue);
      expect(sample(revision: '21').wasHandled(url, saved), isFalse);
      expect(
          sample(revision: '1', time: 200000, uptime: 1000)
              .wasHandled(url, saved),
          isFalse);
      // Even coincidentally equal counters after reboot must not suppress.
      expect(
          sample(time: 200000, uptime: 1000).wasHandled(url, saved), isFalse);
      expect(
          sample(time: 500000, uptime: 150000).wasHandled(url, saved), isFalse);
      expect(sample(uptime: null).wasHandled(url, saved), isFalse);
      expect(
          sample().wasHandled('https://another.lofter.com/', saved), isFalse);
      expect(sample().wasHandled(url, {'schema': 0}), isFalse);
    });
  }

  test(
      'reader retries concurrent clipboard changes before pairing text and metadata',
      () async {
    var reads = 0;
    final reader = ClipboardSnapshotReader(
      platform: 'windows',
      now: () => 1000,
      readText: () async => reads == 1 ? 'old text' : url,
      readMetadata: () async => {
        'revision': (++reads == 1 ? '1' : '2'),
        'uptimeMs': 500,
      },
    );
    final result = await reader.read();
    expect(reads, 4);
    expect(result!.text, url);
    expect(result.revision, '2');
    expect(result.uptimeMs, 500);
  });

  test('unstable clipboard is skipped instead of showing mismatched content',
      () async {
    var reads = 0;
    final reader = ClipboardSnapshotReader(
      readText: () async => url,
      readMetadata: () async => {'revision': '${++reads}'},
    );
    expect(await reader.read(), isNull);
    expect(reads, 4);
  });

  test('native metadata channel and unsupported-platform fallback', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async => {'text': url});
    messenger.setMockMethodCallHandler(ClipboardSnapshotReader.channel,
        (call) async {
      expect(call.method, 'getMetadata');
      return {'revision': '1234', 'uptimeMs': 500};
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      messenger.setMockMethodCallHandler(ClipboardSnapshotReader.channel, null);
    });
    final reader = ClipboardSnapshotReader(platform: 'android');
    expect((await reader.read())!.revision, '1234');
    messenger.setMockMethodCallHandler(ClipboardSnapshotReader.channel, null);
    final fallback = await reader.read();
    expect(fallback!.text, url);
    expect(fallback.revision, isNull);
    messenger.setMockMethodCallHandler(ClipboardSnapshotReader.channel,
        (call) async {
      throw PlatformException(code: 'clipboard_unavailable');
    });
    await expectLater(reader.read(), throwsA(isA<PlatformException>()));
  });
}
