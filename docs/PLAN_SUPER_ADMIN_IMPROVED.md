# خطة السوبر أدمن المحسّنة — صلاتي حياتي

خطة تنفيذية واحدة لصفحة سوبر أدمن متكاملة. تحل محل شاشة طلبات المساجد الحالية بصفة تبويب واحد داخل لوحة كاملة.

---

## ما الموجود ولا يُغيّر

| المكوّن | الموجود |
|--------|---------|
| **AdminRepository** | getSystemStats، getAllMosques(status)، suspendMosque، reactivateMosque، getAllUsers(role, limit, offset)، updateUserRole، banUser (يغيّر الدور لـ parent)، changeImam |
| **AdminBloc** | LoadSystemStats، LoadAllMosques(status)، SuspendMosque، ReactivateMosque، LoadAllUsers(role)، UpdateUserRole، ChangeImam — **لا يوجد حدث BanUser** |
| **AdminState** | SystemStatsLoaded(stats)، MosquesLoaded(mosques)، UsersLoaded(users)، AdminActionSuccess، AdminError |
| **MosqueBloc** (للموافقة/الرفض) | MosqueApproveRequest(mosqueId)، MosqueRejectRequest(mosqueId) |
| **RLS** | السوبر أدمن يصل للمساجد والمستخدمين عبر سياسات موجودة |

---

## التعديل الأدنى المطلوب (إن رغبت زر "حظر" يعمل)

- **AdminBloc + AdminEvent:** إضافة حدث واحد فقط: `BanUser(userId)` يستدعي `_repo.banUser(event.userId)` ويصدر `AdminActionSuccess('تم حظر المستخدم')`.
- **ملاحظة:** `banUser` حالياً يغيّر الدور لـ parent فقط (لا عمود `is_banned` في DB). إن أردت حظراً حقيقياً لاحقاً تضيف migration لـ `users.is_banned` وتعدّل الـ Repository.

---

## الهيكل المطلوب للشاشة

- **ملف واحد:** `lib/app/features/super_admin/presentation/screens/admin_screen.dart`.
- **المسار:** يستبدل الشاشة الحالية على `/admin` — أي أن الـ route يبقى `/admin` ويُربط بـ `AdminScreen` بدل `AdminMosqueRequestsScreen`.
- **Scaffold:** اتجاه RTL، `BottomNavigationBar` بأربع عناصر: المساجد | المستخدمون | الإحصائيات | ملفي.
- **IndexedStack** للتبديل بين محتوى التبويبات (بدون إعادة بناء كاملة).

---

## تبويب 1 — المساجد

**الاستدعاءات:**
- عند فتح التبويب أو اختيار فلتر: `AdminBloc.add(LoadAllMosques(status: _selectedStatus))` حيث `_selectedStatus` من الـ FilterChip (null = الكل، pending، approved، rejected).
- موافقة على طلب: `MosqueBloc.add(MosqueApproveRequest(mosqueId))`.
- رفض طلب: `MosqueBloc.add(MosqueRejectRequest(mosqueId))`.
- تعليق مسجد (من حالة approved): `AdminBloc.add(SuspendMosque(mosqueId))`.
- إعادة تفعيل (من حالة rejected): `AdminBloc.add(ReactivateMosque(mosqueId))`.

**الواجهة:**
- صف FilterChip أفقي: **الكل** | **قيد المراجعة** | **مفعّل** | **موقوف** (الموقوف = status rejected).
- قائمة بطاقات: كل بطاقة تعرض (اسم المسجد، العنوان، تاريخ الإنشاء، عدد الأعضاء، عدد الطلاب إن أمكن، اسم الإمام إن أمكن).
- **حسب الحالة:**
  - **pending:** أزرار "موافقة" و "رفض" فقط (عبر MosqueBloc).
  - **approved:** زر "تعليق" (AdminBloc SuspendMosque).
  - **rejected:** زر "إعادة تفعيل" (AdminBloc ReactivateMosque).
- عند النقر على البطاقة: `showModalBottomSheet` يعرض كل تفاصيل المسجد (من الـ model أو حقول إضافية من الـ repo إن وُجدت).
- **تغيير إمام:** إن وُجد في الـ BottomSheet حقل لاختيار مستخدم جديد كإمام، استدعاء `AdminBloc.add(ChangeImam(mosqueId, newOwnerId))`.

**الحالات:**
- Loading: مؤشر تحميل.
- MosquesLoaded: عرض القائمة أو "لا توجد مساجد" إن كانت القائمة فارغة.
- AdminError / MosqueError: SnackBar بالرسالة.

---

## تبويب 2 — المستخدمون

**الاستدعاءات:**
- عند فتح التبويب أو تغيير الفلتر: `AdminBloc.add(LoadAllUsers(role: _selectedRole))` مع `_selectedRole` من الـ FilterChip (null = الكل، parent، imam، supervisor، child).
- تغيير الدور: حوار يختار فيه المستخدم الدور الجديد ثم `AdminBloc.add(UpdateUserRole(userId, newRole))`.
- حظر: إن أضفت حدث `BanUser` → `AdminBloc.add(BanUser(userId))`، وإلا أخفِ الزر أو اعرض "قريباً".

