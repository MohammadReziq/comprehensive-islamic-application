-- ═══════════════════════════════════════════════════════════════════════════════
-- حذف مستخدم وكل البيانات المرتبطة به (للاستخدام من لوحة Supabase فقط)
-- الاستخدام: استبدل 'email@example.com' ببريد المستخدم ثم نفّذ الدالة في SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.delete_user_and_all_related(target_email TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_id  UUID;
  v_user_id  UUID;
  v_mosque_ids UUID[];
  v_result   JSONB := '{}'::JSONB;
BEGIN
  -- 1) الحصول على auth_id و user_id من البريد (من auth.users و public.users)
  SELECT au.id, u.id INTO v_auth_id, v_user_id
  FROM auth.users au
  LEFT JOIN public.users u ON u.auth_id = au.id
  WHERE au.email = target_email;

  IF v_auth_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'المستخدم غير موجود في auth.users');
  END IF;

  IF v_user_id IS NULL THEN
    -- المستخدم موجود في auth لكن لا سجل في users (نادر) — نحذف من auth فقط
    DELETE FROM auth.users WHERE id = v_auth_id;
    RETURN jsonb_build_object('ok', true, 'message', 'تم حذف المستخدم من المصادقة فقط (لا سجل في users)');
  END IF;

  -- 2) قراءة المساجد التي يملكها (قبل حذف أي شيء)
  SELECT ARRAY_AGG(id) INTO v_mosque_ids FROM public.mosques WHERE owner_id = v_user_id;
  IF v_mosque_ids IS NULL THEN v_mosque_ids := ARRAY[]::UUID[]; END IF;

  -- 3) ترتيب الحذف حسب الاعتماديات (من الأقل إلى الأكثر حساسية)

  -- سجلات قراءة الإعلانات
  DELETE FROM public.announcement_reads WHERE user_id = v_user_id;

  -- ملاحظات أرسلها هذا المستخدم
  DELETE FROM public.notes WHERE sender_id = v_user_id;

  -- إعلانات أنشأها هذا المستخدم (لأي مسجد)
  DELETE FROM public.announcements WHERE sender_id = v_user_id;

  -- طلبات التصحيح: نحرر reviewed_by ثم نحذف طلبات ولي الأمر
  UPDATE public.correction_requests SET reviewed_by = NULL WHERE reviewed_by = v_user_id;
  DELETE FROM public.correction_requests WHERE parent_id = v_user_id;

  -- مساجد يملكها: تحرير الحضور من mosque_id ثم حذف طلبات التصحيح للمسجد ثم حذف المسجد (يتسلسل مع الأعضاء والأطفال والإعلانات والمسابقات)
  IF COALESCE(array_length(v_mosque_ids, 1), 0) > 0 THEN
    UPDATE public.attendance SET mosque_id = NULL WHERE mosque_id = ANY(v_mosque_ids);
    DELETE FROM public.correction_requests WHERE mosque_id = ANY(v_mosque_ids);
    DELETE FROM public.mosques WHERE owner_id = v_user_id;
  END IF;

  -- حضور سجّله هذا المستخدم (مشرف)
  DELETE FROM public.attendance WHERE recorded_by_id = v_user_id;

  -- مكافآت أنشأها ولي الأمر
  DELETE FROM public.rewards WHERE parent_id = v_user_id;

  -- طلبات انضمام للمسجد
  DELETE FROM public.mosque_join_requests WHERE user_id = v_user_id;

  -- أعضاء المساجد (حتى لو لم يكن مالك)
  DELETE FROM public.mosque_members WHERE user_id = v_user_id;

  -- الأبناء (يتسلسل: mosque_children، attendance، badges، correction_requests، notes المرتبطة بالأبناء)
  DELETE FROM public.children WHERE parent_id = v_user_id;

  -- سجل المستخدم في public.users
  DELETE FROM public.users WHERE id = v_user_id;

  -- المستخدم من المصادقة
  DELETE FROM auth.users WHERE id = v_auth_id;

  RETURN jsonb_build_object('ok', true, 'message', 'تم حذف المستخدم وجميع البيانات المرتبطة به');
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('ok', false, 'error', SQLERRM);
END;
$$;

COMMENT ON FUNCTION public.delete_user_and_all_related(TEXT) IS
  'حذف مستخدم (بالبريد) من auth.users و public.users وجميع الجداول المرتبطة. للاستخدام من لوحة Supabase فقط.';

-- ═══════════════════════════════════════════════════════════════════════════════
-- مثال استدعاء (استبدل البريد ثم نفّذ):
-- SELECT public.delete_user_and_all_related('moereziq1423@gmail.com');
-- ═══════════════════════════════════════════════════════════════════════════════
