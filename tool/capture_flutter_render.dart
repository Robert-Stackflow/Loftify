import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 2 || arguments.length > 4) {
    stderr.writeln(
      'Usage: dart run tool/capture_flutter_render.dart '
      '<vm-service-uri> <output.png> [width] [height]',
    );
    exitCode = 64;
    return;
  }

  final serviceUri = Uri.parse(arguments[0]);
  final output = File(arguments[1]);
  final width = arguments.length > 2 ? double.parse(arguments[2]) : 430.0;
  final height = arguments.length > 3 ? double.parse(arguments[3]) : 940.0;
  final service =
      await vmServiceConnectUri(flutterRenderWebSocketUri(serviceUri));
  const objectGroup = 'loftify-render-capture';

  try {
    final vm = await service.getVM();
    final isolate = vm.isolates?.where((entry) => entry.id != null).firstOrNull;
    if (isolate?.id == null) {
      throw StateError('The VM service did not expose a runnable isolate.');
    }

    final rootResponse = await service.callServiceExtension(
      'ext.flutter.inspector.getRootWidget',
      isolateId: isolate!.id,
      args: const {'objectGroup': objectGroup},
    );
    final root = rootResponse.json?['result'];
    final rootId = root is Map ? root['valueId'] as String? : null;
    if (rootId == null) {
      throw StateError('The Flutter inspector did not expose a root element.');
    }

    final screenshotResponse = await service.callServiceExtension(
      'ext.flutter.inspector.screenshot',
      isolateId: isolate.id,
      args: {
        'id': rootId,
        'width': '$width',
        'height': '$height',
        'maxPixelRatio': '3.0',
        'debugPaint': 'false',
      },
    );
    final encoded = screenshotResponse.json?['result'];
    if (encoded is! String || encoded.isEmpty) {
      throw StateError('The Flutter inspector returned no screenshot.');
    }

    await output.parent.create(recursive: true);
    await output.writeAsBytes(base64Decode(encoded), flush: true);
    stdout.writeln(output.absolute.path);
  } finally {
    try {
      final vm = await service.getVM();
      final isolateId =
          vm.isolates?.where((entry) => entry.id != null).firstOrNull?.id;
      if (isolateId != null) {
        await service.callServiceExtension(
          'ext.flutter.inspector.disposeGroup',
          isolateId: isolateId,
          args: const {'objectGroup': objectGroup},
        );
      }
    } catch (_) {
      // The screenshot is already safely written; cleanup is best effort.
    }
    await service.dispose();
  }
}

String flutterRenderWebSocketUri(Uri serviceUri) {
  final path = serviceUri.path.endsWith('/ws')
      ? serviceUri.path
      : serviceUri.path.endsWith('/')
          ? '${serviceUri.path}ws'
          : '${serviceUri.path}/ws';
  return serviceUri
      .replace(
        scheme: switch (serviceUri.scheme) {
          'https' => 'wss',
          'wss' => 'wss',
          _ => 'ws',
        },
        path: path,
      )
      .toString();
}
