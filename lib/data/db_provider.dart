// lib/data/db_provider.dart
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  static final DBProvider _instance = DBProvider._internal();
  DBProvider._internal();
  static DBProvider get instance => _instance;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "memo_app.db");

    // DEBUGビルドなら古いDBファイルを消す
    assert(() {
      final dbFile = File(path);
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }
      return true;
    }());

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Memoテーブル
    await db.execute('''
      CREATE TABLE Memo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        imagePath TEXT,
        createdAt TEXT,
        folderId INTEGER DEFAULT 0,
        textContent TEXT
      )
    ''');

    // Folderテーブル
    await db.execute('''
      CREATE TABLE Folder (
        folderId INTEGER PRIMARY KEY AUTOINCREMENT,
        folderName TEXT
      )
    ''');
  }
}