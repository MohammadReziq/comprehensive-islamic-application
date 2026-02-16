-- ═══════════════════════════════════════════════════════════════════
-- تحويل حساب إلى مدير نظام (سوبر أدمن)
-- غيّر الإيميل في السطر الأخير ثم شغّل الاستعلام في Supabase → SQL Editor
-- ═══════════════════════════════════════════════════════════════════

UPDATE public.users
SET role = 'super_admin'
WHERE email = 'moe.reziq.dev@gmail.com';  -- غيّر الإيميل هنا

-- للتأكد: اعرض الصف بعد التحديث
-- SELECT id, name, email, role FROM public.users WHERE email = 'moe.reziq.dev@gmail.com';
