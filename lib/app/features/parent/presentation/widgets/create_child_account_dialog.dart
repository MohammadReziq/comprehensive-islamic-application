import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../data/repositories/child_repository.dart';
import 'child_credentials_dialog.dart';

/// دايلوج إنشاء حساب لابن موجود (بدون حساب)
class CreateChildAccountDialog {
  static void show({
    required BuildContext context,
    required String childId,
    required String childName,
    required VoidCallback onAccountCreated,
  }) {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool showPassword = false;
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_add_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'إنشاء حساب لـ $childName',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFF42A5F5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Color(0xFF1565C0), size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'سيتمكن الابن من تسجيل الدخول بهذه البيانات ومتابعة نقاطه',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('الإيميل',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2B3C))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'example@email.com',
                      prefixIcon:
                          const Icon(Icons.email_rounded, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('كلمة المرور',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2B3C))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon:
                          const Icon(Icons.lock_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                            showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20),
                        onPressed: () => setDialogState(
                            () => showPassword = !showPassword),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(error!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.of(ctx).pop(),
                child: Text('إلغاء',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        final password = passwordCtrl.text.trim();
                        if (email.isEmpty || password.isEmpty) {
                          setDialogState(
                              () => error = 'الرجاء ملء جميع الحقول');
                          return;
                        }
                        if (password.length < 6) {
                          setDialogState(() =>
                              error = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
                          return;
                        }
                        setDialogState(() {
                          loading = true;
                          error = null;
                        });
                        try {
                          final result = await sl<ChildRepository>()
                              .createAccountForChild(
                            childId: childId,
                            email: email,
                            password: password,
                          );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            // عرض بيانات الدخول
                            if (context.mounted) {
                              ChildCredentialsDialog.show(
                                context: context,
                                email: result.email ?? email,
                                password: result.password ?? password,
                                onDismiss: onAccountCreated,
                              );
                            }
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setDialogState(() {
                              loading = false;
                              error = e
                                  .toString()
                                  .replaceFirst('Exception: ', '');
                            });
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                    : const Text('إنشاء الحساب',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
