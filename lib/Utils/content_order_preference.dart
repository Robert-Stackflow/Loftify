import 'package:hive/hive.dart';

import 'hive_util.dart';

enum ContentOrderType { collection, grain }

/// The collection detail page and its directory sheet share one preference.
/// Grain order is independent because it uses a separate content type.
class ContentOrderPreference {
  const ContentOrderPreference._();

  static String _key(ContentOrderType type) => switch (type) {
        ContentOrderType.collection => HiveUtil.collectionOldestFirstKey,
        ContentOrderType.grain => HiveUtil.grainOldestFirstKey,
      };

  static bool read(ContentOrderType type) {
    final value = Hive.box(HiveUtil.settingsBox).get(_key(type));
    return value is bool ? value : false;
  }

  static Future<void> write(ContentOrderType type, bool oldestFirst) =>
      Hive.box(HiveUtil.settingsBox).put(_key(type), oldestFirst);
}
