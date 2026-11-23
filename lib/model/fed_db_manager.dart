import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'fed_storage_service.dart';

typedef DBManageModelFunc = Future<void> Function(
  Database db,
  int oldVersion,
  int version,
);

/// Each FedDBManager object is associated with one database. So the app can use several databases for performance or more purposes
class FedDBManager {
  FedDBManager({this.databaseName = 'default.db', this.version = 1});

  final String databaseName;
  final int version;

  @mustCallSuper
  Future<void> init() async {
    _db ??= await _initDB();
  }

  final List<DBManageModelFunc> _manageModelFuncs = [];

  void addModel(FedModelHelper helper) {
    helper.dbManager = this;
    _manageModelFuncs.add(helper.manageModel);
  }

  List<DBManageModelFunc> get manageModelFuncs {
    return _manageModelFuncs;
  }

  Database? _db;

  Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future close() async {
    await _db?.close();
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: version,
      onConfigure: (db) async {
        // Enable Write-Ahead Logging for concurrent read/write across isolates
        await db.rawQuery('PRAGMA journal_mode=WAL;');
        // Wait up to 5 seconds instead of throwing "database is locked" immediately
        await db.rawQuery('PRAGMA busy_timeout=5000;');
      },
      onCreate: (db, version) async {
        await _manageModelDBTables(db, -1, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _manageModelDBTables(db, oldVersion, newVersion);
      },
    );
  }

  Future _manageModelDBTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (var manageModelFunc in manageModelFuncs) {
      await manageModelFunc(db, oldVersion, newVersion);
    }
  }

  static Future<bool> isTableExists(Database db, String? tableName) async {
    if (tableName == null || tableName == '') return false;
    final List<Map<String, dynamic>> maps = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', tableName],
    );
    return maps.isNotEmpty;
  }

  static Future<bool> isColumnExists(
    Database db,
    String? tableName,
    String? columnName,
  ) async {
    if (tableName == null || tableName == '') return false;
    if (columnName == null || columnName == '') return false;
    // Query the table metadata using PRAGMA
    try {
      final List<Map<String, dynamic>> columns = await db.rawQuery(
        "PRAGMA table_info('$tableName')",
      );

      // Check if any row in the result contains our column name
      return columns.any((column) => column['name'] == columnName);
    } catch (e) {
      return false;
    }
  }
}
