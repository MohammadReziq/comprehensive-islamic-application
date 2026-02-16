-- إصلاح: infinite recursion في سياسة "Users: mosque owner reads join requesters"
-- السبب: السياسة كانت تقرأ من جدول users داخل نفس السياسة
-- الحل: دالة SECURITY DEFINER تُرجع id المستخدم الحالي بدون تفعيل RLS على users
--
-- التشغيل: Supabase → SQL Editor → الصق المحتوى → Run
--

-- دالة تُرجع id المستخدم الحالي (من users حيث auth_id = auth.uid())
CREATE OR REPLACE FUNCTION public.get_current_user_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT id FROM public.users WHERE auth_id = auth.uid() LIMIT 1;
$$;

-- إزالة السياسة التي تسبب التع recursion
DROP POLICY IF EXISTS "Users: mosque owner reads join requesters" ON public.users;

-- إعادة إنشاء السياسة: تُقيَّم فقط عند قراءة صف مستخدم آخر (لا عند قراءة الملف الشخصي)
-- عند قراءة الملف الشخصي: users.auth_id = auth.uid() فالشروط التالية لا تُقيَّم → لا استدعاء للدالة → لا recursion
CREATE POLICY "Users: mosque owner reads join requesters"
  ON public.users FOR SELECT
  USING (
    (users.auth_id IS DISTINCT FROM auth.uid())
    AND
    (
      EXISTS (
        SELECT 1 FROM mosque_join_requests mjr
        JOIN mosques m ON m.id = mjr.mosque_id
        WHERE mjr.user_id = users.id
          AND mjr.status = 'pending'
          AND m.owner_id = public.get_current_user_id()
      )
      OR
      EXISTS (
        SELECT 1 FROM mosque_join_requests mjr
        JOIN mosque_members mm ON mm.mosque_id = mjr.mosque_id
        WHERE mm.user_id = public.get_current_user_id()
          AND mm.role = 'owner'
          AND mjr.user_id = users.id
          AND mjr.status = 'pending'
      )
    )
  );
