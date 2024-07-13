import 'dart:async';
import 'dart:io';

import 'package:loftify/Database/create_table_sql.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseManager {
  static const _dbName = "loftify.db";
  static const _dbVersion = 1;
  static Database? _database;

  static Future<Database> getDataBase() async {
    if (_database == null) {
      await _initDataBase();
    }
    return _database!;
  }

  static Future<void> _initDataBase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
    }
    databaseFactory = databaseFactoryFfi;
    if (_database == null) {
      String path = join(await getDatabasesPath(), _dbName);
      _database =
          await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(CreateTableSql.rssItems.sql);
  }

  static Future<void> createTable({
    required String tableName,
    required String sql,
  }) async {
    if (await isTableExist(tableName) == false) {
      await (await getDataBase()).execute(sql);
    }
  }

  static Future<bool> isTableExist(String tableName) async {
    var result = await (await getDataBase()).rawQuery(
        "select * from Sqlite_master where type = 'table' and name = '$tableName'");
    return result.isNotEmpty;
  }
}
