import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Utils/content_order_preference.dart';
import 'package:loftify/Utils/hive_util.dart';

void main() {
  setUpAll(() async {
    final directory = Directory('build/test_hive/content_order_preference');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    await Hive.openBox(HiveUtil.settingsBox);
  });

  setUp(() async {
    if (!Hive.isBoxOpen(HiveUtil.settingsBox)) {
      await Hive.openBox(HiveUtil.settingsBox);
    }
    await Hive.box(HiveUtil.settingsBox).clear();
  });

  tearDownAll(() async => Hive.close());

  test('both content types default to descending order', () {
    expect(ContentOrderPreference.read(ContentOrderType.collection), isFalse);
    expect(ContentOrderPreference.read(ContentOrderType.grain), isFalse);
  });

  test('collection and grain remember independent choices', () async {
    await ContentOrderPreference.write(ContentOrderType.collection, true);
    expect(ContentOrderPreference.read(ContentOrderType.collection), isTrue);
    expect(ContentOrderPreference.read(ContentOrderType.grain), isFalse);

    await ContentOrderPreference.write(ContentOrderType.grain, true);
    await ContentOrderPreference.write(ContentOrderType.collection, false);
    expect(ContentOrderPreference.read(ContentOrderType.collection), isFalse);
    expect(ContentOrderPreference.read(ContentOrderType.grain), isTrue);
  });

  test('saved order survives reopening the settings box', () async {
    await ContentOrderPreference.write(ContentOrderType.collection, true);
    await Hive.box(HiveUtil.settingsBox).close();
    await Hive.openBox(HiveUtil.settingsBox);

    expect(ContentOrderPreference.read(ContentOrderType.collection), isTrue);
  });

  test('invalid saved values fall back to descending order', () async {
    await Hive.box(HiveUtil.settingsBox)
        .put(HiveUtil.grainOldestFirstKey, 'invalid');
    expect(ContentOrderPreference.read(ContentOrderType.grain), isFalse);
  });
}
