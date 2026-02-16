-- ═══════════════════════════════════════
-- إصلاح Trigger إنشاء المستخدم (Email + Google)
-- يحل: Database error عند saving new user
-- ═══════════════════════════════════════

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

  -- الاسم: من metadata أو من auth
  user_name := COALESCE(
    NULLIF(TRIM(meta->>'full_name'), ''),
    NULLIF(TRIM(meta->>'name'), ''),
    NULLIF(TRIM(meta->>'given_name'), ''),
    'مستخدم جديد'
  );

  -- البريد
  user_email := COALESCE(
    NEW.email,
    NULLIF(TRIM(meta->>'email'), '')
  );

  -- الدور: فقط قيم الـ enum وإلا parent
  CASE NULLIF(TRIM(meta->>'role'), '')
    WHEN 'super_admin' THEN user_role_val := 'super_admin'::user_role;
    WHEN 'imam'         THEN user_role_val := 'imam'::user_role;
    ELSE user_role_val := 'parent'::user_role;
  END CASE;

  -- إدراج أو تحديث (لو المستخدم وُجد من محاولة سابقة)
  INSERT INTO public.users (auth_id, name, email, role)
  VALUES (NEW.id, user_name, user_email, user_role_val)
  ON CONFLICT (auth_id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role;

  RETURN NEW;
END;
$$;

-- التأكد أن الـ Trigger ما زال مربوطاً
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
