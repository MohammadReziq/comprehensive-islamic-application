# دليل المطور للبنية التحتية — صلاتي حياتي
> **الإصدار:** 2.0 — فبراير 2026  
> **المصدر:** تطوير `foundation_first_plan.md` بعد نقد شامل ومراجعة الكود الفعلي

---

## 0. النقد اللاذع الشامل (Deep Critique)

### 0.1 ثغرات سلامة البيانات (Data Integrity)

| الثغرة | الخطورة | التفصيل |
|--------|---------|---------|
| **النقاط تُحسب Client-side فقط** | 🔴 حرجة | `SupervisorRepository.recordAttendance()` يحسب `points_earned` عبر `PointsService` في Flutter ثم يرسلها مع الـ INSERT. **لا يوجد trigger في DB** يحدّث `children.total_points`. النقاط قابلة للتلاعب: أي شخص يرسل INSERT مباشر لـ Supabase يضع `points_earned = 9999`. |
| **السلاسل لا تُحدَّث أبداً** | 🔴 حرجة | `children.current_streak` و `best_streak` = 0 دائماً. لا يوجد كود (لا trigger ولا Flutter) يحدّثها بعد تسجيل الحضور. |
| **حذف حضور لا يعيد حساب النقاط** | 🔴 حرجة | لا يوجد trigger on DELETE. حذف سجل attendance → `total_points` يبقى مرتفعاً بشكل خاطئ. |
| **`points_earned` يمكن تزويره** | 🟠 عالية | العميل يرسل `points_earned` في الـ INSERT body. المطلوب: الـ trigger يحسبها server-side ويتجاهل القيمة المرسلة. |

### 0.2 Race Conditions

| السيناريو | التحليل |
|-----------|---------|
| **مشرفان يسجلان نفس الطفل/صلاة/تاريخ** | `UNIQUE(child_id, prayer, prayer_date)` يمنع التكرار ✅. لكن التطبيق لا يعرض رسالة خطأ واضحة — يستلم المشرف `PostgresException` خام. المطلوب: try/catch في الريبو يحوّل الخطأ لـ `DuplicateAttendanceFailure`. |
| **تفعيل مسابقتين نشطتين** | لا يوجد جدول `competitions` بعد. عند إنشائه: يجب `UNIQUE(mosque_id) WHERE is_active = true` (partial unique index) أو transaction: إيقاف القديمة ثم تفعيل الجديدة. |
| **Offline sync يرفع سجلين متعارضين** | `OfflineSyncService.syncPendingOperations()` تفشل صامتة (`continue` في catch). لا retry policy، لا تسجيل للخطأ، لا إشعار للمستخدم. |

### 0.3 ثغرات RLS الفعلية (من الكود، ليست نظرية)

| الجدول | الثغرة | الخطورة |
|--------|--------|---------|
| **attendance INSERT** | السياسة `"Attendance: supervisor records"` تتحقق فقط من `recorded_by_id = auth.uid()`. **لا تتحقق أن المسجل عضو في المسجد**. أي مستخدم مسجّل يقدر يسجّل حضور لأي طفل في أي مسجد! | 🔴 حرجة |
| **notes INSERT** | `"Notes: supervisor sends"` تتحقق فقط من `sender_id = auth.uid()`. **لا تتحقق من عضوية المسجد**. أي مستخدم يرسل ملاحظة لأي طفل. | 🔴 حرجة |
| **announcements INSERT** | `"Announcements: supervisor creates"` — نفس المشكلة: `sender_id = auth.uid()` فقط. | 🟠 عالية |
| **correction_requests FOR ALL** | السياسة `"Corrections: parent creates and reads"` تستخدم `FOR ALL` مع `USING (parent_id = auth.uid())`. هذا يسمح لولي الأمر بـ UPDATE و DELETE طلباته — بما فيه تغيير `status` من `pending` إلى `approved` بنفسه! | 🔴 حرجة |
| **children UPDATE** | ولي الأمر يعدّل أطفاله — يشمل `total_points`, `current_streak`, `best_streak`. يمكنه كتابة أي قيمة! المطلوب: إما trigger يمنع تعديل هذه الأعمدة من العميل، أو RLS أضيق. | 🔴 حرجة |
| **mosques SELECT** | `status = 'approved' OR owner_id = auth.uid()` — أي مستخدم يرى كل المساجد المعتمدة بكل بياناتها (invite_code!). المطلوب: إخراج `invite_code` من SELECT العام أو إنشاء view. | 🟠 عالية |

