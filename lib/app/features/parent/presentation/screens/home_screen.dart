import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../injection_container.dart';
import '../../data/repositories/child_repository.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// الشاشة الرئيسية — ترحيب + حضور اليوم (دورة حياة الحضور) + أطفالي
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  List<ChildModel> _children = [];
  List<AttendanceModel> _todayAttendance = [];
  bool _loadingAttendance = true;

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  @override
  void dispose() {
    sl<RealtimeService>().unsubscribeAttendance();
    super.dispose();
  }

  Future<void> _loadTodayAttendance() async {
    setState(() => _loadingAttendance = true);
    try {
      final repo = sl<ChildRepository>();
      final children = await repo.getMyChildren();
      final attendance = await repo.getAttendanceForMyChildren(DateTime.now());
      if (mounted) {
        setState(() {
          _children = children;
          _todayAttendance = attendance;
          _loadingAttendance = false;
        });
        final realtime = sl<RealtimeService>();
        realtime.unsubscribeAttendance();
        final childIds = children.map((c) => c.id).toList();
        if (childIds.isNotEmpty) {
          realtime.subscribeAttendanceForChildIds(childIds, (_) {
            if (mounted) _loadTodayAttendance();
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAttendance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(
          title: 'صلاتي حياتي',
          subtitle: 'ولي أمر',
          items: [
            AppDrawerItem(
              title: 'الرئيسية',
              icon: Icons.home,
              onTap: () => context.go('/home'),
            ),
            AppDrawerItem(
              title: 'أطفالي',
              icon: Icons.people,
              onTap: () => context.push('/parent/children'),
            ),
            AppDrawerItem(
              title: 'ملاحظات المشرف',
              icon: Icons.mail_outline,
              onTap: () => context.push('/parent/notes'),
            ),
          ],
          onLogout: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.paddingSM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingSM),

                    // ─── ترحيب ───
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        String userName = 'مستخدم';
                        String userRole = '';
                        if (state is AuthAuthenticated &&
                            state.userProfile != null) {
                          userName = state.userProfile!.name;
                          userRole = state.userProfile!.role.nameAr;
                        }
                        return Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '👋',
                                  style: TextStyle(fontSize: 40),
                                ),
                              ),
                            ).animate().scale(
                              begin: const Offset(0.5, 0.5),
                              curve: Curves.elasticOut,
                              duration: 800.ms,
                            ),

                            const SizedBox(height: AppDimensions.spacingLG),

                            Text(
                              'مرحباً $userName',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textOnDark,
                              ),
                            ).animate().fadeIn(delay: 300.ms),

                            if (userRole.isNotEmpty) ...[
                              const SizedBox(height: AppDimensions.spacingXS),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingMD,
                                  vertical: AppDimensions.paddingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusRound,
                                  ),
                                ),
                                child: Text(
                                  userRole,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ).animate().fadeIn(delay: 500.ms),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppDimensions.paddingXL),

                    // ─── بطاقة النجاح ───
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingMD,
                        ),
                        padding: const EdgeInsets.all(AppDimensions.paddingLG),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppDimensions.radiusXL),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '✅',
                                      style: TextStyle(fontSize: 48),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .scale(
                                  begin: const Offset(0.5, 0.5),
                                  curve: Curves.elasticOut,
                                  duration: 800.ms,
                                ),

                            const SizedBox(height: AppDimensions.spacingXL),

                            const Text(
                              'تابع صلاة أطفالك',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 800.ms),

                            const SizedBox(height: AppDimensions.spacingMD),

                            Text(
                              'أضف أطفالك واربطهم بمسجدهم لترى حضورهم ونقاطهم.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 1000.ms),

                            const SizedBox(height: AppDimensions.paddingLG),

                            // ─── حضور اليوم (دورة حياة الحضور) ───
                            _buildTodayAttendanceSection(),

                            const Spacer(),

                            // ─── أطفالي ───
                            SizedBox(
                              width: double.infinity,
                              height: AppDimensions.buttonHeight,
                              child: FilledButton.icon(
                                onPressed: () =>
                                    context.push('/parent/children'),
                                icon: const Icon(Icons.child_care),
                                label: const Text(
                                  'أطفالي',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                              ),
                            ).animate().fadeIn(delay: 1100.ms),

                            const SizedBox(height: AppDimensions.paddingMD),

                            // ─── زر تسجيل الخروج ───
                            SizedBox(
                              width: double.infinity,
                              height: AppDimensions.buttonHeight,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.read<AuthBloc>().add(
                                    const AuthLogoutRequested(),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(
                                    color: AppColors.error,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMD,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.logout),
                                label: const Text(
                                  AppStrings.logout,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 1200.ms),

                            const SizedBox(height: AppDimensions.paddingLG),
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'الملف الشخصي',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAttendanceSection() {
    if (_loadingAttendance) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_children.isEmpty) {
      return Text(
        'أضف ابناً واربطه بمسجد لترى حضور اليوم هنا.',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      );
    }
    final byChild = <String, List<AttendanceModel>>{};
    for (final a in _todayAttendance) {
      byChild.putIfAbsent(a.childId, () => []).add(a);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.todayAttendance,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ..._children.map((c) {
          final list = byChild[c.id] ?? [];
          final prayers = list.map((a) => a.prayer.nameAr).join('، ');
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (list.isEmpty)
                  Text(
                    'لا حضور مسجّل اليوم',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Text(
                    prayers,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
