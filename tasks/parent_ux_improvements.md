# خطة تحسين تجربة ولي الأمر والطالب
## منطق العرض + Real-time + المسجد المتعدد + المشرف المتعدد

---

## الإشكاليات المكتشفة في الكود الحالي

| # | الإشكالية | الملف | الحالة |
|---|-----------|-------|--------|
| 1 | كل مسجد يُربط كـ `type=primary` حتى لو كان ثانياً | `child_repository.dart:134` | ❌ مكسور |
| 2 | المشرف في أكثر من مسجد → السكانر يختار الأول تلقائياً | `scanner_screen.dart:38` | ❌ خطأ منطقي |
| 3 | زر "طلب تصحيح" يظهر دائماً حتى بدون مسابقة | `home_screen.dart:825` | ❌ غير منطقي |
| 4 | `RealtimeService` موجود ومكتمل لكن غير مفعّل في أي شاشة | `realtime_service.dart` | ❌ غير مستخدم |
| 5 | شاشة "طلبات التصحيح" فارغة (placeholder بـ TODO) | `my_corrections_screen.dart:25` | ❌ placeholder |
| 6 | نموذج طلب التصحيح لا يظهر نوع المسجد (أساسي/إضافي) | `request_correction_screen.dart` | ⚠️ ناقص |

---

## التغييرات السبعة المطلوبة

---

### التغيير 1 — إصلاح نوع المسجد عند الربط
**الملف:** `lib/app/features/parent/data/repositories/child_repository.dart`

**المشكلة الحالية:**
```dart
// السطر 134 — دائماً primary حتى لو ثاني مسجد!
'type': MosqueType.primary.value,
```

**الإصلاح:**
```dart
// تحديد النوع تلقائياً: الأول أساسي، ما بعده إضافي
final existingIds = await getChildMosqueIds(childId);
if (existingIds.contains(mosque.id)) {
  throw Exception('الابن مرتبط بهذا المسجد مسبقاً');
}
final mosqueType = existingIds.isEmpty ? MosqueType.primary : MosqueType.secondary;

await supabase.from('mosque_children').insert({
  'mosque_id':    mosque.id,
  'child_id':     childId,
  'type':         mosqueType.value,  // ✅ primary أو secondary
  'local_number': next,
  'is_active':    true,
});
```

---

### التغيير 2 — عرض نوع المسجد في نموذج طلب التصحيح
**الملفات:**
- `lib/app/features/parent/data/repositories/child_repository.dart` (دالة جديدة)
- `lib/app/features/parent/presentation/screens/request_correction_screen.dart`

**دالة جديدة في child_repository.dart:**
```dart
/// مساجد الابن مع النوع (أساسي/إضافي)
Future<List<({String mosqueId, MosqueType type})>> getChildMosquesWithType(
  String childId,
) async {
  final res = await supabase
      .from('mosque_children')
      .select('mosque_id, type')
      .eq('child_id', childId)
      .eq('is_active', true);
  return (res as List).map((e) => (
    mosqueId: e['mosque_id'] as String,
    type: MosqueType.fromString(e['type'] as String),
  )).toList();
}
```

**في request_correction_screen.dart — الـ DropdownMenuItem:**
```dart
// قبل: Text(m.name)
// بعد: Text("${m.name} (${mosqueType.nameAr})")
// مثال: "مسجد النور (أساسي)" أو "مسجد الفجر (إضافي)"
```

---

### التغيير 3 — منتقي مسجد للمشرف المتعدد
**الملف:** `lib/app/features/supervisor/presentation/screens/scanner_screen.dart`

**المشكلة الحالية:** يختار أول مسجد معتمد تلقائياً بغض النظر عن عدد المساجد.

**الإصلاح:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final mosqueState = context.read<MosqueBloc>().state;
    if (mosqueState is! MosqueLoaded) return;
    final approved = mosqueState.mosques
        .where((m) => m.status == MosqueStatus.approved)
        .toList();

    if (approved.length > 1) {
      _showMosquePicker(approved);     // ← جديد: BottomSheet للاختيار
    } else if (approved.length == 1) {
      _loadForMosque(approved.first);  // ← كما الحال
    }
  });
}

