# خطة التنفيذ النهائية — تطبيق صلاتي حياتي
> بناءً على دراسة v4 + استكشاف الكود الكامل
> التاريخ: 2026-03-03

---

## إجابات الأسئلة المفتوحة أولاً

**"لو قرر الإمام ينشئ المسابقة بعدين؟"**
→ الـ Setup Checklist يبقى على dashboard الإمام. "لاحقاً" ينقله للوحته والـ checklist يظل مرئياً حتى يكمل الخطوات الثلاث.

**"مسابقة السوبر أدمن لعدة مساجد"**
→ لا نعمله الآن. معقد ومش ضروري. يُضاف كـ O8 مستقبلاً.

**"QR بدون نت"**
→ نحفظ QR data محلياً في SharedPreferences. الطفل يقدر يعرضه offline.

**"نقاط الصلوات + تغيير أثناء المسابقة"**
→ `prayer_points_settings_screen.dart` موجود بالفعل! نتأكد أنه يعمل صح. أي تغيير أثناء المسابقة = إعلان تلقائي.

**"فش حدا بقدر يحذف حسابه"**
→ موجود بالفعل (delete_my_account RPC). الـ cascade policy تبقى كما هي.

**"Onboarding ولي الأمر + كود المسجد"**
→ نضيف خطوة الكود مباشرة في الـ onboarding.

---

## ما الموجود بالفعل (لا نعيد كتابته)

✅ `correction_requests` table + screens (تحتاج تعديل فقط)
✅ `prayer_points_settings_screen.dart` (تحتاج تحقق)
✅ `mosque.attendance_window_minutes` field في الـ DB
✅ `mosque_children.local_number` + unique constraint
✅ QR display widget + scanner
✅ Realtime service (تحتاج توسيع)
✅ `activate_competition` RPC
✅ `announcement` system كامل

---

## قائمة التغييرات — مرتبة بالأولوية

```
C = Critical (قبل أي إطلاق)
I = Important (قبل الإطلاق العام)
E = Enhancement (بعد الإطلاق)
```

---

# ═══════════════════════════════════════════════
# [C1] نظام تسجيل الإمام — السوبر أدمن ينشئ الحساب
# ═══════════════════════════════════════════════

## المشكلة الحالية
السوبر أدمن لا يملك واجهة لإنشاء حساب الإمام.
الإمام حالياً يسجل نفسه من شاشة Register (يجب إزالة هذا).

## ما يتغير في قاعدة البيانات
لا تغيير في الـ schema. نستخدم Admin API لإنشاء المستخدم.

## ما يتغير في Supabase Edge Functions
**إنشاء Edge Function جديدة: `create-imam-account`**

```typescript
// supabase/functions/create-imam-account/index.ts
// المستدعي: Super Admin فقط

Request body:
{
  name: string,
  email: string,
  temp_password: string  // يُولَّد في الـ client
}

الخطوات:
1. تحقق أن المستدعي superAdmin (من JWT)
2. استخدم Admin API: supabaseAdmin.auth.admin.createUser({email, password, email_confirm: true})
3. أضف سجل في public.users مع role='imam'
4. أعد البيانات للـ client

Response:
{ user_id, email, temp_password }

أسباب الفشل → رسائل واضحة:
- الإيميل موجود مسبقاً → "هذا الإيميل مسجّل بالفعل"
- إيميل غير صالح → "صيغة الإيميل غير صحيحة"
```

## ما يتغير في Flutter

### `lib/app/features/super_admin/presentation/screens/admin_screen.dart`
**إضافة زر "إنشاء حساب إمام":**
```dart
// أضف FloatingActionButton أو زر في الـ AppBar
// يفتح Dialog أو BottomSheet:

// حقول:
// - اسم الإمام (TextField, required)
// - إيميله (TextField, email validation, required)
// - كلمة سر (TextField مع زر "توليد تلقائي")

// "توليد تلقائي" يُنتج: imam_[random 6 chars]
// مثال: imam_Ab3K9x

// بعد الإنشاء → يظهر Dialog النتيجة:
// ┌──────────────────────────────────────┐
// │ ✓ تم إنشاء حساب الإمام بنجاح       │
// │ الإيميل: imam@mosque.com            │
// │ كلمة السر: imam_Ab3K9x              │
// │ [نسخ البيانات] [مشاركة بواتساب]    │
// └──────────────────────────────────────┘

// "مشاركة بواتساب" يستخدم:
// url_launcher: 'https://wa.me/?text=${Uri.encodeComponent(message)}'
// message = "بسم الله، بيانات دخولك لتطبيق صلاتي حياتي:\n..."
```

