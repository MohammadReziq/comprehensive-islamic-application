// مواقيت الصلاة عبر Aladhan API — مع تخزين مؤقت ذكي في SharedPreferences

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_enums.dart';
import '../constants/app_strings.dart';
import '../network/aladhan_api.dart';

/// خدمة مواقيت الصلاة — تخزين مؤقت ذكي + تحديث في الخلفية
class PrayerTimesService {
  /// الأوقات المحمّلة للجلسة الحالية
  Map<Prayer, DateTime>? _lastFetch;
  Map<Prayer, DateTime>? _tomorrowFetch;
  double? _lastLat;
  double? _lastLng;
  DateTime? _lastDate;

  // ── Cache Keys ─────────────────────────────────────────────
  static const _prefix = 'prayer_cache_';
  static const _keyDate = '${_prefix}date';
  static const _keyCacheLat = '${_prefix}lat';
  static const _keyCacheLng = '${_prefix}lng';

  // ── التطابق ────────────────────────────────────────────────

  bool _matches(double lat, double lng, DateTime d) {
    if (_lastFetch == null ||
        _lastLat == null ||
        _lastLng == null ||
        _lastDate == null) {
      return false;
    }
    return _lastLat == lat &&
        _lastLng == lng &&
        _lastDate!.year == d.year &&
        _lastDate!.month == d.month &&
        _lastDate!.day == d.day;
  }

  // ── كاش SharedPreferences ──────────────────────────────────

  /// حفظ المواقيت في SharedPreferences
  Future<void> _saveToCache(
      Map<Prayer, DateTime> timings, double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      await prefs.setString(
          _keyDate, '${today.year}-${today.month}-${today.day}');
      await prefs.setDouble(_keyCacheLat, lat);
      await prefs.setDouble(_keyCacheLng, lng);
      for (final e in timings.entries) {
        await prefs.setString(
            '$_prefix${e.key.name}', e.value.toIso8601String());
      }
    } catch (_) {}
  }

  /// تحميل المواقيت من SharedPreferences (إذا كانت لنفس اليوم)
  Future<Map<Prayer, DateTime>?> _loadFromCache(
      [double? lat, double? lng]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = prefs.getString(_keyDate);
      if (dateStr == null) return null;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      if (dateStr != todayStr) return null; // كاش يوم قديم

      // تحقق من تشابه الموقع إذا مُرّر
      if (lat != null && lng != null) {
        final cachedLat = prefs.getDouble(_keyCacheLat);
        final cachedLng = prefs.getDouble(_keyCacheLng);
        if (cachedLat != null && cachedLng != null) {
          // إذا الموقع بعيد جداً (~50 كم) لا نستخدم الكاش
          if ((lat - cachedLat).abs() > 0.45 ||
              (lng - cachedLng).abs() > 0.45) {
            return null;
          }
        }
      }

      final result = <Prayer, DateTime>{};
      for (final p in Prayer.values) {
        final str = prefs.getString('$_prefix${p.name}');
        if (str == null) return null;
        result[p] = DateTime.parse(str);
      }

      // تأكد أن التواريخ المحفوظة لنفس اليوم
      final firstTime = result.values.first;
      if (firstTime.year != now.year ||
          firstTime.month != now.month ||
          firstTime.day != now.day) {
        return null;
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  // ── الجلب الرئيسي ─────────────────────────────────────────

  /// جلب أوقات اليوم — يحاول الكاش أولاً، ثم API، ثم يحفظ
  Future<bool> loadTimingsFor(double lat, double lng, [DateTime? date]) async {
    final d = date ?? DateTime.now();

    // إذا كانت البيانات محمّلة بالفعل ومطابقة → لا حاجة
    if (_matches(lat, lng, d)) return true;

    // حاول الكاش أولاً (فقط إذا طلب بدون تاريخ = اليوم)
    if (date == null) {
      final cached = await _loadFromCache(lat, lng);
      if (cached != null) {
        _lastFetch = cached;
        _lastLat = lat;
        _lastLng = lng;
        _lastDate = d;

        // حاول تحميل الغد + تحديث خلفي
        _backgroundRefresh(lat, lng, d);
        return true;
      }
    }

    // لا كاش → اطلب من API
    final timings = await getTimings(lat: lat, lng: lng, date: d);
    if (timings != null) {
      _lastFetch = timings;
      _lastLat = lat;
      _lastLng = lng;
      _lastDate = d;

      // احفظ في الكاش (فقط إذا اليوم)
      if (date == null) {
        _saveToCache(timings, lat, lng);
      }

      // حمّل الغد إذا مرّ العشاء
      final now = DateTime.now();
      if (now.isAfter(timings[Prayer.isha]!)) {
        final tomorrow = d.add(const Duration(days: 1));
        _tomorrowFetch = await getTimings(lat: lat, lng: lng, date: tomorrow);
      } else {
        _tomorrowFetch = null;
      }
      return true;
    }

    // API فشل — حاول كاش الأمس كحل أخير
    if (date == null) {
      final oldCache = await _loadFromCache();
      if (oldCache != null) {
        _lastFetch = oldCache;
        _lastLat = lat;
        _lastLng = lng;
        _lastDate = d;
        return true;
      }
    }

    return false;
  }

  /// تحديث خلفي بدون حجب المستخدم
  Future<void> _backgroundRefresh(
      double lat, double lng, DateTime date) async {
    try {
      final timings = await getTimings(lat: lat, lng: lng, date: date);
      if (timings != null) {
        _lastFetch = timings;
        _saveToCache(timings, lat, lng);

        final now = DateTime.now();
        if (now.isAfter(timings[Prayer.isha]!)) {
          final tomorrow = date.add(const Duration(days: 1));
          _tomorrowFetch =
              await getTimings(lat: lat, lng: lng, date: tomorrow);
        } else {
          _tomorrowFetch = null;
        }
      }
    } catch (_) {}
  }

  // ── الدوال الموجودة (بدون تغيير سلوكي) ────────────────────

  Map<Prayer, DateTime>? _getCached(double lat, double lng, DateTime date) {
    if (!_matches(lat, lng, date)) return null;
    return _lastFetch;
  }

  /// أوقات صلاة اليوم — بعد استدعاء loadTimingsFor
  Map<Prayer, DateTime>? getTodayPrayerTimesRaw(double lat, double lng) {
    return _getCached(lat, lng, DateTime.now());
  }

  /// الصلاة القادمة — إن لم تُحمّل الأوقات بعد يُعاد null
  PrayerInfo? getNextPrayerOrNull(double lat, double lng) {
    final times = _getCached(lat, lng, DateTime.now());
    if (times == null) return null;
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
    if (_lastLat == lat && _lastLng == lng && _tomorrowFetch != null) {
      return _info(Prayer.fajr, _tomorrowFetch![Prayer.fajr]!, now);
    }
    return null;
  }

  /// الصلاة القادمة — للشاشات ذات الموقع الثابت (مسجد)
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
