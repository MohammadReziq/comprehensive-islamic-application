// lib/app/features/notes/presentation/bloc/notes_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_failure.dart';
import '../../data/repositories/notes_repository.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc(this._repo) : super(NotesInitial()) {
    on<LoadNotesForChildren>(_onLoadForChildren);
    on<LoadSentNotes>(_onLoadSent);
    on<SendNote>(_onSend);
    on<MarkNoteRead>(_onMarkRead);
    on<MarkAllNotesRead>(_onMarkAllRead);
  }

  final NotesRepository _repo;

  Future<void> _onLoadForChildren(
      LoadNotesForChildren event, Emitter emit) async {
    emit(NotesLoading());
    try {
      final notes = await _repo.getNotesForMyChildren(event.childIds);
      emit(NotesLoaded(notes));
    } on AppFailure catch (f) {
      emit(NotesError(f.messageAr));
    } catch (_) {
      emit(const NotesError('حدث خطأ في تحميل الملاحظات'));
    }
  }

  Future<void> _onLoadSent(LoadSentNotes event, Emitter emit) async {
    emit(NotesLoading());
    try {
      final notes = await _repo.getMySentNotes();
      emit(NotesLoaded(notes));
    } on AppFailure catch (f) {
      emit(NotesError(f.messageAr));
    } catch (_) {
      emit(const NotesError('حدث خطأ في تحميل الملاحظات'));
    }
  }

  Future<void> _onSend(SendNote event, Emitter emit) async {
    emit(NotesLoading());
    try {
      await _repo.sendNote(
        childId:  event.childId,
        mosqueId: event.mosqueId,
        message:  event.message,
      );
      emit(const NotesSent());
    } on AppFailure catch (f) {
      emit(NotesError(f.messageAr));
    } catch (_) {
      emit(const NotesError('حدث خطأ في إرسال الملاحظة'));
    }
  }

  Future<void> _onMarkRead(MarkNoteRead event, Emitter emit) async {
    try {
      await _repo.markAsRead(event.noteId);
      // تحديث القائمة الحالية محلياً
      if (state is NotesLoaded) {
        final updated = (state as NotesLoaded).notes
            .map((n) => n.id == event.noteId ? n.copyWith(isRead: true) : n)
            .toList();
        emit(NotesLoaded(updated));
      }
    } catch (_) {
      // خطأ صامت — القراءة ليست حرجة
    }
  }

  Future<void> _onMarkAllRead(MarkAllNotesRead event, Emitter emit) async {
    try {
      await _repo.markAllReadForChild(event.childId);
      if (state is NotesLoaded) {
        final updated = (state as NotesLoaded).notes
            .map((n) => n.childId == event.childId
                ? n.copyWith(isRead: true)
                : n)
            .toList();
        emit(NotesLoaded(updated));
      }
    } catch (_) {
      // خطأ صامت
    }
  }
}
