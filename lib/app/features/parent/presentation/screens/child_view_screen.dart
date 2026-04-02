import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../../../../models/competition_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';


import '../../data/repositories/child_repository.dart';
import '../../../notes/data/repositories/notes_repository.dart';
import '../../../competitions/data/repositories/competition_repository.dart';
import '../widgets/child_view_hero.dart';
import '../widgets/child_stats_row.dart';
import '../widgets/child_view_qr_card.dart';
import '../widgets/child_view_today_attendance.dart';
import '../widgets/child_view_info_cards.dart';

/// شاشة الابن (دور child)
class ChildViewScreen extends StatefulWidget {
  const ChildViewScreen({super.key});

  @override
  State<ChildViewScreen> createState() => _ChildViewScreenState();
}

class _ChildViewScreenState extends State<ChildViewScreen>
    with SingleTickerProviderStateMixin {
  ChildModel? _child;
  List<AttendanceModel> _todayAttendance = [];
  bool _loading = true;
  String? _error;
  int _unreadNotesCount = 0;
  List<CompetitionModel> _activeCompetitions = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    sl<RealtimeService>().unsubscribeAttendance();
    super.dispose();
  }

  void _subscribeRealtime() {
    if (_child == null) return;
    sl<RealtimeService>().subscribeAttendanceForChildIds([_child!.id], (payload) {
      if (!mounted) return;
      _reloadAttendanceWithCelebration(payload);
    });
  }

  Future<void> _reloadAttendanceWithCelebration(PostgresChangePayload payload) async {
    final updated = await sl<ChildRepository>().getAttendanceForChildOnDate(_child!.id, DateTime.now());
    if (!mounted) return;
    setState(() => _todayAttendance = updated);
    if (payload.eventType == PostgresChangeEvent.insert) {
      final points = (payload.newRecord['points_earned'] as num?)?.toInt() ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(points > 0 ? 'تم تسجيل حضورك! +$points نقطة 🎉' : 'تم تسجيل حضورك!'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await sl<AuthRepository>().getCurrentUserProfile();
      if (user == null) { setState(() { _error = 'لم يتم العثور على الجلسة'; _loading = false; }); return; }
      final child = await sl<ChildRepository>().getChildByLoginUserId(user.id);
      if (child == null) { setState(() { _error = 'لا يوجد ابن مرتبط بهذا الحساب'; _loading = false; }); return; }
      final today = await sl<ChildRepository>().getAttendanceForChildOnDate(child.id, DateTime.now());
      if (mounted) {
        setState(() { _child = child; _todayAttendance = today; _loading = false; });
        _animController.forward();
        _subscribeRealtime();
        _loadUnreadNotes(child.id);
        _loadCompetitions(child.id);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _loadUnreadNotes(String childId) async {
    try {
      final notes = await sl<NotesRepository>().getNotesForChild(childId);
      if (mounted) setState(() => _unreadNotesCount = notes.where((n) => !n.isRead).length);
    } catch (_) {}
  }

  Future<void> _loadCompetitions(String childId) async {
    try {
      final mosqueIds = await sl<ChildRepository>().getChildMosqueIds(childId);
      if (mosqueIds.isEmpty) return;
      final comps = await sl<CompetitionRepository>().getActiveForMosques(mosqueIds);
      if (mounted) setState(() => _activeCompetitions = comps);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: _loading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : _child == null
                    ? const SizedBox.shrink()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(child: ChildViewHero(child: _child!)),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      ChildStatsRow(child: _child!),
                                      const SizedBox(height: 16),
                                      ChildViewQrCard(child: _child!),
                                      const SizedBox(height: 16),
                                      ChildViewInfoCards(
                                        child: _child!,
                                        unreadNotesCount: _unreadNotesCount,
                                        activeCompetitions: _activeCompetitions,
                                        onNotesViewed: () => _loadUnreadNotes(_child!.id),
                                      ),
                                      const SizedBox(height: 16),
                                      ChildViewTodayAttendance(todayAttendance: _todayAttendance),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildLoadingState() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      colors: [Color(0xFF0D2137), Color(0xFF1B5E8A), Color(0xFF2E8B57)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    )),
    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
  );

  Widget _buildErrorState() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      colors: [Color(0xFF0D2137), Color(0xFF1B5E8A), Color(0xFF2E8B57)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    )),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 56),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0D2137)),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    ),
  );
}
