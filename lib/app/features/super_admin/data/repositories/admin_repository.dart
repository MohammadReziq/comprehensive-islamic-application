// lib/app/features/super_admin/data/repositories/admin_repository.dart

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../models/mosque_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// مستودع مدير النظام — عمليات إدارة النظام
class AdminRepository {
  AdminRepository(this._authRepo);

  final AuthRepository _authRepo;

  // ─── إحصائيات النظام ───

  /// إحصائيات النظام الشاملة
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      // إجمالي المساجد
      final mosques = await supabase.from('mosques').select('id, status');
      final totalMosques = (mosques as List).length;
      final approvedMosques =
          mosques.where((m) => m['status'] == 'approved').length;
      final pendingMosques =
          mosques.where((m) => m['status'] == 'pending').length;

      // إجمالي المستخدمين
      final users = await supabase.from('users').select('id, role');
      final totalUsers = (users as List).length;

      // إجمالي الأطفال
      final children = await supabase.from('children').select('id');
      final totalChildren = (children as List).length;

      // حضور اليوم (كل المساجد)
      final todayStr = _dateStr(DateTime.now());
      final todayAttendance = await supabase
          .from('attendance')
          .select('id')
          .eq('prayer_date', todayStr);
      final todayCount = (todayAttendance as List).length;

      return {
        'total_mosques': totalMosques,
        'approved_mosques': approvedMosques,
        'pending_mosques': pendingMosques,
        'total_users': totalUsers,
        'total_children': totalChildren,
        'today_attendance': todayCount,
      };
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── إدارة المساجد ───

  /// كل المساجد (مع فلتر حسب الحالة)
  Future<List<MosqueModel>> getAllMosques({MosqueStatus? status}) async {
    try {
      var query = supabase.from('mosques').select();
      if (status != null) {
        query = query.eq('status', status.value);
      }
      final res = await query.order('created_at', ascending: false);
      return (res as List).map((e) => MosqueModel.fromJson(e)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// تعليق مسجد (تغيير حالته لـ rejected)
  Future<void> suspendMosque(String mosqueId) async {
    try {
      await supabase
          .from('mosques')
          .update({'status': 'rejected'})
          .eq('id', mosqueId);
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// إعادة تفعيل مسجد (تغيير حالته لـ approved)
  Future<void> reactivateMosque(String mosqueId) async {
    try {
      await supabase
          .from('mosques')
          .update({'status': 'approved'})
          .eq('id', mosqueId);
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// تحديث موقع المسجد على الخريطة
  Future<void> updateMosqueLocation(String mosqueId, double lat, double lng) async {
    try {
      await supabase
          .from('mosques')
          .update({'lat': lat, 'lng': lng})
          .eq('id', mosqueId);
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── إدارة المستخدمين ───

  /// كل المستخدمين مع أدوارهم
  Future<List<Map<String, dynamic>>> getAllUsers({
    UserRole? role,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = supabase.from('users').select('id, name, email, role, created_at');
      if (role != null) {
        query = query.eq('role', role.value);
      }
      final res = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// تغيير دور مستخدم
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      await supabase
          .from('users')
          .update({'role': newRole.value})
          .eq('id', userId);
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// حظر مستخدم (يمكن إضافة عمود is_banned لاحقاً)
  /// حالياً: تغيير الدور لـ parent فقط
  Future<void> banUser(String userId) async {
    try {
      await supabase
          .from('users')
          .update({'role': 'parent'})
          .eq('id', userId);
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── تغيير إمام المسجد ───

  /// تغيير مالك المسجد (نقل الملكية)
  Future<void> changeImam(String mosqueId, String newOwnerId) async {
    try {
      // تحديث المسجد
      await supabase
          .from('mosques')
          .update({'owner_id': newOwnerId})
          .eq('id', mosqueId);

      // تحديث الأعضاء — المالك القديم → مشرف
      await supabase
          .from('mosque_members')
          .update({'role': 'supervisor'})
          .eq('mosque_id', mosqueId)
          .eq('role', 'owner');

      // المالك الجديد → owner
      // أولاً نتحقق هل هو عضو
      final existing = await supabase
          .from('mosque_members')
          .select('id')
          .eq('mosque_id', mosqueId)
          .eq('user_id', newOwnerId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('mosque_members')
            .update({'role': 'owner'})
            .eq('mosque_id', mosqueId)
            .eq('user_id', newOwnerId);
      } else {
        await supabase.from('mosque_members').insert({
          'mosque_id': mosqueId,
          'user_id': newOwnerId,
          'role': 'owner',
        });
      }
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
