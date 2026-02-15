-- ╔══════════════════════════════════════════════════════════╗
-- ║  صلاتي حياتي - Supabase Database Schema v1.0          ║
-- ║  تنفيذ: انسخ هذا الملف → Supabase Dashboard → SQL Editor ║
-- ╚══════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════
-- 1. Custom Enums
-- ═══════════════════════════════════════

CREATE TYPE user_role AS ENUM ('super_admin', 'parent', 'imam');
CREATE TYPE prayer AS ENUM ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha');
CREATE TYPE location_type AS ENUM ('mosque', 'home');
CREATE TYPE mosque_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE mosque_role AS ENUM ('owner', 'supervisor');
CREATE TYPE mosque_type AS ENUM ('primary', 'secondary');
CREATE TYPE correction_status AS ENUM ('pending', 'approved', 'rejected');

-- ═══════════════════════════════════════
-- 2. Helper Function - Auto UUID
-- ═══════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ═══════════════════════════════════════
-- 3. Tables
-- ═══════════════════════════════════════

-- ─── Users ───
CREATE TABLE users (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id     UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  email       TEXT UNIQUE,
  phone       TEXT UNIQUE,
  role        user_role NOT NULL DEFAULT 'parent',
  avatar_url  TEXT,
  fcm_token   TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── Children ───
CREATE TABLE children (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  age             INT NOT NULL CHECK (age > 0 AND age < 20),
  qr_code         TEXT UNIQUE NOT NULL DEFAULT uuid_generate_v4()::TEXT,
  avatar_url      TEXT,
  total_points    INT NOT NULL DEFAULT 0,
  current_streak  INT NOT NULL DEFAULT 0,
  best_streak     INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── Mosques ───
CREATE TABLE mosques (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id      UUID NOT NULL REFERENCES users(id),
  name          TEXT NOT NULL,
  code          TEXT UNIQUE NOT NULL,
  invite_code   TEXT UNIQUE NOT NULL,
  address       TEXT,
  lat           DOUBLE PRECISION,
  lng           DOUBLE PRECISION,
  status        mosque_status NOT NULL DEFAULT 'pending',
  prayer_config JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── Mosque Members (المشرفون) ───
CREATE TABLE mosque_members (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id   UUID NOT NULL REFERENCES mosques(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role        mosque_role NOT NULL DEFAULT 'supervisor',
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(mosque_id, user_id)
);

-- ─── Mosque Children (ربط الأطفال بالمساجد) ───
CREATE TABLE mosque_children (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id     UUID NOT NULL REFERENCES mosques(id) ON DELETE CASCADE,
  child_id      UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  type          mosque_type NOT NULL DEFAULT 'primary',
  local_number  INT NOT NULL,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(mosque_id, child_id)
);

-- ─── Attendance (الحضور) ───
CREATE TABLE attendance (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id        UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  mosque_id       UUID REFERENCES mosques(id),  -- NULL = منزل
  recorded_by_id  UUID NOT NULL REFERENCES users(id),
  prayer          prayer NOT NULL,
  location_type   location_type NOT NULL,
  points_earned   INT NOT NULL DEFAULT 0,
  prayer_date     DATE NOT NULL,
  synced_offline  BOOLEAN NOT NULL DEFAULT false,
  recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(child_id, prayer, prayer_date)  -- منع التكرار
);

-- ─── Badges (الشارات) ───
CREATE TABLE badges (
  id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id  UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  type      TEXT NOT NULL,
  name_ar   TEXT NOT NULL,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── Rewards (الجوائز) ───
CREATE TABLE rewards (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id       UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  parent_id      UUID NOT NULL REFERENCES users(id),
  title          TEXT NOT NULL,
  target_points  INT NOT NULL CHECK (target_points > 0),
  is_claimed     BOOLEAN NOT NULL DEFAULT false,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── Correction Requests (طلبات التصحيح) ───
CREATE TABLE correction_requests (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id    UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  parent_id   UUID NOT NULL REFERENCES users(id),
  mosque_id   UUID NOT NULL REFERENCES mosques(id),
  prayer      prayer NOT NULL,
  prayer_date DATE NOT NULL,
  status      correction_status NOT NULL DEFAULT 'pending',
  note        TEXT,
  reviewed_by UUID REFERENCES users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

-- ─── Notes (ملاحظات المشرف) ───
CREATE TABLE notes (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id   UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  sender_id  UUID NOT NULL REFERENCES users(id),
  mosque_id  UUID NOT NULL REFERENCES mosques(id),
  message    TEXT NOT NULL,
  is_read    BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── Announcements (إعلانات المسجد) ───
CREATE TABLE announcements (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id  UUID NOT NULL REFERENCES mosques(id) ON DELETE CASCADE,
  sender_id  UUID NOT NULL REFERENCES users(id),
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════
-- 4. Indexes (لتسريع الاستعلامات)
-- ═══════════════════════════════════════

CREATE INDEX idx_children_parent ON children(parent_id);
CREATE INDEX idx_attendance_child ON attendance(child_id);
CREATE INDEX idx_attendance_date ON attendance(prayer_date);
CREATE INDEX idx_attendance_mosque ON attendance(mosque_id);
CREATE INDEX idx_mosque_members_mosque ON mosque_members(mosque_id);
CREATE INDEX idx_mosque_members_user ON mosque_members(user_id);
CREATE INDEX idx_mosque_children_mosque ON mosque_children(mosque_id);
CREATE INDEX idx_mosque_children_child ON mosque_children(child_id);
CREATE INDEX idx_corrections_child ON correction_requests(child_id);
CREATE INDEX idx_corrections_status ON correction_requests(status);
CREATE INDEX idx_notes_child ON notes(child_id);
CREATE INDEX idx_badges_child ON badges(child_id);
CREATE INDEX idx_rewards_child ON rewards(child_id);
CREATE INDEX idx_mosques_status ON mosques(status);
CREATE INDEX idx_users_auth_id ON users(auth_id);

-- ═══════════════════════════════════════
-- 5. RLS Policies (Row Level Security)
-- ═══════════════════════════════════════

-- تفعيل RLS على كل الجداول
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE children ENABLE ROW LEVEL SECURITY;
ALTER TABLE mosques ENABLE ROW LEVEL SECURITY;
ALTER TABLE mosque_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE mosque_children ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE correction_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- ─── Users Policies ───
-- المستخدم يقرأ ملفه الشخصي
CREATE POLICY "Users: read own profile"
  ON users FOR SELECT
  USING (auth.uid() = auth_id);

-- المستخدم ينشئ ملفه عند التسجيل
CREATE POLICY "Users: insert own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = auth_id);

-- المستخدم يعدّل ملفه فقط
CREATE POLICY "Users: update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = auth_id);

-- ─── Children Policies ───
-- الأب يقرأ أطفاله فقط
CREATE POLICY "Children: parent reads own"
  ON children FOR SELECT
  USING (
    parent_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- الأب يضيف أطفاله
CREATE POLICY "Children: parent inserts"
  ON children FOR INSERT
  WITH CHECK (
    parent_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- الأب يعدّل أطفاله
CREATE POLICY "Children: parent updates"
  ON children FOR UPDATE
  USING (
    parent_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- المشرفون يقرأون أطفال مسجدهم
CREATE POLICY "Children: supervisors read mosque children"
  ON children FOR SELECT
  USING (
    id IN (
      SELECT mc.child_id FROM mosque_children mc
      JOIN mosque_members mm ON mm.mosque_id = mc.mosque_id
      JOIN users u ON u.id = mm.user_id
      WHERE u.auth_id = auth.uid()
    )
  );

-- ─── Mosques Policies ───
-- الكل يقدر يقرأ المساجد المعتمدة
CREATE POLICY "Mosques: read approved"
  ON mosques FOR SELECT
  USING (status = 'approved' OR owner_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- إنشاء مسجد
CREATE POLICY "Mosques: create"
  ON mosques FOR INSERT
  WITH CHECK (
    owner_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- المالك يعدّل مسجده
CREATE POLICY "Mosques: owner updates"
  ON mosques FOR UPDATE
  USING (
    owner_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- ─── Mosque Members Policies ───
CREATE POLICY "Mosque Members: read own mosque"
  ON mosque_members FOR SELECT
  USING (
    user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    OR mosque_id IN (
      SELECT m.id FROM mosques m
      JOIN users u ON u.id = m.owner_id
      WHERE u.auth_id = auth.uid()
    )
  );

CREATE POLICY "Mosque Members: owner manages"
  ON mosque_members FOR INSERT
  WITH CHECK (
    mosque_id IN (
      SELECT m.id FROM mosques m
      JOIN users u ON u.id = m.owner_id
      WHERE u.auth_id = auth.uid()
    )
  );

CREATE POLICY "Mosque Members: owner deletes"
  ON mosque_members FOR DELETE
  USING (
    mosque_id IN (
      SELECT m.id FROM mosques m
      JOIN users u ON u.id = m.owner_id
      WHERE u.auth_id = auth.uid()
    )
  );

-- ─── Mosque Children Policies ───
CREATE POLICY "Mosque Children: read"
  ON mosque_children FOR SELECT
  USING (
    child_id IN (SELECT c.id FROM children c JOIN users u ON u.id = c.parent_id WHERE u.auth_id = auth.uid())
    OR mosque_id IN (SELECT mm.mosque_id FROM mosque_members mm JOIN users u ON u.id = mm.user_id WHERE u.auth_id = auth.uid())
  );

CREATE POLICY "Mosque Children: parent links"
  ON mosque_children FOR INSERT
  WITH CHECK (
    child_id IN (SELECT c.id FROM children c JOIN users u ON u.id = c.parent_id WHERE u.auth_id = auth.uid())
  );

-- ─── Attendance Policies ───
CREATE POLICY "Attendance: read own children"
  ON attendance FOR SELECT
  USING (
    child_id IN (SELECT c.id FROM children c JOIN users u ON u.id = c.parent_id WHERE u.auth_id = auth.uid())
    OR recorded_by_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

CREATE POLICY "Attendance: supervisor records"
  ON attendance FOR INSERT
  WITH CHECK (
    recorded_by_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- ─── Badges Policies ───
CREATE POLICY "Badges: read own children"
  ON badges FOR SELECT
  USING (
    child_id IN (SELECT c.id FROM children c JOIN users u ON u.id = c.parent_id WHERE u.auth_id = auth.uid())
  );

-- ─── Rewards Policies ───
CREATE POLICY "Rewards: parent manages"
  ON rewards FOR ALL
  USING (
    parent_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- ─── Correction Requests Policies ───
CREATE POLICY "Corrections: parent creates and reads"
  ON correction_requests FOR ALL
  USING (
    parent_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

CREATE POLICY "Corrections: supervisor reads mosque corrections"
  ON correction_requests FOR SELECT
  USING (
    mosque_id IN (SELECT mm.mosque_id FROM mosque_members mm JOIN users u ON u.id = mm.user_id WHERE u.auth_id = auth.uid())
  );

CREATE POLICY "Corrections: supervisor reviews"
  ON correction_requests FOR UPDATE
  USING (
    mosque_id IN (SELECT mm.mosque_id FROM mosque_members mm JOIN users u ON u.id = mm.user_id WHERE u.auth_id = auth.uid())
  );

-- ─── Notes Policies ───
CREATE POLICY "Notes: sender or parent reads"
  ON notes FOR SELECT
  USING (
    sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    OR child_id IN (SELECT c.id FROM children c JOIN users u ON u.id = c.parent_id WHERE u.auth_id = auth.uid())
  );

CREATE POLICY "Notes: supervisor sends"
  ON notes FOR INSERT
  WITH CHECK (
    sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- ─── Announcements Policies ───
CREATE POLICY "Announcements: read mosque announcements"
  ON announcements FOR SELECT
  USING (
    mosque_id IN (SELECT mm.mosque_id FROM mosque_members mm JOIN users u ON u.id = mm.user_id WHERE u.auth_id = auth.uid())
    OR mosque_id IN (
      SELECT mc.mosque_id FROM mosque_children mc
      JOIN children c ON c.id = mc.child_id
      JOIN users u ON u.id = c.parent_id
      WHERE u.auth_id = auth.uid()
    )
  );

CREATE POLICY "Announcements: supervisor creates"
  ON announcements FOR INSERT
  WITH CHECK (
    sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

-- ═══════════════════════════════════════
-- 6. Super Admin Policies
-- ═══════════════════════════════════════

-- Super Admin يقرأ كل شيء
CREATE POLICY "Super Admin: read all users"
  ON users FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "Super Admin: manage mosques"
  ON mosques FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE auth_id = auth.uid() AND role = 'super_admin')
  );

-- ═══════════════════════════════════════
-- 7. Auto-create user profile on signup
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (auth_id, name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'مستخدم جديد'),
    NEW.email,
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'parent')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: عند إنشاء حساب جديد → ينشئ record تلقائياً في users
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
