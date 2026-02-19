# خطة صفحات الإمام الكاملة

مرجع واحد لتنفيذ كل شاشات وويدجتات الإمام حسب المواصفات المطلوبة. يُنفَّذ بالترتيب أدناه.

---

## الهيكل النهائي

```
lib/app/features/imam/presentation/
├── screens/
│   ├── imam_dashboard_screen.dart              ✅ موجود
│   ├── prayer_points_settings_screen.dart      ✅ موجود
│   ├── imam_corrections_screen.dart            🔲
│   ├── imam_competitions_screen.dart           🔲
│   ├── imam_mosque_settings_screen.dart        🔲
│   ├── imam_attendance_report_screen.dart      🔲
│   └── imam_supervisors_performance_screen.dart 🔲
└── widgets/
    ├── imam_stat_card.dart                     🔲
    ├── correction_tile.dart                     🔲
    ├── competition_card.dart                    🔲
    └── supervisor_performance_tile.dart        🔲
```

---

## ترتيب التنفيذ (لـ Cursor أو أي مطوّر)

| # | المهمة | الملف | التبعيات |
|---|--------|--------|-----------|
| 1 | ويجت بطاقة إحصائية | `widgets/imam_stat_card.dart` | لا |
| 2 | ويجت طلب تصحيح | `widgets/correction_tile.dart` | لا |
| 3 | شاشة طلبات التصحيح | `screens/imam_corrections_screen.dart` | correction_tile |
| 4 | ويجت مسابقة | `widgets/competition_card.dart` | لا |
| 5 | شاشة المسابقات | `screens/imam_competitions_screen.dart` | competition_card |
| 6 | شاشة إعدادات المسجد | `screens/imam_mosque_settings_screen.dart` | ImamBloc (موجود) |
| 7 | ويجت أداء مشرف | `widgets/supervisor_performance_tile.dart` | لا |
| 8 | شاشة أداء المشرفين | `screens/imam_supervisors_performance_screen.dart` | supervisor_performance_tile، ImamBloc |
| 9 | شاشة تقرير الحضور | `screens/imam_attendance_report_screen.dart` | imam_stat_card، ImamBloc |
| 10 | تحديث المسارات والربط | `app_router.dart` + `imam_dashboard_screen.dart` | كل الشاشات الجديدة |

---

## مواصفات كل ملف (لنسخها في الـ Prompt)

### 1. `imam_stat_card.dart`

- **المسار:** `lib/app/features/imam/presentation/widgets/imam_stat_card.dart`
- **نوع:** StatelessWidget (أو stateful إذا احتجت onTap).
- **المدخلات:**
  - `String title`
  - `String value`
  - `IconData icon`
  - `Color? color` (اختياري)
  - `VoidCallback? onTap` (اختياري)
- **الشكل:**
  - Container بخلفية `AppColors.primarySurface`
  - `borderRadius`: `AppDimensions.radiusMD`
  - أيقونة + قيمة (نص كبير) + عنوان صغير
  - إن وُجد `onTap`: InkWell أو GestureDetector
- **يُستخدم في:** لوحة الإمام، تقرير الحضور، أداء المشرفين.

---

### 2. `correction_tile.dart`

- **المسار:** `lib/app/features/imam/presentation/widgets/correction_tile.dart`
- **المدخلات:**
  - `Map<String, dynamic> correction` (يحتوي `children(name)`, `prayer`, `prayer_date`, `note`, `status`)
  - `bool isPending`
  - `bool isLoading`
  - `VoidCallback? onApprove`
  - `VoidCallback? onReject`
- **الشكل:**
  - Card مع ListTile (أو محتوى مكافئ).
  - العنوان: اسم الطفل + الصلاة + التاريخ (استخدم `Prayer.fromString(...).nameAr` واسم الطفل من `correction['children']` إن وُجد).
  - الـ subtitle: الملاحظة (`note`).
  - trailing:
    - إن `isPending`: زر ✅ أخضر (onApprove) + زر ❌ أحمر (onReject).
    - إن `!isPending`: Chip يعرض الحالة (مقبول/مرفوض) بلون مناسب.
    - إن `isLoading`: CircularProgressIndicator.
