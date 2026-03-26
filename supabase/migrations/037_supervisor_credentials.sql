-- ═══════════════════════════════════════
-- Migration 037: supervisor_credentials
-- جدول لحفظ بيانات دخول المشرفين (مشفرة)
-- ═══════════════════════════════════════

CREATE TABLE IF NOT EXISTS supervisor_credentials (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mosque_id UUID NOT NULL REFERENCES mosques(id) ON DELETE CASCADE,
  encrypted_password TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, mosque_id)
);

-- فهرس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_supervisor_credentials_mosque
  ON supervisor_credentials(mosque_id);

-- تفعيل RLS
ALTER TABLE supervisor_credentials ENABLE ROW LEVEL SECURITY;

-- الإمام (owner) في نفس المسجد يقدر يقرأ بيانات مشرفيه
CREATE POLICY "imam_reads_own_mosque_credentials"
ON supervisor_credentials FOR SELECT
USING (
  mosque_id IN (
    SELECT m.id FROM mosques m
    JOIN users u ON u.id = m.owner_id
    WHERE u.auth_id = auth.uid()
  )
);

-- الإمام يقدر يضيف بيانات
CREATE POLICY "imam_inserts_credentials"
ON supervisor_credentials FOR INSERT
WITH CHECK (
  mosque_id IN (
    SELECT m.id FROM mosques m
    JOIN users u ON u.id = m.owner_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Super Admin يقرأ الكل
CREATE POLICY "superadmin_reads_all_credentials"
ON supervisor_credentials FOR SELECT
USING (
  EXISTS (SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'super_admin')
);
