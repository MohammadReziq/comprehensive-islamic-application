# كل ما يستطيع الإمام فعله الآن — مواصفات حرفية لبناء صفحات الإمام

هذه الوثيقة تذكر **حرفياً** كل شيء يستطيع الإمام (مدير المسجد، أي المستخدم الذي له دور `imam` ويكون **مالك المسجد** `owner` في جدول `mosque_members` و`mosques.owner_id`) أن يفعله في النظام حالياً — للتوجيه عند بناء أو إعادة بناء صفحات الإمام.

---

## 1. التوجيه والمسارات (Routes)

- بعد تسجيل الدخول: إذا كان `users.role = imam` أو `supervisor` يُوجّه إلى `/mosque`.
- في **بوابة المسجد** (`/mosque`): إذا كان المستخدم مالك مسجد معتمد (`mosques.owner_id = user.id` و`status = approved`) يُوجّه إلى `/imam/dashboard`؛ وإلا إلى `/supervisor/dashboard`.

### مسارات يستخدمها الإمام فقط أو مع المشرف

| المسار | الاسم | الشاشة/الاستخدام |
|--------|--------|-------------------|
| `/mosque` | mosque | بوابة المسجد (إنشاء/انضمام) — يحدد هل إمام أو مشرف |
| `/mosque/create` | mosqueCreate | إنشاء مسجد جديد |
| `/mosque/join` | mosqueJoin | الانضمام بكوْد الدعوة (للمشرفين) |
| `/imam/dashboard` | imamDashboard | **لوحة مدير المسجد** — الصفحة الرئيسية للإمام |
| `/supervisor/scan` | supervisorScan | مسح QR / تسجيل الحضور (الإمام يستخدمها أيضاً) |
| `/supervisor/students` | supervisorStudents | قائمة طلاب المسجد |
| `/supervisor/child/:id` | supervisorChildProfile | صفحة ملف طفل في المسجد |
| `/supervisor/notes/send/:mosqueId` | supervisorNotesSend | إرسال ملاحظة لطلاب المسجد |
| `/imam/corrections/:mosqueId` | imamCorrections | طلبات التصحيح للمسجد (مراجعة/قبول/رفض) |
| `/imam/competitions/:mosqueId` | imamCompetitions | إدارة المسابقات (إنشاء، تفعيل، إيقاف، ترتيب) |
| `/imam/mosque/:mosqueId/prayer-points` | imamPrayerPoints | إعداد نقاط الصلوات للمسجد |

---

## 2. لوحة مدير المسجد (`/imam/dashboard`) — المحتوى والإجراءات

- **مصدر البيانات:** المسجد المعتمد الأول للمستخدم من `MosqueBloc` (مساجدي التي `status = approved`).
- **ما يُعرض:**
  - بطاقة المسجد: الاسم، **كود المسجد** (لربط الأطفال من ولي الأمر)، **كود الدعوة** (لدعوة المشرفين) — مع زر نسخ لكل كود.
  - **طلبات الانضمام:** قائمة طلبات `mosque_join_requests` المعلقة للمسجد (مع أسماء/إيميل عبر RPC).
  - **المشرفون:** قائمة أعضاء المسجد بدور مشرف (عبر RPC `get_mosque_supervisors_with_names`).
  - **الصلاة القادمة:** من `PrayerTimesService` (الاسم، الوقت، "بعد X دقيقة").
  - **إحصائيات سريعة:** حضور اليوم، عدد طلاب المسجد (من `SupervisorRepository`).
  - **أزرار إجراءات:** التحضير، الطلاب، طلبات التصحيح، الملاحظات، المسابقات، نقاط الصلوات (كلها تنتقل للمسارات أعلاه).

- **إجراءات من لوحة المدير:**
  - **موافقة على طلب انضمام:** استدعاء `MosqueRepository.approveJoinRequest(requestId)`.
  - **رفض طلب انضمام:** استدعاء `MosqueRepository.rejectJoinRequest(requestId)`.
  - **إزالة مشرف من المسجد:** استدعاء `MosqueRepository.removeMosqueMember(mosqueId, userId)` بعد تأكيد.

