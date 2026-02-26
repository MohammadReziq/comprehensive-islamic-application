import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../models/announcement_model.dart';
import '../../../parent/data/repositories/child_repository.dart';
import '../bloc/announcement_bloc.dart';
import '../bloc/announcement_event.dart';
import '../bloc/announcement_state.dart';

/// شاشة إعلانات ولي الأمر — إعلانات مساجد أبنائه، مقروء/غير مقروء
class ParentAnnouncementsScreen extends StatefulWidget {
  const ParentAnnouncementsScreen({super.key});

  @override
  State<ParentAnnouncementsScreen> createState() =>
      _ParentAnnouncementsScreenState();
}

class _ParentAnnouncementsScreenState extends State<ParentAnnouncementsScreen> {
  bool _hasMarkedAllRead = false;

  @override
  void initState() {
    super.initState();
    _loadMosqueIdsAndAnnouncements();
  }

  Future<void> _loadMosqueIdsAndAnnouncements() async {
    final children = await sl<ChildRepository>().getMyChildren();
    final mosqueIds = <String>{};
    for (final c in children) {
      final ids = await sl<ChildRepository>().getChildMosqueIds(c.id);
      mosqueIds.addAll(ids);
    }
    if (!mounted) return;
    context.read<AnnouncementBloc>().add(LoadForParent(mosqueIds.toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text('الإعلانات'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocConsumer<AnnouncementBloc, AnnouncementState>(
          listener: (context, state) {
            if (state is AnnouncementsLoaded &&
                !_hasMarkedAllRead &&
                state.announcements.isNotEmpty) {
              final unreadIds = state.announcements
                  .map((a) => a.id)
                  .where((id) => !state.readIds.contains(id))
                  .toList();
              if (unreadIds.isNotEmpty) {
                _hasMarkedAllRead = true;
                context.read<AnnouncementBloc>().add(MarkAllAsRead(unreadIds));
              }
            }
          },
          buildWhen: (_, __) => true,
          builder: (context, state) {
            if (state is AnnouncementLoading && state is! AnnouncementsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AnnouncementError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loadMosqueIdsAndAnnouncements,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is AnnouncementsLoaded) {
              if (state.announcements.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد إعلانات حتى الآن',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'انضم لمسجد أو انتظر إعلانات من إمام المسجد',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _loadMosqueIdsAndAnnouncements,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.announcements.length,
                  itemBuilder: (context, index) {
                    final a = state.announcements[index];
                    final isRead = state.readIds.contains(a.id);
                    return _AnnouncementTile(
                      announcement: a,
                      isRead: isRead,
                      onTap: () => _openAndMarkRead(context, a, state),
                    );
                  },
                ),
              );
            }
            return const Center(child: Text('اسحب للتحديث'));
          },
        ),
      ),
    );
  }

  void _openAndMarkRead(BuildContext context, AnnouncementModel a,
      AnnouncementsLoaded state) {
    context.read<AnnouncementBloc>().add(MarkAsRead(a.id));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                a.body,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDate(a.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${d.year}/${d.month}/${d.day}';
  }
}

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementModel announcement;
  final bool isRead;
  final VoidCallback onTap;

  const _AnnouncementTile({
    required this.announcement,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isRead
            ? BorderSide.none
            : BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isRead ? Colors.grey : AppColors.primary)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: isRead ? Colors.grey : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                        color: isRead ? Colors.grey.shade700 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
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
}
