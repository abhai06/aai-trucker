import 'package:sqflite/sqflite.dart';

class DataModel {
  static const String apiUrl = 'http://192.168.198.115:8000/api/v1/runsheet';
  static const String databaseName = 'trams.db';

  // Private constructor
  DataModel._privateConstructor();
  // Private static instance of the DataModel class
  static final DataModel _instance = DataModel._privateConstructor();

  // Public static method to access the instance of the DataModel class
  static DataModel get instance => _instance;

  // Public method to fetch data from the API and store it in sqflite
  Future<void> fetchDataAndStoreInDatabase(tableName, columns, data) async {
    // Open the database
    final db = await openDatabase(databaseName);
    // Create the table if it does not exist
    await db.execute(
        'CREATE TABLE IF NOT EXISTS $tableName (${columns.join(', ')})');

    for (final item in data) {
      await db.insert(tableName, item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    // Close the database
    await db.close();
  }

  // Public method to get data from the database
  Future<List<Map<String, dynamic>>> getDataFromDatabase(tableName) async {
    final db = await openDatabase(databaseName);
    final result = await db.query(tableName);
    await db.close();
    return result;
  }

  // Public method to delete all data from the database
  Future<void> deleteAllDataFromDatabase(tableName) async {
    final db = await openDatabase(databaseName);
    await db.delete(tableName);
    await db.close();
  }
}
