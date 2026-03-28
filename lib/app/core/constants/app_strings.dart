/// كل النصوص العربية في التطبيق
class AppStrings {
  AppStrings._();

  // ─── عام ───
  static const String appName = 'صلاتي حياتي';
  static const String appTagline = 'تابع صلاة أبنائك بسهولة';

  // ─── Auth ───
  static const String login = 'تسجيل الدخول';
  static const String register = 'إنشاء حساب';
  static const String logout = 'تسجيل الخروج';
  static const String email = 'البريد الإلكتروني';
  static const String password = 'كلمة المرور';
  static const String confirmPassword = 'تأكيد كلمة المرور';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String resetPassword = 'إعادة تعيين كلمة المرور';
  static const String name = 'الاسم الكامل';
  static const String phone = 'رقم الهاتف';
  static const String orLoginWith = 'أو سجل دخول بـ';
  static const String dontHaveAccount = 'ليس لديك حساب؟';
  static const String alreadyHaveAccount = 'لديك حساب بالفعل؟';
  static const String loginWithGoogle = 'تسجيل بحساب Google';

  // ─── Onboarding ───
  static const String onboardingTitle1 = 'مرحباً بك في صلاتي حياتي ';
  static const String onboardingDesc1 =
      'منصة متكاملة لربط المسجد بالأسرة، لتشجيع الأجيال على المحافظة على الصلاة';
  static const String onboardingTitle2 = 'القدوة والتشجيع المستمر ';
  static const String onboardingDesc2 =
      'كن الداعم الأول! تكامل بين جهودنا لمتابعة حضور الأبناء وتحفيزهم نحو أداء الصلوات بشغف';
  static const String onboardingTitle3 = 'انطلق معنا! ';
  static const String onboardingDesc3 = 'أنشئ حسابك الآن، واختر دورك (إمام، مشرف، أو ولي أمر) لتبدأ الرحلة';
  static const String getStarted = 'ابدأ';
  static const String skip = 'تخطي';
  static const String alreadyHaveAccountQuestion = 'تملك حساب؟ سجل دخولك';

  // ─── اختيار الدور ───
  static const String chooseRole = 'اختر ما يناسبك';
  static const String roleParent = 'ولي أمر';
  static const String roleParentDesc = 'تابع صلاة أبنائك واحصل على تقارير';
  static const String roleImam = ' (مدير المسجد)';
  static const String roleImamDesc =
      'أنشئ مسجدك وأدِر المشرفين وتابع تقارير الحضور';
  static const String roleSupervisor = 'مشرف';
  static const String roleSupervisorDesc =
      'انضم بكوْد الدعوة من مدير المسجد، وسجّل حضور الطلاب';
  static const String welcomeMessage = 'مرحباً بك في تطبيق صلاتي';

  // ─── الصلوات ───
  static const String fajr = 'الفجر';
  static const String dhuhr = 'الظهر';
  static const String asr = 'العصر';
  static const String maghrib = 'المغرب';
  static const String isha = 'العشاء';
  static const String nextPrayer = 'الصلاة القادمة';
  static const String timeRemaining = 'الوقت المتبقي';
  static const String prayerInMosque = 'صلاة جماعة';
  static const String prayerAtHome = 'صلاة منزلية';
  static const String minutesRemaining = 'دقيقة';

  // ─── الحضور ───
  static const String attendance = 'الحضور';
  static const String present = 'حاضر';
  static const String absent = 'غائب';
  static const String todayAttendance = 'حضور اليوم';
  static const String recordAttendance = 'تسجيل الحضور';
  static const String scanQR = 'مسح QR';
  static const String studentNumber = 'رقم الطالب';
  static const String searchByName = 'بحث بالاسم';
  static const String finishAttendance = 'إنهاء التحضير';
  static const String attendanceRecorded = 'تم تسجيل الحضور ✅';
  static const String alreadyRecorded = 'تم تسجيله مسبقاً';
  static const String studentNotFound = 'لم يتم العثور على الطالب';

  // ─── المسجد ───
  static const String mosque = 'المسجد';
  static const String createMosque = 'إنشاء مسجد جديد';
  static const String joinMosque = 'الانضمام لمسجد';
  static const String mosqueCode = 'كود المسجد';
  static const String inviteCode = 'كود الدعوة';
  static const String mosqueName = 'اسم المسجد';
  static const String mosqueAddress = 'عنوان المسجد';
  static const String pendingApproval = 'طلبك قيد المراجعة';
  static const String pendingApprovalDesc = 'سيتم إعلامك فور الموافقة على طلبك';
  static const String pendingApprovalByAdmin =
      'مدير النظام ينظر في الطلبات ويوافق أو يرفض';
  static const String imamGateSubtitle =
      'أنشئ مسجدك أو انضم بكوْد — طلبك سيراجعه مدير النظام للموافقة';
  static const String mosqueApproved = 'تمت الموافقة على مسجدك!';
  static const String mosqueRejected = 'تم رفض طلبك';
  static const String adminMosqueRequests = 'طلبات المساجد';
  static const String adminMosqueRequestsDesc =
      'موافقة أو رفض طلبات إنشاء المساجد';
  static const String approve = 'موافقة';
  static const String reject = 'رفض';
  static const String primaryMosque = 'مسجد أساسي';
  static const String secondaryMosque = 'مسجد إضافي';

  // ─── المشرفين ───
  static const String supervisors = 'المشرفون';
  static const String imamDashboardTitle = 'لوحة مدير المسجد';
  static const String supervisorDashboardTitle = 'لوحة المشرف';
  static const String addSupervisor = 'إضافة مشرف';
  static const String removeSupervisor = 'إزالة المشرف';
  static const String shareInviteCode = 'مشاركة كود الدعوة';
  static const String copyCode = 'نسخ الكود';

