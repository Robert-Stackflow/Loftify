import 'dart:io';
import 'package:hive/hive.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Models/collection_response.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Widgets/Item/loftify_item_builder.dart';
import 'package:loftify/generated/app_localizations.dart';

class _Collection extends Fake implements Collection {
  @override
  String get name => 'A long collection of creative works';
  @override
  String get coverUrl => '';
  @override
  int get postCount => 123456789;
  @override
  int get lastPublishTime => 1700000000000;
  @override
  List<String> get tags =>
      ['Photography and creative illustration', 'last-tag'];
}

class _Grain extends Fake implements GrainInfo {
  @override
  String get name => 'A long selection of creative works';
  @override
  String get coverUrl => '';
  @override
  int get postCount => 123456789;
  @override
  int get updateTime => 1700000000000;
  @override
  List<String> get tags =>
      ['Photography and creative illustration', 'last-tag'];
}

void main() {
  setUpAll(() async {
    final dir = Directory('build/test_hive/search_collection_rows');
    await dir.create(recursive: true);
    Hive.init(dir.absolute.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
  });
  for (final grain in [false, true]) {
    for (final locale in [
      const Locale('en'),
      const Locale('zh'),
      const Locale('zh', 'TW')
    ]) {
      for (final width in [280.0, 720.0]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
              'search collection grain=$grain $locale width=$width scale=$scale',
              (tester) async {
            tester.view.physicalSize = Size(width, 480);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            var taps = 0;
            await tester.pumpWidget(MaterialApp(
              locale: locale,
              theme:
                  ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                ChewieLocalizations.delegate,
                ...AppLocalizations.localizationsDelegates
              ],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Builder(builder: (context) {
                chewieProvider.setRootContext(context);
                return Scaffold(
                    body: SingleChildScrollView(
                        child: grain
                            ? LoftifyItemBuilder.buildGrainRow(
                                context, _Grain(), onTap: () => taps++)
                            : LoftifyItemBuilder.buildCollectionRow(
                                context, _Collection(),
                                onTap: () => taps++)));
              }),
            ));
            await tester.pump();
            expect(tester.takeException(), isNull);
            final name = find.text(grain ? _Grain().name : _Collection().name);
            await tester.tap(name);
            expect(taps, 1);
            final tags = find.text('#last-tag');
            await tester.ensureVisible(tags);
            await tester.pump();
            expect(tags.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
