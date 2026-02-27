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
import 'imam_profile_screen.dart';
import '../../../supervisor/data/repositories/supervisor_repository.dart';
import '../../../mosque/presentation/bloc/mosque_event.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';

class ImamDashboardScreen extends StatefulWidget {
  const ImamDashboardScreen({super.key});

  @override
  State<ImamDashboardScreen> createState() => _ImamDashboardScreenState();
}

class _ImamDashboardScreenState extends State<ImamDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _statsRefreshKey = 0;
  String? _mosqueChildrenSubscribedForMosqueId;
  String? _prayerTimingsLoadedForMosqueId;

  List<MosqueMemberModel>? _supervisors;
  bool _loadingSupervisors = false;
  List<MosqueJoinRequestModel>? _pendingRequests;
  bool _loadingPendingRequests = false;
  String? _removingUserId;
  String? _processingRequestId;
  List<Map<String, dynamic>> _absentStudents = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

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
    _animController.dispose();
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
        final lat = mosque?.lat;
        final lng = mosque?.lng;
        if (mosque != null && lat != null && lng != null && mosque.id != _prayerTimingsLoadedForMosqueId) {
          _prayerTimingsLoadedForMosqueId = mosque.id;
          sl<PrayerTimesService>().loadTimingsFor(lat, lng).then((_) {
            if (mounted) setState(() {});
          });
        }
        final nextPrayer = (lat != null && lng != null)
            ? sl<PrayerTimesService>().getNextPrayerOrNull(lat, lng)
            : null;
        if (mosque != null && _supervisors == null && !_loadingSupervisors) {
          _loadingSupervisors = true;
          final id = mosque.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadSupervisors(id);
          });
        }
        if (mosque != null &&
            _pendingRequests == null &&
            !_loadingPendingRequests) {
          _loadingPendingRequests = true;
          final id = mosque.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadPendingRequests(id);
          });
        }
        if (mosque != null &&
            mosque.id != _mosqueChildrenSubscribedForMosqueId) {
          _mosqueChildrenSubscribedForMosqueId = mosque.id;
          sl<RealtimeService>().unsubscribeMosqueChildren();
          sl<RealtimeService>().subscribeMosqueChildren(mosque.id, (_) {
            if (mounted) setState(() => _statsRefreshKey++);
          });
          // جلب الغائبين
          sl<MosqueRepository>().getAbsentStudents(mosque.id, days: 3).then((list) {
            if (mounted) setState(() => _absentStudents = list);
          });
        }

        final initialDataReady =
            mosque != null && _supervisors != null && _pendingRequests != null;

        if (initialDataReady && !_animController.isCompleted) {
          _animController.forward();
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF5F6FA),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                !initialDataReady
                    ? _buildLoadingState()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: _buildHeroSection(
                                  context,
                                  mosque!,
                                  nextPrayer,
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  24,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      _buildActionsGrid(
                                        context,
                                        mosque,
                                        nextPrayer,
                                      ),
                                      if (_absentStudents.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        _AbsenceAlerts(
                                            absentStudents: _absentStudents),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                const ImamProfileScreen(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3A5C), Color(0xFF2D6A9F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'جاري التحميل...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    MosqueModel mosque,
    dynamic nextPrayer,
  ) {
    final pendingCount = _pendingRequests?.length ?? 0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1B4F80), Color(0xFF2D7DD2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Row ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'لوحة مدير المسجد',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        mosque.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ─── Prayer Time Card ───
              _buildPrayerCard(nextPrayer),
              const SizedBox(height: 14),

              // ─── Info Row: كود المسجد | كود الدعوة | طلبات الانضمام ───
              Row(
                children: [
                  Expanded(
                    child: _buildHeroInfoChip(
                      icon: Icons.tag_rounded,
                      label: 'كود المسجد',
                      value: mosque.code,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: mosque.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ كود المسجد'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      trailingIcon: Icons.copy_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildHeroInfoChip(
                      icon: Icons.link_rounded,
                      label: 'كود الدعوة',
                      value: mosque.inviteCode,
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: mosque.inviteCode),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ كود الدعوة'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      trailingIcon: Icons.copy_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildHeroInfoChip(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'طلبات الانضمام',
                      value: pendingCount > 0 ? '$pendingCount طلب' : 'لا يوجد',
                      onTap: () => _showJoinRequestsSheet(context, mosque),
                      trailingIcon: pendingCount > 0 ? Icons.circle : null,
                      accentColor: pendingCount > 0
                          ? const Color(0xFFFFB74D)
                          : null,
                      hasBadge: pendingCount > 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(dynamic nextPrayer) {
    final nameAr = nextPrayer?.nameAr ?? '—';
    final timeFormatted = nextPrayer?.timeFormatted ?? '—';
    final remaining = nextPrayer?.remaining;
    final remainingMin = remaining?.inMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الصلاة القادمة',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$nameAr  $timeFormatted',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (remainingMin != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withOpacity(0.5),
                ),
              ),
              child: Text(
                'بعد ${remainingMin}د',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD54F),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    IconData? trailingIcon,
    Color? accentColor,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasBadge
                ? const Color(0xFFFFB74D).withOpacity(0.5)
                : Colors.white.withOpacity(0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: accentColor ?? Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accentColor ?? Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions Grid: 3 per row ───
  Widget _buildActionsGrid(
    BuildContext context,
    MosqueModel? mosque,
    dynamic nextPrayer,
  ) {
    if (mosque == null) return const SizedBox.shrink();

    final actions = [
      _ActionItem(
        icon: Icons.people_outline_rounded,
        title: 'المشرفون',
        color: const Color(0xFF5C8BFF),
        onTap: () => _showSupervisorsSheet(context, mosque),
      ),
      _ActionItem(
        icon: Icons.qr_code_scanner_rounded,
        title: 'التحضير',
        color: const Color(0xFF4CAF50),
        onTap: () => context.push('/supervisor/scan').then((_) {
          if (mounted) setState(() => _statsRefreshKey++);
        }),
      ),
      _ActionItem(
        icon: Icons.people_rounded,
        title: AppStrings.students,
        color: const Color(0xFFFF7043),
        onTap: () => context.push('/supervisor/students').then((_) {
          if (mounted) setState(() => _statsRefreshKey++);
        }),
      ),
      _ActionItem(
        icon: Icons.edit_note_rounded,
        title: 'طلب تصحيح',
        color: const Color(0xFF9C27B0),
        onTap: () => context.push('/imam/corrections/${mosque.id}'),
      ),
      _ActionItem(
        icon: Icons.note_alt_outlined,
        title: 'الملاحظات',
        color: const Color(0xFF00BCD4),
        onTap: () => context.push('/supervisor/notes/send/${mosque.id}'),
      ),
      _ActionItem(
        icon: Icons.campaign_rounded,
        title: 'الإعلانات',
        color: const Color(0xFF2E8B57),
        onTap: () => context.push('/imam/announcements/${mosque.id}'),
      ),
      _ActionItem(
        icon: Icons.emoji_events_rounded,
        title: 'المسابقات',
        color: const Color(0xFFFFB300),
        onTap: () => context.push('/imam/competitions/${mosque.id}'),
      ),
      _ActionItem(
        icon: Icons.star_rounded,
        title: 'نقاط الصلاة',
        color: const Color(0xFFE91E63),
        onTap: () => context.push(
          '/imam/mosque/${mosque.id}/prayer-points',
          extra: mosque.name,
        ),
      ),
      _ActionItem(
        icon: Icons.settings_rounded,
        title: 'إعدادات المسجد',
        color: const Color(0xFF607D8B),
        onTap: () =>
            context.push('/imam/mosque/${mosque.id}/settings', extra: mosque),
      ),
      _ActionItem(
        icon: Icons.bar_chart_rounded,
        title: 'تقرير الحضور',
        color: const Color(0xFF26A69A),
        onTap: () =>
            context.push('/imam/mosque/${mosque.id}/attendance-report'),
      ),
      _ActionItem(
        icon: Icons.workspace_premium_rounded,
        title: 'أداء المشرفين',
        color: const Color(0xFF7E57C2),
        onTap: () =>
            context.push('/imam/mosque/${mosque.id}/supervisors-performance'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 14),
          child: Text(
            'الإجراءات',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B3C),
              letterSpacing: -0.2,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, i) => _buildActionTile(context, actions[i]),
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, _ActionItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.13),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(height: 9),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B3C),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: const Color(0xFFB0B8C4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'لوحة المدير',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }

  // ─── Sheets ───
  void _showJoinRequestsSheet(BuildContext context, MosqueModel mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx,
        title: 'طلبات الانضمام',
        child: _buildPendingJoinRequestsContent(ctx, mosque),
      ),
    );
  }

  void _showSupervisorsSheet(BuildContext context, MosqueModel mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx,
        title: 'المشرفون',
        child: _buildSupervisorsContent(ctx, mosque),
      ),
    );
  }

  Widget _buildSheet(
    BuildContext ctx, {
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2137),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewPadding.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingJoinRequestsContent(
    BuildContext context,
    MosqueModel mosque,
  ) {
    if (_loadingPendingRequests)
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: Colors.white70,
            strokeWidth: 2,
          ),
        ),
      );
    final list = _pendingRequests ?? [];
    if (list.isEmpty) return _buildEmptySheet('لا توجد طلبات انضمام جديدة.');
    return Column(
      children: list.map((r) {
        final isProcessing = _processingRequestId == r.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white60,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.userName ?? r.userEmail ?? 'مستخدم',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (r.userEmail != null && r.userEmail!.isNotEmpty)
                        Text(
                          r.userEmail!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.55),
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
                  GestureDetector(
                    onTap: () => _approveJoinRequest(mosque, r),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF69F0AE),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _rejectJoinRequest(mosque, r),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFF5252),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSupervisorsContent(BuildContext context, MosqueModel mosque) {
    if (_loadingSupervisors)
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: Colors.white70,
            strokeWidth: 2,
          ),
        ),
      );
    final list = _supervisors ?? [];
    if (list.isEmpty)
      return _buildEmptySheet('لا يوجد مشرفون بعد. شارك كود الدعوة لدعوتهم.');
    return Column(
      children: list.map((m) {
        final isRemoving = _removingUserId == m.userId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white60,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.userName ?? m.userEmail ?? 'مشرف',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (m.userEmail != null && m.userEmail!.isNotEmpty)
                        Text(
                          m.userEmail!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.55),
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: isRemoving ? null : () => _removeSupervisor(mosque, m),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isRemoving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          )
                        : const Icon(
                            Icons.person_remove_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptySheet(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
        ),
      ),
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
}

// ─── Absence Alerts ───
class _AbsenceAlerts extends StatelessWidget {
  final List<Map<String, dynamic>> absentStudents;
  const _AbsenceAlerts({required this.absentStudents});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF7043).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFF7043), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تنبيهات الغياب',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                    Text(
                      '${absentStudents.length} طالب بدون حضور 3 أيام',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...absentStudents.take(5).map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7043).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      (s['name'] as String).isNotEmpty
                          ? (s['name'] as String)[0]
                          : '؟',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF7043),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s['name'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ),
              ],
            ),
          )),
          if (absentStudents.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'و ${absentStudents.length - 5} طالب آخر...',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Data class ───
class _ActionItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}
