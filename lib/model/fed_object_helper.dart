import 'package:sqflite/sqflite.dart';

import 'fed_db_manager.dart';
import 'fed_object.dart';

class FedObjectHelper<T extends FedObject> {
  /// Helper is used as a runtime code/factory utility to create FedObject, manage database operations,...
  FedObjectHelper.makeHelper({
    required this.createNew,
    required this._tableName,
    this._dbManager,
  }) {
    _ref = createNew(this);
    manageModel = _ref.manageModel;
  }

  late T _ref;
  T Function(FedObjectHelper helper) createNew;

  FedDBManager? _dbManager;
  FedDBManager get dbManager {
    if (_dbManager != null) {
      return _dbManager!;
    } else {
      throw Exception(
        'DBManager must be set for helper ${runtimeType.toString()}',
      );
    }
  }

  set dbManager(FedDBManager value) {
    _dbManager = value;
  }

  String? _tableName;

  String get tableName {
    if (_tableName != null) {
      return _tableName!;
    } else {
      throw Exception(
        'Table name must be set for helper ${runtimeType.toString()}',
      );
    }
  }

  set tableName(String value) {
    _tableName = value;
  }

  Future<Database> getDatabase() async {
    return await dbManager.getDatabase();
  }

  late Future Function(Database db, int oldVersion, int newVersion) manageModel;

  Map<String, dynamic> toMap(T fedObject, {Set<String>? included, Set<String>? excluded}) {
    return fedObject.toMap(included:included, excluded: excluded);
  }

  T fromMap(Map<String, dynamic> map) {
    T fedObject = createNew(this);
    fedObject.loadMap(map);
    return fedObject;
  }

  // --- CRUD OPERATIONS ---

  /// Insert
  Future<String?> insert(T fedObject, {Set<String>? included, Set<String>? excluded}) async {
    return await fedObject.insert(included:included, excluded: excluded);
  }

  /// Update
  Future<String?> update(T fedObject, {Set<String>? included, Set<String>? excluded}) async {
    return await fedObject.update(included:included, excluded: excluded);
  }

  /// Save: create & update
  Future<String?> save(T fedObject, {Set<String>? included, Set<String>? excluded}) async {
    return await fedObject.save(included:included, excluded: excluded);
  }

  /// Load by Id
  Future<bool> load(T fedObject, [String? loadId]) async {
    return await fedObject.load(loadId);
  }

  /// Create a new object and load into it
  Future<T?> loadNew([String? loadId]) async {
    T fedObject = createNew(this);
    if (await load(fedObject, loadId)) {
      return fedObject;
    } else {
      return null;
    }
  }

  /// Load by a field like an unique code
  Future<bool> loadByField(
    T fedObject,
    String field,
    dynamic fieldValue,
  ) async {
    return await fedObject.loadByField(field, fieldValue);
  }

  /// Create a new object and load into it
  Future<T?> loadNewByField(
    String field,
    dynamic fieldValue,
  ) async {
    T fedObject = createNew(this);
    if (await loadByField(fedObject, field, fieldValue)) {
      return fedObject;
    } else {
      return null;
    }
  }

  /// Fetch an object by id
  Future<Map<String, dynamic>?> fetch(String? id) async {
    if (id == null) return null;

    final db = await dbManager.getDatabase();

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }


  /// Fetch an object by field
  Future<Map<String, dynamic>?> fetchByField(String field, dynamic fieldValue) async {
    if (fieldValue == null) return null;

    final db = await dbManager.getDatabase();

    bool columnExists = await isColumnExists(field);

    if (!columnExists) {
      throw ArgumentError('Invalid column name "$field"');
    }

    final maps = await db.query(
      tableName,
      where: '$field = ?',
      whereArgs: [fieldValue],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Get list
  Future<List<T>> getList({
    String? orderBy,
    String? where,
    List<Object>? whereArgs,
    int? limit,
  }) async {
    return await FedObject.getList(
      this,
      orderBy: orderBy,
      where: where,
      whereArgs: whereArgs,
      limit: limit,
    );
  }

  /// Delete by id
  Future<int> delete(String? delId) async {
    return await FedObject.delete(this, delId);
  }

  /// Check exist by id
  Future<bool> isExists(String? checkId) async {
    return await FedObject.isExists(this, checkId);
  }

  /// Check exist by a field like an unique Code
  Future<bool> isExistsByField(
    String? currentId,
    String? field,
    dynamic fieldValue,
  ) async {
    return await FedObject.isExistsByField(this, currentId, field, fieldValue);
  }

  /// Check if a table exists by name
  Future<bool> isTableExists(String? tableName) async {
    final db = await dbManager.getDatabase();
    return await FedDBManager.isTableExists(db, tableName);
  }

  /// Check if a column exists by name
  Future<bool> isColumnExists(
    String? columnName,
  ) async {
    final db = await dbManager.getDatabase();
    return await FedDBManager.isColumnExists(db, tableName, columnName);
  }

  /// Check if a field is included and not excluded
  bool incExc(String? field, Set<String>? included, Set<String>? excluded) {
    if (field == null) return false;
    return (included?.contains(field)??true) && !(excluded?.contains(field)??false);
  }
}
