-- ╔══════════════════════════════════════════════════════════════╗
-- ║  021 — إصلاح ثغرات RLS الحرجة                              ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════
-- 1. إصلاح attendance INSERT
--    المشكلة: أي مستخدم مسجّل يسجّل حضور لأي طفل في أي مسجد
--    الحل: المسجّل يجب أن يكون عضواً في المسجد
-- ═══════════════════════════════════════

DROP POLICY IF EXISTS "Attendance: supervisor records" ON attendance;

CREATE POLICY "Attendance: member records"
  ON attendance FOR INSERT
  WITH CHECK (
    -- المسجّل هو المستخدم الحالي
    recorded_by_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
    AND
    -- المسجد يجب أن يكون مسجد المستخدم (عضو فيه)
    mosque_id IN (
      SELECT mm.mosque_id
        FROM mosque_members mm
        JOIN users u ON u.id = mm.user_id
       WHERE u.auth_id = auth.uid()
    )
  );

-- ═══════════════════════════════════════
-- 2. إصلاح notes INSERT
--    المشكلة: أي مستخدم يرسل ملاحظة لأي طفل
--    الحل: المرسل يجب أن يكون عضواً في المسجد
-- ═══════════════════════════════════════

DROP POLICY IF EXISTS "Notes: supervisor sends" ON notes;

CREATE POLICY "Notes: mosque member sends"
  ON notes FOR INSERT
  WITH CHECK (
    sender_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
    AND
    mosque_id IN (
      SELECT mm.mosque_id
        FROM mosque_members mm
        JOIN users u ON u.id = mm.user_id
       WHERE u.auth_id = auth.uid()
    )
  );

-- ═══════════════════════════════════════
-- 3. إصلاح announcements INSERT
--    المشكلة: أي مستخدم ينشئ إعلاناً لأي مسجد
--    الحل: المرسل يجب أن يكون عضواً في المسجد
-- ═══════════════════════════════════════

DROP POLICY IF EXISTS "Announcements: supervisor creates" ON announcements;

CREATE POLICY "Announcements: mosque member creates"
  ON announcements FOR INSERT
  WITH CHECK (
    sender_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
    AND
    mosque_id IN (
      SELECT mm.mosque_id
        FROM mosque_members mm
        JOIN users u ON u.id = mm.user_id
       WHERE u.auth_id = auth.uid()
    )
  );

-- إضافة UPDATE/DELETE للمرسل أو owner المسجد
CREATE POLICY "Announcements: sender or owner updates"
  ON announcements FOR UPDATE
  USING (
    sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    OR
    mosque_id IN (
      SELECT m.id FROM mosques m
      JOIN users u ON u.id = m.owner_id
      WHERE u.auth_id = auth.uid()
    )
  );

CREATE POLICY "Announcements: sender or owner deletes"
  ON announcements FOR DELETE
  USING (
    sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    OR
    mosque_id IN (
      SELECT m.id FROM mosques m
      JOIN users u ON u.id = m.owner_id
      WHERE u.auth_id = auth.uid()
    )
  );

-- ═══════════════════════════════════════
-- 4. إصلاح correction_requests: تفكيك FOR ALL
--    المشكلة: ولي الأمر يقدر يغيّر status إلى approved بنفسه!
--    الحل: تفكيك FOR ALL → SELECT + INSERT فقط لولي الأمر
-- ═══════════════════════════════════════

DROP POLICY IF EXISTS "Corrections: parent creates and reads" ON correction_requests;

-- ولي الأمر يقرأ طلباته فقط
CREATE POLICY "Corrections: parent reads own"
  ON correction_requests FOR SELECT
  USING (
    parent_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- ولي الأمر ينشئ طلباً (لا يستطيع UPDATE أو DELETE)
CREATE POLICY "Corrections: parent creates"
  ON correction_requests FOR INSERT
  WITH CHECK (
    parent_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- ملاحظة: سياسات المشرف/الإمام موجودة أصلاً:
-- "Corrections: supervisor reads mosque corrections" → SELECT
-- "Corrections: supervisor reviews"                 → UPDATE
