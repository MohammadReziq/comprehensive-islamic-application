import 'package:adhan/adhan.dart' hide Prayer;
import 'package:intl/intl.dart';
import '../constants/app_enums.dart';
import '../constants/app_strings.dart';

/// خدمة حساب أوقات الصلاة
class PrayerTimesService {
  /// إحداثيات افتراضية (مكة المكرمة)
  /// يمكن تغييرها حسب موقع المستخدم
  double _latitude = 21.4225;
  double _longitude = 39.8262;

  /// طريقة الحساب
  CalculationParameters _params = CalculationMethod.umm_al_qura.getParameters();

  /// تحديث الموقع
  void updateLocation(double lat, double lng) {
    _latitude = lat;
    _longitude = lng;
  }

  /// تغيير طريقة الحساب
  void setCalculationMethod(CalculationMethod method) {
    _params = method.getParameters();
  }

  // ─── أوقات الصلاة ───

  /// الحصول على أوقات صلاة اليوم
  PrayerTimes getTodayPrayerTimes() {
    final coordinates = Coordinates(_latitude, _longitude);
    final dateComponents = DateComponents.from(DateTime.now());
    return PrayerTimes(coordinates, dateComponents, _params);
  }

  /// الحصول على أوقات صلاة لتاريخ معين
  PrayerTimes getPrayerTimesForDate(DateTime date) {
    final coordinates = Coordinates(_latitude, _longitude);
    final dateComponents = DateComponents.from(date);
    return PrayerTimes(coordinates, dateComponents, _params);
  }

  // ─── الصلاة الحالية والقادمة ───

  /// الصلاة القادمة
  PrayerInfo getNextPrayer() {
    final times = getTodayPrayerTimes();
    final now = DateTime.now();

    if (now.isBefore(times.fajr)) {
      return PrayerInfo(
        prayer: Prayer.fajr,
        time: times.fajr,
        timeFormatted: _formatTime(times.fajr),
        remaining: times.fajr.difference(now),
      );
    }
    if (now.isBefore(times.dhuhr)) {
      return PrayerInfo(
        prayer: Prayer.dhuhr,
        time: times.dhuhr,
        timeFormatted: _formatTime(times.dhuhr),
        remaining: times.dhuhr.difference(now),
      );
    }
    if (now.isBefore(times.asr)) {
      return PrayerInfo(
        prayer: Prayer.asr,
        time: times.asr,
        timeFormatted: _formatTime(times.asr),
        remaining: times.asr.difference(now),
      );
    }
    if (now.isBefore(times.maghrib)) {
      return PrayerInfo(
        prayer: Prayer.maghrib,
        time: times.maghrib,
        timeFormatted: _formatTime(times.maghrib),
        remaining: times.maghrib.difference(now),
      );
    }
    if (now.isBefore(times.isha)) {
      return PrayerInfo(
        prayer: Prayer.isha,
        time: times.isha,
        timeFormatted: _formatTime(times.isha),
        remaining: times.isha.difference(now),
      );
    }

    // بعد العشاء → الفجر بكرة
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowTimes = getPrayerTimesForDate(tomorrow);
    return PrayerInfo(
      prayer: Prayer.fajr,
      time: tomorrowTimes.fajr,
      timeFormatted: _formatTime(tomorrowTimes.fajr),
      remaining: tomorrowTimes.fajr.difference(now),
    );
  }

  /// الصلاة الحالية (آخر صلاة فاتت)
  Prayer? getCurrentPrayer() {
    final times = getTodayPrayerTimes();
    final now = DateTime.now();

    if (now.isAfter(times.isha)) return Prayer.isha;
    if (now.isAfter(times.maghrib)) return Prayer.maghrib;
    if (now.isAfter(times.asr)) return Prayer.asr;
    if (now.isAfter(times.dhuhr)) return Prayer.dhuhr;
    if (now.isAfter(times.fajr)) return Prayer.fajr;
    return null;
  }

  /// كل أوقات اليوم كـ Map
  Map<Prayer, PrayerInfo> getAllTodayPrayers() {
    final times = getTodayPrayerTimes();
    return {
      Prayer.fajr: PrayerInfo(
        prayer: Prayer.fajr,
        time: times.fajr,
        timeFormatted: _formatTime(times.fajr),
      ),
      Prayer.dhuhr: PrayerInfo(
        prayer: Prayer.dhuhr,
        time: times.dhuhr,
        timeFormatted: _formatTime(times.dhuhr),
      ),
      Prayer.asr: PrayerInfo(
        prayer: Prayer.asr,
        time: times.asr,
        timeFormatted: _formatTime(times.asr),
      ),
      Prayer.maghrib: PrayerInfo(
        prayer: Prayer.maghrib,
        time: times.maghrib,
        timeFormatted: _formatTime(times.maghrib),
      ),
      Prayer.isha: PrayerInfo(
        prayer: Prayer.isha,
        time: times.isha,
        timeFormatted: _formatTime(times.isha),
      ),
    };
  }

  // ─── تنسيق ───

  /// تنسيق الوقت (12 ساعة)
  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a', 'ar').format(time);
  }

  /// تنسيق الوقت المتبقي بالعربية
  static String formatRemaining(Duration duration) {
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      return '${duration.inHours} ساعة و $minutes ${AppStrings.minutesRemaining}';
    }
    return '${duration.inMinutes} ${AppStrings.minutesRemaining}';
  }
}

/// معلومات صلاة واحدة
class PrayerInfo {
  final Prayer prayer;
  final DateTime time;
  final String timeFormatted;
  final Duration? remaining;

  const PrayerInfo({
    required this.prayer,
    required this.time,
    required this.timeFormatted,
    this.remaining,
  });

  /// اسم الصلاة بالعربي
  String get nameAr => prayer.nameAr;

  /// هل فاتت هذه الصلاة؟
  bool get isPassed => DateTime.now().isAfter(time);
}
