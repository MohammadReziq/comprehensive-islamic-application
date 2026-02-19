# خطة التنفيذ العملية — مهام مرقمة (صلاتي حياتي)

مرجع الاستراتيجية: `EXECUTION_PLAN_FINAL.md`.  
هذه الوثيقة **مهام تنفيذية فقط** — مهمة واحدة في كل مرة، مع التبعيات وخطوة التحقق. عند إكمال مهمة تقول "تم" وتنتقل للتالية.

**السيناريو المعتمد لحساب الابن (إجباري):**
1. الطلب: تطبيق Flutter يرسل إيميل الابن وكلمة السر للـ Edge Function.
2. التحقق: الـ Edge Function تتأكد أولاً (باستخدام JWT) أن الطالب هو ولي أمر وأن الطفل يخصه.
3. الإنشاء: الـ Edge Function تستخدم مفتاح الماستر (service_role) لإنشاء حساب الابن في Supabase Auth.
4. الأتمتة: Trigger في SQL (handle_new_user) ينشئ صفاً للابن في جدول users.
5. الربط: الـ Edge Function تربط حساب الابن بجدول children (تحديث login_user_id).
6. النتيجة: الـ Edge Function ترسل رسالة نجاح (مع email و password) للتطبيق.

---

## المهمة 1 — إنشاء ملف migration 028 وكتابة محتواه (بدون تشغيل)

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- وجود المشروع مع Supabase ومجلد `supabase/migrations/` ووجود migrations 001 و 002 (على الأقل).

**ماذا سأفعل بالضبط:**
- إنشاء ملف جديد: `supabase/migrations/028_child_account.sql`.
- كتابة المحتوى التالي داخل الملف (بدون تنفيذ في Supabase بعد):
  1. `ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'child';`  
     (إن كان المشروع يستخدم إصداراً لا يدعم IF NOT EXISTS، استخدم `ALTER TYPE user_role ADD VALUE 'child';` مع التأكد أن القيمة غير مضافة مسبقاً.)
  2. `ALTER TABLE children ADD COLUMN IF NOT EXISTS login_user_id UUID REFERENCES users(id) ON DELETE SET NULL;`
  3. سياسة RLS:  
     `CREATE POLICY "Children: child reads own" ON children FOR SELECT USING (login_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));`
  4. تحديث دالة `handle_new_user()`: إضافة في الـ CASE الخاص بالدور:  
     `WHEN 'child' THEN user_role_val := 'child'::user_role;`
  5. Trigger حماية عمود login_user_id: إن المُحدّث ليس من سياق service_role، إعادة `NEW.login_user_id := OLD.login_user_id` (دالة BEFORE UPDATE على children).
  6. سياسات RLS للدور child على attendance و notes:  
     - attendance: الابن يرى حضوره فقط (سجلات الحضور للطفل المرتبط بحسابه):  
       `CREATE POLICY "Attendance: child reads own" ON attendance FOR SELECT USING (child_id IN (SELECT id FROM children WHERE login_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())));`  
     - notes: الابن يرى ملاحظاته فقط (الملاحظات عن الطفل المرتبط بحسابه):  
       `CREATE POLICY "Notes: child reads own" ON notes FOR SELECT USING (child_id IN (SELECT id FROM children WHERE login_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())));`

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- الملف `supabase/migrations/028_child_account.sql` موجود.
- المحتوى يضم: إضافة child لـ user_role، إضافة العمود login_user_id، سياسة "Children: child reads own"، تحديث handle_new_user بدعم child، trigger حماية login_user_id، وسياستي attendance و notes للابن.
- لا أخطاء syntax واضحة (يمكن فتح الملف ومراجعته سطراً سطراً).

---

## المهمة 2 — تنفيذ migration 028 في Supabase والتحقق منها

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 1 (ملف 028 مكتوب بالكامل).

