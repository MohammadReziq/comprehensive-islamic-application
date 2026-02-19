-- ═══════════════════════════════════════════════════════════════╗
-- ║  029 — نقاط الصلوات من mosques.prayer_config (الإمام يتحكم) ║
-- ║  لا ثوابت للجماعة في الجسم — القراءة من DB فقط             ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION trg_enforce_points()
RETURNS TRIGGER AS $$
DECLARE
  v_config JSONB;
  v_points INT;
BEGIN
  -- صلاة المنزل: ثابت (الإمام لا يتحكم بها)
  IF NEW.location_type = 'home' THEN
    NEW.points_earned := CASE WHEN NEW.prayer = 'fajr' THEN 5 ELSE 3 END;
    RETURN NEW;
  END IF;

  -- صلاة الجماعة: القراءة من prayer_config للمسجد، افتراضي 10
  IF NEW.location_type = 'mosque' AND NEW.mosque_id IS NOT NULL THEN
    SELECT prayer_config INTO v_config FROM mosques WHERE id = NEW.mosque_id;
    v_points := COALESCE((v_config->>NEW.prayer::TEXT)::INT, 10);
    NEW.points_earned := v_points;
    RETURN NEW;
  END IF;

  -- fallback (mosque بدون mosque_id أو غير متوقع)
  NEW.points_earned := 10;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- التأكد أن الـ trigger ما زال مربوطاً (قد يكون موجوداً من 020)
DROP TRIGGER IF EXISTS enforce_points_trigger ON attendance;
CREATE TRIGGER enforce_points_trigger
  BEFORE INSERT ON attendance
  FOR EACH ROW EXECUTE FUNCTION trg_enforce_points();
