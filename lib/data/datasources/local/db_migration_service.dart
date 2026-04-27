import 'package:sqflite_sqlcipher/sqflite.dart';

class DbMigrationService {
  static const int schemaVersion = 2;

  Future<void> createLatestSchema(Database db) async {
    await _createV1Schema(db);
    await _upgradeToV2(db);
  }

  Future<void> upgrade(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 2:
          await _upgradeToV2(db);
          break;
        default:
          break;
      }
    }
  }

  Future<void> _createV1Schema(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'wallet'
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        used_amount REAL NOT NULL DEFAULT 0,
        FOREIGN KEY(category_id) REFERENCES categories(id)
      )
    ''');

    await db.insert('categories', {
      'name': 'General',
      'color_hex': '#0D3B66',
      'icon': 'wallet',
    });
  }

  Future<void> _upgradeToV2(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(categories)');
    final hasArchived = columns.any((row) => row['name'] == 'is_archived');
    if (hasArchived) {
      return;
    }

    await db.execute('ALTER TABLE categories ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0');
  }
}
