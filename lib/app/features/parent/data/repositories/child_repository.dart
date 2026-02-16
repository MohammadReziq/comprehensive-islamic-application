import '../../../../core/constants/app_enums.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';

/// مستودع الأطفال - إضافة، جلب، ربط بمسجد
class ChildRepository {
  ChildRepository(this._authRepo, this._mosqueRepo);

  final AuthRepository _authRepo;
  final MosqueRepository _mosqueRepo;

  /// طفل واحد (إن كان من أطفالي)
  Future<ChildModel?> getMyChild(String childId) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) return null;
    final row = await supabase
        .from('children')
        .select()
        .eq('id', childId)
        .eq('parent_id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return ChildModel.fromJson(row);
  }

  /// أطفالي
  Future<List<ChildModel>> getMyChildren() async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) return [];

    final res = await supabase
        .from('children')
        .select()
        .eq('parent_id', user.id)
        .order('created_at', ascending: false);
    return (res as List).map((e) => ChildModel.fromJson(e)).toList();
  }

  /// إضافة طفل
  Future<ChildModel> addChild({
    required String name,
    required int age,
  }) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final row = await supabase.from('children').insert({
      'parent_id': user.id,
      'name': name,
      'age': age,
    }).select().single();
    return ChildModel.fromJson(row);
  }

  /// ربط طفل بمسجد (بكود المسجد)
  Future<void> linkChildToMosque({
    required String childId,
    required String mosqueCode,
  }) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final mosque = await _mosqueRepo.getApprovedMosqueByCode(mosqueCode);
    if (mosque == null) throw Exception('كود المسجد غير صحيح أو المسجد غير معتمد');

    final children = await getMyChildren();
    if (!children.any((c) => c.id == childId)) throw Exception('الطفل غير موجود');

    final maxNum = await supabase
        .from('mosque_children')
        .select('local_number')
        .eq('mosque_id', mosque.id)
        .order('local_number', ascending: false)
        .limit(1);

    int next = 1;
    final list = maxNum as List;
    if (list.isNotEmpty) {
      next = (list.first['local_number'] as int) + 1;
    }

    await supabase.from('mosque_children').insert({
      'mosque_id': mosque.id,
      'child_id': childId,
      'type': MosqueType.primary.value,
      'local_number': next,
      'is_active': true,
    });
  }

  /// مساجد الطفل (المرتبط بها)
  Future<List<String>> getChildMosqueIds(String childId) async {
    final res = await supabase
        .from('mosque_children')
        .select('mosque_id')
        .eq('child_id', childId)
        .eq('is_active', true);
    return (res as List).map((e) => e['mosque_id'] as String).toList();
  }

  /// حضور أطفالي لتاريخ معيّن (لولي الأمر — دورة حياة الحضور)
  Future<List<AttendanceModel>> getAttendanceForMyChildren(DateTime date) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) return [];

    final children = await getMyChildren();
    if (children.isEmpty) return [];

    final childIds = children.map((c) => c.id).toList();
    final dateStr = _dateStr(date);

    final res = await supabase
        .from('attendance')
        .select()
        .inFilter('child_id', childIds)
        .eq('prayer_date', dateStr)
        .order('prayer', ascending: true);

    return (res as List).map((e) => AttendanceModel.fromJson(e)).toList();
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
