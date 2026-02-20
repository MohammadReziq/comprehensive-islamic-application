# خطة صفحات المشرف

مرجع لبناء/تحسين شاشات المشرف. يُستند إلى `docs/supervisor_capabilities_spec.md`.

---

## الهيكل الحالي

```
lib/app/features/supervisor/
├── data/
│   ├── models/mosque_student_model.dart
│   └── repositories/supervisor_repository.dart    ✅
├── presentation/
│   ├── bloc/
│   │   ├── scanner_bloc.dart                     ✅
│   │   ├── scanner_event.dart
│   │   └── scanner_state.dart
│   └── screens/
│       ├── supervisor_dashboard_screen.dart      ✅
│       ├── supervisor_placeholder_screen.dart    (للـ placeholder فقط)
│       ├── scanner_screen.dart                  ✅
│       ├── students_screen.dart                 ✅
│       ├── child_profile_screen.dart            ✅
│       └── (مشترك: corrections, notes send, competitions من features أخرى)
```

**ملاحظة:** لا يوجد SupervisorBloc — لوحة المشرف تعتمد MosqueBloc + SupervisorRepository مباشرة.

---

## ما يعمل حاليًا (لا يحتاج تغييرًا إلا إن رغبت بتحسين التصميم)

| المسار | الشاشة | الحالة |
|--------|--------|--------|
| `/supervisor/dashboard` | SupervisorDashboardScreen | ✅ |
| `/supervisor/scan` | ScannerScreen | ✅ |
| `/supervisor/students` | StudentsScreen | ✅ |
| `/supervisor/child/:id` | ChildProfileScreen | ✅ |
| `/supervisor/corrections/:mosqueId` | CorrectionsListScreen | ✅ |
| `/supervisor/notes/send/:mosqueId` | SendNoteScreen | ✅ |
| `/supervisor/competitions/:mosqueId` | ManageCompetitionScreen | ⚠️ يعمل قراءة؛ أزرار إنشاء/تفعيل/إيقاف ترمي خطأ صلاحية للمشرف |

---

## النواقص المطلوب إضافتها في الريبو/البلوك

### 1. شاشة الملاحظات المرسلة (`/supervisor/notes`) — ناقص

- **الوضع الحالي:** المسار يفتح `SupervisorPlaceholderScreen(title: 'الملاحظات')`.
- **المطلوب:** شاشة حقيقية تعرض "الملاحظات التي أرسلتها" باستخدام:
  - **NotesBloc** + حدث **LoadSentNotes** (موجود في `notes_event.dart`).
  - **NotesRepository.getMySentNotes()** (موجود).
- **الخيارات:**
  - **أ)** إنشاء `lib/app/features/supervisor/presentation/screens/supervisor_sent_notes_screen.dart` — تستخدم BlocProvider<NotesBloc> و LoadSentNotes وتعرض قائمة كـ NotesInboxScreen لكن للمرسَل (بدون mark as read للمرسل؛ اختياري: عرض اسم الطفل إذا أضفنا في الـ repo جلب الاسم).
  - **ب)** إنشاء شاشة في `features/notes` مثل `SentNotesScreen` يعاد استخدامها من المشرف وولي الأمر إن لزم.
- **التوصية:** أ — شاشة في مجلد supervisor تعتمد NotesBloc و LoadSentNotes وقائمة بسيطة (نص، تاريخ، اختياري اسم الطفل).

### 2. المسابقات للمشرف — عرض فقط (اختياري لكن مُفضّل)

- **الوضع الحالي:** `ManageCompetitionScreen` يعرض زر "إنشاء مسابقة" و"تفعيل/إيقاف". عند المشرف استدعاء create/activate/deactivate يرمي `UnauthorizedActionFailure`.
- **المطلوب (واحد من اثنين):**
  - **أ)** تمرير `isImam: bool` (أو `canManage: bool`) للشاشة من الـ router حسب دور المستخدم، وإخفاء أزرار الإنشاء/التفعيل/الإيقاف عندما `canManage == false`.
  - **ب)** مسار منفصل للمشرف يشير لشاشة "عرض المسابقات فقط" (مثلاً `SupervisorCompetitionsScreen` أو `CompetitionViewOnlyScreen`) تعرض القائمة والترتيب بدون أزرار إدارة.
- **التوصية:** أ — أقل تكرارًا؛ نمرر من الـ router الـ extra أو نتحقق من دور المستخدم في الشاشة (AuthBloc) ونخفي الأزرار.

---

## ما يمكن نسخه من صفحات الإمام (بدون منطق الإمام فقط)

| من الإمام | للمشرف | ملاحظة |
|-----------|--------|--------|
| تخطيط لوحة (قسم علوي + شبكة إجراءات) | لوحة المشرف | يمكن توحيد التصميم؛ المشرف بدون طلبات انضمام/مشرفين/إعدادات. |
| ImamStatCard | اختياري | لو أراد المشرف بطاقات إحصائية بنفس الشكل. |
| بطاقة الصلاة القادمة | موجودة حاليًا في لوحة المشرف | يمكن استخراجها كـ widget مشترك لاحقًا. |
| بطاقة المسجد (اسم + كود المسجد فقط) | موجودة | المشرف لا يرى كود الدعوة ولا طلبات الانضمام. |
| CorrectionTile | لا حاجة | المشرف يستخدم CorrectionsListScreen المشتركة. |
| CompetitionCard | نعم إن بُنيت شاشة عرض فقط للمشرف | نفس الـ card مع إخفاء أزرار التفعيل/الإيقاف. |

---

## ترتيب التنفيذ المقترح

| # | المهمة | الملف / التعديل |
|---|--------|------------------|
| 1 | شاشة الملاحظات المرسلة | إنشاء `supervisor_sent_notes_screen.dart` + ربط المسار `/supervisor/notes` بها بدل Placeholder. |
| 2 | إخفاء أزرار إدارة المسابقات للمشرف | في `ManageCompetitionScreen`: قراءة دور المستخدم (AuthBloc أو تمرير من router) وإخفاء زر الإضافة وأزرار تفعيل/إيقاف عندما المستخدم مشرف. |
| 3 | (اختياري) تحسين لوحة المشرف | توحيد التصميم مع لوحة الإمام (شبكة، بطاقات) إن رغبت. |

---

## مراجع سريعة

- **مواصفات المشرف كاملة:** `docs/supervisor_capabilities_spec.md`
- **مواصفات الإمام (للمقارنة والنسخ):** `docs/imam_capabilities_spec.md`
- **مسارات المشرف:** `lib/app/core/router/app_router.dart` (بحث: `/supervisor`)
- **مستودع المشرف:** `lib/app/features/supervisor/data/repositories/supervisor_repository.dart`
- **NotesBloc / LoadSentNotes:** `lib/app/features/notes/presentation/bloc/notes_bloc.dart` و `notes_event.dart`
- **CompetitionRepository:** إنشاء/تفعيل/إيقاف يتحققون من `_requireOwnerRole` في `lib/app/features/competitions/data/repositories/competition_repository.dart`

بعد تنفيذ النقاط 1 و 2 يكون كل ما يفعله المشرف مغطى في الريبو؛ Claude (أو أي مطوّر) يمكنه بناء أو تحسين صفحات المشرف بالاعتماد على هذا الملف و `supervisor_capabilities_spec.md`.
