import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('content center keeps downloads and moves dress after it', () {
    final source = File(
      'lib/Screens/Navigation/mine_screen.dart',
    ).readAsStringSync();
    final contentStart = source.indexOf('List<Widget> _buildContent()');
    final creationStart = source.indexOf('List<Widget> _buildCreation()');

    expect(contentStart, isNonNegative);
    expect(creationStart, greaterThan(contentStart));

    final contentSource = source.substring(contentStart, creationStart);
    final historyStart = contentSource.indexOf(
      'title: appLocalizations.myHistory',
    );
    final downloadStart = contentSource.indexOf(
      'title: appLocalizations.downloadManagement',
    );
    final dressStart = contentSource.indexOf(
      'title: appLocalizations.dress',
    );

    expect(historyStart, isNonNegative);
    expect(downloadStart, greaterThan(historyStart));
    expect(dressStart, greaterThan(downloadStart));
    expect(
      contentSource.substring(historyStart, downloadStart),
      isNot(contains('roundBottom: true')),
    );
    expect(
      contentSource.substring(downloadStart),
      allOf(
        contains('const DownloadManagementScreen()'),
        contains('leading: LoftifyIcons.download'),
      ),
    );
    expect(contentSource, contains('LoftifySection('));
    expect(contentSource, contains('LoftifyEntryItem('));
    expect(contentSource, contains('const SuitScreen()'));
  });

  test('image settings do not duplicate the download manager entrance', () {
    final source = File(
      'lib/Screens/Setting/image_setting_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('DownloadManagementScreen')));
    expect(source, isNot(contains('appLocalizations.downloadManagement')));
    expect(source, contains('appLocalizations.downloadImagePath'));
    expect(source, contains('appLocalizations.filenameFormat'));
  });
}
