-- السماح لمالك المسجد (من mosque_members بدور owner) بقراءة طلبات الانضمام
-- يغطي الحالة التي يكون فيها المستخدم مسجّلاً كعضو owner في المسجد
CREATE POLICY "Join requests: owner read via mosque_members"
  ON mosque_join_requests FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM mosque_members mm
      JOIN users u ON u.id = mm.user_id
      WHERE u.auth_id = auth.uid()
        AND mm.mosque_id = mosque_join_requests.mosque_id
        AND mm.role = 'owner'
    )
  );

-- نفس الفكرة للتحديث (موافقة/رفض)
CREATE POLICY "Join requests: owner update via mosque_members"
  ON mosque_join_requests FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM mosque_members mm
      JOIN users u ON u.id = mm.user_id
      WHERE u.auth_id = auth.uid()
        AND mm.mosque_id = mosque_join_requests.mosque_id
        AND mm.role = 'owner'
    )
  );
