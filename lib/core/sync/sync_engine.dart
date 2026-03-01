import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../models/daily_log.dart';
import '../models/egg_sale.dart';
import '../models/expense.dart';
import '../models/flock.dart';
import '../config/app_config.dart';

const _storage = FlutterSecureStorage();
const _jwtKey = 'dave_farm_jwt';

/// Background sync engine.
/// - Listens for connectivity changes.
/// - On network available: pushes all unsynced records to the backend.
/// - On fresh login (empty DB): pulls a full restore from /api/v1/restore.
class SyncEngine {
  SyncEngine._();
  static final SyncEngine instance = SyncEngine._();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isSyncing = false;

  /// Start listening for connectivity changes.
  void start() {
    _sub = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && !_isSyncing) {
        await _pushUnsynced();
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<String?> get _jwt async => _storage.read(key: _jwtKey);

  Future<Map<String, String>> _authHeaders() async {
    final token = await _jwt;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ───────────────────────────────────────────
  // PUSH — upload unsynced records
  // ───────────────────────────────────────────

  Future<void> _pushUnsynced() async {
    _isSyncing = true;
    try {
      final headers = await _authHeaders();
      final db = DatabaseHelper.instance;

      await _syncTable<Flock>(
        items: await db.getUnsyncedFlocks(),
        endpoint: '/api/v1/flocks',
        headers: headers,
        table: DatabaseHelper.tableFlocks,
      );

      await _syncTable<DailyLog>(
        items: await db.getUnsyncedDailyLogs(),
        endpoint: '/api/v1/daily-logs',
        headers: headers,
        table: DatabaseHelper.tableDailyLogs,
      );

      await _syncTable<EggSale>(
        items: await db.getUnsyncedEggSales(),
        endpoint: '/api/v1/egg-sales',
        headers: headers,
        table: DatabaseHelper.tableEggSales,
      );

      await _syncTable<Expense>(
        items: await db.getUnsyncedExpenses(),
        endpoint: '/api/v1/expenses',
        headers: headers,
        table: DatabaseHelper.tableExpenses,
      );
    } catch (_) {
      // Silent fail — will retry on next connectivity event
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncTable<T>({
    required List<T> items,
    required String endpoint,
    required Map<String, String> headers,
    required String table,
  }) async {
    for (final item in items) {
      final map = (item as dynamic).toMap() as Map<String, dynamic>;
      try {
        final res = await http
            .post(
              Uri.parse('${AppConfig.baseUrl}$endpoint'),
              headers: headers,
              body: jsonEncode(map),
            )
            .timeout(const Duration(seconds: 10));

        if (res.statusCode == 200 || res.statusCode == 201) {
          await DatabaseHelper.instance
              .markSynced(table, map['id'] as String);
        }
      } catch (_) {
        // Network error — skip this record and move on
      }
    }
  }

  // ───────────────────────────────────────────
  // PULL — restore full data from backend
  // ───────────────────────────────────────────

  /// Call this on fresh login when local DB is empty.
  Future<void> restoreFromCloud() async {
    try {
      final headers = await _authHeaders();
      final res = await http
          .get(Uri.parse('${AppConfig.baseUrl}/api/v1/restore'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        final flocks = (data['flocks'] as List? ?? [])
            .map((e) => Flock.fromMap(e as Map<String, dynamic>))
            .toList();
        final logs = (data['daily_logs'] as List? ?? [])
            .map((e) => DailyLog.fromMap(e as Map<String, dynamic>))
            .toList();
        final sales = (data['egg_sales'] as List? ?? [])
            .map((e) => EggSale.fromMap(e as Map<String, dynamic>))
            .toList();
        final expenses = (data['expenses'] as List? ?? [])
            .map((e) => Expense.fromMap(e as Map<String, dynamic>))
            .toList();

        await DatabaseHelper.instance.batchInsertRestore(
          flocks: flocks,
          dailyLogs: logs,
          eggSales: sales,
          expenses: expenses,
        );
      }
    } catch (_) {
      // Network unavailable — proceed with empty local DB
    }
  }

  /// Trigger a manual sync push (e.g., user taps "Sync Now").
  Future<void> syncNow() => _pushUnsynced();
}
