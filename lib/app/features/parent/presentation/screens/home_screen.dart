import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_storage_keys.dart';
import '../../../../core/constants/hadiths_prayer.dart';
import '../../../../core/widgets/shared_dashboard_widgets.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/competition_model.dart';
import 'parent_profile_screen.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';
import '../helpers/home_data_helper.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/home_actions_grid.dart';
import '../widgets/home_today_section.dart';
import '../widgets/home_empty_children.dart';
import '../widgets/home_credentials_dialog.dart';
import '../widgets/home_error_banner.dart';

/// الشاشة الرئيسية لولي الأمر
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _hadithIndex = 0;
  Timer? _countdownTimer;
  Timer? _hadithTimer;
  String? _lastLoadDate;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final HomeDataHelper _helper = HomeDataHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastLoadDate = _todayStr();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(AppStorageKeys.parentOnboardingSeen) ?? false;
      if (!seen && mounted) {
        context.go('/parent/onboarding');
        return;
      }
      if (mounted) context.read<ChildrenBloc>().add(const ChildrenLoad());
    });
    
    _helper.loadAll();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _hadithIndex = Random().nextInt(HadithPrayer.list.length);
    _hadithTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _hadithIndex = (_hadithIndex + 1) % HadithPrayer.list.length);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _hadithTimer?.cancel();
    _animController.dispose();
    _helper.disposeHelper();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = _todayStr();
      if (today != _lastLoadDate) {
        _lastLoadDate = today;
        _helper.loadPrayerTimesWithLocation();
      }
    }
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChildrenBloc, ChildrenState>(
      listener: (context, state) {
        if (state is ChildrenLoaded || state is ChildrenLoadedWithCredentials) {
          final children = state is ChildrenLoaded
              ? state.children
              : (state as ChildrenLoadedWithCredentials).children;
          
          _helper.refreshChildren(children);
          
          if (!_animController.isCompleted) _animController.forward();
          if (state is ChildrenLoadedWithCredentials) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) HomeCredentialsDialog.show(context, state.email, state.password);
            });
          }
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
                          child: ListenableBuilder(
                            listenable: _helper,
                            builder: (context, _) {
                              final hasLocation = _helper.prayerLat != null && _helper.prayerLng != null;
                              final nextPrayer = hasLocation
                                  ? sl<PrayerTimesService>().getNextPrayerOrNull(_helper.prayerLat!, _helper.prayerLng!)
                                  : null;
                                  
                              final actions = _buildActions(context);
                              return CustomScrollView(
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: HomeHeroSection(
                                      nextPrayer: nextPrayer,
                                      lat: _helper.prayerLat,
                                      lng: _helper.prayerLng,
                                      loadingPrayer: _helper.loadingPrayer,
                                      prayerLoadError: _helper.prayerLoadError,
                                      hadithIndex: _hadithIndex,
                                      permissionStatus: _helper.permissionStatus,
                                      onRetryPrayer: _helper.requestLocationPermission,
                                      onNextHadith: () => setState(() {
                                        _hadithIndex = (_hadithIndex + 1) % HadithPrayer.list.length;
                                      }),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                    sliver: SliverToBoxAdapter(
                                      child: Column(
                                        children: [
                                          if (state is ChildrenError) ...[
                                            const SizedBox(height: 12),
                                            HomeErrorBanner(message: state.message),
                                          ],
                                          HomeActionsGrid(
                                            actions: actions,
                                            competitionStatus: _helper.competitionStatus,
                                            competition: _helper.competition,
                                            competitionMosqueName: _helper.competitionMosqueName,
                                          ),
                                          const SizedBox(height: 20),
                                          children.isEmpty
                                              ? const HomeEmptyChildren()
                                              : HomeTodaySection(
                                                  children: children,
                                                  todayAttendance: _helper.todayAttendance,
                                                  loadingAttendance: _helper.loadingAttendance,
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                      ),
                const ParentProfileScreen(),
              ],
            ),
            bottomNavigationBar: DashboardBottomNav(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              dashboardLabel: 'الرئيسية',
              dashboardIcon: Icons.home_rounded,
            ),
          ),
        );
      },
    );
  }

  List<HomeAction> _buildActions(BuildContext context) {
    return [
      HomeAction(Icons.child_care_rounded, 'أبنائي', const Color(0xFF5C8BFF), () async {
        await context.push('/parent/children');
        if (!context.mounted) return;
        context.read<ChildrenBloc>().add(const ChildrenLoad()); 
        _helper.loadUnreadCount(); 
      }),
      if (_helper.competitionStatus == CompetitionStatus.running)
        HomeAction(Icons.edit_note_rounded, 'طلب تصحيح', const Color(0xFF9C27B0), () async {
          await context.push('/parent/corrections');
          if (!context.mounted) return;
          _helper.loadUnreadCount();
        }),
      HomeAction(Icons.forum_rounded, 'الملاحظات', const Color(0xFF00BCD4), () async {
        await context.push('/parent/notes');
        if (!context.mounted) return;
        _helper.loadUnreadCount();
      }, badge: _helper.unreadCount),
      HomeAction(Icons.campaign_rounded, 'الإعلانات', const Color(0xFFFF9800), () async {
        await context.push('/parent/announcements');
        if (!context.mounted) return;
        _helper.loadUnreadCount();
      }, badge: _helper.announcementsUnreadCount),
    ];
  }

  Widget _buildLoadingState() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0D2137), Color(0xFF1B5E8A), Color(0xFF2E8B57)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
  );
}