void _showMosquePicker(List<MosqueModel> mosques) {
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                'اختر المسجد لهذه الجلسة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            ...mosques.map((m) => ListTile(
              leading: const Icon(Icons.mosque_rounded, color: Color(0xFF2E8B57)),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: m.address != null ? Text(m.address!) : null,
              onTap: () {
                Navigator.pop(context);
                _loadForMosque(m);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
```

> **ملاحظة:** يلزم إعادة تسمية `_loadIfNeeded()` الحالية إلى `_loadForMosque(MosqueModel mosque)` لتقبل مسجداً محدداً.

---

### التغيير 4 — إظهار "طلب تصحيح" فقط أثناء المسابقة النشطة
**الملف:** `lib/app/features/parent/presentation/screens/home_screen.dart`

**في `_buildActionsGrid()`:**
```dart
final actions = [
  _Action(Icons.child_care_rounded, 'أبنائي', const Color(0xFF5C8BFF),
      () => context.push('/parent/children')),
  _Action(Icons.person_add_rounded, 'إضافة ابن', const Color(0xFF4CAF50),
      () => context.push('/parent/children/add')),

  // ✅ يظهر فقط أثناء المسابقة النشطة
  if (_competitionStatus == CompetitionStatus.running)
    _Action(Icons.edit_note_rounded, 'طلب تصحيح', const Color(0xFF9C27B0),
        () => context.push('/parent/corrections')),

  _Action(Icons.forum_rounded, 'الرسائل', const Color(0xFF00BCD4),
      () async { await context.push('/parent/inbox'); _loadUnreadCount(); },
      badge: _unreadCount),
];
```

---

### التغيير 5 — تفعيل Real-time في home_screen.dart (ولي الأمر)
**الملف:** `lib/app/features/parent/presentation/screens/home_screen.dart`

**الخطوات:**

1. إضافة imports:
```dart
import '../../../../core/services/realtime_service.dart';
```

2. إضافة متغيرات:
```dart
bool _realtimeSubscribed = false;
List<ChildModel> _latestChildren = [];
```

3. في BlocListener — تفعيل Realtime مرة واحدة:
```dart
listener: (context, state) {
  if (state is ChildrenLoaded || state is ChildrenLoadedWithCredentials) {
    final children = state is ChildrenLoaded
        ? state.children
        : (state as ChildrenLoadedWithCredentials).children;
    _latestChildren = children;
    _loadTodayAttendance(children);
    if (!_animController.isCompleted) _animController.forward();
    if (!_realtimeSubscribed && children.isNotEmpty) {
      _startRealtime(children.map((c) => c.id).toList());
    }
    if (state is ChildrenLoadedWithCredentials) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCredentialsDialog(context, state.email, state.password);
      });
    }
  }
},
```

4. دالة `_startRealtime()` الجديدة:
```dart
void _startRealtime(List<String> childIds) {
  _realtimeSubscribed = true;

  // عند تسجيل حضور لأي ابن → تحديث قائمة حضور اليوم فوراً
  sl<RealtimeService>().subscribeAttendanceForChildIds(childIds, (_) {
    if (!mounted) return;
    _loadTodayAttendance(_latestChildren);
  });

  // عند وصول ملاحظة جديدة → تحديث عداد "الرسائل" فوراً
  sl<RealtimeService>().subscribeNotesForChildren(childIds, (_) {
    if (!mounted) return;
    _loadUnreadCount();
  });
}
```

5. في `dispose()`:
```dart
@override
void dispose() {
  _countdownTimer?.cancel();
  _hadithTimer?.cancel();
  _animController.dispose();
  sl<RealtimeService>().unsubscribeAttendance();   // ← جديد
  sl<RealtimeService>().unsubscribeNotes();         // ← جديد
  super.dispose();
}
```

---

### التغيير 6 — تفعيل Real-time في child_view_screen.dart (الابن)
**الملف:** `lib/app/features/parent/presentation/screens/child_view_screen.dart`

**الخطوات:**

1. imports:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/realtime_service.dart';
```

2. في `_load()` بعد النجاح:
```dart
if (mounted) {
  setState(() { _child = child; _todayAttendance = today; _loading = false; });
  _animController.forward();
  _subscribeRealtime(); // ← جديد
}
```

3. دالتان جديدتان:
```dart
void _subscribeRealtime() {
  if (_child == null) return;
  sl<RealtimeService>().subscribeAttendanceForChildIds([_child!.id], (payload) {
    if (!mounted) return;
    _reloadAttendanceWithCelebration(payload);
  });
}

Future<void> _reloadAttendanceWithCelebration(PostgresChangePayload payload) async {
  final updated = await sl<ChildRepository>().getAttendanceForChildOnDate(
    _child!.id, DateTime.now(),
  );
  if (!mounted) return;
  setState(() => _todayAttendance = updated);

  if (payload.eventType == PostgresChangeEvent.insert) {
    final points = payload.newRecord['points_earned'] as int? ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم تسجيل حضورك! +$points نقطة'),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

4. في `dispose()`:
```dart
@override
void dispose() {
  _animController.dispose();
  sl<RealtimeService>().unsubscribeAttendance(); // ← جديد
  super.dispose();
}
```

---

### التغيير 7 — إصلاح my_corrections_screen.dart (إزالة placeholder)
**الملف:** `lib/app/features/parent/presentation/screens/my_corrections_screen.dart`

**الإصلاح الكامل:**
```dart
// imports جديدة
import '../../../../injection_container.dart';
import '../../../../models/correction_request_model.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../corrections/data/repositories/correction_repository.dart';

