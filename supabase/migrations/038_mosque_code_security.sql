-- [C8+C9] أمان كود المسجد
-- كود عشوائي 6 أحرف + حماية Brute Force

-- ═══════════════════════════════════════════════════════════
-- 1. إضافة حقل invite_code إلى mosques لو مش موجود
-- ═══════════════════════════════════════════════════════════

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'mosques' AND column_name = 'invite_code'
  ) THEN
    ALTER TABLE mosques ADD COLUMN invite_code TEXT UNIQUE;
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════
-- 2. Function لتوليد كود عشوائي 6 أحرف (أرقام + أحرف كبيرة)
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION generate_mosque_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INT;
  new_code TEXT;
  code_exists BOOLEAN;
BEGIN
  LOOP
    result := '';
    FOR i IN 1..6 LOOP
      result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    new_code := result;

    SELECT EXISTS(SELECT 1 FROM mosques WHERE invite_code = new_code) INTO code_exists;
    IF NOT code_exists THEN
      RETURN new_code;
    END IF;
  END LOOP;
END;
$$;

-- ═══════════════════════════════════════════════════════════
-- 3. ملء الأكواد للمساجد الحالية اللي ما عندها كود
-- ═══════════════════════════════════════════════════════════

UPDATE mosques
SET invite_code = generate_mosque_code()
WHERE invite_code IS NULL;

-- الآن نجعل الحقل NOT NULL
ALTER TABLE mosques ALTER COLUMN invite_code SET NOT NULL;

-- ═══════════════════════════════════════════════════════════
-- 4. Trigger لتوليد الكود تلقائياً عند إنشاء مسجد جديد
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION set_mosque_invite_code()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
    NEW.invite_code := generate_mosque_code();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_mosque_invite_code ON mosques;
CREATE TRIGGER trg_set_mosque_invite_code
  BEFORE INSERT ON mosques
  FOR EACH ROW
  EXECUTE FUNCTION set_mosque_invite_code();

-- ═══════════════════════════════════════════════════════════
-- 5. جدول brute force protection
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS mosque_code_attempts (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ip_hash    TEXT NOT NULL,
  user_id    UUID,
  attempted_at TIMESTAMPTZ DEFAULT now(),
  was_correct BOOLEAN DEFAULT FALSE
);

-- فهرس لتسريع البحث بالزمن
CREATE INDEX IF NOT EXISTS idx_code_attempts_ip_time
  ON mosque_code_attempts (ip_hash, attempted_at DESC);

CREATE INDEX IF NOT EXISTS idx_code_attempts_user_time
  ON mosque_code_attempts (user_id, attempted_at DESC)
  WHERE user_id IS NOT NULL;

-- RLS
ALTER TABLE mosque_code_attempts ENABLE ROW LEVEL SECURITY;

-- فقط Edge Functions (service_role) يمكنها الكتابة والقراءة
-- لا نريد أحد يقرأ أو يكتب مباشرة
CREATE POLICY "service_only_insert"
  ON mosque_code_attempts FOR INSERT
  WITH CHECK (false);

CREATE POLICY "service_only_select"
  ON mosque_code_attempts FOR SELECT
  USING (false);
