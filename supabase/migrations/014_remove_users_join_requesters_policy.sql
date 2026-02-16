-- إزالة سياسة "Users: mosque owner reads join requesters" نهائياً لتفادي أي recursion على جدول users.
-- التطبيق يعرض طلبات الانضمام بدون اسم/إيميل الطالب (بدون embed من users) فلا حاجة للسياسة.
--
-- التشغيل: Supabase → SQL Editor → الصق المحتوى → Run
--

DROP POLICY IF EXISTS "Users: mosque owner reads join requesters" ON public.users;