**إضافة Repository Method:**
```dart
// lib/app/features/super_admin/data/repositories/admin_repository.dart
Future<Map<String, dynamic>> createImamAccount({
  required String name,
  required String email,
  required String tempPassword,
}) async {
  final response = await supabase.functions.invoke(
    'create-imam-account',
    body: {'name': name, 'email': email, 'temp_password': tempPassword},
  );
  if (response.error != null) throw response.error!;
  return response.data as Map<String, dynamic>;
}
```

---

# ═══════════════════════════════════════════════
# [C2] نظام إنشاء المشرف من لوحة الإمام
# ═══════════════════════════════════════════════

## المشكلة الحالية
حالياً `mosque_join_requests` تُستخدم للمشرفين (يقدمون طلب).
المطلوب: الإمام ينشئ الحساب مباشرة بدون طلب.

## ما يتغير في Supabase Edge Functions
**إنشاء Edge Function جديدة: `create-supervisor-account`**

```typescript
// supabase/functions/create-supervisor-account/index.ts

Request body:
{
  name: string,
  email: string,
  temp_password: string,
  mosque_id: string
}

الخطوات:
1. تحقق أن المستدعي imam (من JWT)
2. تحقق أن mosque_id ينتمي للإمام المستدعي
3. Rate limit: لا أكثر من 10 حسابات في الساعة للمسجد الواحد
4. استخدم Admin API: createUser({email, password, email_confirm: true})
5. أضف في public.users مع role='supervisor'
6. أضف في mosque_members مع (mosque_id, user_id, role='supervisor')
7. احفظ temp_password مشفراً في supervisor_credentials table (جديدة)

أسباب الفشل:
- الإيميل موجود كـ ولي أمر → "هذا الإيميل مرتبط بحساب ولي أمر. استخدم إيميلاً مختلفاً"
- الإيميل موجود مسبقاً → "حساب بهذا الإيميل موجود بالفعل"
- ليس من صلاحية الإمام → رفض صامت
```

**جدول جديد: `supervisor_credentials`**
```sql
CREATE TABLE supervisor_credentials (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  mosque_id UUID REFERENCES mosques(id),
  encrypted_password TEXT,  -- مشفر ببساطة (base64 أو AES)
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: imam في نفس المسجد يقدر يقرأ
CREATE POLICY "imam_can_read_own_mosque_credentials"
ON supervisor_credentials FOR SELECT
USING (
  mosque_id IN (
    SELECT mosque_id FROM mosque_members
    WHERE user_id = auth.uid() AND role = 'owner'
  )
);
```

## ما يتغير في Flutter

### `lib/app/features/imam/presentation/screens/imam_supervisors_screen.dart`
*(أو الشاشة الحالية التي تعرض المشرفين)*

**الشاشة الحالية** تعرض قائمة المشرفين.
**نضيف:**

1. **زر "إضافة مشرف"** → يفتح BottomSheet:
```dart
// حقول:
// - الاسم (required)
// - الإيميل (required, email validation)
// - كلمة السر (مع زر "توليد تلقائي")

// بعد الإنشاء → Dialog النتيجة:
// ┌────────────────────────────────────────┐
// │ ✓ تم إنشاء حساب المشرف               │
// │ الاسم:     أبو عبدالله               │
// │ الإيميل:   sup@email.com              │
// │ كلمة السر: sup_Kx9mP2                │
// │                                        │
// │ [نسخ] [مشاركة واتساب] [عرض لاحقاً] │
// └────────────────────────────────────────┘
```

2. **في بطاقة كل مشرف** → زر "عرض بيانات الدخول":
```dart
// يستدعي API لجلب بيانات من supervisor_credentials
// يعرض نفس الـ Dialog
```

3. **إزالة آلية "طلبات الانضمام"** للمشرفين (تبقى للأطفال فقط لو كانت)

---

# ═══════════════════════════════════════════════
# [C3] نظام Onboarding — بعد أول تسجيل دخول
# ═══════════════════════════════════════════════

## المشكلة الحالية
`lib/app/features/onboarding/` موجود لكن يظهر قبل تسجيل الدخول.
المطلوب: يظهر بعد أول دخول لكل دور.

## منطق التحقق من "أول دخول"
```dart
// SharedPreferences key: 'onboarding_shown_{user_id}'
// عند كل دخول:
final prefs = await SharedPreferences.getInstance();
final key = 'onboarding_shown_${user.id}';
final shown = prefs.getBool(key) ?? false;
if (!shown) {
  // اعرض onboarding
  await prefs.setBool(key, true);
}
```

## ما يتغير في Flutter

