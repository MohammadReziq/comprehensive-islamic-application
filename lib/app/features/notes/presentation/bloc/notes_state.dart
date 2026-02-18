// lib/app/features/notes/presentation/bloc/notes_state.dart

import 'package:equatable/equatable.dart';
import '../../../../models/note_model.dart';

abstract class NotesState extends Equatable {
  const NotesState();
  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {}
class NotesLoading extends NotesState {}

class NotesLoaded extends NotesState {
  final List<NoteModel> notes;
  final int unreadCount;
  const NotesLoaded(this.notes)
      : unreadCount = 0; // يُحسب في getter

  int get unread => notes.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [notes];
}

class NotesSent extends NotesState {
  const NotesSent();
}

class NotesError extends NotesState {
  final String message;
  const NotesError(this.message);
  @override
  List<Object?> get props => [message];
}
