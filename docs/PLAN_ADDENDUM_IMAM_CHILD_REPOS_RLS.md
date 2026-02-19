# إضافة للخطة: نقاط الإمام، حساب الابن، الريپوهات، RLS، ونقد لاذع

هذه الوثيقة مكمّلة لـ `PLAN_FULL_INTEGRATED.md` وتغطي:
1. تحكم الإمام بنقاط كل صلاة
2. حساب الابن (إيميل وكلمة سر)
3. تدقيق الريپوهات — ما يُجلب من DB وما ينقص للواجهات
4. تدقيق RLS — هل كل عملية في التطبيق مسموحة في الداتابيس؟
5. نقد لاذع للخطة (بدون مجاملة)

---

# 1. تحكم الإمام بنقاط كل صلاة

## الوضع الحالي

- **النقاط ثابتة في الكود والـ DB:**
  - `PointsService`: صلاة جماعة = 10، فجر منزل = 5، غير فجر منزل = 3 (ثوابت).
  - Trigger `trg_enforce_points()` في migration 020: نفس المنطق مكتوب في SQL (mosque=10, fajr=5, else=3).
- **جدول `mosques`** فيه عمود `prayer_config` (JSONB) لكن **لا يُستخدم** في أي مكان — لا في الـ trigger ولا في PointsService.
- النتيجة: الإمام لا يتحكم بأي شيء؛ "في فترة المدارس نخلّي الظهر ما عليها نقاط" غير ممكنة.

## المطلوب (كل ما يخص النقاط يمتلكه الإمام)

### 1.1 تعريف إعداد النقاط في DB

- **استخدام `mosques.prayer_config`** (موجود) أو إضافة عمود واضح مثل `prayer_points` JSONB.
- الصيغة المقترحة: نقاط كل صلاة في المسجد، مثلاً  
  `{"fajr": 10, "dhuhr": 0, "asr": 10, "maghrib": 10, "isha": 10}`.  
  إن لم يُحدَّد للصلاة أو للمسجد → استخدام قيمة افتراضية (مثلاً 10).
- القرار: هل النقاط فقط لـ location_type = mosque أم أيضاً للمنزل؟ الخطة الحالية: **للجماعة فقط** (كل صلاة لها نقطة 0 أو N حسب إعداد الإمام). صلاة المنزل يمكن تركها ثابتة أو إضافتها لاحقاً.

### 1.2 Trigger في DB (إلزامي)

- **استبدال أو تعديل `trg_enforce_points()`**: عند INSERT في `attendance`:
  - إذا `mosque_id` غير NULL: جلب `prayer_config` (أو `prayer_points`) للمسجد، واستخراج نقطة الصلاة `NEW.prayer`؛ إن لم توجد فالقيمة الافتراضية 10 (أو 0 حسب السياسة).
  - إذا `mosque_id` NULL (منزل): الإبقاء على المنطق الحالي (فجر 5، غير فجر 3) أو جعله قابلاً للإعداد لاحقاً.
- **لا يعتمد التطبيق على إرسال `points_earned`** — الـ trigger يفرض القيمة دائماً (وهذا موجود حالياً؛ يجب أن يقرأ من المسجد).

### 1.3 PointsService في التطبيق

- **إلغاء الثوابت الثابتة** لصلاة الجماعة؛ استبدالها بقراءة من إعداد المسجد.
- دالة مثل: `int getPointsForPrayerInMosque(String mosqueId, Prayer prayer)` — تجلب `mosques.prayer_config` (أو prayer_points) من الريپو وتُرجع النقطة. تُستدعى من `SupervisorRepository.recordAttendance` قبل الإدراج (للتحقق أو للعرض فقط؛ القيمة الفعلية يحددها الـ trigger).
- أو: `PointsService.calculateAttendancePoints(prayer, locationType, {String? mosqueId, Map<String,int>? prayerPoints})` — إن وُجد mosqueId و prayerPoints (من المسجد) استخدمها، وإلا افتراضي.

### 1.4 ريپو الإمام / المسجد

- **تحديث إعداد النقاط:** دالة في ImamRepository أو MosqueRepository:  
  `updateMosquePrayerPoints(String mosqueId, Map<Prayer, int> points)`  
  تحفظ في `mosques.prayer_config` (أو prayer_points) بصيغة JSON مثل `{"fajr":10,"dhuhr":0,...}`.
- فقط **owner المسجد** يعدّل (التحقق في الريپو أو RLS).

