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
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_event.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';
import '../../data/repositories/supervisor_repository.dart';

/// لوحة المشرف — نفس تصميم الإمام بصلاحيات المشرف فقط
class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _statsRefreshKey = 0;
  String? _mosqueChildrenSubscribedForMosqueId;
  String? _prayerTimingsLoadedForMosqueId;
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
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    sl<RealtimeService>().unsubscribeMosqueChildren();
    _mosqueChildrenSubscribedForMosqueId = null;
    super.dispose();
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

        // Realtime subscription
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

        if (mosque != null && !_animController.isCompleted) {
          _animController.forward();
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                mosque == null
                    ? _buildNoMosqueState(context, state)
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: _buildHeroSection(
                                  context,
                                  mosque,
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
                const ProfileScreen(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(),
          ),
        );
      },
    );
  }

  // ─── No Mosque ───
  Widget _buildNoMosqueState(BuildContext context, MosqueState state) {
    final isLoading = state is MosqueLoading;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1B4F80), Color(0xFF2D7DD2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'لوحة المشرف',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.read<AuthBloc>().add(
                            const AuthLogoutRequested(),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/mosque/join').then((_) {
                        if (mounted) {
                          context.read<MosqueBloc>().add(
                            const MosqueLoadMyMosques(),
                          );
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.group_add_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'انضم لمسجد',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أدخل كود الدعوة الذي أعطاك إياه مدير المسجد',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'انضم الآن',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B4F80),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── Hero Section ───
  Widget _buildHeroSection(
    BuildContext context,
    MosqueModel mosque,
    dynamic nextPrayer,
  ) {
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'لوحة المشرف',
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
                  Row(
                    children: [
                      // زر انضم لمسجد آخر
                      GestureDetector(
                        onTap: () => context.push('/mosque/join').then((_) {
                          if (mounted) {
                            context.read<MosqueBloc>().add(
                              const MosqueLoadMyMosques(),
                            );
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.mosque_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Prayer Card
              _buildPrayerCard(nextPrayer),
              const SizedBox(height: 14),

              // Info Row: كود المسجد + إحصائيات
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: _buildStatsChips(mosque)),
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

  Widget _buildStatsChips(MosqueModel mosque) {
    final repo = sl<SupervisorRepository>();
    return FutureBuilder<List<dynamic>>(
      key: ValueKey(_statsRefreshKey),
      future: Future.wait([
        repo.getTodayAttendanceCount(mosque.id),
        repo.getMosqueStudents(mosque.id),
      ]),
      builder: (context, snapshot) {
        final todayCount = snapshot.hasData
            ? (snapshot.data![0] as int).toString()
            : '—';
        final studentsCount = snapshot.hasData
            ? (snapshot.data![1] as List).length.toString()
            : '—';
        return Row(
          children: [
            Expanded(
              child: _buildStatMini(
                'حضور اليوم',
                todayCount,
                Icons.how_to_reg_rounded,
                const Color(0xFF69F0AE),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatMini(
                'الطلاب',
                studentsCount,
                Icons.people_rounded,
                const Color(0xFF82B1FF),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatMini(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions Grid: 3 per row — صلاحيات المشرف فقط ───
  Widget _buildActionsGrid(
    BuildContext context,
    MosqueModel? mosque,
    dynamic nextPrayer,
  ) {
    if (mosque == null) return const SizedBox.shrink();

    final actions = [
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
        title: 'طلبات التصحيح',
        color: const Color(0xFF9C27B0),
        onTap: () =>
            context.push('/supervisor/corrections/${mosque.id}').then((_) {
              if (mounted) setState(() => _statsRefreshKey++);
            }),
      ),
      _ActionItem(
        icon: Icons.note_alt_outlined,
        title: 'الملاحظات',
        color: const Color(0xFF00BCD4),
        onTap: () => context.push('/supervisor/notes/send/${mosque.id}'),
      ),

      _ActionItem(
        icon: Icons.add_home_work_rounded,
        title: 'انضم لمسجد',
        color: const Color(0xFF5C8BFF),
        onTap: () => context.push('/mosque/join').then((_) {
          if (mounted) {
            context.read<MosqueBloc>().add(const MosqueLoadMyMosques());
            setState(() => _statsRefreshKey++);
          }
        }),
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
      child: Container(
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
            label: 'لوحة المشرف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
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
