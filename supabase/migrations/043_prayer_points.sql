-- [043] إضافة prayer_points لجدول competitions
-- migration 029 تتحكم بنقاط attendance من mosques.prayer_config
-- هذا الحقل للمسابقات: كم نقطة لكل صلاة في المسابقة تحديداً

ALTER TABLE competitions
ADD COLUMN IF NOT EXISTS prayer_points JSONB DEFAULT '{
  "fajr": 10,
  "dhuhr": 10,
  "asr": 10,
  "maghrib": 10,
  "isha": 10
}'::jsonb;

-- تحديث المسابقات الحالية التي لا تملك القيمة
UPDATE competitions
SET prayer_points = '{
  "fajr": 10,
  "dhuhr": 10,
  "asr": 10,
  "maghrib": 10,
  "isha": 10
}'::jsonb
WHERE prayer_points IS NULL;