### 0.4 أمان Realtime Subscriptions

**الحقيقة:** Supabase Realtime **يطبّق RLS** على `postgres_changes` — المستخدم يرى فقط الصفوف التي يسمح SELECT بقراءتها. **لكن:**

- سياسة `attendance SELECT` تسمح لولي الأمر برؤية حضور أطفاله ✅. يسمح أيضاً لـ `recorded_by_id = auth.uid()` — أي مشرف يرى كل ما سجّله هو فقط ✅.
- **لكنها لا تسمح للمشرف برؤية حضور سجّله مشرف آخر في نفس المسجد** — فالـ SELECT مربوط بـ `recorded_by_id` وليس بعضوية المسجد. هذا يكسر الـ Realtime لشاشة "حضور المسجد اليوم" للمشرفين.
- **ملاحظة:** Migration `018_attendance_mosque_members_read.sql` قد تكون عالجت هذا. يجب التحقق.

### 0.5 حالات حافة (Edge Cases)

| الحالة | المشكلة | الحل |
|--------|---------|------|
| **طفل ينتقل بين مسجدين** | `UNIQUE(child_id, prayer, prayer_date)` يعني أول مسجد يسجّل يفوز. المسجد الثاني يفشل بخطأ duplicate. لا يوجد منطق "أي مسجد أولاً". | الخطة: نقبل "الأول يربح". عند فشل INSERT → رسالة واضحة "تم التسجيل في مسجد آخر". |
| **حذف حضور قديم** | لا يوجد RPC للحذف. لا DELETE policy على attendance. المشرف يجب أن يطلب من الأدمن. | RPC `cancel_attendance(attendance_id)` مع صلاحيات وإعادة حساب. |
| **مسابقة تنتهي وفيها حضور معلق offline** | offline record يحمل `prayer_date` ضمن فترة المسابقة، لكن يُرفع بعد انتهائها. | الـ trigger يربط `competition_id` بناءً على `prayer_date` (وليس `recorded_at`). |
| **طلب تصحيح لصلاة مُسجّلة** | لا يوجد validation. ولي الأمر يرسل طلب لصلاة فيها حضور بالفعل. | فحص في الريبو + DB constraint. |
| **ولي أمر يرسل 10 طلبات لنفس الصلاة** | لا UNIQUE على `correction_requests(child_id, prayer, prayer_date)`. | إضافة partial unique: `WHERE status = 'pending'`. |

---

## 1. قاعدة البيانات: SQL الفعلي للتنفيذ

### 1.1 Trigger: تحديث النقاط والسلاسل (الأهم)

