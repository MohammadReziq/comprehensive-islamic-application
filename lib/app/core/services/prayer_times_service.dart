// مواقيت الصلاة عبر Aladhan API — بدون كاش، كل مرة من الشبكة

import 'package:intl/intl.dart';

import '../constants/app_enums.dart';
import '../constants/app_strings.dart';
import '../network/aladhan_api.dart';

/// خدمة مواقيت الصلاة — تستدعي الـ API عند كل طلب، بدون تخزين مؤقت
class PrayerTimesService {
  /// آخر نتيجة جلب للجلسة الحالية فقط (لا يُحفظ بعد إغلاق التطبيق)
  Map<Prayer, DateTime>? _lastFetch;
  Map<Prayer, DateTime>? _tomorrowFetch;
  double? _lastLat;
  double? _lastLng;
  DateTime? _lastDate;

  bool _matches(double lat, double lng, DateTime d) {
    if (_lastFetch == null ||
        _lastLat == null ||
        _lastLng == null ||
        _lastDate == null)
      return false;
    return _lastLat == lat &&
        _lastLng == lng &&
        _lastDate!.year == d.year &&
        _lastDate!.month == d.month &&
        _lastDate!.day == d.day;
  }

  /// جلب أوقات اليوم من الـ API (كل مرة بدون كاش دائم)
  /// يعيد true إن تم جلب المواقيت، false إن فشل الطلب (لا إنترنت أو خطأ)
  Future<bool> loadTimingsFor(double lat, double lng, [DateTime? date]) async {
    final d = date ?? DateTime.now();
    final timings = await getTimings(lat: lat, lng: lng, date: d);
    if (timings != null) {
      _lastFetch = timings;
      _lastLat = lat;
      _lastLng = lng;
      _lastDate = d;
      final now = DateTime.now();
      if (now.isAfter(timings[Prayer.isha]!)) {
        final tomorrow = d.add(const Duration(days: 1));
        _tomorrowFetch = await getTimings(lat: lat, lng: lng, date: tomorrow);
      } else {
        _tomorrowFetch = null;
      }
      return true;
    }
    return false;
  }

  Map<Prayer, DateTime>? _getCached(double lat, double lng, DateTime date) {
    if (!_matches(lat, lng, date)) return null;
    return _lastFetch;
  }

  /// أوقات صلاة اليوم — بعد استدعاء loadTimingsFor
  Map<Prayer, DateTime>? getTodayPrayerTimesRaw(double lat, double lng) {
    return _getCached(lat, lng, DateTime.now());
  }

  /// الصلاة القادمة — إن لم تُحمّل الأوقات بعد (لا إنترنت أو لا موقع) يُعاد null للتعامل في الواجهة
  PrayerInfo? getNextPrayerOrNull(double lat, double lng) {
    final times = _getCached(lat, lng, DateTime.now());
    if (times == null) return null;
    final now = DateTime.now();
    if (now.isBefore(times[Prayer.fajr]!))
      return _info(Prayer.fajr, times[Prayer.fajr]!, now);
    if (now.isBefore(times[Prayer.dhuhr]!))
      return _info(Prayer.dhuhr, times[Prayer.dhuhr]!, now);
    if (now.isBefore(times[Prayer.asr]!))
      return _info(Prayer.asr, times[Prayer.asr]!, now);
    if (now.isBefore(times[Prayer.maghrib]!))
      return _info(Prayer.maghrib, times[Prayer.maghrib]!, now);
    if (now.isBefore(times[Prayer.isha]!))
      return _info(Prayer.isha, times[Prayer.isha]!, now);
    if (_lastLat == lat && _lastLng == lng && _tomorrowFetch != null) {
      return _info(Prayer.fajr, _tomorrowFetch![Prayer.fajr]!, now);
    }
    return null;
  }

  /// الصلاة القادمة — للشاشات التي تعتمد على موقع ثابت (مسجد). إن لم تُحمّل يُعاد افتراض معقول
  PrayerInfo getNextPrayer(double lat, double lng) {
    final info = getNextPrayerOrNull(lat, lng);
    if (info != null) return info;
    return _defaultNextPrayer();
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
    return _info(
      Prayer.dhuhr,
      DateTime(now.year, now.month, now.day, 12, 50),
      now,
    );
  }

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

  Future<DateTime?> getAdhanTime({
    required double lat,
    required double lng,
    required Prayer prayer,
    required DateTime date,
  }) async {
    final ok = await loadTimingsFor(lat, lng, date);
    if (!ok) return null;
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
