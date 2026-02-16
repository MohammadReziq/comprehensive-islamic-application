-- ═══════════════════════════════════════════════════════════════════
-- إصلاح: infinite recursion في سياسة جدول users
-- السبب: السياسة "Super Admin: read all users" كانت تفحص جدول users
--        داخل السياسة نفسها → حلقة لا نهائية
-- الحل: دالة SECURITY DEFINER تتحقق من دور السوبر أدمن بدون RLS
--
-- التشغيل: Supabase → SQL Editor → الصق المحتوى → Run
-- ═══════════════════════════════════════════════════════════════════

-- دالة تتحقق إذا المستخدم الحالي سوبر أدمن (تعمل بدون تفعيل RLS على users)
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE auth_id = auth.uid() AND role = 'super_admin'
  );
$$;

-- إزالة السياسة القديمة التي تسبب التع recursion
DROP POLICY IF EXISTS "Super Admin: read all users" ON public.users;

-- سياسة جديدة: إما تقرأ ملفك (auth_id = auth.uid()) أو أنت سوبر أدمن فتقدر تقرأ الكل
CREATE POLICY "Super Admin: read all users"
  ON public.users FOR SELECT
  USING (
    auth_id = auth.uid()
    OR public.is_super_admin()
  );

-- تحديث سياسة المساجد لاستخدام الدالة بدل الاستعلام عن users (تفادي أي recursion)
DROP POLICY IF EXISTS "Super Admin: manage mosques" ON public.mosques;
CREATE POLICY "Super Admin: manage mosques"
  ON public.mosques FOR ALL
  USING (public.is_super_admin());
