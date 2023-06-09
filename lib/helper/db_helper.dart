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
    await db.execute(
        'CREATE TABLE attachment (id INTEGER PRIMARY KEY, attach BLOB, source_id INTEGER, task_id INTEGER)');
    await db.execute(
        'CREATE TABLE tasks (id INTEGER PRIMARY KEY, code TEXT, name TEXT, sequence_no INTEGER, task TEXT)');
    await db.execute(
        'CREATE TABLE exception (id INTEGER PRIMARY KEY, code TEXT, name TEXT, description TEXT, task_id INTEGER)');
    await db.execute(
        'CREATE TABLE runsheet (id INTEGER PRIMARY KEY, runsheet_id INTEGER ,monitor_id INTEGER, plate_id INTEGER, cbm REAL, charging_type TEXT, date_from TEXT, date_to TEXT, ar_no TEXT, dr_no TEXT, est_tot_cbm REAL, est_tot_pcs INTEGER, est_tot_wt REAL, from_loc TEXT, plate_no TEXT, reference TEXT, remarks TEXT, status TEXT, task TEXT, to_loc TEXT, total_pcs INTEGER, total_wt REAL, tracking_no TEXT, trucking_id TEXT, updated_at TEXT, user_id INTEGER, vehicle_id INTEGER, vehicle_type TEXT )');
    await db.execute(
        'CREATE TABLE booking (id INTEGER PRIMARY KEY, source_id INTEGER, runsheet_id INTEGER, address TEXT, pickup_other_address TEXT, pickup_expected_date TEXT, customer_contact TEXT, task TEXT, customer TEXT, remarks TEXT, item_details INTEGER, pickup_loc TEXT,delivery_loc TEXT, delivery_other_address TEXT, delivery_expected_date TEXT, reference TEXT,service_type TEXT, item_cbm REAL, item_height REAL, item_length REAL, item_width REAL, item_qty INTEGER, item_weight INTEGER,trip_type TEXT , status TEXT, sequence_no INTEGER, fixed TEXT, line_id INTEGER, location_id INTEGER)');
    await db.execute(
        'CREATE TABLE booking_logs (id INTEGER PRIMARY KEY, task TEXT, task_type TEXT, task_code TEXT, location TEXT, contact_person TEXT, receive_by TEXT, datetime TEXT, note TEXT, line_id INTEGER, source_id INTEGER, monitor_id INTEGER, task_id INTEGER, task_exception TEXT, signature BLOB, flag INTEGER)');
  }

  save(String table, data, {String? pkey}) async {
    var dbClient = await db;
    try {
      for (var item in data) {
        final record = await dbClient
            .query(table, where: '$pkey = ?', whereArgs: [item[pkey]]);
        if (record.isNotEmpty) {
          await dbClient
              .update(table, item, where: '$pkey = ?', whereArgs: [item[pkey]]);
        } else {
          await dbClient.insert(table, item,
              conflictAlgorithm: ConflictAlgorithm.replace);
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
        final record = await dbClient.query(table,
            where: 'source_id = ? AND task = ? AND runsheet_id = ?',
            whereArgs: [item['source_id'], item['task'], item['runsheet_id']]);
        if (record.isNotEmpty) {
          await dbClient.update(table, item,
              where: 'source_id = ? AND task = ?',
              whereArgs: [item['source_id'], item['task']]);
        } else {
          await dbClient.insert(table, item,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    } catch (e) {
      print('Error on saving : $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAll(String table,
      {String? whereCondition,
      List<dynamic>? whereArgs,
      String? orderBy}) async {
    var dbClient = await db;
    List<Map<String, Object?>> result = [];
    try {
      if (whereCondition != null) {
        result = await dbClient.query(table,
            where: whereCondition, whereArgs: whereArgs, orderBy: orderBy);
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
    return Sqflite.firstIntValue(
        await dbClient.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  Future<Map<String, dynamic>?> getData(String table,
      {String? whereCondition, List<dynamic>? whereArgs}) async {
    var dbClient = await db;
    try {
      var result = await dbClient.query(table,
          where: whereCondition, whereArgs: whereArgs, limit: 1);
      if (result.isEmpty) return null;
      return result.first;
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<int> update(String table, Map<String, dynamic> item, int id) async {
    var dbClient = await db;
    return await dbClient.update(table, item, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    var dbClient = await db;
    return await dbClient.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    var dbClient = await db;
    return dbClient.close();
  }

  truncateTable(String tableName) async {
    var dbClient = await db;
    await dbClient.execute('DELETE FROM $tableName');
  }
}
