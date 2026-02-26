// lib/app/features/competitions/data/repositories/competition_repository.dart

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../models/competition_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class CompetitionRepository {
  CompetitionRepository(this._authRepo);

  final AuthRepository _authRepo;

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─────────────────────────────────────────────────────────
  // إمام: إنشاء مسابقة (غير نشطة تلقائياً)
  // ─────────────────────────────────────────────────────────

  Future<CompetitionModel> create({
    required String mosqueId,
    required String nameAr,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) throw const NotLoggedInFailure();

      // ── تحقق: فقط الإمام (owner) ينشئ مسابقات ──
      await _requireOwnerRole(mosqueId, user.id);

      final row = await supabase.from('competitions').insert({
        'mosque_id':   mosqueId,
        'name_ar':     nameAr,
        'start_date':  _dateStr(startDate),
        'end_date':    _dateStr(endDate),
        'is_active':   false,
        'created_by':  user.id,
      }).select().single();

      return CompetitionModel.fromJson(row);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // إمام: تفعيل مسابقة (عبر RPC تُوقف النشطة أولاً)
  // ─────────────────────────────────────────────────────────

  Future<void> activate(String competitionId) async {
    try {
      // جلب mosque_id من المسابقة والتحقق من صلاحية الإمام
      final comp = await supabase
          .from('competitions')
          .select('mosque_id')
          .eq('id', competitionId)
          .single();
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) throw const NotLoggedInFailure();
      await _requireOwnerRole(comp['mosque_id'] as String, user.id);

      await supabase.rpc(
        'activate_competition',
        params: {'p_competition_id': competitionId},
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // إمام: إيقاف مسابقة
  // ─────────────────────────────────────────────────────────

  Future<void> deactivate(String competitionId) async {
    try {
      // تحقق من صلاحية الإمام
      final comp = await supabase
          .from('competitions')
          .select('mosque_id')
          .eq('id', competitionId)
          .single();
      final user = await _authRepo.getCurrentUserProfile();
      if (user == null) throw const NotLoggedInFailure();
      await _requireOwnerRole(comp['mosque_id'] as String, user.id);

      await supabase
          .from('competitions')
          .update({'is_active': false})
          .eq('id', competitionId);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // المسابقة النشطة للمسجد
  // ─────────────────────────────────────────────────────────

  Future<CompetitionModel?> getActive(String mosqueId) async {
    try {
      final row = await supabase
          .from('competitions')
          .select()
          .eq('mosque_id', mosqueId)
          .eq('is_active', true)
          .maybeSingle();

      return row != null ? CompetitionModel.fromJson(row) : null;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // كل مسابقات المسجد
  // ─────────────────────────────────────────────────────────

  Future<List<CompetitionModel>> getAllForMosque(String mosqueId) async {
    try {
      final res = await supabase
          .from('competitions')
          .select()
          .eq('mosque_id', mosqueId)
          .order('created_at', ascending: false);

      return (res as List).map((e) => CompetitionModel.fromJson(e)).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // ترتيب الأبناء في مسابقة (Leaderboard)
  // ─────────────────────────────────────────────────────────

  Future<List<LeaderboardEntry>> getLeaderboard(
      String competitionId) async {
    try {
      // نجمع الحضور المرتبط بالمسابقة ونحسب النقاط لكل ابن
      final res = await supabase
          .from('attendance')
          .select('child_id, points_earned, children(name)')
          .eq('competition_id', competitionId);

      // تجميع النقاط لكل ابن
      final Map<String, Map<String, dynamic>> byChild = {};
      for (final row in (res as List)) {
        final childId = row['child_id'] as String;
        final points = (row['points_earned'] as num?)?.toInt() ?? 0;
        final name = (row['children'] as Map?)?['name'] as String? ?? 'غير معروف';
        if (!byChild.containsKey(childId)) {
          byChild[childId] = {
            'child_id':        childId,
            'child_name':      name,
            'total_points':    0,
            'attendance_count': 0,
          };
        }
        byChild[childId]!['total_points'] =
            (byChild[childId]!['total_points'] as int) + points;
        byChild[childId]!['attendance_count'] =
            (byChild[childId]!['attendance_count'] as int) + 1;
      }

      // ترتيب تنازلي حسب النقاط
      final sorted = byChild.values.toList()
        ..sort((a, b) =>
            (b['total_points'] as int).compareTo(a['total_points'] as int));

      return sorted.asMap().entries
          .map((e) => LeaderboardEntry.fromJson(e.value, e.key + 1))
          .toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // حالة المسابقة للمسجد: جارية / قادمة / منتهية / لا شيء
  // ─────────────────────────────────────────────────────────

  Future<({CompetitionStatus status, CompetitionModel? competition})>
      getCompetitionStatus(String mosqueId) async {
    try {
      final now = DateTime.now();

      // 1. مسابقة نشطة الآن
      final active = await getActive(mosqueId);
      if (active != null) {
        return (status: CompetitionStatus.running, competition: active);
      }

      // 2. كل مسابقات المسجد
      final all = await getAllForMosque(mosqueId);
      if (all.isEmpty) {
        return (status: CompetitionStatus.noCompetition, competition: null);
      }

      // 3. مسابقة قادمة (startDate في المستقبل)
      final upcoming = all
          .where((c) => now.isBefore(c.startDate))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      if (upcoming.isNotEmpty) {
        return (status: CompetitionStatus.upcoming, competition: upcoming.first);
      }

      // 4. أحدث مسابقة منتهية
      return (status: CompetitionStatus.finished, competition: all.first);
    } catch (_) {
      return (status: CompetitionStatus.noCompetition, competition: null);
    }
  }

  /// تحقق: المستخدم لازم يكون owner (إمام) في هذا المسجد
  Future<void> _requireOwnerRole(String mosqueId, String userId) async {
    final membership = await supabase
        .from('mosque_members')
        .select('role')
        .eq('mosque_id', mosqueId)
        .eq('user_id', userId)
        .maybeSingle();

    if (membership == null || membership['role'] != 'owner') {
      throw const UnauthorizedActionFailure(
        'فقط الإمام يمكنه إدارة المسابقات',
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // المسابقات النشطة لعدة مساجد (لولي الأمر والابن)
  // ─────────────────────────────────────────────────────────

  Future<List<CompetitionModel>> getActiveForMosques(
      List<String> mosqueIds) async {
    if (mosqueIds.isEmpty) return [];
    try {
      final res = await supabase
          .from('competitions')
          .select()
          .inFilter('mosque_id', mosqueIds)
          .eq('is_active', true)
          .order('start_date', ascending: false);
      return (res as List)
          .map((e) => CompetitionModel.fromJson(e))
          .toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }
}
