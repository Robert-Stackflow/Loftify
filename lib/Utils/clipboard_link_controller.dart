import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import 'clipboard_snapshot.dart';
import 'hive_util.dart';
import 'uri_util.dart';

enum ClipboardLinkDecision { open, dismiss }

class ClipboardLinkStore {
  static const key = 'handledClipboardLinkV1';

  Map<dynamic, dynamic>? read() {
    final value = Hive.box(HiveUtil.settingsBox).get(key);
    return value is Map ? value : null;
  }

  Future<void> write(Map<String, dynamic> record) async {
    final box = Hive.box(HiveUtil.settingsBox);
    await box.put(key, record);
    await box.flush();
  }
}

/// Reads only on explicit lifecycle events; clipboard contents are never logged.
class ClipboardLinkController {
  ClipboardLinkController({
    required this.canPrompt,
    required this.confirm,
    required this.open,
    Future<ClipboardSnapshot?> Function()? readSnapshot,
    ClipboardLinkStore? store,
  })  : readSnapshot = readSnapshot ?? ClipboardSnapshotReader().read,
        _store = store ?? ClipboardLinkStore();

  final bool Function() canPrompt;
  final Future<ClipboardLinkDecision?> Function(String url) confirm;
  final Future<void> Function(String url) open;
  final Future<ClipboardSnapshot?> Function() readSnapshot;
  final ClipboardLinkStore _store;
  Map<dynamic, dynamic>? _lastHandled;
  bool _checking = false;
  bool _disposed = false;

  Future<void> check() async {
    if (_disposed || _checking || !canPrompt()) return;
    _checking = true;
    try {
      final snapshot = await readSnapshot();
      final text = snapshot?.text;
      if (_disposed || !canPrompt() || snapshot == null || text == null) return;
      final url = LoftifyUriUtil.extractSupportedClipboardUrl(text);
      if (url == null) return;
      try {
        _lastHandled ??= _store.read();
      } catch (_) {
        // A damaged/unavailable settings store must not prevent opening links.
      }
      if (snapshot.wasHandled(url, _lastHandled)) return;
      final decision = await confirm(url);
      // Barrier/back dismissal or app termination is not an explicit decision.
      if (decision == null) return;
      final record = snapshot.handledRecord(url);
      _lastHandled = record;
      try {
        await _store.write(record);
      } catch (_) {
        // Retain in-memory deduplication if disk persistence fails.
      }
      if (decision == ClipboardLinkDecision.open && !_disposed && canPrompt()) {
        await open(url);
      }
    } on PlatformException {
      // Clipboard permission/access can be denied; it must not interrupt the app.
    } on MissingPluginException {
      // Some embedded targets do not implement clipboard access.
    } finally {
      _checking = false;
    }
  }

  void dispose() => _disposed = true;
}
