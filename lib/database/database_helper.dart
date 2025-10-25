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
      version: 2, // Incremented version for schema change
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    AppLogger.info('Creating database tables');

    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const intTypeNullable = 'INTEGER';

    // Create trips table first (parent table)
    await db.execute('''
    CREATE TABLE trips (
      id $idType,
      name $textType,
      description $textTypeNullable,
      start_timestamp $intType,
      end_timestamp $intTypeNullable,
      is_active $intType DEFAULT 1
    )
    ''');

    // Create locations table with foreign key to trips
    await db.execute('''
    CREATE TABLE locations (
      id $idType,
      trip_id $intTypeNullable,
      latitude $realType,
      longitude $realType,
      altitude $realType,
      accuracy $realType,
      timestamp $intType,
      address $textType,
      FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
    )
    ''');

    AppLogger.info('Database tables created successfully');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Create trips table
      await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        start_timestamp INTEGER NOT NULL,
        end_timestamp INTEGER,
        is_active INTEGER DEFAULT 1
      )
      ''');

      // Add trip_id column to locations table
      await db.execute('ALTER TABLE locations ADD COLUMN trip_id INTEGER');

      AppLogger.info('Database upgrade completed');
    }
  }

  // ============ Trip Management Methods ============

  /// Insert a new trip
  Future<int> insertTrip(Map<String, dynamic> trip) async {
    final db = await instance.database;
    AppLogger.debug('Inserting trip: ${trip['name']}');
    return await db.insert('trips', trip);
  }

  /// Get all trips
  Future<List<Map<String, dynamic>>> getAllTrips() async {
    final db = await instance.database;
    return await db.query('trips', orderBy: 'start_timestamp DESC');
  }

  /// Get active trip
  Future<Map<String, dynamic>?> getActiveTrip() async {
    final db = await instance.database;
    final result = await db.query(
      'trips',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Get trip by ID
  Future<Map<String, dynamic>?> getTripById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Update a trip
  Future<int> updateTrip(int id, Map<String, dynamic> trip) async {
    final db = await instance.database;
    AppLogger.debug('Updating trip ID: $id');
    return await db.update('trips', trip, where: 'id = ?', whereArgs: [id]);
  }

  /// End a trip (set end timestamp and mark as inactive)
  Future<int> endTrip(int id, int endTimestamp) async {
    final db = await instance.database;
    AppLogger.info('Ending trip ID: $id');
    return await db.update(
      'trips',
      {'end_timestamp': endTimestamp, 'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a trip (will cascade delete all locations)
  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    AppLogger.warning('Deleting trip ID: $id (will cascade delete locations)');
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Location Management Methods ============

  /// Insert a new location
  Future<int> insertLocation(Map<String, dynamic> location) async {
    final db = await instance.database;
    return await db.insert('locations', location);
  }

  /// Get all locations
  Future<List<Map<String, dynamic>>> getAllLocations() async {
    final db = await instance.database;
    return await db.query('locations', orderBy: 'timestamp DESC');
  }

  /// Get locations for a specific trip
  Future<List<Map<String, dynamic>>> getLocationsByTripId(int tripId) async {
    final db = await instance.database;
    return await db.query(
      'locations',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Get latest location
  Future<Map<String, dynamic>?> getLatestLocation() async {
    final db = await instance.database;
    final result = await db.query(
      'locations',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Get latest location for a specific trip
  Future<Map<String, dynamic>?> getLatestLocationForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'locations',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Delete a location
  Future<int> deleteLocation(int id) async {
    final db = await instance.database;
    return await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  /// Close database connection
  Future close() async {
    final db = await instance.database;
    AppLogger.info('Closing database connection');
    db.close();
  }
}