- **الاستيراد:** `AppColors`, `AppDimensions`, `app_enums.dart` (Prayer).

---

### 3. `imam_corrections_screen.dart`

- **المسار:** `lib/app/features/imam/presentation/screens/imam_corrections_screen.dart`
- **المسار في التطبيق:** `/imam/corrections/:mosqueId`
- **المدخلات:** `String mosqueId` (من `state.pathParameters['mosqueId']!`).
- **الحالة:**
  - `TabController` بتبويبين: **"معلقة"** | **"مُعالجة"**.
  - `Map<String, bool> _loadingMap` (مفتاح = correction id).
- **تبويب "معلقة":**
  - `FutureBuilder` → `CorrectionRepository.getPendingForMosque(mosqueId)`.
  - لكل عنصر: `CorrectionTile` مع `isPending: true`.
  - `onApprove`: استدعاء `CorrectionRepository.approveRequest(id)` ثم تحديث القائمة (إزالة من القائمة أو إعادة تحميل).
  - `onReject`: حوار يسأل عن السبب (اختياري) ثم `CorrectionRepository.rejectRequest(id, reason)`.
- **تبويب "مُعالجة":**
  - `FutureBuilder` → `ImamRepository.getProcessedCorrections(mosqueId)`.
  - لكل عنصر: `CorrectionTile` مع `isPending: false`.
- **AppBar:** عنوان "طلبات التصحيح" + زر refresh.
- **حالة فارغة:** رسالة "لا توجد طلبات تصحيح" مع أيقونة.
- **التوجيه:** RTL، استخدم `Directionality` أو الـ theme.

---

### 4. `competition_card.dart`

- **المسار:** `lib/app/features/imam/presentation/widgets/competition_card.dart`
- **المدخلات:**
  - `Map<String, dynamic> competition` (`id`, `name_ar`, `start_date`, `end_date`, `is_active`)
  - `bool isLoading`
  - `VoidCallback? onActivate`
  - `VoidCallback? onDeactivate`
  - `VoidCallback? onViewLeaderboard`
- **الشكل:**
  - Card.
  - العنوان: `name_ar`.
  - subtitle: تاريخ البداية ← تاريخ النهاية (تنسيق واضح).
  - trailing: Switch أو زر "تفعيل"/"إيقاف" حسب `is_active` (عند التحميل: تعطيل أو CircularProgressIndicator).
  - زر "الترتيب" يفعّل `onViewLeaderboard` (القائمة نفسها تفتح من الشاشة الأب كـ BottomSheet).
  - إن `is_active`: حدود خضراء أو badge "نشطة".

---

### 5. `imam_competitions_screen.dart`

- **المسار:** `lib/app/features/imam/presentation/screens/imam_competitions_screen.dart`
- **المسار في التطبيق:** `/imam/competitions/:mosqueId`
- **المدخلات:** `String mosqueId`.
- **الحالة:**
  - `List<Map<String, dynamic>> _competitions`
  - `Map<String, bool> _loadingMap` (مفتاح = competition id)
  - `bool _creating = false`
- **عند الفتح:** `CompetitionRepository.getAllForMosque(mosqueId)` وتعبئة `_competitions`.
- **AppBar:** عنوان "المسابقات" + زر إضافة (FAB أو action) لإنشاء مسابقة.
- **إنشاء مسابقة:**
  - BottomSheet أو Dialog: اسم المسابقة (`name_ar`)، تاريخ البداية (DatePicker)، تاريخ النهاية (DatePicker)، زر "إنشاء".
  - عند الحفظ: `CompetitionRepository.create(mosqueId, nameAr, startDate, endDate)` ثم إعادة تحميل القائمة.
