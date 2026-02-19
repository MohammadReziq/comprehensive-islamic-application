# خطة متكاملة — ما ينقصنا (صلاتي حياتي)

**هدف الوثيقة:** خطة واحدة شاملة تجمع كل ما تبقى من الخطة الأصلية والدراسات، مرتبة حسب **البنية أولاً ثم المنطق ثم التحسينات**. **لا تركيز على الشاشات الآن** — المرحلة الأخيرة قائمة عناوين فقط؛ التفصيل عند بناء الواجهات لاحقاً.

مصادر الخطة: `PLAN_COMPLETE_REMAINING.md`, `PLAN_FINAL_COMPLETE.md`, `STUDY_COMPLETE_WHAT_WE_HAVE_AND_WHAT_NEXT.md`, `STATUS_AFTER_ANTIGRAVITY.md`, `مواصفات_المشروع_للكستمر.md`, `MASTER_PLAN_CRITICAL_REVIEW.txt`, `infrastructure_developer_guide.md`.

**إضافة تكميلية (نقاط الإمام، حساب الابن، تدقيق ريپوهات و RLS، نقد لاذع):** `docs/PLAN_ADDENDUM_IMAM_CHILD_REPOS_RLS.md`

---

## تم بالفعل (لا تحتاج عمل)

- [x] AttendanceValidationService + ربطه في recordAttendance
- [x] فصل صلاحيات المسابقة (الإمام فقط)
- [x] إلغاء حضور خاطئ (024 + RPC + SupervisorRepository + ImamRepository + ImamBloc)
- [x] أوقات صلاة حسب المسجد (025 + MosqueModel + التحقق يستخدم lat/lng من DB)
- [x] ImamRepository + ImamBloc
- [x] AdminRepository + AdminBloc
- [x] RealtimeService: دوال subscribe للتصحيحات والملاحظات (موجودة في الكود)
- [x] شاشة إنشاء طلب تصحيح لولي الأمر + مسار + زر من بطاقة الطفل
- [x] عرض طلبات التصحيح "طلباتي" لولي الأمر
- [x] RequestCorrectionScreen + تسجيل في Router و injection
- [x] إصلاح ImamRepository.getProcessedCorrections: ترتيب بـ `reviewed_at` (جدول correction_requests لا يملك updated_at)

---

# الجزء الأول — قاعدة البيانات والـ Backend (قبل أي واجهة)

## 1.1 تنفيذ Migration 026 (الإعلانات)

- [ ] نسخ محتوى `supabase/migrations/026_announcements.sql` كاملاً ولصقه في Supabase → SQL Editor وتشغيله مرة واحدة.
- [ ] التأكد: إضافة أعمدة `is_pinned`, `updated_at` إن لم تكونا، إنشاء index، استبدال سياسات RLS، إضافة الجدول لـ Realtime.
- [ ] لا تعارض مع 001 (الجدول يستخدم `sender_id`).

## 1.2 آلية ربط جهاز الابن (Backend)

- [ ] إنشاء migration جديدة (مثلاً `027_child_link_codes.sql`):
  - جدول `child_link_codes`: `id`, `child_id` (FK → children), `code` (مثلاً VARCHAR(10) UNIQUE), `expires_at` (TIMESTAMPTZ), `created_at`.
  - RLS: ولي الأمر يدرج صفاً لطفله فقط؛ لا قراءة عامة للكود (أو دالة RPC تتحقق من الكود وتُرجع child_id/بيانات العرض فقط).
- [ ] دالة RPC (اختياري أن تكون في نفس الـ migration أو لاحقاً): `validate_child_link_code(p_code TEXT)` → تُرجع `child_id` وبيانات العرض (اسم، qr_code أو ما يحدد الباركود) إن الكود صالح وغير منتهٍ؛ وإلا خطأ.
- [ ] سياسة حذف أو انتهاء صلاحية: إما TTL عبر Cron أو الاعتماد على `expires_at` في التحقق فقط.

## 1.3 Realtime للجداول (Supabase)

