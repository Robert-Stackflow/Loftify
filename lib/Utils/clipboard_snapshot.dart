import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ClipboardSnapshot {
  const ClipboardSnapshot({
    required this.text,
    required this.platform,
    required this.observedAtMs,
    this.revision,
    this.uptimeMs,
  });

  final String? text;
  final String platform;
  final String? revision;
  final int? uptimeMs;
  final int observedAtMs;

  Map<String, dynamic> handledRecord(String url) => {
        'schema': 1,
        'fingerprint': sha256.convert(utf8.encode(url)).toString(),
        'platform': platform,
        'revision': revision,
        'uptimeMs': uptimeMs,
        'observedAtMs': observedAtMs,
      };

  bool wasHandled(String url, Map<dynamic, dynamic>? record) {
    if (record == null ||
        record['schema'] != 1 ||
        record['platform'] != platform ||
        record['fingerprint'] != sha256.convert(utf8.encode(url)).toString()) {
      return false;
    }
    // Older Android / unsupported platforms cannot distinguish recopying the
    // same URL. Use content-only deduplication only when both lack metadata.
    if (revision == null || record['revision'] == null) {
      return revision == null && record['revision'] == null;
    }
    if (record['revision'] != revision) return false;
    // Android's revision is a wall-clock copy timestamp, not a resettable count.
    if (platform == 'android') return true;

    final previousUptime = record['uptimeMs'];
    final previousTime = record['observedAtMs'];
    if (uptimeMs == null || previousUptime is! int || previousTime is! int) {
      return false;
    }
    final elapsed = observedAtMs - previousTime;
    final runningElapsed = uptimeMs! - previousUptime;
    // Counter values may be reused after a reboot. Compare elapsed times
    // between observations as well. Clock changes / uncertain sessions prompt
    // again instead of silently suppressing a newly copied link.
    return elapsed >= 0 &&
        runningElapsed >= 0 &&
        (elapsed - runningElapsed).abs() <= 5000;
  }
}

class ClipboardSnapshotReader {
  ClipboardSnapshotReader({
    Future<Map<Object?, Object?>?> Function()? readMetadata,
    Future<String?> Function()? readText,
    int Function()? now,
    String? platform,
  })  : _readMetadata = readMetadata ?? _nativeMetadata,
        _readText = readText ?? _clipboardText,
        _now = now ?? (() => DateTime.now().millisecondsSinceEpoch),
        _platform = platform ?? (kIsWeb ? 'web' : defaultTargetPlatform.name);

  static const channel = MethodChannel('loftify/clipboard');
  final Future<Map<Object?, Object?>?> Function() _readMetadata;
  final Future<String?> Function() _readText;
  final int Function() _now;
  final String _platform;

  static Future<Map<Object?, Object?>?> _nativeMetadata() async {
    try {
      return await channel.invokeMapMethod<Object?, Object?>('getMetadata');
    } on MissingPluginException {
      return null;
    }
  }

  static Future<String?> _clipboardText() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  Future<ClipboardSnapshot?> read() async {
    // Text is read through Flutter's platform implementation. Read the version
    // on both sides so a concurrent copy cannot pair old text with a new count.
    for (var attempt = 0; attempt < 2; attempt++) {
      final before = await _readMetadata();
      final text = await _readText();
      final after = await _readMetadata();
      if (before?['revision'] != after?['revision']) continue;
      final revision = after?['revision'];
      final uptime = after?['uptimeMs'];
      return ClipboardSnapshot(
        text: text,
        platform: _platform,
        revision: revision is String && revision.isNotEmpty ? revision : null,
        uptimeMs: uptime is int && uptime >= 0 ? uptime : null,
        observedAtMs: _now(),
      );
    }
    return null;
  }
}
