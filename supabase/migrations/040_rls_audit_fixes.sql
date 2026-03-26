-- [040] تدقيق وإصلاح سياسات RLS
-- التاريخ: 2026-03-24

-- ═══════════════════════════════════════════════════
-- 1. إضافة DELETE policy على supervisor_credentials
-- لو الإمام أزال مشرف، يقدر يحذف بياناته
-- ═══════════════════════════════════════════════════

DROP POLICY IF EXISTS "imam_deletes_own_mosque_credentials" ON supervisor_credentials;

CREATE POLICY "imam_deletes_own_mosque_credentials"
ON supervisor_credentials FOR DELETE
USING (
  mosque_id IN (
    SELECT m.id FROM mosques m
    JOIN users u ON u.id = m.owner_id
    WHERE u.auth_id = auth.uid()
  )
);

-- ═══════════════════════════════════════════════════
-- 2. إضافة UPDATE على correction_requests للمشرف
-- المشرف يقدر يوافق/يرفض طلبات التصحيح في مسجده
-- ═══════════════════════════════════════════════════

DROP POLICY IF EXISTS "supervisor_updates_correction_requests" ON correction_requests;

CREATE POLICY "supervisor_updates_correction_requests"
ON correction_requests FOR UPDATE
USING (
  mosque_id IN (
    SELECT mm.mosque_id
    FROM mosque_members mm
    JOIN users u ON u.id = mm.user_id
    WHERE u.auth_id = auth.uid()
    AND mm.role = 'supervisor'
  )
)
WITH CHECK (true);

-- ═══════════════════════════════════════════════════
-- 3. تحقق من سياسة SELECT على children
-- ⚠ افحص السياسة الحالية قبل تطبيق هذا الجزء
-- نفذ هذا في SQL Editor أولاً:
-- SELECT policyname, qual FROM pg_policies WHERE tablename = 'children';
-- لو يستخدم subquery مع auth_id → لا تغيير مطلوب
-- لو يستخدم parent_id = auth.uid() مباشرة → فعّل الجزء التالي
-- ═══════════════════════════════════════════════════

DO $$
DECLARE
  policy_uses_subquery BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_policies
    WHERE tablename = 'children'
    AND policyname LIKE '%parent%'
    AND (qual LIKE '%auth_id%' OR qual LIKE '%subquery%' OR qual LIKE '%SELECT%')
  ) INTO policy_uses_subquery;

  IF NOT policy_uses_subquery THEN
    -- السياسة تستخدم parent_id = auth.uid() مباشرة → خاطئ، نصلحها
    DROP POLICY IF EXISTS "parents_can_select_own_children" ON children;
    DROP POLICY IF EXISTS "parents_own_children_select_v2" ON children;

    CREATE POLICY "parents_own_children_select_fixed"
    ON children FOR SELECT
    USING (
      parent_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
      )
    );
  END IF;
END $$;
