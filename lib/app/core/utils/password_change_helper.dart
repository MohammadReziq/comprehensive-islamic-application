import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';

/// أداة لتذكير الإمام/المشرف بتغيير كلمة السر المؤقتة
class PasswordChangeHelper {
  static const _prefix = 'password_change_reminded_';

  /// هل يجب تذكير هذا المستخدم؟
  static Future<bool> shouldRemind(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_prefix$userId') ?? false);
  }

  /// حفظ أنه تم التذكير
  static Future<void> markReminded(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$userId', true);
  }

  /// عرض dialog التذكير
  static Future<void> showReminderDialog(
    BuildContext context, {
    required String userId,
    VoidCallback? onChangeNow,
  }) async {
    if (!await shouldRemind(userId)) return;

    await markReminded(userId);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline,
            color: AppColors.primaryDark, size: 40),
        title: const Text('تغيير كلمة السر'),
        content: const Text(
          'أنت تستخدم كلمة سر مؤقتة.\n'
          'ننصحك بتغييرها لكلمة سر قوية تختارها بنفسك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقاً'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              onChangeNow?.call();
            },
            icon: const Icon(Icons.lock_reset),
            label: const Text('تغيير الآن'),
          ),
        ],
      ),
    );
  }
}
