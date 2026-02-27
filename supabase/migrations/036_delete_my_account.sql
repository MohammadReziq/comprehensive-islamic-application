-- ═══════════════════════════════════════════════════════════════════════════════
-- حذف حساب ولي الأمر الحالي وكل البيانات المرتبطة به (self-service)
-- يستخدم auth.uid() — لا يقبل أي مدخلات من المستخدم
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_id    UUID;
  v_user_id    UUID;
  v_mosque_ids UUID[];
BEGIN
  v_auth_id := auth.uid();
  IF v_auth_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'غير مسجل دخول');
  END IF;

  SELECT id INTO v_user_id FROM public.users WHERE auth_id = v_auth_id;

  IF v_user_id IS NULL THEN
    -- لا سجل في public.users — نحذف من auth فقط
    DELETE FROM auth.users WHERE id = v_auth_id;
    RETURN jsonb_build_object('ok', true);
  END IF;

  -- المساجد التي يملكها (إمام)
  SELECT ARRAY_AGG(id) INTO v_mosque_ids FROM public.mosques WHERE owner_id = v_user_id;
  IF v_mosque_ids IS NULL THEN v_mosque_ids := ARRAY[]::UUID[]; END IF;

  -- سجلات قراءة الإعلانات
  DELETE FROM public.announcement_reads WHERE user_id = v_user_id;

  -- ملاحظات أرسلها
  DELETE FROM public.notes WHERE sender_id = v_user_id;

  -- إعلانات أنشأها
  DELETE FROM public.announcements WHERE sender_id = v_user_id;

  -- طلبات التصحيح
  UPDATE public.correction_requests SET reviewed_by = NULL WHERE reviewed_by = v_user_id;
  DELETE FROM public.correction_requests WHERE parent_id = v_user_id;

  -- المساجد التي يملكها (مع بياناتها المرتبطة عبر CASCADE)
  IF COALESCE(array_length(v_mosque_ids, 1), 0) > 0 THEN
    UPDATE public.attendance SET mosque_id = NULL WHERE mosque_id = ANY(v_mosque_ids);
    DELETE FROM public.correction_requests WHERE mosque_id = ANY(v_mosque_ids);
    DELETE FROM public.mosques WHERE owner_id = v_user_id;
  END IF;

  -- حضور سجّله كمشرف
  DELETE FROM public.attendance WHERE recorded_by_id = v_user_id;

  -- المكافآت
  DELETE FROM public.rewards WHERE parent_id = v_user_id;

  -- طلبات الانضمام
  DELETE FROM public.mosque_join_requests WHERE user_id = v_user_id;

  -- عضويات المساجد
  DELETE FROM public.mosque_members WHERE user_id = v_user_id;

  -- الأبناء (يتسلسل: mosque_children، attendance، badges، correction_requests، notes)
  DELETE FROM public.children WHERE parent_id = v_user_id;

  -- سجل المستخدم
  DELETE FROM public.users WHERE id = v_user_id;

  -- حذف من المصادقة
  DELETE FROM auth.users WHERE id = v_auth_id;

  RETURN jsonb_build_object('ok', true);
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('ok', false, 'error', SQLERRM);
END;
$$;

COMMENT ON FUNCTION public.delete_my_account() IS
  'حذف الحساب الحالي (auth.uid) وجميع البيانات المرتبطة به. يُستدعى من تطبيق Flutter.';