-- [I1+I2] السماح للمشرف بتعديل طلبات التصحيح في مسجده
-- ═══════════════════════════════════════════════════════════

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'supervisor_updates_corrections'
      AND tablename = 'correction_requests'
  ) THEN
    EXECUTE '
      CREATE POLICY "supervisor_updates_corrections"
      ON correction_requests FOR UPDATE
      USING (
        mosque_id IN (
          SELECT mm.mosque_id FROM mosque_members mm
          JOIN users u ON u.id = mm.user_id
          WHERE u.auth_id = auth.uid()
          AND mm.role IN (''owner'', ''supervisor'')
        )
      )
      WITH CHECK (
        mosque_id IN (
          SELECT mm.mosque_id FROM mosque_members mm
          JOIN users u ON u.id = mm.user_id
          WHERE u.auth_id = auth.uid()
          AND mm.role IN (''owner'', ''supervisor'')
        )
      )
    ';
  END IF;
END $$;

-- السماح للمشرف بقراءة طلبات التصحيح في مسجده
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'supervisor_reads_corrections'
      AND tablename = 'correction_requests'
  ) THEN
    EXECUTE '
      CREATE POLICY "supervisor_reads_corrections"
      ON correction_requests FOR SELECT
      USING (
        mosque_id IN (
          SELECT mm.mosque_id FROM mosque_members mm
          JOIN users u ON u.id = mm.user_id
          WHERE u.auth_id = auth.uid()
          AND mm.role IN (''owner'', ''supervisor'')
        )
      )
    ';
  END IF;
END $$;