### `lib/app/core/router/app_router.dart`
بعد التحقق من الدور، أضف check لـ onboarding:
```dart
// في redirect logic:
if (isFirstLogin && role == 'imam') return '/imam-onboarding';
if (isFirstLogin && role == 'supervisor') return '/supervisor-onboarding';
if (isFirstLogin && role == 'parent') return '/parent-onboarding';
// superAdmin: بدون onboarding
```

### شاشة جديدة: `imam_onboarding_screen.dart`
```dart
// Setup Checklist — يُحسب ديناميكياً:
// ✓ إنشاء المسجد (دائماً تم — الإمام لا يصل لهنا بدون مسجد)
// ○ إضافة مشرف → supervisors.isEmpty
// ○ إطلاق مسابقة → competitions.isEmpty

// الشاشة تعرض الخطوات + أزرار "افعل الآن" / "لاحقاً"
// "لاحقاً" يذهب للـ dashboard لكن الـ checklist يبقى هناك!

// الـ Checklist تبقى على dashboard الإمام:
// ChecklistCard widget — تختفي فقط لما يكمل الخطوات الثلاث
```

### شاشة جديدة: `supervisor_onboarding_screen.dart`
```dart
// شاشة ثابتة — لا تتغير
// تشرح: مهمتك، 3 طرق التحضير
// زر: "جرّب الآن — ابدأ التحضير" → يذهب لـ scanner
```

### شاشة جديدة: `parent_onboarding_screen.dart`
```dart
// 3 صفحات:
// 1. مرحبا بك + شرح التطبيق
// 2. "أضف طفلك الأول" → TextFormField للاسم والعمر والجنس
// 3. "أدخل كود المسجد" → TextField للكود
//    زر [تخطي — سأضيف لاحقاً]

// إذا أدخل الكود في هذه الخطوة → يربط الطفل فوراً
// لو أخطأ الكود → رسالة خطأ ويبقى في نفس الخطوة
// لو تخطى → ينتقل للـ home مع banner واضح "أضف طفلك لمسجد"
```

### `imam_dashboard_screen.dart`
**إضافة ChecklistCard:**
```dart
// في أعلى الـ dashboard:
// تظهر لو supervisors.isEmpty || competitions.isEmpty
// تختفي تلقائياً لما تكتمل الخطوات

SetupChecklistCard(
  hasAddedSupervisor: supervisors.isNotEmpty,
  hasCreatedCompetition: competitions.isNotEmpty,
  onAddSupervisor: () => navigateToAddSupervisor(),
  onCreateCompetition: () => navigateToCreateCompetition(),
)
```

---

# ═══════════════════════════════════════════════
# [C4] Empty States لكل الشاشات
# ═══════════════════════════════════════════════

## ما يتغير في Flutter

### شاشات تحتاج Empty State محسّن:

**1. `imam_dashboard_screen.dart` — قبل إكمال الـ setup:**
```dart
EmptyStateWidget(
  icon: Icons.mosque_outlined,
  title: 'مرحباً! مسجدك جاهز',
  subtitle: 'ابدأ بإضافة مشرف لمسجدك',
  actionLabel: 'إضافة مشرف',
  onAction: () => navigateToSupervisors(),
)
```

**2. `supervisor_dashboard_screen.dart` — لا طلاب:**
```dart
EmptyStateWidget(
  icon: Icons.people_outline,
  title: 'لا يوجد طلاب بعد',
  subtitle: 'شارك كود المسجد مع أولياء الأمور\nكود مسجدك: ${mosque.code}',
  actionLabel: 'مشاركة الكود',
  onAction: () => shareCode(mosque.code),
)
```

**3. `parent/home_screen.dart` — لم يُربط طفل بمسجد:**
```dart
EmptyStateWidget(
  icon: Icons.link_off,
  title: 'لم يُربط أطفالك بمسجد بعد',
  subtitle: 'اطلب كود المسجد من الإمام واربط أطفالك',
  actionLabel: 'ربط طفل بمسجد',
  onAction: () => navigateToLinkChild(),
)
```

**4. `admin_screen.dart` — لا طلبات:**
```dart
// الحالي: قد يظهر شاشة فارغة
// المطلوب:
EmptyStateWidget(
  icon: Icons.inbox_outlined,
  title: 'لا توجد طلبات مساجد',
  subtitle: 'عند تسجيل أئمة جدد ستظهر طلباتهم هنا',
)
```

**5. `imam_competitions_screen.dart` — لا مسابقات:**
```dart
EmptyStateWidget(
  icon: Icons.emoji_events_outlined,
  title: 'لا توجد مسابقات بعد',
  subtitle: 'أنشئ أول مسابقة لمسجدك',
  actionLabel: 'إنشاء مسابقة',
  onAction: () => navigateToCreateCompetition(),
)
```