```sql
-- ═══════════════════════════════════════
-- دالة حساب النقاط والسلاسل لطفل معين
-- تُستدعى من trigger بعد INSERT أو DELETE على attendance
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION recalc_child_stats(p_child_id UUID)
RETURNS VOID AS $$
DECLARE
  v_total       INT;
  v_current     INT := 0;
  v_best        INT := 0;
  v_prev_date   DATE := NULL;
  v_streak      INT := 0;
  rec           RECORD;
BEGIN
  -- 1) مجموع النقاط
  SELECT COALESCE(SUM(points_earned), 0) INTO v_total
    FROM attendance WHERE child_id = p_child_id;

  -- 2) حساب السلاسل من التواريخ المميزة (مرتبة تنازلياً)
  FOR rec IN
    SELECT DISTINCT prayer_date
      FROM attendance
     WHERE child_id = p_child_id
     ORDER BY prayer_date DESC
  LOOP
    IF v_prev_date IS NULL THEN
      -- أول تاريخ (الأحدث)
      v_streak := 1;
    ELSIF v_prev_date - rec.prayer_date = 1 THEN
      -- يوم متتالي
      v_streak := v_streak + 1;
    ELSE
      -- انقطاع: حفظ أفضل سلسلة والبدء من جديد
      IF v_streak > v_best THEN v_best := v_streak; END IF;
      v_streak := 1;
    END IF;
    v_prev_date := rec.prayer_date;
  END LOOP;

  -- حفظ آخر سلسلة
  IF v_streak > v_best THEN v_best := v_streak; END IF;

  -- current_streak = السلسلة فقط إذا شملت اليوم أو أمس
  IF v_prev_date IS NOT NULL THEN
    -- v_prev_date هو أقدم تاريخ في آخر سلسلة متصلة
    -- نحتاج أحدث تاريخ (أول rec في الحلقة)
    SELECT MAX(prayer_date) INTO v_prev_date
      FROM attendance WHERE child_id = p_child_id;
    IF v_prev_date >= CURRENT_DATE - INTERVAL '1 day' THEN
      v_current := v_streak; -- BUG FIX: نحتاج إعادة حساب من الأحدث
    END IF;
  END IF;

  -- إعادة حساب current_streak بشكل صحيح
  v_current := 0;
  v_prev_date := NULL;
  FOR rec IN
    SELECT DISTINCT prayer_date
      FROM attendance
     WHERE child_id = p_child_id
     ORDER BY prayer_date DESC
  LOOP
    IF v_prev_date IS NULL THEN
      IF rec.prayer_date >= CURRENT_DATE - INTERVAL '1 day' THEN
        v_current := 1;
      ELSE
        EXIT; -- آخر حضور قديم، لا سلسلة حالية
      END IF;
    ELSIF v_prev_date - rec.prayer_date = 1 THEN
      v_current := v_current + 1;
    ELSE
      EXIT; -- انقطاع
    END IF;
    v_prev_date := rec.prayer_date;
  END LOOP;

  -- 3) تحديث الطفل
  UPDATE children SET
    total_points   = v_total,
    current_streak = v_current,
    best_streak    = GREATEST(v_best, v_current)
  WHERE id = p_child_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════
-- Trigger function
-- ═══════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_attendance_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM recalc_child_stats(OLD.child_id);
    RETURN OLD;
  ELSE
    -- فرض حساب النقاط server-side (تجاهل القيمة المرسلة من العميل)
    IF TG_OP = 'INSERT' THEN
      NEW.points_earned := CASE
        WHEN NEW.location_type = 'mosque' THEN 10
        WHEN NEW.prayer = 'fajr' THEN 5
        ELSE 3
      END;
    END IF;
    PERFORM recalc_child_stats(NEW.child_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER attendance_stats_trigger
  AFTER INSERT OR DELETE ON attendance
  FOR EACH ROW EXECUTE FUNCTION trg_attendance_stats();

-- Trigger BEFORE INSERT لفرض النقاط server-side
CREATE OR REPLACE FUNCTION trg_enforce_points()
RETURNS TRIGGER AS $$
BEGIN
  NEW.points_earned := CASE
    WHEN NEW.location_type = 'mosque' THEN 10
    WHEN NEW.prayer = 'fajr' THEN 5
    ELSE 3
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_points_trigger
  BEFORE INSERT ON attendance
  FOR EACH ROW EXECUTE FUNCTION trg_enforce_points();
```

### 1.2 جدول المسابقات

```sql
CREATE TABLE competitions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id   UUID NOT NULL REFERENCES mosques(id) ON DELETE CASCADE,
  name_ar     TEXT NOT NULL,
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT false,
  created_by  UUID NOT NULL REFERENCES users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_date >= start_date)
);

-- مسابقة نشطة واحدة فقط لكل مسجد
CREATE UNIQUE INDEX idx_competitions_active_mosque
  ON competitions(mosque_id) WHERE is_active = true;

ALTER TABLE competitions ENABLE ROW LEVEL SECURITY;

-- owner المسجد يقرأ ويكتب
CREATE POLICY "Competitions: owner manages"
  ON competitions FOR ALL
  USING (mosque_id IN (
    SELECT m.id FROM mosques m
    JOIN users u ON u.id = m.owner_id
    WHERE u.auth_id = auth.uid()
  ));

-- أعضاء المسجد يقرأون
CREATE POLICY "Competitions: members read"
  ON competitions FOR SELECT
  USING (mosque_id IN (
    SELECT mm.mosque_id FROM mosque_members mm
    JOIN users u ON u.id = mm.user_id
    WHERE u.auth_id = auth.uid()
  ));

-- أولياء الأمور يقرأون مسابقات مساجد أطفالهم
CREATE POLICY "Competitions: parents read"
  ON competitions FOR SELECT
  USING (mosque_id IN (
    SELECT mc.mosque_id FROM mosque_children mc
    JOIN children c ON c.id = mc.child_id
    JOIN users u ON u.id = c.parent_id
    WHERE u.auth_id = auth.uid()
  ));

-- ربط الحضور بالمسابقة
ALTER TABLE attendance ADD COLUMN competition_id UUID REFERENCES competitions(id);
CREATE INDEX idx_attendance_competition ON attendance(competition_id);
```

