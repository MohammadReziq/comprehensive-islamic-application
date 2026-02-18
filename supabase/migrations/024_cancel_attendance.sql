-- 024: إلغاء حضور خاطئ
-- RPC يسمح للمشرف بإلغاء حضور سجّله بنفسه (خلال 24 ساعة)
-- أو للإمام (owner) بإلغاء أي حضور في مسجده بدون قيد زمني
-- ملاحظة: الدالة كانت في 023 بـ RETURNS VOID؛ نُسقطها ثم نُنشئ نسخة جديدة RETURNS TEXT

-- انت غل\تن اضرطيت أضيف هذا السطر 
-- باختصار تقدر تقول: "الدالة cancel_attendance كانت في 023 بـ RETURNS VOID، والـ 024 غيّرها لـ RETURNS TEXT فـ PostgreSQL رفض. أضفت في أول 024 سطر DROP FUNCTION IF EXISTS cancel_attendance(UUID); قبل الـ CREATE فصارت تشتغل. لو حابب نلتزم بهذا الأسلوب (DROP ثم CREATE) كل ما نغيّر نوع إرجاع دالة."
DROP FUNCTION IF EXISTS cancel_attendance(UUID);

CREATE OR REPLACE FUNCTION cancel_attendance(p_attendance_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_attendance RECORD;
  v_caller_id UUID := auth.uid();
  v_caller_role TEXT;
  v_hours_since NUMERIC;
BEGIN
  -- 1. جلب سجل الحضور
  SELECT a.*, m.id as mosque_id_ref
  INTO v_attendance
  FROM attendance a
  JOIN mosques m ON m.id = a.mosque_id
  WHERE a.id = p_attendance_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'سجل الحضور غير موجود';
  END IF;

  -- 2. تحقق من دور المستدعي في المسجد
  SELECT role INTO v_caller_role
  FROM mosque_members
  WHERE mosque_id = v_attendance.mosque_id
    AND user_id = v_caller_id;

  IF v_caller_role IS NULL THEN
    RAISE EXCEPTION 'ليس لديك صلاحية في هذا المسجد';
  END IF;

  -- 3. تحقق من الصلاحيات والنافذة الزمنية
  v_hours_since := EXTRACT(EPOCH FROM (NOW() - v_attendance.recorded_at)) / 3600;

  IF v_caller_role = 'owner' THEN
    -- الإمام يمكنه الإلغاء بدون قيد زمني
    NULL;
  ELSIF v_attendance.recorded_by_id = v_caller_id THEN
    -- المشرف يمكنه فقط إلغاء ما سجّله بنفسه خلال 24 ساعة
    IF v_hours_since > 24 THEN
      RAISE EXCEPTION 'انتهت مهلة الإلغاء (24 ساعة)';
    END IF;
  ELSE
    RAISE EXCEPTION 'لا يمكنك إلغاء حضور لم تسجّله بنفسك';
  END IF;

  -- 4. حذف السجل (trigger 020 سيعيد حساب النقاط والسلسلة)
  DELETE FROM attendance WHERE id = p_attendance_id;

  RETURN 'تم إلغاء الحضور بنجاح';
END;
$$;