**ماذا سأفعل بالضبط:**
- فتح Supabase Dashboard → SQL Editor.
- نسخ محتوى `supabase/migrations/028_child_account.sql` كاملاً ولصقه في استعلام جديد.
- تشغيل الاستعلام.
- في حال ظهور خطأ (مثلاً القيمة child مضافة مسبقاً): معالجة الخطأ (إزالة السطر المكرر أو استخدام شرط) ثم إعادة التشغيل حتى ينجح التنفيذ بالكامل.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- تنفيذ الـ SQL ينتهي بدون أخطاء.
- من SQL Editor تنفيذ:  
  `SELECT enumlabel FROM pg_enum WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_role');`  
  → النتيجة تحتوي القيمة `child`.
- تنفيذ:  
  `SELECT column_name FROM information_schema.columns WHERE table_name = 'children' AND column_name = 'login_user_id';`  
  → يُرجع صفاً واحداً.
- تنفيذ:  
  `SELECT policyname FROM pg_policies WHERE tablename = 'children' AND policyname = 'Children: child reads own';`  
  → يُرجع صفاً واحداً.
- (اختياري) التحقق من وجود سياسات "Attendance: child reads own" و "Notes: child reads own" على الجداول المعنية.

---

## المهمة 3 — إنشاء ملف migration 029 وكتابة trigger النقاط من prayer_config

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 2 (028 منفّذة ومتحقق منها).

**ماذا سأفعل بالضبط:**
- إنشاء ملف: `supabase/migrations/029_prayer_points_from_config.sql`.
- كتابة استبدال دالة `trg_enforce_points()` بحيث:
  - إذا `location_type = 'home'`: فجر = 5، غير فجر = 3 (ثابت).
  - إذا `location_type = 'mosque'` و `mosque_id IS NOT NULL`: قراءة `prayer_config` من جدول `mosques` للمسجد، استخراج قيمة الصلاة (مفتاح اسم الصلاة كما في enum)، إن لم توجد أو كانت NULL فالقيمة 10. **لا ثوابت للجماعة في الجسم** — القراءة من DB فقط.
- استخدام نفس اسم الـ trigger الموجود: `enforce_points_trigger` على جدول `attendance` BEFORE INSERT.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- الملف موجود ومحتواه يطابق المواصفة أعلاه.
- لا يوجد في جسم الدالة رقم ثابت 10 للجماعة إلا كقيمة افتراضية عند غياب المفتاح في prayer_config (مثلاً COALESCE(..., 10)).

---

## المهمة 4 — تنفيذ migration 029 في Supabase والتحقق منها

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 3 (ملف 029 مكتوب).

**ماذا سأفعل بالضبط:**
- فتح Supabase → SQL Editor.
- نسخ محتوى `supabase/migrations/029_prayer_points_from_config.sql` وتشغيله.
- في حال خطأ: تصحيح المحتوى وإعادة التشغيل حتى النجاح.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- التنفيذ ينجح بدون أخطاء.
- اختبار يدوي: تحديث مسجد معيّن بـ `prayer_config = '{"dhuhr": 0}'::jsonb`، ثم إدراج سجل حضور تجريبي لذلك المسجد لصلاة الظهر (عبر SQL أو من التطبيق إن كان التحضير يعمل). الاستعلام عن الصف المُدرج: عمود `points_earned` يجب أن يكون 0 لصلاة الظهر. إن كان 10 فالثابت ما زال مستخدماً — مراجعة الدالة.

---

## المهمة 5 — تنفيذ migration 026 (الإعلانات) والتحقق من Realtime

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- لا تعتمد على 028 أو 029. يمكن تنفيذها بعد المهمة 2 إن رغبت، أو هنا بعد 4.

**ماذا سأفعل بالضبط:**
- فتح Supabase → SQL Editor.
- نسخ محتوى `supabase/migrations/026_announcements.sql` كاملاً وتشغيله.
- التحقق من أن جداول `correction_requests` و `notes` و `announcements` في الـ Publication الخاصة بـ Realtime (مثلاً `supabase_realtime`). إن لم تكن، تنفيذ:  
  `ALTER PUBLICATION supabase_realtime ADD TABLE correction_requests;`  
  `ALTER PUBLICATION supabase_realtime ADD TABLE notes;`  
  (وannouncements عادة تُضاف داخل 026.)

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- تنفيذ 026 ينجح بدون أخطاء.
- استعلام:  
  `SELECT tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename IN ('correction_requests','notes','announcements');`  
  → يُرجع ثلاثة صفوف (أو حسب أسماء الجداول في مشروعك).

