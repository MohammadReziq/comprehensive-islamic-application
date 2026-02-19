# خطة التنفيذ النهائية الوحيدة — صلاتي حياتي (Flutter + Supabase)

هذه الوثيقة **الخطة التنفيذية الوحيدة** للمشروع. **تحل محل جميع وثائق الخطط السابقة** (مثل PLAN_FULL_INTEGRATED، PLAN_ADDENDUM، PLAN_COMPLETE_REMAINING، PLAN_FINAL_COMPLETE، إلخ). في حال اختفاء أي توثيق آخر، هذه الوثيقة كافية للتنفيذ الكامل.

---

# القسم 0 — جدول القرارات المحسومة

| القرار | الخيار المختار | الأثر التقني | من يتأثر |
|--------|----------------|--------------|----------|
| صور المستخدمين | لن تُضاف إطلاقاً في هذا المشروع | لا حقول avatar، لا رفع ملفات، لا واجهة صور | كل الأدوار |
| حساب الابن | حساب auth حقيقي. إنشاء تلقائي عبر Edge Function عند addChild. **ولي الأمر يتحكم باسم الحساب (الإيميل) وكلمة السر إن أراد**؛ وإلا يُولَّدان تلقائياً. عرض credentials مرة واحدة لولي الأمر. الابن يدخل من شاشة تسجيل الدخول → دور child → شاشة مخصصة (باركود، حضور، نقاط). لا كود ربط مؤقت ولا تخزين محلي | إضافة `child` لـ user_role؛ عمود `children.login_user_id`؛ RLS للدور child؛ Edge Function لإنشاء auth user (تقبل email/password اختياريين من ولي الأمر)； تحديث handle_new_user ليقبل role=child؛ توجيه حسب الدور؛ شاشة ChildView | ولي الأمر (عرض/تعيين credentials مرة واحدة)، الابن (تسجيل دخول وحساب مخصص) |
| نقاط الصلوات | الإمام يتحكم بكل نقاط صلوات المسجد. التخزين في mosques.prayer_config. يمكن تغيير النقاط في أي وقت (مثلاً الظهر = 0 لأسبوع). trigger يقرأ من prayer_config؛ لا ثوابت للجماعة في الكود. افتراضي 10 للجماعة إن لم يُحدد. صلاة المنزل ثابتة: فجر=5، غير فجر=3 | تعديل trigger trg_enforce_points لقراءة من mosques.prayer_config؛ PointsService يقرأ من الريپو؛ ImamRepository.updateMosquePrayerPoints؛ واجهة إعداد النقاط للإمام فقط | الإمام، المشرف (تسجيل الحضور يستخدم نقاط المسجد)، ولي الأمر والابن (عرض النقاط) |
| تسجيل صلاة المنزل | لا واجهة في هذه المرحلة. DB جاهز (location_type=home) | لا تغيير واجهة؛ عند التصميم المستقبلي: من يسجّل، نافذة الوقت، المسابقة، صلاحية الإمام لتعطيلها | — |

---

# القسم 1 — الأساس: DB والـ Backend

يُنجز هذا القسم قبل أي تغيير في الخدمات أو الريپوهات أو الواجهات. الترتيب الداخلي حسب التبعيات.

## 1.1 Migration: إضافة دور child وربط الطفل بحساب الدخول

