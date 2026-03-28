import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_storage_keys.dart';
import '../../../../core/constants/hadiths_prayer.dart';
import '../../../../core/widgets/shared_dashboard_widgets.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../../../../models/competition_model.dart';
import '../../../announcements/data/repositories/announcement_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../competitions/data/repositories/competition_repository.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';
import '../../../notes/data/repositories/notes_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'parent_profile_screen.dart';
import '../../data/repositories/child_repository.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/home_actions_grid.dart';
import '../widgets/home_today_section.dart';
import '../widgets/home_empty_children.dart';

/// الشاشة الرئيسية لولي الأمر
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
  double? _prayerLat;
  double? _prayerLng;
  bool _prayerLoadError = false;
  bool _loadingPrayer = true;
  CompetitionStatus _competitionStatus = CompetitionStatus.noCompetition;
  CompetitionModel? _competition;
  String? _competitionMosqueName;
  int _unreadCount = 0;
  int _announcementsUnreadCount = 0;
  Timer? _countdownTimer;
  int _hadithIndex = 0;
  Timer? _hadithTimer;
  bool _realtimeSubscribed = false;
  List<ChildModel> _latestChildren = [];

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
    _loadPrayerTimesWithLocation();
    _loadCompetitionStatus();
    _loadUnreadCount();
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
    _countdownTimer?.cancel();
    _hadithTimer?.cancel();
    _animController.dispose();
    sl<RealtimeService>().unsubscribeAttendance();
    sl<RealtimeService>().unsubscribeNotes();
    super.dispose();
  }

  // ─── Data Loading ───

  Future<void> _loadPrayerTimesWithLocation() async {
    setState(() { _loadingPrayer = true; _prayerLoadError = false; });
    double? lat, lng;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() { _prayerLat = null; _prayerLng = null; _loadingPrayer = false; });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 12),
            onTimeout: () => throw TimeoutException('تعذّر تحديد الموقع في الوقت المحدد'));
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) { lat = null; lng = null; }
    if (!mounted) return;
    setState(() { _prayerLat = lat; _prayerLng = lng; _loadingPrayer = false; });
    if (lat != null && lng != null) {
      final ok = await sl<PrayerTimesService>().loadTimingsFor(lat, lng);
      if (mounted) setState(() => _prayerLoadError = !ok);
    }
  }

  Future<void> _loadCompetitionStatus() async {
    try {
      final children = await sl<ChildRepository>().getMyChildren();
      final mosqueIds = <String>{};
      for (final c in children) {
        final ids = await sl<ChildRepository>().getChildMosqueIds(c.id);
        mosqueIds.addAll(ids);
      }
      if (mosqueIds.isEmpty) return;
      for (final mosqueId in mosqueIds) {
        final result = await sl<CompetitionRepository>().getCompetitionStatus(mosqueId);
        if (result.status != CompetitionStatus.noCompetition) {
          String? mosqueName;
          try {
            final mosques = await sl<MosqueRepository>().getMosquesByIds([mosqueId]);
            if (mosques.isNotEmpty) mosqueName = mosques.first.name;
          } catch (_) {}
          if (mounted) {
            setState(() {
              _competitionStatus = result.status;
              _competition = result.competition;
              _competitionMosqueName = mosqueName;
            });
          }
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadCount() async {
    try {
      final children = await sl<ChildRepository>().getMyChildren();
      final childIds = children.map((c) => c.id).toList();
      final notes = await sl<NotesRepository>().getNotesForMyChildren(childIds);
      final unreadNotes = notes.where((n) => !n.isRead).length;

      final mosqueIds = <String>{};
      for (final c in children) {
        final ids = await sl<ChildRepository>().getChildMosqueIds(c.id);
        mosqueIds.addAll(ids);
      }
      int unreadAnn = 0;
      if (mosqueIds.isNotEmpty) {
        final user = await sl<AuthRepository>().getCurrentUserProfile();
        if (user != null) {
          final anns = await sl<AnnouncementRepository>().getForParent(mosqueIds.toList());
          final readIds = await sl<AnnouncementRepository>().getReadIds(user.id);
          unreadAnn = anns.where((a) => !readIds.contains(a.id)).length;
        }
      }
      if (mounted) setState(() { _unreadCount = unreadNotes; _announcementsUnreadCount = unreadAnn; });
    } catch (_) {}
  }

  void _startRealtime(List<String> childIds) {
    _realtimeSubscribed = true;
    sl<RealtimeService>().subscribeAttendanceForChildIds(childIds, (_) {
      if (!mounted) return;
      _loadTodayAttendance(_latestChildren);
    });
    sl<RealtimeService>().subscribeNotesForChildren(childIds, (_) {
      if (!mounted) return;
      _loadUnreadCount();
    });
  }

  Future<void> _loadTodayAttendance(List<ChildModel> children) async {
    if (children.isEmpty) return;
    setState(() => _loadingAttendance = true);
    try {
      final list = await sl<ChildRepository>().getAttendanceForMyChildren(DateTime.now());
      if (mounted) setState(() => _todayAttendance = list);
    } catch (_) {}
    if (mounted) setState(() => _loadingAttendance = false);
  }

  String _getUserName(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) return auth.userProfile?.name ?? 'ولي الأمر';
    return 'ولي الأمر';
  }

  void _showCredentialsDialog(BuildContext context, String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.key_rounded, color: Color(0xFF2E8B57)),
              SizedBox(width: 8),
              Text('بيانات دخول الابن', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('احتفظ بهذه البيانات — لن تظهر مرة أخرى',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                context.read<ChildrenBloc>().add(const ChildrenCredentialsShown());
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
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم النسخ إلى الحافظة'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final hasLocation = _prayerLat != null && _prayerLng != null;
    final nextPrayer = hasLocation
        ? sl<PrayerTimesService>().getNextPrayerOrNull(_prayerLat!, _prayerLng!)
        : null;

    return BlocConsumer<ChildrenBloc, ChildrenState>(
      listener: (context, state) {
        if (state is ChildrenLoaded || state is ChildrenLoadedWithCredentials) {
          final children = state is ChildrenLoaded
              ? state.children
              : (state as ChildrenLoadedWithCredentials).children;
          _latestChildren = children;
          _loadTodayAttendance(children);
          if (!_animController.isCompleted) _animController.forward();
          if (!_realtimeSubscribed && children.isNotEmpty) {
            _startRealtime(children.map((c) => c.id).toList());
          }
          if (state is ChildrenLoadedWithCredentials) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showCredentialsDialog(context, state.email, state.password);
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

        final actions = _buildActions(context);

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
                                child: HomeHeroSection(
                                  nextPrayer: nextPrayer,
                                  lat: _prayerLat,
                                  lng: _prayerLng,
                                  loadingPrayer: _loadingPrayer,
                                  prayerLoadError: _prayerLoadError,
                                  hadithIndex: _hadithIndex,
                                  onRetryPrayer: _loadPrayerTimesWithLocation,
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
                                        _buildChildrenErrorBanner(context, state.message),
                                      ],
                                      HomeActionsGrid(
                                        actions: actions,
                                        competitionStatus: _competitionStatus,
                                        competition: _competition,
                                        competitionMosqueName: _competitionMosqueName,
                                      ),
                                      const SizedBox(height: 20),
                                      children.isEmpty
                                          ? const HomeEmptyChildren()
                                          : HomeTodaySection(
                                              children: children,
                                              todayAttendance: _todayAttendance,
                                              loadingAttendance: _loadingAttendance,
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
        if (mounted) { context.read<ChildrenBloc>().add(const ChildrenLoad()); _loadUnreadCount(); }
      }),
      if (_competitionStatus == CompetitionStatus.running)
        HomeAction(Icons.edit_note_rounded, 'طلب تصحيح', const Color(0xFF9C27B0), () async {
          await context.push('/parent/corrections');
          if (mounted) _loadUnreadCount();
        }),
      HomeAction(Icons.forum_rounded, 'الملاحظات', const Color(0xFF00BCD4), () async {
        await context.push('/parent/notes');
        _loadUnreadCount();
      }, badge: _unreadCount),
      HomeAction(Icons.campaign_rounded, 'الإعلانات', const Color(0xFFFF9800), () async {
        await context.push('/parent/announcements');
        _loadUnreadCount();
      }, badge: _announcementsUnreadCount),
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

  Widget _buildChildrenErrorBanner(BuildContext context, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('تعذّر تحميل بيانات الأبناء',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
          ),
          GestureDetector(
            onTap: () => context.read<ChildrenBloc>().add(const ChildrenLoad()),
            child: Text('إعادة المحاولة',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade600, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}
