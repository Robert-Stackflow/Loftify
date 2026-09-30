import 'package:flutter/services.dart';

import 'uri_util.dart';

/// Reads only on explicit lifecycle events; clipboard contents are never logged.
class ClipboardLinkController {
  ClipboardLinkController({
    required this.canPrompt,
    required this.confirm,
    required this.open,
    Future<String?> Function()? readText,
  }) : readText = readText ?? _readClipboard;

  final bool Function() canPrompt;
  final Future<bool> Function(String url) confirm;
  final Future<void> Function(String url) open;
  final Future<String?> Function() readText;
  final Set<String> _seen = {};
  bool _checking = false;
  bool _disposed = false;

  static Future<String?> _readClipboard() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  Future<void> check() async {
    if (_disposed || _checking || !canPrompt()) return;
    _checking = true;
    try {
      final text = await readText();
      if (_disposed || !canPrompt() || text == null) return;
      final url = LoftifyUriUtil.extractSupportedClipboardUrl(text);
      if (url == null || _seen.contains(url)) return;
      _seen.add(url);
      if (_seen.length > 64) _seen.remove(_seen.first);
      final accepted = await confirm(url);
      if (accepted && !_disposed && canPrompt()) await open(url);
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