---

# ═══════════════════════════════════════════════
# [C5] بانر المسابقة — 4 حالات لولي الأمر
# ═══════════════════════════════════════════════

## ما يتغير في Flutter

### `lib/app/features/parent/presentation/screens/home_screen.dart`
**إضافة CompetitionBannerWidget في أعلى الصفحة:**

```dart
// يحسب الحالة بناءً على:
// 1. هل الطفل مربوط بمسجد؟
// 2. هل للمسجد مسابقة نشطة؟
// 3. هل للمسجد مسابقة قادمة (upcoming)?
// 4. هل آخر مسابقة انتهت؟

// CompetitionState enum:
// - active: competition.is_active == true
// - upcoming: competition.start_date > now()
// - ended: competition.is_active == false && competition.end_date < now()
// - none: لا توجد competitions للمسجد

class CompetitionBannerWidget extends StatelessWidget {
  // الحالة 1 - نشطة:
  // بانر أخضر: اسم المسابقة + "باقي X أيام"

  // الحالة 2 - قادمة:
  // بانر أزرق: "تبدأ في X أيام"

  // الحالة 3 - لا توجد:
  // بطاقة رمادية هادئة: "تابع حضور أطفالك"

  // الحالة 4 - منتهية:
  // بطاقة رمادية + زر "عرض النتائج"
}
```

**حضور اليوم — الصلوات الخمس:**
```dart
// في home_screen، قسم "حضور اليوم":
// يعرض الصلوات الخمس لكل طفل:
// ✓ = حضر | ─ = لم يُسجَّل

DailyAttendanceRow(
  child: child,
  todayAttendance: attendanceList,  // filter للـ today
  prayers: [fajr, dhuhr, asr, maghrib, isha],
)
// كل صلاة: أيقونة ✓ خضراء أو ─ رمادية
```

---

# ═══════════════════════════════════════════════
# [C6+C7] Realtime + إنهاء المسابقة تلقائياً
# ═══════════════════════════════════════════════

## إنهاء المسابقة تلقائياً
**آلية بسيطة — في كل طلب للبيانات:**

```dart
// lib/app/features/competitions/data/repositories/competition_repository.dart
// في getActive() و getAllForMosque():

Future<void> _checkAndEndExpiredCompetitions(String mosqueId) async {
  final now = DateTime.now().toIso8601String().split('T')[0]; // 'YYYY-MM-DD'

  // تحديث المسابقات المنتهية
  await supabase
    .from('competitions')
    .update({'is_active': false})
    .eq('mosque_id', mosqueId)
    .eq('is_active', true)
    .lt('end_date', now);  // end_date قبل اليوم
}

// استدعِها في بداية getActive() و getAllForMosque()
```

**لا نحتاج Cron Job — هذا يكفي ويعمل فوراً.**

## Realtime Events المطلوبة

### `lib/app/core/services/realtime_service.dart`
**إضافة subscriptions جديدة:**

```dart
// 1. تفعيل/إنهاء مسابقة:
supabase
  .from('competitions')
  .stream(primaryKey: ['id'])
  .eq('mosque_id', mosqueId)
  .listen((data) {
    // إشعار الـ BLoC بتغيير حالة المسابقة
    competitionBloc.add(CompetitionStatusChanged(data));
  });

// 2. طلب تصحيح جديد (للمشرف):
supabase
  .from('correction_requests')
  .stream(primaryKey: ['id'])
  .eq('mosque_id', mosqueId)
  .eq('status', 'pending')
  .listen((data) {
    supervisorBloc.add(NewCorrectionRequest(data));
  });

// 3. رد على طلب تصحيح (لولي الأمر):
supabase
  .from('correction_requests')
  .stream(primaryKey: ['id'])
  .eq('parent_id', parentId)
  .neq('status', 'pending')
  .listen((data) {
    parentBloc.add(CorrectionRequestResolved(data));
  });
```

**مهم — dispose صحيح في كل Widget:**
```dart
// في كل StatefulWidget يستخدم Realtime:
@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

---

# ═══════════════════════════════════════════════
# [C8+C9] أمان كود المسجد
# ═══════════════════════════════════════════════

## كود المسجد 6 أحرف

### تغيير في DB:
```sql
-- Migration:
ALTER TABLE mosques
ALTER COLUMN invitation_code TYPE CHAR(6);

