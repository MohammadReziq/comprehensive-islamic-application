import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/repositories/child_repository.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';

/// 📁 lib/app/features/parent/presentation/screens/home_screen.dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  List<AttendanceModel> _todayAttendance = [];
  bool _loadingAttendance = false;

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
      if (mounted) context.read<ChildrenBloc>().add(const ChildrenLoad());
    });
    sl<PrayerTimesService>()
        .loadTimingsFor(PrayerTimesService.defaultLat, PrayerTimesService.defaultLng)
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayAttendance(List<ChildModel> children) async {
    if (children.isEmpty) return;
    setState(() => _loadingAttendance = true);
    try {
      final list = await sl<ChildRepository>().getAttendanceForMyChildren(
        DateTime.now(),
      );
      if (mounted) setState(() => _todayAttendance = list);
    } catch (_) {}
    if (mounted) setState(() => _loadingAttendance = false);
  }

  String _getUserName(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) return auth.userProfile?.name ?? 'ولي الأمر';
    return 'ولي الأمر';
  }

  void _showCredentialsDialog(
    BuildContext context,
    String email,
    String password,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.key_rounded, color: Color(0xFF2E8B57)),
              SizedBox(width: 8),
              Text(
                'بيانات دخول الابن',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'احتفظ بهذه البيانات — لن تظهر مرة أخرى',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _credRow('الإيميل', email),
              const SizedBox(height: 10),
              _credRow('كلمة المرور', password),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<ChildrenBloc>().add(
                  const ChildrenCredentialsShown(),
                );
              },
              child: const Text('فهمت، أغلق'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _credRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = sl<PrayerTimesService>().getNextPrayer(
      PrayerTimesService.defaultLat,
      PrayerTimesService.defaultLng,
    );

    return BlocConsumer<ChildrenBloc, ChildrenState>(
      listener: (context, state) {
        if (state is ChildrenLoaded) {
          _loadTodayAttendance(state.children);
          if (!_animController.isCompleted) _animController.forward();
        }
        if (state is ChildrenLoadedWithCredentials) {
          _loadTodayAttendance(state.children);
          if (!_animController.isCompleted) _animController.forward();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
              _showCredentialsDialog(context, state.email, state.password);
          });
        }
      },
      builder: (context, state) {
        final children = state is ChildrenLoaded
            ? state.children
            : state is ChildrenLoadedWithCredentials
            ? state.children
            : <ChildModel>[];
        final isLoading = state is ChildrenLoading || state is ChildrenInitial;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                isLoading
                    ? _buildLoadingState()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: _buildHero(
                                  context,
                                  children,
                                  nextPrayer,
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  32,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      _buildActionsGrid(context, children),
                                      const SizedBox(height: 20),
                                      _buildTodaySection(context, children),
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

  // ─── Loading ───
  Widget _buildLoadingState() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0D2137), Color(0xFF1B5E8A), Color(0xFF2E8B57)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
  );

  // ─── Hero Section ───
  Widget _buildHero(
    BuildContext context,
    List<ChildModel> children,
    dynamic nextPrayer,
  ) {
    final name = _getUserName(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1B5E8A), Color(0xFF2E8B57)],
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
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أهلاً، $name',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'ولي الأمر',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.mosque_rounded,
                      size: 42,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Prayer Card
              _buildPrayerCard(nextPrayer),
              const SizedBox(height: 14),

              // Stats Row: أبنائي | حضور اليوم
              Row(
                children: [
                  Expanded(
                    child: _buildHeroChip(
                      icon: Icons.child_care_rounded,
                      label: 'أبنائي',
                      value: '${children.length} أبناء',
                      onTap: () => context.push('/parent/children'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildHeroChip(
                      icon: Icons.how_to_reg_rounded,
                      label: 'حضور اليوم',
                      value: _loadingAttendance
                          ? '...'
                          : '${_todayAttendance.length} صلاة',
                      accentColor: _todayAttendance.isNotEmpty
                          ? const Color(0xFF69F0AE)
                          : null,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildHeroChip(
                      icon: Icons.notifications_rounded,
                      label: 'الملاحظات',
                      value: 'عرض',
                      onTap: () => context.push('/parent/notes'),
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

  Widget _buildHeroChip({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                Icon(
                  icon,
                  size: 13,
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
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions Grid 3×N ───
  Widget _buildActionsGrid(BuildContext context, List<ChildModel> children) {
    final actions = [
      _Action(
        Icons.child_care_rounded,
        'أبنائي',
        const Color(0xFF5C8BFF),
        () => context.push('/parent/children'),
      ),
      _Action(
        Icons.person_add_rounded,
        'إضافة ابن',
        const Color(0xFF4CAF50),
        () => context.push('/parent/children/add'),
      ),
      _Action(
        Icons.edit_note_rounded,
        'طلب تصحيح',
        const Color(0xFF9C27B0),
        () => context.push('/parent/corrections'),
      ),
      _Action(
        Icons.inbox_rounded,
        'ملاحظات المشرف',
        const Color(0xFF00BCD4),
        () => context.push('/parent/notes'),
      ),
      _Action(
        Icons.history_rounded,
        'طلباتي',
        const Color(0xFFFF7043),
        () => context.push('/parent/corrections'),
      ),
      _Action(Icons.qr_code_rounded, 'بطاقة ابن', const Color(0xFFFFB300), () {
        if (children.isNotEmpty) {
          context.push('/parent/children/${children.first.id}/card');
        } else {
          context.push('/parent/children');
        }
      }),
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
          itemBuilder: (context, i) => _buildTile(actions[i]),
        ),
      ],
    );
  }

  Widget _buildTile(_Action a) {
    return GestureDetector(
      onTap: a.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: a.color.withOpacity(0.13),
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
                color: a.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(a.icon, color: a.color, size: 26),
            ),
            const SizedBox(height: 9),
            Text(
              a.label,
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

  // ─── Today Attendance Section ───
  Widget _buildTodaySection(BuildContext context, List<ChildModel> children) {
    if (children.isEmpty) {
      return _buildEmptyChildren(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'حضور اليوم',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2B3C),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/parent/children'),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_loadingAttendance)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_todayAttendance.isEmpty)
          _buildNoAttendanceCard()
        else
          ..._todayAttendance.map((a) => _buildAttendanceCard(a, children)),
      ],
    );
  }

  Widget _buildAttendanceCard(
    AttendanceModel attendance,
    List<ChildModel> children,
  ) {
    final child = children.firstWhere(
      (c) => c.id == attendance.childId,
      orElse: () => ChildModel(
        id: '',
        name: 'ابن',
        age: 0,
        parentId: '',
        qrCode: '',
        totalPoints: 0,
        currentStreak: 0,
        bestStreak: 0,
        createdAt: DateTime.now(),
      ),
    );

    final prayerNames = {
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
    };
    final prayerColors = {
      'fajr': const Color(0xFF5C8BFF),
      'dhuhr': const Color(0xFFFFB300),
      'asr': const Color(0xFF4CAF50),
      'maghrib': const Color(0xFFFF7043),
      'isha': const Color(0xFF9C27B0),
    };

    final prayerKey = attendance.prayer.value;
    final color = prayerColors[prayerKey] ?? AppColors.primary;
    final prayerAr = prayerNames[prayerKey] ?? attendance.prayer.nameAr;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                Text(
                  'صلاة $prayerAr · ${attendance.pointsEarned} نقطة',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'حاضر',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 40,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'لا يوجد حضور مسجل اليوم',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChildren(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/parent/children/add'),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.child_care_rounded,
                color: Color(0xFF4CAF50),
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'أضف ابنك الأول',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2B3C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'اضغط لإضافة ابن وربطه بمسجد',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'إضافة ابن',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Nav ───
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
            icon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
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

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.color, this.onTap);
}