  // ─── الأبناء ───
  static const String children = 'الأبناء';
  static const String addChild = 'إضافة ابن';
  static const String childName = 'اسم الابن';
  static const String childAge = 'العمر';
  static const String childCard = 'بطاقة الابن';
  static const String printCard = 'طباعة البطاقة';
  static const String shareCard = 'مشاركة البطاقة';
  static const String regenerateQR = 'إعادة توليد QR';
  static const String students = 'الطلاب';

  // ─── التحفيز ───
  static const String points = 'النقاط';
  static const String streak = 'سلسلة';
  static const String days = 'يوم';
  static const String leaderboard = 'لوحة الشرف';
  static const String rank = 'الترتيب';
  static const String badges = 'الشارات';
  static const String rewards = 'الجوائز';
  static const String addReward = 'إضافة جائزة';
  static const String rewardTitle = 'عنوان الجائزة';
  static const String targetPoints = 'النقاط المطلوبة';
  static const String claimed = 'تم الحصول عليها!';
  static const String congratulations = 'مبروك! 🎉';
  static const String pointsMosque = '10 نقاط';
  static const String pointsHomeFajr = '5 نقاط';
  static const String pointsHome = '3 نقاط';

  // ─── التقارير ───
  static const String reports = 'التقارير';
  static const String weekly = 'أسبوعي';
  static const String monthly = 'شهري';
  static const String yearly = 'سنوي';
  static const String mosqueVsHome = 'جماعة مقابل منزل';

  // ─── التصحيح ───
  static const String correctionRequest = 'طلب تصحيح';
  static const String sendCorrection = 'إرسال طلب تصحيح';
  static const String correctionNote = 'ملاحظة';
  static const String correctionPending = 'قيد المراجعة';
  static const String correctionApproved = 'تمت الموافقة ✅';
  static const String correctionRejected = 'تم الرفض ❌';

  // ─── الملاحظات ───
  static const String notes = 'الملاحظات';
  static const String sendNote = 'إرسال ملاحظة';
  static const String quickNotes = 'ملاحظات سريعة';
  // رسائل جاهزة
  static const String noteExcellent = 'ابنك ممتاز ماشاء الله ⭐';
  static const String noteImproved = 'ابنك مستواه تحسن كثيراً 👍';
  static const String noteNeedsEncouragement = 'يحتاج تشجيع أكثر 💪';
  static const String noteAbsentOften = 'غاب أكثر من مرة ⚠️';
  static const String customMessage = 'رسالة مخصصة';

  // ─── الإعدادات ───
  static const String settings = 'الإعدادات';
  static const String profile = 'الملف الشخصي';
  static const String notifications = 'الإشعارات';
  static const String aboutApp = 'عن التطبيق';
  static const String contactUs = 'تواصل معنا';
  static const String darkMode = 'الوضع الليلي';

  // ─── رسائل عامة ───
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String confirm = 'تأكيد';
  static const String send = 'إرسال';
  static const String done = 'تم';
  static const String next = 'التالي';
  static const String back = 'رجوع';
  static const String search = 'بحث';
  static const String filter = 'فلتر';
  static const String all = 'الكل';
  static const String loading = 'جاري التحميل...';
  static const String noData = 'لا توجد بيانات';
  static const String retry = 'إعادة المحاولة';
  static const String yes = 'نعم';
  static const String no = 'لا';

  // ─── رسائل الخطأ ───
  static const String errorGeneral = 'حدث خطأ، يرجى المحاولة لاحقاً';
  static const String errorNoInternet = 'لا يوجد اتصال بالإنترنت';
  static const String errorInvalidEmail = 'البريد الإلكتروني غير صحيح';
  static const String errorWeakPassword = 'كلمة المرور ضعيفة';
  static const String errorPasswordMismatch = 'كلمة المرور غير متطابقة';
  static const String errorFieldRequired = 'هذا الحقل مطلوب';
  static const String errorInvalidCode = 'الكود غير صحيح';
  static const String errorUserNotFound = 'المستخدم غير موجود';

  // ─── الحالة بدون إنترنت ───
  static const String offlineMode = '⚡ وضع عدم الاتصال';
  static const String offlineMessage = 'البيانات ستُزامن عند عودة الإنترنت';
  static const String syncing = 'جاري المزامنة...';
  static const String syncComplete = 'تمت المزامنة ✅';

  // ─── أحاديث وآيات عن الصلاة ───
  static const List<String> prayerQuotes = [
    'قال ﷺ: "العهد الذي بيننا وبينهم الصلاة، فمن تركها فقد كفر"',
    'قال ﷺ: "صلاة الجماعة أفضل من صلاة الفذ بسبع وعشرين درجة"',
    'قال ﷺ: "من صلى الفجر في جماعة فكأنما قام الليل كله"',
    'قال ﷺ: "أقرب ما يكون العبد من ربه وهو ساجد"',
    '﴿إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا﴾',
    '﴿وَأَقِيمُوا الصَّلَاةَ وَآتُوا الزَّكَاةَ وَارْكَعُوا مَعَ الرَّاكِعِينَ﴾',
    'قال ﷺ: "إن أول ما يُحاسب به العبد يوم القيامة من عمله: صلاته"',
    'قال ﷺ: "من حافظ على الصلوات الخمس كان له نوراً يوم القيامة"',
    '﴿حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَىٰ وَقُومُوا لِلَّهِ قَانِتِينَ﴾',
    'قال ﷺ: "بشّر المشّائين في الظُلَم إلى المساجد بالنور التام يوم القيامة"',
  ];
}
