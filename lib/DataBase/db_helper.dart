import 'dart:ffi';

import 'package:sqflite/sqflite.dart' as sql;
class SQLHelper {
  // static Future<void> createTable(sql.Database database)async{
  //   await database.execute("""CREATE TABLE data(
  //   id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  //   cloud_id INTEGER NULL,
  //   title TEXT,
  //   description TEXT,
  //   isSynced INTEGER,
  //   // isDeleted INTEGER DEFAULT 0,
  //   createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  //   )""");
  // }
  static Future<void> createTable(sql.Database database)async{
    await database.execute("""CREATE TABLE data(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    cloud_id INTEGER NULL,
    title TEXT,
    description TEXT,
    isSynced INTEGER,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )""");
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase("todo.db" , version: 1,
    onCreate: (sql.Database database, int version) async{
      await createTable(database);
    });
  }
  static Future<int> createData(String title, String? description, int isSynced)async{
    final db = await SQLHelper.db();

    final data = {'title' : title , 'description' : description, 'isSynced' : isSynced};
    final id =  await db.insert('data', data,conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }
  static Future<List<Map<String, dynamic>>> getData()async{
    final db = await SQLHelper.db();
    return db.query('data', orderBy: 'id');
  }

  static Future<List<Map<String, dynamic>>> getAllData()async{
    final db = await SQLHelper.db();
    return db.query('data', orderBy: 'id');
  }
  // static Future<List<Map<String, dynamic>>> getAllData()async{
  //   final db = await SQLHelper.db();
  //   return db.query('data', where: "isDeleted = 0", orderBy: 'id');
  // }
  static Future<List<Map<String, dynamic>>> getUnSyncedData()async{
    final db = await SQLHelper.db();
    return db.query('data', where: 'isSynced = 0');
  }
  static Future<List<Map<String, dynamic>>> getSingleData(int id) async{
    final db = await SQLHelper.db();
    return db.query('data',where: 'id = ?' , whereArgs: [id] , limit: 1);
  }
  static Future<int> updateData(int id, String title, String? description, int isSynced) async{
    final db = await SQLHelper.db();
    final data = {
      'title' : title,
      'description' : description,
      'isSynced' : isSynced,
    };
    final result = await db.update('data',data, where: 'id = ?' , whereArgs: [id]);
    return result;
  }
  static Future<int> updateSqfliteData(int id, String title, String? description) async{
    final db = await SQLHelper.db();
    final data = {
      'title' : title,
      'description' : description,
      'createdAt' : DateTime.now().toString()
    };
    final result = await db.update('data',data, where: 'id = ?' , whereArgs: [id]);
    return result;
  }
  static Future<int> deleteDataTemp(int id, String title, String? description, int isSynced) async{
    final db = await SQLHelper.db();
    final data = {
      'isDeleted' : 1,
    };
    final result = await db.update('data',data, where: 'id = ?' , whereArgs: [id]);
    return result;
  }
  static Future<void> deleteData(int id)async{
    final db = await SQLHelper.db();
    try{
      await db.delete('data', where: 'id = ?' , whereArgs: [id]);
    } catch(e){}
  }
}