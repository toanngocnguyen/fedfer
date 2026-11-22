import 'package:meta/meta.dart';

import 'package:uuid/uuid.dart';

import 'package:sqflite/sqflite.dart';

import 'fed_db_manager.dart';
import 'fed_storage_service.dart';

abstract class FedObject {
  String? id;

  FedObject({this.id, required this.storage});

  // Convert an object into a Map. Object keys must match database columns.
  @mustBeOverridden
  Map<String, dynamic> toMap({Set<String>? included, Set<String>? excluded}) {
    return {'id': id};
  }

  // load properties from a Map (database row) into current object.
  @mustBeOverridden
  void loadMap(Map<String, dynamic> map) {}

  // Convert a Map (database row) into a new object.
  static T fromMap<T extends FedObject>(
    FedStorageService<T> storage,
    Map<String, dynamic> map,
  ) {
    T fedObject = storage.createNew(storage);
    fedObject.loadMap(map);
    return fedObject;
  }

  // --- Metadata definition ---

  /// Helper for storage activities: CRUD,...
  FedStorageService storage;

  @mustBeOverridden
  Future manageModel(Database db, int oldVersion, int newVersion) async {
    // onCreate model
    if (oldVersion == -1) {
      _createTable(db, newVersion);
    }
    // onUpgrade model
    else {}
  }

  Future _createTable(Database db, int newVersion) async {
    bool bExisted = await FedDBManager.isTableExists(db, storage.tableName);

    if (!bExisted) {
      await db.execute('''
      CREATE TABLE ${storage.tableName} (
        id TEXT PRIMARY KEY
      )
      ''');
    }
  }

  // --- FIELDS BY NAME ---

  dynamic operator [](String fieldName) {}

  // --- CRUD OPERATIONS ---

  // Insert
  Future<String?> insert({Set<String>? included, Set<String>? excluded}) async {
    final db = await storage.dbManager.getDatabase();
    if (id == null || id == '') {
      id = Uuid().v7();
    }

    await db.insert(
      storage.tableName,
      toMap(included: included, excluded: excluded),
    );

    return id;
  }

  // Update
  Future<String?> update({Set<String>? included, Set<String>? excluded}) async {
    final db = await storage.dbManager.getDatabase();
    if (id == null || id == '') {
      return null;
    } else {
      await db.update(
        storage.tableName,
        toMap(included: included, excluded: excluded),
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    return id;
  }

  // Save: create & update
  Future<String?> save({Set<String>? included, Set<String>? excluded}) async {
    final db = await storage.dbManager.getDatabase();
    if (id == null || id == '') {
      id = Uuid().v7();

      await db.insert(
        storage.tableName,
        toMap(included: included, excluded: excluded),
      );
    } else {
      bool exists = await FedObject.isExists(storage, id!);

      if (exists) {
        await db.update(
          storage.tableName,
          toMap(included: included, excluded: excluded),
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.insert(
          storage.tableName,
          toMap(included: included, excluded: excluded),
        );
      }
    }

    return id;
  }

  // Load by Id
  Future<bool> load([String? loadId]) async {
    final db = await storage.dbManager.getDatabase();

    if (loadId != null) id = loadId;

    final result = await db.query(
      storage.tableName,
      //columns: ['id'],
      where: 'id = ?',
      whereArgs: [loadId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      loadMap(result[0]);
    }
    return result.isNotEmpty;
  }

  // Load by a field like an unique Code
  Future<bool> loadByField(String field, dynamic fieldValue) async {
    final db = await storage.dbManager.getDatabase();

    bool columnExists = await storage.isColumnExists(field);

    if (!columnExists) {
      throw ArgumentError('Invalid column name "$field"');
    }

    final result = await db.query(
      storage.tableName,
      where: '$field = ?',
      whereArgs: [fieldValue],
      limit: 1,
    );

    if (result.isNotEmpty) {
      loadMap(result[0]);
    }
    return result.isNotEmpty;
  }

  // Get list
  static Future<List<T>> getList<T extends FedObject>(
    FedStorageService<T> helper, {
    String? orderBy,
    String? where,
    List<Object>? whereArgs,
    int? limit,
  }) async {
    final db = await helper.dbManager.getDatabase();
    final result = await db.query(
      helper.tableName,
      orderBy: orderBy,
      where: where,
      whereArgs: whereArgs,
      limit: limit,
    );

    return result.map((json) => FedObject.fromMap<T>(helper, json)).toList();
  }

  // Delete, return number of rows affected
  static Future<int> delete(FedStorageService helper, String? delId) async {
    if (delId == null) return 0;

    final db = await helper.dbManager.getDatabase();
    return await db.delete(
      helper.tableName,
      where: 'id = ?',
      whereArgs: [delId],
    );
  }

  // Check exist
  static Future<bool> isExists(
    FedStorageService helper,
    String? checkId,
  ) async {
    if (checkId == null) return false;

    final db = await helper.dbManager.getDatabase();

    final result = await db.query(
      helper.tableName,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [checkId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Check exist by a field like an unique Code, Email,...
  static Future<bool> isExistsByField(
    FedStorageService helper,
    String? currentId,
    String? field,
    dynamic fieldValue,
  ) async {
    if (field == null) return false;

    final db = await helper.dbManager.getDatabase();

    bool columnExists = await helper.isColumnExists(field);

    if (!columnExists) {
      throw ArgumentError('Invalid column name "$field"');
    }

    if (currentId == null || currentId == '') {
      final result = await db.query(
        helper.tableName,
        columns: ['id'],
        where: '$field = ?',
        whereArgs: [fieldValue],
        limit: 1,
      );

      return result.isNotEmpty;
    } else {
      final result = await db.query(
        helper.tableName,
        columns: ['id'],
        where: 'id <> ? and $field = ?',
        whereArgs: [field, fieldValue],
        limit: 1,
      );

      return result.isNotEmpty;
    }
  }

  /// Extended code after creation or other actions
  FedObject more(void Function(FedObject) moreAction) {
    moreAction(this);
    return this;
  }
}
