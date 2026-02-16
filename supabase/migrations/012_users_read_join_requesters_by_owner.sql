-- مالك المسجد يقرأ اسم/إيميل المستخدمين الذين لديهم طلب انضمام معلّق لمسجده
-- (ضروري لعرض طلبات الانضمام في لوحة الإمام مع اسم الطالب)
CREATE POLICY "Users: mosque owner reads join requesters"
  ON public.users FOR SELECT
  USING (
    -- المالك عبر mosques.owner_id
    EXISTS (
      SELECT 1 FROM mosque_join_requests mjr
      JOIN mosques m ON m.id = mjr.mosque_id
      WHERE mjr.user_id = users.id
        AND mjr.status = 'pending'
        AND m.owner_id IN (SELECT u.id FROM users u WHERE u.auth_id = auth.uid())
    )
    OR
    -- المالك عبر mosque_members (دور owner)
    EXISTS (
      SELECT 1 FROM mosque_join_requests mjr
      JOIN mosque_members mm ON mm.mosque_id = mjr.mosque_id
      JOIN users u ON u.id = mm.user_id
      WHERE u.auth_id = auth.uid()
        AND mm.role = 'owner'
        AND mjr.user_id = users.id
        AND mjr.status = 'pending'
    )
  );
