import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../injection_container.dart';
import '../../data/repositories/child_repository.dart';

/// بيانات عنصر صحة الحساب
class HealthItem {
  final String label;
  final IconData icon;
  final bool ok;
  final String hint;
  final String? route;
  const HealthItem({required this.label, required this.icon, required this.ok, required this.hint, this.route});
}

/// قسم صحة الحساب لولي الأمر
class ParentAccountHealthSection extends StatefulWidget {
  final dynamic user;
  const ParentAccountHealthSection({super.key, required this.user});
  @override
  State<ParentAccountHealthSection> createState() => _ParentAccountHealthSectionState();
}

class _ParentAccountHealthSectionState extends State<ParentAccountHealthSection> {
  List<HealthItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  Future<void> _evaluate() async {
    final user = widget.user;
    final items = <HealthItem>[];

    final hasName = user.name.isNotEmpty && user.name != 'مستخدم جديد';
    items.add(HealthItem(label: 'الاسم', icon: Icons.person_rounded, ok: hasName, hint: hasName ? user.name : 'لم يُحدد بعد'));

    final authUser = Supabase.instance.client.auth.currentUser;
    final emailConfirmed = authUser?.emailConfirmedAt != null;
    items.add(HealthItem(label: 'البريد المفعّل', icon: Icons.email_rounded, ok: emailConfirmed, hint: emailConfirmed ? 'مفعّل ✓' : 'لم يتم التأكيد'));

    final hasPhone = user.phone != null && (user.phone as String).isNotEmpty;
    items.add(HealthItem(label: 'الهاتف', icon: Icons.phone_rounded, ok: hasPhone, hint: hasPhone ? user.phone : 'غير محدد'));

    try {
      final children = await sl<ChildRepository>().getMyChildren();
      final hasChildren = children.isNotEmpty;
      items.add(HealthItem(label: 'الأبناء', icon: Icons.child_care_rounded, ok: hasChildren, hint: hasChildren ? '${children.length} أبناء' : 'لا يوجد أبناء', route: hasChildren ? null : '/parent/children/add'));

      if (hasChildren) {
        final childIds = children.map((c) => c.id).toList();
        final linkedIds = await sl<ChildRepository>().getLinkedChildIds(childIds);
        final linked = linkedIds.length;
        final allLinked = linked == children.length;
        items.add(HealthItem(label: 'ربط بمسجد', icon: Icons.mosque_rounded, ok: allLinked, hint: allLinked ? 'كل الأبناء مرتبطون' : '$linked/${children.length} مرتبطون', route: allLinked ? null : '/parent/children'));
      }
    } catch (_) {
      items.add(const HealthItem(label: 'الأبناء', icon: Icons.child_care_rounded, ok: false, hint: 'خطأ في الجلب'));
    }

    if (mounted) setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]),
        child: const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final doneCount = _items.where((i) => i.ok).length;
    final total = _items.length;
    final progress = total > 0 ? doneCount / total : 0.0;
    final allDone = doneCount == total;
    final progressColor = allDone ? const Color(0xFF4CAF50) : doneCount >= total - 1 ? const Color(0xFFFFB300) : const Color(0xFFFF7043);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: progressColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.shield_rounded, color: progressColor, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('صحة الحساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
              Text('$doneCount/$total مكتمل', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ])),
            SizedBox(width: 40, height: 40, child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: progress, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(progressColor), strokeWidth: 4),
              Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: progressColor)),
            ])),
          ]),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(progressColor))),
          const SizedBox(height: 14),
          ..._items.map((item) => GestureDetector(
            onTap: item.route != null ? () => context.push(item.route!) : null,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: (item.ok ? const Color(0xFF4CAF50) : const Color(0xFFFF7043)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(item.ok ? Icons.check_rounded : Icons.close_rounded, size: 16, color: item.ok ? const Color(0xFF4CAF50) : const Color(0xFFFF7043))),
                const SizedBox(width: 10),
                Icon(item.icon, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(child: Text(item.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2B3C)))),
                Text(item.hint, style: TextStyle(fontSize: 11, color: item.ok ? Colors.grey.shade500 : const Color(0xFFFF7043), fontWeight: item.ok ? FontWeight.w400 : FontWeight.w600)),
                if (item.route != null) ...[const SizedBox(width: 4), const Icon(Icons.chevron_left, size: 16, color: Color(0xFFFF7043))],
              ]),
            ),
          )),
        ],
      ),
    );
  }
}
