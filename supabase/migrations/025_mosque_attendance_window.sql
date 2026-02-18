-- 025: إضافة نافذة وقت الحضور لكل مسجد
-- يسمح للإمام بتعديل المدة المسموح بها لتسجيل الحضور بعد الأذان

ALTER TABLE mosques
ADD COLUMN IF NOT EXISTS attendance_window_minutes INT DEFAULT 60;

-- التأكد من أن lat و lng موجودان (تمت إضافتهما سابقاً لكن نتأكد)
-- ALTER TABLE mosques ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION;
-- ALTER TABLE mosques ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION;

COMMENT ON COLUMN mosques.attendance_window_minutes IS 'المدة المسموح بها بالدقائق لتسجيل الحضور بعد الأذان (افتراضي 60)';
