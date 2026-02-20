import 'dart:math';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/mosque_model.dart';
import '../../../../models/other_models.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// مستودع المساجد - إنشاء، انضمام، جلب مساجدي
class MosqueRepository {
  MosqueRepository(this._authRepo);

  final AuthRepository _authRepo;

  static final _random = Random.secure();
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _generateCode(int length) {
    return List.generate(length, (_) => _codeChars[_random.nextInt(_codeChars.length)]).join();
  }

  /// إنشاء مسجد جديد (المستخدم الحالي = المالك) — الموقع إلزامي
  Future<MosqueModel> createMosque({
    required String name,
    String? address,
    required double lat,
    required double lng,
  }) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw Exception('يجب تسجيل الدخول');

    String code;
    String inviteCode;
    int attempts = 0;
    while (true) {
      code = _generateCode(6);
      inviteCode = _generateCode(8);
      try {
        final res = await supabase.from('mosques').insert({
          'owner_id': user.id,
          'name': name,
          'code': code,
          'invite_code': inviteCode,
          'address': address,
          'lat': lat,
          'lng': lng,
          'status': 'pending',
        }).select().single();
        final mosque = MosqueModel.fromJson(res);

        await supabase.from('mosque_members').insert({
          'mosque_id': mosque.id,
          'user_id': user.id,
          'role': 'owner',
        });
        return mosque;
      } catch (e) {
        if (e.toString().contains('unique') && attempts < 5) {
          attempts++;
          continue;
        }
        rethrow;
      }
    }
  }

  /// طلب الانضمام لمسجد بكود الدعوة (يُرسل طلباً للإمام للموافقة)
  Future<MosqueModel> requestToJoinByInviteCode(String inviteCode) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final trimmed = inviteCode.trim().toUpperCase();
    if (trimmed.isEmpty) throw Exception('أدخل كود الدعوة');

    final row = await supabase
        .from('mosques')
        .select()
        .eq('invite_code', trimmed)
        .eq('status', 'approved')
        .maybeSingle();
    if (row == null) throw Exception('كود الدعوة غير صحيح');

    final mosqueId = row['id'] as String;

    final existingMember = await supabase
        .from('mosque_members')
        .select('id')
        .eq('mosque_id', mosqueId)
        .eq('user_id', user.id)
        .maybeSingle();
    if (existingMember != null) throw Exception('أنت منضم لهذا المسجد مسبقاً');

    final existingRequest = await supabase
        .from('mosque_join_requests')
        .select('id')
        .eq('mosque_id', mosqueId)
        .eq('user_id', user.id)
        .eq('status', 'pending')
        .maybeSingle();
    if (existingRequest != null) throw Exception('لديك طلب انضمام قيد المراجعة لهذا المسجد');

    await supabase.from('mosque_join_requests').insert({
      'mosque_id': mosqueId,
      'user_id': user.id,
      'status': 'pending',
    });
    return MosqueModel.fromJson(row);
  }

  /// طلبات الانضمام المعلقة لمسجد مع أسماء الطالبين (للإمام، عبر RPC لتجنب RLS على users)
  Future<List<MosqueJoinRequestModel>> getPendingJoinRequests(String mosqueId) async {
    final res = await supabase.rpc(
      'get_pending_join_requests_with_names',
      params: {'p_mosque_id': mosqueId},
    );
    if (res == null) return [];
    final list = res is List ? res : (res is Map ? (res['data'] as List?) ?? [] : []);
    return list
        .map((e) => MosqueJoinRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// موافقة الإمام على طلب انضمام → إدراج في mosque_members وتحديث الطلب
  Future<void> approveJoinRequest(String requestId) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final req = await supabase
        .from('mosque_join_requests')
        .select('mosque_id, user_id')
        .eq('id', requestId)
        .eq('status', 'pending')
        .maybeSingle();
    if (req == null) throw Exception('الطلب غير موجود أو تمت معالجته');

    await supabase.from('mosque_members').insert({
      'mosque_id': req['mosque_id'],
      'user_id': req['user_id'],
      'role': 'supervisor',
    });
    await supabase.from('mosque_join_requests').update({
      'status': 'approved',
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_by': user.id,
    }).eq('id', requestId);
  }

  /// رفض الإمام لطلب انضمام
  Future<void> rejectJoinRequest(String requestId) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw Exception('يجب تسجيل الدخول');

    await supabase.from('mosque_join_requests').update({
      'status': 'rejected',
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_by': user.id,
    }).eq('id', requestId).eq('status', 'pending');
  }

  /// مساجدي (كمالك أو مشرف)
  Future<List<MosqueModel>> getMyMosques() async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) return [];

    final members = await supabase
        .from('mosque_members')
        .select('mosque_id')
        .eq('user_id', user.id);
    if (members.isEmpty) return [];

    final ids = (members as List).map((e) => e['mosque_id'] as String).toSet().toList();
    final list = await supabase.from('mosques').select().inFilter('id', ids).order('created_at', ascending: false);
    return (list as List).map((e) => MosqueModel.fromJson(e)).toList();
  }

  /// قائمة مشرفي المسجد مع الأسماء (للمالك/الإمام، عبر RPC لتجنب RLS على users)
  Future<List<MosqueMemberModel>> getMosqueSupervisors(String mosqueId) async {
    final res = await supabase.rpc(
      'get_mosque_supervisors_with_names',
      params: {'p_mosque_id': mosqueId},
    );
    if (res == null) return [];
    final list = res is List ? res : (res is Map ? (res['data'] as List?) ?? [] : []);
    return list
        .map((e) => MosqueMemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// إزالة مشرف من المسجد (للمالك فقط — RLS يسمح بحذف أعضاء مسجده)
  Future<void> removeMosqueMember(String mosqueId, String userId) async {
    await supabase
        .from('mosque_members')
        .delete()
        .eq('mosque_id', mosqueId)
        .eq('user_id', userId);
  }

  /// هل لدي مسجد معتمد؟
  Future<bool> hasApprovedMosque() async {
    final list = await getMyMosques();
    return list.any((m) => m.status == MosqueStatus.approved);
  }

  /// جلب مساجد بعدة معرفات (مثلاً مساجد الطفل لشاشة طلب التصحيح)
  Future<List<MosqueModel>> getMosquesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final list = await supabase
        .from('mosques')
        .select()
        .inFilter('id', ids)
        .order('name');
    return (list as List).map((e) => MosqueModel.fromJson(e)).toList();
  }

  /// مسجد معتمد بكوده (لربط الأطفال من ولي الأمر)
  Future<MosqueModel?> getApprovedMosqueByCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    final row = await supabase
        .from('mosques')
        .select()
        .eq('code', trimmed)
        .eq('status', 'approved')
        .maybeSingle();
    if (row == null) return null;
    return MosqueModel.fromJson(row);
  }

  /// طلبات المساجد قيد المراجعة (للسوبر أدمن فقط)
  Future<List<MosqueModel>> getPendingMosquesForAdmin() async {
    final res = await supabase
        .from('mosques')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (res as List).map((e) => MosqueModel.fromJson(e)).toList();
  }

  /// تحديث حالة المسجد (موافقة/رفض) — للسوبر أدمن
  Future<void> updateMosqueStatus(String mosqueId, MosqueStatus status) async {
    await supabase
        .from('mosques')
        .update({'status': status.value})
        .eq('id', mosqueId);
  }

  /// تحديث موقع المسجد (للإمام) — يُستخدم لحساب أوقات الصلاة
  Future<void> updateMosqueLocation(
    String mosqueId, {
    required double lat,
    required double lng,
  }) async {
    await supabase.from('mosques').update({
      'lat': lat,
      'lng': lng,
    }).eq('id', mosqueId);
  }

  /// تحديث إعدادات المسجد (للإمام)
  Future<void> updateMosqueSettings(
    String mosqueId, {
    String? name,
    String? address,
    double? lat,
    double? lng,
    int? attendanceWindowMinutes,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (address != null) updates['address'] = address;
    if (lat != null) updates['lat'] = lat;
    if (lng != null) updates['lng'] = lng;
    if (attendanceWindowMinutes != null) {
      updates['attendance_window_minutes'] = attendanceWindowMinutes;
    }
    if (updates.isEmpty) return;

    await supabase.from('mosques').update(updates).eq('id', mosqueId);
  }
}
