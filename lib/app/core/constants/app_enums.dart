// كل التعدادات في التطبيق

/// أدوار المستخدمين
enum UserRole {
  superAdmin('super_admin', 'مدير النظام'),
  imam('imam', 'إمام (مدير المسجد)'),
  supervisor('supervisor', 'مشرف'),
  parent('parent', 'ولي أمر');

  const UserRole(this.value, this.nameAr);
  final String value;
  final String nameAr;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.parent,
    );
  }
}

/// الصلوات الخمس
enum Prayer {
  fajr('fajr', 'الفجر', 1),
  dhuhr('dhuhr', 'الظهر', 2),
  asr('asr', 'العصر', 3),
  maghrib('maghrib', 'المغرب', 4),
  isha('isha', 'العشاء', 5);

  const Prayer(this.value, this.nameAr, this.order);
  final String value;
  final String nameAr;
  final int order;

  static Prayer fromString(String value) {
    return Prayer.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Prayer.fajr,
    );
  }
}

/// مكان الصلاة
enum LocationType {
  mosque('mosque', 'مسجد'),
  home('home', 'منزل');

  const LocationType(this.value, this.nameAr);
  final String value;
  final String nameAr;

  static LocationType fromString(String value) {
    return LocationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LocationType.mosque,
    );
  }
}

/// حالة المسجد
enum MosqueStatus {
  pending('pending', 'قيد المراجعة'),
  approved('approved', 'معتمد'),
  rejected('rejected', 'مرفوض');

  const MosqueStatus(this.value, this.nameAr);
  final String value;
  final String nameAr;

  static MosqueStatus fromString(String value) {
    return MosqueStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MosqueStatus.pending,
    );
  }
}

/// دور المشرف في المسجد
enum MosqueRole {
  owner('owner', 'مدير المسجد'),
  supervisor('supervisor', 'مشرف');

  const MosqueRole(this.value, this.nameAr);
  final String value;
  final String nameAr;

  static MosqueRole fromString(String value) {
    return MosqueRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MosqueRole.supervisor,
    );
  }
}

/// نوع ربط الطفل بالمسجد
enum MosqueType {
  primary('primary', 'أساسي'),
  secondary('secondary', 'إضافي');

  const MosqueType(this.value, this.nameAr);
  final String value;
  final String nameAr;

  static MosqueType fromString(String value) {
    return MosqueType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MosqueType.primary,
    );
  }
}

/// حالة طلب التصحيح
enum CorrectionStatus {
  pending('pending', 'قيد المراجعة'),
  approved('approved', 'مقبول'),
  rejected('rejected', 'مرفوض');

  const CorrectionStatus(this.value, this.nameAr);
  final String value;
  final String nameAr;

  static CorrectionStatus fromString(String value) {
    return CorrectionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CorrectionStatus.pending,
    );
  }
}

/// أنواع الشارات
enum BadgeType {
  prayerHero('prayer_hero', 'بطل الصلاة', '🏅', 'حضور 7 أيام متتالية'),
  prayerLeader('prayer_leader', 'زعيم الصلاة', '👑', 'حضور 30 يوم متتالي'),
  mosquePrince('mosque_prince', 'أمير المسجد', '🏰', 'الأول في الترتيب أسبوعياً'),
  fajrKnight('fajr_knight', 'فارس الفجر', '🌙', '15 فجر في الشهر'),
  persistent('persistent', 'المثابر', '💪', 'استعاد السلسلة بعد انقطاع');

  const BadgeType(this.value, this.nameAr, this.emoji, this.description);
  final String value;
  final String nameAr;
  final String emoji;
  final String description;

  static BadgeType fromString(String value) {
    return BadgeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BadgeType.prayerHero,
    );
  }
}

/// طريقة التحضير
enum AttendanceMethod {
  qrScan('qr_scan', 'مسح QR'),
  number('number', 'رقم الطالب'),
  nameSearch('name_search', 'بحث بالاسم'),
  manualTap('manual_tap', 'ضغط من القائمة');

  const AttendanceMethod(this.value, this.nameAr);
  final String value;
  final String nameAr;
}
