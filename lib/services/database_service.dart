import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  final Map<String, String> _webSettingsMock = {};
  
  bool get _isSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

  Future<Database?> get database async {
    if (!_isSupported) return null;
    _db ??= await _initDatabase();
    return _db;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'irigrow.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diagnosis_history (
        id TEXT PRIMARY KEY,
        imagePath TEXT,
        disease TEXT NOT NULL,
        confidence REAL DEFAULT 0.0,
        date TEXT NOT NULL,
        block TEXT,
        treatment TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        sub TEXT,
        isDone INTEGER NOT NULL DEFAULT 0,
        icon TEXT,
        iconColor INTEGER,
        imagePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE care_plans (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        day TEXT NOT NULL,
        task TEXT NOT NULL,
        detail TEXT,
        status TEXT DEFAULT 'Pending',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // ─── DIAGNOSIS HISTORY ────────────────────────────────────────────────────

  Future<void> insertDiagnosis(Map<String, dynamic> diagnosis) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'diagnosis_history',
      diagnosis,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllDiagnoses() async {
    final db = await database;
    if (db == null) return [];
    return db.query('diagnosis_history', orderBy: 'createdAt DESC');
  }

  Future<void> deleteDiagnosis(String id) async {
    final db = await database;
    if (db == null) return;
    await db.delete('diagnosis_history', where: 'id = ?', whereArgs: [id]);
  }

  // ─── DAILY TASKS ──────────────────────────────────────────────────────────

  Future<void> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    if (db == null) return;
    final data = Map<String, dynamic>.from(task);
    data['isDone'] = (data['isDone'] == true) ? 1 : 0;
    data['createdAt'] = data['createdAt'] ?? DateTime.now().toIso8601String();
    await db.insert('daily_tasks', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query('daily_tasks', orderBy: 'createdAt ASC');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['isDone'] = m['isDone'] == 1;
      return m;
    }).toList();
  }

  Future<void> updateTaskDone(String id, bool isDone) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'daily_tasks',
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    if (db == null) return;
    await db.delete('daily_tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CARE PLANS ───────────────────────────────────────────────────────────

  Future<void> insertCarePlan(Map<String, dynamic> plan) async {
    final db = await database;
    if (db == null) return;
    final data = Map<String, dynamic>.from(plan);
    data['id'] = data['id'] ?? 'cp_${DateTime.now().millisecondsSinceEpoch}';
    data['createdAt'] = data['createdAt'] ?? DateTime.now().toIso8601String();
    await db.insert('care_plans', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllCarePlans() async {
    final db = await database;
    if (db == null) return [];
    return db.query('care_plans', orderBy: 'createdAt ASC');
  }

  Future<void> deleteCarePlan(String id) async {
    final db = await database;
    if (db == null) return;
    await db.delete('care_plans', where: 'id = ?', whereArgs: [id]);
  }

  // ─── APP SETTINGS ─────────────────────────────────────────────────────────

  Future<void> setSetting(String key, String? value) async {
    if (!_isSupported) {
      if (value == null) {
        _webSettingsMock.remove(key);
      } else {
        _webSettingsMock[key] = value;
      }
      return;
    }
    final db = await database;
    if (db == null) return;
    if (value == null) {
      await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
    } else {
      await db.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<String?> getSetting(String key) async {
    if (!_isSupported) {
      return _webSettingsMock[key];
    }
    final db = await database;
    if (db == null) return null;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }
}