- [ ] التأكد في Supabase أن جداول `correction_requests` و `notes` مضافة إلى الـ Publication (مثلاً `supabase_realtime`). إن لم تكن، إضافة عبر SQL:
  - `ALTER PUBLICATION supabase_realtime ADD TABLE correction_requests;`
  - `ALTER PUBLICATION supabase_realtime ADD TABLE notes;`
- [ ] (026 يضيف `announcements` للـ Realtime إن لم يكن مضافاً.)

## 1.4 مراجعة RLS وسلامة البيانات (حسب infrastructure_developer_guide)

- [ ] مراجعة سياسات RLS الحرجة المذكورة في الدليل (مثلاً correction_requests: منع ولي الأمر من UPDATE لـ status؛ attendance INSERT يتحقق من عضوية المسجد إن لزم).
- [ ] إن وُجدت ثغرات موثّقة ولم تُعالج بعد، معالجتها في migrations منفصلة.

## 1.5 تحكم الإمام بنقاط كل صلاة (DB + trigger)

- [ ] استخدام `mosques.prayer_config` (أو عمود جديد) لجدول نقاط الصلوات في المسجد (مثلاً `{"fajr":10,"dhuhr":0,"asr":10,...}`).
- [ ] تعديل trigger `trg_enforce_points()` في 020 لقراءة نقطة الصلاة من مسجد الحضور (JOIN mosques) بدل الثوابت الثابتة؛ إن لم يُحدَّد للمسجد فقيمة افتراضية.
- [ ] التفصيل الكامل في `PLAN_ADDENDUM_IMAM_CHILD_REPOS_RLS.md` (قسم 1).

## 1.6 حساب الابن (إيميل + كلمة سر — اختياري بديل أو مكمّل لربط الجهاز)

- [ ] إن رغبت في "كل طالب له إيميل وكلمة سر ويدخل ويشوف معلوماته": إضافة دور `child` إلى user_role، وعمود `children.login_user_id` لربط الطفل بحساب users، و RL S للابن، و Edge Function (أو Admin API) لإنشاء حساب auth عند إضافة طفل.
- [ ] التفصيل الكامل في `PLAN_ADDENDUM_IMAM_CHILD_REPOS_RLS.md` (قسم 2). الفصل بين "ربط جهاز بكود مؤقت" و"حساب ابن دخول" مذكور هناك.

---

# الجزء الثاني — الخدمات (Services)

## 2.1 AttendanceValidationService

- [x] الخدمة موجودة ومربوطة في `SupervisorRepository.recordAttendance`.
- [ ] التأكد أن `canRecordNow` يستخدم أوقات المسجد من DB (mosqueId → lat/lng → PrayerTimesService) وليس موقعاً افتراضياً ثابتاً في كل الحالات.
- [ ] التأكد أن رسالة الرفض (reason) واضحة وتُعاد في الـ Failure للمستخدم.

## 2.2 PrayerTimesService

- [ ] وجود دالة (أو استخدام موجود): `getTimesForMosque(String mosqueId)` — تجلب بيانات المسجد (lat, lng من MosqueRepository أو من الـ Bloc)، وتعيد أوقات الصلاة لذلك الموقع.
- [ ] Fallback: إن لم يكن للمسجد lat/lng، استخدام مكة أو موقع الجهاز حسب ما هو موثّق في الخطة.

## 2.3 RealtimeService

- [x] `subscribeCorrectionRequests(mosqueId, onEvent)` و `subscribeNotesForChildren(childIds, onEvent)` موجودتان.
- [ ] التأكد أن الـ channel/filter يستخدمان أسماء الأعمدة والجدول الصحيحة في Supabase (postgres_changes).
- [ ] لا حاجة لتعديل الشاشات هنا — ربط الاستدعاء في الشاشات ضمن "المرحلة الأخيرة — الشاشات".

## 2.4 خدمة ربط جهاز الابن (أو داخل ChildRepository)

