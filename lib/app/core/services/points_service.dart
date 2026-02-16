import '../constants/app_enums.dart';

/// خدمة حساب النقاط والسلاسل والمستويات
class PointsService {
  // ─── ثوابت النقاط ───

  /// نقاط صلاة الجماعة
  static const int mosquePrayerPoints = 10;

  /// نقاط صلاة الفجر في المنزل
  static const int homeFajrPoints = 5;

  /// نقاط صلاة أخرى في المنزل
  static const int homeOtherPoints = 3;

  /// مكافأة سلسلة 7 أيام
  static const int streak7Bonus = 25;

  /// مكافأة سلسلة 30 يوم
  static const int streak30Bonus = 100;

  /// مكافأة سلسلة 100 يوم
  static const int streak100Bonus = 500;

  // ─── حساب النقاط ───

  /// حساب نقاط حضور واحد
  int calculateAttendancePoints({
    required Prayer prayer,
    required LocationType locationType,
  }) {
    if (locationType == LocationType.mosque) {
      return mosquePrayerPoints;
    }

    // صلاة منزلية
    if (prayer == Prayer.fajr) {
      return homeFajrPoints;
    }
    return homeOtherPoints;
  }

  /// حساب مكافأة السلسلة (إن وُجدت)
  int? getStreakBonus(int currentStreak) {
    if (currentStreak == 7) return streak7Bonus;
    if (currentStreak == 30) return streak30Bonus;
    if (currentStreak == 100) return streak100Bonus;
    return null;
  }

  // ─── نظام المستويات ───

  /// الحصول على المستوى بناءً على النقاط
  ChildLevel getLevelForPoints(int totalPoints) {
    for (int i = _levels.length - 1; i >= 0; i--) {
      if (totalPoints >= _levels[i].minPoints) {
        return _levels[i];
      }
    }
    return _levels.first;
  }

  /// النقاط المطلوبة للمستوى التالي
  int? getPointsToNextLevel(int totalPoints) {
    final currentLevel = getLevelForPoints(totalPoints);
    final currentIndex = _levels.indexOf(currentLevel);

    if (currentIndex >= _levels.length - 1) return null; // أعلى مستوى

    return _levels[currentIndex + 1].minPoints - totalPoints;
  }

  /// نسبة التقدم نحو المستوى التالي (0.0 - 1.0)
  double getProgressToNextLevel(int totalPoints) {
    final currentLevel = getLevelForPoints(totalPoints);
    final currentIndex = _levels.indexOf(currentLevel);

    if (currentIndex >= _levels.length - 1) return 1.0;

    final nextLevel = _levels[currentIndex + 1];
    final range = nextLevel.minPoints - currentLevel.minPoints;
    final progress = totalPoints - currentLevel.minPoints;

    return (progress / range).clamp(0.0, 1.0);
  }

  /// قائمة كل المستويات
  static final List<ChildLevel> _levels = [
    const ChildLevel(level: 1, nameAr: 'بذرة الصلاة', icon: '🌱', minPoints: 0),
    const ChildLevel(level: 2, nameAr: 'نبتة الصلاة', icon: '🌿', minPoints: 100),
    const ChildLevel(level: 3, nameAr: 'شجرة الصلاة', icon: '🌳', minPoints: 300),
    const ChildLevel(level: 4, nameAr: 'نجم الصلاة', icon: '⭐', minPoints: 700),
    const ChildLevel(level: 5, nameAr: 'نجم المسجد', icon: '🌟', minPoints: 1500),
    const ChildLevel(level: 6, nameAr: 'أمير الصلاة', icon: '👑', minPoints: 3000),
  ];

  /// كل المستويات (للعرض)
  List<ChildLevel> get allLevels => List.unmodifiable(_levels);

  // ─── تقييم الشارات ───

  /// فحص هل يستحق شارة جديدة
  List<BadgeType> evaluateNewBadges({
    required int currentStreak,
    required int bestStreak,
    required int weeklyRank,
    required int monthlyFajrCount,
    required bool hadStreakBreak,
    required List<String> existingBadgeTypes,
  }) {
    final newBadges = <BadgeType>[];

    // بطل الصلاة: 7 أيام متتالية
    if (currentStreak >= 7 &&
        !existingBadgeTypes.contains(BadgeType.prayerHero.value)) {
      newBadges.add(BadgeType.prayerHero);
    }

    // زعيم الصلاة: 30 يوم متتالي
    if (currentStreak >= 30 &&
        !existingBadgeTypes.contains(BadgeType.prayerLeader.value)) {
      newBadges.add(BadgeType.prayerLeader);
    }

    // أمير المسجد: الأول أسبوعياً
    if (weeklyRank == 1 &&
        !existingBadgeTypes.contains(BadgeType.mosquePrince.value)) {
      newBadges.add(BadgeType.mosquePrince);
    }

    // فارس الفجر: 15 فجر في الشهر
    if (monthlyFajrCount >= 15 &&
        !existingBadgeTypes.contains(BadgeType.fajrKnight.value)) {
      newBadges.add(BadgeType.fajrKnight);
    }

    // المثابر: استعاد السلسلة بعد انقطاع
    if (hadStreakBreak &&
        currentStreak >= 3 &&
        !existingBadgeTypes.contains(BadgeType.persistent.value)) {
      newBadges.add(BadgeType.persistent);
    }

    return newBadges;
  }
}

/// نموذج المستوى
class ChildLevel {
  final int level;
  final String nameAr;
  final String icon;
  final int minPoints;

  const ChildLevel({
    required this.level,
    required this.nameAr,
    required this.icon,
    required this.minPoints,
  });
}
