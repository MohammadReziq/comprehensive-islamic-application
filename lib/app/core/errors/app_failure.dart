// lib/app/core/errors/app_failure.dart
// تسلسل هرمي للأخطاء — يُحوّل PostgresException لرسائل مفهومة

/// الفشل الأساسي
abstract class AppFailure {
  final String messageAr;
  const AppFailure(this.messageAr);

  @override
  String toString() => 'AppFailure($messageAr)';
}

/// فشل عام من الشبكة أو Supabase
class ServerFailure extends AppFailure {
  final String? code;
  const ServerFailure([String message = 'حدث خطأ في الخادم', this.code])
      : super(message);
}

/// المستخدم غير مسجّل دخول
class NotLoggedInFailure extends AppFailure {
  const NotLoggedInFailure() : super('يجب تسجيل الدخول أولاً');
}

/// تكرار حضور لنفس (ابن، صلاة، تاريخ)
class DuplicateAttendanceFailure extends AppFailure {
  const DuplicateAttendanceFailure()
      : super('تم تسجيل الحضور لهذه الصلاة مسبقاً');
}

/// المستخدم ليس عضواً في المسجد
class NotMosqueMemberFailure extends AppFailure {
  const NotMosqueMemberFailure()
      : super('ليس لديك صلاحية في هذا المسجد');
}

/// انتهت نافذة تسجيل الحضور (قبل الأذان أو بعد ساعة)
class AttendanceWindowClosedFailure extends AppFailure {
  const AttendanceWindowClosedFailure()
      : super('انتهت مهلة تسجيل الحضور لهذه الصلاة');
}

/// يوجد طلب تصحيح معلق لنفس الصلاة
class PendingCorrectionExistsFailure extends AppFailure {
  const PendingCorrectionExistsFailure()
      : super('يوجد طلب تصحيح معلق لهذه الصلاة');
}

/// يوجد حضور مسبق — لا يمكن إنشاء طلب تصحيح
class AttendanceAlreadyExistsFailure extends AppFailure {
  const AttendanceAlreadyExistsFailure()
      : super('الحضور مسجّل بالفعل لهذه الصلاة');
}

/// الطلب ليس في حالة انتظار
class RequestNotPendingFailure extends AppFailure {
  const RequestNotPendingFailure()
      : super('الطلب لم يعد في حالة انتظار');
}

/// انتهت مهلة إلغاء الحضور (24 ساعة)
class CancellationWindowExpiredFailure extends AppFailure {
  const CancellationWindowExpiredFailure()
      : super('انتهت مهلة الإلغاء (24 ساعة)');
}

/// لم يحن وقت الصلاة بعد (قبل الأذان)
class AttendanceBeforeAdhanFailure extends AppFailure {
  const AttendanceBeforeAdhanFailure()
      : super('لم يحن وقت هذه الصلاة بعد');
}

/// ليس لديك صلاحية لهذا الإجراء
class UnauthorizedActionFailure extends AppFailure {
  const UnauthorizedActionFailure([String message = 'ليس لديك صلاحية لهذا الإجراء'])
      : super(message);
}

/// تحويل PostgresException → AppFailure
AppFailure mapPostgresError(Object e) {
  final msg = e.toString().toLowerCase();

  if (msg.contains('23505') || msg.contains('unique')) {
    if (msg.contains('attendance')) return const DuplicateAttendanceFailure();
    if (msg.contains('correction')) return const PendingCorrectionExistsFailure();
    return ServerFailure('تكرار في البيانات', '23505');
  }

  if (msg.contains('mosque_member') || msg.contains('صلاحية')) {
    return const NotMosqueMemberFailure();
  }

  if (msg.contains('انتهت مهلة')) {
    return const CancellationWindowExpiredFailure();
  }

  if (msg.contains('حضور مسجّل')) {
    return const AttendanceAlreadyExistsFailure();
  }

  if (msg.contains('ليس في حالة انتظار')) {
    return const RequestNotPendingFailure();
  }

  return ServerFailure(e.toString());
}
