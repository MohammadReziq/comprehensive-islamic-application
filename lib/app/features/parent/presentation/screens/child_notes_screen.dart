// lib/app/features/parent/presentation/screens/child_notes_screen.dart
// صندوق ملاحظات الابن — التحسين 7

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../models/note_model.dart';
import '../../../notes/data/repositories/notes_repository.dart';

class ChildNotesScreen extends StatefulWidget {
  const ChildNotesScreen({super.key, required this.childId, required this.childName});

  final String childId;
  final String childName;

  @override
  State<ChildNotesScreen> createState() => _ChildNotesScreenState();
}

class _ChildNotesScreenState extends State<ChildNotesScreen> {
  List<NoteModel> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final notes = await sl<NotesRepository>().getNotesForChild(widget.childId);
      if (mounted) setState(() { _notes = notes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'حدث خطأ أثناء التحميل'; _loading = false; });
    }
  }

  Future<void> _markRead(NoteModel note) async {
    if (note.isRead) return;
    try {
      await sl<NotesRepository>().markAsRead(note.id);
      if (mounted) {
        setState(() {
          final idx = _notes.indexWhere((n) => n.id == note.id);
          if (idx != -1) _notes[idx] = note.copyWith(isRead: true);
        });
      }
    } catch (_) {}
  }

  void _showDetail(NoteModel note) {
    _markRead(note);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (_, ctrl) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: ListView(
              controller: ctrl,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // العنوان
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ملاحظة من المشرف',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                // نص الملاحظة
                Text(
                  note.message,
                  style: const TextStyle(
                      fontSize: 15, height: 1.7, color: Color(0xFF3D4F5F)),
                ),
                const SizedBox(height: 12),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(note.createdAt.toLocal()),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notes.where((n) => !n.isRead).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text('رسائل ${widget.childName}'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Badge(
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.mark_email_unread_rounded),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _notes.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildTile(_notes[i]),
                        ),
                      ),
      ),
    );
  }

  Widget _buildTile(NoteModel note) {
    return Material(
      color: note.isRead ? Colors.white : const Color(0xFFEDF7FF),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.hardEdge,
      elevation: note.isRead ? 0 : 1,
      child: InkWell(
        onTap: () => _showDetail(note),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.speaker_notes_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملاحظة من المشرف',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: note.isRead ? FontWeight.w600 : FontWeight.w800,
                        color: const Color(0xFF1A2B3C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy/MM/dd').format(note.createdAt.toLocal()),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (!note.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد ملاحظات بعد',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
}