- [ ] توليد كود ربط: `generateLinkCode(String childId)` — يدرج صفاً في `child_link_codes` (بعد 1.2) بكود عشوائي (مثلاً 6 أحرف) و `expires_at` (مثلاً بعد 24–72 ساعة)، مع التحقق من أن المستخدم الحالي والد الطفل.
- [ ] التحقق من الكود: `validateLinkCode(String code)` → استدعاء RPC أو قراءة آمنة تُرجع child_id وبيانات العرض (اسم، معرف الباركود) إن الكود صالح.
- [ ] تسجيل الخدمة أو توسيع ChildRepository في injection_container.

## 2.5 PointsService — نقاط من إعداد المسجد

- [ ] إزالة الثوابت الثابتة لصلاة الجماعة؛ استبدالها بقراءة من `mosques.prayer_config` (أو prayer_points) عبر ريپو عند حساب النقاط (للتحقق/عرض قبل الإدراج؛ القيمة الفعلية يفرضها trigger الـ DB).
- [ ] دالة مثل `getPointsForPrayerInMosque(mosqueId, prayer)` أو تمرير إعداد المسجد لـ `calculateAttendancePoints`. التفصيل في الإضافة التكميلية.

---

# الجزء الثالث — الريپوهات والـ Blocs (المنطق دون واجهة)

## 3.1 موقع المسجد (lat/lng) + إعداد نقاط الصلوات

- [ ] في MosqueRepository أو ImamRepository: دالة `updateMosqueLocation(String mosqueId, double lat, double lng)` — تحديث جدول `mosques` بحقول `lat`, `lng` (والـ timezone إن أردنا استنتاجها).
- [ ] دالة `updateMosquePrayerPoints(String mosqueId, Map<Prayer,int>)` — حفظ نقاط كل صلاة في `mosques.prayer_config`؛ فقط owner المسجد. التفصيل في الإضافة التكميلية.
- [ ] التحقق من الصلاحية: المستخدم هو owner المسجد فقط.
- [ ] ImamBloc: أحداث UpdateMosqueLocation و UpdateMosquePrayerPoints (إن وُجدت واجهة لاحقاً).

## 3.2 ربط جهاز الابن (من ولي الأمر)

- [ ] ChildRepository (أو خدمة مخصصة): `generateLinkCode(childId)` كما في 2.4.
- [ ] دالة لجلب بيانات عرض الطفل للشاشة "عرض الابن": `getChildDisplayData(String linkCode)` أو بعد التحقق تخزين child_id محلياً ثم `getChildById(childId)` مع التحقق أن الجهاز مربوط بهذا الطفل (من التخزين المحلي).
- [ ] لا واجهة هنا — فقط الـ API والمنطق.

## 3.3 طلبات التصحيح و"طلباتي"

- [x] CreateCorrectionRequest و getMyRequests موجودان في CorrectionRepository و CorrectionBloc.
- [ ] التأكد أن LoadMyCorrections يُستدعى من مكان يتحكم به ولي الأمر (الربط في الشاشة في المرحلة الأخيرة).

## 3.4 الإعلانات

- [ ] التأكد أن AnnouncementRepository يقدم: قائمة إعلانات المسجد، إنشاء (للإمام)، تعديل، حذف (للمنشئ)، وفق RLS في 026.
- [ ] AnnouncementBloc: أحداث LoadForMosque, Create, Update, Delete وحالات مناسبة.
- [ ] تسجيل الـ Bloc والريپو في injection_container (موجودان حسب الجريب).

## 3.5 إلغاء الحضور

- [x] RPC و SupervisorRepository/ImamRepository موجودان.
- [ ] ImamBloc (أو ScannerBloc): حدث مثل `CancelAttendanceByImam(attendanceId)` يستدعي الريپو ويعيد تحميل القائمة أو يحدّث الحالة.
- [ ] عرض الزر واستدعاء الحدث في الشاشة — في المرحلة الأخيرة.

## 3.6 المسابقة النشطة لولي الأمر

- [ ] في CompetitionRepository أو ChildRepository: دالة تجلب "المسابقة النشطة لمسجد أحد أطفال المستخدم" وترتيب أطفاله (مثلاً getLeaderboard مع فلترة بأطفال المستخدم). إن وُجدت دالة مناسبة (getActive + getLeaderboard) يمكن استخدامها مع فلترة من طبقة أعلى.
- [ ] Bloc (CompetitionBloc أو ParentBloc): حدث مثل LoadActiveCompetitionForMyChildren وحالة تعرض المسابقة وترتيب أطفال المستخدم.
- [ ] الشاشة في المرحلة الأخيرة.