---

## المهمة 6 — إنشاء Edge Function create_child_account (الخطوات الست الإجبارية)

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 2 والتحقق من 028 (دور child، عمود login_user_id، trigger حماية login_user_id، سياسات child).

**ماذا سأفعل بالضبط:**
- إنشاء مجلد الدالة: `supabase/functions/create_child_account/`.
- إنشاء الملف `supabase/functions/create_child_account/index.ts` (أو الاسم المعتمد في مشروعك لـ Deno).
- تنفيذ الدالة حسب **السيناريو الإجباري**:
  1. **الطلب:** استقبال من الجسم: `child_id`، `email` (إيميل الابن)، `password` (كلمة سر الابن). التطبيق Flutter يرسل هذه الحقول.
  2. **التحقق:** استخراج JWT من الـ request (Header Authorization أو ما يوفره Supabase). التحقق أن المستخدم الحالي ولي أمر وأن `child_id` يخصه: استعلام من جدول `children` أن `id = child_id` و `parent_id` يطابق `users.id` للمستخدم الحالي (من JWT). إن لم يطابق — إرجاع 403.
  3. **الإنشاء:** استخدام مفتاح الماستر (service_role أو Admin API) لإنشاء مستخدم في Supabase Auth بالـ email والـ password الممرّرين، مع `raw_user_meta_data` يحتوي `role: 'child'` (واسم الابن إن أردت).
  4. **الأتمتة:** لا كود إضافي — بمجرد إنشاء الحساب في Auth، الـ Trigger `handle_new_user` في SQL ينشئ صفاً في جدول `users` برول child.
  5. **الربط:** بعد إنشاء الحساب، جلب `users.id` للمستخدم الجديد (من Auth أو من جدول users بالبريد). ثم باستخدام client بصلاحية service_role: `UPDATE children SET login_user_id = <ذلك users.id> WHERE id = child_id`. (التحقق أن child_id لم يتغير وأن الربط لطفل تابع لولي الأمر تم في الخطوة 2.)
  6. **النتيجة:** إرجاع 200 مع body يحتوي `{ "email": "...", "password": "..." }` (أو رسالة نجاح مع نفس البيانات) للتطبيق.
- تهيئة الدالة في المشروع (إن وُجدت أوامر مثل `supabase functions new` أو إعدادات في `supabase/config.toml`).

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- الملف موجود والخطوات الست مذكورة في التعليقات أو المنطق.
- نشر الدالة (إن أمكن في بيئة التطوير) واستدعاؤها من Postman أو curl بجسم يحتوي child_id و email و password و JWT ولي أمر صالح — الاستجابة 200 وتحتوي email و password، وفي DB يظهر صف في users برول child و children.login_user_id محدّث لذلك الطفل.

---

## المهمة 7 — تصحيح ImamRepository: getProcessedCorrections وترتيب reviewed_at

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- لا تعتمد على migrations. يمكن تنفيذها بعد المهمة 4.

**ماذا سأفعل بالضبط:**
- فتح ملف `lib/app/features/imam/data/repositories/imam_repository.dart`.
- البحث عن استدعاء يرتب نتائج `getProcessedCorrections` (أو ما يعادل) بـ `updated_at`.
- استبدال الترتيب ليكون بـ `reviewed_at` (جدول correction_requests لا يملك عمود updated_at). إذا وُجدت استدعاءات أخرى لنفس الجدول ترتب بـ updated_at، تصحيحها أيضاً.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- لا وجود لـ `order('updated_at'` أو ما يعادله في استعلامات جدول correction_requests في هذا الملف.
- تشغيل التطبيق وفتح شاشة طلبات التصحيح المعالجة (إن وُجدت) — لا يظهر خطأ من قاعدة البيانات.

---

