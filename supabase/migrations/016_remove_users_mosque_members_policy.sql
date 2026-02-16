-- إزالة سياسة "Users: mosque owner reads mosque members" لتفادي recursion على جدول users.
-- التطبيق يعرض قائمة المشرفين بدون embed من users (نص "مشرف" في الواجهة).
--
-- التشغيل: Supabase → SQL Editor → الصق المحتوى → Run
--

DROP POLICY IF EXISTS "Users: mosque owner reads mosque members" ON public.users;
