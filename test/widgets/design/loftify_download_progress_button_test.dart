import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Theme/loftify_design_theme.dart';
import 'package:loftify/Widgets/Design/loftify_download_progress_button.dart';
import 'package:loftify/Widgets/loftify_icons.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/download_progress_button',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('real byte progress stays readable and blocks duplicate taps',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _TestApp(
        child: LoftifyDownloadProgressButton(
          label: 'Save this image',
          icon: LoftifyIcons.download,
          progress: 0.42,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.pump();

    final button = find.byType(LoftifyDownloadProgressButton);
    final semantics = tester.getSemantics(button);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('loftify-download-progress-track')),
    );
    expect(semantics.label, 'Save this image');
    expect(semantics.value, '42%');
    expect(progress.value, 0.42);
    expect(find.text('Save this image 42%'), findsOneWidget);
    await tester.tap(find.text('Save this image 42%'));
    await tester.pump();
    expect(taps, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('idle action remains reachable on narrow two-times text',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _TestApp(
        child: LoftifyDownloadProgressButton(
          label: 'Download the currently selected decoration image',
          icon: LoftifyIcons.download,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.text('Download the currently selected decoration image'),
    );
    await tester.pump();
    expect(taps, 1);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact card action exposes a real circular progress value',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _TestApp(
        child: LoftifyDownloadProgressIconButton(
          semanticLabel: 'Download decoration part',
          icon: LoftifyIcons.download,
          progress: 0.68,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.pump();

    final button = find.byType(LoftifyDownloadProgressIconButton);
    final semantics = tester.getSemantics(button);
    final progress = tester.widget<CircularProgressIndicator>(
      find.byKey(const ValueKey('loftify-download-progress-ring')),
    );
    expect(semantics.label, 'Download decoration part');
    expect(semantics.value, '68%');
    expect(progress.value, 0.68);
    await tester.tap(button);
    await tester.pump();
    expect(taps, 0);
    expect(tester.takeException(), isNull);
  });

  test('download progress button does not use Lottie loading feedback', () {
    final source = File(
      'lib/Widgets/Design/loftify_download_progress_button.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('LoftifyLottie')));
    expect(source, isNot(contains("package:lottie")));
    expect(source, contains('LinearProgressIndicator'));

    final sheetSource = File(
      'lib/Widgets/BottomSheet/custom_bg_avatar_detail_bottom_sheet.dart',
    ).readAsStringSync();
    expect(sheetSource, isNot(contains('CustomLoadingDialog')));
    expect(sheetSource, contains('LoftifyFileUtil.saveImage'));
    expect(sheetSource, contains('LoftifyFileUtil.saveImages'));

    for (final path in <String>[
      'lib/Screens/Suit/emote_detail_screen.dart',
      'lib/Screens/Suit/dress_detail_screen.dart',
    ]) {
      final detailSource = File(path).readAsStringSync();
      expect(detailSource, isNot(contains('CustomLoadingDialog')),
          reason: path);
      expect(detailSource, contains('LoftifyFileUtil.saveImage'), reason: path);
      expect(detailSource, contains('_downloadProgress'), reason: path);
    }
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: LoftifyTheme.build(
        ChewieThemeColorData.defaultLightThemes.first,
      ),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(280, 568),
          textScaler: TextScaler.linear(2),
        ),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: 260, child: child),
          ),
        ),
      ),
    );
  }
}
