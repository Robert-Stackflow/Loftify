import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Database/database_manager.dart';
import 'package:loftify/Utils/file_util.dart';
import 'package:sqflite/sqflite.dart';

import 'global_provider.dart';

abstract class ProviderManager {
  static bool _initialized = false;
  static GlobalProvider globalProvider = GlobalProvider();
  static late Database db;
  static GlobalKey<NavigatorState> desktopNavigatorKey =
      GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> globalNavigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    db = await DatabaseManager.getDataBase();
    await initHive();
  }

  static Future<void> initHive() async {
    Hive.defaultDirectory = await FileUtil.getApplicationDir();
  }

  static Brightness currentBrightness(BuildContext context) {
    return globalProvider.getBrightness() ??
        MediaQuery.of(context).platformBrightness;
  }
}