-- تحديث الأكواد الموجودة (تمديدها لـ 6 أحرف):
UPDATE mosques
SET invitation_code = invitation_code || substring(gen_random_uuid()::text, 1, 2)
WHERE length(invitation_code) = 4;

-- Function لتوليد كود جديد:
CREATE OR REPLACE FUNCTION generate_mosque_code() RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INT;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;
```

## حماية Brute Force

### جدول جديد: `mosque_code_attempts`
```sql
CREATE TABLE mosque_code_attempts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ip_address TEXT,            -- أو device_id
  parent_id UUID REFERENCES auth.users(id),
  attempted_code TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index للبحث السريع:
CREATE INDEX ON mosque_code_attempts(parent_id, created_at);
```

### في Flutter — قبل كل محاولة ربط:
```dart
// lib/app/features/parent/data/repositories/child_repository.dart
// في linkChildToMosque():

Future<void> checkBruteForce(String parentId) async {
  final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));

  final attempts = await supabase
    .from('mosque_code_attempts')
    .select('id')
    .eq('parent_id', parentId)
    .gte('created_at', fiveMinutesAgo.toIso8601String());

  if (attempts.length >= 5) {
    throw Exception('انتظر 10 دقائق قبل المحاولة مجدداً');
  }

  // سجّل المحاولة
  await supabase.from('mosque_code_attempts').insert({
    'parent_id': parentId,
    'created_at': DateTime.now().toIso8601String(),
  });
}
```

---

# ═══════════════════════════════════════════════
# [C10] RLS تدقيق شامل
# ═══════════════════════════════════════════════

## Supabase RLS Policies يجب التحقق منها:

```sql
-- 1. ولي الأمر يرى أطفاله فقط:
CREATE POLICY "parent_sees_own_children_only" ON children
FOR SELECT USING (parent_id = auth.uid());

-- 2. ولي الأمر يرى حضور أطفاله فقط:
CREATE POLICY "parent_sees_own_children_attendance" ON attendance
FOR SELECT USING (
  child_id IN (SELECT id FROM children WHERE parent_id = auth.uid())
);

-- 3. المشرف يُسجِّل حضور مسجده فقط:
CREATE POLICY "supervisor_inserts_own_mosque_attendance" ON attendance
FOR INSERT WITH CHECK (
  mosque_id IN (
    SELECT mosque_id FROM mosque_members WHERE user_id = auth.uid()
  )
);

-- 4. ولي الأمر لا يقدر يستدعي activate_competition:
-- (الـ RPC نفسها تتحقق من role='imam' في بدايتها)
-- تأكد من وجود هذا الـ check في activate_competition function
```

---

# ═══════════════════════════════════════════════
# [I1+I2] طلبات التصحيح — تذهب للمشرف
# ═══════════════════════════════════════════════

## المشكلة الحالية
`corrections_list_screen.dart` في لوحة الإمام فقط.
المطلوب: المشرف يستقبلها أيضاً.

## ما يتغير في DB
لا تغيير في الـ schema. `correction_requests` موجود مع:
```
child_id, parent_id, mosque_id, prayer, prayer_date, status, note, reviewed_by, reviewed_at
```

`reviewed_by` يمكن أن يكون mosque_id لأي supervisor.

## ما يتغير في Flutter

### `lib/app/features/supervisor/presentation/screens/supervisor_dashboard_screen.dart`
**إضافة قسم "طلبات التصحيح":**
```dart
// في الـ dashboard:
CorrectionRequestsSection(
  mosqueId: mosqueId,
  // يعرض عدد الطلبات المعلقة
  // عند الضغط → CorrectionListScreen (نفس شاشة الإمام لكن بـ reviewer_role='supervisor')
)
```

### `lib/app/features/corrections/data/repositories/correction_repository.dart`
**تعديل `getPendingForMosque()`:**
```dart
// الحالي: يُستدعى من الإمام
// الجديد: يُستدعى من الإمام والمشرف بنفس الـ query

Future<List<CorrectionRequest>> getPendingForMosque(String mosqueId) async {
  return await supabase
    .from('correction_requests')
    .select('*, children(name)')
    .eq('mosque_id', mosqueId)
    .eq('status', 'pending')
    .order('created_at');
}

