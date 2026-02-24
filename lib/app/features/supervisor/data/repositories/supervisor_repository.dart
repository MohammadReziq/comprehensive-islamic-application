import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/attendance_validation_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../../../../core/services/points_service.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../models/mosque_student_model.dart';

/// مستودع المشرف: طلاب المسجد + تسجيل الحضور
class SupervisorRepository {
  SupervisorRepository(this._authRepo);

  final AuthRepository _authRepo;

  /// طلاب مسجد معين (من mosque_children + children)
  Future<List<MosqueStudentModel>> getMosqueStudents(String mosqueId) async {
    final res = await supabase
        .from('mosque_children')
        .select('child_id, local_number')
        .eq('mosque_id', mosqueId)
        .eq('is_active', true)
        .order('local_number');

    if (res.isEmpty) return [];

    final childIds = (res as List).map((e) => e['child_id'] as String).toList();
    final childrenData = await supabase
        .from('children')
        .select()
        .inFilter('id', childIds);

    final childrenMap = <String, ChildModel>{};
    for (final row in childrenData as List) {
      final c = ChildModel.fromJson(row);
      childrenMap[c.id] = c;
    }

    return (res as List)
        .map((e) {
          final child = childrenMap[e['child_id'] as String];
          if (child == null) return null;
          return MosqueStudentModel(
            child: child,
            localNumber: e['local_number'] as int,
          );
        })
        .whereType<MosqueStudentModel>()
        .toList();
  }

  /// عدد سجلات الحضور اليوم لهذا المسجد (للعرض في لوحة المشرف)
  Future<int> getTodayAttendanceCount(String mosqueId) async {
    final dateStr = _dateStr(DateTime.now());
    final res = await supabase
        .from('attendance')
        .select('id')
        .eq('mosque_id', mosqueId)
        .eq('prayer_date', dateStr);
    return (res as List).length;
  }

  /// من سجّل حضورهم لصلاة معينة في تاريخ معين (في هذا المسجد)
  Future<Set<String>> getRecordedChildIdsForPrayer({
    required String mosqueId,
    required Prayer prayer,
    required DateTime date,
  }) async {
    final dateStr = _dateStr(date);
    final res = await supabase
        .from('attendance')
        .select('child_id')
        .eq('mosque_id', mosqueId)
        .eq('prayer', prayer.value)
        .eq('prayer_date', dateStr);

    return (res as List).map((e) => e['child_id'] as String).toSet();
  }

  /// تسجيل حضور ابن لصلاة في المسجد
  Future<AttendanceModel> recordAttendance({
    required String mosqueId,
    required String childId,
    required Prayer prayer,
    required DateTime date,
  }) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw const NotLoggedInFailure();

    // ── التحقق من وقت الصلاة وجلب نقاط الصلوات ──
    final mosqueData = await supabase
        .from('mosques')
        .select('owner_id, lat, lng, attendance_window_minutes, prayer_config')
        .eq('id', mosqueId)
        .maybeSingle();

    final String? ownerId = mosqueData?['owner_id'] as String?;
    final bool isImam = (ownerId != null && user.id == ownerId);
    final double? mLat = (mosqueData?['lat'] as num?)?.toDouble();
    final double? mLng = (mosqueData?['lng'] as num?)?.toDouble();
    final int windowMin = (mosqueData?['attendance_window_minutes'] as int?) ?? 60;
    final Map<Prayer, int>? mosquePrayerPoints = _prayerConfigToMap(
      mosqueData?['prayer_config'] as Map<String, dynamic>?,
    );

    final validation = await sl<AttendanceValidationService>().canRecordNow(
      prayer: prayer,
      date: date,
      lat: mLat,
      lng: mLng,
      windowMinutes: windowMin,
      isImam: isImam,
    );

    if (!validation.allowed) {
      if (validation.reason?.contains('لم يحن') == true) {
        throw const AttendanceBeforeAdhanFailure();
      }
      throw const AttendanceWindowClosedFailure();
    }

    // ── حساب النقاط وتسجيل الحضور ──
    final points = sl<PointsService>().calculateAttendancePoints(
      prayer: prayer,
      locationType: LocationType.mosque,
      mosquePrayerPoints: mosquePrayerPoints,
    );

