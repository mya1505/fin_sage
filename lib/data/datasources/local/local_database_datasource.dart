import 'dart:io';

import 'package:fin_sage/core/constants/app_constants.dart';
import 'package:fin_sage/data/datasources/local/secure_key_service.dart';
import 'package:fin_sage/data/models/budget_model.dart';
import 'package:fin_sage/data/models/category_model.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

class LocalDatabaseDataSource {
  LocalDatabaseDataSource(this._secureKeyService);

  final SecureKeyService _secureKeyService;
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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color_hex TEXT NOT NULL,
            icon TEXT NOT NULL DEFAULT 'wallet',
            is_archived INTEGER NOT NULL DEFAULT 0
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE categories ADD COLUMN is_archived INTEGER DEFAULT 0');
        }
      },
    );

    return _db!;
  }

  Future<String> databasePath() async {
    final folder = await getDatabasesPath();
    return p.join(folder, AppConstants.dbName);
  }

  Future<List<int>> databaseBytes() async {
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

  Future<void> deleteTransaction(int transactionId) async {
    final db = await _database();
    await db.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await _database();
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map(CategoryModel.fromMap).toList();
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

  Future<void> replaceDatabaseFile(List<int> bytes) async {
    final path = await databasePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(bytes, flush: true);
    _db = null;
  }
}