## 3.7 توحيد معالجة الأخطاء (AppFailure)

- [ ] توحيد رسائل Failure في الريپوهات (كود مسجد خاطئ، انتهت مهلة التسجيل، طلب مرفوض، خارج نافذة الحضور، إلخ) بحيث كل استدعاء يرمي AppFailure برسالة مفهومة.
- [ ] التأكد أن الـ Blocs لا تبلع الأخطاء — تُمرّر للمستخدم عبر state (failureMessage أو ما شابه).

## 3.8 تدقيق الريپوهات — عمليات قابلة للجلب من DB

- [ ] مراجعة كل ريپو: هل كل معلومة يمكن استنتاجها من الداتابيس (إحصائيات الإمام، أداء المشرفين لفترة، تفصيل صلوات، إلخ) مكشوفة كدالة؟ الإضافة التكميلية تسرد ما ينقص (أداء مشرفين لفترة، تقرير حضور حسب صلاة، تحديث نقاط الصلوات).
- [ ] الهدف: أن تكون الـ UI لاحقاً قادرة على استدعاء عمليات جاهزة بدل تركيب استعلامات معقدة في الواجهة.

## 3.9 تدقيق RLS — كل عملية في التطبيق مسموحة في DB

- [ ] مراجعة منهجية: لكل استدعاء Supabase (select/insert/update/delete/rpc) من الريپوهات — التأكد أن سياسة RLS (أو RPC) تسمح به لدور المستخدم الحالي. الإضافة التكميلية تحتوي جدولاً مرجعياً ونقاط تحقق.
- [ ] أحياناً الاختبار لا يكشف صلاحيات خاطئة؛ التدقيق يقلل مخاطر الإنتاج.

---

# الجزء الرابع — تدفق التطبيق والتوجيه (بدون تصميم الشاشات)

## 4.1 توجيه الجهاز المربوط بالابن

- [ ] عند بدء التطبيق (مثلاً في منطق الـ Router أو splash): فحص التخزين المحلي (مثلاً flutter_secure_storage) لوجود "ربط جهاز" (child_id مخزّن).
- [ ] إن وُجد ربط: توجيه إلى مسار مثل `/child-view` (شاشة عرض الابن فقط — الشاشة نفسها في المرحلة الأخيرة).
- [ ] إن لم يُوجد ربط: المسار المعتاد (تسجيل دخول أو اختيار "لدي كود ربط").
- [ ] تسجيل المسار `/child-view` في الـ Router (حتى لو الشاشة بسيطة أو placeholder في البداية).

## 4.2 مسارات إضافية للتسجيل في الـ Router

- [ ] تسجيل أي مسار جديد مطلوب للخطة (مثلاً `/parent/competition` للمسابقة النشطة، `/child-view`، إعدادات المسجد للإمام إن لم تكن مسجّلة).
- [ ] لا يشترط أن تكون الشاشات مكتملة التصميم — يكفي أن المسار يعمل ويستدعي الـ Bloc الصحيح.

## 4.3 Dependency Injection

- [ ] تسجيل أي Repository أو Bloc أو Service جديد في injection_container (ربط جهاز الابن، AnnouncementBloc إن لم يكن، إلخ).

---

# الجزء الخامس — تحسينات الجودة (غير واجهة أو واجهة خفيفة)

## 5.1 رسائل خطأ واضحة

- [ ] توحيد عرض AppFailure في مكان واحد (مثلاً في قاعدة الشاشات أو في BlocListener عام): toast أو snackbar برسالة مفهومة.
- [ ] مراجعة استدعاءات الريپو التي ترمي AppFailure والتأكد أن الواجهة تعرضها ولا تبلعها.

## 5.2 Pull-to-refresh (المنطق)

