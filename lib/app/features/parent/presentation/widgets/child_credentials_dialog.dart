import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

/// دايلوج بيانات دخول الابن بعد إنشائه
class ChildCredentialsDialog {
  static void show({
    required BuildContext context,
    required String email,
    required String password,
    required VoidCallback onDismiss,
  }) {
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.key_rounded, color: Color(0xFF2E8B57)),
                SizedBox(width: 8),
                Text('بيانات دخول الابن', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCC02)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFF57F17), size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('احتفظ بهذه البيانات — لن تظهر مرة أخرى',
                            style: TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _credRow('الإيميل', email),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 90,
                      child: Text('كلمة المرور', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2B3C))),
                    ),
                    Expanded(
                      child: Text(
                        obscurePassword ? '••••••••' : password,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D2137)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Clipboard.setData(ClipboardData(text: password)),
                      child: const Tooltip(message: 'نسخ', child: Icon(Icons.copy_rounded, size: 17, color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setDialogState(() => obscurePassword = !obscurePassword),
                      child: Icon(
                        obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 17, color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onDismiss();
                },
                child: const Text('فهمت، حفظتها'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _credRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2B3C))),
        ),
        Expanded(
          child: SelectableText(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D2137))),
        ),
        GestureDetector(
          onTap: () => Clipboard.setData(ClipboardData(text: value)),
          child: const Tooltip(message: 'نسخ', child: Icon(Icons.copy_rounded, size: 17, color: Colors.grey)),
        ),
      ],
    );
  }
}
