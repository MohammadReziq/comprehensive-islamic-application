-- 031: جدول رموز تفعيل البريد عند التسجيل (للاستخدام مع Edge Functions)
-- يُنشئ الرمز دالة send-signup-verification-code ويُتحقق منه عبر verify-signup-code

CREATE TABLE IF NOT EXISTS email_verification_codes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email      TEXT NOT NULL,
  code       TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_email_verification_codes_email ON email_verification_codes(email);
CREATE INDEX IF NOT EXISTS idx_email_verification_codes_expires ON email_verification_codes(expires_at);

COMMENT ON TABLE email_verification_codes IS 'رموز OTP لتفعيل البريد عند إنشاء حساب جديد — تُحذف بعد الاستخدام أو انتهاء الصلاحية';