### 1.5 خلاصة نقاط الإمام

| المكوّن | المطلوب |
|---------|---------|
| DB | استخدام `prayer_config` (أو عمود جديد) لجدول نقاط الصلوات في المسجد؛ الـ trigger يقرأ منه ويضع `points_earned`. |
| Trigger 020 | تعديل `trg_enforce_points()` لقراءة نقاط الصلاة من مسجد الحضور (عبر JOIN مع mosques). |
| PointsService | عدم استخدام ثوابت للجماعة؛ قراءة النقاط من إعداد المسجد (عبر ريپو أو معامل). |
| recordAttendance | تمرير mosqueId لـ PointsService أو جلب prayer_config مسبقاً وحساب النقاط للعرض/التحقق. |
| ImamRepository/MosqueRepository | دالة تحديث إعداد نقاط الصلوات للمسجد (للإمام فقط). |

---

# 2. حساب الابن (إيميل وكلمة سر — دخول الابن لمعلوماته)

## الاقتراح

- ولي الأمر يضيف الابن كالعادة؛ **لكل طالب يُولَّد إيميل وكلمة سر** (تلقائي أو يعرضه التطبيق لولي الأمر ليعطيه للابن).
- الابن يدخل بتسجيل الدخول ويجد **معلوماته وما يحتاجه** (حضور، نقاط، باركود، إلخ).

## الوضع الحالي

- جدول `children`: فيه `parent_id` فقط؛ **لا ربط بحساب دخول (auth)**.
- جدول `users`: فيه `auth_id`, `role` (user_role = super_admin | parent | imam) — **لا يوجد دور `child`**.
- لا يوجد إنشاء حساب auth للطفل عند "إضافة طفل".

## ما ينقص (بدون ترتيب تنفيذ)

### 2.1 قاعدة البيانات

- **إضافة `child` إلى enum `user_role`** (migration).
- **ربط الطفل بحساب مستخدم:**  
  - إما عمود في `children`: `login_user_id UUID REFERENCES users(id)` (nullable)،  
  - أو عمود `auth_id` في `children` يشير إلى auth.users (أغلب التطبيقات تربط الـ profile بـ users لا بـ auth مباشرة)، لذا **`children.login_user_id` → users(id)** أنسب.
- **RLS لجدول children:** سياسة SELECT تسمح للابن بقراءة **صف الطفل الخاص به فقط**:  
  `children.login_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())`.
- **RLS لجدول attendance:** الابن يرى حضور **طفله فقط** (نفس الطفل المرتبط بـ login_user_id). إما إضافة سياسة SELECT: الطفل مرتبط بـ user حالي عبر login_user_id، و attendance.child_id = ذلك الطفل.
- **RLS لـ mosque_children، notes، إلخ:** تحديد ما يسمح للابن برؤيته (مثلاً قراءة mosque_children لمعرفة مسجده، وقراءة notes لطفله).

### 2.2 إنشاء حساب الابن

- **لا يمكن إنشاء مستخدم في Supabase Auth من التطبيق مباشرة بكلمة سر عشوائية** دون استخدام Admin API أو Edge Function (لأن التسجيل العادي يمر بشاشة المستخدم).
- **المطلوب:** Edge Function (أو خدمة خلفية) تستدعى عند "إضافة طفل" من ولي الأمر:
  - إنشاء مستخدم في `auth.users` (بإيميل مُولَّد، مثلاً `child_<child_id>@app.local` أو إيميل حقيقي إن وُجد)، مع كلمة سر عشوائية (أو قابلة للتعيين).
  - إنشاء صف في `users` (auth_id، name، role='child').
  - تحديث `children` لربط `login_user_id` = ذلك users.id (أو عند الإنشاء: أولاً إنشاء child ثم إنشاء الحساب ثم تحديث child بـ login_user_id).
- **إرجاع الإيميل وكلمة السر** (مرة واحدة) لولي الأمر لعرضها أو تسليمها للابن.

### 2.3 تسجيل دخول الابن في التطبيق

- نفس شاشة تسجيل الدخول (إيميل + كلمة سر). بعد الدخول، `getCurrentUserProfile()` يرجع user بـ role=child.
- **التوجيه:** إذا role == child → مسار خاص بالابن (لوحة الابن: معلوماتي، حضور، نقاط، باركود، إلخ).
- **جلب بيانات الطفل:** دالة مثل `getChildByLoginUserId(String userId)` أو من الريپو: من `children` WHERE login_user_id = current user id، مع التحقق من RLS.