### 1.3 إصلاح RLS الحرجة

```sql
-- ═══ إصلاح attendance INSERT ═══
DROP POLICY IF EXISTS "Attendance: supervisor records" ON attendance;
CREATE POLICY "Attendance: member records"
  ON attendance FOR INSERT
  WITH CHECK (
    recorded_by_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    AND mosque_id IN (
      SELECT mm.mosque_id FROM mosque_members mm
      JOIN users u ON u.id = mm.user_id
      WHERE u.auth_id = auth.uid()
    )
  );

-- ═══ إصلاح notes INSERT ═══
DROP POLICY IF EXISTS "Notes: supervisor sends" ON notes;
CREATE POLICY "Notes: mosque member sends"
  ON notes FOR INSERT
  WITH CHECK (
    sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    AND mosque_id IN (
      SELECT mm.mosque_id FROM mosque_members mm
      JOIN users u ON u.id = mm.user_id
      WHERE u.auth_id = auth.uid()
    )
  );

-- ═══ إصلاح announcements INSERT ═══
DROP POLICY IF EXISTS "Announcements: supervisor creates" ON announcements;
CREATE POLICY "Announcements: mosque member creates"
  ON announcements FOR INSERT
  WITH CHECK (
    sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    AND mosque_id IN (
      SELECT mm.mosque_id FROM mosque_members mm
      JOIN users u ON u.id = mm.user_id
      WHERE u.auth_id = auth.uid()
    )
  );

-- ═══ إصلاح correction_requests: تفكيك FOR ALL ═══
DROP POLICY IF EXISTS "Corrections: parent creates and reads" ON correction_requests;

CREATE POLICY "Corrections: parent reads own"
  ON correction_requests FOR SELECT
  USING (parent_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Corrections: parent creates"
  ON correction_requests FOR INSERT
  WITH CHECK (parent_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- ممنوع على ولي الأمر UPDATE أو DELETE
-- فقط المشرف/الإمام يحدّث
-- (السياسة "Corrections: supervisor reviews" موجودة أصلاً)

-- ═══ منع تعديل نقاط الطفل من العميل ═══
CREATE OR REPLACE FUNCTION trg_protect_child_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- فقط SECURITY DEFINER functions تعدّل هذه الحقول
  IF current_setting('role') != 'service_role' THEN
    NEW.total_points   := OLD.total_points;
    NEW.current_streak := OLD.current_streak;
    NEW.best_streak    := OLD.best_streak;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER protect_child_stats_trigger
  BEFORE UPDATE ON children
  FOR EACH ROW EXECUTE FUNCTION trg_protect_child_stats();

-- ═══ إصلاح announcements: UPDATE/DELETE للمرسل ═══
CREATE POLICY "Announcements: sender updates"
  ON announcements FOR UPDATE
  USING (sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Announcements: sender deletes"
  ON announcements FOR DELETE
  USING (sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
```

### 1.4 Indexes ناقصة

```sql
-- طلبات التصحيح المعلقة لمسجد (أكثر استعلام تكراراً)
CREATE INDEX idx_corrections_mosque_status
  ON correction_requests(mosque_id, status);

-- حضور طفل مرتب بالتاريخ (لحساب السلسلة)
CREATE INDEX idx_attendance_child_date
  ON attendance(child_id, prayer_date DESC);

-- منع تكرار طلب تصحيح pending
CREATE UNIQUE INDEX idx_corrections_pending_unique
  ON correction_requests(child_id, prayer, prayer_date)
  WHERE status = 'pending';

-- ملاحظات طفل غير مقروءة
CREATE INDEX idx_notes_child_unread
  ON notes(child_id, is_read) WHERE is_read = false;
```

### 1.5 RPC: إلغاء حضور

