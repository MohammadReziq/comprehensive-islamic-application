-- السماح للمستخدم بالانضمام لمسجد معتمد بكود الدعوة (إدراج نفسه في mosque_members كمشرف)
-- السياسة الحالية تسمح فقط لمالك المسجد بإضافة أعضاء؛ المشرف الذي يدخل الكود يحتاج إدراج نفسه.
CREATE POLICY "Mosque Members: join by invite (self)"
  ON mosque_members FOR INSERT
  WITH CHECK (
    user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    AND mosque_id IN (SELECT id FROM mosques WHERE status = 'approved')
  );
