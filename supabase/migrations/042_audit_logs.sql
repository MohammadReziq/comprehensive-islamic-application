-- [042] جدول تسجيل العمليات الحساسة (Audit Trail)
-- يُكتب فقط من Edge Functions عبر service_role

CREATE TABLE IF NOT EXISTS audit_logs (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  action         TEXT NOT NULL,        -- 'create_imam_account', 'create_supervisor_account'
  performed_by   UUID REFERENCES public.users(id) ON DELETE SET NULL,
  target_user_id UUID,                 -- المستخدم الذي تم إنشاؤه/تعديله
  details        JSONB,               -- { email, name, mosque_id }
  created_at     TIMESTAMPTZ DEFAULT now()
);

-- فهارس لتسريع البحث
CREATE INDEX IF NOT EXISTS idx_audit_logs_action
  ON audit_logs(action, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_performer
  ON audit_logs(performed_by, created_at DESC);

-- RLS
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- السوبر أدمن فقط يقرأ
CREATE POLICY "superadmin_reads_audit_logs"
ON audit_logs FOR SELECT
USING (
  EXISTS (SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'super_admin')
);

-- لا أحد يكتب مباشرة — service_role فقط (عبر Edge Functions)
CREATE POLICY "no_direct_insert_audit"
ON audit_logs FOR INSERT
WITH CHECK (false);
