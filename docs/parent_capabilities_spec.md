# كل ما يستطيع ولي الأمر فعله — مواصفات حرفية لبناء صفحات ولي الأمر

هذه الوثيقة تذكر **حرفياً** كل شيء يستطيع ولي الأمر (المستخدم الذي له دور `parent` في `users.role`) أن يفعله في النظام — للتوجيه عند بناء أو إعادة بناء صفحات ولي الأمر.

---

## 1. التوجيه والمسارات (Routes)

- بعد تسجيل الدخول: إذا كان `users.role = parent` يُوجّه إلى `/home`.
- **الرئيسية:** `/home` — الشاشة الرئيسية (ترحيب، حضور اليوم، أطفالي).
- **منع ولي الأمر** من الوصول إلى: `/admin`، `/mosque`، `/imam/*`، `/supervisor/*`، `/child-view` (للابن فقط).

### مسارات ولي الأمر

| المسار | الاسم | الشاشة/الاستخدام |
|--------|--------|-------------------|
| `/home` | home | **الشاشة الرئيسية** — ترحيب، حضور اليوم، أطفالي، إجراءات |
| `/parent/children` | parentChildren | قائمة أطفالي |
| `/parent/children/add` | parentAddChild | إضافة طفل جديد |
| `/parent/children/:id/card` | parentChildCard | بطاقة الطفل (QR، ربط بمسجد، طلب تصحيح) |
| `/parent/children/:id/request-correction` | parentRequestCorrection | طلب تصحيح حضور (صلاة + تاريخ + ملاحظة) |
| `/parent/corrections` | parentMyCorrections | طلبات التصحيح التي أرسلتها |
| `/parent/notes` | parentNotes | ملاحظات المشرف لأطفالي |

---

## 2. الشاشة الرئيسية (`/home`) — المحتوى والإجراءات

- **مصدر البيانات:** `ChildRepository.getMyChildren()` و `getAttendanceForMyChildren(DateTime.now())`.
- **ما يُعرض:**
  - ترحيب بالاسم ودور المستخدم.
  - **حضور اليوم:** قائمة حضور أطفالي اليوم (من `attendance` عبر RLS — ولي الأمر يقرأ حضور أطفاله فقط).
  - **أطفالي:** قائمة مختصرة أو أزرار للانتقال إلى `/parent/children`.
  - إجراءات سريعة: أطفالي، ملاحظات المشرف، طلبات التصحيح.
- **القائمة الجانبية (Drawer):** الرئيسية، أطفالي، ملاحظات المشرف، طلبات التصحيح، تسجيل الخروج.
- **الشريط السفلي:** تبويبان — الرئيسية، الملف الشخصي (ProfileScreen).

---

## 3. المستودعات والعمليات — ما يستخدمه ولي الأمر

### 3.1 الأطفال (ChildRepository)

| العملية | الوصف |
|---------|--------|
| `getMyChildren()` | أطفالي (حيث `parent_id = user.id`). |
| `getMyChild(childId)` | طفل واحد (إن كان من أطفالي). |
| `addChild(name, age, email?, password?)` | إضافة طفل جديد. إن وُجدت email و password يُنشَأ حساب للابن عبر Edge Function `create_child_account` وتُرجع بيانات الدخول. |
| `linkChildToMosque(childId, mosqueCode)` | ربط طفل بمسجد بكود المسجد. يتحقق أن الكود صحيح والمسجد معتمد. |
| `getChildMosqueIds(childId)` | مساجد الطفل المرتبط بها. |
| `getAttendanceForChildOnDate(childId, date)` | حضور طفل واحد في تاريخ معيّن. |
| `getAttendanceForMyChildren(date)` | حضور كل أطفالي في تاريخ معيّن. |
| `getFullChildProfile(childId)` | ملف شامل: الطفل، مساجده، إجمالي النقاط، إجمالي أيام الحضور، المستوى (level = totalPoints ~/ 100 + 1). |
| `getAttendanceHistory(childId, limit?, offset?)` | سجل حضور الطفل (مرتب بالأحدث). |
| `getChildReport(childId, fromDate, toDate)` | تقرير: إجمالي الصلوات، النقاط، أيام الحضور، نسبة الحضور، تفصيل حسب الصلاة. |

### 3.2 الملاحظات (NotesRepository) — ولي الأمر يقرأ فقط

| العملية | الوصف |
|---------|--------|
| `getNotesForMyChildren(childIds)` | ملاحظات أطفالي (مرتبة بالأحدث، مع اسم الطفل من JOIN). |
| `markAsRead(noteId)` | تحديث ملاحظة كمقروءة. |
| `markAllReadForChild(childId)` | تحديث كل ملاحظات طفل كمقروءة. |

### 3.3 طلبات التصحيح (CorrectionRepository)

| العملية | الوصف |
|---------|--------|
| `createRequest(childId, mosqueId, prayer, prayerDate, note?)` | إنشاء طلب تصحيح حضور. يتحقق: لا حضور مسبق، لا طلب pending لنفس (طفل، صلاة، تاريخ). |
| `getMyRequests()` | طلبات التصحيح التي أرسلتها (حيث `parent_id = user.id`). |

### 3.4 المسجد (MosqueRepository) — للتحقق فقط

| العملية | الوصف |
|---------|--------|
| `getApprovedMosqueByCode(code)` | جلب مسجد معتمد بكود (لربط الطفل). |
| `getMosquesByIds(ids)` | جلب مساجد بمعرّفات (للاختيار في طلب التصحيح). |

---

