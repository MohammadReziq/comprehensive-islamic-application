// lib/app/features/gamification/data/repositories/gamification_repository.dart

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// مستودع نظام الحوافز — مستويات، شارات، ترتيب
class GamificationRepository {
  GamificationRepository(this._authRepo);

  final AuthRepository _authRepo;

  // ─── مستوى الطفل ───

  /// حساب مستوى الطفل بناءً على إجمالي النقاط
  /// المستويات: كل 100 نقطة = مستوى جديد
  Future<Map<String, dynamic>> getChildLevel(String childId) async {
    try {
      final res = await supabase
          .from('attendance')
          .select('points_earned')
          .eq('child_id', childId);

      int totalPoints = 0;
      for (final row in (res as List)) {
        totalPoints += (row['points_earned'] as num?)?.toInt() ?? 0;
      }

      final level = (totalPoints ~/ 100) + 1;
      final pointsInLevel = totalPoints % 100;
      final pointsForNext = 100;

      return {
        'child_id': childId,
        'total_points': totalPoints,
        'level': level,
        'points_in_level': pointsInLevel,
        'points_for_next': pointsForNext,
        'level_name': _getLevelName(level),
      };
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── شارات الطفل ───

  /// حساب الشارات المستحقة للطفل
  Future<List<Map<String, dynamic>>> getChildBadges(String childId) async {
    try {
      final badges = <Map<String, dynamic>>[];

      // شارة بطل الصلاة: 7 أيام متتالية
      final streak = await _getCurrentStreak(childId);
      if (streak >= 7) {
        badges.add({
          'badge': BadgeType.prayerHero,
          'earned': true,
          'progress': '${streak >= 7 ? 7 : streak}/7',
        });
      }
      if (streak < 7) {
        badges.add({
          'badge': BadgeType.prayerHero,
          'earned': false,
          'progress': '$streak/7',
        });
      }

      // شارة زعيم الصلاة: 30 يوم متتالي
      badges.add({
        'badge': BadgeType.prayerLeader,
        'earned': streak >= 30,
        'progress': '${streak >= 30 ? 30 : streak}/30',
      });

      // شارة فارس الفجر: 15 فجر في الشهر الحالي
      final fajrCount = await _getFajrCountThisMonth(childId);
      badges.add({
        'badge': BadgeType.fajrKnight,
        'earned': fajrCount >= 15,
        'progress': '${fajrCount >= 15 ? 15 : fajrCount}/15',
      });

      return badges;
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── ترتيب المسجد (عام) ───

  /// ترتيب الأطفال في مسجد حسب إجمالي النقاط
  Future<List<Map<String, dynamic>>> getMosqueLeaderboard(
    String mosqueId, {
    int limit = 20,
  }) async {
    try {
      // جلب أطفال المسجد
      final children = await supabase
          .from('mosque_children')
          .select('child_id')
          .eq('mosque_id', mosqueId)
          .eq('is_active', true);

      final childIds =
          (children as List).map((e) => e['child_id'] as String).toList();
      if (childIds.isEmpty) return [];

      // جلب النقاط مع الأسماء
      final attendance = await supabase
          .from('attendance')
          .select('child_id, points_earned, children(name)')
          .inFilter('child_id', childIds);

      // تجميع
      final Map<String, Map<String, dynamic>> byChild = {};
      for (final row in (attendance as List)) {
        final cId = row['child_id'] as String;
        final pts = (row['points_earned'] as num?)?.toInt() ?? 0;
        final name = (row['children'] as Map?)?['name'] as String? ?? 'غير معروف';
        if (!byChild.containsKey(cId)) {
          byChild[cId] = {'child_id': cId, 'name': name, 'total_points': 0};
        }
        byChild[cId]!['total_points'] =
            (byChild[cId]!['total_points'] as int) + pts;
      }

      final sorted = byChild.values.toList()
        ..sort((a, b) =>
            (b['total_points'] as int).compareTo(a['total_points'] as int));

      return sorted.take(limit).toList().asMap().entries.map((e) {
        return {...e.value, 'rank': e.key + 1};
      }).toList();
    } catch (e) {
      throw mapPostgresError(e);
    }
  }

  // ─── مساعد: السلسلة الحالية ───

  Future<int> _getCurrentStreak(String childId) async {
    final res = await supabase
        .from('attendance')
        .select('prayer_date')
        .eq('child_id', childId)
        .order('prayer_date', ascending: false);

    if ((res as List).isEmpty) return 0;

    // جمع التواريخ الفريدة
    final dates = res
        .map((e) => e['prayer_date'] as String)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      final current = DateTime.parse(dates[i]);
      final previous = DateTime.parse(dates[i - 1]);
      if (previous.difference(current).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ─── مساعد: عدد الفجر هذا الشهر ───

  Future<int> _getFajrCountThisMonth(String childId) async {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final firstOfMonthStr =
        '${firstOfMonth.year}-${firstOfMonth.month.toString().padLeft(2, '0')}-01';

    final res = await supabase
        .from('attendance')
        .select('id')
        .eq('child_id', childId)
        .eq('prayer', 'fajr')
        .gte('prayer_date', firstOfMonthStr);

    return (res as List).length;
  }

  /// اسم المستوى حسب الرقم
  String _getLevelName(int level) {
    if (level <= 5) return 'مبتدئ';
    if (level <= 10) return 'مجتهد';
    if (level <= 20) return 'متقدم';
    if (level <= 30) return 'بطل';
    return 'أسطورة';
  }
}
