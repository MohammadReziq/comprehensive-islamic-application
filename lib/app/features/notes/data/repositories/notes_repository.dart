// lib/app/features/notes/data/repositories/notes_repository.dart

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/note_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class NotesRepository {
  NotesRepository(this._authRepo);

  final AuthRepository _authRepo;

  // ─────────────────────────────────────────────────────────
  // مشرف/إمام: إرسال ملاحظة لولي أمر طفل
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
  // ولي الأمر: ملاحظات أطفاله (مرتبة بالأحدث)
  // ─────────────────────────────────────────────────────────

  Future<List<NoteModel>> getNotesForMyChildren(
      List<String> childIds) async {
    try {
      if (childIds.isEmpty) return [];

      final res = await supabase
          .from('notes')
          .select()
          .inFilter('child_id', childIds)
          .order('created_at', ascending: false);

      return (res as List).map((e) => NoteModel.fromJson(e)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // مشرف: الملاحظات التي أرسلها
  // ─────────────────────────────────────────────────────────

  Future<List<NoteModel>> getMySentNotes() async {
    try {
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) return [];

      final res = await supabase
          .from('notes')
          .select()
          .eq('sender_id', user.id)
          .order('created_at', ascending: false);

      return (res as List).map((e) => NoteModel.fromJson(e)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // ولي الأمر: تحديث حالة القراءة
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

  // ─────────────────────────────────────────────────────────
  // تحديث كل ملاحظات طفل كمقروءة
  // ─────────────────────────────────────────────────────────

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
