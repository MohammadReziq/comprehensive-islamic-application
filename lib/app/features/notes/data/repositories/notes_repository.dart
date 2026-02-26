// lib/app/features/notes/data/repositories/notes_repository.dart

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/note_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class NotesRepository {
  NotesRepository(this._authRepo);

  final AuthRepository _authRepo;

  // ─────────────────────────────────────────────────────────
  // مشرف/إمام: إرسال ملاحظة لولي أمر ابن
  // ─────────────────────────────────────────────────────────

  Future<NoteModel> sendNote({
    required String childId,
    required String mosqueId,
    required String message,
  }) async {
    try {
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) throw const NotLoggedInFailure();

      final row = await supabase.from('notes').insert({
        'child_id':  childId,
        'sender_id': user.id,
        'mosque_id': mosqueId,
        'message':   message,
        'is_read':   false,
      }).select().single();

      return NoteModel.fromJson(row);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // ولي الأمر: ملاحظات أبنائه (مرتبة بالأحدث)
  // ─────────────────────────────────────────────────────────

  Future<List<NoteModel>> getNotesForMyChildren(
      List<String> childIds) async {
    try {
      if (childIds.isEmpty) return [];

      // جلب الملاحظات مع اسم الابن + رد ولي الأمر
      final res = await supabase
          .from('notes')
          .select('*, children(name)')
          .inFilter('child_id', childIds)
          .order('created_at', ascending: false);

      return (res as List).map((e) => NoteModel.fromJson(e)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // ابن: ملاحظاته الخاصة (التحسين 7)
  // ─────────────────────────────────────────────────────────

  /// ملاحظات ابن معيّن — RLS تضمن أن الابن يقرأ فقط ملاحظاته
  Future<List<NoteModel>> getNotesForChild(String childId) async {
    try {
      final res = await supabase
          .from('notes')
          .select('*, children(name)')
          .eq('child_id', childId)
          .order('created_at', ascending: false);

      return (res as List).map((e) => NoteModel.fromJson(e)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // مشرف: الملاحظات التي أرسلها
  // ─────────────────────────────────────────────────────────

  /// ملاحظات أرسلها المستخدم (مشرف/إمام) — مع اسم الابن + رد ولي الأمر
  Future<List<NoteModel>> getMySentNotes() async {
    try {
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) return [];

      final res = await supabase
          .from('notes')
          .select('*, children(name)')
          .eq('sender_id', user.id)
          .order('created_at', ascending: false);

      return (res as List).map((e) => NoteModel.fromJson(e)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // ولي الأمر: رد على ملاحظة (مرة واحدة) — التحسين 3
  // ─────────────────────────────────────────────────────────

  /// يرسل رد ولي الأمر على ملاحظة معيّنة.
  /// يفشل إن كان قد ردّ سابقاً (شرط parent_reply IS NULL في RLS/DB).
  Future<NoteModel> updateParentReply({
    required String noteId,
    required String replyText,
  }) async {
    try {
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) throw const NotLoggedInFailure();

      // الشرط parent_reply IS NULL يُطبّق على مستوى RLS أيضاً (Migration 034)
      final res = await supabase
          .from('notes')
          .update({
            'parent_reply':      replyText.trim(),
            'parent_replied_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', noteId)
          .isFilter('parent_reply', null)   // يمنع الكتابة فوق رد موجود
          .select('*, children(name)')
          .maybeSingle();

      if (res == null) {
        throw Exception('لا يمكن الرد: إما أن ردّك وُجد مسبقاً أو الملاحظة غير موجودة.');
      }

      return NoteModel.fromJson(res);
    } on AppFailure {
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // تحديث حالة القراءة
  // ─────────────────────────────────────────────────────────

  Future<void> markAsRead(String noteId) async {
    try {
      await supabase
          .from('notes')
          .update({'is_read': true})
          .eq('id', noteId);
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  /// تحديث كل ملاحظات ابن كمقروءة
  Future<void> markAllReadForChild(String childId) async {
    try {
      await supabase
          .from('notes')
          .update({'is_read': true})
          .eq('child_id', childId)
          .eq('is_read', false);
    } catch (e) {
      throw mapPostgresError(e);
    }
  }
}
