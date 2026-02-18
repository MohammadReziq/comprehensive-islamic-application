-- ╔══════════════════════════════════════════════════════════════╗
-- ║  022 — جدول المسابقات + ربط الحضور بها                     ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════
-- 1. جدول competitions
-- ═══════════════════════════════════════

CREATE TABLE IF NOT EXISTS competitions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id   UUID NOT NULL REFERENCES mosques(id) ON DELETE CASCADE,
  name_ar     TEXT NOT NULL,
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT false,
  created_by  UUID NOT NULL REFERENCES users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_date >= start_date)
);

-- مسابقة نشطة واحدة فقط لكل مسجد (partial unique index)
CREATE UNIQUE INDEX IF NOT EXISTS idx_competitions_active_mosque
  ON competitions(mosque_id) WHERE is_active = true;

-- ═══════════════════════════════════════
-- 2. RLS على competitions
-- ═══════════════════════════════════════

ALTER TABLE competitions ENABLE ROW LEVEL SECURITY;

-- owner المسجد يدير المسابقات (CRUD)
CREATE POLICY "Competitions: owner manages"
  ON competitions FOR ALL
  USING (
    mosque_id IN (
      SELECT m.id FROM mosques m
      JOIN users u ON u.id = m.owner_id
      WHERE u.auth_id = auth.uid()
    )
  );

-- أعضاء المسجد يقرأون
CREATE POLICY "Competitions: members read"
  ON competitions FOR SELECT
  USING (
    mosque_id IN (
      SELECT mm.mosque_id
        FROM mosque_members mm
        JOIN users u ON u.id = mm.user_id
       WHERE u.auth_id = auth.uid()
    )
  );

-- أولياء الأمور يقرأون مسابقات مساجد أطفالهم
CREATE POLICY "Competitions: parents read"
  ON competitions FOR SELECT
  USING (
    mosque_id IN (
      SELECT mc.mosque_id
        FROM mosque_children mc
        JOIN children c ON c.id = mc.child_id
        JOIN users u ON u.id = c.parent_id
       WHERE u.auth_id = auth.uid()
    )
  );

-- ═══════════════════════════════════════
-- 3. ربط الحضور بالمسابقة
-- ═══════════════════════════════════════

ALTER TABLE attendance
  ADD COLUMN IF NOT EXISTS competition_id UUID REFERENCES competitions(id);

CREATE INDEX IF NOT EXISTS idx_attendance_competition
  ON attendance(competition_id);

-- ═══════════════════════════════════════
-- 4. إضافة timezone للمسجد
-- ═══════════════════════════════════════

ALTER TABLE mosques
  ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'Asia/Riyadh';

-- ═══════════════════════════════════════
-- 5. دالة مساعدة: "اليوم" بتوقيت المسجد
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION mosque_today(p_mosque_id UUID)
RETURNS DATE AS $$
DECLARE
  v_tz TEXT;
BEGIN
  SELECT COALESCE(timezone, 'Asia/Riyadh')
    INTO v_tz
    FROM mosques
   WHERE id = p_mosque_id;
  RETURN (now() AT TIME ZONE v_tz)::DATE;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ═══════════════════════════════════════
-- 6. إضافة competitions لـ Realtime publication
-- ═══════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE competitions;
