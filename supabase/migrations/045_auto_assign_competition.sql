-- ╔══════════════════════════════════════════════════════════════╗
-- ║  045 — Auto-assign competition_id on attendance insert     ║
-- ║  يُعيّن المسابقة النشطة تلقائياً عند تسجيل الحضور          ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════
-- 1. Trigger: تعيين competition_id تلقائياً
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_assign_competition()
RETURNS TRIGGER AS $$
BEGIN
  -- فقط حضور المسجد الذي لم يُعيّن له مسابقة
  IF NEW.mosque_id IS NOT NULL AND NEW.competition_id IS NULL THEN
    SELECT id INTO NEW.competition_id
      FROM competitions
     WHERE mosque_id = NEW.mosque_id
       AND is_active = true
       AND start_date <= NEW.prayer_date
       AND end_date   >= NEW.prayer_date
     LIMIT 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS assign_competition_trigger ON attendance;
CREATE TRIGGER assign_competition_trigger
  BEFORE INSERT ON attendance
  FOR EACH ROW EXECUTE FUNCTION trg_assign_competition();

-- ═══════════════════════════════════════
-- 2. Backfill: ربط الحضور الموجود بالمسابقات النشطة
--    (الحضور الذي تم تسجيله أثناء مسابقة لكن بدون competition_id)
-- ═══════════════════════════════════════

UPDATE attendance a
   SET competition_id = c.id
  FROM competitions c
 WHERE a.mosque_id = c.mosque_id
   AND a.competition_id IS NULL
   AND a.prayer_date >= c.start_date
   AND a.prayer_date <= c.end_date
   AND (c.is_active = true OR c.end_date < CURRENT_DATE);
