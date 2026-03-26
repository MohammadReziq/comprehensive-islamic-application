-- ═══════════════════════════════════════════════════════════════════════════════
-- Migration 039: Fix Delete Cascades
-- تسمح هذه الـ migration بحذف المستخدمين من لوحة Supabase مباشرة
-- عبر إضافة ON DELETE CASCADE للقيود التي كانت تمنع ذلك.
-- ═══════════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
  -- 1) المساجد (mosques): إذا حُذف المالك، يُحذف المسجد (يتسلسل للأعضاء والمسابقات)
  ALTER TABLE public.mosques DROP CONSTRAINT IF EXISTS mosques_owner_id_fkey;
  ALTER TABLE public.mosques ADD CONSTRAINT mosques_owner_id_fkey 
    FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;

  -- 2) الحضور (attendance):
  -- إذا حُذف المشرف (recorded_by_id) يُحذف السجل أو يبقى؟ يفضل الحذف لتنظيف البيانات
  ALTER TABLE public.attendance DROP CONSTRAINT IF EXISTS attendance_recorded_by_id_fkey;
  ALTER TABLE public.attendance ADD CONSTRAINT attendance_recorded_by_id_fkey 
    FOREIGN KEY (recorded_by_id) REFERENCES public.users(id) ON DELETE CASCADE;

  -- إذا حُذف المسجد، يبقى سجل الحضور لكن mosque_id يصبح null (حضور منزلي أو مسجد محذوف)
  ALTER TABLE public.attendance DROP CONSTRAINT IF EXISTS attendance_mosque_id_fkey;
  ALTER TABLE public.attendance ADD CONSTRAINT attendance_mosque_id_fkey 
    FOREIGN KEY (mosque_id) REFERENCES public.mosques(id) ON DELETE SET NULL;

  -- 3) الجوائز (rewards)
  ALTER TABLE public.rewards DROP CONSTRAINT IF EXISTS rewards_parent_id_fkey;
  ALTER TABLE public.rewards ADD CONSTRAINT rewards_parent_id_fkey 
    FOREIGN KEY (parent_id) REFERENCES public.users(id) ON DELETE CASCADE;

  -- 4) طلبات التصحيح (correction_requests)
  ALTER TABLE public.correction_requests DROP CONSTRAINT IF EXISTS correction_requests_parent_id_fkey;
  ALTER TABLE public.correction_requests ADD CONSTRAINT correction_requests_parent_id_fkey 
    FOREIGN KEY (parent_id) REFERENCES public.users(id) ON DELETE CASCADE;

  ALTER TABLE public.correction_requests DROP CONSTRAINT IF EXISTS correction_requests_mosque_id_fkey;
  ALTER TABLE public.correction_requests ADD CONSTRAINT correction_requests_mosque_id_fkey 
    FOREIGN KEY (mosque_id) REFERENCES public.mosques(id) ON DELETE CASCADE;

  ALTER TABLE public.correction_requests DROP CONSTRAINT IF EXISTS correction_requests_reviewed_by_fkey;
  ALTER TABLE public.correction_requests ADD CONSTRAINT correction_requests_reviewed_by_fkey 
    FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL;

  -- 5) الملاحظات (notes)
  ALTER TABLE public.notes DROP CONSTRAINT IF EXISTS notes_sender_id_fkey;
  ALTER TABLE public.notes ADD CONSTRAINT notes_sender_id_fkey 
    FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;

  ALTER TABLE public.notes DROP CONSTRAINT IF EXISTS notes_mosque_id_fkey;
  ALTER TABLE public.notes ADD CONSTRAINT notes_mosque_id_fkey 
    FOREIGN KEY (mosque_id) REFERENCES public.mosques(id) ON DELETE CASCADE;

  -- 6) الإعلانات (announcements)
  ALTER TABLE public.announcements DROP CONSTRAINT IF EXISTS announcements_sender_id_fkey;
  ALTER TABLE public.announcements ADD CONSTRAINT announcements_sender_id_fkey 
    FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;

  -- 7) المسابقات (competitions)
  ALTER TABLE public.competitions DROP CONSTRAINT IF EXISTS competitions_created_by_fkey;
  ALTER TABLE public.competitions ADD CONSTRAINT competitions_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;

  -- 8) قراءات الإعلانات (announcement_reads)
  ALTER TABLE public.announcement_reads DROP CONSTRAINT IF EXISTS announcement_reads_user_id_fkey;
  ALTER TABLE public.announcement_reads ADD CONSTRAINT announcement_reads_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

END $$;
