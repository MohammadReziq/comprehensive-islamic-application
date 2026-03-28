import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:salati_hayati/app/models/announcement_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../parent/data/repositories/child_repository.dart';
import '../bloc/announcement_bloc.dart';
import '../bloc/announcement_event.dart';
import '../bloc/announcement_state.dart';
import '../widgets/announcement_detail_sheet.dart';
import '../widgets/announcement_empty_state.dart';
import '../widgets/announcement_tile.dart';

/// شاشة إعلانات ولي الأمر — إعلانات مساجد أبنائه، مع دعم القراءة التلقائية.
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

  void _openDetail(BuildContext context, AnnouncementModel a) {
    context.read<AnnouncementBloc>().add(MarkAsRead(a.id));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnnouncementDetailSheet(announcement: a),
    );
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
              return _ErrorView(
                message: state.message,
                onRetry: _loadMosqueIdsAndAnnouncements,
              );
            }
            if (state is AnnouncementsLoaded) {
              if (state.announcements.isEmpty) {
                return const AnnouncementEmptyState(
                  message: 'لا توجد إعلانات حتى الآن',
                  subtitle: 'انضم لمسجد أو انتظر إعلانات من إمام المسجد',
                );
              }
              return RefreshIndicator(
                onRefresh: _loadMosqueIdsAndAnnouncements,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.announcements.length,
                  itemBuilder: (_, index) {
                    final a = state.announcements[index];
                    final isRead = state.readIds.contains(a.id);
                    return AnnouncementTile(
                      announcement: a,
                      isRead: isRead,
                      showReadDot: true,
                      onTap: () => _openDetail(context, a),
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
}

// ── حالة الخطأ ──────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
