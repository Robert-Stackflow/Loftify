import 'package:flutter_test/flutter_test.dart';

import '../../tool/capture_flutter_render.dart';

void main() {
  test('converts HTTP VM service URIs to inspector WebSocket URIs', () {
    expect(
      flutterRenderWebSocketUri(
        Uri.parse('http://127.0.0.1:58789/secure-token=/'),
      ),
      'ws://127.0.0.1:58789/secure-token=/ws',
    );
    expect(
      flutterRenderWebSocketUri(
        Uri.parse('https://example.test/service/'),
      ),
      'wss://example.test/service/ws',
    );
  });

  test('keeps an existing WebSocket screenshot endpoint stable', () {
    expect(
      flutterRenderWebSocketUri(
        Uri.parse('ws://127.0.0.1:58789/secure-token=/ws'),
      ),
      'ws://127.0.0.1:58789/secure-token=/ws',
    );
  });
}
