// lib/app/features/corrections/data/repositories/correction_repository.dart

import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/correction_request_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class CorrectionRepository {
  CorrectionRepository(this._authRepo);

  final AuthRepository _authRepo;

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─────────────────────────────────────────────────────────
  // ولي الأمر: إنشاء طلب تصحيح
  // ─────────────────────────────────────────────────────────

  Future<CorrectionRequestModel> createRequest({
    required String childId,
    required String mosqueId,
    required Prayer prayer,
    required DateTime prayerDate,
    String? note,
  }) async {
    try {
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) throw const NotLoggedInFailure();

      final dateStr = _dateStr(prayerDate);

      // التحقق: لا يوجد حضور مسبق
      final existing = await supabase
          .from('attendance')
          .select('id')
          .eq('child_id', childId)
          .eq('prayer', prayer.value)
          .eq('prayer_date', dateStr)
          .maybeSingle();
      if (existing != null) throw const AttendanceAlreadyExistsFailure();

      // التحقق: لا يوجد طلب pending (partial unique سيمنع التكرار أيضاً)
      final pendingCheck = await supabase
          .from('correction_requests')
          .select('id')
          .eq('child_id', childId)
          .eq('prayer', prayer.value)
          .eq('prayer_date', dateStr)
          .eq('status', 'pending')
          .maybeSingle();
      if (pendingCheck != null) throw const PendingCorrectionExistsFailure();

      final row = await supabase.from('correction_requests').insert({
        'child_id':   childId,
        'parent_id':  user.id,
        'mosque_id':  mosqueId,
        'prayer':     prayer.value,
        'prayer_date': dateStr,
        'note':       note,
        'status':     'pending',
      }).select().single();

      return CorrectionRequestModel.fromJson(row);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // مشرف/إمام: طلبات معلقة للمسجد
  // ─────────────────────────────────────────────────────────

  Future<List<CorrectionRequestModel>> getPendingForMosque(
      String mosqueId) async {
    try {
      final res = await supabase
          .from('correction_requests')
          .select()
          .eq('mosque_id', mosqueId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => CorrectionRequestModel.fromJson(e))
          .toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // ولي الأمر: طلباتي
  // ─────────────────────────────────────────────────────────

  Future<List<CorrectionRequestModel>> getMyRequests() async {
    try {
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) return [];

      final res = await supabase
          .from('correction_requests')
          .select()
          .eq('parent_id', user.id)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => CorrectionRequestModel.fromJson(e))
          .toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // مشرف/إمام: موافقة (عبر RPC آمنة في DB)
  // ─────────────────────────────────────────────────────────

  Future<String> approveRequest(String requestId) async {
    try {
      final result = await supabase.rpc(
        'approve_correction_request',
        params: {'p_request_id': requestId},
      );
      return result as String;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // مشرف/إمام: رفض
  // ─────────────────────────────────────────────────────────

  Future<void> rejectRequest(String requestId, {String? reason}) async {
    try {
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) throw const NotLoggedInFailure();

      await supabase
          .from('correction_requests')
          .update({
            'status':      'rejected',
            'reviewed_by': user.id,
            'reviewed_at': DateTime.now().toIso8601String(),
            if (reason != null) 'note': reason,
          })
          .eq('id', requestId)
          .eq('status', 'pending');
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }
}
