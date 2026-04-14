import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/attendance_model.dart';
import '../../../../models/competition_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../screens/child_notes_screen.dart';

import '../../data/repositories/child_repository.dart';
import '../../../notes/data/repositories/notes_repository.dart';
import '../../../competitions/data/repositories/competition_repository.dart';
import '../widgets/child_view_hero.dart';
import '../widgets/child_view_prayer_card.dart';
import '../widgets/child_stats_row.dart';
import '../widgets/child_view_qr_card.dart';
import '../widgets/child_view_today_attendance.dart';
import '../widgets/child_view_info_cards.dart';

/// شاشة الابن (دور child) — تصميم محسّن مع أنيميشن متتابعة
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
          content: Row(
            children: [
              const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                points > 0 ? 'تم تسجيل حضورك! +$points نقطة 🎉' : 'تم تسجيل حضورك!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
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
                          child: RefreshIndicator(
                            onRefresh: () async {
                              _animController.reset();
                              await _load();
                            },
                            color: const Color(0xFF1B5E8A),
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: SafeArea(
                                    bottom: false,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // زر الرسائل مع badge
                                          GestureDetector(
                                            onTap: () async {
                                              await Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => ChildNotesScreen(
                                                  childId: _child!.id,
                                                  childName: _child!.name,
                                                ),
                                              ));
                                              _loadUnreadNotes(_child!.id);
                                            },
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Container(
                                                  width: 40, height: 40,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF1B5E8A).withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(Icons.mail_rounded, color: Color(0xFF1B5E8A), size: 20),
                                                ),
                                                if (_unreadNotesCount > 0)
                                                  Positioned(
                                                    top: -4, left: -4,
                                                    child: Container(
                                                      width: 20, height: 20,
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                                                        ),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: const Color(0xFFF5F6FA), width: 2),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '$_unreadNotesCount',
                                                          style: const TextStyle(
                                                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // زر تسجيل الخروج
                                          GestureDetector(
                                            onTap: () => _showLogoutDialog(context),
                                            child: Container(
                                              width: 40, height: 40,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF5350).withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.logout_rounded, color: Color(0xFFEF5350), size: 20),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                                  sliver: SliverToBoxAdapter(
                                    child: Column(
                                      children: [
                                        // بطاقة الصلاة القادمة
                                        _buildAnimatedSection(
                                          delay: 200,
                                          child: const ChildViewPrayerCard(),
                                        ),
                                        
                                        const SizedBox(height: 10),
                                        // بطاقة QR (بطاقتي) — في المنتصف بارزة
                                        _buildAnimatedSection(
                                          delay: 100,
                                          child: ChildViewQrCard(child: _child!),
                                        ),
                                        
                                        const SizedBox(height: 10),
                                        // حضور اليوم
                                        _buildAnimatedSection(
                                          delay: 300,
                                          child: ChildViewTodayAttendance(todayAttendance: _todayAttendance),
                                        ),
                                        // مسابقات نشطة (إن وجدت)
                                        if (_activeCompetitions.isNotEmpty) ...[
                                          const SizedBox(height: 20),
                                          _buildAnimatedSection(
                                            delay: 400,
                                            child: ChildViewInfoCards(
                                              child: _child!,
                                              activeCompetitions: _activeCompetitions,
                                            ),
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
                      ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFEF5350), size: 24),
              SizedBox(width: 10),
              Text('تسجيل الخروج', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text('هل تريد تسجيل الخروج من حسابك؟',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('خروج', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// قسم متحرك مع تأخر
  Widget _buildAnimatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      builder: (context, value, widget) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: widget,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildLoadingState() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      colors: [Color(0xFF0A1628), Color(0xFF132D5A), Color(0xFF1B5E8A), Color(0xFF1E7A5F)],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      stops: [0.0, 0.35, 0.7, 1.0],
    )),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildErrorState() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      colors: [Color(0xFF0A1628), Color(0xFF132D5A), Color(0xFF1B5E8A), Color(0xFF1E7A5F)],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      stops: [0.0, 0.35, 0.7, 1.0],
    )),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0A1628),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
