-- ═══════════════════════════════════════════════════════════════════
-- 030: سوبر أدمن — قراءة إحصائيات الأطفال والحضور
-- السبب: إحصائيات لوحة السوبر أدمن (إجمالي الأطفال، حضور اليوم)
--        تحتاج SELECT على children و attendance، والـ RLS الحالي لا يسمح
--        لسوبر أدمن برؤية كل الصفوف فيرجع 0.
-- الحل: سياسة SELECT إضافية باستخدام is_super_admin()
--
-- التشغيل: Supabase → SQL Editor → الصق المحتوى → Run
-- أو: supabase db push
-- ═══════════════════════════════════════════════════════════════════

-- سوبر أدمن يقرأ كل الأطفال (لإحصائيات إجمالي الأطفال)
CREATE POLICY "Super Admin: read all children"
  ON public.children FOR SELECT
  USING (public.is_super_admin());

-- سوبر أدمن يقرأ كل سجلات الحضور (لإحصائيات حضور اليوم)
CREATE POLICY "Super Admin: read all attendance"
  ON public.attendance FOR SELECT
  USING (public.is_super_admin());
