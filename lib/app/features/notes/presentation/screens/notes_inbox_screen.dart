// lib/app/features/notes/presentation/screens/notes_inbox_screen.dart
// صندوق الملاحظات — لولي الأمر

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';

/// اسم الابن من الداتا؛ إن لم يُجلب نعرض "لم نستطع جلب الاسم" لتعرف أن الحالة خطأ وتختبر التطبيق.
String _effectiveChildName(String? childName) {
  final trimmed = childName?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  return 'لم نستطع جلب الاسم';
}

class NotesInboxScreen extends StatelessWidget {
  final List<String> childIds;
  const NotesInboxScreen({super.key, required this.childIds});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotesBloc>()..add(LoadNotesForChildren(childIds)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ملاحظات المشرف'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              BlocBuilder<NotesBloc, NotesState>(
                builder: (context, state) {
                  final hasUnread = state is NotesLoaded &&
                      state.notes.any((n) => !n.isRead);
                  if (!hasUnread) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () {
                      // نُطلق MarkAllNotesRead لكل ابن على حدة
                      for (final id in childIds) {
                        context.read<NotesBloc>().add(MarkAllNotesRead(id));
                      }
                    },
                    child: const Text(
                      'قراءة الكل',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<NotesBloc, NotesState>(
            builder: (context, state) {
              if (state is NotesLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is NotesLoaded) {
                if (state.notes.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد ملاحظات بعد',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<NotesBloc>().add(
                      LoadNotesForChildren(childIds),
                    );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final note = state.notes[i];
                      return Dismissible(
                        key: Key(note.id),
                        direction: DismissDirection.startToEnd,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.success,
                          child: const Icon(
                            Icons.done_all,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          context.read<NotesBloc>().add(MarkNoteRead(note.id));
                        },
                        child: Card(
                          elevation: note.isRead ? 0 : 3,
                          color: note.isRead
                              ? Colors.grey.shade50
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: note.isRead
                                ? BorderSide.none
                                : const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: note.isRead
                                  ? Colors.grey.shade200
                                  : AppColors.primary.withValues(alpha: 0.15),
                              child: Icon(
                                Icons.person,
                                color: note.isRead
                                    ? Colors.grey
                                    : AppColors.primary,
                              ),
                            ),
                            title: Text(
                              _effectiveChildName(note.childName),
                              style: TextStyle(
                                fontWeight: note.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(note.message),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'yyyy/MM/dd HH:mm',
                                  ).format(note.createdAt.toLocal()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: note.isRead
                                ? null
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () {
                              if (!note.isRead) {
                                context.read<NotesBloc>().add(
                                  MarkNoteRead(note.id),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              if (state is NotesError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