### 2.4 ما يقرأه الابن (منطقياً)

- بيانات الطفل (اسم، عمر، باركود، نقاط، سلاسل).
- حضور اليوم والتاريخ.
- ملاحظات المشرف عنه (إن سُمح بها للابن).
- إعلانات المسجد إن رُبطت بمسجد الطفل.

كل هذه تحتاج **استعلامات وRLS** تسمح لـ user بدور child بقراءة بيانات طفله فقط.

### 2.5 خلاصة حساب الابن

| البند | الحالة |
|-------|--------|
| user_role + child | غير موجود — مطلوب migration. |
| children.login_user_id | غير موجود — مطلوب migration. |
| RLS للابن (children, attendance, notes, …) | غير موجود — مطلوب. |
| إنشاء حساب auth + users عند إضافة طفل | يحتاج Edge Function أو Admin API. |
| تسجيل دخول الابن + توجيه + جلب بيانات الطفل | منطق التطبيق — بعد وجود الحساب والـ RLS. |

---

# 3. تدقيق الريپوهات — ما يُجلب من DB وما ينقص

الهدف: **كل معلومة يمكن استنتاجها من الداتابيس يجب أن تكون قابلة للجلب كعملية (دالة)** حتى لو الـ UI لم يُبنَ بعد — حتى لا تصبح الواجهات مليئة بعمليات معقدة أو استعلامات مكررة.

## 3.1 ImamRepository — ما موجود وما ينقص

| الدالة | الوصف | ملاحظة |
|--------|--------|--------|
| getMosqueStats | إجماليات: طلاب، مشرفون، حضور اليوم، تصحيحات معلقة، طلبات انضمام | ✅ |
| getAttendanceReport | حضور المسجد لفترة (تاريخ، صلاة، طفل، نقاط) | ✅ |
| getSupervisorsPerformance | عدد سجلات كل مشرف **اليوم** فقط | ⚠️ اليوم فقط؛ لا تفصيل صلوات ولا فترة. |
| getProcessedCorrections | طلبات معالجة (غير pending) | ⚠️ **يطلب ترتيباً بـ `updated_at`** بينما جدول correction_requests **لا يملك عمود updated_at** — يوجد فقط `reviewed_at`. تصحيح: استبدال `order('updated_at')` بـ `order('reviewed_at')`. |
| updateMosqueSettings | اسم، عنوان، موقع، نافذة حضور | ✅ لا يشمل prayer_config/نقاط الصلوات. |
| cancelAttendance | إلغاء حضور | ✅ |

ما ينقص (مقترح):

- **أداء المشرفين لفترة (وليس اليوم فقط):** عدد السجلات لكل مشرف ضمن fromDate–toDate، ويفضل تفصيل حسب الصلاة (كم فجر، كم ظهر، …).
- **تقرير حضور حسب الصلاة:** إحصائيات مجمعة (كم طفل حضر كل صلاة في الفترة) — يمكن اشتقاقه من getAttendanceReport لكن دالة مخصصة أوضح.
- **قائمة الطلاب مع إحصائياتهم:** لكل طالب: إجمالي حضور، سلاسل، نقاط (موجود جزئياً في Gamification/Competition؛ للإمام قد نحتاج نفس المنطق لمسجد واحد).
- **تحديث إعداد نقاط الصلوات:** `updateMosquePrayerPoints(mosqueId, Map<Prayer,int>)` كما في الفقرة 1.

## 3.2 SupervisorRepository

- **getMosqueStudents**, **getTodayAttendanceCount**, **getRecordedChildIdsForPrayer**, **recordAttendance**, **findChildByQrCode**, **getChildById**, **findChildByLocalNumber**, **cancelAttendance**, **findChildByName**, **getDailyStats** — كلها موجودة.
- قد ينقص: **تقرير يومي للمشرف عن نفسه** (كم سجل اليوم، حسب الصلاة) — يمكن من getDailyStats أو توسيعها.

## 3.3 ChildRepository (ولي الأمر)

- **getMyChild**, **getMyChildren**, **addChild**, **linkChildToMosque**, **getChildMosqueIds**, **getAttendanceForMyChildren**, **getFullChildProfile**, **getAttendanceHistory**, **getChildReport** — تغطي معظم احتياجات ولي الأمر.
- عند وجود **حساب الابن**: دالة لجلب الطفل المرتبط بـ login_user_id (للابن عند تسجيل الدخول).

