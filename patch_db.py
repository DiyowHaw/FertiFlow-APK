import re

with open('lib/services/database_service.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Add foundation import
if 'package:flutter/foundation.dart' not in code:
    code = code.replace('import \'package:path/path.dart\';', 'import \'package:path/path.dart\';\nimport \'package:flutter/foundation.dart\';')

# Add _isSupported and _webSettingsMock
if '_isSupported' not in code:
    replace_str = '''  Database? _db;
  final Map<String, String> _webSettingsMock = {};
  bool get _isSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);
'''
    code = code.replace('  Database? _db;', replace_str)

# Update get database
old_get_db = '''  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }'''
new_get_db = '''  Future<Database?> get database async {
    if (!_isSupported) return null;
    _db ??= await _initDatabase();
    return _db;
  }'''
code = code.replace(old_get_db, new_get_db)

# Update insertDiagnosis
code = code.replace('final db = await database;\n    await db.insert(', 'final db = await database;\n    if (db == null) return;\n    await db.insert(')

# Update getAllDiagnoses
code = code.replace('final db = await database;\n    return db.query(', 'final db = await database;\n    if (db == null) return [];\n    return db.query(')

# Update deleteDiagnosis
code = code.replace('final db = await database;\n    await db.delete(', 'final db = await database;\n    if (db == null) return;\n    await db.delete(')

# Update insertTask
code = code.replace('final db = await database;\n    final data = Map<String, dynamic>.from(task);', 'final db = await database;\n    if (db == null) return;\n    final data = Map<String, dynamic>.from(task);')

# Update getAllTasks
code = code.replace('final db = await database;\n    final rows = await db.query(', 'final db = await database;\n    if (db == null) return [];\n    final rows = await db.query(')

# Update updateTaskDone
code = code.replace('final db = await database;\n    await db.update(', 'final db = await database;\n    if (db == null) return;\n    await db.update(')

# Update deleteTask
code = code.replace('final db = await database;\n    await db.delete(\'daily_tasks\'', 'final db = await database;\n    if (db == null) return;\n    await db.delete(\'daily_tasks\'')

# Update insertCarePlan
code = code.replace('final db = await database;\n    final data = Map<String, dynamic>.from(plan);', 'final db = await database;\n    if (db == null) return;\n    final data = Map<String, dynamic>.from(plan);')

# Update getAllCarePlans
code = code.replace('final db = await database;\n    return db.query(\'care_plans\'', 'final db = await database;\n    if (db == null) return [];\n    return db.query(\'care_plans\'')

# Update deleteCarePlan
code = code.replace('final db = await database;\n    await db.delete(\'care_plans\'', 'final db = await database;\n    if (db == null) return;\n    await db.delete(\'care_plans\'')

# Update setSetting
old_set_setting = '''  Future<void> setSetting(String key, String? value) async {
    final db = await database;
    if (value == null) {
      await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
    } else {
      await db.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }'''
new_set_setting = '''  Future<void> setSetting(String key, String? value) async {
    if (!_isSupported) {
      if (value == null) _webSettingsMock.pop(key, None)
      else _webSettingsMock[key] = value
      return
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
  }'''
# Oh wait, python dict pop syntax in string for flutter! I made a typo in new_set_setting.
# Let's fix that typo.
new_set_setting = '''  Future<void> setSetting(String key, String? value) async {
    if (!_isSupported) {
      if (value == null) _webSettingsMock.remove(key);
      else _webSettingsMock[key] = value;
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
  }'''
code = code.replace(old_set_setting, new_set_setting)

# Update getSetting
old_get_setting = '''  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }'''
new_get_setting = '''  Future<String?> getSetting(String key) async {
    if (!_isSupported) return _webSettingsMock[key];
    final db = await database;
    if (db == null) return null;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }'''
code = code.replace(old_get_setting, new_get_setting)

with open('lib/services/database_service.dart', 'w', encoding='utf-8') as f:
    f.write(code)
