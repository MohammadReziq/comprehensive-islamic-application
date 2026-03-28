import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../parent/data/repositories/child_repository.dart';

/// دايلوج تعديل بيانات الابن (اسم + عمر)
class ChildEditDialog {
  static void show({
    required BuildContext context,
    required ChildModel child,
    required String childId,
    required VoidCallback onSaved,
  }) {
    final nameCtrl = TextEditingController(text: child.name);
    int age = child.age;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('تعديل بيانات الابن', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('العمر', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    _ageButton(
                      icon: Icons.remove_rounded,
                      enabled: age > 3,
                      onTap: () => setDlg(() => age--),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('$age', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    _ageButton(
                      icon: Icons.add_rounded,
                      enabled: age < 18,
                      onTap: () => setDlg(() => age++),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        setDlg(() => saving = true);
                        try {
                          await sl<ChildRepository>().updateChild(childId: childId, name: name, age: age);
                          if (ctx.mounted) Navigator.pop(ctx);
                          onSaved();
                        } catch (e) {
                          setDlg(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _ageButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF5F6FA) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: enabled ? const Color(0xFF1A2B3C) : Colors.grey.shade300, size: 18),
      ),
    );
  }
}