| البند | التفصيل |
|-------|---------|
| **رقم/اسم مقترح** | `028_child_account.sql` |
| **تعتمد على** | 001 (جداول users, children)، 002 (handle_new_user) |
| **ما تضيفه** | (1) `ALTER TYPE user_role ADD VALUE 'child';` (2) `ALTER TABLE children ADD COLUMN login_user_id UUID REFERENCES users(id) ON DELETE SET NULL;` (3) سياسة RLS: الابن يقرأ صف الطفل المرتبط بحسابه فقط: `CREATE POLICY "Children: child reads own" ON children FOR SELECT USING (login_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));` (4) تحديث دالة `handle_new_user()` لتدعم `role = 'child'` من raw_user_meta_data (إضافة WHEN 'child' THEN user_role_val := 'child'::user_role في الـ CASE). (5) سياسة UPDATE على children: ولي الأمر فقط يعدّل login_user_id (أو نمنع التعديل المباشر من العميل ونجعل الربط يتم من Edge Function/خدمة). الأبسّط: ولي الأمر يعدّل أطفاله؛ إضافة شرط أن العمود login_user_id يُحدَّث فقط من دالة SECURITY DEFINER أو من خدمة موثوقة — أو نسمح لولي الأمر بتحديثه مرة واحدة عند الربط. القرار: Edge Function بعد إنشاء auth و users تُحدّث children.login_user_id = users.id للطفل؛ إذن الـ Edge Function تحتاج صلاحية (service_role أو دالة RPC). الأفضل: RPC تستدعى من Edge Function بعد إنشاء المستخدم، مثل `link_child_to_user(p_child_id, p_user_id)` وتتحقق أن p_user_id من مستخدم role=child وأن الطفل لولي الأمر الحالي — لكن الـ Edge Function تعمل بسياق مختلف. الأبسّط: Edge Function بصلاحية service_role تُدرج في users ثم تُحدّث children.set login_user_id = ذلك user.id حيث child.id = الطفل المعني. لا نعرض RPC لعميل عادي. |
| **ما يكسر إن غابت** | تسجيل دخول الابن لا يعرض بيانات الطفل؛ addChild لا يقدر يربط حساباً بالطفل. |

**تفصيل تنفيذي للمigration 028:**

- إضافة القيمة `child` إلى enum `user_role`.
- إضافة العمود `children.login_user_id UUID REFERENCES users(id) ON DELETE SET NULL`.
- سياسة SELECT للابن: `Children: child reads own` — USING (login_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())).
- تحديث `handle_new_user`: في الـ CASE إضافة `WHEN 'child' THEN user_role_val := 'child'::user_role`.
- سياسة INSERT على users: إنشاء المستخدم من التطبيق العادي يمر عبر auth.signUp؛ المستخدم الجديد يُنشأ من Edge Function عبر Admin API — الـ trigger يشتغل على auth.users. لا حاجة لسياسة INSERT إضافية لـ users من دور child (الإنشاء من الخادم).
- ربط الطفل بالمستخدم: يتم من Edge Function بعد إنشاء auth user و users row. Edge Function تعمل بصلاحية service_role فتقوم بـ UPDATE children SET login_user_id = ذلك users.id WHERE id = child_id (بعد التحقق من أن child.parent_id يطابق ولي الأمر من JWT الممرّر). **حماية عمود login_user_id:** ولي الأمر لا يعدّل login_user_id من التطبيق — إضافة trigger BEFORE UPDATE على children: إن المُحدّث ليس service_role، أعد NEW.login_user_id := OLD.login_user_id (بحيث لا يقدر العميل بتغيير الربط).

**ملفات متأثرة:** migration جديدة 028؛ trigger handle_new_user (في 002 أو في 028).

---

## 1.2 Migration: تعديل trigger trg_enforce_points لقراءة prayer_config

| البند | التفصيل |
|-------|---------|
| **رقم/اسم مقترح** | `029_prayer_points_from_config.sql` |
| **تعتمد على** | 001 (mosques.prayer_config، attendance)، 020 (trg_enforce_points) |
| **ما تضيفه** | استبدال دالة `trg_enforce_points()`: عند INSERT في attendance، إذا location_type = 'mosque' و mosque_id IS NOT NULL: جلب prayer_config من mosques للمسجد، استخراج قيمة الصلاة (NEW.prayer) من JSONB؛ إن لم توجد أو كانت NULL فالقيمة الافتراضية 10. إذا location_type = 'home': فجر=5، غير فجر=3 (ثابت). لا ثوابت للجماعة في الجسم — القراءة من mosques.prayer_config فقط. صيغة prayer_config المقترحة: `{"fajr": 10, "dhuhr": 0, "asr": 10, "maghrib": 10, "isha": 10}` (مفاتيح أسماء الصلوات كما في enum prayer). |
| **ما يكسر إن غابت** | النقاط تبقى ثابتة في DB؛ قرار الإمام بتعديل النقاط لا ينعكس. |

