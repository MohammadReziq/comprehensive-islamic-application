# خطة صفحات ولي الأمر

مرجع لبناء/تحسين شاشات ولي الأمر. يُستند إلى `docs/parent_capabilities_spec.md`.

---

## الهيكل الحالي

```
lib/app/features/parent/
├── data/
│   └── repositories/child_repository.dart       ✅
├── presentation/
│   ├── bloc/
│   │   ├── children_bloc.dart                  ✅
│   │   ├── children_event.dart
│   │   └── children_state.dart
│   └── screens/
│       ├── home_screen.dart                    ✅
│       ├── children_screen.dart                ✅
│       ├── add_child_screen.dart               ✅
│       ├── child_card_screen.dart              ✅
│       └── child_view_screen.dart              ⚠️ للابن (role=child) وليس ولي الأمر
```

**شاشات مشتركة (من features أخرى):**
- `RequestCorrectionScreen` — طلب تصحيح
- `MyCorrectionsScreen` — طلباتي
- `NotesInboxScreen` — ملاحظات المشرف
- `ProfileScreen` — الملف الشخصي

---

## ما يعمل حاليًا (لا يحتاج تغييرًا إلا إن رغبت بتحسين التصميم)

| المسار | الشاشة | الحالة |
|--------|--------|--------|
| `/home` | HomeScreen | ✅ |
| `/parent/children` | ChildrenScreen | ✅ |
| `/parent/children/add` | AddChildScreen | ✅ |
| `/parent/children/:id/card` | ChildCardScreen | ✅ |
| `/parent/children/:id/request-correction` | RequestCorrectionScreen | ✅ |
| `/parent/corrections` | MyCorrectionsScreen | ✅ |
| `/parent/notes` | NotesInboxScreen | ✅ |

---

## النواقص أو التحسينات الممكنة (اختياري)

### 1. صفحة ملف الطفل الشامل (للولي أمر) — غير موجودة حالياً

- **المصدر:** `ChildRepository.getFullChildProfile(childId)` و `getAttendanceHistory` و `getChildReport`.
- **المحتوى المقترح:** النقاط، المستوى، أيام الحضور، سجل الحضور، تقرير أسبوعي/شهري.
- **المسار المقترح:** `/parent/children/:id` أو `/parent/children/:id/profile` — حالياً ولي الأمر يفتح بطاقة الطفل ثم طلب تصحيح؛ لا صفحة "ملف الطفل الشامل" مخصصة لولي الأمر (ChildViewScreen مخصصة للابن role=child).

### 2. عرض مسابقات الطفل وترتيبه — غير موجود

- **المصدر:** RLS تسمح لولي الأمر بقراءة مسابقات مساجد أطفاله؛ `CompetitionRepository.getLeaderboard(competitionId)`.
- **المحتوى المقترح:** عرض المسابقات النشطة لأطفاله وترتيب كل مسابقة.
- **ملاحظة:** يمكن إضافتها داخل صفحة ملف الطفل أو شاشة مستقلة.

### 3. تحسين طلبات التصحيح — عرض اسم الطفل

- **الوضع الحالي:** `CorrectionRepository.getMyRequests()` يُرجع طلبات بدون `children(name)` — `childName` يكون null في `CorrectionRequestModel`.
- **المطلوب (اختياري):** إضافة JOIN مع `children` في `getMyRequests` لعرض اسم الطفل: `.select('*, children(name)')` أو RPC مشابه.

### 4. توحيد التصميم مع لوحة الإمام/المشرف

- لوحة الرئيسية لولي الأمر يمكن تحويلها إلى شبكة إجراءات + قسم علوي (ترحيب، حضور اليوم) كالإمام إن رغبت.

---

## ترتيب التنفيذ المقترح (اختياري)

| # | المهمة | الملف / التعديل |
|---|--------|------------------|
| 1 | (اختياري) إضافة اسم الطفل لطلبات التصحيح | `CorrectionRepository.getMyRequests()` — select مع JOIN `children(name)` |
| 2 | (اختياري) صفحة ملف الطفل الشامل لولي الأمر | إنشاء `child_profile_parent_screen.dart` أو توسيع ChildCardScreen |
| 3 | (اختياري) عرض مسابقات الطفل وترتيبه | إضافة قسم في صفحة ملف الطفل أو شاشة مستقلة |

---

## مراجع سريعة

- **مواصفات ولي الأمر:** `docs/parent_capabilities_spec.md`
- **مواصفات الإمام:** `docs/imam_capabilities_spec.md`
- **مواصفات المشرف:** `docs/supervisor_capabilities_spec.md`
- **مسارات ولي الأمر:** `lib/app/core/router/app_router.dart` (بحث: `/parent` أو `/home`)
- **مستودع الأطفال:** `lib/app/features/parent/data/repositories/child_repository.dart`
- **ChildrenBloc:** `lib/app/features/parent/presentation/bloc/children_bloc.dart`
- **CorrectionBloc / NotesBloc:** في مجلدات `corrections` و `notes`

بعد تنفيذ ما هو مطلوب يكون كل ما يفعله ولي الأمر مغطى في الريبو؛ Claude يمكنه بناء أو تحسين صفحات ولي الأمر بالاعتماد على هذا الملف و `parent_capabilities_spec.md`.