- **القائمة:** `ListView` من `CompetitionCard`.
  - `onActivate` → `CompetitionRepository.activate(id)` → reload.
  - `onDeactivate` → `CompetitionRepository.deactivate(id)` → reload.
  - `onViewLeaderboard` → BottomSheet يعرض:
    - `FutureBuilder` → `CompetitionRepository.getLeaderboard(competitionId)`.
    - كل عنصر من `getLeaderboard` يحتوي على الحقول: `child_name`, `total_points`, `rank` — استخدمها مباشرة في العرض.
    - قائمة: رقم الترتيب (من `rank`) + اسم الطفل (`child_name`) + النقاط (`total_points`).
    - أيقونات 🥇🥈🥉 للأوائل الثلاثة.
- **حالة فارغة:** "لا توجد مسابقات، أنشئ أولى مسابقاتك!" + زر إنشاء.

---

### 6. `imam_mosque_settings_screen.dart`

- **المسار:** `lib/app/features/imam/presentation/screens/imam_mosque_settings_screen.dart`
- **المسار في التطبيق:** `/imam/mosque/:mosqueId/settings`
- **المدخلات:** `String mosqueId`, `MosqueModel mosque` (من `state.extra`).
- **الحالة:**
  - `TextEditingController` للاسم (قيمة أولية: `mosque.name`)
  - `TextEditingController` للعنوان (قيمة أولية: `mosque.address ?? ''`)
  - `TextEditingController` لنافذة الحضور (قيمة أولية: `(mosque.attendanceWindowMinutes ?? 30).toString()`)
  - `bool _saving = false`
- **المحتوى:**
  - Form بـ `GlobalKey<FormState>`.
  - حقل: اسم المسجد (validator: مطلوب).
  - حقل: العنوان.
  - حقل: نافذة الحضور بالدقائق (`keyboardType: number`, validator: بين 1 و 120).
  - ملاحظة: "نافذة الحضور هي المدة التي يُقبل فيها تسجيل الحضور بعد وقت الصلاة."
  - زر "حفظ" → إذا النموذج صالح: `context.read<ImamBloc>().add(UpdateMosqueSettings(mosqueId: mosqueId, name: ..., address: ..., attendanceWindowMinutes: ...))`.
- **BlocProvider:** تأكد أن الشاشة داخل `BlocProvider<ImamBloc>` (أو تأتي من الأعلى).
- **BlocListener:**
  - `MosqueSettingsUpdated` → SnackBar "تم الحفظ" + `context.pop()`.
  - `ImamError` → SnackBar بالخطأ.
- **AppBar:** عنوان "إعدادات المسجد".

---

### 7. `supervisor_performance_tile.dart`

- **المسار:** `lib/app/features/imam/presentation/widgets/supervisor_performance_tile.dart`
- **المدخلات:**
  - `String name`
  - `String? email`
  - `int todayRecords`
  - `int totalStudents` (لحساب النسبة؛ تجنّب القسمة على صفر).
- **الشكل:**
  - ListTile (أو صف مخصص).
  - leading: أيقونة شخص.
  - title: الاسم.
  - subtitle: "سجّل X حضور اليوم".
  - trailing: `LinearProgressIndicator` بنسبة `totalStudents > 0 ? todayRecords / totalStudents : 0` مع نص النسبة المئوية.

---

### 8. `imam_supervisors_performance_screen.dart`

- **المسار:** `lib/app/features/imam/presentation/screens/imam_supervisors_performance_screen.dart`
- **المسار في التطبيق:** `/imam/mosque/:mosqueId/supervisors-performance`
- **المدخلات:** `String mosqueId`.
- **الحالة:**
  - `List<Map<String, dynamic>>? _supervisors`
  - `int? _totalStudents`
  - `bool _loading = false`
- **عند الفتح:**
  - إما استدعاء `ImamBloc.add(LoadSupervisorsPerformance(mosqueId))` و`SupervisorRepository.getMosqueStudents(mosqueId)` ثم أخذ `.length` لـ `_totalStudents`.
  - أو تحميل الأداء مباشرة من `ImamRepository.getSupervisorsPerformance(mosqueId)` وطلاب المسجد من `SupervisorRepository.getMosqueStudents(mosqueId)` (بدون Bloc).
