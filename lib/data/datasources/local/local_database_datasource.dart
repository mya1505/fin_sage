import 'dart:io';

import 'package:fin_sage/core/constants/app_constants.dart';
import 'package:fin_sage/data/datasources/local/db_migration_service.dart';
import 'package:fin_sage/data/datasources/local/secure_key_service.dart';
import 'package:fin_sage/data/models/budget_model.dart';
import 'package:fin_sage/data/models/category_model.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

class LocalDatabaseDataSource {
  LocalDatabaseDataSource(this._secureKeyService, this._migrationService);

  final SecureKeyService _secureKeyService;
  final DbMigrationService _migrationService;
  Database? _db;

  Future<Database> _database() async {
    if (_db != null) {
      return _db!;
    }

    final key = await _secureKeyService.getOrCreateDbKey();
    final folder = await getDatabasesPath();
    final dbPath = p.join(folder, AppConstants.dbName);

    _db = await openDatabase(
      dbPath,
      password: key,
      version: DbMigrationService.schemaVersion,
      onCreate: (db, version) async => _migrationService.createLatestSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async =>
          _migrationService.upgrade(db, oldVersion, newVersion),
    );

    return _db!;
  }

  Future<String> databasePath() async {
    final folder = await getDatabasesPath();
    return p.join(folder, AppConstants.dbName);
  }

  Future<List<int>> databaseBytes() async {
    await _database();
    final file = File(await databasePath());
    return file.readAsBytes();
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await _database();
    final rows = await db.query('transactions', orderBy: 'date DESC');
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<void> saveTransaction(TransactionModel transaction) async {
    final db = await _database();
    await db.insert('transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaction id is required for update');
    }
    final db = await _database();
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> deleteTransaction(int transactionId) async {
    final db = await _database();
    await db.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await _database();
    final rows = await db.query(
      'categories',
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'name ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<void> saveCategory(CategoryModel category) async {
    final db = await _database();
    final normalizedName = category.name.trim().toLowerCase();
    final existing = await db.query(
      'categories',
      where: 'lower(name) = ?',
      whereArgs: [normalizedName],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw StateError('Category already exists');
    }

    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> archiveCategory(int categoryId) async {
    if (categoryId == 1) {
      throw StateError('Default category cannot be archived');
    }

    final db = await _database();
    final usage = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM transactions WHERE category_id = ?',
      [categoryId],
    );
    final usedCount = (usage.first['total'] as num?)?.toInt() ?? 0;
    if (usedCount > 0) {
      throw StateError('Category is still used by transactions');
    }

    await db.update(
      'categories',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<List<BudgetModel>> getBudgets() async {
    final db = await _database();
    final rows = await db.query('budgets', orderBy: 'month DESC');
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<void> saveBudget(BudgetModel budget) async {
    final db = await _database();
    await db.insert('budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteBudget(int budgetId) async {
    final db = await _database();
    await db.delete('budgets', where: 'id = ?', whereArgs: [budgetId]);
  }

  Future<void> replaceDatabaseFile(List<int> bytes) async {
    final activeDb = _db;
    _db = null;
    await activeDb?.close();

    final path = await databasePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> resetLocalData() async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('categories');
      await txn.insert('categories', {
        'name': 'General',
        'color_hex': '#0D3B66',
        'icon': 'wallet',
        'is_archived': 0,
      });
    });
  }
}
