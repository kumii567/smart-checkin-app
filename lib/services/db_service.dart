import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbService {
  DbService._();

  static final DbService instance = DbService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'class_checkin.db');

    // Single local table to store both check-in and finish-class submissions.
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE class_records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            flow_type TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            qr_data TEXT NOT NULL,
            previous_topic TEXT,
            expected_topic TEXT,
            mood_before INTEGER,
            learned_today TEXT,
            feedback TEXT,
            instructor_rating INTEGER,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE class_records ADD COLUMN instructor_rating INTEGER',
          );
        }
      },
    );
  }

  Future<int> insertRecord(Map<String, Object?> data) async {
    final db = await database;
    // Persist one submission record locally and return inserted row id.
    return db.insert('class_records', data);
  }

  Future<Map<String, Object?>?> fetchLatestRecord(String flowType) async {
    final db = await database;
    final results = await db.query(
      'class_records',
      where: 'flow_type = ?',
      whereArgs: [flowType],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }
}