**الواجهة:**
- حقل بحث (اختياري): فلترة **على القائمة المحمّلة فقط** (اسم أو إيميل) — لا استعلام جديد؛ الـ repo يعيد حداً (مثلاً 100) والفلترة من جانب العميل.
- صف FilterChip: **الكل** | **أولياء أمور** | **أئمة** | **مشرفون** | **أطفال**.
- قائمة بطاقات: (الاسم، الإيميل، الدور، تاريخ التسجيل).
- كل بطاقة: زر "تغيير الدور" (حوار → UpdateUserRole)، وزر "حظر" (إن وُجد BanUser).

**الحالات:**
- Loading، UsersLoaded، AdminError — نفس أسلوب المساجد.

---

## تبويب 3 — الإحصائيات

**الاستدعاء:**
- عند فتح التبويب: `AdminBloc.add(LoadSystemStats())`.

**الواجهة:**
- عند `SystemStatsLoaded`: عرض شبكة 2×3 (أو أكثر) بأرقام كبيرة:
  - إجمالي المساجد
  - المساجد المفعّلة (approved)
  - قيد المراجعة (pending)
  - المساجد الموقوفة (rejected) = `total_mosques - approved_mosques - pending_mosques`
  - إجمالي المستخدمين
  - إجمالي الأطفال
  - حضور اليوم (today_attendance)
- كل رقم في بطاقة مع أيقونة ولون مميز (استخدم AppColors).
- Loading و AdminError كالعادة.

---

## تبويب 4 — ملفي

- عرض اسم المستخدم الحالي (من AuthBloc أو من profile).
- زر "تسجيل الخروج" → `AuthBloc.add(AuthLogoutRequested())`.
- بدون استدعاء AdminBloc.

---

## القواعد الصارمة

1. **لا تعديل في AdminRepository أو في توقيعات أحداث/حالات AdminBloc الحالية** — ما عدا إضافة حدث واحد اختياري: `BanUser`.
2. استخدام **AppColors** و **AppDimensions** واتجاه **RTL** في كل الواجهة.
3. **BlocConsumer** حيث تحتاج استماعاً (نجاح/خطأ) وعرضاً (قوائم، إحصائيات).
4. رسائل الخطأ والنجاح عبر **SnackBar** (behavior: floating).
5. مؤشر تحميل عند **AdminLoading** أو **MosqueLoading** حيث يناسب.
6. **Router:** استبدال الـ builder الحالي لـ `/admin` ليعيد `AdminScreen()` (مع توفير AdminBloc و MosqueBloc إن لم يكونا متوفرين من الأعلى).

---

## التبعيات في الـ Router

- الصفحة تحتاج **AdminBloc** و **MosqueBloc** (للموافقة/الرفض في تبويب المساجد).
- إن لم يكن الـ router يوفر الاثنين، استخدم **MultiBlocProvider** أو تأكد أن الأب يوفرها عند المسار `/admin`.

---

## اختبار قبول (جملة واحدة لكل تبويب)

- **المساجد:** السوبر أدمن يختار "قيد المراجعة"، يرى قائمة الطلبات، يضغط موافقة على مسجد فيصبح معتمداً ويختفي من قائمة قيد المراجعة.
- **المستخدمون:** السوبر أدمن يختار "أئمة"، يرى قائمة، يغيّر دور مستخدم إلى "مشرف" فيتحدّث العرض ويظهر رسالة نجاح.
- **الإحصائيات:** عند فتح التبويب تظهر ستة أرقام على الأقل (مساجد، مستخدمون، أطفال، حضور اليوم، إلخ) دون خطأ.
- **ملفي:** الضغط على تسجيل الخروج يخرج المستخدم من التطبيق.

---

## ما لن يُبنى في هذه المرحلة

- **عمود is_banned في users:** الحظر الحالي = تغيير الدور (أو عدم تنفيذ حظر حتى إضافة الحدث).
- **سجل تدقيق (audit_log):** لا جدول ولا واجهة في هذه الخطة.
- **عمود suspended_at في mosques:** التعليق = تغيير status فقط؛ لا حاجة لتاريخ في هذه المرحلة.

---

## ملخص للمطور (Cursor)

- إنشاء **AdminScreen** واحدة بأربعة تبويبات كما وُصفت.
- ربط المسار `/admin` بـ **AdminScreen** بدل **AdminMosqueRequestsScreen**.
- استخدام **AdminBloc** و **AdminState** و **AdminEvent** كما هي (مع إضافة **BanUser** اختيارياً).
- استخدام **MosqueBloc** لـ MosqueApproveRequest و MosqueRejectRequest في تبويب المساجد فقط.
- عدم تعديل **AdminRepository** أو **AdminState** أو أحداث **AdminBloc** الأخرى.
- الالتزام بـ RTL و AppColors و SnackBar للأخطاء والنجاح.
