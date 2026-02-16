-- ═══════════════════════════════════════════════════════════════════
-- إصلاح: infinite recursion في سياسات children و mosque_children
-- السبب: سياسة children (المشرفون) تقرأ mosque_children، وسياسة mosque_children
--        تقرأ children → حلقة لا نهائية
-- الحل: دوال SECURITY DEFINER تُرجع المعرّفات بدون تفعيل RLS
--
-- التشغيل: Supabase → SQL Editor → الصق المحتوى → Run
-- ═══════════════════════════════════════════════════════════════════

-- أطفال المستخدم الحالي (ولي الأمر) — بدون تفعيل RLS
CREATE OR REPLACE FUNCTION public.get_my_child_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT c.id FROM children c
  JOIN users u ON u.id = c.parent_id
  WHERE u.auth_id = auth.uid();
$$;

-- أطفال مرئيون للمشرف الحالي (من مساجده) — بدون تفعيل RLS
CREATE OR REPLACE FUNCTION public.get_supervisor_visible_child_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT mc.child_id FROM mosque_children mc
  JOIN mosque_members mm ON mm.mosque_id = mc.mosque_id
  JOIN users u ON u.id = mm.user_id
  WHERE u.auth_id = auth.uid();
$$;

-- إزالة السياسة القديمة للمشرفين على children
DROP POLICY IF EXISTS "Children: supervisors read mosque children" ON public.children;

-- سياسة جديدة: المشرف يقرأ أطفال مسجده عبر الدالة (بدون recursion)
CREATE POLICY "Children: supervisors read mosque children"
  ON public.children FOR SELECT
  USING (id IN (SELECT get_supervisor_visible_child_ids()));

-- إزالة السياسة القديمة لقراءة mosque_children
DROP POLICY IF EXISTS "Mosque Children: read" ON public.mosque_children;

-- سياسة جديدة: ولي الأمر يقرأ ربط أطفاله، أو المشرف يقرأ ربط مسجده (بدون recursion)
CREATE POLICY "Mosque Children: read"
  ON public.mosque_children FOR SELECT
  USING (
    child_id IN (SELECT get_my_child_ids())
    OR mosque_id IN (
      SELECT mm.mosque_id FROM mosque_members mm
      JOIN users u ON u.id = mm.user_id
      WHERE u.auth_id = auth.uid()
    )
  );

-- تحديث سياسة الإدراج لـ mosque_children لاستخدام الدالة
DROP POLICY IF EXISTS "Mosque Children: parent links" ON public.mosque_children;
CREATE POLICY "Mosque Children: parent links"
  ON public.mosque_children FOR INSERT
  WITH CHECK (child_id IN (SELECT get_my_child_ids()));
