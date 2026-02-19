import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/mosque_model.dart';
import '../../../../models/other_models.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../supervisor/data/repositories/supervisor_repository.dart';
import '../../../mosque/presentation/bloc/mosque_event.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';

/// لوحة مدير المسجد (الإمام) — صفحة مخصصة للإمام: إدارة المشرفين، الأكواد، والإجراءات
class ImamDashboardScreen extends StatefulWidget {
  const ImamDashboardScreen({super.key});

  @override
  State<ImamDashboardScreen> createState() => _ImamDashboardScreenState();
}

class _ImamDashboardScreenState extends State<ImamDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _statsRefreshKey = 0;
  String? _mosqueChildrenSubscribedForMosqueId;

  List<MosqueMemberModel>? _supervisors;
  bool _loadingSupervisors = false;
  List<MosqueJoinRequestModel>? _pendingRequests;
  bool _loadingPendingRequests = false;
  String? _removingUserId;
  String? _processingRequestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<MosqueBloc>().state;
      if (state is! MosqueLoaded || state.mosques.isEmpty) {
        context.read<MosqueBloc>().add(const MosqueLoadMyMosques());
      }
      sl<RealtimeService>().subscribeMosques((_) {
        if (mounted) {
          context.read<MosqueBloc>().add(const MosqueLoadMyMosques());
        }
      });
    });
  }

  @override
  void dispose() {
    sl<RealtimeService>().unsubscribeMosques();
    sl<RealtimeService>().unsubscribeMosqueChildren();
    _mosqueChildrenSubscribedForMosqueId = null;
    super.dispose();
  }

  void _loadSupervisors(String mosqueId) async {
    setState(() => _loadingSupervisors = true);
    try {
      final list = await sl<MosqueRepository>().getMosqueSupervisors(mosqueId);
      if (mounted)
        setState(() {
          _supervisors = list;
          _loadingSupervisors = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _supervisors = [];
          _loadingSupervisors = false;
        });
    }
  }

  void _loadPendingRequests(String mosqueId) async {
    setState(() => _loadingPendingRequests = true);
    try {
      final list = await sl<MosqueRepository>().getPendingJoinRequests(
        mosqueId,
      );
      if (mounted)
        setState(() {
          _pendingRequests = list;
          _loadingPendingRequests = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _pendingRequests = [];
          _loadingPendingRequests = false;
        });
    }
  }

  Future<void> _removeSupervisor(
    MosqueModel mosque,
    MosqueMemberModel member,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.removeSupervisor),
        content: Text(
          'هل تريد إزالة "${member.userName ?? member.userEmail ?? 'المشرف'}" من مسجد ${mosque.name}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _removingUserId = member.userId);
    try {
      await sl<MosqueRepository>().removeMosqueMember(mosque.id, member.userId);
      if (mounted) {
        setState(() {
          _supervisors =
              _supervisors?.where((m) => m.userId != member.userId).toList() ??
              [];
          _removingUserId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إزالة المشرف'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _removingUserId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = sl<PrayerTimesService>().getNextPrayer();
    return BlocBuilder<MosqueBloc, MosqueState>(
      builder: (context, state) {
        MosqueModel? mosque;
        if (state is MosqueLoaded) {
          try {
            mosque = state.mosques.firstWhere(
              (m) => m.status == MosqueStatus.approved,
            );
          } catch (_) {}
        }
        if (mosque != null && _supervisors == null && !_loadingSupervisors) {
          _loadingSupervisors = true;
          final mosqueId = mosque.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadSupervisors(mosqueId);
          });
        }
        if (mosque != null &&
            _pendingRequests == null &&
            !_loadingPendingRequests) {
          _loadingPendingRequests = true;
          final mosqueId = mosque.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadPendingRequests(mosqueId);
          });
        }
        if (mosque != null &&
            mosque.id != _mosqueChildrenSubscribedForMosqueId) {
          _mosqueChildrenSubscribedForMosqueId = mosque.id;
          sl<RealtimeService>().unsubscribeMosqueChildren();
          sl<RealtimeService>().subscribeMosqueChildren(mosque.id, (_) {
            if (mounted) setState(() => _statsRefreshKey++);
          });
        }

        final initialDataReady =
            mosque != null && _supervisors != null && _pendingRequests != null;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            key: _scaffoldKey,

            body: IndexedStack(
              index: _selectedIndex,
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                    ),
                  ),
                  child: SafeArea(
                    child: !initialDataReady
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  'جاري التحميل...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppDimensions.paddingLG,
                              ),
                              child: Column(
                                children: [
                                  _buildAppBar(context),
                                  const SizedBox(height: AppDimensions.paddingMD),
                                  _buildTopSection(
                                    context,
                                    mosque,
                                    nextPrayer,
                                  ),
                                  const SizedBox(height: AppDimensions.paddingLG),
                                  _buildActionsGrid(
                                    context,
                                    mosque,
                                    nextPrayer,
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.paddingXXL,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                const ProfileScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'لوحة المدير',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'الملف الشخصي',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMD,
            horizontal: AppDimensions.paddingSM,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCodesDialog(BuildContext context, MosqueModel mosque) {
    void copyAndShow(String value, String label) {
      Clipboard.setData(ClipboardData(text: value));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ $label'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mosque.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: const Text('كود المسجد'),
              subtitle: Text(mosque.code),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => copyAndShow(mosque.code, 'كود المسجد'),
              ),
            ),
            ListTile(
              title: const Text('كود الدعوة'),
              subtitle: Text(mosque.inviteCode),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => copyAndShow(mosque.inviteCode, 'كود الدعوة'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showNextPrayerDialog(BuildContext context, dynamic nextPrayer) {
    final nameAr = nextPrayer?.nameAr ?? '—';
    final timeFormatted = nextPrayer?.timeFormatted ?? '—';
    final remaining = nextPrayer?.remaining;
    final remainingStr = remaining != null
        ? 'بعد ${remaining.inMinutes} د'
        : '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الصلاة القادمة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$nameAr — $timeFormatted',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (remainingStr.isNotEmpty)
              Text(remainingStr, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(
    BuildContext context,
    MosqueModel mosque,
    dynamic nextPrayer,
  ) {
    final nextName = nextPrayer?.nameAr ?? '—';
    final nextTime = nextPrayer?.timeFormatted ?? '';
    final pendingCount = (_pendingRequests?.length ?? 0).toString();
    return Row(
      children: [
        Expanded(
          child: _buildTopTile(
            context,
            icon: Icons.schedule,
            title: 'الصلاة القادمة',
            subtitle: '$nextName $nextTime',
            onTap: () => _showNextPrayerDialog(context, nextPrayer),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTopTile(
            context,
            icon: Icons.person_add,
            title: 'طلبات الانضمام',
            subtitle: pendingCount != '0' ? '$pendingCount طلب' : 'لا توجد',
            onTap: () => _showJoinRequestsSheet(context, mosque),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTopTile(
            context,
            icon: Icons.link,
            title: 'كود الدعوة',
            subtitle: mosque.inviteCode,
            onTap: () {
              Clipboard.setData(ClipboardData(text: mosque.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ كود الدعوة'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTopTile(
            context,
            icon: Icons.mosque,
            title: mosque.name,
            subtitle: 'كود: ${mosque.code}',
            onTap: () => _showCodesDialog(context, mosque),
          ),
        ),
      ],
    );
  }

  Widget _buildTopTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingSM,
            horizontal: AppDimensions.paddingXS,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsGrid(
    BuildContext context,
    MosqueModel? mosque,
    dynamic nextPrayer,
  ) {
    if (mosque == null) return const SizedBox.shrink();
    final rows = <Widget>[
      Row(
        children: [
          Expanded(
            child: _buildGridTile(
              context,
              icon: Icons.people_outline,
              title: 'المشرفون',
              onTap: () => _showSupervisorsSheet(context, mosque),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGridTile(
              context,
              icon: Icons.qr_code_scanner,
              title: 'التحضير',
              onTap: () => context.push('/supervisor/scan').then((_) {
                if (mounted) setState(() => _statsRefreshKey++);
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGridTile(
              context,
              icon: Icons.people,
              title: AppStrings.students,
              onTap: () => context.push('/supervisor/students').then((_) {
                if (mounted) setState(() => _statsRefreshKey++);
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGridTile(
              context,
              icon: Icons.edit_note,
              title: 'طلب تصحيح',
              onTap: () => context.push('/imam/corrections/${mosque.id}'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGridTile(
              context,
              icon: Icons.note_alt_outlined,
              title: 'الملاحظات',
              onTap: () => context.push('/supervisor/notes/send/${mosque.id}'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _buildGridTile(
              context,
              icon: Icons.emoji_events,
              title: 'المسابقات',
              onTap: () => context.push('/imam/competitions/${mosque.id}'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGridTile(
              context,
              icon: Icons.star_outline,
              title: 'نقاط الصلاة',
              onTap: () => context.push(
                '/imam/mosque/${mosque.id}/prayer-points',
                extra: mosque.name,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGridTile(
              context,
              icon: Icons.settings_outlined,
              title: 'إعدادات المسجد',
              onTap: () => context.push(
                '/imam/mosque/${mosque.id}/settings',
                extra: mosque,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGridTile(
              context,
              icon: Icons.bar_chart_outlined,
              title: 'تقرير الحضور',
              onTap: () =>
                  context.push('/imam/mosque/${mosque.id}/attendance-report'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _buildGridTile(
              context,
              icon: Icons.people_outline,
              title: 'أداء المشرفين',
              onTap: () => context.push(
                '/imam/mosque/${mosque.id}/supervisors-performance',
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: SizedBox.shrink()),
          const SizedBox(width: 8),
          const Expanded(child: SizedBox.shrink()),
          const SizedBox(width: 8),
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
    ];
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  void _showJoinRequestsSheet(BuildContext context, MosqueModel mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewPadding.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'طلبات الانضمام',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  child: _buildPendingJoinRequestsContent(ctx, mosque),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupervisorsSheet(BuildContext context, MosqueModel mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewPadding.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'المشرفون',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  child: _buildSupervisorsContent(ctx, mosque),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'لوحة مدير المسجد',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildMosqueCard(BuildContext context, MosqueModel mosque) {
    void copyAndShow(String value, String label) {
      Clipboard.setData(ClipboardData(text: value));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ $label'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mosque, color: Colors.white, size: 28),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: Text(
                  mosque.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          _buildCodeRow(
            context,
            label: AppStrings.mosqueCode,
            value: mosque.code,
            hint: 'لربط الأطفال (ولي الأمر)',
            onCopy: () => copyAndShow(mosque.code, AppStrings.mosqueCode),
          ),
          const SizedBox(height: 6),
          _buildCodeRow(
            context,
            label: AppStrings.inviteCode,
            value: mosque.inviteCode,
            hint: 'لدعوة المشرفين',
            onCopy: () => copyAndShow(mosque.inviteCode, AppStrings.inviteCode),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeRow(
    BuildContext context, {
    required String label,
    required String value,
    required String hint,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, color: Colors.white, size: 22),
          onPressed: onCopy,
          tooltip: AppStrings.copyCode,
        ),
      ],
    );
  }

  Widget _buildPendingJoinRequestsContent(
    BuildContext context,
    MosqueModel mosque,
  ) {
    if (_loadingPendingRequests) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLG),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }
    final list = _pendingRequests ?? [];
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        child: Text(
          'لا توجد طلبات انضمام جديدة.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      );
    }
    return Column(
      children: list.map((r) {
        final isProcessing = _processingRequestId == r.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMD,
              vertical: AppDimensions.paddingSM,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Row(
              children: [
                Icon(Icons.person_add, color: Colors.white70, size: 22),
                const SizedBox(width: AppDimensions.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.userName ?? r.userEmail ?? 'مستخدم طلب الانضمام',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (r.userEmail != null && r.userEmail!.isNotEmpty)
                        Text(
                          r.userEmail!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isProcessing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 26,
                    ),
                    onPressed: () => _approveJoinRequest(mosque, r),
                    tooltip: AppStrings.approve,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                    onPressed: () => _rejectJoinRequest(mosque, r),
                    tooltip: AppStrings.reject,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _approveJoinRequest(
    MosqueModel mosque,
    MosqueJoinRequestModel request,
  ) async {
    setState(() => _processingRequestId = request.id);
    try {
      await sl<MosqueRepository>().approveJoinRequest(request.id);
      if (mounted) {
        setState(() {
          _pendingRequests =
              _pendingRequests?.where((r) => r.id != request.id).toList() ?? [];
          _processingRequestId = null;
          _supervisors = null;
          _loadingSupervisors = false;
        });
        _loadSupervisors(mosque.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت الموافقة على طلب الانضمام'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingRequestId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectJoinRequest(
    MosqueModel mosque,
    MosqueJoinRequestModel request,
  ) async {
    setState(() => _processingRequestId = request.id);
    try {
      await sl<MosqueRepository>().rejectJoinRequest(request.id);
      if (mounted) {
        setState(() {
          _pendingRequests =
              _pendingRequests?.where((r) => r.id != request.id).toList() ?? [];
          _processingRequestId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض طلب الانضمام'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingRequestId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSupervisorsContent(BuildContext context, MosqueModel mosque) {
    if (_loadingSupervisors) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLG),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }
    final list = _supervisors ?? [];
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        child: Text(
          'لا يوجد مشرفون بعد. شارك كود الدعوة لدعوتهم.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      );
    }
    return Column(
      children: list.map((m) {
        final isRemoving = _removingUserId == m.userId;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMD,
              vertical: AppDimensions.paddingSM,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: Colors.white70, size: 22),
                const SizedBox(width: AppDimensions.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.userName ?? m.userEmail ?? 'مشرف',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (m.userEmail != null && m.userEmail!.isNotEmpty)
                        Text(
                          m.userEmail!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: isRemoving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        )
                      : const Icon(
                          Icons.person_remove,
                          color: Colors.white70,
                          size: 24,
                        ),
                  onPressed: isRemoving
                      ? null
                      : () => _removeSupervisor(mosque, m),
                  tooltip: AppStrings.removeSupervisor,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextPrayerCard(dynamic nextPrayer) {
    final nameAr = nextPrayer?.nameAr ?? '—';
    final timeFormatted = nextPrayer?.timeFormatted ?? '—';
    final remaining = nextPrayer?.remaining;
    final remainingStr = remaining != null ? '${remaining.inMinutes} د' : '';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppDimensions.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.nextPrayer,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '$nameAr $timeFormatted',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (remainingStr.isNotEmpty)
                  Text(
                    'بعد $remainingStr',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, MosqueModel? mosque) {
    if (mosque == null) {
      return Row(
        children: [
          Expanded(child: _buildStatChip('حضور اليوم', '0')),
          const SizedBox(width: AppDimensions.paddingSM),
          Expanded(child: _buildStatChip('طلاب المسجد', '—')),
        ],
      );
    }
    final repo = sl<SupervisorRepository>();
    return FutureBuilder<List<dynamic>>(
      key: ValueKey(_statsRefreshKey),
      future: Future.wait([
        repo.getTodayAttendanceCount(mosque.id),
        repo.getMosqueStudents(mosque.id),
      ]),
      builder: (context, snapshot) {
        final todayCount = snapshot.hasData && snapshot.data != null
            ? (snapshot.data![0] as int).toString()
            : '—';
        final studentsCount = snapshot.hasData && snapshot.data != null
            ? (snapshot.data![1] as List).length.toString()
            : '—';
        return Row(
          children: [
            Expanded(child: _buildStatChip('حضور اليوم', todayCount)),
            const SizedBox(width: AppDimensions.paddingSM),
            Expanded(child: _buildStatChip('طلاب المسجد', studentsCount)),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.paddingMD,
        horizontal: AppDimensions.paddingSM,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
