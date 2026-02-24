// lib/app/features/parent/presentation/screens/parent_inbox_screen.dart
// صندوق الرسائل الموحّد — إعلانات + ملاحظات المشرف

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../models/announcement_model.dart';
import '../../../../models/note_model.dart';
import '../../../announcements/data/repositories/announcement_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';
import '../../../notes/data/repositories/notes_repository.dart';
import '../../data/repositories/child_repository.dart';

// ─── نوع العنصر في الصندوق ───
enum _ItemType { note, announcement }

// ─── عنصر موحّد (ملاحظة أو إعلان) ───
class _InboxItem {
  final String id;
  final _ItemType type;
  final String title;
  final String body;
  final DateTime date;
  final bool isRead;
  final String? childName;

  const _InboxItem._({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    required this.isRead,
    this.childName,
  });

  factory _InboxItem.fromNote(NoteModel n) => _InboxItem._(
        id: n.id,
        type: _ItemType.note,
        title: 'ملاحظة المشرف',
        body: n.message,
        date: n.createdAt,
        isRead: n.isRead,
        childName: n.childName,
      );

  factory _InboxItem.fromAnnouncement(AnnouncementModel a, bool isRead) =>
      _InboxItem._(
        id: a.id,
        type: _ItemType.announcement,
        title: a.title,
        body: a.body,
        date: a.createdAt,
        isRead: isRead,
      );

  _InboxItem markRead() => _InboxItem._(
        id: id,
        type: type,
        title: title,
        body: body,
        date: date,
        isRead: true,
        childName: childName,
      );
}

// ─── الشاشة الرئيسية ───
class ParentInboxScreen extends StatefulWidget {
  const ParentInboxScreen({super.key});

  @override
  State<ParentInboxScreen> createState() => _ParentInboxScreenState();
}

class _ParentInboxScreenState extends State<ParentInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<_InboxItem> _allItems = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      // 1. معرّفات الأبناء (للملاحظات)
      final children = await sl<ChildRepository>().getMyChildren();
      final childIds = children.map((c) => c.id).toList();

      // 2. معرّفات المساجد (للإعلانات)
      final mosques = await sl<MosqueRepository>().getMyMosques();
      final mosqueIds = mosques.map((m) => m.id).toList();

      // 3. المستخدم الحالي (لمعرفة الإعلانات المقروءة)
      final user = await sl<AuthRepository>().getCurrentUserProfile();

      // 4. جلب البيانات
      final notes = await sl<NotesRepository>().getNotesForMyChildren(childIds);

      final announcements = mosqueIds.isNotEmpty
          ? await sl<AnnouncementRepository>().getForParent(mosqueIds)
          : <AnnouncementModel>[];

      final readIds = user != null
          ? await sl<AnnouncementRepository>().getReadIds(user.id)
          : <String>{};

      // 5. دمج وترتيب
      final items = <_InboxItem>[
        ...notes.map(_InboxItem.fromNote),
        ...announcements
            .map((a) => _InboxItem.fromAnnouncement(a, readIds.contains(a.id))),
      ]..sort((a, b) => b.date.compareTo(a.date));

      if (mounted) setState(() { _allItems = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'حدث خطأ أثناء التحميل'; _loading = false; });
    }
  }

  Future<void> _onTap(_InboxItem item) async {
    await _showDetail(item);
    if (!item.isRead) {
      try {
        if (item.type == _ItemType.note) {
          await sl<NotesRepository>().markAsRead(item.id);
        } else {
          final user = await sl<AuthRepository>().getCurrentUserProfile();
          if (user != null) {
            await sl<AnnouncementRepository>().markAsRead(item.id, user.id);
          }
        }
        if (mounted) {
          setState(() {
            final idx = _allItems.indexWhere((i) => i.id == item.id);
            if (idx != -1) _allItems[idx] = item.markRead();
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _showDetail(_InboxItem item) async {
    final isNote = item.type == _ItemType.note;
    final accentColor =
        isNote ? const Color(0xFF00838F) : AppColors.primary;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.35,
        builder: (_, ctrl) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: ListView(
              controller: ctrl,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // نوع العنصر
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isNote ? 'ملاحظة المشرف' : 'إعلان',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                if (item.childName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الابن: ${item.childName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  item.body,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.65,
                    color: Color(0xFF3D4F5F),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _fullDate(item.date),
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
    final notes =
        _allItems.where((i) => i.type == _ItemType.note).toList();
    final announcements =
        _allItems.where((i) => i.type == _ItemType.announcement).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text('الرسائل'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              Tab(text: 'الكل (${_allItems.length})'),
              Tab(text: 'إعلانات (${announcements.length})'),
              Tab(text: 'ملاحظات (${notes.length})'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_allItems),
                      _buildList(announcements),
                      _buildList(notes),
                    ],
                  ),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadAll,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );

  Widget _buildList(List<_InboxItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'لا توجد رسائل',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildItemTile(items[i]),
      ),
    );
  }

  Widget _buildItemTile(_InboxItem item) {
    final isNote = item.type == _ItemType.note;
    final accentColor =
        isNote ? const Color(0xFF00BCD4) : AppColors.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.hardEdge,
      elevation: item.isRead ? 0 : 1,
      shadowColor: accentColor.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => _onTap(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isNote
                      ? Icons.speaker_notes_rounded
                      : Icons.campaign_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: const Color(0xFF1A2B3C),
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(item.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (item.childName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.childName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays}أيام';
    return '${date.day}/${date.month}';
  }

  String _fullDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  $h:$m';
  }
}
