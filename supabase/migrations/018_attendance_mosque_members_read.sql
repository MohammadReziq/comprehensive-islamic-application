-- ═══════════════════════════════════════════════════════════════════
-- صلاحيات الحضور: المشرف يرى حضور مسجده (بما فيه ما سجّله الإمام)
-- السبب: السياسة الحالية تسمح بالقراءة فقط لـ ولي الأمر أو لـ recorded_by_id
--        فالمشرف لا يرى سجلات الحضور التي سجّلها الإمام على الطلاب
-- الحل: السماح لأعضاء المسجد (mosque_members) بقراءة حضور ذلك المسجد
-- ═══════════════════════════════════════════════════════════════════

CREATE POLICY "Attendance: mosque members read mosque attendance"
  ON public.attendance FOR SELECT
  USING (
    mosque_id IS NOT NULL
    AND mosque_id IN (
      SELECT mm.mosque_id FROM mosque_members mm
      JOIN users u ON u.id = mm.user_id
      WHERE u.auth_id = auth.uid()
    )
  );