## المهمة 8 — ImamRepository: إضافة updateMosquePrayerPoints و getPrayerPointsForMosque

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 4 (029 منفّذة؛ prayer_config مستخدم في الـ trigger).

**ماذا سأفعل بالضبط:**
- في `lib/app/features/imam/data/repositories/imam_repository.dart` (أو في MosqueRepository إن وُجد اتفاق على المكان):
  - إضافة دالة `Future<void> updateMosquePrayerPoints(String mosqueId, Map<Prayer, int> points)`: تحويل الخريطة إلى JSON (مفاتيح أسماء الصلوات كما في enum) وحفظها في `mosques.prayer_config` للمسجد. التحقق أن المستخدم الحالي هو owner المسجد (من mosque_members أو mosques.owner_id).
  - إضافة دالة `Future<Map<Prayer, int>> getPrayerPointsForMosque(String mosqueId)`: قراءة عمود `prayer_config` من جدول mosques للمسجد، تحويل القيم إلى خريطة Prayer → int، مع افتراضي 10 لأي صلاة غير موجودة أو null.
- تسجيل الدوال في نفس الريپو (لا إنشاء ملف جديد إن لم يكن ضرورياً).

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- التطبيق يبنى بدون أخطاء.
- استدعاء getPrayerPointsForMosque لمسجد له prayer_config = {"dhuhr": 0} يُرجع خريطة تحتوي 0 للظهر و 10 للباقي (أو حسب المنطق المتفق عليه).

---

## المهمة 9 — PointsService: إزالة ثوابت الجماعة وقراءة النقاط من الريپو

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 8 (وجود getPrayerPointsForMosque أو ما يعادلها).

**ماذا سأفعل بالضبط:**
- فتح `lib/app/core/services/points_service.dart`.
- إزالة الثوابت الثابتة لصلاة الجماعة (مثلاً mosquePrayerPoints = 10) من حساب النقاط في الدالة التي تستخدمها تسجيل الحضور.
- جعل حساب النقاط للجماعة يعتمد على إما: استدعاء ريپو (getPrayerPointsForMosque) أو استقبال معامل (خريطة نقاط الصلوات) من المستدعي. القيمة الافتراضية عند غياب قيمة لصلاة معينة: 10.
- الإبقاء على ثوابت صلاة المنزل: فجر = 5، غير فجر = 3.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- لا يوجد في PointsService ثابت واحد يستخدم مباشرة لنقاط صلاة الجماعة (مثل 10) إلا كقيمة افتراضية عند غياب إعداد المسجد.
- SupervisorRepository.recordAttendance يمرّر mosqueId أو خريطة النقاط عند استدعاء حساب النقاط (للعرض/التحقق فقط؛ القيمة الفعلية من trigger الـ DB).

---

## المهمة 10 — SupervisorRepository: تمرير mosqueId أو نقاط المسجد لـ PointsService

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 9 (PointsService تقبل مصدر نقاط الجماعة من المسجد).

**ماذا سأفعل بالضبط:**
- فتح `lib/app/features/supervisor/data/repositories/supervisor_repository.dart`.
- في دالة `recordAttendance`: قبل إدراج الحضور، جلب نقاط المسجد (من ImamRepository أو MosqueRepository.getPrayerPointsForMosque(mosqueId)) وتمريرها إلى PointsService عند حساب النقاط، أو تمرير mosqueId إن كانت PointsService تجلب النقاط بنفسها. الهدف: أن يعكس الحساب في التطبيق (للتحقق أو العرض) نفس منطق الـ trigger؛ القيمة المُدرجة في DB يحددها الـ trigger فقط.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- تسجيل حضور لمسجد له prayer_config الظهر = 0 يُرجع (أو يعرض) 0 نقطة من الحساب في التطبيق، والقيمة المُدرجة في attendance من الـ trigger هي 0.

---

## المهمة 11 — ChildRepository: getChildByLoginUserId

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 2 (028؛ عمود login_user_id و RLS للابن).

