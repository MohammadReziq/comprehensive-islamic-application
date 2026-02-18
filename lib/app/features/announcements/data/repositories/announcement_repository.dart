// lib/app/features/announcements/data/repositories/announcement_repository.dart

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/announcement_model.dart';
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
        'created_by': user.id,
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
}