**تفصيل الدالة (للمرجع):**

```sql
CREATE OR REPLACE FUNCTION trg_enforce_points()
RETURNS TRIGGER AS $$
DECLARE
  v_config JSONB;
  v_points INT;
BEGIN
  IF NEW.location_type = 'home' THEN
    NEW.points_earned := CASE WHEN NEW.prayer = 'fajr' THEN 5 ELSE 3 END;
    RETURN NEW;
  END IF;
  IF NEW.location_type = 'mosque' AND NEW.mosque_id IS NOT NULL THEN
    SELECT prayer_config INTO v_config FROM mosques WHERE id = NEW.mosque_id;
    v_points := COALESCE((v_config->>NEW.prayer::TEXT)::INT, 10);
    NEW.points_earned := v_points;
    RETURN NEW;
  END IF;
  NEW.points_earned := 10;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**ملفات متأثرة:** migration 029 فقط.

---

## 1.3 Edge Function: إنشاء حساب الابن عند addChild

| البند | التفصيل |
|-------|---------|
| **تعتمد على** | 028 (دور child، children.login_user_id، trigger حماية login_user_id)، Supabase Auth Admin API |
| **ما تضيفه** | Edge Function (مثلاً `create_child_account`) تُستدعى من التطبيق بعد إدراج الطفل في children. المدخلات: child_id، (اختياري) email و password من ولي الأمر — إن وُجدان تُستخدمان؛ وإلا تُولَّد تلقائياً. الوظيفة: (1) التحقق من JWT أن المستخدم ولي أمر وأن child_id يخصه. (2) إنشاء مستخدم في auth.users عبر Admin API (بالإيميل وكلمة السر الممرّرين أو المولَّدين؛ raw_user_meta_data.role = 'child'). (3) trigger handle_new_user ينشئ صفاً في users برول child. (4) Edge Function بصلاحية service_role تُحدّث children SET login_user_id = ذلك users.id WHERE id = child_id. (5) إرجاع للعميل: email، password (مرة واحدة). |
| **ما يكسر إن غابت** | لا حساب للابن؛ لا تسجيل دخول بدور child. |

**ملفات متأثرة:** `supabase/functions/create_child_account/index.ts` (أو ما يُعتمد)، إعدادات المشروع لاستدعاء الدالة من التطبيق.

**مخاطر أمنية:** تسريب credentials إن نُقلت عبر قناة غير آمنة؛ عرض credentials مرة واحدة فقط وتنبيه ولي الأمر. الدالة تتحقق من ملكية الطفل لولي الأمر قبل أي إجراء.

---

## 1.4 Migration 026 (الإعلانات) وتأكيد Realtime

| البند | التفصيل |
|-------|---------|
| **تعتمد على** | 001 (جدول announcements) |
| **ما تضيفه** | تنفيذ محتوى `026_announcements.sql` كاملاً في Supabase (أعمدة is_pinned، updated_at، index، RLS الجديدة، Realtime لـ announcements). التأكد أن جداول correction_requests و notes و announcements في Publication `supabase_realtime` (007 يضيف correction_requests و notes؛ 026 يضيف announcements). إن لم تكن notes أو correction_requests في النشر، إضافتهما في migration أو يدوياً. |
| **ما يكسر إن غابت** | إعلانات المسجد بدون RLS صحيحة؛ Realtime للإعلانات أو التصحيحات/الملاحظات قد لا يعمل. |

**ملفات متأثرة:** تنفيذ 026 في SQL Editor؛ التحقق من 007 و 026 لـ Realtime.

---

## 1.5 اختبارات قبول — القسم 1

| البند | اختبار قبول (جملة واحدة) |
|-------|---------------------------|
| 1.1 | بعد تطبيق 028، إدراج صف في users برول child وربط children.login_user_id يسمح لذلك المستخدم بقراءة صف الطفل فقط عبر RLS. |
| 1.2 | بعد تطبيق 029، إدراج حضور لمسجد له prayer_config = {"dhuhr":0} يعطي points_earned = 0 لصلاة الظهر. |
| 1.3 | استدعاء Edge Function create_child_account بطفل تابع لولي أمر مسجّل يعيد email وكلمة سر ويُظهر تسجيل دخول ذلك الحساب بدور child. |
| 1.4 | سياسات 026 مطبّقة على announcements؛ جداول correction_requests و notes و announcements في supabase_realtime. |

---

# القسم 2 — RLS Audit المنهجي

كل جدول في المشروع: العملية، الدور، السياسة الحالية، ثغرة محتملة، الحل المطلوب.

| الجدول | العملية | الدور | السياسة الحالية | ثغرة محتملة | الحل المطلوب |
|--------|----------|-------|------------------|-------------|--------------|
| users | SELECT | ذاتي | read own profile | — | لا تغيير. دور child يقرأ ملفه (نفس السياسة). |
| users | INSERT | auth trigger | handle_new_user | — | إضافة دعم role=child في 028. |
| users | UPDATE | ذاتي | update own profile | — | لا تغيير. |
| children | SELECT | parent | parent reads own | — | لا تغيير. |
| children | SELECT | supervisor/imam | supervisors read mosque children | — | لا تغيير. |
| children | SELECT | **child** | — | الابن لا يرى طفله | إضافة "Children: child reads own" في 028 (login_user_id = current user). |
| children | INSERT | parent | parent inserts | — | لا تغيير. |
| children | UPDATE | parent | parent updates | ولي الأمر قد يعدّل total_points/streaks | 020 trg_protect_child_stats يمنع تعديل النقاط/السلاسل من العميل. التأكد أن تحديث login_user_id مسموح من الدالة فقط أو من Edge Function (سياق service). الأبسّط: السماح لولي الأمر بتحديث كل الأعمدة ما عدا total_points، current_streak، best_streak — والـ trigger يحمي الثلاثة. تحديث login_user_id: إما نسمح لولي الأمر بتحديثه مرة واحدة (لربط من التطبيق بدون Edge Function) أو نمنعه ونربط فقط من الخادم. حسب القرار: الربط من Edge Function فقط — إذن لا سياسة UPDATE للعميل على login_user_id؛ الدالة link_child_login_user SECURITY DEFINER تقوم بالتحديث. |
| mosques | SELECT/INSERT/UPDATE | حسب 001 | read approved, create, owner updates | — | لا تغيير. |
| mosque_members | * | حسب 001 | read own mosque, owner manages | — | لا تغيير. |
| mosque_children | * | حسب 001 | read, parent links | — | لا تغيير. |
| attendance | SELECT | parent / recorded_by | read own children, recorded_by | 018: mosque members read | لا تغيير. |
| attendance | SELECT | **child** | — | الابن لا يرى حضوره | إضافة سياسة: الابن يرى حضوره فقط — سجلات الحضور للطفل المرتبط بحسابه (child_id IN (SELECT id FROM children WHERE login_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()))). |
| attendance | INSERT | member | 021 member records | — | لا تغيير. |
| badges | SELECT | parent | read own children | **child** لا يرى شاراته | اختياري: إضافة سياسة child يقرأ badges لطفله. القرار: في الخطة الابن يرى "النقاط" فقط؛ الشارات يمكن تأجيلها. إن أردنا الابن يرى الشارات: إضافة "Badges: child reads own" بنفس شرط child. |
| rewards | * | parent | parent manages | — | لا تغيير. |
| correction_requests | SELECT | parent | 021 parent reads own | — | لا تغيير. |
| correction_requests | SELECT | supervisor/imam | supervisor reads mosque corrections | — | لا تغيير. |
| correction_requests | INSERT | parent | 021 parent creates | — | لا تغيير. |
| correction_requests | UPDATE | parent | **لا يوجد** | ولي الأمر لا يعدّل status | 021 فصل: parent له SELECT و INSERT فقط؛ لا سياسة UPDATE لولي الأمر. التحقق: لا سياسة UPDATE تستخدم parent_id فقط — فقط "supervisor reviews" للمسجد. ✅ لا ثغرة. |
| correction_requests | UPDATE | supervisor/imam | supervisor reviews | — | لا تغيير. |
| notes | SELECT | sender / parent | sender or parent reads | **child** لا يرى ملاحظاته | إضافة "Notes: child reads own" — الابن يرى ملاحظاته فقط (الملاحظات عن الطفل المرتبط بحسابه). |
| notes | INSERT | member | 021 mosque member sends | — | لا تغيير. |
| announcements | SELECT/INSERT/UPDATE/DELETE | حسب 026 | 026 (members+parents read, imam insert, creator update/delete) | — | لا تغيير. |
| competitions | * | حسب 022 | owner manages, members/parents read | — | لا تغيير. |
| mosque_join_requests | * | حسب 010–017 | — | — | لا تغيير. |

**ملخص إضافات RLS للدور child (في 028 أو migration لاحق):**

- children: SELECT WHERE login_user_id = current user.
- attendance: SELECT WHERE child_id IN (children that have login_user_id = current user).
- notes: SELECT WHERE child_id IN (children that have login_user_id = current user).

---

# القسم 3 — الخدمات والريپوهات

كل دالة جديدة أو معدّلة: توقيع + ريپو + من يستدعيها.

| الدالة | التوقيع | الريپو | من يستدعيها |
|--------|---------|--------|-------------|
| updateMosquePrayerPoints | `Future<void> updateMosquePrayerPoints(String mosqueId, Map<Prayer, int> points)` | ImamRepository | ImamBloc (حدث UpdateMosquePrayerPoints) |
| getProcessedCorrections | ترتيب النتائج بـ `reviewed_at` بدل `updated_at` | ImamRepository | ImamBloc / شاشة طلبات التصحيح المعالجة |
| getChildByLoginUserId | `Future<ChildModel?> getChildByLoginUserId(String userId)` — يستعلم children WHERE login_user_id = userId، مع التحقق من RLS | ChildRepository | عند تسجيل دخول دور child؛ ChildViewScreen أو Bloc الطفل |
| addChild | توسيع: بعد إدراج الطفل في children، استدعاء Edge Function create_child_account(childId، [email، password اختياري])؛ إرجاع credentials (email، password) للعرض مرة واحدة | ChildRepository | ParentBloc/ChildBloc (حدث AddChild) |
| getPrayerPointsForMosque | `Future<Map<Prayer, int>> getPrayerPointsForMosque(String mosqueId)` — يقرأ mosques.prayer_config ويُرجع خريطة صلاة → نقطة، افتراضي 10 | MosqueRepository أو ImamRepository | PointsService، PrayerPointsSettingsScreen |
| calculateAttendancePoints | تعديل: لـ location_type mosque لا تستخدم ثابتاً؛ تستدعي getPrayerPointsForMosque(mosqueId) وتأخذ نقطة الصلاة، أو تستقبل Map<Prayer,int> من الريپو. افتراضي 10 إن لم تُحدد. المنزل: فجر=5، غير فجر=3 ثابت | PointsService | SupervisorRepository.recordAttendance (قبل الإدراج للتحقق/عرض فقط؛ القيمة الفعلية من trigger) |
| getSupervisorsPerformance | توسيع: دالة ثانية أو معاملات اختيارية `DateTime? fromDate, DateTime? toDate` — إن وُجدت فترة تُجلب سجلات الحضور لكل مشرف ضمنها مع تفصيل صلوات إن أمكن | ImamRepository | لوحة الإمام (تقارير أداء المشرفين) |

**ملفات متأثرة:**  
`lib/app/features/imam/data/repositories/imam_repository.dart`، `lib/app/features/parent/data/repositories/child_repository.dart`، `lib/app/features/mosque/data/repositories/mosque_repository.dart` (أو imam لـ getPrayerPoints)، `lib/app/core/services/points_service.dart`، وربط PointsService بجلب prayer_config من الريپو (أو تمرير mosqueId وقراءة النقاط من الريپو عند كل حساب).

---

# القسم 4 — منطق الـ Blocs (أحداث جديدة أو معدّلة فقط)

| Bloc | الحدث الجديد/المعدّل | الوصف |
|------|------------------------|-------|
| ImamBloc | UpdateMosquePrayerPoints(mosqueId, Map<Prayer,int> points) | يستدعي ImamRepository.updateMosquePrayerPoints ثم يحدّث الحالة أو يعيد تحميل إعدادات المسجد. |
| AuthBloc / منطق التوجيه | بعد تسجيل الدخول: إن كان user.role == child → توجيه إلى /child-view | في نفس مكان التوجيه الحالي (parent→/home، imam→/mosque، إلخ) إضافة branch لـ child. |
| ParentBloc أو ChildBloc | AddChild: بعد نجاح الإدراج واستدعاء Edge Function، استقبال credentials (email، password) وحفظها في state لعرضها مرة واحدة (شاشة "احفظ بيانات الدخول لابنك"). | الشاشة تعرض الإيميل وكلمة السر مع تحذير "لن تظهر مجدداً"؛ بعد الإغلاق أو الانتقال تُزال من state. |

**ملفات متأثرة:**  
`lib/app/features/imam/presentation/bloc/imam_bloc.dart` (وأحداثه)، نقطة التوجيه بعد Login (router أو auth listener)، `lib/app/features/parent/` أو child bloc عند addChild.

---

# القسم 5 — الواجهات

فقط: اسم الشاشة | route | Bloc | من يصل إليها | ملاحظة UX واحدة.

| الشاشة | route | Bloc | من يصل إليها | ملاحظة UX |
|--------|-------|------|---------------|-----------|
| ChildViewScreen | /child-view | ChildBloc أو بيانات من ChildRepository مباشرة | دور child فقط (بعد تسجيل الدخول) | قراءة فقط: الاسم، الباركود، حضور اليوم، النقاط الإجمالية؛ لا أزرار تعديل. |
| PrayerPointsSettingsScreen | /imam/mosque/:id/prayer-points أو ضمن إعدادات المسجد | ImamBloc | الإمام فقط | 5 صلوات، حقل نقاط لكل صلاة، زر حفظ؛ تحذير أن التغيير ينطبق فوراً (بما فيه المسابقة الجارية). |
| عرض credentials الابن | مسار مؤقت أو ديالوغ بعد إضافة الطفل | ParentBloc/ChildBloc | ولي الأمر | تظهر مرة واحدة بعد addChild + Edge Function؛ إيميل وكلمة سر مع نص "احفظها الآن، لن تظهر مجدداً" وزر "تم". |
| توجيه تسجيل الدخول | — | منطق Router/Auth | الكل | parent/imam/super_admin → المسارات المعتادة؛ child → /child-view. |

باقي الشاشات الموجودة (بوابة المسجد، لوحة الإمام، التحضير، أطفالي، إلخ) لا تُعدّل في هذا الجدول إلا إن لزم ربطها ببنود الخطة (مثلاً رابط من لوحة الإمام إلى PrayerPointsSettingsScreen).

---

# القسم 6 — ترتيب التنفيذ الخطي

كل بند يذكر ما يفتحه للبند التالي + مدة تقديرية بالساعات.

1. **تنفيذ migration 028 (دور child، login_user_id، RLS child، handle_new_user)** — يفتح: Edge Function واختبار تسجيل دخول الابن. [~2–3 س]
2. **تنفيذ migration 029 (trigger نقاط من prayer_config)** — يفتح: PointsService وواجهة إعداد النقاط. [~1 س]
3. **إضافة trigger حماية login_user_id على children (ضمن 028)** — منع العميل من تحديث login_user_id؛ التحديث من service_role فقط. [مدرج في 1]
4. **إنشاء Edge Function create_child_account** وربطها من التطبيق عند addChild. [~3–4 س]
5. **تنفيذ 026 إن لم يكن منفّذاً** + التحقق من Realtime لـ correction_requests، notes، announcements. [~0.5 س]
6. **RLS Audit: إضافة سياسات SELECT للدور child** على children، attendance، notes (ضمن 028 أو migration لاحق). [~0.5 س]
7. **ImamRepository: updateMosquePrayerPoints، getPrayerPointsForMosque؛ تصحيح getProcessedCorrections (reviewed_at)**. [~1 س]
8. **PointsService: إزالة ثوابت الجماعة، قراءة النقاط من الريپو (getPrayerPointsForMosque)**. [~1 س]
9. **SupervisorRepository.recordAttendance:** تمرير mosqueId لـ PointsService أو جلب النقاط من المسجد قبل الحساب (للتحقق فقط؛ القيمة الفعلية من trigger). [~0.5 س]
10. **ChildRepository: getChildByLoginUserId؛ توسيع addChild لاستدعاء Edge Function وإرجاع credentials.** [~1.5 س]
11. **ImamBloc: حدث UpdateMosquePrayerPoints.** [~0.5 س]
12. **توجيه بعد تسجيل الدخول: role child → /child-view.** [~0.5 س]
13. **ParentBloc/ChildBloc: عند AddChild استقبال credentials وعرضها مرة واحدة.** [~1 س]
14. **شاشة ChildViewScreen (route /child-view، بيانات من getChildByLoginUserId + حضور اليوم + نقاط).** [~2 س]
15. **شاشة PrayerPointsSettingsScreen (للإمام، 5 صلوات + حفظ).** [~1.5 س]
16. **شاشة/ديالوغ عرض credentials الابن بعد الإضافة (مرة واحدة).** [~1 س]
17. **ImamRepository.getSupervisorsPerformance توسيع لفترة زمنية (اختياري للجدول الزمني).** [~1 س]

**المجموع التقريبي:** ~18–22 ساعة.

---

# القسم 7 — ما لن يُبنى في هذا المشروع

| البند | السبب | ملاحظة للمستقبل |
|-------|--------|------------------|
| صور المستخدمين | قرار محسوم (القرار 1). | لا حقول avatar، لا رفع، لا واجهة. |
| تسجيل صلاة المنزل يدوياً | قرار محسوم (القرار 4). DB جاهز (location_type=home). | عند التصميم: من يسجّل (طفل/ولي أمر)، نافذة الوقت، احتساب المسابقة، صلاحية الإمام لتعطيلها. |
| كود ربط مؤقت للابن | استُبدل بحساب auth حقيقي (القرار 2). | لا child_link_codes، لا تخزين محلي لربط الجهاز. |
| أقرب مسجد | خارج نطاق الخطة الحالية. | يحتاج مساجد ذات إحداثيات وواجهة اقتراح. |
| اعتراف/تحقق المسجد | خارج النطاق. | سير معقد؛ يؤجل. |
| Offline للمسجد | خارج النطاق. | تخزين محلي ومزامنة. |
| FCM من الخادم | خارج النطاق. | إشعارات عند أحداث (حضور، تصحيح، ملاحظة، إلخ). |
| واجهة الجوائز والشارات | خارج النطاق. | جداول rewards و badges موجودة؛ العرض لاحقاً. |
| مسجد أساسي + ثانوي (واجهة) | خارج النطاق. | الحقل موجود في mosque_children. |

---

# تناقضات تم حسمها في هذه الوثيقة

- **الوثائق القديمة** ذكرت أحياناً "ربط جهاز الابن بكود مؤقت" و"عرض الابن بدون تسجيل". القرار النهائي: **حساب auth حقيقي بدور child**؛ لا كود ربط ولا تخزين محلي.
- **النقاط:** وثائق سابقة تركت prayer_config غير مستخدم. القرار: **trigger و PointsService يقرآن من prayer_config**؛ لا ثوابت للجماعة في الكود أو في الـ trigger.
- **ولي الأمر وتعديل status في correction_requests:** تم التحقق في 021 أن ولي الأمر له SELECT و INSERT فقط؛ لا سياسة UPDATE له — لا ثغرة.
- **getProcessedCorrections:** الجدول لا يملك عمود updated_at؛ الترتيب يكون بـ **reviewed_at** فقط.

---

*هذه الوثيقة هي الخطة التنفيذية النهائية الوحيدة. أي تعارض مع وثائق أخرى يُحسم لصالح هذه الوثيقة.*
