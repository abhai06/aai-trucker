import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper.internal();

  factory DBHelper() => _instance;

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }

    _db = await initDB();
    return _db!;
  }

  DBHelper.internal();

  initDB() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'trams.db');

    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  void _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE attachment (id INTEGER PRIMARY KEY, attach TEXT, booking_id INTEGER, runsheet_id INTEGER, task_code TEXT)');
    await db.execute('CREATE TABLE tasks (id INTEGER PRIMARY KEY, code TEXT, name TEXT, sequence_no INTEGER, task TEXT)');
    await db.execute('CREATE TABLE exception (id INTEGER PRIMARY KEY, code TEXT, name TEXT, description TEXT, task_id INTEGER)');
    await db.execute('CREATE TABLE runsheet (id INTEGER PRIMARY KEY, runsheet_id INTEGER, date_from TEXT, date_to TEXT, plate_no TEXT, reference TEXT, status TEXT)');
    await db.execute('CREATE TABLE booking (id INTEGER PRIMARY KEY, booking_id INTEGER, runsheet_id INTEGER, customer TEXT, delivery_expected_date TEXT, delivery_city TEXT, delivery_name TEXT, delivery_other_address TEXT, delivery_contact_no TEXT, delivery_contact_person TEXT, item_cbm REAL, item_qty REAL, item_sqm REAL, item_weight REAL, pickup_contact_no TEXT, pickup_contact_person TEXT, pickup_city TEXT, pickup_expected_date TEXT, pickup_name TEXT, pickup_other_address TEXT, reference TEXT, remarks TEXT, status TEXT, status_name TEXT, task TEXT, sequence_no INTEGER)');
    await db.execute('CREATE TABLE booking_logs (id INTEGER PRIMARY KEY, task TEXT, task_type TEXT, task_code TEXT, contact_person TEXT, receive_by TEXT, datetime TEXT, note TEXT, booking_id INTEGER, runsheet_id INTEGER, task_exception TEXT, flag INTEGER)');
  }

  save(String table, data, {String? pkey}) async {
    var dbClient = await db;
    try {
      for (var item in data) {
        final record = await dbClient.query(table, where: '$pkey = ?', whereArgs: [
          item[pkey]
        ]);
        if (record.isNotEmpty) {
          await dbClient.update(table, item, where: '$pkey = ?', whereArgs: [
            item[pkey]
          ]);
        } else {
          await dbClient.insert(table, item, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    } catch (e) {
      print('Error on saving : $e');
    }
  }

  saveBooking(String table, data) async {
    var dbClient = await db;
    try {
      for (var item in data) {
        final record = await dbClient.query(table, where: 'source_id = ? AND task = ? AND runsheet_id = ?', whereArgs: [
          item['source_id'],
          item['task'],
          item['runsheet_id']
        ]);
        if (record.isNotEmpty) {
          await dbClient.update(table, item, where: 'source_id = ? AND task = ? AND runsheet_id = ?', whereArgs: [
            item['source_id'],
            item['task'],
            item['runsheet_id']
          ]);
        } else {
          await dbClient.insert(table, item, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    } catch (e) {
      print('Error on saving : $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAll(String table, {String? whereCondition, List<dynamic>? whereArgs, String? orderBy, String? join}) async {
    var dbClient = await db;
    List<Map<String, Object?>> result = [];
    try {
      if (whereCondition != null) {
        result = await dbClient.query(table, where: whereCondition, whereArgs: whereArgs, orderBy: orderBy);
      } else {
        result = await dbClient.query(table);
      }
    } catch (e) {
      print(e);
    }
    return result.toList();
  }

  Future<List<Map<String, dynamic>>> getDelivery(String table, {String? whereCondition, List<dynamic>? whereArgs, String? orderBy}) async {
    var dbClient = await db;
    List<Map<String, Object?>> result = [];
    try {
      if (whereCondition != null) {
        result = await dbClient.query(table,
            columns: [
              'id',
              'runsheet_id',
              'booking_id',
              'customer',
              'delivery_expected_date',
              'delivery_city',
              'delivery_name',
              'delivery_other_address',
              'delivery_contact_no',
              'delivery_contact_person',
              'item_cbm',
              'item_qty',
              'item_sqm',
              'item_weight',
              'pickup_city',
              'pickup_contact_no',
              'pickup_contact_person',
              'pickup_expected_date',
              'pickup_name',
              'pickup_other_address',
              'reference',
              'remarks',
              'status',
              'status_name',
              'task',
              "(SELECT bk.status from $table as bk WHERE bk.runsheet_id = $table.runsheet_id AND bk.task = 'PICKUP') as pick_stat"
            ],
            where: whereCondition,
            whereArgs: whereArgs,
            orderBy: orderBy);
      } else {
        result = await dbClient.query(table);
      }
    } catch (e) {
      print(e);
    }
    return result.toList();
  }

  Future<int?> getCount(String table) async {
    var dbClient = await db;
    return Sqflite.firstIntValue(await dbClient.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  getData(String table, {String? whereCondition, List<dynamic>? whereArgs, String? orderBy}) async {
    var dbClient = await db;
    try {
      var result = await dbClient.query(table, where: whereCondition, whereArgs: whereArgs, orderBy: orderBy, limit: 1);
      if (result.isEmpty) return null;
      return result.first;
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<int> update(String table, Map<String, dynamic> item, int id) async {
    var dbClient = await db;
    return await dbClient.update(table, item, where: 'id = ?', whereArgs: [
      id
    ]);
  }

  Future<int> delete(String table, int id) async {
    var dbClient = await db;
    return await dbClient.delete(table, where: 'id = ?', whereArgs: [
      id
    ]);
  }

  Future close() async {
    var dbClient = await db;
    return dbClient.close();
  }

  truncateTable(String tableName) async {
    var dbClient = await db;
    await dbClient.execute('DELETE FROM $tableName');
  }

  getBooking(String table, {String? whereCondition, List<dynamic>? whereArgs, String? orderBy}) async {
    var dbClient = await db;
    var result = await dbClient.query(table, where: whereCondition, whereArgs: whereArgs, orderBy: orderBy, limit: 1);

    if (result.isNotEmpty) {
      Map<String, dynamic> row = result.first;
      return Booking(status: row['status'] as String);
    } else {
      return null;
    }
  }

  Future<void> deleteMultipleData(List<int> idsToDelete) async {
    var dbClient = await db;
    // Specify the table name and the WHERE clause with an IN condition.
    const tableName = 'runsheet';
    final whereClause = 'runsheet_id IN (${idsToDelete.map((id) => '?').join(', ')})';
    final whereArgs = idsToDelete;
    await dbClient.delete(tableName, where: whereClause, whereArgs: whereArgs);
  }

  Future<void> deleteDataNotIn(String table, String id, List<String> idsToKeep) async {
    var dbClient = await db;
    // Specify the table name and the WHERE clause with a NOT IN condition.
    final whereClause = '$id NOT IN (${idsToKeep.map((id) => '?').join(', ')})';
    final whereArgs = idsToKeep; // List of id values to keep.
    // Execute the raw SQL query to delete rows not in the specified list.
    await dbClient.rawDelete('DELETE FROM $table WHERE $whereClause', whereArgs);
  }
}

class Booking {
  final String status;

  Booking({required this.status});
}
