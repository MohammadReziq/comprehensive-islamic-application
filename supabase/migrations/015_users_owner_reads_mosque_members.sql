-- مالك المسجد يقرأ اسم/إيميل الأعضاء (المشرفين) في مسجده لعرضهم في لوحة الإمام.
-- نستخدم (users.auth_id IS DISTINCT FROM auth.uid()) حتى لا تُقيَّم السياسة عند قراءة الملف الشخصي → لا recursion.
--
-- التشغيل: Supabase → SQL Editor → الصق المحتوى → Run
--

-- التأكد من وجود الدالة (قد تكون موجودة من 013)
CREATE OR REPLACE FUNCTION public.get_current_user_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT id FROM public.users WHERE auth_id = auth.uid() LIMIT 1;
$$;

CREATE POLICY "Users: mosque owner reads mosque members"
  ON public.users FOR SELECT
  USING (
    (users.auth_id IS DISTINCT FROM auth.uid())
    AND
    EXISTS (
      SELECT 1 FROM mosque_members mm
      JOIN mosques m ON m.id = mm.mosque_id
      WHERE mm.user_id = users.id
        AND (
          m.owner_id = public.get_current_user_id()
          OR EXISTS (
            SELECT 1 FROM mosque_members mm2
            WHERE mm2.mosque_id = m.id
              AND mm2.user_id = public.get_current_user_id()
              AND mm2.role = 'owner'
          )
        )
    )
  );
