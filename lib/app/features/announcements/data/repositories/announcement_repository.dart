// lib/app/features/announcements/data/repositories/announcement_repository.dart

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/announcement_model.dart';
import '../../../../models/user_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// مستودع الإعلانات — إنشاء، جلب، تعديل، حذف
class AnnouncementRepository {
  AnnouncementRepository(this._authRepo);

  final AuthRepository _authRepo;

  /// إنشاء إعلان جديد (الإمام فقط)
  Future<AnnouncementModel> create({
    required String mosqueId,
    required String title,
    required String body,
    bool isPinned = false,
  }) async {
    try {
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) throw const NotLoggedInFailure();

      final row = await supabase.from('announcements').insert({
        'mosque_id': mosqueId,
        'sender_id': user.id,
        'title': title,
        'body': body,
        'is_pinned': isPinned,
      }).select().single();

      return AnnouncementModel.fromJson(row);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// جلب إعلانات مسجد (الأحدث أولاً، المثبتة في المقدمة)
  Future<List<AnnouncementModel>> getForMosque(
    String mosqueId, {
    int limit = 50,
  }) async {
    try {
      final res = await supabase
          .from('announcements')
          .select()
          .eq('mosque_id', mosqueId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return (res as List)
          .map((e) => AnnouncementModel.fromJson(e))
          .toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// تعديل إعلان (الإمام فقط)
  Future<AnnouncementModel> update(
    String announcementId, {
    String? title,
    String? body,
    bool? isPinned,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (body != null) updates['body'] = body;
      if (isPinned != null) updates['is_pinned'] = isPinned;
      updates['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final row = await supabase
          .from('announcements')
          .update(updates)
          .eq('id', announcementId)
          .select()
          .single();

      return AnnouncementModel.fromJson(row);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// حذف إعلان (الإمام فقط)
  Future<void> delete(String announcementId) async {
    try {
      await supabase
          .from('announcements')
          .delete()
          .eq('id', announcementId);
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// تثبيت/إلغاء تثبيت إعلان
  Future<void> togglePin(String announcementId, bool isPinned) async {
    try {
      await supabase
          .from('announcements')
          .update({'is_pinned': isPinned})
          .eq('id', announcementId);
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// المستخدم الحالي (للمصادقة ومعرف المستخدم)
  Future<UserModel?> getCurrentUser() async =>
      _authRepo.getCurrentUserProfile();

  /// إعلانات لولي الأمر (مساجد أبنائه فقط)
  Future<List<AnnouncementModel>> getForParent(List<String> mosqueIds,
      {int limit = 50}) async {
    if (mosqueIds.isEmpty) return [];
    try {
      final res = await supabase
          .from('announcements')
          .select()
          .inFilter('mosque_id', mosqueIds)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List).map((e) => AnnouncementModel.fromJson(e)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// معرفات الإعلانات التي قرأها المستخدم
  Future<Set<String>> getReadIds(String userId) async {
    try {
      final res = await supabase
          .from('announcement_reads')
          .select('announcement_id')
          .eq('user_id', userId);
      return (res as List)
          .map((e) => e['announcement_id'] as String)
          .toSet();
    } catch (e) {
      return {};
    }
  }

  /// تسجيل قراءة إعلان (للوالد)
  Future<void> markAsRead(String announcementId, String userId) async {
    try {
      await supabase.from('announcement_reads').upsert({
        'announcement_id': announcementId,
        'user_id': userId,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'announcement_id,user_id');
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// تسجيل قراءة كل الإعلانات المعطاة (للوالد — عند دخول شاشة الإعلانات)
  Future<void> markAllAsRead(List<String> announcementIds, String userId) async {
    if (announcementIds.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      for (final id in announcementIds) {
        await supabase.from('announcement_reads').upsert({
          'announcement_id': id,
          'user_id': userId,
          'read_at': now,
        }, onConflict: 'announcement_id,user_id');
      }
    } catch (e) {
      throw mapPostgresError(e);
    }
  }
}
