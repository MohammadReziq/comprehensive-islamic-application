import '../../../../core/constants/app_enums.dart';
import '../../../../core/network/supabase_client.dart';
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

  /// تسجيل حضور طفل لصلاة في المسجد
  Future<AttendanceModel> recordAttendance({
    required String mosqueId,
    required String childId,
    required Prayer prayer,
    required DateTime date,
  }) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final points = sl<PointsService>().calculateAttendancePoints(
      prayer: prayer,
      locationType: LocationType.mosque,
    );

    final dateStr = _dateStr(date);
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
  }

  /// البحث عن طفل بـ QR في قائمة طلاب المسجد (أو من جدول children)
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

  /// طفل برقمه المحلي في المسجد
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

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
