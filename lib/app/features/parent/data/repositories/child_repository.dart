import '../../../../core/constants/app_enums.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';

/// نتيجة إضافة ابن — مع بيانات الدخول للابن إن تم إنشاء الحساب
class AddChildResult {
  final ChildModel child;
  final String? email;
  final String? password;

  const AddChildResult(this.child, {this.email, this.password});
}

/// مستودع الأبناء - إضافة، جلب، ربط بمسجد
class ChildRepository {
  ChildRepository(this._authRepo, this._mosqueRepo);

  final AuthRepository _authRepo;
  final MosqueRepository _mosqueRepo;

  /// الابن المرتبط بحساب تسجيل الدخول (للدور child) — RLS تسمح بالقراءة إن كان userId = المستخدم الحالي
  Future<ChildModel?> getChildByLoginUserId(String userId) async {
    final row = await supabase
        .from('children')
        .select()
        .eq('login_user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return ChildModel.fromJson(row);
  }

  /// ابن واحد (إن كان من أبنائي)
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

  /// أبنائي
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

  /// إضافة ابن. إن وُجدت [email] و [password] يُنشَأ حساب للابن عبر Edge Function وتُرجع بيانات الدخول.
  Future<AddChildResult> addChild({
    required String name,
    required int age,
    String? email,
    String? password,
  }) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final row = await supabase.from('children').insert({
      'parent_id': user.id,
      'name': name,
      'age': age,
    }).select().single();
    final child = ChildModel.fromJson(row);

    if (email != null && email.isNotEmpty && password != null && password.isNotEmpty) {
      try {
        final res = await supabase.functions.invoke(
          'create_child_account',
          body: {'child_id': child.id, 'email': email, 'password': password},
        );
        if (res.status == 200 && res.data != null) {
          final data = res.data as Map<String, dynamic>?;
          return AddChildResult(
            child,
            email: data?['email'] as String? ?? email,
            password: data?['password'] as String? ?? password,
          );
        }
      } catch (_) {
        // الابن مُدرج؛ إرجاع النتيجة بدون credentials
      }
    }
    return AddChildResult(child);
  }

  /// ربط ابن بمسجد (بكود المسجد)
  Future<void> linkChildToMosque({
    required String childId,
    required String mosqueCode,
  }) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final mosque = await _mosqueRepo.getApprovedMosqueByCode(mosqueCode);
    if (mosque == null) throw Exception('كود المسجد غير صحيح أو المسجد غير معتمد');

    final children = await getMyChildren();
    if (!children.any((c) => c.id == childId)) throw Exception('الابن غير موجود');

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

  /// مساجد الابن (المرتبط بها)
  Future<List<String>> getChildMosqueIds(String childId) async {
    final res = await supabase
        .from('mosque_children')
        .select('mosque_id')
        .eq('child_id', childId)
        .eq('is_active', true);
    return (res as List).map((e) => e['mosque_id'] as String).toList();
  }

  /// حضور ابن واحد في تاريخ معيّن (للابن أو ولي الأمر — RLS يسمح للابن بحضوره فقط)
  Future<List<AttendanceModel>> getAttendanceForChildOnDate(
    String childId,
    DateTime date,
  ) async {
    final dateStr = _dateStr(date);
    final res = await supabase
        .from('attendance')
        .select()
        .eq('child_id', childId)
        .eq('prayer_date', dateStr)
        .order('prayer', ascending: true);
    return (res as List).map((e) => AttendanceModel.fromJson(e)).toList();
  }

  /// حضور أبنائي لتاريخ معيّن (لولي الأمر — دورة حياة الحضور)
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

  /// ملف الابن الشامل — الابن + مساجده + نقاطه + سلسلته
  Future<Map<String, dynamic>> getFullChildProfile(String childId) async {
    final child = await getMyChild(childId);
    if (child == null) throw Exception('الابن غير موجود');

    // مساجد الابن
    final mosqueIds = await getChildMosqueIds(childId);

    // إجمالي النقاط
    final attendance = await supabase
        .from('attendance')
        .select('points_earned')
        .eq('child_id', childId);
    int totalPoints = 0;
    for (final row in (attendance as List)) {
      totalPoints += (row['points_earned'] as num?)?.toInt() ?? 0;
    }

    // إجمالي أيام الحضور
    final totalDays = (attendance)
        .map((e) => e['prayer_date'] as String)
        .toSet()
        .length;

    return {
      'child': child,
      'mosque_ids': mosqueIds,
      'total_points': totalPoints,
      'total_days': totalDays,
      'level': (totalPoints ~/ 100) + 1,
    };
  }

  /// سجل حضور الابن — مع ترقيم
  Future<List<AttendanceModel>> getAttendanceHistory(
    String childId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await supabase
        .from('attendance')
        .select()
        .eq('child_id', childId)
        .order('prayer_date', ascending: false)
        .order('prayer', ascending: true)
        .range(offset, offset + limit - 1);

    return (res as List).map((e) => AttendanceModel.fromJson(e)).toList();
  }

  /// تقرير أسبوعي/شهري للابن
  Future<Map<String, dynamic>> getChildReport(
    String childId, {
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final res = await supabase
        .from('attendance')
        .select('prayer_date, prayer, points_earned')
        .eq('child_id', childId)
        .gte('prayer_date', _dateStr(fromDate))
        .lte('prayer_date', _dateStr(toDate));

    int totalPoints = 0;
    final byPrayer = <String, int>{};
    final uniqueDays = <String>{};

    for (final row in (res as List)) {
      final pts = (row['points_earned'] as num?)?.toInt() ?? 0;
      totalPoints += pts;
      final prayer = row['prayer'] as String;
      byPrayer[prayer] = (byPrayer[prayer] ?? 0) + 1;
      uniqueDays.add(row['prayer_date'] as String);
    }

    final totalDays = toDate.difference(fromDate).inDays + 1;
    final attendedDays = uniqueDays.length;
    final attendanceRate = totalDays > 0 ? (attendedDays / totalDays * 100) : 0.0;

    return {
      'total_prayers': (res).length,
      'total_points': totalPoints,
      'attended_days': attendedDays,
      'total_days': totalDays,
      'attendance_rate': attendanceRate.round(),
      'by_prayer': byPrayer,
    };
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
