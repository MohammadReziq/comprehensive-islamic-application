/// [I8] رسائل خطأ عربية موحّدة
/// بدلاً من عرض رسائل Supabase الإنجليزية أو التقنية
class ErrorMessages {
  ErrorMessages._();

  /// خطأ عام
  static const String generic = 'حدث خطأ. يُرجى المحاولة مرة أخرى.';

  /// مشاكل الشبكة
  static const String noInternet = 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مجدداً.';
  static const String timeout = 'انتهت المهلة. تحقق من الاتصال وحاول مجدداً.';
  static const String serverError = 'حدث خطأ في الخادم. حاول لاحقاً.';
  static const String sessionExpired = 'انتهت الجلسة. سجّل دخولك مرة أخرى.';

  /// تسجيل الدخول
  static const String invalidCredentials = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
  static const String emailAlreadyExists = 'البريد الإلكتروني مسجّل مسبقاً.';
  static const String weakPassword = 'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل.';
  static const String emailNotVerified = 'يُرجى تأكيد بريدك الإلكتروني أولاً.';

  /// الحساب
  static const String unauthorized = 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
  static const String accountDisabled = 'الحساب معطّل. تواصل مع الإدارة.';
  static const String permissionDenied = 'ليس لديك صلاحية لهذه العملية.';

  /// إنشاء الحسابات (إمام/مشرف)
  static const String emailBelongsToParent =
      'هذا الإيميل مرتبط بحساب ولي أمر. استخدم إيميلاً مختلفاً.';
  static const String accountCreatedButSyncFailed =
      'تم إنشاء الحساب لكن التزامن تأخر. حاول لاحقاً.';
  static const String passwordTooShort =
      'كلمة السر يجب أن تكون 6 أحرف على الأقل.';

  /// المسجد
  static const String mosqueNotFound = 'لم يُعثر على المسجد.';
  static const String invalidMosqueCode = 'كود المسجد غير صحيح. تأكد من الكود وحاول مجدداً.';
  static const String alreadyJoined = 'أنت عضو بالفعل في هذا المسجد.';
  static const String pendingApproval = 'طلبك بانتظار الموافقة.';
  static const String rateLimited = 'محاولات كثيرة. حاول بعد قليل.';
  static const String childAlreadyLinked = 'هذا الطفل مرتبط بالمسجد بالفعل.';

  /// الأطفال
  static const String childNotFound = 'لم يُعثر على الطفل.';
  static const String duplicateChild = 'هذا الطفل مضاف مسبقاً.';

  /// المسابقة
  static const String noActiveCompetition = 'لا توجد مسابقة نشطة حالياً.';
  static const String competitionEnded = 'المسابقة انتهت.';
  static const String competitionAlreadyActive =
      'يوجد مسابقة نشطة بالفعل. أنهها أولاً.';
  static const String competitionPointsChanged =
      'تم تحديث نقاط الصلوات. ينطبق على الحضور القادم.';

  /// الحضور
  static const String attendanceAlreadyRecorded = 'تم تسجيل الحضور مسبقاً لهذه الصلاة.';
  static const String outsideAttendanceWindow = 'خارج نافذة تسجيل الحضور.';

  /// التصحيحات
  static const String correctionAlreadyPending =
      'يوجد طلب تصحيح معلق لهذه الصلاة.';
  static const String correctionDateTooOld =
      'لا يمكن طلب تصحيح لأكثر من 7 أيام.';

  /// تحويل رسالة Supabase إلى رسالة عربية
  static String fromSupabase(String? message) {
    if (message == null) return generic;
    final lower = message.toLowerCase();

    // Auth errors
    if (lower.contains('invalid login credentials')) return invalidCredentials;
    if (lower.contains('email already registered') || lower.contains('already been registered')) return emailAlreadyExists;
    if (lower.contains('password should be at least')) return weakPassword;
    if (lower.contains('email not confirmed')) return emailNotVerified;
    if (lower.contains('jwt') || lower.contains('token')) return sessionExpired;
    if (lower.contains('rate limit') || lower.contains('too many')) return rateLimited;

    // RLS errors
    if (lower.contains('new row violates row-level security') ||
        lower.contains('row-level security')) return permissionDenied;

    // Network errors
    if (lower.contains('network') || lower.contains('socket') ||
        lower.contains('clientexception') || lower.contains('connection refused')) return noInternet;
    if (lower.contains('timeout')) return timeout;

    // Unique constraint
    if (lower.contains('unique constraint') || lower.contains('duplicate key')) {
      return 'هذا العنصر موجود بالفعل.';
    }

    // Foreign key
    if (lower.contains('foreign key') || lower.contains('violates foreign key')) {
      return 'لا يمكن إتمام العملية — بيانات مرتبطة مفقودة.';
    }

    return message; // إذا لم نعرف الرسالة نُرجعها كما هي
  }
}