- **BlocListener (إن استخدمت Bloc):** `SupervisorsPerformanceLoaded` → تحديث `_supervisors`.
- **AppBar:** عنوان "أداء المشرفين"، subtitle: "اليوم — [التاريخ]"، زر refresh.
- **الملخص في الأعلى:** Row من `ImamStatCard`: إجمالي المشرفين، إجمالي التسجيلات اليوم.
- **القائمة:** `ListView` من `SupervisorPerformanceTile`، مرتبة تنازلياً حسب `today_records`.
- **حالة فارغة:** "لا يوجد مشرفون في هذا المسجد".

---

### 9. `imam_attendance_report_screen.dart`

- **المسار:** `lib/app/features/imam/presentation/screens/imam_attendance_report_screen.dart`
- **المسار في التطبيق:** `/imam/mosque/:mosqueId/attendance-report`
- **المدخلات:** `String mosqueId`.
- **الحالة:**
  - `DateTime _fromDate` = أول الشهر الحالي
  - `DateTime _toDate` = اليوم
  - `List<Map<String, dynamic>>? _records`
  - `bool _loading = false`
  - `String? _error`
- **عند الفتح:** تحميل التقرير بالتواريخ الافتراضية: `ImamBloc.add(LoadAttendanceReport(mosqueId: mosqueId, fromDate: _fromDate, toDate: _toDate))`.
- **BlocListener:** `AttendanceReportLoaded` → تحديث `_records`؛ `ImamError` → `_error`.
- **AppBar:** عنوان "تقرير الحضور"، زر تصفية (filter) يفتح BottomSheet:
  - DatePicker "من"، DatePicker "إلى"، زر "تطبيق" → إعادة إرسال `LoadAttendanceReport` ثم إغلاق الـ sheet.
- **الملخص (Row من ImamStatCard):**
  - إجمالي السجلات.
  - عدد الأطفال المختلفين (distinct `child_id`).
  - أعلى يوم حضوراً: اليوم (`prayer_date`) الذي يتكرر أكثر في `_records` — احسبه بتجميع السجلات حسب `prayer_date` (groupBy) ثم اختيار المجموعة ذات الحجم الأكبر.
- **القائمة:** تجميع حسب `prayer_date` (مثلاً `ListView` مع عناوين للتواريخ)، ثم لكل سجل: اسم الطفل + الصلاة (`Prayer.fromString(r['prayer']).nameAr`) + النقاط.
- **الحالات:** تحميل → CircularProgressIndicator؛ خطأ → رسالة + زر retry؛ فارغ → "لا توجد سجلات للفترة المحددة".

---

## 10. المسارات (Router)

- **الملف:** `lib/app/core/router/app_router.dart`
- **التعديلات:**
  1. استبدال أو إضافة المسارات التالية بحيث تشير للشاشات الجديدة:

```dart
// طلبات التصحيح — شاشة الإمام الجديدة
GoRoute(
  path: '/imam/corrections/:mosqueId',
  name: 'imamCorrections',
  builder: (context, state) => ImamCorrectionsScreen(
    mosqueId: state.pathParameters['mosqueId']!,
  ),
),
// المسابقات — شاشة الإمام الجديدة
GoRoute(
  path: '/imam/competitions/:mosqueId',
  name: 'imamCompetitions',
  builder: (context, state) => ImamCompetitionsScreen(
    mosqueId: state.pathParameters['mosqueId']!,
  ),
),
// إعدادات المسجد
GoRoute(
  path: '/imam/mosque/:mosqueId/settings',
  name: 'imamMosqueSettings',
  builder: (context, state) => ImamMosqueSettingsScreen(
    mosqueId: state.pathParameters['mosqueId']!,
    mosque: state.extra as MosqueModel,
  ),
),
// تقرير الحضور
GoRoute(
  path: '/imam/mosque/:mosqueId/attendance-report',
  name: 'imamAttendanceReport',
  builder: (context, state) => ImamAttendanceReportScreen(
    mosqueId: state.pathParameters['mosqueId']!,
  ),
),
// أداء المشرفين
GoRoute(
  path: '/imam/mosque/:mosqueId/supervisors-performance',
  name: 'imamSupervisorsPerformance',
  builder: (context, state) => ImamSupervisorsPerformanceScreen(
    mosqueId: state.pathParameters['mosqueId']!,
  ),
),
```

  2. إضافة استيراد الشاشات الجديدة و`MosqueModel` إن لزم.
  3. شاشات تقرير الحضور وأداء المشرفين وإعدادات المسجد تحتاج `BlocProvider<ImamBloc>` — لفّ كل منها في الـ builder بـ `BlocProvider(create: (_) => sl<ImamBloc>(), child: ImamXxxScreen(...))` كما في مسار `imamPrayerPoints`، أو وفر الـ Bloc من الشاشة الأب.

