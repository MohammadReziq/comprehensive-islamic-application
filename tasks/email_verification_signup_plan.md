# خطة تفعيل الحساب برمز البريد الإلكتروني (بعد التسجيل)

> **الهدف:** لما المستخدم ينشئ حساب جديد، يوصل له إيميل فيه **رمز (OTP)**، يدخل الرمز في التطبيق، وبعدها يقدر يكمل ويفعّل حسابه.

---

## 1. تدفق المستخدم (User Flow)

```
[شاشة التسجيل] → يدخل الاسم، الإيميل، كلمة المرور، الدور
       ↓
   ضغط "إنشاء حساب"
       ↓
   إنشاء الحساب في Supabase Auth (بدون تفعيل كامل إن لزم)
       ↓
   إرسال إيميل يحتوي على رمز (6 خانات)
       ↓
   [شاشة "أدخل الرمز المرسل إلى بريدك"]
       ↓
   المستخدم يدخل الرمز
       ↓
   التحقق من الرمز → تفعيل الحساب
       ↓
   إنشاء/ربط السجل في جدول users + الانتقال للوحة الرئيسية
```

---

## 2. خياران للتنفيذ

### الخيار أ: استخدام Supabase Auth جاهز (مُفضّل إن كان يكفي)

Supabase يدعم إرسال إيميل تأكيد عند التسجيل، والقالب يدعم متغير **`{{ .Token }}`** (رمز رقمي). بعد التأكيد يمكن التحقق من الرمز عبر **verifyOTP**.

| الخطوة | ماذا تفعل |
|--------|-----------|
| 1 | في **Supabase Dashboard** → Authentication → Email Templates → **Confirm signup**: تفعيل "Confirm email" وتعديل قالب الإيميل ليعرض الرمز: مثلاً `رمز التفعيل: {{ .Token }}` |
| 2 | التأكد من إعدادات **Auth** → "Enable email confirmations" = مفعّل |
| 3 | في التطبيق: بعد استدعاء `signUp()` إذا كان الحساب يحتاج تأكيد (لا توجد جلسة أو المستخدم غير مؤكد)، لا نعتبر المستخدم مفعّلًا — ننتقل لحالة "بانتظار إدخال الرمز" مع حفظ الإيميل (والاسم والدور إن لزم) |
| 4 | شاشة جديدة (أو نفس شاشة التسجيل بخطوة ثانية): حقل لإدخال الرمز المرسل للإيميل |
| 5 | عند إدخال الرمز: استدعاء `verifyOTP(type: OtpType.email, token: الرمز, email: الإيميل)` من Flutter |
| 6 | بعد نجاح التحقق: Supabase يفعّل الحساب ويعيد جلسة. نستدعي `ensureProfileAfterSignUp` ثم نُصدِر `AuthAuthenticated` وننتقل للوحة الرئيسية |

**ملاحظة:** في Dart/Flutter تأكد أن `OtpType.email` (أو ما يعادله في حزمة supabase_flutter) مستخدم لتأكيد التسجيل وليس recovery.

---

### الخيار ب: استخدام Edge Function + إيميل مخصص (Resend)

إذا أردت **تصميم الإيميل بالكامل** عبر خدمة Resend (مثل دالة `send-emails` الموجودة عندك)، التدفق يصبح كالتالي:

| المكوّن | الوظيفة |
|---------|---------|
| **جدول في Supabase** | تخزين الرموز المؤقتة: مثلاً `email_verification_codes` (email, code, expires_at, created_at). الرمز يُنشأ عند طلب "إرسال الرمز" ويُحذف أو يُهمَل بعد الاستخدام أو انتهاء المدة. |
| **Edge Function: إرسال الرمز** | تُستدعى بعد نجاح `signUp()` من التطبيق (أو عبر Auth Hook بعد إنشاء المستخدم). تُنشئ رمزًا عشوائيًا (6 خانات)، تحفظه في الجدول مع انتهاء صلاحية (مثلاً 10–15 دقيقة)، وترسل إيميلًا عبر Resend (استدعاء دالة `send-emails` أو دالة جديدة مثل `send-verification-code`) تحتوي على الرمز. |
| **Edge Function: التحقق من الرمز** | تُستدعى من التطبيق عند إدخال المستخدم للرمز. تتحقق من الجدول (email + code + عدم انتهاء الصلاحية). إذا الرمز صحيح: تستخدم **Service Role Key** وواجهة Supabase Admin (مثلاً `auth.admin.updateUserById`) لتعليم المستخدم كمؤكد (email_confirmed_at أو ما يعادله). ثم تُرجع نجاحًا للتطبيق. التطبيق بعدها إما يعيد تسجيل الدخول (email + password) أو يحدّث الجلسة إن أمكن. |

