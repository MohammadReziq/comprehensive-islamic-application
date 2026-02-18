-- ╔══════════════════════════════════════════════════════════════╗
-- ║  020 — Triggers: نقاط وسلاسل server-side                   ║
-- ║  يمنع التلاعب بالنقاط من العميل                             ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════
-- 1. دالة إعادة حساب إحصائيات الطفل
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION recalc_child_stats(p_child_id UUID)
RETURNS VOID AS $$
DECLARE
  v_total       INT := 0;
  v_current     INT := 0;
  v_best        INT := 0;
  v_streak      INT := 0;
  v_prev_date   DATE := NULL;
  v_max_date    DATE := NULL;
  rec           RECORD;
BEGIN
  -- 1) مجموع النقاط
  SELECT COALESCE(SUM(points_earned), 0)
    INTO v_total
    FROM attendance
   WHERE child_id = p_child_id;

  -- 2) أحدث تاريخ حضور
  SELECT MAX(prayer_date)
    INTO v_max_date
    FROM attendance
   WHERE child_id = p_child_id;

  -- 3) حساب best_streak من كل التواريخ المميزة (تنازلياً)
  FOR rec IN
    SELECT DISTINCT prayer_date
      FROM attendance
     WHERE child_id = p_child_id
     ORDER BY prayer_date DESC
  LOOP
    IF v_prev_date IS NULL THEN
      v_streak := 1;
    ELSIF v_prev_date - rec.prayer_date = 1 THEN
      v_streak := v_streak + 1;
    ELSE
      IF v_streak > v_best THEN v_best := v_streak; END IF;
      v_streak := 1;
    END IF;
    v_prev_date := rec.prayer_date;
  END LOOP;
  -- حفظ آخر سلسلة
  IF v_streak > v_best THEN v_best := v_streak; END IF;

  -- 4) حساب current_streak: السلسلة الحالية (تشمل اليوم أو أمس)
  v_streak    := 0;
  v_prev_date := NULL;

  IF v_max_date IS NOT NULL AND v_max_date >= CURRENT_DATE - INTERVAL '1 day' THEN
    FOR rec IN
      SELECT DISTINCT prayer_date
        FROM attendance
       WHERE child_id = p_child_id
       ORDER BY prayer_date DESC
    LOOP
      IF v_prev_date IS NULL THEN
        v_streak := 1;
      ELSIF v_prev_date - rec.prayer_date = 1 THEN
        v_streak := v_streak + 1;
      ELSE
        EXIT; -- انقطاع → نوقف
      END IF;
      v_prev_date := rec.prayer_date;
    END LOOP;
    v_current := v_streak;
  END IF;

  -- 5) تحديث الطفل (SECURITY DEFINER يتجاوز trigger الحماية)
  UPDATE children SET
    total_points   = v_total,
    current_streak = v_current,
    best_streak    = GREATEST(v_best, v_current)
  WHERE id = p_child_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════
-- 2. Trigger BEFORE INSERT: فرض النقاط server-side
--    يتجاهل القيمة المرسلة من العميل
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_enforce_points()
RETURNS TRIGGER AS $$
BEGIN
  -- نقاط الجماعة في المسجد = 10
  -- نقاط الفجر في المنزل = 5
  -- نقاط باقي الصلوات في المنزل = 3
  NEW.points_earned := CASE
    WHEN NEW.location_type = 'mosque' THEN 10
    WHEN NEW.prayer = 'fajr'          THEN 5
    ELSE                                   3
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_points_trigger ON attendance;
CREATE TRIGGER enforce_points_trigger
  BEFORE INSERT ON attendance
  FOR EACH ROW EXECUTE FUNCTION trg_enforce_points();

-- ═══════════════════════════════════════
-- 3. Trigger AFTER INSERT OR DELETE: إعادة حساب الإحصائيات
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_attendance_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM recalc_child_stats(OLD.child_id);
    RETURN OLD;
  ELSE
    PERFORM recalc_child_stats(NEW.child_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS attendance_stats_trigger ON attendance;
CREATE TRIGGER attendance_stats_trigger
  AFTER INSERT OR DELETE ON attendance
  FOR EACH ROW EXECUTE FUNCTION trg_attendance_stats();

-- ═══════════════════════════════════════
-- 4. Trigger BEFORE UPDATE على children:
--    يمنع العميل من تعديل النقاط/السلاسل مباشرة
--    (فقط SECURITY DEFINER functions تعدّلها)
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_protect_child_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- إذا لم يكن الطلب من service_role → أعد القيم القديمة
  IF current_setting('request.jwt.claims', true)::jsonb->>'role' != 'service_role' THEN
    NEW.total_points   := OLD.total_points;
    NEW.current_streak := OLD.current_streak;
    NEW.best_streak    := OLD.best_streak;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS protect_child_stats_trigger ON children;
CREATE TRIGGER protect_child_stats_trigger
  BEFORE UPDATE ON children
  FOR EACH ROW EXECUTE FUNCTION trg_protect_child_stats();

-- ═══════════════════════════════════════
-- 5. إعادة حساب كل الأطفال الحاليين (backfill)
-- ═══════════════════════════════════════

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT DISTINCT child_id FROM attendance LOOP
    PERFORM recalc_child_stats(r.child_id);
  END LOOP;
END;
$$;