// approve/reject: يُحدِّث reviewed_by = current user (imam أو supervisor)
```

### **Realtime للمشرف:**
```dart
// عند وصول طلب تصحيح جديد → badge/counter على dashboard المشرف
// يتحدث Realtime من subscription في supervisor_dashboard
```

### `lib/app/features/corrections/presentation/screens/request_correction_screen.dart`
**تحقق من وجود هذه الشاشة وإضافتها لولي الأمر:**
```dart
// ولي الأمر يفتح سجل حضور ابنه → يضغط على سجل
// شاشة طلب التصحيح:
// - الطفل (معبأ)
// - الصلاة والتاريخ (معبأة)
// - حقل ملاحظة ← اكتب سببك هنا
// - [إرسال الطلب]
```

---

# ═══════════════════════════════════════════════
# [I3] نافذة الحضور المرنة — تحكم السوبر أدمن
# ═══════════════════════════════════════════════

## المشكلة الحالية
`attendance_validation_service.dart`:
- Supervisors: 60-minute window بعد الأذان
- Imams: بلا حد

المطلوب: يوم كامل للسوبر أدمن.

## ما يتغير في DB
حقل `attendance_window_minutes` موجود في `mosques` table.
**نضيف جدول إعدادات النظام:**
```sql
CREATE TABLE system_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID REFERENCES auth.users(id)
);

INSERT INTO system_settings (key, value) VALUES
  ('default_attendance_window_hours', '24'),
  ('max_attendance_window_hours', '24');

-- RLS: السوبر أدمن يكتب، الجميع يقرأ
CREATE POLICY "superadmin_write_settings" ON system_settings
FOR ALL USING (
  auth.uid() IN (SELECT id FROM auth.users
    WHERE id IN (SELECT id FROM users WHERE role = 'superAdmin'))
);
CREATE POLICY "all_read_settings" ON system_settings
FOR SELECT USING (true);
```

## ما يتغير في Flutter

### `lib/app/core/services/attendance_validation_service.dart`
```dart
// تعديل canRecordNow():
// بدل windowMinutes ثابت = 60:

Future<int> getWindowMinutes(String? mosqueId) async {
  // 1. جلب إعداد النظام الافتراضي
  final settings = await supabase
    .from('system_settings')
    .select('value')
    .eq('key', 'default_attendance_window_hours')
    .single();
  final hours = int.parse(settings['value']);
  return hours * 60;  // تحويل لدقائق
}

// المنطق الجديد:
// - لو windowMinutes >= 1440 (24 ساعة) → اسمح بأي وقت في اليوم
// - لو أقل → تحقق من النافذة كما كان
```

### `lib/app/features/super_admin/presentation/screens/admin_screen.dart`
**إضافة قسم الإعدادات:**
```dart
// في لوحة السوبر أدمن: tab أو section "الإعدادات"
// Slider أو TextField: "نافذة تسجيل الحضور (بالساعات)"
// default: 24 ساعة
// يحفظ في system_settings
```

---

# ═══════════════════════════════════════════════
# [I4] نقاط الصلوات — تحكم الإمام
# ═══════════════════════════════════════════════

## الموجود
`prayer_points_settings_screen.dart` موجود بالفعل!
**يجب التحقق أنه:**
1. يحفظ النقاط في `competitions` table (حقل `prayer_points` JSONB)
2. يُستخدم عند حساب النقاط في `points_service.dart`

## ما قد يحتاج تعديل في DB:
```sql
-- إضافة حقل لو مش موجود:
ALTER TABLE competitions
ADD COLUMN IF NOT EXISTS prayer_points JSONB DEFAULT '{
  "fajr": 10,
  "dhuhr": 10,
  "asr": 10,
  "maghrib": 10,
  "isha": 10
}'::jsonb;
```

## تغيير نقاط أثناء المسابقة النشطة:
```dart
// في prayer_points_settings_screen.dart:
// لو المسابقة نشطة + غيّر الإمام النقاط:
// → Dialog تأكيد: "سيتغير احتساب النقاط للصلوات القادمة فقط. هل تريد المتابعة؟"
// → لو وافق: تحديث + إنشاء إعلان تلقائي في mosque announcements:
//   "تنبيه: تغيّرت نقاط صلاة [الظهر] إلى 0 نقطة بسبب [سبب اختياري]"

Future<void> updatePrayerPoints({
  required String competitionId,
  required Map<String, int> newPoints,
  String? reason,
}) async {
  // 1. حدّث نقاط المسابقة
  await supabase.from('competitions')
    .update({'prayer_points': newPoints})
    .eq('id', competitionId);

  // 2. أنشئ إعلان تلقائي لو المسابقة نشطة
  if (competition.isActive) {
    await supabase.from('announcements').insert({
      'mosque_id': mosqueId,
      'created_by': userId,
      'title_ar': 'تحديث نقاط المسابقة',
      'content_ar': _buildPointsChangedMessage(newPoints, reason),
    });
  }
}
```

---

# ═══════════════════════════════════════════════
# [I5] QR Code — يعمل بدون إنترنت
# ═══════════════════════════════════════════════

## المشكلة
QR code يحتاج بيانات الطفل من الـ DB في كل مرة.

## الحل — Cache محلي

### `lib/app/features/parent/data/repositories/child_repository.dart`
```dart
// عند تحميل بيانات الطفل:
Future<void> cacheChildQrData(Child child) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'child_qr_${child.id}',
    jsonEncode({
      'id': child.id,
      'name': child.name,
      'qr_code': child.qrCode,
      'local_numbers': child.localNumbers,  // {mosque_id: local_number}
    }),
  );
}

