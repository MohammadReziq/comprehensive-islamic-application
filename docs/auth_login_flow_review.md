يي# مراجعة تدفق تسجيل الدخول — كود، فكرة، وتجربة مستخدم

## 1. الفكرة والتدفق (Concept & Flow)

### الخيار الحالي
- **تسجيل الدخول فقط عبر Google** (لا بريد/كلمة مرور في الواجهة).
- شاشة واحدة: **تسجيل الدخول** تحتوي على:
  - اختيار الدور (ولي أمر، إمام، مشرف) مع توضيح كل دور.
  - زر واحد: **تسجيل بحساب Google**.

### السلوك
| الحالة | ماذا يحدث |
|--------|-----------|
| **أول مرة (مستخدم جديد)** | يختار الدور → يضغط Google → يُنشأ سجل في `users` بالدور المختار → يُوجّه حسب الدور (منزل / مسجد / إدارة). |
| **لديه حساب (مستخدم قديم)** | يضغط Google (الدور المعروض لا يغيّر حسابه) → يُربط بالحساب الموجود أو يُجلب السجل → يُوجّه حسب دوره المحفوظ. |

### إصلاح تم تطبيقه
- **قبل:** كان يتم استدعاء `updateUserRole` بعد كل دخول بـ Google، فالمستخدم القديم كان يمكن أن يتغيّر دوره إذا كان دور افتراضي مختلف مُختاراً.
- **بعد:** الدور المختار يُمرَّر فقط عند **إنشاء سجل جديد** عبر `getCurrentUserProfile(roleForNewUser: ...)`. المستخدمون القدامى يحتفظون بدورهم من قاعدة البيانات.

---

## 2. الكود (Code)

### الملفات الأساسية
| الملف | الدور |
|-------|--------|
| `login_screen.dart` | واجهة تسجيل الدخول: اختيار الدور + زر Google. |
| `auth_bloc.dart` | معالجة `AuthLoginWithGoogleRequested`، `AuthCheckRequested`، وتوجيه النتيجة. |
| `auth_repository.dart` | `signInWithGoogle()`، `getCurrentUserProfile(roleForNewUser: ...)`، `ensureProfileFromAuthSession(role: ...)`. |
| `splash_screen.dart` | فحص الجلسة عند البدء والتوجيه حسب الدور (admin / mosque / child-view / home). |
| `app_router.dart` | إعادة التوجيه حسب حالة المصادقة والدور؛ `/register` → `/login`. |

### تدفق الكود عند الضغط على Google
1. **LoginScreen** يُصدِر `AuthLoginWithGoogleRequested(roleForNewUser: _selectedRole)`.
2. **AuthBloc** يستدعي `signInWithGoogle()` ثم يضع `_skipNextCheck = true` حتى لا يُعاد فحص الجلسة فوراً ويمسح الحالة.
3. **AuthBloc** يستدعي `getCurrentUserProfile(roleForNewUser: event.roleForNewUser)`:
   - إن وُجد سجل بـ `auth_id`: يُعاد كما هو (لا تغيير دور).
   - إن وُجد ربط بـ `link_user_profile_to_auth`: يُعاد السجل المرتبط.
   - إن لم يُوجد: يُستدعى `ensureProfileFromAuthSession(role: roleForNewUser ?? 'parent')` فالمستخدم **الجديد** يُنشأ بالدور المختار.
4. **AuthBloc** يصدِر `AuthAuthenticated(userProfile: profile)`.
5. **LoginScreen** (BlocListener) يوجّه إلى `/admin` أو `/mosque` أو `/home` حسب `userProfile.role`.

### أحداث وحالات غير مستخدمة في الواجهة الحالية
- **أحداث:** `AuthRegisterRequested`, `AuthVerifySignupCodeRequested`, `AuthResendSignupCodeRequested`, `AuthLoginRequested`, `AuthResetPasswordRequested`, ... (لا تُستدعى من شاشة الدخول الحالية؛ يمكن الاحتفاظ بها لاستخدام مستقبلي أو إزالتها لتبسيط الكود).
- **حالات:** `AuthAwaitingEmailVerification`, `AuthResetPasswordSent`, … (نفس الشيء).

