import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:loftify/Database/database_manager.dart';
import 'package:sqflite/sqflite.dart';

import '../Utils/hive_util.dart';
import 'global_provider.dart';

abstract class ProviderManager {
  static bool _initialized = false;
  static GlobalProvider globalProvider = GlobalProvider();
  static late Database db;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    db = await DatabaseManager.getDataBase();
    await initHive();
  }

  static Future<void> initHive() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await Hive.initFlutter(HiveUtil.database);
    } else {
      await Hive.initFlutter();
    }
    await HiveUtil.openHiveBox(HiveUtil.settingsBox);
  }

  static Brightness currentBrightness(BuildContext context) {
    return globalProvider.getBrightness() ??
        MediaQuery.of(context).platformBrightness;
  }
}
