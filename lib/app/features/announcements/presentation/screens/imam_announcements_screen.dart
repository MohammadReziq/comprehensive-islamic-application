import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:salati_hayati/app/models/announcement_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/announcement_bloc.dart';
import '../bloc/announcement_event.dart';
import '../bloc/announcement_state.dart';
import '../widgets/announcement_detail_sheet.dart';
import '../widgets/announcement_empty_state.dart';
import '../widgets/announcement_tile.dart';
import '../widgets/create_announcement_dialog.dart';

/// شاشة إعلانات الإمام — عرض وإنشاء وحذف إعلانات المسجد.
class ImamAnnouncementsScreen extends StatefulWidget {
  final String mosqueId;

  const ImamAnnouncementsScreen({super.key, required this.mosqueId});

  @override
  State<ImamAnnouncementsScreen> createState() =>
      _ImamAnnouncementsScreenState();
}

class _ImamAnnouncementsScreenState extends State<ImamAnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AnnouncementBloc>().add(LoadAnnouncements(widget.mosqueId));
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateAnnouncementDialog(mosqueId: widget.mosqueId),
    );
  }

  void _showDetail(AnnouncementModel a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnnouncementDetailSheet(
        announcement: a,
        showDeleteButton: true,
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(a);
        },
      ),
    );
  }

  void _confirmDelete(AnnouncementModel a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AnnouncementBloc>().add(DeleteAnnouncement(a.id));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text('إعلانات المسجد'),
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
            if (state is AnnouncementActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF2E8B57),
                ),
              );
              context.read<AnnouncementBloc>().add(
                LoadAnnouncements(widget.mosqueId),
              );
            }
            if (state is AnnouncementError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AnnouncementLoading && state is! AnnouncementsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AnnouncementsLoaded) {
              if (state.announcements.isEmpty) {
                return const AnnouncementEmptyState(
                  message: 'لا توجد إعلانات',
                  subtitle: 'اضغط + لإضافة إعلان',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => context.read<AnnouncementBloc>().add(
                  LoadAnnouncements(widget.mosqueId),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.announcements.length,
                  itemBuilder: (_, index) {
                    final a = state.announcements[index];
                    return AnnouncementTile(
                      announcement: a,
                      isPinned: a.isPinned,
                      onTap: () => _showDetail(a),
                    );
                  },
                ),
              );
            }
            return const Center(child: Text('اسحب للتحديث'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateDialog,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }
}
