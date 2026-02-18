// lib/app/features/notes/presentation/bloc/notes_event.dart

import 'package:equatable/equatable.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotesForChildren extends NotesEvent {
  final List<String> childIds;
  const LoadNotesForChildren(this.childIds);
  @override
  List<Object?> get props => [childIds];
}

class LoadSentNotes extends NotesEvent {
  const LoadSentNotes();
}

class SendNote extends NotesEvent {
  final String childId;
  final String mosqueId;
  final String message;
  const SendNote({
    required this.childId,
    required this.mosqueId,
    required this.message,
  });
  @override
  List<Object?> get props => [childId, mosqueId, message];
}

class MarkNoteRead extends NotesEvent {
  final String noteId;
  const MarkNoteRead(this.noteId);
  @override
  List<Object?> get props => [noteId];
}

class MarkAllNotesRead extends NotesEvent {
  final String childId;
  const MarkAllNotesRead(this.childId);
  @override
  List<Object?> get props => [childId];
}
