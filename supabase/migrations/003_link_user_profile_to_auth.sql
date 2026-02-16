-- ═══════════════════════════════════════════════════════════════════
-- ربط صف جدول users بحساب المصادقة الحالي (نفس الإيميل)
-- يحل: "لم يتم العثور على بيانات المستخدم" عندما السجل موجود لكن auth_id غير مطابق
--
-- التشغيل: Supabase Dashboard → SQL Editor → انسخ كل المحتوى → Run
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.link_user_profile_to_auth()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  u_email text;
  u_id    uuid;
BEGIN
  u_id := auth.uid();
  IF u_id IS NULL THEN RETURN; END IF;

  SELECT LOWER(TRIM(email)) INTO u_email FROM auth.users WHERE id = u_id;
  IF u_email IS NULL OR u_email = '' THEN RETURN; END IF;

  -- (1) تحرير أي صف مرتبط حالياً بهذا الحساب حتى لا نخرق UNIQUE على auth_id
  UPDATE public.users SET auth_id = NULL WHERE auth_id = u_id;

  -- (2) ربط الصف الذي يحمل نفس الإيميل بحساب المصادقة الحالي
  UPDATE public.users
  SET auth_id = u_id
  WHERE LOWER(TRIM(email)) = u_email;
END;
$$;

COMMENT ON FUNCTION public.link_user_profile_to_auth() IS
  'Links the users row with matching email to the current auth user. Call from app when profile is missing after login.';