- [ ] في الـ Blocs المعنية (حضور اليوم، طلبات التصحيح، الملاحظات، المسابقات): دعم "إعادة تحميل" عند طلب المستخدم (حدث Refresh).
- [ ] ربط RefreshIndicator في الشاشات بالحدث — يمكن في المرحلة الأخيرة.

## 5.3 Pagination و Caching (اختياري)

- [ ] Pagination في القوائم الكبيرة (طلبات التصحيح، المستخدمين للأدمن إن وُجدت) إن ظهرت حاجة.
- [ ] Caching بسيط لقائمة الطلاب أو إعدادات المسجد إن رغبت.
- [ ] تحقق من دور المستخدم في الكود (Defense in Depth) قبل استدعاء عمليات حساسة، بجانب RLS.

## 5.4 Skeleton / تحميل أنيق

- [ ] وجود مكوّن Skeleton أو Shimmer في المشروع (أو إضافته) لاستخدامه في القوائم.
- [ ] استبدال أو استكمال الـ spinner بهيكل تحميل في الشاشات — يمكن تنفيذ الواجهة في المرحلة الأخيرة.

---

# المرحلة الأخيرة — عناوين الشاشات/الواجهات (لا نبنيها الآن)

**لا تركيز على بناء الشاشات في هذه الخطة.** القائمة التالية عناوين فقط للمرحلة اللاحقة؛ التفصيل عند البدء ببناء الواجهات.

- س.1 واجهة موقع المسجد (للإمام) — إعدادات الموقع + (اختياري) إعداد نقاط كل صلاة
- س.2 ربط جهاز الابن + عرض الابن (كود ربط → شاشة عرض باركود) و/أو حساب الابن (إيميل/كلمة سر)
- س.3 المسابقة النشطة لولي الأمر
- س.4 ربط Realtime في شاشات التصحيحات والملاحظات
- س.5 إلغاء الحضور من الواجهة (زر للإمام/المشرف)
- س.6 واجهات الإعلانات (إمام: إنشاء/تعديل/حذف؛ مشرف/ولي أمر: قراءة)
- س.7 Pull-to-refresh و Skeleton في القوائم
- س.8 روابط واختبار يدوي لدورة كاملة

---

# ملخص ترتيب التنفيذ المقترح

1. **الجزء الأول** — تنفيذ 026، migration ربط جهاز الابن، Realtime للجداول، مراجعة RLS.
2. **الجزء الثاني** — التأكد من الخدمات (AttendanceValidation، PrayerTimes للمسجد، RealtimeService، خدمة ربط الابن).
3. **الجزء الثالث** — تحديث موقع المسجد، ربط جهاز الابن (ريپو/بلوك)، الإعلانات، إلغاء الحضور (حدث بلوك)، المسابقة النشطة (دالة + بلوك)، توحيد الأخطاء.
4. **الجزء الرابع** — توجيه جهاز الابن، مسارات، DI.
5. **الجزء الخامس** — تحسينات الجودة (رسائل خطأ، منطق refresh، pagination/caching إن لزم).
6. **المرحلة الأخيرة — عناوين الشاشات فقط (لا نبنيها الآن)** — س.1 حتى س.8 عند بناء الواجهات لاحقاً.

---

# نقد لاذع للخطة (مرجع)

ما قد يُنسى أو يُؤجّل بدون قرار واضح، والتناقضات المحتملة، مذكور في **`PLAN_ADDENDUM_IMAM_CHILD_REPOS_RLS.md`** (قسم 5). يُنصح بقراءته قبل التنفيذ.

---

# مؤجّل (خارج نطاق هذه الخطة)

- أقرب مسجد لولي الأمر  
- اعتراف/تحقق المسجد  
- مسجد أساسي + ثانوي (واجهة ربط الطفل)  
- Offline للمسجد  
- FCM من الخادم (إشعارات)  
- الجوائز والشارات (واجهة)  
- توسيع دور السوبر أدمن (إحصائيات، قائمة مساجد/مستخدمين، إلخ) — حسب MASTER_PLAN

---

*هذه الوثيقة مرجع واحد لما ينقصنا؛ تُحدَّث عند إنجاز بنود. الشاشات دائماً في المرحلة الأخيرة.*
