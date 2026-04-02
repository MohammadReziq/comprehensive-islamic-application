import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_storage_keys.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_dashboard_widgets.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/mosque_model.dart';
import '../../../../models/other_models.dart';
import '../../../mosque/data/repositories/mosque_repository.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_event.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';
import 'imam_profile_screen.dart';
import '../widgets/create_supervisor_dialog.dart';
import '../widgets/imam_hero_section.dart';
import '../widgets/imam_actions_grid.dart';
import '../widgets/imam_supervisors_sheet.dart';
import '../../../../core/constants/app_enums.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(AppStorageKeys.imamOnboardingSeen) ?? false;
      if (!seen && mounted) {
        context.go('/imam/onboarding');
        return;
      }
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

  // ── Data loaders ────────────────────────────────────────────

  Future<void> _loadSupervisors(String mosqueId) async {
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

  Future<void> _loadPendingRequests(String mosqueId) async {
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

  // ── Actions ─────────────────────────────────────────────────

  Future<void> _removeSupervisor(
    MosqueModel mosque,
    MosqueMemberModel member,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة مشرف'),
        content: Text(
          'هل تريد إزالة "${member.userName ?? member.userEmail ?? 'المشرف'}" من مسجد ${mosque.name}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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

  // ── Sheet helpers ────────────────────────────────────────────

  void _showSupervisorsSheet(MosqueModel mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImamSupervisorsSheet(
        mosque: mosque,
        supervisors: _supervisors,
        isLoading: _loadingSupervisors,
        removingUserId: _removingUserId,
        onRemove: (m) => _removeSupervisor(mosque, m),
        onAddNew: () async {
          Navigator.pop(context);
          final result = await showDialog<bool>(
            context: context,
            builder: (_) => CreateSupervisorDialog(
              mosqueId: mosque.id,
              mosqueName: mosque.name,
            ),
          );
          if (mounted) {
            setState(() {
              _supervisors = null;
              _loadingSupervisors = false;
            });
            _loadSupervisors(mosque.id);
            if (result == true) {
              await Future.delayed(const Duration(milliseconds: 800));
              if (mounted) _showSupervisorsSheet(mosque);
            }
          }
        },
      ),
    );
  }

  void _showJoinRequestsSheet(MosqueModel mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImamJoinRequestsSheet(
        requests: _pendingRequests,
        isLoading: _loadingPendingRequests,
        processingRequestId: _processingRequestId,
        onApprove: (r) => _approveJoinRequest(mosque, r),
        onReject: (r) => _rejectJoinRequest(mosque, r),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────

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
        if (mosque != null &&
            lat != null &&
            lng != null &&
            mosque.id != _prayerTimingsLoadedForMosqueId) {
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
          sl<MosqueRepository>().getAbsentStudents(mosque.id, days: 3).then((
            list,
          ) {
            if (mounted) setState(() => _absentStudents = list);
          });
        }

        final dataReady =
            mosque != null && _supervisors != null && _pendingRequests != null;
        if (dataReady && !_animController.isCompleted) {
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
                !dataReady
                    ? _buildLoadingState()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: ImamHeroSection(
                                  mosque: mosque!,
                                  nextPrayer: nextPrayer,
                                  pendingCount: _pendingRequests?.length ?? 0,
                                  onJoinRequestsTap: () =>
                                      _showJoinRequestsSheet(mosque!),
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
                                      ImamActionsGrid(
                                        mosque: mosque,
                                        nextPrayer: nextPrayer,
                                        onSupervisorsTap: () =>
                                            _showSupervisorsSheet(mosque!),
                                        onStatsRefresh: () =>
                                            setState(() => _statsRefreshKey++),
                                        router: (route, {Object? extra}) =>
                                            context
                                                .push(route, extra: extra)
                                                .then((_) {
                                                  if (mounted)
                                                    setState(
                                                      () => _statsRefreshKey++,
                                                    );
                                                }),
                                      ),
                                      if (_absentStudents.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        DashboardAbsenceAlerts(
                                          absentStudents: _absentStudents,
                                        ),
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
            bottomNavigationBar: DashboardBottomNav(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              dashboardLabel: 'لوحة المدير',
            ),
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
}