**ماذا سأفعل بالضبط:**
- فتح `lib/app/features/parent/data/repositories/child_repository.dart` (أو الملف الذي يحتوي عمليات الأطفال).
- إضافة دالة: `Future<ChildModel?> getChildByLoginUserId(String userId)` — استعلام من جدول children WHERE login_user_id = userId، مع select بالحقول المطلوبة لـ ChildModel، وإرجاع صف واحد أو null. الـ RLS للدور child تسمح بقراءة الصف إن كان userId يطابق المستخدم الحالي.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- التطبيق يبنى بدون أخطاء.
- عند تسجيل دخول مستخدم بدور child (بعد تنفيذ المهمة 6)، استدعاء getChildByLoginUserId(ذلك المستخدم.id) يُرجع بيانات الطفل المرتبط به.

---

## المهمة 12 — ChildRepository: توسيع addChild لاستدعاء Edge Function وإرجاع credentials

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 6 (Edge Function create_child_account تعمل وتُرجع email و password).

**ماذا سأفعل بالضبط:**
- في نفس ملف ChildRepository (أو حيث توجد دالة إضافة الطفل): بعد إدراج الطفل في جدول children بنجاح، استدعاء Edge Function `create_child_account` مع تمرير: child_id (المُدرج)، email (من ولي الأمر أو مولّد من الدالة)، password (من ولي الأمر أو مولّد). استخدام JWT الحالي (ولي الأمر) في الـ request.
- قراءة الاستجابة؛ إن كانت نجاح (200)، استخراج email و password من الـ body وإرجاعهما مع نتيجة addChild (مثلاً كائن يحتوي ChildModel و optional email و password) حتى يعرضهما التطبيق مرة واحدة لولي الأمر.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- من التطبيق: ولي أمر يضيف طفلاً (مع إدخال إيميل وكلمة سر للابن إن كانت الواجهة تدعمها) — العملية تكتمل ويُرجع للتطبيق email و password (أو رسالة نجاح تحتويهما)، وفي Supabase يظهر للمستخدم الجديد صف في users برول child و children.login_user_id محدّث.

---

## المهمة 13 — ImamBloc: حدث UpdateMosquePrayerPoints

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 8 (ImamRepository.updateMosquePrayerPoints موجودة).

**ماذا سأفعل بالضبط:**
- فتح ملف الـ Bloc الخاص بالإمام (مثلاً `lib/app/features/imam/presentation/bloc/imam_bloc.dart` وأحداثه).
- إضافة حدث جديد: مثلاً `UpdateMosquePrayerPoints(mosqueId, Map<Prayer, int> points)`.
- في الـ handler: استدعاء ImamRepository.updateMosquePrayerPoints ثم إما إصدار حالة نجاح أو إعادة تحميل إعدادات المسجد.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- التطبيق يبنى بدون أخطاء.
- إطلاق الحدث من واجهة (لاحقاً) يغيّر prayer_config في DB ويُحدّث العرض إن وُجد.

---

## المهمة 14 — توجيه تسجيل الدخول: دور child → /child-view

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- وجود نقطة توجيه بعد تسجيل الدخول (router أو auth listener) ووجود مسار /child-view (حتى لو الشاشة فارغة أو placeholder).

**ماذا سأفعل بالضبط:**
- فتح الملف الذي يحدد التوجيه بعد تسجيل الدخول (مثلاً في Router أو AuthBloc أو splash/home).
- إضافة شرط: إن كان `user.role == 'child'` (أو القيمة المعادلة في المشروع) → التوجيه إلى المسار `/child-view` بدل المسارات المعتادة (home، mosque، admin، إلخ).

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- تسجيل دخول بحساب بدور child يوجّه المستخدم إلى /child-view وليس إلى الصفحة الرئيسية لولي الأمر أو غيرها.

---

## المهمة 15 — شاشة ChildViewScreen (قراءة فقط: اسم، باركود، حضور اليوم، نقاط)

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 11 (getChildByLoginUserId)، والمهمة 14 (التوجيه إلى /child-view).

