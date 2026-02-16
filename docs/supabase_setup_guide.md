# دليل إعداد Supabase لتطبيق "صلاتي حياتي"

## 1. الدخول إلى Supabase

1. افتح المتصفح وادخل: **https://supabase.com**
2. سجّل دخولك (أو أنشئ حساباً).
3. من **Dashboard** اختر مشروعك، أو أنشئ مشروع جديد:
   - **New Project** → اختر Organization → اسم المشروع → كلمة سر قاعدة البيانات (احفظها) → Region (مثلاً Frankfurt) → **Create**.

---

## 2. تفعيل المصادقة (Auth)

### من وين؟
من القائمة الجانبية: **Authentication** (أيقونة شخص).

### تفعيل تسجيل الدخول بالإيميل
1. اذهب إلى **Authentication** → **Providers**.
2. تأكد أن **Email** مفعّل (عادة مفعّل افتراضياً).
3. اختياري: من **Email Templates** عدّل قالب "Confirm signup" إذا حاب تخصّص رسالة التأكيد.

### تفعيل تسجيل الدخول بـ Google
1. من **Authentication** → **Providers** اضغط **Google**.
2. فعّل **Enable Sign in with Google**.
3. تحتاج من **Google Cloud Console**:
   - ادخل: https://console.cloud.google.com
   - مشروع → **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**.
   - نوع التطبيق: **Web application** (لـ Supabase).
   - Authorized redirect URIs: انسخ الرابط اللي يظهر في Supabase تحت إعدادات Google (شكلها: `https://nyiejilwpwhmednjqcho.supabase.co/auth/v1/callback`).
   - انسخ **Client ID** و **Client Secret** والصقهم في Supabase في حقول Google.
4. احفظ (**Save**).

### إعدادات إضافية (اختياري)
- من **Authentication** → **URL Configuration**: تأكد أن **Site URL** صحيح (مثلاً للاختبار: `http://localhost` أو رابط التطبيق).
- من **Authentication** → **Settings**: يمكنك تغيير "Confirm email" إذا حاب المستخدم يدخل بدون تأكيد إيميل في البداية.

---

## 3. تنفيذ الـ Schema و RLS (قاعدة البيانات + الصلاحيات)

### من وين؟
من القائمة الجانبية: **SQL Editor** (أيقونة `</>` أو "SQL Editor").

### الخطوات
1. اضغط **SQL Editor** → **New query**.
2. افتح الملف من مشروعك:
   ```
   supabase/migrations/001_initial_schema.sql
   ```
3. انسخ **كل** محتوى الملف (من أول سطر حتى آخر سطر).
4. الصق في نافذة الـ Query في Supabase.
5. اضغط **Run** (أو Ctrl+Enter).

إذا ظهرت رسالة نجاح بدون أخطاء، معناها:
- تم إنشاء الجداول (users, children, mosques, attendance, ...).
- تم تفعيل RLS (Row Level Security) ووضع الـ Policies.
- تم إنشاء الـ Trigger الذي ينشئ سجل في `users` عند تسجيل مستخدم جديد.

### لو ظهر خطأ "already exists"
- لو المشروع جديد وتنفّذ الملف لأول مرة: ما يتوقع يظهر هذا.
- لو سبق ونفّذت جزء من الملف: يمكن تنفيذ الأجزاء المتبقية فقط (مثلاً قسم RLS فقط)، أو إنشاء مشروع Supabase جديد وتنفيذ الملف من جديد.

---

## 4. أخذ الـ URL والـ Anon Key (للتطبيق)

التطبيق عندك يستخدم قيم ثابتة في `lib/app/core/network/supabase_client.dart`. لو أنشأت مشروعاً جديداً:

1. من القائمة الجانبية: **Project Settings** (ترس).
2. من تبويب **API** انسخ:
   - **Project URL** → ضعه في `SupabaseConfig.url`.
   - **anon public** key → ضعه في `SupabaseConfig.anonKey`.

---

## ملخص سريع

| المطلوب              | من وين في Supabase؟        |
|----------------------|----------------------------|
| تفعيل Auth (Email/Google) | **Authentication** → **Providers** |
| تنفيذ الجداول + RLS  | **SQL Editor** → لصق محتوى `001_initial_schema.sql` → Run |
| URL و Anon Key       | **Project Settings** → **API** |

بعد هالخطوات يكون Supabase جاهز من ناحية المصادقة وقاعدة البيانات والصلاحيات، وتبقى خطوة إضافة `google-services.json` من Firebase لو حاب الإشعارات تعمل.
