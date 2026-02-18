import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/mosque_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_event.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/repositories/supervisor_repository.dart';

/// لوحة المشرف — ملخص اليوم + التحضير والطلاب والتصحيحات والملاحظات
class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  /// يُستعمل لإعادة جلب أرقام طلاب المسجد وحضور اليوم عند العودة من التحضير/الطلاب أو عند حدث Realtime
  int _statsRefreshKey = 0;
  /// مسجد اللي صار عليه اشتراك Realtime لـ mosque_children (حتى لا نكرر الاشتراك)
  String? _mosqueChildrenSubscribedForMosqueId;

  @override
  void initState() {
    super.initState();
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
    sl<RealtimeService>().unsubscribeMosqueChildren();
    _mosqueChildrenSubscribedForMosqueId = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = sl<PrayerTimesService>().getNextPrayer();
    final approvedMosque = _getApprovedMosque(context);
    final isSupervisor = _isSupervisor(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(
          title: AppStrings.supervisorDashboardTitle,
          subtitle: 'مشرف',
          items: [
            AppDrawerItem(
              title: 'لوحة المشرف',
              icon: Icons.dashboard,
              onTap: () => context.go('/supervisor/dashboard'),
            ),
            AppDrawerItem(
              title: 'التحضير',
              icon: Icons.qr_code_scanner,
              onTap: () => context.push('/supervisor/scan'),
            ),
            AppDrawerItem(
              title: AppStrings.students,
              icon: Icons.people,
              onTap: () => context.push('/supervisor/students'),
            ),
            AppDrawerItem(
              title: AppStrings.correctionRequest,
              icon: Icons.edit_note,
              onTap: () {
                if (approvedMosque != null) {
                  context.push('/supervisor/corrections/${approvedMosque!.id}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('حدد المسجد أولاً')),
                  );
                }
              },
            ),
            AppDrawerItem(
              title: 'الملاحظات',
              icon: Icons.note_alt_outlined,
              onTap: () {
                if (approvedMosque != null) {
                  context.push('/supervisor/notes/send/${approvedMosque!.id}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('حدد المسجد أولاً')),
                  );
                }
              },
            ),
            AppDrawerItem(
              title: 'المسابقات',
              icon: Icons.emoji_events,
              onTap: () {
                if (approvedMosque != null) {
                  context.push('/supervisor/competitions/${approvedMosque!.id}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('حدد المسجد أولاً')),
                  );
                }
              },
            ),
            AppDrawerItem(
              title: 'انضم لمسجد',
              icon: Icons.add,
              onTap: () => context.push('/mosque/join').then((_) {
                if (mounted) setState(() => _statsRefreshKey++);
              }),
            ),
          ],
          onLogout: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
        ),
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
            child: BlocListener<MosqueBloc, MosqueState>(
              listener: (context, state) {
                if (!isSupervisor) return;
                if (state is MosqueLoaded && state.mosques.isEmpty) {
                  if (context.mounted) context.go('/mosque');
                  return;
                }
                if (state is MosqueLoaded && state.mosques.isNotEmpty) {
                  try {
                    final approved = state.mosques
                        .firstWhere((m) => m.status == MosqueStatus.approved);
                    if (approved.id != _mosqueChildrenSubscribedForMosqueId) {
                      sl<RealtimeService>().unsubscribeMosqueChildren();
                      sl<RealtimeService>().subscribeMosqueChildren(
                        approved.id,
                        (_) {
                          if (mounted) setState(() => _statsRefreshKey++);
                        },
                      );
                      _mosqueChildrenSubscribedForMosqueId = approved.id;
                    }
                  } catch (_) {}
                }
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAppBar(context),
                          const SizedBox(height: AppDimensions.paddingXL),
                          if (approvedMosque == null && isSupervisor)
                            _buildJoinMosqueCard(context),
                          if (approvedMosque != null) ...[
                            _buildMosqueCard(context, approvedMosque),
                            _buildJoinAnotherMosqueLink(context),
                          ],
                          const SizedBox(height: AppDimensions.paddingMD),
                          _buildNextPrayerCard(nextPrayer),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildSectionTitle(AppStrings.todayAttendance),
                          const SizedBox(height: AppDimensions.paddingSM),
                          _buildStatsRow(context, approvedMosque),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildSectionTitle('الإجراءات'),
                          const SizedBox(height: AppDimensions.paddingMD),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildActionCard(
                          context,
                          icon: Icons.qr_code_scanner,
                          title: 'التحضير',
                          subtitle: 'مسح QR أو إدخال رقم الطالب',
                          onTap: () => context.push('/supervisor/scan').then((_) {
                            if (mounted) setState(() => _statsRefreshKey++);
                          }),
                        ),
                        const SizedBox(height: AppDimensions.paddingSM),
                        _buildActionCard(
                          context,
                          icon: Icons.people,
                          title: AppStrings.students,
                          subtitle: 'قائمة طلاب المسجد',
                          onTap: () => context.push('/supervisor/students').then((_) {
                            if (mounted) setState(() => _statsRefreshKey++);
                          }),
                        ),
                        const SizedBox(height: AppDimensions.paddingSM),
                        _buildActionCard(
                          context,
                          icon: Icons.edit_note,
                          title: AppStrings.correctionRequest,
                          subtitle: 'طلبات التصحيح من أولياء الأمور',
                          onTap: () {
                            if (approvedMosque != null) {
                              context.push('/supervisor/corrections/${approvedMosque!.id}').then((_) {
                                if (mounted) setState(() => _statsRefreshKey++);
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('حدد المسجد أولاً')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingSM),
                        _buildActionCard(
                          context,
                          icon: Icons.note_alt_outlined,
                          title: 'الملاحظات',
                          subtitle: 'ملاحظات للطلاب',
                          onTap: () {
                            if (approvedMosque != null) {
                              context.push('/supervisor/notes/send/${approvedMosque!.id}');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('حدد المسجد أولاً')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingSM),
                        _buildActionCard(
                          context,
                          icon: Icons.emoji_events,
                          title: 'المسابقات',
                          subtitle: 'المسابقة النشطة والترتيب',
                          onTap: () {
                            if (approvedMosque != null) {
                              context.push('/supervisor/competitions/${approvedMosque!.id}').then((_) {
                                if (mounted) setState(() => _statsRefreshKey++);
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('حدد المسجد أولاً')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingXXL),
                      ]),
                    ),
                  ),
                ],
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
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'لوحة المشرف'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف الشخصي'),
          ],
        ),
      ),
    );
  }

  bool _isSupervisor(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated &&
        authState.userProfile?.role == UserRole.supervisor;
  }

  Widget _buildJoinMosqueCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
      child: Material(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: InkWell(
          onTap: () => context.push('/mosque/join'),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            child: Row(
              children: [
                Icon(Icons.group_add, color: Colors.white, size: 40),
                const SizedBox(width: AppDimensions.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'انضم لمسجد',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'أدخل كود الدعوة الذي أعطاك إياه مدير المسجد',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinAnotherMosqueLink(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.paddingSM),
      child: TextButton.icon(
        onPressed: () => context.push('/mosque/join'),
        icon: const Icon(Icons.add, color: Colors.white70, size: 20),
        label: Text(
          'انضم لمسجد آخر (كود الدعوة)',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.95)),
        ),
      ),
    );
  }

  MosqueModel? _getApprovedMosque(BuildContext context) {
    final state = context.read<MosqueBloc>().state;
    if (state is MosqueLoaded) {
      try {
        return state.mosques.firstWhere((m) => m.status == MosqueStatus.approved);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Text(
          AppStrings.supervisorDashboardTitle,
          style: const TextStyle(
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
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
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
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

  Widget _buildNextPrayerCard(PrayerInfo? nextPrayer) {
    final nameAr = nextPrayer?.nameAr ?? '—';
    final timeFormatted = nextPrayer?.timeFormatted ?? '—';
    final remaining = nextPrayer?.remaining;
    final remainingStr = remaining != null
        ? '${remaining.inMinutes} د'
        : '';

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

  Widget _buildStatsRow(BuildContext context, MosqueModel? approvedMosque) {
    if (approvedMosque == null) {
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
        repo.getTodayAttendanceCount(approvedMosque.id),
        repo.getMosqueStudents(approvedMosque.id),
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
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMD, horizontal: AppDimensions.paddingSM),
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
