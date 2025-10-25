import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/app_logger.dart';

/// Singleton class to manage SQLite database operations
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('travel_location.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    AppLogger.info('Initializing database at: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    AppLogger.info('Creating database tables');

    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE locations (
      id $idType,
      latitude $realType,
      longitude $realType,
      altitude $realType,
      accuracy $realType,
      timestamp $intType,
      address $textType
    )
    ''');

    AppLogger.info('Database tables created successfully');
  }

  Future<int> insertLocation(Map<String, dynamic> location) async {
    final db = await instance.database;
    return await db.insert('locations', location);
  }

  Future<List<Map<String, dynamic>>> getAllLocations() async {
    final db = await instance.database;
    return await db.query('locations', orderBy: 'timestamp DESC');
  }

  Future<Map<String, dynamic>?> getLatestLocation() async {
    final db = await instance.database;
    final result = await db.query(
      'locations',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> deleteLocation(int id) async {
    final db = await instance.database;
    return await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    AppLogger.info('Closing database connection');
    db.close();
  }
}
