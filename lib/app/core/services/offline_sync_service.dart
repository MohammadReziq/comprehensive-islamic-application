import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../network/supabase_client.dart';
import 'connectivity_service.dart';

/// خدمة المزامنة في وضع Offline
/// تحفظ العمليات محلياً وتزامنها عند عودة الإنترنت
class OfflineSyncService {
  final ConnectivityService _connectivityService;
  Database? _db;

  OfflineSyncService(this._connectivityService);

  // ─── إعداد قاعدة البيانات المحلية ───

  /// تهيئة sqflite
  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'salati_hayati_offline.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );

    // الاستماع لعودة الإنترنت → مزامنة تلقائية
    _connectivityService.onConnectivityChanged.listen((connected) {
      if (connected) {
        syncPendingOperations();
      }
    });
  }

  /// إنشاء الجداول المحلية
  Future<void> _createTables(Database db, int version) async {
    // جدول العمليات المعلقة
    await db.execute('''
      CREATE TABLE offline_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // كاش الطلاب (للبحث بدون نت)
    await db.execute('''
      CREATE TABLE cached_students (
        id TEXT PRIMARY KEY,
        mosque_id TEXT NOT NULL,
        name TEXT NOT NULL,
        local_number INTEGER,
        qr_code TEXT,
        data TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // كاش أوقات الصلاة
    await db.execute('''
      CREATE TABLE cached_prayer_times (
        date TEXT PRIMARY KEY,
        fajr TEXT NOT NULL,
        dhuhr TEXT NOT NULL,
        asr TEXT NOT NULL,
        maghrib TEXT NOT NULL,
        isha TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // ─── إضافة عملية للـ Queue ───

  /// إضافة عملية حضور للكيو المحلي
  Future<void> enqueueOperation({
    required String tableName,
    required String operation, // 'insert', 'update', 'delete'
    required Map<String, dynamic> data,
  }) async {
    if (_db == null) return;

    await _db!.insert('offline_queue', {
      'table_name': tableName,
      'operation': operation,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  // ─── مزامنة ───

  /// مزامنة كل العمليات المعلقة
  Future<int> syncPendingOperations() async {
    if (_db == null) return 0;
    if (!_connectivityService.isConnected) return 0;

    final pending = await _db!.query(
      'offline_queue',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );

    int syncedCount = 0;

    for (final op in pending) {
      try {
        final tableName = op['table_name'] as String;
        final operation = op['operation'] as String;
        final data = jsonDecode(op['data'] as String) as Map<String, dynamic>;

        switch (operation) {
          case 'insert':
            await supabase.from(tableName).insert(data);
            break;
          case 'update':
            final id = data.remove('id');
            await supabase.from(tableName).update(data).eq('id', id);
            break;
          case 'delete':
            await supabase.from(tableName).delete().eq('id', data['id']);
            break;
        }

        // تحديد كـ synced
        await _db!.update(
          'offline_queue',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [op['id']],
        );
        syncedCount++;
      } catch (e) {
        // نتجاهل الخطأ ← نحاول مرة ثانية لاحقاً
        continue;
      }
    }

    return syncedCount;
  }

  /// عدد العمليات المعلقة
  Future<int> getPendingCount() async {
    if (_db == null) return 0;
    final result = await _db!.rawQuery(
      'SELECT COUNT(*) as count FROM offline_queue WHERE synced = 0',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ─── كاش الطلاب ───

  /// حفظ/تحديث بيانات طالب في الكاش
  Future<void> cacheStudent({
    required String id,
    required String mosqueId,
    required String name,
    int? localNumber,
    String? qrCode,
    required Map<String, dynamic> fullData,
  }) async {
    if (_db == null) return;

    await _db!.insert(
      'cached_students',
      {
        'id': id,
        'mosque_id': mosqueId,
        'name': name,
        'local_number': localNumber,
        'qr_code': qrCode,
        'data': jsonEncode(fullData),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// البحث في الكاش بالاسم
  Future<List<Map<String, dynamic>>> searchCachedStudents({
    required String mosqueId,
    String? query,
  }) async {
    if (_db == null) return [];

    if (query != null && query.isNotEmpty) {
      final results = await _db!.query(
        'cached_students',
        where: 'mosque_id = ? AND name LIKE ?',
        whereArgs: [mosqueId, '%$query%'],
      );
      return results
          .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
          .toList();
    }

    final results = await _db!.query(
      'cached_students',
      where: 'mosque_id = ?',
      whereArgs: [mosqueId],
    );
    return results
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// البحث بـ QR Code في الكاش
  Future<Map<String, dynamic>?> findCachedStudentByQR(String qrCode) async {
    if (_db == null) return null;

    final results = await _db!.query(
      'cached_students',
      where: 'qr_code = ?',
      whereArgs: [qrCode],
    );

    if (results.isEmpty) return null;
    return jsonDecode(results.first['data'] as String) as Map<String, dynamic>;
  }

  // ─── تنظيف ───

  /// حذف العمليات المزامنة القديمة (أكثر من 7 أيام)
  Future<void> cleanupOldOperations() async {
    if (_db == null) return;

    final cutoff =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    await _db!.delete(
      'offline_queue',
      where: 'synced = 1 AND created_at < ?',
      whereArgs: [cutoff],
    );
  }

  /// إغلاق قاعدة البيانات
  Future<void> dispose() async {
    await _db?.close();
  }
}
