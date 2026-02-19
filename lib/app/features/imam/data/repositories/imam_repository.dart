// lib/app/features/imam/data/repositories/imam_repository.dart

import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/mosque_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// مستودع الإمام — عمليات خاصة بمدير المسجد
class ImamRepository {
  ImamRepository(this._authRepo);

  final AuthRepository _authRepo;

  // ─── إحصائيات المسجد ───

  /// إحصائيات شاملة للمسجد
  Future<Map<String, dynamic>> getMosqueStats(String mosqueId) async {
    try {
      final now = DateTime.now();
      final todayStr = _dateStr(now);

      // عدد الطلاب المسجلين
      final students = await supabase
          .from('mosque_children')
          .select('id')
          .eq('mosque_id', mosqueId)
          .eq('is_active', true);
      final totalStudents = (students as List).length;

      // عدد المشرفين
      final supervisors = await supabase
          .from('mosque_members')
          .select('id')
          .eq('mosque_id', mosqueId)
          .eq('role', 'supervisor');
      final totalSupervisors = (supervisors as List).length;

      // حضور اليوم
      final todayAttendance = await supabase
          .from('attendance')
          .select('id')
          .eq('mosque_id', mosqueId)
          .eq('prayer_date', todayStr);
      final todayCount = (todayAttendance as List).length;

      // طلبات التصحيح المعلقة
      final pendingCorrections = await supabase
          .from('correction_requests')
          .select('id')
          .eq('mosque_id', mosqueId)
          .eq('status', 'pending');
      final pendingCount = (pendingCorrections as List).length;

      // طلبات الانضمام المعلقة
      final pendingJoins = await supabase
          .from('mosque_join_requests')
          .select('id')
          .eq('mosque_id', mosqueId)
          .eq('status', 'pending');
      final pendingJoinsCount = (pendingJoins as List).length;

      return {
        'total_students': totalStudents,
        'total_supervisors': totalSupervisors,
        'today_attendance': todayCount,
        'pending_corrections': pendingCount,
        'pending_joins': pendingJoinsCount,
      };
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── تقرير الحضور ───

  /// تقرير حضور المسجد لفترة معينة
  Future<List<Map<String, dynamic>>> getAttendanceReport(
    String mosqueId, {
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final res = await supabase
          .from('attendance')
          .select('prayer_date, prayer, child_id, points_earned, children(name)')
          .eq('mosque_id', mosqueId)
          .gte('prayer_date', _dateStr(fromDate))
          .lte('prayer_date', _dateStr(toDate))
          .order('prayer_date', ascending: false);

      return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── أداء المشرفين ───

  /// عدد سجلات الحضور التي سجّلها كل مشرف اليوم
  Future<List<Map<String, dynamic>>> getSupervisorsPerformance(
      String mosqueId) async {
    try {
      final todayStr = _dateStr(DateTime.now());

      // جلب أسماء المشرفين عبر RPC
      final supervisors = await supabase.rpc(
        'get_mosque_supervisors_with_names',
        params: {'p_mosque_id': mosqueId},
      );

      final result = <Map<String, dynamic>>[];
      for (final sup in (supervisors as List? ?? [])) {
        final userId = sup['user_id'] as String;
        final name = sup['user_name'] as String? ?? 'غير معروف';

        final records = await supabase
            .from('attendance')
            .select('id')
            .eq('mosque_id', mosqueId)
            .eq('recorded_by_id', userId)
            .eq('prayer_date', todayStr);

        result.add({
          'user_id': userId,
          'name': name,
          'role': sup['role'] ?? 'supervisor',
          'today_records': (records as List).length,
        });
      }

      return result;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── طلبات التصحيح المعالجة ───

  /// طلبات التصحيح المعالجة (مقبولة/مرفوضة = تاريخ)
  Future<List<Map<String, dynamic>>> getProcessedCorrections(
    String mosqueId, {
    int limit = 50,
  }) async {
    try {
      final res = await supabase
          .from('correction_requests')
          .select('*, children(name)')
          .eq('mosque_id', mosqueId)
          .neq('status', 'pending')
          .order('reviewed_at', ascending: false)
          .limit(limit);

      return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── نقاط الصلوات (الإمام يتحكم) ───

  /// جلب نقاط كل صلاة للمسجد من prayer_config؛ افتراضي 10 إن لم تُحدد
  Future<Map<Prayer, int>> getPrayerPointsForMosque(String mosqueId) async {
    try {
      final row = await supabase
          .from('mosques')
          .select('prayer_config')
          .eq('id', mosqueId)
          .maybeSingle();
      final config = row?['prayer_config'] as Map<String, dynamic>?;
      final result = <Prayer, int>{};
      for (final p in Prayer.values) {
        final v = config?[p.value];
        result[p] = (v is num) ? v.toInt() : 10;
      }
      return result;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// تحديث نقاط الصلوات للمسجد (الإمام فقط)
  Future<void> updateMosquePrayerPoints(
    String mosqueId,
    Map<Prayer, int> points,
  ) async {
    try {
      final config = <String, int>{};
      for (final e in points.entries) {
        config[e.key.value] = e.value;
      }
      await supabase
          .from('mosques')
          .update({'prayer_config': config})
          .eq('id', mosqueId);
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── تحديث إعدادات المسجد ───

  /// تحديث إعدادات المسجد (الاسم، العنوان، الموقع، نافذة الحضور)
  Future<MosqueModel> updateMosqueSettings(
    String mosqueId, {
    String? name,
    String? address,
    double? lat,
    double? lng,
    int? attendanceWindowMinutes,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (address != null) updates['address'] = address;
      if (lat != null) updates['lat'] = lat;
      if (lng != null) updates['lng'] = lng;
      if (attendanceWindowMinutes != null) {
        updates['attendance_window_minutes'] = attendanceWindowMinutes;
      }

      if (updates.isEmpty) {
        final row = await supabase
            .from('mosques')
            .select()
            .eq('id', mosqueId)
            .single();
        return MosqueModel.fromJson(row);
      }

      final row = await supabase
          .from('mosques')
          .update(updates)
          .eq('id', mosqueId)
          .select()
          .single();

      return MosqueModel.fromJson(row);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── إلغاء حضور (الإمام بلا قيد زمني) ───

  /// إلغاء حضور — الإمام يلغي أي حضور في مسجده
  Future<String> cancelAttendance(String attendanceId) async {
    try {
      final result = await supabase.rpc(
        'cancel_attendance',
        params: {'p_attendance_id': attendanceId},
      );
      return result as String;
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