// عند فتح بطاقة الطفل:
Future<Map<String, dynamic>?> getCachedChildData(String childId) async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString('child_qr_$childId');
  if (cached != null) return jsonDecode(cached);
  return null;
}
```

### `lib/app/features/parent/presentation/screens/child_view_screen.dart`
```dart
// عند بناء الشاشة:
// 1. جرّب جلب البيانات من الـ network
// 2. لو نجح → حدّث الـ cache
// 3. لو فشل (لا نت) → استخدم الـ cache
// 4. لو لا cache → أظهر رسالة "افتح التطبيق مرة بنت لتفعيل العرض بدون إنترنت"

// QR يُعرض بـ qr_flutter حتى offline (البيانات محفوظة)
```

---

# ═══════════════════════════════════════════════
# [I6] Arabic Text Normalization في البحث
# ═══════════════════════════════════════════════

### أضف helper function:
```dart
// lib/app/core/utils/arabic_utils.dart
class ArabicUtils {
  static String normalize(String text) {
    return text
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .trim();
  }
}
```

### في `scanner_screen.dart` — البحث بالاسم:
```dart
// بدل:
students.where((s) => s.name.contains(query))

// استخدم:
students.where((s) =>
  ArabicUtils.normalize(s.name).contains(ArabicUtils.normalize(query))
)
```

---

# ═══════════════════════════════════════════════
# [I7] نسخ نتائج المسابقة
# ═══════════════════════════════════════════════

### في شاشة الترتيب (Leaderboard):
```dart
// زر "نسخ النتائج" أو "مشاركة":
Future<void> shareResults(List<LeaderboardEntry> entries, Competition comp) async {
  final buffer = StringBuffer();
  buffer.writeln('نتائج ${comp.nameAr}');
  buffer.writeln('مسجد ${mosque.name}');
  buffer.writeln('من ${_formatDate(comp.startDate)} حتى ${_formatDate(comp.endDate)}');
  buffer.writeln('─────────────────────────');

  for (int i = 0; i < min(entries.length, 10); i++) {
    final entry = entries[i];
    final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i+1}.';
    buffer.writeln('$medal ${entry.childName} — ${entry.totalPoints} نقطة');
  }

  buffer.writeln('─────────────────────────');
  buffer.writeln('عدد المشاركين: ${entries.length}');

  await Clipboard.setData(ClipboardData(text: buffer.toString()));
  // أو Share.share(buffer.toString()) باستخدام share_plus package
}
```

---

# ═══════════════════════════════════════════════
# [I8] رسائل خطأ واضحة بالعربية
# ═══════════════════════════════════════════════

### أنشئ ملف مركزي للرسائل:
```dart
// lib/app/core/constants/error_messages.dart
class AppErrorMessages {
  // Auth
  static const invalidCredentials = 'البريد الإلكتروني أو كلمة السر غير صحيحة';
  static const emailAlreadyExists = 'هذا البريد الإلكتروني مسجّل بالفعل';
  static const networkError = 'تحقق من اتصالك بالإنترنت وحاول مجدداً';

  // Mosque Code
  static const wrongMosqueCode = 'كود المسجد غير صحيح. تأكد من الكود وحاول مجدداً';
  static const tooManyAttempts = 'محاولات كثيرة. انتظر 10 دقائق ثم حاول مجدداً';
  static const childAlreadyLinked = 'هذا الطفل مرتبط بالمسجد بالفعل';

  // Attendance
  static const competitionEnded = 'انتهت المسابقة. لا يمكن تسجيل حضور جديد';
  static const attendanceAlreadyRecorded = 'تم تسجيل حضور هذا الطفل بالفعل لهذه الصلاة';
  static const outsideAttendanceWindow = 'وقت تسجيل الحضور لهذه الصلاة انتهى';

  // Supervisor
  static const emailBelongsToParent = 'هذا الإيميل مرتبط بحساب ولي أمر. استخدم إيميلاً مختلفاً';
  static const emailAlreadyInUse = 'هذا الإيميل مستخدم بالفعل';