```sql
CREATE OR REPLACE FUNCTION cancel_attendance(p_attendance_id UUID)
RETURNS VOID AS $$
DECLARE
  v_child_id    UUID;
  v_recorded_by UUID;
  v_recorded_at TIMESTAMPTZ;
  v_user_id     UUID;
BEGIN
  -- جلب بيانات السجل
  SELECT child_id, recorded_by_id, recorded_at
    INTO v_child_id, v_recorded_by, v_recorded_at
    FROM attendance WHERE id = p_attendance_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'سجل الحضور غير موجود';
  END IF;

  -- التحقق: فقط من سجّل أو عضو المسجد، خلال 24 ساعة
  SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
  IF v_recorded_by != v_user_id THEN
    RAISE EXCEPTION 'ليس لديك صلاحية إلغاء هذا السجل';
  END IF;
  IF now() - v_recorded_at > INTERVAL '24 hours' THEN
    RAISE EXCEPTION 'انتهت مهلة الإلغاء (24 ساعة)';
  END IF;

  -- حذف (الـ trigger سيعيد حساب النقاط/السلاسل)
  DELETE FROM attendance WHERE id = p_attendance_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 1.6 Timezone: إضافة عمود للمسجد

```sql
-- المسجد يحتاج timezone لحساب "اليوم" الصحيح
ALTER TABLE mosques ADD COLUMN timezone TEXT NOT NULL DEFAULT 'Asia/Riyadh';

-- دالة "اليوم" حسب توقيت المسجد
CREATE OR REPLACE FUNCTION mosque_today(p_mosque_id UUID)
RETURNS DATE AS $$
DECLARE
  v_tz TEXT;
BEGIN
  SELECT timezone INTO v_tz FROM mosques WHERE id = p_mosque_id;
  RETURN (now() AT TIME ZONE COALESCE(v_tz, 'Asia/Riyadh'))::DATE;
END;
$$ LANGUAGE plpgsql STABLE;
```

---

## 2. سياسات RLS: مراجعة شاملة لكل جدول

| الجدول | SELECT | INSERT | UPDATE | DELETE | الحالة |
|--------|--------|--------|--------|--------|--------|
| `users` | ✅ own + super_admin | ✅ own | ✅ own | ❌ | ✅ |
| `children` | ✅ parent + supervisors | ✅ parent | ⚠️ parent (يشمل نقاط!) | ❌ | 🔴 يحتاج trigger حماية |
| `mosques` | ⚠️ approved+owner (يكشف invite_code) | ✅ owner | ✅ owner + super_admin | ❌ | 🟠 |
| `mosque_members` | ✅ | ✅ owner | ❌ | ✅ owner | ✅ |
| `mosque_children` | ✅ | ✅ parent | ❌ | ❌ | ✅ |
| `attendance` | ✅ | 🔴 أي مسجل! | ❌ | ❌ | 🔴 يحتاج إصلاح |
| `correction_requests` | ✅ | ✅ parent | 🔴 parent يعدّل status! | 🔴 parent يحذف! | 🔴 يحتاج تفكيك |
| `notes` | ✅ | 🔴 أي مسجل! | ❌ | ❌ | 🔴 يحتاج إصلاح |
| `announcements` | ✅ | 🔴 أي مسجل! | ❌ | ❌ | 🔴 يحتاج إصلاح |
| `badges` | ✅ parent | ❌ | ❌ | ❌ | ✅ |
| `rewards` | ✅ parent | ✅ parent | ✅ parent | ✅ parent | ✅ |

---

## 3. هيكل الريبوهات (Repositories)

### 3.1 CorrectionRepository

```dart
class CorrectionRepository {
  final AuthRepository _authRepo;
  CorrectionRepository(this._authRepo);

  /// إنشاء طلب تصحيح (ولي الأمر)
  /// Failures: NotLoggedIn, AttendanceAlreadyExists,
  ///           PendingCorrectionExists, ChildNotInMosque
  Future<CorrectionRequestModel> createRequest({
    required String childId,
    required String mosqueId,
    required String prayer,       // fajr, dhuhr, ...
    required String prayerDate,   // yyyy-MM-dd
    String? note,
  }) async {
    // 1. التحقق من عدم وجود حضور
    // 2. التحقق من عدم وجود طلب pending
    // 3. INSERT مع parent_id = currentUser.id
  }

  /// طلبات مسجد معلقة (إمام/مشرف)
  Future<List<CorrectionRequestModel>> getPendingForMosque(String mosqueId);

  /// طلبات أطفالي (ولي الأمر)
  Future<List<CorrectionRequestModel>> getMyRequests();

  /// موافقة (إمام/مشرف) — Transaction:
  /// 1. التحقق من عدم وجود حضور
  /// 2. INSERT attendance (الـ trigger يحدّث النقاط)
  /// 3. UPDATE correction_requests SET status='approved'
  Future<void> approveRequest(String requestId);