**ماذا سأفعل بالضبط:**
- إنشاء (أو فتح) الشاشة المرتبطة بمسار `/child-view`.
- جلب بيانات الطفل عبر getChildByLoginUserId(المستخدم الحالي.id) وحضور اليوم والنقاط (من ChildRepository أو دوال موجودة مناسبة).
- عرض: الاسم، الباركود، حضور اليوم، النقاط الإجمالية — بدون أزرار تعديل أو حذف.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- تسجيل دخول بدور child يعرض الشاشة مع بيانات الطفل الصحيحة (نفس الطفل المرتبط بـ login_user_id) والباركود والحضور والنقاط.

---

## المهمة 16 — ParentBloc/ChildBloc: استقبال credentials بعد AddChild وعرضها مرة واحدة

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 12 (addChild يُرجع email و password من Edge Function).

**ماذا سأفعل بالضبط:**
- في الـ Bloc الذي يتعامل مع حدث إضافة الطفل: عند نجاح addChild واستلام email و password من الريپو، تخزينهما في الـ state (مثلاً childCredentials أو ما شابه) لعرضهما في الواجهة.
- التأكد أن الواجهة تعرضهما مرة واحدة فقط (شاشة أو ديالوغ "احفظ بيانات الدخول لابنك") مع تحذير "لن تظهر مجدداً"، وبعد الإغلاق أو الانتقال إزالة credentials من الـ state.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- عند إضافة طفل من ولي الأمر، تظهر شاشة أو ديالوغ يعرض الإيميل وكلمة السر مع التحذير، وبعد الضغط على "تم" أو الخروج لا تُعاد عرض credentials من نفس العملية.

---

## المهمة 17 — شاشة/ديالوغ عرض credentials الابن بعد الإضافة (مرة واحدة)

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 16 (الـ Bloc يضع credentials في state).

**ماذا سأفعل بالضبط:**
- إنشاء شاشة أو ديالوغ يُعرض بعد نجاح إضافة الطفل عندما يكون هناك credentials في الـ state: عرض الإيميل وكلمة السر، نص تحذير "احفظها الآن، لن تظهر مجدداً"، وزر "تم" (أو ما يعادله) يغلق المعرض ويُزيل credentials من الـ state.
- ربط هذا المعرض بمسار إضافة الطفل أو بالشاشة التي تُفتح بعد addChild.

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- سيناريو كامل: ولي أمر يضيف طفلاً → يظهر المعرض مع الإيميل وكلمة السر والتحذير → يضغط "تم" → المعرض يختفي ولا تُعاد عرض credentials عند العودة لنفس الشاشة بدون إضافة طفل جديد.

---

## المهمة 18 — شاشة إعداد نقاط الصلوات للإمام (PrayerPointsSettingsScreen)

**ما الذي يجب أن يكون جاهزاً قبلها:**  
- اكتمال المهمة 13 (ImamBloc حدث UpdateMosquePrayerPoints).

**ماذا سأفعل بالضبط:**
- إنشاء شاشة (أو إضافة قسم في إعدادات المسجد): route مثل `/imam/mosque/:id/prayer-points` أو ضمن إعدادات المسجد، للإمام فقط.
- عرض 5 صلوات مع حقل إدخال (نقاط) لكل صلاة وزر "حفظ". عند الحفظ استدعاء ImamBloc.add(UpdateMosquePrayerPoints(mosqueId, الخريطة)).
- إضافة تحذير نصي أن التغيير ينطبق فوراً (بما فيه المسابقة الجارية إن وُجدت).
- إضافة رابط من لوحة الإمام إلى هذه الشاشة (من قائمة أو إعدادات المسجد).

**كيف أتحقق أنها اكتملت قبل الانتقال للتالية:**
- الإمام يفتح إعدادات نقاط الصلوات، يغيّر نقطة صلاة (مثلاً الظهر = 0)، يحفظ — ثم تسجيل حضور لصلاة الظهر في ذلك المسجد يُسجّل 0 نقطة (من الـ trigger في DB).

---

انتهت قائمة المهام العملية. بعد كل مهمة قل "تم" ثم انتقل للمهمة التالية. لا تنفّذ مهمة قبل اكتمال التحقق من سابقتها.