    final dateStr = _dateStr(date);
    try {
      final row = await supabase.from('attendance').insert({
        'child_id': childId,
        'mosque_id': mosqueId,
        'recorded_by_id': user.id,
        'prayer': prayer.value,
        'location_type': LocationType.mosque.value,
        'points_earned': points,
        'prayer_date': dateStr,
      }).select().single();

      return AttendanceModel.fromJson(row);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// البحث عن ابن بـ QR في قائمة طلاب المسجد (أو من جدول children)
  Future<ChildModel?> findChildByQrCode(String qrCode, String mosqueId) async {
    final trimmed = qrCode.trim();
    if (trimmed.isEmpty) return null;

    final mc = await supabase
        .from('mosque_children')
        .select('child_id')
        .eq('mosque_id', mosqueId)
        .eq('is_active', true);

    final childIds = (mc as List).map((e) => e['child_id'] as String).toList();
    if (childIds.isEmpty) return null;

    final c = await supabase
        .from('children')
        .select()
        .inFilter('id', childIds)
        .eq('qr_code', trimmed)
        .maybeSingle();

    if (c == null) return null;
    return ChildModel.fromJson(c);
  }

  /// جلب بيانات ابن بالمعرّف (للإمام/المشرف — RLS تسمح فقط بأبناء مسجدهم)
  Future<ChildModel?> getChildById(String childId) async {
    final row = await supabase
        .from('children')
        .select()
        .eq('id', childId)
        .maybeSingle();
    if (row == null) return null;
    return ChildModel.fromJson(row);
  }

  /// ابن برقمه المحلي في المسجد
  Future<ChildModel?> findChildByLocalNumber(int localNumber, String mosqueId) async {
    final row = await supabase
        .from('mosque_children')
        .select('child_id')
        .eq('mosque_id', mosqueId)
        .eq('local_number', localNumber)
        .eq('is_active', true)
        .maybeSingle();

    if (row == null) return null;

    final childRow = await supabase
        .from('children')
        .select()
        .eq('id', row['child_id'])
        .single();

    return ChildModel.fromJson(childRow);
  }

  /// إلغاء حضور خاطئ
  /// المشرف: يلغي ما سجّله بنفسه خلال 24 ساعة
  /// الإمام: يلغي أي حضور في مسجده بدون قيد زمني
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

  /// البحث عن ابن بالاسم في قائمة طلاب المسجد
  Future<List<ChildModel>> findChildByName(String name, String mosqueId) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return [];

    final mc = await supabase
        .from('mosque_children')
        .select('child_id')
        .eq('mosque_id', mosqueId)
        .eq('is_active', true);

    final childIds = (mc as List).map((e) => e['child_id'] as String).toList();
    if (childIds.isEmpty) return [];

    final res = await supabase
        .from('children')
        .select()
        .inFilter('id', childIds)
        .ilike('name', '%$trimmed%');

    return (res as List).map((e) => ChildModel.fromJson(e)).toList();
  }

  /// إحصائيات يومية للمشرف: تفصيل الحضور لكل صلاة
  Future<Map<String, dynamic>> getDailyStats(String mosqueId, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final dateStr = _dateStr(d);

    final attendance = await supabase
        .from('attendance')
        .select('prayer, child_id')
        .eq('mosque_id', mosqueId)
        .eq('prayer_date', dateStr);

    final totalStudents = await supabase
        .from('mosque_children')
        .select('id')
        .eq('mosque_id', mosqueId)
        .eq('is_active', true);

    final byPrayer = <String, int>{};
    for (final p in Prayer.values) {
      byPrayer[p.value] = 0;
    }
    for (final row in (attendance as List)) {
      final p = row['prayer'] as String;
      byPrayer[p] = (byPrayer[p] ?? 0) + 1;
    }

    return {
      'date': dateStr,
      'total_students': (totalStudents as List).length,
      'total_attendance': (attendance).length,
      'by_prayer': byPrayer,
    };
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// تحويل prayer_config من DB إلى خريطة نقاط لكل صلاة؛ الناقص = 10
  static Map<Prayer, int>? _prayerConfigToMap(Map<String, dynamic>? config) {
    if (config == null || config.isEmpty) return null;
    final result = <Prayer, int>{};
    for (final p in Prayer.values) {
      final v = config[p.value];
      result[p] = (v is num) ? v.toInt() : 10;
    }
    return result;
  }
}