// تغيير النوع
List<CorrectionRequestModel> _corrections = [];

// إصلاح _load()
Future<void> _load() async {
  setState(() => _loading = true);
  try {
    final list = await sl<CorrectionRepository>().getMyRequests();
    if (mounted) setState(() { _corrections = list; _loading = false; });
  } catch (_) {
    if (mounted) setState(() => _loading = false);
  }
}

// build() — إضافة RefreshIndicator
body: RefreshIndicator(
  onRefresh: _load,
  child: CustomScrollView(...)
),

// _buildCorrectionCard() — استخدام النموذج الحقيقي
Widget _buildCorrectionCard(CorrectionRequestModel c) {
  const prayerNames = {
    'fajr': 'الفجر', 'dhuhr': 'الظهر',
    'asr': 'العصر', 'maghrib': 'المغرب', 'isha': 'العشاء',
  };
  final statusColors = {
    CorrectionStatus.pending:  const Color(0xFFFFB300),
    CorrectionStatus.approved: const Color(0xFF4CAF50),
    CorrectionStatus.rejected: const Color(0xFFE53935),
  };
  final statusLabels = {
    CorrectionStatus.pending:  'معلق',
    CorrectionStatus.approved: 'مقبول',
    CorrectionStatus.rejected: 'مرفوض',
  };
  final color   = statusColors[c.status] ?? const Color(0xFFFFB300);
  final label   = statusLabels[c.status] ?? 'معلق';
  final prayer  = prayerNames[c.prayer.value] ?? c.prayer.value;
  final dateStr = '${c.prayerDate.year}/${c.prayerDate.month.toString().padLeft(2,'0')}/${c.prayerDate.day.toString().padLeft(2,'0')}';
  // ... نفس تصميم البطاقة لكن بالبيانات الحقيقية
}
```

---

## ملخص تسلسل التنفيذ

| # | الملف | وقت التنفيذ |
|---|-------|-------------|
| 1 | `child_repository.dart` — إصلاح نوع المسجد + دالة `getChildMosquesWithType` | سريع |
| 2 | `my_corrections_screen.dart` — إزالة placeholder | سريع |
| 3 | `home_screen.dart` — competition-conditional + Realtime | متوسط |
| 4 | `child_view_screen.dart` — Realtime + احتفال | متوسط |
| 5 | `scanner_screen.dart` — منتقي مسجد للمشرف المتعدد | متوسط |
| 6 | `request_correction_screen.dart` — عرض نوع المسجد | سريع |

---

## قائمة تحقق بعد التنفيذ

- [ ] ربط ابن بمسجد ثانٍ → يُخزَّن كـ `secondary`
- [ ] ربط ابن بنفس المسجد مرتين → خطأ واضح "الابن مرتبط مسبقاً"
- [ ] نموذج طلب التصحيح يعرض `"مسجد النور (أساسي)"` و`"مسجد الفجر (إضافي)"`
- [ ] مشرف في مسجد واحد → السكانر يعمل تلقائياً كما الحال
- [ ] مشرف في مسجدين → BottomSheet يسأله أي مسجد
- [ ] `"طلب تصحيح"` يختفي من home عند `no_competition` / `upcoming` / `finished`
- [ ] `"طلب تصحيح"` يظهر فقط عند `running`
- [ ] شاشة "طلبات التصحيح" تعرض بيانات حقيقية + RefreshIndicator
- [ ] تسجيل حضور لابن → يظهر في home فوراً (بدون سحب للتحديث)
- [ ] وصول ملاحظة للأهل → عداد "الرسائل" يزداد فوراً
- [ ] شاشة الابن: عند تسجيل حضوره → يظهر فوراً + SnackBar احتفالية

---

## ما هو خارج النطاق (للمستقبل)

1. **مؤشر مصدر الحضور** (مسجد مباشر vs تصحيح مقبول): يحتاج عمود `source` جديد في جدول `attendance` (migration في Supabase).
2. **مسابقات متعددة**: إذا كان الابن في مسجدين ولكل مسابقة نشطة → لوحة صدارة منفصلة لكل مسجد.
3. **Push Notifications**: عند قبول/رفض طلب التصحيح → إشعار للوالد (تفعيل `firebase_messaging`).
