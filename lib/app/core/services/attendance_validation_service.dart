import 'package:adhan/adhan.dart' hide Prayer;
import '../constants/app_enums.dart';
import 'prayer_times_service.dart';

/// نتيجة التحقق من وقت الحضور
class AttendanceValidationResult {
  final bool allowed;
  final String? reason;

  const AttendanceValidationResult({required this.allowed, this.reason});

  const AttendanceValidationResult.allowed()
      : allowed = true,
        reason = null;

  const AttendanceValidationResult.denied(String this.reason) : allowed = false;
}

/// خدمة التحقق من وقت تسجيل الحضور
///
/// القواعد:
/// 1. الوقت الحالي >= وقت أذان الصلاة
/// 2. الوقت الحالي <= وقت الأذان + نافذة (افتراضي 60 دقيقة)
/// 3. إذا لم تتوفر إحداثيات المسجد → يستخدم مكة المكرمة كموقع افتراضي
class AttendanceValidationService {
  final PrayerTimesService _prayerTimesService;

  AttendanceValidationService(this._prayerTimesService);

  /// إحداثيات مكة المكرمة (الافتراضية)
  static const double _defaultLat = 21.4225;
  static const double _defaultLng = 39.8262;

  /// التحقق من إمكانية تسجيل الحضور الآن
  ///
  /// [prayer] الصلاة المراد تسجيلها
  /// [date] تاريخ الصلاة
  /// [lat] خط عرض المسجد (اختياري)
  /// [lng] خط طول المسجد (اختياري)
  /// [windowMinutes] نافذة الحضور بالدقائق (افتراضي 60)
  AttendanceValidationResult canRecordNow({
    required Prayer prayer,
    required DateTime date,
    double? lat,
    double? lng,
    int windowMinutes = 60,
  }) {
    final now = DateTime.now();

    // إذا كان التاريخ مختلف عن اليوم → لا نتحقق (طلب تصحيح)
    final today = DateTime(now.year, now.month, now.day);
    final requestDate = DateTime(date.year, date.month, date.day);
    if (requestDate != today) {
      // تسجيل لتاريخ غير اليوم → يتم عبر طلب التصحيح فقط
      return const AttendanceValidationResult.denied(
        'لا يمكن تسجيل حضور ليوم غير اليوم — استخدم طلب التصحيح',
      );
    }

    // حساب أوقات الصلاة بإحداثيات المسجد
    final useLat = lat ?? _defaultLat;
    final useLng = lng ?? _defaultLng;

    final coordinates = Coordinates(useLat, useLng);
    final dateComponents = DateComponents.from(date);
    final params = CalculationMethod.umm_al_qura.getParameters();
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    // الحصول على وقت أذان الصلاة المحددة
    final adhanTime = _getAdhanTime(prayer, prayerTimes);
    if (adhanTime == null) {
      return const AttendanceValidationResult.allowed();
    }

    // التحقق: هل حان الوقت؟
    if (now.isBefore(adhanTime)) {
      return const AttendanceValidationResult.denied(
        'لم يحن وقت هذه الصلاة بعد',
      );
    }

    // التحقق: هل انتهت النافذة؟
    final windowEnd = adhanTime.add(Duration(minutes: windowMinutes));
    if (now.isAfter(windowEnd)) {
      return const AttendanceValidationResult.denied(
        'انتهت مهلة تسجيل الحضور لهذه الصلاة',
      );
    }

    return const AttendanceValidationResult.allowed();
  }

  /// الحصول على وقت أذان صلاة معينة
  DateTime? _getAdhanTime(Prayer prayer, PrayerTimes times) {
    switch (prayer) {
      case Prayer.fajr:
        return times.fajr;
      case Prayer.dhuhr:
        return times.dhuhr;
      case Prayer.asr:
        return times.asr;
      case Prayer.maghrib:
        return times.maghrib;
      case Prayer.isha:
        return times.isha;
    }
  }
}
