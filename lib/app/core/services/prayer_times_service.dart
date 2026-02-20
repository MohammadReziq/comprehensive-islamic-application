// مواقيت الصلاة عبر Aladhan API (مناسب للأردن — Muslim World League)

import 'package:intl/intl.dart';
import '../constants/app_enums.dart';
import '../constants/app_strings.dart';
import '../network/aladhan_api.dart';

/// خدمة مواقيت الصلاة — تعتمد على Aladhan API
class PrayerTimesService {
  /// إحداثيات افتراضية (عمان، الأردن) عند عدم توفّر موقع
  static const double defaultLat = 31.9454;
  static const double defaultLng = 35.9284;
  /// تخزين مؤقت: مفتاح "lat,lng,date" -> أوقات الصلوات
  final Map<String, Map<Prayer, DateTime>> _cache = {};

  String _cacheKey(double lat, double lng, DateTime d) {
    final dateStr = '${d.year}-${d.month}-${d.day}';
    return '$lat,$lng,$dateStr';
  }

  /// جلب أوقات اليوم من API (أو من الكاش) وتخزينها
  Future<void> loadTimingsFor(double lat, double lng, [DateTime? date]) async {
    final d = date ?? DateTime.now();
    final key = _cacheKey(lat, lng, d);
    if (_cache.containsKey(key)) return;
    final timings = await getTimings(lat: lat, lng: lng, date: d);
    if (timings != null) _cache[key] = timings;
  }

  Map<Prayer, DateTime>? _getCached(double lat, double lng, DateTime date) {
    return _cache[_cacheKey(lat, lng, date)];
  }

  /// أوقات صلاة اليوم (من الكاش فقط — استدعِ loadTimingsFor أولاً)
  Map<Prayer, DateTime>? getTodayPrayerTimesRaw(double lat, double lng) {
    return _getCached(lat, lng, DateTime.now());
  }

  /// الصلاة القادمة (من الكاش). إن لم تُحمّل الأوقات بعد يُعاد افتراض معقول.
  PrayerInfo getNextPrayer(double lat, double lng) {
    final times = _getCached(lat, lng, DateTime.now());
    if (times == null) {
      return _defaultNextPrayer();
    }
    final now = DateTime.now();
    if (now.isBefore(times[Prayer.fajr]!)) {
      return _info(Prayer.fajr, times[Prayer.fajr]!, now);
    }
    if (now.isBefore(times[Prayer.dhuhr]!)) {
      return _info(Prayer.dhuhr, times[Prayer.dhuhr]!, now);
    }
    if (now.isBefore(times[Prayer.asr]!)) {
      return _info(Prayer.asr, times[Prayer.asr]!, now);
    }
    if (now.isBefore(times[Prayer.maghrib]!)) {
      return _info(Prayer.maghrib, times[Prayer.maghrib]!, now);
    }
    if (now.isBefore(times[Prayer.isha]!)) {
      return _info(Prayer.isha, times[Prayer.isha]!, now);
    }
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowKey = _cacheKey(lat, lng, tomorrow);
    if (_cache.containsKey(tomorrowKey)) {
      final t = _cache[tomorrowKey]!;
      return _info(Prayer.fajr, t[Prayer.fajr]!, now);
    }
    return _info(Prayer.fajr, DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5, 45), now);
  }

  PrayerInfo _info(Prayer prayer, DateTime time, DateTime now) {
    final remaining = time.difference(now);
    return PrayerInfo(
      prayer: prayer,
      time: time,
      timeFormatted: DateFormat('hh:mm a', 'ar').format(time),
      remaining: remaining,
    );
  }

  PrayerInfo _defaultNextPrayer() {
    final now = DateTime.now();
    final fajrDefault = DateTime(now.year, now.month, now.day, 5, 45);
    if (now.isBefore(fajrDefault)) {
      return _info(Prayer.fajr, fajrDefault, now);
    }
    return _info(Prayer.dhuhr, DateTime(now.year, now.month, now.day, 12, 50), now);
  }

  /// أوقات اليوم كـ Map للعرض (من الكاش)
  Map<Prayer, PrayerInfo>? getAllTodayPrayers(double lat, double lng) {
    final times = _getCached(lat, lng, DateTime.now());
    if (times == null) return null;
    return {
      for (final e in times.entries)
        e.key: PrayerInfo(
          prayer: e.key,
          time: e.value,
          timeFormatted: DateFormat('hh:mm a', 'ar').format(e.value),
        ),
    };
  }

  /// الصلاة الحالية (آخر صلاة فاتت)
  Prayer? getCurrentPrayer(double lat, double lng) {
    final times = _getCached(lat, lng, DateTime.now());
    if (times == null) return null;
    final now = DateTime.now();
    if (now.isAfter(times[Prayer.isha]!)) return Prayer.isha;
    if (now.isAfter(times[Prayer.maghrib]!)) return Prayer.maghrib;
    if (now.isAfter(times[Prayer.asr]!)) return Prayer.asr;
    if (now.isAfter(times[Prayer.dhuhr]!)) return Prayer.dhuhr;
    if (now.isAfter(times[Prayer.fajr]!)) return Prayer.fajr;
    return null;
  }

  /// وقت أذان صلاة معينة ليوم محدد (للتحقق من الحضور)
  Future<DateTime?> getAdhanTime({
    required double lat,
    required double lng,
    required Prayer prayer,
    required DateTime date,
  }) async {
    await loadTimingsFor(lat, lng, date);
    final times = _getCached(lat, lng, date);
    return times?[prayer];
  }

  static String formatRemaining(Duration? duration) {
    if (duration == null) return '';
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
  final DateTime? time;
  final String timeFormatted;
  final Duration? remaining;

  const PrayerInfo({
    required this.prayer,
    this.time,
    required this.timeFormatted,
    this.remaining,
  });

  String get nameAr => prayer.nameAr;

  bool get isPassed => time != null && DateTime.now().isAfter(time!);
}