  // Corrections
  static const correctionAlreadyPending = 'يوجد طلب تصحيح معلق لهذه الصلاة';
}
```

---

# ═══════════════════════════════════════════════
# [E1] Imam Checklist — تبقى على الـ Dashboard
# ═══════════════════════════════════════════════

```dart
// lib/app/features/imam/presentation/widgets/setup_checklist_card.dart
class SetupChecklistCard extends StatelessWidget {
  final bool hasAddedSupervisor;
  final bool hasCreatedCompetition;
  final bool hasMosqueCode;
  final VoidCallback onAddSupervisor;
  final VoidCallback onCreateCompetition;
  final VoidCallback onShareCode;

  // تختفي لما تكتمل الخطوات الثلاث:
  // if (hasAddedSupervisor && hasCreatedCompetition) return SizedBox.shrink();

  // Widget:
  // بطاقة مع عنوان "إعداد مسجدك"
  // CheckTile: "إنشاء المسجد ✓" (دائماً)
  // CheckTile: "إضافة مشرف" (○ أو ✓ مع زر "إضافة الآن")
  // CheckTile: "إطلاق مسابقة" (○ أو ✓ مع زر "إطلاق الآن")
}
```

---

# ═══════════════════════════════════════════════
# ملخص: ترتيب التنفيذ بالأسابيع
# ═══════════════════════════════════════════════

## الأسبوع الأول — الأساسيات (C1 + C2 + C3)
| اليوم | المهمة |
|-------|--------|
| 1-2 | Edge Function: create-imam-account + واجهة السوبر أدمن |
| 2-3 | Edge Function: create-supervisor-account + واجهة الإمام |
| 4-5 | Onboarding: imam + supervisor + parent (مع خطوة الكود) |

## الأسبوع الثاني — UX (C4 + C5 + C6 + C7)
| اليوم | المهمة |
|-------|--------|
| 1-2 | Empty States لكل الشاشات + Setup Checklist للإمام |
| 3-4 | بانر المسابقة بالحالات الأربع + حضور اليوم (5 صلوات) |
| 5 | إنهاء المسابقة تلقائياً + Realtime للتفعيل/الإنهاء |

## الأسبوع الثالث — أمان + تصحيحات (C8 + C9 + C10 + I1 + I2)
| اليوم | المهمة |
|-------|--------|
| 1 | كود المسجد 6 أحرف (migration) + brute force protection |
| 2 | RLS audit شامل |
| 3-4 | طلبات التصحيح للمشرف + Realtime |
| 5 | نافذة الحضور المرنة + system_settings |

## الأسبوع الرابع — تحسينات (I3 → I8)
| اليوم | المهمة |
|-------|--------|
| 1 | QR offline cache |
| 2 | Arabic normalization في البحث |
| 3 | نسخ نتائج المسابقة |
| 4 | رسائل الخطأ موحدة بالعربية |
| 5 | Dispose صحيح لـ Realtime subscriptions |

---

## ملفات Flutter التي ستتغير — ملخص

| الملف | نوع التغيير |
|-------|-------------|
| `app_router.dart` | إضافة routes للـ onboarding |
| `admin_screen.dart` | إضافة "إنشاء إمام" + إعدادات |
| `admin_repository.dart` | createImamAccount() |
| `imam_dashboard_screen.dart` | SetupChecklistCard |
| `imam_supervisors_screen.dart` | createSupervisorAccount() + عرض بيانات |
| `parent/home_screen.dart` | CompetitionBannerWidget + حضور 5 صلوات |
| `supervisor_dashboard_screen.dart` | طلبات التصحيح |
| `corrections/corrections_list_screen.dart` | دعم supervisor |
| `correction_repository.dart` | لا تغيير في الـ query |
| `competition_repository.dart` | _checkAndEndExpiredCompetitions() |
| `attendance_validation_service.dart` | قراءة window من system_settings |
| `realtime_service.dart` | subscriptions جديدة |
| `scanner_screen.dart` | Arabic normalization في البحث |
| `child_view_screen.dart` | QR offline cache |
| **جديد** `imam_onboarding_screen.dart` | |
| **جديد** `supervisor_onboarding_screen.dart` | |
| **جديد** `parent_onboarding_screen.dart` | |
| **جديد** `setup_checklist_card.dart` | |
| **جديد** `competition_banner_widget.dart` | |
| **جديد** `arabic_utils.dart` | |
| **جديد** `error_messages.dart` | |
| **جديد** `supervisor_credentials` table | |
| **جديد** `system_settings` table | |
| **جديد** `mosque_code_attempts` table | |

---

*آخر تحديث: 2026-03-03*