---

## 3. تجربة المستخدم (UX)

### ما يعمل جيداً
- رسالة واحدة واضحة: "أول مرة؟ اختر دورك ثم اضغط Google. لديك حساب؟ اضغط Google مباشرة." (في `AppStrings.loginHint`).
- أدوار ثلاثة مع أوصاف: ولي أمر، إمام، مشرف — يقلل اللبس.
- زر واحد فقط — لا تعدد خيارات دخول.
- حالة تحميل على الزر أثناء انتظار Google أو جلب البروفايل.
- أخطاء المصادقة تظهر في SnackBar.

### تحسينات مقترحة (اختيارية)
- **زر الرجوع (Android):** عند الضغط على Back في شاشة الدخول يمكن الخروج من التطبيق؛ يمكن استخدام `PopScope` مع سؤال "هل تريد الخروج؟".
- **فشل تحميل الفيديو:** لا توجد رسالة للمستخدم؛ الخلفية تبقى التدرج فقط (مقبول).
- **إلغاء اختيار حساب Google:** يتم إرجاع المستخدم لحالة غير مصادق بدون رسالة؛ يمكن إضافة جملة مثل "تم إلغاء تسجيل الدخول" إذا رغبت.

---

## 4. البنية والاعتماديات

### Supabase
- **Auth:** تسجيل الدخول بـ Google (OAuth أو ID Token حسب الإعداد).
- **جدول `users`:** ربط بـ `auth_id`؛ إنشاء سجل جديد عند الحاجة مع `role`.
- **RPC (إن وُجدت):** `link_user_profile_to_auth` لربط سجل موجود بنفس البريد.

### Google
- **Web Client ID** في `SupabaseConfig.googleWebClientId` لاختيار الحساب داخل التطبيق (بدون متصفح إن رُكّب بشكل صحيح).
- **Deep link:** `salatihayati://login-callback` لعودة OAuth إلى التطبيق.

### التوجيه
- **Splash:** يوجّه غير المصادق إلى `/onboarding` أو `/login` حسب `onboardingSeen`.
- **Splash:** يوجّه المصادق حسب الدور إلى `/admin` أو `/mosque` أو `/child-view` أو `/home`.
- **Router:** يمنع غير المصادق من الوصول لمسارات التطبيق الداخلية ويوجّههم إلى `/login`.

---

## 5. ملخص التغييرات التي تمت في هذه المراجعة

1. **الدور للمستخدم الجديد فقط:** تمرير `roleForNewUser` إلى `getCurrentUserProfile` واستخدامه فقط داخل `ensureProfileFromAuthSession` عند إنشاء سجل جديد؛ عدم استدعاء `updateUserRole` بعد Google حتى لا يتغيّر دور المستخدمين القدامى.
2. **منع وميض التحميل:** استخدام `_skipNextCheck` في الـ Bloc حتى لا يُعاد إصدار `AuthLoading` من `AuthCheckRequested` بعد نجاح الدخول بـ Google.
3. **نقل النص إلى AppStrings:** جملة التوجيه في شاشة الدخول في `AppStrings.loginHint`.
4. **توجيه Splash حسب الدور:** التوجيه من شاشة البداية إلى `/admin` أو `/mosque` أو `/child-view` أو `/home` حسب `userProfile.role` بدل توجيه كل المصادقين إلى `/home` ثم الاعتماد على redirect الراوتر فقط.

---

## 6. خريطة تدفق مختصرة

```
[فتح التطبيق] → Splash
  ├─ مصادق + profile → توجيه حسب الدور (admin / mosque / child-view / home)
  └─ غير مصادق → onboarding (أول مرة) أو login

[شاشة تسجيل الدخول]
  ├─ اختيار الدور (للمرة الأولى أو للتذكير)
  └─ ضغط "تسجيل بحساب Google"
       ├─ إلغاء → يبقى على الشاشة (Unauthenticated)
       ├─ خطأ → SnackBar
       └─ نجاح → getCurrentUserProfile(roleForNewUser) → AuthAuthenticated → توجيه حسب الدور
```