- **القائمة الجانبية (Drawer):** لوحة المدير، التحضير، الطلاب، طلبات التصحيح، الملاحظات، المسابقات، نقاط الصلوات، تسجيل الخروج.

- **الشريط السفلي:** تبويبان — لوحة المدير، الملف الشخصي.

---

## 3. المستودعات (Repositories) والعمليات حسب الميزة

### 3.1 المسجد (MosqueRepository)

| العملية | الوصف |
|---------|--------|
| `createMosque(name, address?)` | إنشاء مسجد جديد — المستخدم الحالي يصبح `owner_id` ويدخل في `mosque_members` بدور `owner`. |
| `getMyMosques()` | مساجدي (كمالك أو مشرف). |
| `getPendingJoinRequests(mosqueId)` | طلبات الانضمام المعلقة لمسجدي (RPC `get_pending_join_requests_with_names`). |
| `approveJoinRequest(requestId)` | موافقة على طلب انضمام → إدراج في `mosque_members` بدور `supervisor` وتحديث الطلب. |
| `rejectJoinRequest(requestId)` | رفض طلب انضمام (تحديث حالة الطلب). |
| `getMosqueSupervisors(mosqueId)` | قائمة مشرفي المسجد مع الأسماء (RPC `get_mosque_supervisors_with_names`). |
| `removeMosqueMember(mosqueId, userId)` | إزالة مشرف من المسجد (حذف من `mosque_members`). |
| `updateMosqueLocation(mosqueId, lat, lng)` | تحديث موقع المسجد (لأوقات الصلاة). |
| `updateMosqueSettings(mosqueId, name?, address?, lat?, lng?, attendanceWindowMinutes?)` | تحديث إعدادات المسجد. |

### 3.2 إحصائيات وإعدادات الإمام (ImamRepository)

| العملية | الوصف |
|---------|--------|
| `getMosqueStats(mosqueId)` | إحصائيات: عدد الطلاب، عدد المشرفين، حضور اليوم، طلبات التصحيح المعلقة، طلبات الانضمام المعلقة. |
| `getAttendanceReport(mosqueId, fromDate, toDate)` | تقرير حضور المسجد لفترة (من جدول `attendance` مع `children(name)`). |
| `getSupervisorsPerformance(mosqueId)` | أداء المشرفين اليوم: عدد سجلات الحضور التي سجّلها كل مشرف اليوم (RPC `get_mosque_supervisors_with_names` + استعلام حضور). |
| `getProcessedCorrections(mosqueId, limit?)` | طلبات التصحيح المعالجة (مقبولة/مرفوضة) للمسجد. |
| `getPrayerPointsForMosque(mosqueId)` | جلب نقاط كل صلاة من `mosques.prayer_config` (افتراضي 10). |
| `updateMosquePrayerPoints(mosqueId, points)` | تحديث نقاط الصلوات في `mosques.prayer_config`. |
| `updateMosqueSettings(...)` | نفس إعدادات المسجد (الاسم، العنوان، الموقع، نافذة الحضور) — مذكورة أعلاه أيضاً. |
| `cancelAttendance(attendanceId)` | إلغاء حضور (RPC `cancel_attendance`) — **الإمام يلغي أي حضور في مسجده بدون قيد زمني** (المشرف له قيد زمني). |

### 3.3 المشرف/التحضير (SupervisorRepository) — الإمام يستخدمها

| العملية | الوصف |
|---------|--------|
| `getMosqueStudents(mosqueId)` | طلاب المسجد (من `mosque_children` + `children`، النشطون فقط). |
| `getTodayAttendanceCount(mosqueId)` | عدد سجلات الحضور اليوم للمسجد. |
| `recordAttendance(mosqueId, childId, prayer, date)` | تسجيل حضور طفل لصلاة في المسجد (مع التحقق من النافذة الزمنية ونقاط الصلوات). |
| (وغيرها للتحضير والمسح حسب الشاشات) | |