  /// رفض
  Future<void> rejectRequest(String requestId, {String? reason});
}
```

### 3.2 NotesRepository

```dart
class NotesRepository {
  /// إرسال ملاحظة (مشرف/إمام → عن طفل)
  Future<NoteModel> sendNote({
    required String childId,
    required String mosqueId,
    required String message,
  });

  /// ملاحظات أطفالي (ولي الأمر)
  Future<List<NoteModel>> getNotesForMyChildren();

  /// ملاحظات أرسلتها (مشرف)
  Future<List<NoteModel>> getMySentNotes();

  /// تحديث حالة القراءة
  Future<void> markAsRead(String noteId);
}
```

### 3.3 CompetitionRepository

```dart
class CompetitionRepository {
  /// إنشاء مسابقة (إمام): لا تكون نشطة تلقائياً
  Future<CompetitionModel> create({...});

  /// تفعيل مسابقة (يوقف أي نشطة أخرى تلقائياً عبر partial unique)
  Future<void> activate(String competitionId);

  /// إيقاف مسابقة
  Future<void> deactivate(String competitionId);

  /// المسابقة النشطة للمسجد
  Future<CompetitionModel?> getActive(String mosqueId);

  /// ترتيب الأطفال في المسابقة (من attendance)
  Future<List<LeaderboardEntry>> getLeaderboard(String competitionId);
}
```

### 3.4 معالجة Exceptions → Custom Failures

```dart
// كل Repository يحوّل PostgresException لـ Failure مفهومة:
abstract class AppFailure {
  final String messageAr;
  const AppFailure(this.messageAr);
}

class DuplicateAttendanceFailure extends AppFailure {
  const DuplicateAttendanceFailure()
    : super('تم تسجيل الحضور لهذه الصلاة مسبقاً');
}

class NotMosqueMemberFailure extends AppFailure {
  const NotMosqueMemberFailure()
    : super('ليس لديك صلاحية في هذا المسجد');
}

class AttendanceWindowClosedFailure extends AppFailure {
  const AttendanceWindowClosedFailure()
    : super('انتهت مهلة تسجيل الحضور لهذه الصلاة');
}