---

## 11. ربط لوحة الإمام بالشاشات الجديدة

- **الملف:** `lib/app/features/imam/presentation/screens/imam_dashboard_screen.dart`
- **التعديلات:**
  - استبدال الانتقال إلى طلبات التصحيح من `context.push('/imam/corrections/${mosque!.id}')` إن كان يشير لشاشة أخرى — التأكد أنه يفتح `ImamCorrectionsScreen` (نفس المسار).
  - إضافة روابط في القائمة الجانبية و/أو أزرار الإجراءات لـ:
    - إعدادات المسجد: `context.push('/imam/mosque/${mosque.id}/settings', extra: mosque)`
    - تقرير الحضور: `context.push('/imam/mosque/${mosque.id}/attendance-report')`
    - أداء المشرفين: `context.push('/imam/mosque/${mosque.id}/supervisors-performance')`
  - (اختياري) استخدام `ImamStatCard` في لوحة المدير لعرض الإحصائيات بدل الـ chips الحالية.

---

## 12. التحقق النهائي

- [ ] كل الويدجتات في `presentation/widgets/` وتستورد الثيمات والأبعاد من المشروع.
- [ ] كل الشاشات تعمل مع المسارات المحددة و`pathParameters` و`extra` حيث مطلوب.
- [ ] طلبات التصحيح: قبول ورفض يعملان وتحديث القائمة دون أخطاء.
- [ ] المسابقات: إنشاء، تفعيل، إيقاف، وعرض الترتيب في الـ BottomSheet.
- [ ] إعدادات المسجد: الحفظ يحدّث الـ Bloc ويُظهر SnackBar ثم يعود للخلف.
- [ ] تقرير الحضور: فلتر التواريخ والملخص والقائمة المجمعة يعملان.
- [ ] أداء المشرفين: القائمة والملخص والنسبة المئوية تظهر بشكل صحيح.
- [ ] اتجاه RTL والنصوص العربية متسقة في كل الشاشات.

---

## مراجع سريعة

- **ImamBloc (موجود):** `LoadMosqueStats`, `LoadAttendanceReport`, `LoadSupervisorsPerformance`, `UpdateMosqueSettings`, `UpdateMosquePrayerPoints`, `CancelAttendanceByImam`.
- **الحالات:** `MosqueStatsLoaded`, `AttendanceReportLoaded`, `SupervisorsPerformanceLoaded`, `MosqueSettingsUpdated`, `ImamActionSuccess`, `ImamError`.
- **المستودعات:** \n+  - `ImamRepository`: `getMosqueStats`, `getAttendanceReport`, `getSupervisorsPerformance`, `getProcessedCorrections`, `getPrayerPointsForMosque`, `updateMosquePrayerPoints`, `updateMosqueSettings`, `cancelAttendance`.\n+  - `CorrectionRepository`: `getPendingForMosque`, `approveRequest`, `rejectRequest`.\n+  - `CompetitionRepository`: `create`, `activate`, `deactivate`, `getActive`, `getAllForMosque`, `getLeaderboard`.\n+  - `SupervisorRepository`: `getMosqueStudents`, `getTodayAttendanceCount`, `getRecordedChildIdsForPrayer`, `recordAttendance`.\n+  كلها مسجّلة في `injection_container`.
- **النماذج:** `MosqueModel` (فيه `attendanceWindowMinutes`)، `CorrectionRequestModel` إن وُجد، أو استخدام `Map` من الـ repository كما في المواصفات.

بعد إكمال كل بند، حدّث الهيكل أعلاه من 🔲 إلى ✅ في هذا الملف.