## 4. الشاشات الحالية لولي الأمر

| الشاشة | الملف | الوظيفة |
|--------|--------|---------|
| الرئيسية | `home_screen.dart` | ترحيب، حضور اليوم، أطفالي، إجراءات |
| أطفالي | `children_screen.dart` | قائمة أطفالي + إضافة طفل (ChildrenBloc) |
| إضافة طفل | `add_child_screen.dart` | نموذج اسم، عمر، اختياري: إيميل وكلمة مرور لإنشاء حساب ابن |
| بطاقة الطفل | `child_card_screen.dart` | عرض QR، كود الباركود، ربط بمسجد (كود المسجد)، زر طلب تصحيح |
| طلب تصحيح | `RequestCorrectionScreen` | اختيار مسجد (من مساجد الطفل)، صلاة، تاريخ، ملاحظة — إرسال (CorrectionBloc + createRequest) |
| طلباتي | `MyCorrectionsScreen` | قائمة طلبات التصحيح (CorrectionBloc + LoadMyCorrections) — حالة كل طلب (معلق، مقبول، مرفوض) |
| ملاحظات المشرف | `NotesInboxScreen` | ملاحظات أطفالي (NotesBloc + LoadNotesForChildren)، mark as read |
| الملف الشخصي | `ProfileScreen` | بيانات المستخدم، تسجيل الخروج |

---

## 5. البلوكات (Blocs)

| البلوك | الأحداث | الاستخدام |
|--------|---------|-----------|
| **ChildrenBloc** | ChildrenLoad, ChildrenAdd, ChildrenCredentialsShown | أطفالي، إضافة طفل، عرض بيانات الدخول للابن بعد الإنشاء |
| **CorrectionBloc** | LoadMyCorrections, CreateCorrectionRequest | طلباتي، إنشاء طلب تصحيح |
| **NotesBloc** | LoadNotesForChildren, MarkNoteRead, MarkAllNotesRead | ملاحظات المشرف |

---

## 6. صلاحيات قاعدة البيانات (RLS) — ملخص ولي الأمر

- **children:** قراءة وتعديل أطفالي فقط (`parent_id = user.id`).
- **attendance:** قراءة حضور أطفالي فقط (عبر سياسة تعتمد `mosque_children` و `children.parent_id`).
- **correction_requests:** INSERT لطلبات جديدة (parent_id = أنا)، SELECT لطلباتي.
- **notes:** قراءة ملاحظات أطفالي (child_id IN أطفالي).
- **competitions:** قراءة مسابقات مساجد أطفالي (RLS موجود — يمكن عرض ترتيب مسابقة للابن مستقبلاً).

---

## 7. قائمة إجراءات واحدة — ما يفعله ولي الأمر حرفياً

1. عرض الشاشة الرئيسية: ترحيب، حضور اليوم لأطفالي، إجراءات سريعة.
2. عرض قائمة أطفالي وإضافة طفل جديد (اختياري: إنشاء حساب للابن بإيميل وكلمة مرور).
3. فتح بطاقة طفل: عرض QR، كود الباركود، نسخ الكود.
4. ربط طفل بمسجد عبر كود المسجد (من بطاقة الطفل).
5. طلب تصحيح حضور: اختيار مسجد (من مساجد الطفل)، صلاة، تاريخ، ملاحظة، إرسال.
6. عرض طلبات التصحيح التي أرسلتها وحالتها (معلق، مقبول، مرفوض).
7. عرض ملاحظات المشرف لأطفالي وتحديثها كمقروءة.
8. عرض الملف الشخصي وتعديل الاسم وتحديث FCM token وتسجيل الخروج.
9. **(من ChildRepository — إن بُنيت شاشة)** عرض ملف الطفل الشامل: النقاط، الأيام، المستوى، سجل الحضور، تقرير أسبوعي/شهري.

---

## 8. ما لا يفعله ولي الأمر

- لا وصول لصفحات المسجد (إمام/مشرف).
- لا وصول لصفحات الإدارة (سوبر أدمن).
- لا وصول لشاشة الابن (`/child-view` — للابن فقط).
- لا إرسال ملاحظات (المشرف/الإمام يرسلون).
- لا موافقة/رفض طلبات التصحيح (المشرف/الإمام).

---

## 9. ملاحظات للبناء وإعادة الاستخدام

- **مصدر "أطفالي":** `ChildRepository.getMyChildren()` أو `ChildrenBloc` (ChildrenLoaded).
- **مصدر "حضور اليوم":** `ChildRepository.getAttendanceForMyChildren(DateTime.now())` — يمكن الاشتراك في Realtime للحضور عبر `RealtimeService.subscribeAttendanceForChildIds`.
- **ربط الطفل بمسجد:** يلزم كود المسجد (من مدير المسجد) — ولي الأمر يدخله في بطاقة الطفل.
- **طلب تصحيح:** يجب ربط الطفل بمسجد أولاً؛ يختار ولي الأمر من مساجد الطفل (getChildMosqueIds) ثم صلاة وتاريخ.
- **ملاحظات المشرف:** NotesBloc + LoadNotesForChildren(childIds) — childIds من getMyChildren.
- **ما يمكن نسخه من الإمام/المشرف:** تخطيط لوحة (شبكة، بطاقات)، أسلوب Drawer، أسلوب BottomNav؛ تعديل النصوص والمحتوى حسب ولي الأمر.

بهذا يكون كل ما يستطيع ولي الأمر فعله موثّقاً لاستخدامه عند بناء أو تحسين صفحات ولي الأمر.