## 3.4 MosqueRepository

- **createMosque**, **requestToJoinByInviteCode**, **getPendingJoinRequests**, **approve/rejectJoinRequest**, **getMyMosques**, **getMosqueSupervisors**, **removeMosqueMember**, **hasApprovedMosque**, **getMosquesByIds**, **getApprovedMosqueByCode**, **getPendingMosquesForAdmin**, **updateMosqueStatus**, **updateMosqueLocation**, **updateMosqueSettings**.
- ينقص: **تحديث prayer_config / نقاط الصلوات** (أو في ImamRepository).

## 3.5 باقي الريپوهات (Competition, Correction, Notes, Announcement, Auth, Admin, Gamification)

- مراجعة سريعة: هل هناك استعلامات شائعة في الواجهات (مثلاً: ترتيب أسبوعي، ترتيب شهري، عدد الملاحظات غير المقروءة، إلخ) غير مكشوفة كدالة؟ إن وُجدت إضافتها يقلل تكرار المنطق في الـ UI.

## 3.6 خلاصة الريپوهات

- **إصلاح فوري:** `getProcessedCorrections` — ترتيب بـ `reviewed_at` بدل `updated_at`.
- **إضافة مقترحة:** أداء المشرفين لفترة + تفصيل صلوات؛ دالة تحديث نقاط الصلوات للمسجد؛ دالة للطفل حسب login_user_id عند تفعيل حساب الابن.

---

# 4. تدقيق RLS — هل كل عملية في التطبيق مسموحة في الداتابيس؟

الفكرة: **كل استدعاء من التطبيق (insert, update, delete, select, rpc) يجب أن يكون مسموحاً بسياسة RLS (أو كـ service_role إن استُخدم)**. أحياناً الاختبارات لا تكشف أن سياسة ناقصة أو أن العمود غير موجود.

## 4.1 ملخص سريع (يُستكمل يدوياً أو بأداة)

| الجدول | العملية | من التطبيق | السياسة / الملاحظة |
|--------|---------|------------|---------------------|
| users | SELECT/UPDATE | المستخدم يقرأ/يعدّل ملفه | Users: read/update own ✅ |
| users | INSERT | عند التسجيل (handle_new_user) | trigger + policy ✅ |
| children | SELECT | ولي الأمر، مشرف/إمام، (ابن) | parent/supervisors ✅؛ ابن: يحتاج سياسة عند إضافة login_user_id |
| children | INSERT/UPDATE | ولي الأمر | ✅ |
| mosques | SELECT/INSERT/UPDATE | حسب الدور | ✅ |
| mosque_members | SELECT/INSERT/DELETE | إمام، مشرف | ✅ |
| mosque_children | SELECT/INSERT | ولي أمر، مشرف | ✅ |
| attendance | INSERT | مشرف/إمام (عضو مسجد) | 021 "member records" ✅ |
| attendance | SELECT | ولي أمر، مسجّل، أعضاء المسجد (018) | ✅ |
| attendance | DELETE | لا مباشر — عبر RPC cancel_attendance | RPC ✅ |
| correction_requests | INSERT | ولي الأمر | 021 ✅ |
| correction_requests | SELECT | ولي أمر (طلباته)، مشرف/إمام (المسجد) | 021 ✅ |
| correction_requests | UPDATE | مشرف/إمام (موافقة/رفض) فقط — ولي الأمر **لا** يعدّل status | 021 فصل UPDATE عن parent ✅ |
| notes | INSERT | عضو مسجد (021) | ✅ |
| notes | SELECT | مرسل أو ولي أمر الطفل | ✅ |
| announcements | حسب 026 | قراءة أعضاء+أولياء؛ إنشاء إمام فقط | 026 ✅ |
| competitions | حسب 022/023 | إنشاء/تفعيل إمام فقط | ✅ |

## 4.2 نقاط يجب التحقق منها

- **attendance INSERT:** التأكد أن السياسة الحالية (021) تتحقق من عضوية المسجد؛ تم.
- **correction_requests UPDATE:** ولي الأمر لا يعدّل status (تم فصل السياسات في 021).
- **children UPDATE:** من يعدّل total_points/streaks؟ فقط الـ trigger (020 protect_child_stats) — العميل لا يعدّلها ✅.
- **جدول child_link_codes (المخطط):** عند إنشائه، RLS: ولي الأمر يدرج لطفله؛ والتحقق من الكود إما RPC أو سياسة SELECT محدودة (مثلاً لا يعرض الكود إلا عبر RPC).
- **حساب الابن:** عند إضافة children.login_user_id و role=child، التأكد أن سياسات SELECT للابن تقتصر على صف الطفل المرتبط بحسابه فقط.

