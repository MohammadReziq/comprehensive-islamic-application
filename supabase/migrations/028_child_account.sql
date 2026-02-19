-- ═══════════════════════════════════════════════════════════════╗
-- ║  028 — حساب الابن: دور child، ربط children.login_user_id   ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 1) إضافة دور child إلى user_role (آمن عند إعادة التشغيل)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'user_role' AND e.enumlabel = 'child'
  ) THEN
    ALTER TYPE user_role ADD VALUE 'child';
  END IF;
END
$$;

-- 2) عمود ربط الطفل بحساب الدخول
ALTER TABLE children ADD COLUMN IF NOT EXISTS login_user_id UUID REFERENCES users(id) ON DELETE SET NULL;

-- 3) RLS: الابن يقرأ صف الطفل المرتبط بحسابه فقط
CREATE POLICY "Children: child reads own"
  ON children FOR SELECT
  USING (
    login_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- 4) تحديث handle_new_user ليدعم role = 'child' من raw_user_meta_data
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_name TEXT;
  user_email TEXT;
  user_role_val user_role;
  meta JSONB;
BEGIN
  meta := COALESCE(NEW.raw_user_meta_data, '{}'::jsonb);

  user_name := COALESCE(
    NULLIF(TRIM(meta->>'full_name'), ''),
    NULLIF(TRIM(meta->>'name'), ''),
    NULLIF(TRIM(meta->>'given_name'), ''),
    'مستخدم جديد'
  );

  user_email := COALESCE(
    NEW.email,
    NULLIF(TRIM(meta->>'email'), '')
  );

  CASE NULLIF(TRIM(meta->>'role'), '')
    WHEN 'super_admin' THEN user_role_val := 'super_admin'::user_role;
    WHEN 'imam'         THEN user_role_val := 'imam'::user_role;
    WHEN 'supervisor'   THEN user_role_val := 'supervisor'::user_role;
    WHEN 'child'        THEN user_role_val := 'child'::user_role;
    ELSE user_role_val := 'parent'::user_role;
  END CASE;

  INSERT INTO public.users (auth_id, name, email, role)
  VALUES (NEW.id, user_name, user_email, user_role_val)
  ON CONFLICT (auth_id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role;

  RETURN NEW;
END;
$$;

-- 5) حماية عمود login_user_id: فقط service_role يحدّثه
CREATE OR REPLACE FUNCTION public.trg_protect_children_login_user_id()
RETURNS TRIGGER AS $$
BEGIN
  IF current_setting('request.jwt.claims', true)::jsonb->>'role' != 'service_role' THEN
    NEW.login_user_id := OLD.login_user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS protect_children_login_user_id_trigger ON children;
CREATE TRIGGER protect_children_login_user_id_trigger
  BEFORE UPDATE ON children
  FOR EACH ROW
  WHEN (OLD.login_user_id IS DISTINCT FROM NEW.login_user_id)
  EXECUTE FUNCTION public.trg_protect_children_login_user_id();

-- 6) RLS: الابن يرى حضوره فقط (السجلات التي child_id = الطفل المرتبط بحسابه)
CREATE POLICY "Attendance: child reads own"
  ON attendance FOR SELECT
  USING (
    child_id IN (
      SELECT id FROM children
      WHERE login_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    )
  );

-- 7) RLS: الابن يرى ملاحظاته فقط (الملاحظات عن الطفل المرتبط بحسابه)
CREATE POLICY "Notes: child reads own"
  ON notes FOR SELECT
  USING (
    child_id IN (
      SELECT id FROM children
      WHERE login_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    )
  );
