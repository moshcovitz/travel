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
      version: 5, // Incremented version for budget support
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
      is_active $intType DEFAULT 1,
      budget REAL,
      budget_currency $textTypeNullable
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
      country $textTypeNullable,
      FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
    )
    ''');

    // Create expenses table with foreign key to trips
    await db.execute('''
    CREATE TABLE expenses (
      id $idType,
      trip_id $intType,
      title $textType,
      description $textTypeNullable,
      amount $realType,
      currency $textType,
      category $textType,
      timestamp $intType,
      FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
    )
    ''');

    // Create notes table with foreign key to trips
    await db.execute('''
    CREATE TABLE notes (
      id $idType,
      trip_id $intType,
      title $textType,
      content $textType,
      timestamp $intType,
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

      AppLogger.info('Database upgraded to version 2');
    }

    if (oldVersion < 3) {
      // Add country column to locations table
      await db.execute('ALTER TABLE locations ADD COLUMN country TEXT');
      AppLogger.info('Database upgraded to version 3 - added country column');
    }

    if (oldVersion < 4) {
      // Check if expenses table exists before creating
      var result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='expenses'",
      );

      if (result.isEmpty) {
        // Create expenses table
        await db.execute('''
        CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          trip_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          amount REAL NOT NULL,
          currency TEXT NOT NULL,
          category TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
        )
        ''');
        AppLogger.info('Created expenses table');
      } else {
        AppLogger.info('Expenses table already exists, skipping creation');
      }

      // Check if notes table exists before creating
      result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='notes'",
      );

      if (result.isEmpty) {
        // Create notes table
        await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          trip_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
        )
        ''');
        AppLogger.info('Created notes table');
      } else {
        AppLogger.info('Notes table already exists, skipping creation');
      }

      AppLogger.info('Database upgraded to version 4 - expenses and notes tables ready');
    }

    if (oldVersion < 5) {
      // Add budget columns to trips table
      try {
        await db.execute('ALTER TABLE trips ADD COLUMN budget REAL');
        AppLogger.info('Added budget column to trips');
      } catch (e) {
        AppLogger.warning('Budget column might already exist');
      }

      try {
        await db.execute('ALTER TABLE trips ADD COLUMN budget_currency TEXT');
        AppLogger.info('Added budget_currency column to trips');
      } catch (e) {
        AppLogger.warning('Budget currency column might already exist');
      }

      AppLogger.info('Database upgraded to version 5 - budget support added');
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

  // ============ Expense Management Methods ============

  /// Insert a new expense
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await instance.database;
    AppLogger.debug('Inserting expense: ${expense['title']}');
    return await db.insert('expenses', expense);
  }

  /// Get all expenses for a trip
  Future<List<Map<String, dynamic>>> getExpensesByTripId(int tripId) async {
    final db = await instance.database;
    return await db.query(
      'expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp DESC',
    );
  }

  /// Get expense by ID
  Future<Map<String, dynamic>?> getExpenseById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Update an expense
  Future<int> updateExpense(int id, Map<String, dynamic> expense) async {
    final db = await instance.database;
    AppLogger.debug('Updating expense ID: $id');
    return await db.update('expenses', expense, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete an expense
  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    AppLogger.debug('Deleting expense ID: $id');
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Note Management Methods ============

  /// Insert a new note
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    AppLogger.debug('Inserting note: ${note['title']}');
    return await db.insert('notes', note);
  }

  /// Get all notes for a trip
  Future<List<Map<String, dynamic>>> getNotesByTripId(int tripId) async {
    final db = await instance.database;
    return await db.query(
      'notes',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp DESC',
    );
  }

  /// Get note by ID
  Future<Map<String, dynamic>?> getNoteById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Update a note
  Future<int> updateNote(int id, Map<String, dynamic> note) async {
    final db = await instance.database;
    AppLogger.debug('Updating note ID: $id');
    return await db.update('notes', note, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete a note
  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    AppLogger.debug('Deleting note ID: $id');
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  /// Close database connection
  Future close() async {
    final db = await instance.database;
    AppLogger.info('Closing database connection');
    db.close();
  }
}
