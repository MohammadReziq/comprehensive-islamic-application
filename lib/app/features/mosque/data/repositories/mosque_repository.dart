import 'dart:math';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/mosque_model.dart';
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

  /// إنشاء مسجد جديد (المستخدم الحالي = المالك)
  Future<MosqueModel> createMosque({
    required String name,
    String? address,
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

  /// الانضمام لمسجد بكود الدعوة
  Future<MosqueModel> joinByInviteCode(String inviteCode) async {
    final user = await _authRepo.getCurrentUserProfile();
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final trimmed = inviteCode.trim().toUpperCase();
    if (trimmed.isEmpty) throw Exception('أدخل كود الدعوة');

    final row = await supabase
        .from('mosques')
        .select()
        .eq('invite_code', trimmed)
        .maybeSingle();
    if (row == null) throw Exception('كود الدعوة غير صحيح');

    await supabase.from('mosque_members').insert({
      'mosque_id': row['id'],
      'user_id': user.id,
      'role': 'supervisor',
    });
    return MosqueModel.fromJson(row);
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

  /// هل لدي مسجد معتمد؟
  Future<bool> hasApprovedMosque() async {
    final list = await getMyMosques();
    return list.any((m) => m.status == MosqueStatus.approved);
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
}
