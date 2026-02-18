-- 026: إعلانات المسجد — RLS محدّث (الجدول موجود من 001 بـ sender_id)
-- الإمام (owner) فقط ينشئ إعلانات؛ الأعضاء وأولياء الأمور يقرأون
-- ملاحظة: الجدول announcements في 001 فيه sender_id (مرجع users.id) وليس created_by

-- أعمدة إضافية إن وُجدت في التصميم الجديد
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

-- Index للبحث السريع حسب المسجد
CREATE INDEX IF NOT EXISTS idx_announcements_mosque_id ON announcements(mosque_id);

-- RLS (مفعّل مسبقاً من 001)
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- إسقاط السياسات القديمة لاستبدالها
DROP POLICY IF EXISTS "Announcements: read mosque announcements" ON announcements;
DROP POLICY IF EXISTS "Announcements: supervisor creates" ON announcements;
DROP POLICY IF EXISTS "Announcements: mosque member creates" ON announcements;
DROP POLICY IF EXISTS "Announcements: sender or owner updates" ON announcements;
DROP POLICY IF EXISTS "Announcements: sender or owner deletes" ON announcements;

-- القراءة: أعضاء المسجد + أولياء الأمور (أطفالهم في المسجد) يقرأون إعلانات المسجد
CREATE POLICY "mosque_members_read_announcements"
  ON announcements FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM mosque_members mm
      JOIN users u ON u.id = mm.user_id
      WHERE mm.mosque_id = announcements.mosque_id AND u.auth_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM mosque_children mc
      JOIN children c ON c.id = mc.child_id
      JOIN users u ON u.id = c.parent_id
      WHERE mc.mosque_id = announcements.mosque_id AND u.auth_id = auth.uid()
    )
  );

-- الإنشاء: فقط الإمام (owner) ينشئ إعلانات، و sender_id = المستخدم الحالي
CREATE POLICY "imam_insert_announcements"
  ON announcements FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM mosque_members mm
      JOIN users u ON u.id = mm.user_id
      WHERE mm.mosque_id = mosque_id AND u.auth_id = auth.uid() AND mm.role = 'owner'
    )
    AND sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- التعديل: فقط من أنشأ الإعلان (sender_id = المستخدم الحالي)
CREATE POLICY "creator_update_announcements"
  ON announcements FOR UPDATE
  USING (sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid()))
  WITH CHECK (sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- الحذف: فقط من أنشأ الإعلان
CREATE POLICY "creator_delete_announcements"
  ON announcements FOR DELETE
  USING (sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Realtime: إضافة الجدول للنشر إن لم يكن مضافاً
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'announcements'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE announcements;
  END IF;
END $$;