**تفاصيل تقنية (خيار ب):**

1. **Migration لجدول الرموز:**
   - `email_verification_codes`: `id` (uuid), `email` (text), `code` (text, 6 أحرف), `expires_at` (timestamptz), `created_at` (timestamptz). فهرس على `(email, code)` أو البحث بـ email وترتيب حسب `created_at` لأخذ الأحدث.

2. **دالة إرسال الرمز (مثلاً `send-signup-verification-code`):**
   - المدخلات: `email`, واختياريًا `userName` للترحيب في الإيميل.
   - المنطق: إنشاء رمز 6 خانات، حفظه في `email_verification_codes` مع `expires_at = now() + 15 min`، استدعاء Resend (أو دالة `send-emails`) لإرسال إيميل: "رمز تفعيل حسابك: XXXXXX".

3. **دالة التحقق (مثلاً `verify-signup-code`):**
   - المدخلات: `email`, `code`.
   - المنطق: البحث في الجدول عن سجل مطابق لـ email و code ولم ينتهِ `expires_at`. إذا وُجد: استدعاء Supabase Admin API لتعليم المستخدم مؤكدًا، ثم حذف أو تعطيل الرمز. الإرجاع: نجاح أو خطأ.

4. **التطبيق (Flutter):**
   - بعد `signUp()` نعرض شاشة "أدخل الرمز" ونستدعي Edge Function إرسال الرمز (إن لم يُرسل تلقائيًا عبر Hook).
   - عند إدخال الرمز نستدعي Edge Function التحقق. عند النجاح: إما نطلب من المستخدم تسجيل الدخول (email + password) أو نتحقق إن كان هناك جلسة محدّثة ثم نستدعي `ensureProfileAfterSignUp` وننتقل للوحة الرئيسية.

---

## 3. مقارنة سريعة

| | الخيار أ (Supabase فقط) | الخيار ب (Edge + Resend) |
|---|-------------------------|---------------------------|
| تعقيد البنية | أقل | أعلى (جدول + دالتان + Admin API) |
| تصميم الإيميل | قالب Supabase فقط | كامل التحكم (Resend) |
| أمان الرمز | يديره Supabase | نتحكم نحن (انتهاء صلاحية، حذف بعد الاستخدام) |
| الصيانة | أقل | أكثر (جدول، دوال، إعدادات) |

**التوصية:** البدء بالخيار أ إن كان قالب Supabase كافٍ. إذا احتجت إيميلًا مخصصًا أو منطقًا إضافيًا (مثل إعادة إرسال الرمز، حدّ أدنى بين الطلبات)، استخدم الخيار ب.

---

## 4. تغييرات التطبيق (Flutter) — مشتركة تقريبًا

بغض النظر عن الخيار، تحتاج:

### 4.1 حالات وأحداث جديدة (Auth Bloc)

- **حالة جديدة:** مثلاً `AuthAwaitingEmailVerification` تحتوي على: `email` (إلزامي)، واختياريًا `name`, `role` لاستخدامها بعد التفعيل عند إنشاء الملف في `users`.
- **حدث جديد:** مثلاً `AuthVerifySignupCodeRequested(email, code)` يستدعي إما `verifyOTP` (خيار أ) أو Edge Function التحقق (خيار ب).
- **حدث اختياري:** `AuthResendSignupCodeRequested(email)` — إعادة إرسال الرمز (خيار ب: استدعاء Edge Function الإرسال مرة أخرى).

### 4.2 مستودع المصادقة (AuthRepository)

- **خيار أ:** إضافة دالة مثل `verifySignupOtp({ required String email, required String token })` تستدعي `supabase.auth.verifyOTP(type: OtpType.email, token: token, email: email)`. بعد النجاح الجلسة تكون جاهزة.
- **خيار ب:** دالة `verifySignupCodeViaEdgeFunction(email, code)` تستدعي Edge Function التحقق. ودالة `requestSignupVerificationCode(email, { String? userName })` تستدعي Edge Function الإرسال.

