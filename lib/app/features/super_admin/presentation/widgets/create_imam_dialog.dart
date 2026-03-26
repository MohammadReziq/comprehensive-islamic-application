import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/password_generator.dart';
import '../../../../core/utils/share_credentials.dart';
import '../../data/repositories/admin_repository.dart';
import '../../../../injection_container.dart';

/// Dialog لإنشاء حساب إمام جديد — يظهر من شاشة السوبر أدمن
class CreateImamDialog extends StatefulWidget {
  const CreateImamDialog({super.key});

  @override
  State<CreateImamDialog> createState() => _CreateImamDialogState();
}

class _CreateImamDialogState extends State<CreateImamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _passCtrl.text = PasswordGenerator.generateImamPassword();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _regeneratePassword() {
    setState(() {
      _passCtrl.text = PasswordGenerator.generateImamPassword();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      await sl<AdminRepository>().createImamAccount(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        tempPassword: _passCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessDialog(
          context,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim().toLowerCase(),
          password: _passCtrl.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.person_add, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Text('إنشاء حساب إمام جديد',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
                  if (v.trim().length < 2) return 'حرفين على الأقل';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'البريد مطلوب';
                  final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                  if (!regex.hasMatch(v.trim())) return 'صيغة بريد غير صحيحة';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                decoration: InputDecoration(
                  labelText: 'كلمة السر',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'توليد كلمة سر جديدة',
                    onPressed: _regeneratePassword,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'كلمة السر مطلوبة';
                  if (v.trim().length < 6) return '6 أحرف على الأقل';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                '⚠ سيتم إرسال البيانات للإمام عبر واتساب أو النسخ',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(_loading ? 'جارٍ الإنشاء...' : 'إنشاء الحساب'),
        ),
      ],
    );
  }

  static void _showSuccessDialog(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 8),
            Text('تم إنشاء الحساب بنجاح',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _credRow('الاسم', name),
            _credRow('البريد', email),
            _credRow('كلمة السر', password),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠ احفظ هذه البيانات أو شاركها فوراً. لن تظهر مرة أخرى.',
                style: GoogleFonts.cairo(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              final msg = ShareCredentials.buildImamMessage(
                name: name,
                email: email,
                password: password,
              );
              ShareCredentials.copyToClipboard(msg);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('تم النسخ ✅')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('نسخ'),
          ),
          TextButton.icon(
            onPressed: () {
              final msg = ShareCredentials.buildImamMessage(
                name: name,
                email: email,
                password: password,
              );
              ShareCredentials.shareViaWhatsApp(msg);
            },
            icon: Icon(Icons.share, color: Colors.green.shade700),
            label: Text('واتساب',
                style: TextStyle(color: Colors.green.shade700)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  static Widget _credRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.cairo(fontSize: 14),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