class PendingCorrectionExistsFailure extends AppFailure {
  const PendingCorrectionExistsFailure()
    : super('يوجد طلب تصحيح معلق لهذه الصلاة');
}
```

---

## 4. معمارية BLoC

### 4.1 القاعدة: BLoC لكل Domain وليس لكل شاشة

| BLoC | المسؤولية | النوع |
|------|-----------|-------|
| `AuthBloc` | تسجيل دخول، حالة المستخدم | `LazySingleton` |
| `MosqueBloc` | بيانات المسجد، أعضاء، أكواد | `LazySingleton` |
| `ChildrenBloc` | أطفالي، ربط بمسجد | `Factory` |
| `AttendanceBloC` | تسجيل حضور، حضور اليوم | `Factory` |
| `CorrectionBloc` | طلبات تصحيح | `Factory` |
| `NotesBloc` | ملاحظات | `Factory` |
| `CompetitionBloc` | مسابقات | `Factory` |

### 4.2 ربط Realtime Streams بالـ BLoC بدون Memory Leaks

```dart
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final SupervisorRepository _repo;
  final RealtimeService _realtime;
  StreamSubscription? _realtimeSub; // ← مفتاح منع التسريب

  AttendanceBloc(this._repo, this._realtime) : super(AttendanceInitial()) {
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<AttendanceUpdated>(_onUpdated);
  }

  void _onStartListening(StartListening event, Emitter emit) {
    _realtime.subscribeAttendanceForMosque(
      event.mosqueId,
      (payload) => add(AttendanceUpdated(payload)),
    );
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel(); // ← إلغاء الاشتراك
    _realtime.unsubscribeAttendance();
    return super.close();
  }
}
```

**القاعدة:** الـ `StreamSubscription` تُلغى في `close()`. الـ BLoC من نوع `Factory` يُنشأ ويُدمّر مع الشاشة عبر `BlocProvider`.

### 4.3 Realtime: معالجة انقطاع الاتصال

```dart
// في RealtimeService: إضافة reconnection logic
void _setupReconnection() {
  supabase.realtime.onError((error) {
    // تأخير ثم إعادة الاشتراك
    Future.delayed(Duration(seconds: 5), () {
      _resubscribeAll();
    });
  });
}
```

---

## 5. حل مشاكل التوقيت والـ Offline

### 5.1 ضمان prayer_date بتوقيت المسجد

```
┌─────────────────────────────────────────┐
│ المشرف يفتح التحضير                     │
│   ↓                                     │
│ Flutter: PrayerTimesService             │
│   .updateLocation(mosque.lat, mosque.lng)│
│   ↓                                     │
│ "اليوم" = DateTime.now() مُحوّل         │
│   بتوقيت المسجد (mosque.timezone)       │
│   ↓                                     │
│ prayer_date = اليوم بتوقيت المسجد       │
│   (ليس UTC ولا توقيت الجهاز)           │
└─────────────────────────────────────────┘
```

**التنفيذ في Flutter:**
```dart
String getMosquePrayerDate(MosqueModel mosque) {
  // timezone package لتحويل now() لتوقيت المسجد
  final tz = getLocation(mosque.timezone); // 'Asia/Riyadh'
  final mosqueNow = TZDateTime.now(tz);
  return DateFormat('yyyy-MM-dd').format(mosqueNow);
}
```

### 5.2 Offline Conflict Resolution

```
┌───────────────────────────────────────────┐
│ المشرف بدون إنترنت يسجّل حضور            │
│   ↓                                       │
│ OfflineSyncService.enqueueOperation()      │
│   prayer_date = توقيت المسجد (محسوب محلياً)│
│   ↓                                       │
│ الإنترنت يعود → syncPendingOperations()   │
│   ↓                                       │
│ INSERT attendance مع prayer_date المحفوظ   │
│   ↓                                       │
│ UNIQUE(child_id, prayer, prayer_date)      │
│   ↓ conflict?                             │
│ نعم → 23505 error → DuplicateFailure      │
│   → تعليم العملية كـ "conflict" (ليس خطأ) │
│   → إشعار المشرف "تم التسجيل مسبقاً"     │
│ لا → نجاح → trigger يحدّث النقاط         │
└───────────────────────────────────────────┘
```

**المطلوب في `OfflineSyncService`:**
1. عدم `continue` صامتة — تسجيل نوع الخطأ
2. أخطاء `23505` (unique violation) → تعليم كـ `conflict_resolved`
3. أخطاء أخرى → إعادة المحاولة (max 3)
4. عرض عدد العمليات المتعارضة للمشرف

---

## 6. خطة التنفيذ المرحلية

### المرحلة 1: سلامة البيانات (أولوية قصوى)
1. ✅ Migration: `trg_attendance_stats` + `trg_enforce_points`
2. ✅ Migration: `trg_protect_child_stats`
3. ✅ Migration: إصلاح RLS (attendance, notes, announcements, corrections)
4. ✅ Migration: Indexes

### المرحلة 2: البنية الجديدة
5. Migration: `competitions` + `attendance.competition_id`
6. Migration: `mosques.timezone`
7. Migration: `cancel_attendance` RPC
8. Migration: partial unique على `correction_requests`

### المرحلة 3: Flutter
9. Models: `CorrectionRequestModel`, `NoteModel`, `AnnouncementModel`, `CompetitionModel`
10. `AppFailure` hierarchy + exception mapping
11. Repositories: Correction, Notes, Announcements, Competition
12. `AttendanceValidationService`
13. تحديث `SupervisorRepository.recordAttendance` لاستخدام validation

### المرحلة 4: Realtime + BLoC
14. Realtime channels: corrections, notes
15. BLoCs: Correction, Notes, Competition, Attendance (مع Realtime)
16. Reconnection logic

### المرحلة 5: Offline
17. تحسين `OfflineSyncService` (conflict resolution)
18. Timezone-aware `prayer_date` في الكود

---

## 7. مراجع

| المرجع | الملف |
|--------|-------|
| الخطة الأصلية | `docs/foundation_first_plan.md` |
| دراسة الأدوار | `docs/study_roles_integration.md` |
| Schema الحالي | `supabase/migrations/001_initial_schema.sql` |
| Realtime Service | `lib/app/core/services/realtime_service.dart` |
| Points Service | `lib/app/core/services/points_service.dart` |
| Offline Service | `lib/app/core/services/offline_sync_service.dart` |
| Supervisor Repo | `lib/app/features/supervisor/data/repositories/supervisor_repository.dart` |

---

*آخر تحديث: 2026-02-18 — بعد نقد شامل للكود الفعلي وكتابة SQL التنفيذي وإصلاحات RLS.*
