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

/// خدمة التحقق من وقت تسجيل الحضور (باستخدام أوقات Aladhan API)
class AttendanceValidationService {
  final PrayerTimesService _prayerTimesService;

  AttendanceValidationService(this._prayerTimesService);

  static const double _defaultLat = 31.9454;
  static const double _defaultLng = 35.9284;

  /// التحقق من إمكانية تسجيل الحضور الآن.
  /// [isImam]: إن كان true (مالك المسجد) لا يُطبَّق حدّ الساعة — يُسمح بالتسجيل بعد الأذان بدون قيد.
  /// المشرف فقط مقيد بنافذة الحضور (ساعة بعد الأذان).
  Future<AttendanceValidationResult> canRecordNow({
    required Prayer prayer,
    required DateTime date,
    double? lat,
    double? lng,
    int windowMinutes = 60,
    bool isImam = false,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final requestDate = DateTime(date.year, date.month, date.day);
    if (requestDate != today) {
      return const AttendanceValidationResult.denied(
        'لا يمكن تسجيل حضور ليوم غير اليوم — استخدم طلب التصحيح',
      );
    }

    final useLat = lat ?? _defaultLat;
    final useLng = lng ?? _defaultLng;

    final adhanTime = await _prayerTimesService.getAdhanTime(
      lat: useLat,
      lng: useLng,
      prayer: prayer,
      date: date,
    );

    if (adhanTime == null) {
      return const AttendanceValidationResult.allowed();
    }

    if (now.isBefore(adhanTime)) {
      return const AttendanceValidationResult.denied('لم يحن وقت هذه الصلاة بعد');
    }

    if (isImam) {
      return const AttendanceValidationResult.allowed();
    }

    final windowEnd = adhanTime.add(Duration(minutes: windowMinutes));
    if (now.isAfter(windowEnd)) {
      return const AttendanceValidationResult.denied('انتهت مهلة تسجيل الحضور لهذه الصلاة');
    }

    return const AttendanceValidationResult.allowed();
  }

  /// حالة نافذة التسجيل للمشرف: متبقي X دقيقة أو انتهت المهلة (ساعة بعد الأذان).
  Future<RecordingWindowStatus> getRecordingWindowStatus({
    required Prayer prayer,
    required DateTime date,
    double? lat,
    double? lng,
    int windowMinutes = 60,
  }) async {
    final now = DateTime.now();
    final useLat = lat ?? _defaultLat;
    final useLng = lng ?? _defaultLng;

    final adhanTime = await _prayerTimesService.getAdhanTime(
      lat: useLat,
      lng: useLng,
      prayer: prayer,
      date: date,
    );

    if (adhanTime == null) {
      return RecordingWindowStatus(
        allowed: false,
        remainingMinutes: null,
        message: 'جاري جلب المواقيت...',
      );
    }

    if (now.isBefore(adhanTime)) {
      final mins = adhanTime.difference(now).inMinutes;
      return RecordingWindowStatus(
        allowed: false,
        remainingMinutes: null,
        message: 'لم يحن وقت الصلاة بعد (بعد $mins دقيقة)',
      );
    }

    final windowEnd = adhanTime.add(Duration(minutes: windowMinutes));
    if (now.isAfter(windowEnd)) {
      return RecordingWindowStatus(
        allowed: false,
        remainingMinutes: 0,
        message: 'انتهت مهلة التسجيل (ساعة واحدة بعد الأذان)',
      );
    }

    final remaining = windowEnd.difference(now).inMinutes;
    return RecordingWindowStatus(
      allowed: true,
      remainingMinutes: remaining,
      message: 'متبقي $remaining دقيقة لتسجيل الحضور',
    );
  }
}

/// حالة نافذة تسجيل الحضور (للمشرف)
class RecordingWindowStatus {
  final bool allowed;
  final int? remainingMinutes;
  final String message;

  RecordingWindowStatus({
    required this.allowed,
    this.remainingMinutes,
    required this.message,
  });
}
