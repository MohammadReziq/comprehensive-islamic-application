# تسجيل الدخول بـ Google ونسيت كلمة المرور

## 1. سلوك "سجّلت بإيميل ثم دخلت بقوقل بنفس الإيميل"

- عند تسجيل الدخول بـ **Google** بنفس البريد الذي سجّل به المستخدم سابقاً (إيميل + كلمة سر)، يعتبر Supabase أنّه نفس المستخدم (أو يُربط تلقائياً حسب الإعدادات).
- في التطبيق: عند جلب الملف الشخصي نستدعي الدالة `link_user_profile_to_auth` (migration 003). هذه الدالة تربط صف جدول `users` الذي يحمل **نفس الإيميل** بحساب المصادقة الحالي (بعد دخول Google).
- **النتيجة:** نفس الملف (الاسم، الدور، المسجد، إلخ) يظهر سواء دخل المستخدم بالإيميل/كلمة السر أو بـ Google. لا يتم إنشاء حساب مكرر.

## 2. نسيت كلمة المرور — رمز OTP في التطبيق

التدفق في التطبيق: **إيميل → إرسال رمز → إدخال الرمز في التطبيق → كلمة السر الجديدة**. لا حاجة للمستخدم لفتح رابط من البريد.

### إعداد الإيميلات (مُوصى به للإنتاج): Resend

- البريد المدمج في Supabase محدود (حوالي 2 إيميل/ساعة) للتجربة فقط.
- للإنتاج: استخدم **Resend** (مجاني حتى 3,000 إيميل/شهر، 100/يوم):

1. سجّل في [resend.com](https://resend.com) وأنشئ **API Key**.
2. في **Supabase Dashboard → Project Settings → Authentication → SMTP Settings**:
   - فعّل **Custom SMTP**.
   - Host: `smtp.resend.com`
   - Port: `465`
   - Username: `resend`
   - Password: (API Key من Resend)
3. احفظ. بعدها إيميلات المصادقة (تسجيل، استعادة كلمة المرور) تخرج عبر Resend.

### قالب إيميل "استعادة كلمة المرور" ليعرض الرمز

لكي يصل المستخدم **رمز 6 خانات** ليدخله في التطبيق (بدل الاعتماد على الرابط فقط):

1. **Supabase Dashboard → Authentication → Email Templates**
2. اختر **Reset password** (استعادة كلمة المرور).
3. في محتوى القالب استخدم المتغيّر `{{ .Token }}` لعرض الرمز، مثلاً:

```html
<h2>استعادة كلمة المرور</h2>
<p>مرحباً،</p>
<p>رمزك لاستعادة كلمة المرور هو: <strong>{{ .Token }}</strong></p>
<p>أدخل هذا الرمز في التطبيق ثم اختر كلمة مرور جديدة.</p>
<p>إذا لم تطلب هذا، تجاهل هذا البريد.</p>
```

4. احفظ القالب. عند طلب "نسيت كلمة المرور" سيصل المستخدم إيميلاً فيه الرمز؛ يدخله في التطبيق ثم يغيّر كلمة السر داخل التطبيق.

## 3. إعداد تسجيل الدخول بـ Google (مرة واحدة)

### في Supabase Dashboard

1. **Authentication → Providers → Google**  
   فعّل Google وضيف **Client ID** و **Client Secret** من Google Cloud Console.

2. **Authentication → URL Configuration**  
   أضف رابط إعادة التوجيه المسموح:
   - `salatihayati://login-callback`
   - (أو النمط الذي تستخدمه، مثلاً مع مسار إضافي إن لزم.)

### في Google Cloud Console

1. من **APIs & Services → Credentials** أنشئ (أو استخدم) **OAuth 2.0 Client ID** لنوع **Android** و/أو **iOS** و/أو **Web** حسب المنصة.
2. في **Authorized redirect URIs** أضف:
   - نفس الرابط الذي في Supabase، مثلاً:  
     `salatihayati://login-callback`  
   - أو الرابط الذي يعيدك Supabase إليه (يمكن أن يكون من وثائق Supabase لـ OAuth).

### Deep Link في التطبيق (للطريقة عبر المتصفح)

- **Android:** في `AndroidManifest.xml` تمت إضافة `intent-filter` لـ `salatihayati://login-callback`.
- **iOS:** في `Info.plist` تمت إضافة `CFBundleURLTypes` لـ scheme `salatihayati`.

### تسجيل الدخول داخل التطبيق (قائمة حسابات Google — بدون متصفح)

لتجربة أفضل: أن يظهر اختيار حساب Google **داخل التطبيق** بدل فتح المتصفح:

1. من **Google Cloud Console → Credentials** انسخ **Client ID** من عمود "Web application" (إن لم يكن عندك، أنشئ OAuth 2.0 Client ID من نوع **Web application**).
2. في المشروع افتح `lib/app/core/network/supabase_client.dart`.   
3. عيّن **Web Client ID** في الكلاس `SupabaseConfig`:
   - `googleWebClientId = 'الـ Client ID الكامل من Google (Web application)'`
   - (اختياري لـ iOS) `googleIosClientId = 'الـ iOS Client ID'` إن أردت استخدام عميل iOS منفصل.
4. في **Supabase Dashboard → Authentication → Providers → Google** تأكد أن **Client ID** و **Client Secret** مضبوطان (نفس المشروع في Google Console).
5. (إن طُلِب) فعّل **Skip nonce check** لـ Google في Supabase إن ظهرت مشكلة في التحقق.

بعدها عند الضغط على "تسجيل بحساب Google" تظهر **قائمة حسابات Google** على الجهاز داخل التطبيق، وبعد الاختيار يتم الدخول مباشرة دون فتح المتصفح. ربط نفس الإيميل مع الملف الشخصي يعمل كما هو عبر `link_user_profile_to_auth`.

إن تركت `googleWebClientId` فارغاً، التطبيق يستخدم الطريقة القديمة (فتح المتصفح ثم العودة عبر deep link).

## 4. ملخص

| الميزة | الحل |
|--------|------|
| نفس الإيميل مسجّل بالإيميل ثم دخول بـ Google | ربط تلقائي عبر `link_user_profile_to_auth` → نفس الملف والدور |
| نسيت كلمة المرور | إيميل → رمز OTP في التطبيق → كلمة سر جديدة. إعداد Resend (SMTP) + قالب إيميل يعرض `{{ .Token }}` |
| تسجيل الدخول بـ Google | إن وُضع `googleWebClientId`: قائمة حسابات داخل التطبيق. وإلا: متصفح + deep link |
