# نشر دالة إنشاء حساب الابن (create_child_account)

لكي يستطيع ولي الأمر إنشاء حساب لابنه من التطبيق، يجب نشر Edge Function في Supabase.

## الخطوات

1. **تشغيل الهجرة 028** (إن لم تكن مُطبَّقة):
   - من لوحة Supabase: SQL Editor → تشغيل محتوى `supabase/migrations/028_child_account.sql`
   - أو عبر CLI: `supabase db push` (أو تطبيق الهجرات يدوياً)

2. **نشر الدالة:**
   ```bash
   supabase functions deploy create_child_account
   ```
   أو من لوحة Supabase: Edge Functions → إنشاء/نشر الدالة من مجلد `supabase/functions/create_child_account`.

3. **المتغيرات والـ Secrets:**  
   Supabase يضيف تلقائياً `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` للدوال المنشورة. إذا ظهر خطأ من الدالة (مثل "تم إنشاء الحساب لكن الربط فشل" أو خطأ في إنشاء المستخدم)، أضف الـ Secret يدوياً كما يلي.

## إضافة SUPABASE_SERVICE_ROLE_KEY يدوياً (Edge Functions → Secrets)

1. **افتح لوحة Supabase:**  
   [https://supabase.com/dashboard](https://supabase.com/dashboard) → اختر مشروعك.

2. **انسخ مفتاح Service Role:**
   - من القائمة الجانبية: **Project Settings** (أيقونة الترس).
   - تبويب **API**.
   - في قسم **Project API keys** انسخ قيمة **`service_role`** (المفتاح السري، لا تشاركه ولا تضعه في الكود).

3. **افتح إعدادات Edge Functions:**
   - من القائمة الجانبية: **Edge Functions**.
   - انقر **Manage secrets** أو **Secrets** (أو من **Project Settings** → **Edge Functions** → **Secrets** حسب إصدار اللوحة).

4. **أضف الـ Secret:**
   - **Add new secret** أو **New secret**.
   - **Name:** `SUPABASE_SERVICE_ROLE_KEY` (بالضبط، حروف كبيرة).
   - **Value:** الصق مفتاح الـ `service_role` الذي نسخته من خطوة 2.
   - احفظ.

5. **إعادة نشر الدالة (اختياري):**  
   إذا كانت الدالة منشورة مسبقاً، قد تحتاج إلى إعادة النشر أو الانتظار قليلاً حتى تُحمَّل القيمة الجديدة:
   ```bash
   supabase functions deploy create_child_account
   ```

> **تنبيه:** لا تضع مفتاح `service_role` داخل كود التطبيق أو في مستودع عام. يُستخدم فقط في الخادم (Edge Functions) أو في بيئة آمنة.

## ماذا تفعل الدالة؟

- تتحقق من جلسة ولي الأمر ومن أن الابن يخصه.
- تنشئ مستخدماً في Auth (بريد + كلمة مرور) مع `user_metadata: { role: "child", name }`.
- الـ trigger `handle_new_user` ينشئ صفاً في `users` بدور `child`.
- تربط الابن بحساب الدخول عبر تحديث `children.login_user_id` (بمفتاح service role فقط).

## إذا ظهر خطأ في التطبيق

- **"الدالة غير متوفرة"** → تأكد من نشر الدالة وأن المشروع يتصل بنفس مشروع Supabase.
- **"انتهت الجلسة"** → ولي الأمر يجب أن يعيد تسجيل الدخول.
- **"فشل ربط الحساب بالطفل"** أو **"تم إنشاء الحساب لكن الربط فشل"** → تأكد من تطبيق هجرة 028 (عمود `login_user_id` + الـ trigger الذي يسمح فقط لـ service_role بتحديثه).

بعد النشر، إنشاء حساب الابن من شاشة "إضافة ابن" يعمل من البداية للنهاية، ويظهر حوار بيانات الدخول (إيميل + كلمة مرور) لولي الأمر؛ الابن يسجّل الدخول من شاشة الدخول → "تسجيل الدخول بالبريد الإلكتروني".
