-- إرجاع المشرفين وطلبات الانضمام مع الأسماء عبر دوال SECURITY DEFINER
-- الدوال تقرأ من users بصلاحيات المالك فـ RLS لا يُطبَّق → لا recursion، وتسجيل الدخول يبقى سليماً
--
-- التشغيل: Supabase → SQL Editor → الصق المحتوى → Run
--

-- مشرفو مسجد مع أسمائهم (للمالك فقط)
CREATE OR REPLACE FUNCTION public.get_mosque_supervisors_with_names(p_mosque_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_is_owner boolean;
BEGIN
  SELECT id INTO v_user_id FROM public.users WHERE auth_id = auth.uid() LIMIT 1;
  IF v_user_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM mosques m WHERE m.id = p_mosque_id AND m.owner_id = v_user_id
  ) OR EXISTS (
    SELECT 1 FROM mosque_members mm
    WHERE mm.mosque_id = p_mosque_id AND mm.user_id = v_user_id AND mm.role = 'owner'
  ) INTO v_is_owner;

  IF NOT v_is_owner THEN
    RETURN '[]'::jsonb;
  END IF;

  RETURN COALESCE(
    (SELECT jsonb_agg(
       jsonb_build_object(
         'id', mm.id,
         'mosque_id', mm.mosque_id,
         'user_id', mm.user_id,
         'role', mm.role,
         'joined_at', mm.joined_at,
         'users', jsonb_build_object('name', u.name, 'email', u.email)
       ) ORDER BY mm.joined_at DESC
     )
     FROM mosque_members mm
     JOIN users u ON u.id = mm.user_id
     WHERE mm.mosque_id = p_mosque_id AND mm.role = 'supervisor'),
    '[]'::jsonb
  );
END;
$$;

-- طلبات الانضمام المعلقة مع أسماء الطالبين (للمالك فقط)
CREATE OR REPLACE FUNCTION public.get_pending_join_requests_with_names(p_mosque_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_is_owner boolean;
BEGIN
  SELECT id INTO v_user_id FROM public.users WHERE auth_id = auth.uid() LIMIT 1;
  IF v_user_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM mosques m WHERE m.id = p_mosque_id AND m.owner_id = v_user_id
  ) OR EXISTS (
    SELECT 1 FROM mosque_members mm
    WHERE mm.mosque_id = p_mosque_id AND mm.user_id = v_user_id AND mm.role = 'owner'
  ) INTO v_is_owner;

  IF NOT v_is_owner THEN
    RETURN '[]'::jsonb;
  END IF;

  RETURN COALESCE(
    (SELECT jsonb_agg(
       jsonb_build_object(
         'id', mjr.id,
         'mosque_id', mjr.mosque_id,
         'user_id', mjr.user_id,
         'status', mjr.status,
         'requested_at', mjr.requested_at,
         'users', jsonb_build_object('name', u.name, 'email', u.email)
       ) ORDER BY mjr.requested_at DESC
     )
     FROM mosque_join_requests mjr
     JOIN users u ON u.id = mjr.user_id
     WHERE mjr.mosque_id = p_mosque_id AND mjr.status = 'pending'),
    '[]'::jsonb
  );
END;
$$;

-- منح الصلاحية لاستدعاء الدوال من التطبيق (دور authenticated)
GRANT EXECUTE ON FUNCTION public.get_mosque_supervisors_with_names(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_mosque_supervisors_with_names(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_pending_join_requests_with_names(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_join_requests_with_names(uuid) TO service_role;