### 4.3 شاشة إدخال الرمز

- مسار جديد مثل `/verify-email` أو خطوة ثانية في شاشة التسجيل.
- حقل لإدخال الرمز (6 خانات)، زر "تحقق" يستدعي الحدث `AuthVerifySignupCodeRequested`.
- إن استخدمت الخيار ب: زر "إعادة إرسال الرمز" يستدعي `AuthResendSignupCodeRequested` مع تعطيل الزر لثوانٍ لتجنب الإزعاج.
- عند النجاح: استدعاء `ensureProfileAfterSignUp` (بعد الحصول على المستخدم الحالي من الجلسة) ثم الانتقال للوحة الرئيسية.

### 4.4 تعديل تدفق التسجيل الحالي

- بعد `signUpWithEmail()`:
  - **خيار أ:** إذا كانت الإعدادات تمنع الجلسة حتى التأكيد، أو إذا كان `currentUser` null أو غير مؤكد، نُصدِر `AuthAwaitingEmailVerification` وننتقل لشاشة إدخال الرمز بدل اعتبار المستخدم مسجّل دخول فورًا.
  - **خيار ب:** نفس الفكرة: بعد `signUp()` نستدعي Edge Function إرسال الرمز ثم نُصدِر `AuthAwaitingEmailVerification` وننتقل لشاشة الرمز.
- بعد التحقق الناجح (خيار أ أو ب): نستدعي `ensureProfileAfterSignUp` ثم نُصدِر `AuthAuthenticated` ونحدّث المسار.

### 4.5 التوجيه (GoRouter)

- إضافة مسار لشاشة التحقق (مثلاً `/verify-email`) وربطها بحالة `AuthAwaitingEmailVerification` في الـ redirect logic إن لزم (مثلاً: إذا الحالة awaiting verification فالإعادة التوجيه لـ `/verify-email`).

---

## 5. ملخص الملفات المتأثرة

| الملف / المكوّن | التعديل |
|------------------|---------|
| `lib/app/features/auth/presentation/bloc/auth_state.dart` | إضافة `AuthAwaitingEmailVerification` |
| `lib/app/features/auth/presentation/bloc/auth_event.dart` | إضافة `AuthVerifySignupCodeRequested` واختياريًا `AuthResendSignupCodeRequested` |
| `lib/app/features/auth/presentation/bloc/auth_bloc.dart` | معالجة التسجيل مع الانتقال لـ awaiting verification؛ معالجة التحقق وإكمال التفعيل |
| `lib/app/features/auth/data/repositories/auth_repository.dart` | دوال التحقق (وإرسال الرمز إن خيار ب) |
| شاشة جديدة أو توسيع `register_screen.dart` | واجهة إدخال الرمز (وربما خطوة ثانية في نفس الشاشة) |
| التوجيه (مثلاً `app_router.dart` أو ما يعادله) | مسار `/verify-email` وشرط إعادة التوجيه حسب حالة التحقق |
| Supabase Dashboard (خيار أ) | قالب "Confirm signup" + تفعيل تأكيد الإيميل |
| Supabase: migrations + functions (خيار ب) | جدول `email_verification_codes`، دالة إرسال الرمز، دالة التحقق |

---

## 6. ترتيب تنفيذ مقترح

1. **تحديد الخيار** (أ أو ب) حسب رغبتك في قالب Supabase vs إيميل مخصص.
2. **إعداد الخلفية:** إن خيار أ: تعديل القالب والإعدادات في Supabase. إن خيار ب: migration الجدول + Edge Functions (إرسال + تحقق).
3. **تعديل Auth state/event/bloc/repository** في Flutter كما أعلاه.
4. **شاشة إدخال الرمز** وربطها بالـ Bloc والمسار.
5. **تعديل تدفق التسجيل** بحيث بعد `signUp` ننتقل لشاشة الرمز ولا نعتبر المستخدم مفعّلًا حتى ينجح التحقق.
6. **اختبار:** إنشاء حساب جديد → استلام الإيميل → إدخال الرمز → التحقق من إنشاء السجل في `users` والانتقال للوحة الرئيسية.

بعد هذا يكون "لما حدا ينشئ حساب لازم تييج رسالة فيها رمز، بعدين يدخله حتى يقدر يكمل ويفعّل حسابه" منفّذًا حسب الخيار الذي تختاره.