### 3.4 طلبات التصحيح (CorrectionRepository)

| العملية | الوصف |
|---------|--------|
| `getPendingForMosque(mosqueId)` | طلبات التصحيح المعلقة للمسجد. |
| `approveRequest(requestId)` | موافقة على طلب تصحيح (RPC `approve_correction_request` — تُسجّل الحضور وتحدّث الطلب). |
| `rejectRequest(requestId, reason?)` | رفض طلب تصحيح (تحديث الحالة و`reviewed_by`, `reviewed_at`). |

### 3.5 المسابقات (CompetitionRepository)

| العملية | الوصف | ملاحظة |
|---------|--------|--------|
| `create(mosqueId, nameAr, startDate, endDate)` | إنشاء مسابقة (غير نشطة). | **فقط الإمام (owner)** — يتحقق من `mosque_members.role = 'owner'`. |
| `activate(competitionId)` | تفعيل مسابقة (RPC `activate_competition` توقف النشطة ثم تفعّل الجديدة). | فقط الإمام. |
| `deactivate(competitionId)` | إيقاف مسابقة. | فقط الإمام. |
| `getActive(mosqueId)` | المسابقة النشطة للمسجد. | قراءة. |
| `getAllForMosque(mosqueId)` | كل مسابقات المسجد. | قراءة. |
| `getLeaderboard(competitionId)` | ترتيب الأطفال في مسابقة (نقاط من حضور مرتبط بالمسابقة). | قراءة. |

### 3.6 الملاحظات (NotesRepository)

| العملية | الوصف |
|---------|--------|
| `sendNote(childId, mosqueId, message)` | إرسال ملاحظة لولي أمر طفل (الإمام والمشرف يستخدمانها). |

### 3.7 الإعلانات (AnnouncementRepository)

| العملية | الوصف |
|---------|--------|
| `create(mosqueId, title, body, isPinned?)` | إنشاء إعلان. | **في DB السياسة تعتمد `sender_id`** — إن كان الجدول يستخدم `created_by` فقط يلزم توافق التطبيق مع الـ RLS. |
| `getForMosque(mosqueId, limit?)` | جلب إعلانات المسجد. |
| `update(announcementId, title?, body?, isPinned?)` | تعديل إعلان. |
| `delete(announcementId)` | حذف إعلان. |
| `togglePin(announcementId, isPinned)` | تثبيت/إلغاء تثبيت. |

---

## 4. الشاشات المخصصة للإمام (حالياً)

| الشاشة | الملف | الوظيفة المختصرة |
|--------|--------|-------------------|
| لوحة مدير المسجد | `imam_dashboard_screen.dart` | عرض المسجد، الأكواد، طلبات الانضمام، المشرفون، إجراءات سريعة، إحصائيات يومية. |
| إعداد نقاط الصلوات | `prayer_points_settings_screen.dart` | عرض/تعديل نقاط كل صلاة للمسجد (ImamBloc + ImamRepository). |
| طلبات التصحيح | `CorrectionsListScreen` مع `mosqueId` من مسار الإمام | عرض طلبات المسجد وقبول/رفض. |
| إدارة المسابقات | `ManageCompetitionScreen` مع `mosqueId` من مسار الإمام | إنشاء، تفعيل، إيقاف، وعرض الترتيب. |
| التحضير | `ScannerScreen` | مسح QR / تسجيل الحضور (مشترك مع المشرف). |
| الطلاب | `StudentsScreen` | قائمة طلاب المسجد. |
| إرسال ملاحظة | `SendNoteScreen` مع `mosqueId` | اختيار طفل وإرسال ملاحظة. |

---

## 5. صلاحيات قاعدة البيانات (RLS) — ملخص ما يخص المالك (الإمام)

