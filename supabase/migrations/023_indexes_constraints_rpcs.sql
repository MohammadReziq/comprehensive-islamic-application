-- ╔══════════════════════════════════════════════════════════════╗
-- ║  023 — Indexes + Constraints + RPC إلغاء الحضور            ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════
-- 1. Indexes لتسريع الاستعلامات الأكثر تكراراً
-- ═══════════════════════════════════════

-- طلبات التصحيح المعلقة لمسجد (الاستعلام الأكثر تكراراً للمشرف)
CREATE INDEX IF NOT EXISTS idx_corrections_mosque_status
  ON correction_requests(mosque_id, status);

-- حضور طفل مرتب بالتاريخ (لحساب السلسلة وعرض التاريخ)
CREATE INDEX IF NOT EXISTS idx_attendance_child_date
  ON attendance(child_id, prayer_date DESC);

-- ملاحظات غير مقروءة لطفل
CREATE INDEX IF NOT EXISTS idx_notes_child_unread
  ON notes(child_id, is_read) WHERE is_read = false;

-- مسابقات المسجد
CREATE INDEX IF NOT EXISTS idx_competitions_mosque
  ON competitions(mosque_id, is_active);

-- ═══════════════════════════════════════
-- 2. Partial Unique: منع تكرار طلب تصحيح pending
--    ولي الأمر لا يرسل أكثر من طلب pending لنفس (طفل، صلاة، تاريخ)
-- ═══════════════════════════════════════

CREATE UNIQUE INDEX IF NOT EXISTS idx_corrections_pending_unique
  ON correction_requests(child_id, prayer, prayer_date)
  WHERE status = 'pending';

-- ═══════════════════════════════════════
-- 3. RPC: إلغاء حضور (للمشرف خلال 24 ساعة)
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION cancel_attendance(p_attendance_id UUID)
RETURNS VOID AS $$
DECLARE
  v_child_id    UUID;
  v_recorded_by UUID;
  v_recorded_at TIMESTAMPTZ;
  v_user_id     UUID;
BEGIN
  -- جلب بيانات السجل
  SELECT child_id, recorded_by_id, recorded_at
    INTO v_child_id, v_recorded_by, v_recorded_at
    FROM attendance
   WHERE id = p_attendance_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'سجل الحضور غير موجود';
  END IF;

  -- التحقق: المستخدم الحالي
  SELECT id INTO v_user_id
    FROM users
   WHERE auth_id = auth.uid();

  -- فقط من سجّل الحضور يقدر يلغيه
  IF v_recorded_by != v_user_id THEN
    RAISE EXCEPTION 'ليس لديك صلاحية إلغاء هذا السجل';
  END IF;

  -- خلال 24 ساعة فقط
  IF now() - v_recorded_at > INTERVAL '24 hours' THEN
    RAISE EXCEPTION 'انتهت مهلة الإلغاء (24 ساعة)';
  END IF;

  -- الحذف (الـ trigger سيعيد حساب النقاط/السلاسل تلقائياً)
  DELETE FROM attendance WHERE id = p_attendance_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════
-- 4. RPC: تفعيل مسابقة (يوقف النشطة أولاً)
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION activate_competition(p_competition_id UUID)
RETURNS VOID AS $$
DECLARE
  v_mosque_id UUID;
  v_user_id   UUID;
  v_owner_id  UUID;
BEGIN
  -- جلب mosque_id للمسابقة
  SELECT mosque_id INTO v_mosque_id
    FROM competitions
   WHERE id = p_competition_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المسابقة غير موجودة';
  END IF;

  -- التحقق: المستخدم هو owner المسجد
  SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
  SELECT owner_id INTO v_owner_id FROM mosques WHERE id = v_mosque_id;

  IF v_owner_id != v_user_id THEN
    RAISE EXCEPTION 'ليس لديك صلاحية تفعيل المسابقة';
  END IF;

  -- إيقاف أي مسابقة نشطة أخرى لنفس المسجد
  UPDATE competitions
     SET is_active = false
   WHERE mosque_id = v_mosque_id
     AND is_active = true
     AND id != p_competition_id;

  -- تفعيل المسابقة المطلوبة
  UPDATE competitions
     SET is_active = true
   WHERE id = p_competition_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════
-- 5. RPC: الموافقة على طلب تصحيح (transaction آمنة)
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION approve_correction_request(p_request_id UUID)
RETURNS UUID AS $$
DECLARE
  v_req         RECORD;
  v_user_id     UUID;
  v_points      INT;
  v_attendance_id UUID;
  v_competition_id UUID;
BEGIN
  -- جلب بيانات الطلب
  SELECT * INTO v_req
    FROM correction_requests
   WHERE id = p_request_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الطلب غير موجود';
  END IF;

  IF v_req.status != 'pending' THEN
    RAISE EXCEPTION 'الطلب ليس في حالة انتظار';
  END IF;

  -- التحقق: المستخدم عضو في المسجد
  SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();

  IF NOT EXISTS (
    SELECT 1 FROM mosque_members mm
    JOIN users u ON u.id = mm.user_id
    WHERE u.auth_id = auth.uid()
      AND mm.mosque_id = v_req.mosque_id
  ) THEN
    RAISE EXCEPTION 'ليس لديك صلاحية مراجعة هذا الطلب';
  END IF;

  -- التحقق: لا يوجد حضور مسبق لنفس (طفل، صلاة، تاريخ)
  IF EXISTS (
    SELECT 1 FROM attendance
     WHERE child_id = v_req.child_id
       AND prayer = v_req.prayer
       AND prayer_date = v_req.prayer_date
  ) THEN
    RAISE EXCEPTION 'يوجد سجل حضور لهذه الصلاة مسبقاً';
  END IF;

  -- البحث عن مسابقة نشطة في تاريخ الصلاة
  SELECT id INTO v_competition_id
    FROM competitions
   WHERE mosque_id = v_req.mosque_id
     AND is_active = true
     AND start_date <= v_req.prayer_date
     AND end_date >= v_req.prayer_date
   LIMIT 1;

  -- إدراج سجل الحضور (الـ trigger يحسب النقاط ويحدّث الطفل)
  INSERT INTO attendance (
    child_id, mosque_id, recorded_by_id,
    prayer, location_type, prayer_date, competition_id
  ) VALUES (
    v_req.child_id, v_req.mosque_id, v_user_id,
    v_req.prayer, 'mosque', v_req.prayer_date, v_competition_id
  )
  RETURNING id INTO v_attendance_id;

  -- تحديث الطلب
  UPDATE correction_requests SET
    status      = 'approved',
    reviewed_by = v_user_id,
    reviewed_at = now()
  WHERE id = p_request_id;

  RETURN v_attendance_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
