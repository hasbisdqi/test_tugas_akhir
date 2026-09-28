import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../security/security_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'agro_smart_system.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        avatar_url TEXT,
        role TEXT DEFAULT 'farmer',
        wallet_address TEXT,
        crypto_balance REAL DEFAULT 0.0,
        biometric_enabled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Crop/Farm Management Table
    await db.execute('''
      CREATE TABLE crops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        variety TEXT NOT NULL,
        planting_date TEXT NOT NULL,
        harvest_date TEXT,
        land_area_ha REAL NOT NULL,
        expected_yield_ton REAL NOT NULL,
        status TEXT DEFAULT 'growing',
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 3. IoT Sensor Logs Table
    await db.execute('''
      CREATE TABLE sensor_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        crop_id INTEGER,
        sensor_type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        recorded_at TEXT NOT NULL,
        synced_online INTEGER DEFAULT 0,
        FOREIGN KEY (crop_id) REFERENCES crops (id) ON DELETE SET NULL
      )
    ''');

    // 4. Crypto / Agro Token Transactions Table
    await db.execute('''
      CREATE TABLE agro_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tx_hash TEXT UNIQUE NOT NULL,
        tx_type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'AGRO',
        status TEXT DEFAULT 'completed',
        recipient_address TEXT,
        timestamp TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Seed initial demo user
    final defaultPasswordHash = SecurityHelper.hashPassword('admin123');
    await db.insert('users', {
      'username': 'admin',
      'email': 'admin@smartagro.io',
      'password_hash': defaultPasswordHash,
      'full_name': 'Chief Agro Officer',
      'role': 'admin',
      'wallet_address': '0x71C...Agro99X',
      'crypto_balance': 2500.75,
      'biometric_enabled': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    final farmerPasswordHash = SecurityHelper.hashPassword('farmer123');
    await db.insert('users', {
      'username': 'farmer_dan',
      'email': 'dan@smartagro.io',
      'password_hash': farmerPasswordHash,
      'full_name': 'Dan Agro Master',
      'role': 'farmer',
      'wallet_address': '0x44B...Farm11A',
      'crypto_balance': 340.50,
      'biometric_enabled': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