- **mosques:** قراءة المعتمد أو مساجدي؛ إنشاء (مع `owner_id = أنا`)؛ تحديث إذا `owner_id = أنا`.
- **mosque_members:** قراءة أعضاء مساجدي؛ إدراج أعضاء في مساجد أنا مالكها؛ حذف أعضاء من مساجد أنا مالكها.
- **mosque_join_requests:** قراءة وتحديث طلبات مساجد أنا مالكها (للموافقة/الرفض).
- **attendance:** الإدراج (تسجيل الحضور) للمشرفين/الإمام؛ RPC `cancel_attendance` تسمح للإمام (owner) بإلغاء أي حضور في مسجده بدون قيد زمني.
- **correction_requests:** قراءة طلبات مسجدي؛ التحديث (مراجعة) عبر RLS للمشرفين/مالك المسجد؛ RPC `approve_correction_request` تتحقق من أن المستدعي owner المسجد.
- **competitions:** كل العمليات (CRUD) للمساجد التي أنا `owner_id` لها.
- **announcements:** إنشاء إعلان إذا أنا owner في المسجد و`sender_id = أنا`؛ تعديل/حذف إذا `sender_id = أنا` (أو سياسات محدثة لـ owner).
- **notes:** إدراج ملاحظة (مرسل = أنا) للمشرفين/الإمام.
- **RPCs:** `get_mosque_supervisors_with_names`, `get_pending_join_requests_with_names` — تُرجع بيانات فقط إذا المستدعي owner المسجد.

---

## 6. قائمة إجراءات واحدة (مرجع سريع)

الإمام يستطيع **حرفياً** أن:

1. إنشاء مسجد (ويصبح مالكه).
2. عرض مسجده المعتمد وكود المسجد وكود الدعوة ونسخهما.
3. عرض طلبات الانضمام لمسجده والموافقة عليها أو رفضها.
4. عرض قائمة المشرفين وإزالة مشرف من المسجد.
5. تحديث إعدادات المسجد (الاسم، العنوان، الموقع، نافذة الحضور).
6. عرض إحصائيات المسجد (طلاب، مشرفون، حضور اليوم، طلبات تصحيح معلقة، طلبات انضمام معلقة).
7. عرض تقرير حضور المسجد لفترة وتقرير أداء المشرفين (من سجّل اليوم).
8. تعيين/تعديل نقاط كل صلاة للمسجد (prayer_config).
9. إلغاء أي حضور في مسجده (بدون قيد زمني).
10. فتح شاشة التحضير (مسح QR / تسجيل الحضور) كالمشرف.
11. عرض قائمة طلاب المسجد وملف كل طفل.
12. إرسال ملاحظة لولي أمر طفل في المسجد.
13. عرض طلبات التصحيح للمسجد وقبولها (عبر RPC) أو رفضها.
14. إنشاء مسابقة، تفعيلها، إيقافها، وعرض ترتيب المسابقة.
15. إنشاء إعلان للمسجد وتعديله وحذفه وتثبيته (حسب التصميم الفعلي للجدول والـ RLS).

---

## 7. ملاحظات للبناء

- **مصدر "هل أنا إمام هذا المسجد":** التحقق من وجود صف في `mosque_members` حيث `mosque_id` و`user_id = أنا` و`role = 'owner'` (أو من `mosques.owner_id = user.id`). التطبيق يوجّه إلى `/imam/dashboard` عندما يكون للمستخدم مسجد معتمد وهو مالكه.
- **مسجد واحد معتمد:** حالياً لوحة الإمام تعتمد "أول مسجد معتمد" من قائمة مساجدي؛ إذا دعمت تطبيقك عدة مساجد للإمام لاحقاً، تحتاج اختيار مسجد أو تكرار الواجهة لكل مسجد.
- **الإعلانات:** إن كان جدول `announcements` يعتمد عمود `sender_id` فقط في RLS، تأكد أن إنشاء الإعلان يضع `sender_id` وليس `created_by` فقط؛ وإلا عدّل الـ migration أو السياسات ليتوافقا مع التطبيق.

بهذا يكون كل ما يستطيع الإمام فعله الآن موثّقاً حرفياً لاستخدامه عند بناء صفحات الإمام.