## 4.3 توصية

- تشغيل **قائمة بكل استدعاءات Supabase** (من كل الريپوهات): from().select/insert/update/delete و rpc(). لكل واحدة كتابة: **من أي دور؟** و**أي سياسة تسمح؟** إن لم توجد سياسة → إضافتها أو تصحيح الاستدعاء.

---

# 5. نقد لاذع للخطة (بدون مجاملة)

- **النقاط كلها بيد الإمام غير مذكورة في الخطة الحالية.** هذا تغيير منتج كبير (قواعد نقاط ديناميكية، trigger، واجهة إعداد). عدم وجودها في الخطة = نسيان أو تأجيل غير معلن.

- **حساب الابن (إيميل/كلمة سر) غير موجود في الخطة.** الاقتراح يغيّر نموذج الاستخدام (من "عرض الابن بدون تسجيل" إلى "دخول الابن بحسابه"). هذا يتطلب migrations، RLS، وEdge Function — وكل هذا غير مذكور.

- **الخطة تخلط "ربط جهاز الابن" (كود ربط مؤقت + عرض باركود بدون تسجيل) مع احتمال "حساب ابن".** يجب الفصل: إما مسار "كود ربط → عرض فقط" أو "حساب ابن بإيميل/كلمة سر" أو الاثنان معاً. القرار يحدد حجم العمل.

- **الريپوهات: كثير من الواجهات المستقبلية (لوحة الإمام، تقارير المشرفين، إلخ) تحتاج دوال إضافية.** الخطة لا تذكر مراجعة شاملة للريپوهات من منظور "كل ما يمكن استخراجه من DB". النتيجة: عند بناء الـ UI ستُكتشف ثغرات (مثل ترتيب بـ updated_at غير موجود).

- **RLS: لا يوجد تدقيق منهجي "عملية تطبيق ↔ سياسة DB".** الاعتماد على أن "ما يعمل في الاختبار يعمل" خطير؛ صلاحيات خاطئة قد تظهر فقط في إنتاج أو مع مستخدمين مختلفين.

- **إعداد نقاط الصلوات (prayer_config) موجود في الـ schema وغير مستخدم منذ البداية.** هذا يدل على تصميم غير مكتمل أو نسيان — والخيار الوحيد الواضح هو إما استخدامه الآن أو إزالته من المواصفات.

- **الخطة تذكر "لا تركيز على الشاشات" لكن القسم الأخير لا يزال قسماً كبيراً للشاشات.** إذا الهدف "لا نبني شاشات الآن" فيُفضّل تقليص ذلك القسم إلى قائمة عناوين فقط وترك التفصيل لمرحلة لاحقة، والتركيز في الخطة على DB وخدمات وريپوهات وRLS.

- **ترتيب التنفيذ: "تنفيذ 026 ثم ربط جهاز الابن ثم …" لا يأخذ في الاعتبار اعتماديات كبيرة:** مثلاً تحكم الإمام بالنقاط يؤثر على trigger وعلى كل مكان يحسب النقاط؛ حساب الابن يؤثر على auth و users و children و RLS. وضعها في الخطة بدون ترتيب واضح قد يسبب إعادة عمل.

---

# 6. إصلاحات فورية مقترحة (كود موجود)

1. **ImamRepository.getProcessedCorrections:** استبدال `order('updated_at', ascending: false)` بـ `order('reviewed_at', ascending: false)` لأن جدول `correction_requests` لا يملك `updated_at`.
2. **تحديث الخطة الرئيسية:** إضافة بند "تحكم الإمام بنقاط كل صلاة" (DB + trigger + PointsService + ريپو)، وبند "حساب الابن (إيميل/كلمة سر)" مع ما ينقص (migrations، RLS، Edge Function)، وتدقيق ريپوهات وRLS كما أعلاه، وتقليص قسم الشاشات إلى عناوين فقط إن كان التركيز "لا شاشات الآن".

---

*هذه الوثيقة مرجع تكميلي؛ يُحدَّث مع تنفيذ البنود أو اكتشاف ثغرات إضافية.*
