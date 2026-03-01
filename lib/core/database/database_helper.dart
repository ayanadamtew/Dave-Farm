import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/daily_log.dart';
import '../models/egg_sale.dart';
import '../models/expense.dart';
import '../models/flock.dart';

/// Singleton SQLite database helper for Dave Farm.
/// All tables include `id` (TEXT UUID PK) and `is_synced` (INTEGER 0/1).
class DatabaseHelper {
  static const String _dbName = 'dave_farm.db';
  static const int _dbVersion = 1;

  // Table names
  static const String tableFlocks = 'flocks';
  static const String tableDailyLogs = 'daily_logs';
  static const String tableEggSales = 'egg_sales';
  static const String tableExpenses = 'expenses';

  // --- Singleton boilerplate ---
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Flocks table
    await db.execute('''
      CREATE TABLE $tableFlocks (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        initial_bird_count INTEGER NOT NULL,
        current_bird_count INTEGER NOT NULL,
        breed TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Daily logs table
    await db.execute('''
      CREATE TABLE $tableDailyLogs (
        id TEXT PRIMARY KEY NOT NULL,
        flock_id TEXT NOT NULL,
        date TEXT NOT NULL,
        good_eggs INTEGER NOT NULL DEFAULT 0,
        broken_eggs INTEGER NOT NULL DEFAULT 0,
        dead_birds INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (flock_id) REFERENCES $tableFlocks(id)
      )
    ''');

    // Egg sales table
    await db.execute('''
      CREATE TABLE $tableEggSales (
        id TEXT PRIMARY KEY NOT NULL,
        customer_name TEXT NOT NULL,
        date TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE $tableExpenses (
        id TEXT PRIMARY KEY NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // =========================================================================
  // FLOCKS CRUD
  // =========================================================================

  Future<int> insertFlock(Flock flock) async {
    final db = await database;
    return db.insert(tableFlocks, flock.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Flock>> getAllFlocks() async {
    final db = await database;
    final maps = await db.query(tableFlocks, orderBy: 'start_date DESC');
    return maps.map(Flock.fromMap).toList();
  }

  Future<Flock?> getFlockById(String id) async {
    final db = await database;
    final maps =
        await db.query(tableFlocks, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Flock.fromMap(maps.first);
  }

  Future<int> updateFlock(Flock flock) async {
    final db = await database;
    return db.update(tableFlocks, flock.toMap(),
        where: 'id = ?', whereArgs: [flock.id]);
  }

  Future<int> deleteFlock(String id) async {
    final db = await database;
    return db.delete(tableFlocks, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Flock>> getUnsyncedFlocks() async {
    final db = await database;
    final maps = await db
        .query(tableFlocks, where: 'is_synced = ?', whereArgs: [0]);
    return maps.map(Flock.fromMap).toList();
  }

  // =========================================================================
  // DAILY LOGS CRUD
  // =========================================================================

  /// Insert a DailyLog and — if dead_birds > 0 — decrement the flock's
  /// current_bird_count atomically within a transaction.
  Future<void> insertDailyLog(DailyLog log) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(tableDailyLogs, log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      if (log.deadBirds > 0) {
        await txn.rawUpdate(
          '''UPDATE $tableFlocks
             SET current_bird_count = MAX(0, current_bird_count - ?)
             WHERE id = ?''',
          [log.deadBirds, log.flockId],
        );
      }
    });
  }

  Future<List<DailyLog>> getAllDailyLogs() async {
    final db = await database;
    final maps = await db.query(tableDailyLogs, orderBy: 'date DESC');
    return maps.map(DailyLog.fromMap).toList();
  }

  Future<List<DailyLog>> getDailyLogsByFlock(String flockId) async {
    final db = await database;
    final maps = await db.query(tableDailyLogs,
        where: 'flock_id = ?', whereArgs: [flockId], orderBy: 'date DESC');
    return maps.map(DailyLog.fromMap).toList();
  }

  /// Returns daily logs within a date range (inclusive), ordered by date.
  Future<List<DailyLog>> getDailyLogsByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      tableDailyLogs,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );
    return maps.map(DailyLog.fromMap).toList();
  }

  /// Returns the last 30 days of logs (aggregated goodEggs per day).
  Future<List<Map<String, dynamic>>> getLast30DaysEggTotals() async {
    final db = await database;
    final cutoff =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    return db.rawQuery('''
      SELECT DATE(date) as day, SUM(good_eggs) as total_eggs
      FROM $tableDailyLogs
      WHERE date >= ?
      GROUP BY DATE(date)
      ORDER BY day ASC
    ''', [cutoff]);
  }

  Future<int> updateDailyLog(DailyLog log) async {
    final db = await database;
    return db.update(tableDailyLogs, log.toMap(),
        where: 'id = ?', whereArgs: [log.id]);
  }

  Future<int> deleteDailyLog(String id) async {
    final db = await database;
    return db.delete(tableDailyLogs, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DailyLog>> getUnsyncedDailyLogs() async {
    final db = await database;
    final maps = await db
        .query(tableDailyLogs, where: 'is_synced = ?', whereArgs: [0]);
    return maps.map(DailyLog.fromMap).toList();
  }

  // =========================================================================
  // EGG SALES CRUD
  // =========================================================================

  Future<int> insertEggSale(EggSale sale) async {
    final db = await database;
    return db.insert(tableEggSales, sale.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EggSale>> getAllEggSales() async {
    final db = await database;
    final maps = await db.query(tableEggSales, orderBy: 'date DESC');
    return maps.map(EggSale.fromMap).toList();
  }

  Future<List<EggSale>> getEggSalesByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      tableEggSales,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );
    return maps.map(EggSale.fromMap).toList();
  }

  Future<int> updateEggSale(EggSale sale) async {
    final db = await database;
    return db.update(tableEggSales, sale.toMap(),
        where: 'id = ?', whereArgs: [sale.id]);
  }

  Future<int> deleteEggSale(String id) async {
    final db = await database;
    return db.delete(tableEggSales, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<EggSale>> getUnsyncedEggSales() async {
    final db = await database;
    final maps = await db
        .query(tableEggSales, where: 'is_synced = ?', whereArgs: [0]);
    return maps.map(EggSale.fromMap).toList();
  }

  // =========================================================================
  // EXPENSES CRUD
  // =========================================================================

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert(tableExpenses, expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query(tableExpenses, orderBy: 'date DESC');
    return maps.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      tableExpenses,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );
    return maps.map(Expense.fromMap).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return db.update(tableExpenses, expense.toMap(),
        where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    return db.delete(tableExpenses, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getUnsyncedExpenses() async {
    final db = await database;
    final maps = await db
        .query(tableExpenses, where: 'is_synced = ?', whereArgs: [0]);
    return maps.map(Expense.fromMap).toList();
  }

  // =========================================================================
  // SYNC HELPERS
  // =========================================================================

  /// Mark any record across the given table as synced.
  Future<void> markSynced(String table, String id) async {
    final db = await database;
    await db.update(
      table,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Batch-insert data received from the cloud restore endpoint.
  /// All inserted records are immediately marked is_synced = 1.
  Future<void> batchInsertRestore({
    required List<Flock> flocks,
    required List<DailyLog> dailyLogs,
    required List<EggSale> eggSales,
    required List<Expense> expenses,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final f in flocks) {
        batch.insert(tableFlocks, {...f.toMap(), 'is_synced': 1},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final l in dailyLogs) {
        batch.insert(tableDailyLogs, {...l.toMap(), 'is_synced': 1},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final s in eggSales) {
        batch.insert(tableEggSales, {...s.toMap(), 'is_synced': 1},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final e in expenses) {
        batch.insert(tableExpenses, {...e.toMap(), 'is_synced': 1},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  // =========================================================================
  // ANALYTICS QUERIES
  // =========================================================================

  /// Returns today's total good eggs across all flocks.
  Future<int> getTodayGoodEggs() async {
    final db = await database;
    final today = DateTime.now();
    final dayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(good_eggs), 0) as total
      FROM $tableDailyLogs
      WHERE DATE(date) = ?
    ''', [dayStr]);
    return (result.first['total'] as num).toInt();
  }

  /// Returns total current bird count across all flocks.
  Future<int> getTotalCurrentBirds() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(current_bird_count), 0) as total
      FROM $tableFlocks
    ''');
    return (result.first['total'] as num).toInt();
  }

  /// Net profit = SUM(egg_sales.total_price) - SUM(expenses.amount)
  /// for the given date range.
  Future<double> getNetProfit(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();
    final salesResult = await db.rawQuery(
        'SELECT COALESCE(SUM(total_price), 0) as total FROM $tableEggSales WHERE date >= ? AND date <= ?',
        [startStr, endStr]);
    final expensesResult = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM $tableExpenses WHERE date >= ? AND date <= ?',
        [startStr, endStr]);
    final sales = (salesResult.first['total'] as num).toDouble();
    final expenses = (expensesResult.first['total'] as num).toDouble();
    return sales - expenses;
  }

  /// Cost per egg = SUM(expenses) / SUM(good_eggs) for the given period.
  Future<double> getCostPerEgg(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();
    final logsResult = await db.rawQuery(
        'SELECT COALESCE(SUM(good_eggs), 0) as total FROM $tableDailyLogs WHERE date >= ? AND date <= ?',
        [startStr, endStr]);
    final expensesResult = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM $tableExpenses WHERE date >= ? AND date <= ?',
        [startStr, endStr]);
    final eggs = (logsResult.first['total'] as num).toDouble();
    final expenses = (expensesResult.first['total'] as num).toDouble();
    if (eggs == 0) return 0;
    return expenses / eggs;
  }

  /// Returns a list of {day: String, net_profit: double} for the last 30 days.
  Future<List<Map<String, dynamic>>> getLast30DaysNetProfit() async {
    final db = await database;
    final cutoff =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final sales = await db.rawQuery('''
      SELECT DATE(date) as day, SUM(total_price) as total_sales
      FROM $tableEggSales WHERE date >= ?
      GROUP BY DATE(date)
    ''', [cutoff]);
    final expenses = await db.rawQuery('''
      SELECT DATE(date) as day, SUM(amount) as total_expenses
      FROM $tableExpenses WHERE date >= ?
      GROUP BY DATE(date)
    ''', [cutoff]);

    final Map<String, double> salesMap = {
      for (final r in sales)
        r['day'] as String: (r['total_sales'] as num).toDouble()
    };
    final Map<String, double> expensesMap = {
      for (final r in expenses)
        r['day'] as String: (r['total_expenses'] as num).toDouble()
    };

    final allDays = <String>{...salesMap.keys, ...expensesMap.keys}.toList()
      ..sort();
    return allDays
        .map((day) => {
              'day': day,
              'net_profit': (salesMap[day] ?? 0) - (expensesMap[day] ?? 0),
            })
        .toList();
  }

  /// Drop all data (for testing / logout).
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableDailyLogs);
      await txn.delete(tableEggSales);
      await txn.delete(tableExpenses);
      await txn.delete(tableFlocks);
    });
  }
}
