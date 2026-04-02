import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إدارة الموقع الذكية — يحفظ آخر موقع ناجح ويعيد استخدامه فوراً
/// يحدّث في الخلفية كل 30 يوم أو إذا تغيّر الموقع بشكل ملحوظ
class SmartLocationManager {
  static const _keyLat = 'prayer_saved_lat';
  static const _keyLng = 'prayer_saved_lng';
  static const _keyDate = 'prayer_loc_date';
  static const _refreshDays = 30;
  static const _significantChangeDeg = 0.045; // ≈ 5 km

  // ── قراءة/كتابة الموقع المحفوظ ──────────────────────────

  /// يعيد آخر موقع محفوظ فوراً من SharedPreferences
  static Future<({double? lat, double? lng})> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyLat);
    final lng = prefs.getDouble(_keyLng);
    return (lat: lat, lng: lng);
  }

  /// يحفظ الموقع الجديد مع تاريخ الحفظ
  static Future<void> saveLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLat, lat);
    await prefs.setDouble(_keyLng, lng);
    await prefs.setString(_keyDate, DateTime.now().toIso8601String());
  }

  /// هل مرّ أكثر من 30 يوم منذ آخر تحديث؟
  static Future<bool> needsRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyDate);
    if (dateStr == null) return true;
    final saved = DateTime.tryParse(dateStr);
    if (saved == null) return true;
    return DateTime.now().difference(saved).inDays >= _refreshDays;
  }

  /// هل الموقع الجديد بعيد عن المحفوظ بشكل ملحوظ (~5 كم)؟
  static bool hasSignificantChange(
      double newLat, double newLng, double? oldLat, double? oldLng) {
    if (oldLat == null || oldLng == null) return true;
    return (newLat - oldLat).abs() > _significantChangeDeg ||
        (newLng - oldLng).abs() > _significantChangeDeg;
  }

  // ── حالة الإذن ──────────────────────────────────────────

  /// يتحقق من حالة إذن الموقع الحالية بدون طلب إذن
  static Future<LocationPermissionStatus> checkPermissionStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;
      final perm = await Geolocator.checkPermission();
      switch (perm) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationPermissionStatus.granted;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.deniedForever;
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return LocationPermissionStatus.denied;
      }
    } catch (_) {
      return LocationPermissionStatus.denied;
    }
  }

  // ── الدالة الذكية الرئيسية ────────────────────────────────

  /// تعيد الموقع فوراً من الكاش إن وُجد، ثم تحدّث في الخلفية
  ///
  /// [onLocationReady] يُستدعى فوراً بالكاش أو بعد GPS إن كانت أول مرة
  /// [onLocationUpdated] يُستدعى إذا تغيّر الموقع بشكل ملحوظ أثناء التحديث الخلفي
  /// [onPermissionStatus] يبلّغ الـ UI بحالة الإذن لعرض البانر المناسب
  static Future<void> getLocationSmart({
    required void Function(double lat, double lng) onLocationReady,
    void Function(double lat, double lng)? onLocationUpdated,
    void Function(LocationPermissionStatus status)? onPermissionStatus,
  }) async {
    final saved = await getSavedLocation();

    // ——— إذا عندنا موقع محفوظ → استخدمه فوراً ———
    if (saved.lat != null && saved.lng != null) {
      onLocationReady(saved.lat!, saved.lng!);

      // تحديث خلفي إذا مرّ 30 يوم
      final refresh = await needsRefresh();
      if (refresh) {
        _tryBackgroundRefresh(
            saved.lat!, saved.lng!, onLocationUpdated, onPermissionStatus);
      } else {
        // حتى لو لا نحتاج refresh، نبلّغ بحالة الإذن
        final status = await checkPermissionStatus();
        onPermissionStatus?.call(status);
      }
      return;
    }

    // ——— أول مرة: نحتاج طلب GPS ———
    final status = await checkPermissionStatus();
    onPermissionStatus?.call(status);

    if (status == LocationPermissionStatus.denied) {
      // حاول طلب الإذن
      try {
        final perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          onPermissionStatus?.call(LocationPermissionStatus.granted);
          final pos = await _getPosition();
          if (pos != null) {
            await saveLocation(pos.latitude, pos.longitude);
            onLocationReady(pos.latitude, pos.longitude);
          }
          return;
        }
        if (perm == LocationPermission.deniedForever) {
          onPermissionStatus?.call(LocationPermissionStatus.deniedForever);
        }
      } catch (_) {}
      return;
    }

    if (status == LocationPermissionStatus.granted) {
      final pos = await _getPosition();
      if (pos != null) {
        await saveLocation(pos.latitude, pos.longitude);
        onLocationReady(pos.latitude, pos.longitude);
      }
      return;
    }

    // deniedForever أو serviceDisabled → الـ UI يعرض البانر المناسب
  }

  // ── مساعدات داخلية ────────────────────────────────────────

  static Future<void> _tryBackgroundRefresh(
    double oldLat,
    double oldLng,
    void Function(double, double)? onUpdated,
    void Function(LocationPermissionStatus)? onPermissionStatus,
  ) async {
    final status = await checkPermissionStatus();
    onPermissionStatus?.call(status);

    if (status != LocationPermissionStatus.granted) return;

    final pos = await _getPosition();
    if (pos == null) return;

    if (hasSignificantChange(pos.latitude, pos.longitude, oldLat, oldLng)) {
      await saveLocation(pos.latitude, pos.longitude);
      onUpdated?.call(pos.latitude, pos.longitude);
    } else {
      // الموقع لم يتغيّر — فقط حدّث التاريخ
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDate, DateTime.now().toIso8601String());
    }
  }

  static Future<Position?> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () =>
            throw TimeoutException('تعذّر تحديد الموقع في الوقت المحدد'),
      );
    } catch (_) {
      return null;
    }
  }
}

/// حالة إذن الموقع — يُستخدم لعرض UI مناسب
enum LocationPermissionStatus {
  /// الإذن ممنوح + GPS مشغّل
  granted,

  /// الإذن مرفوض (يمكن طلبه)
  denied,

  /// الإذن مرفوض نهائياً (يحتاج إعدادات)
  deniedForever,

  /// خدمة الموقع مغلقة على الجهاز
  serviceDisabled,

  /// لم يُتحقّق بعد
  unknown,
}
