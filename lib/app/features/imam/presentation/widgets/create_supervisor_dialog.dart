import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/password_generator.dart';
import '../../../../core/utils/share_credentials.dart';
import '../../data/repositories/imam_repository.dart';
import '../../../../injection_container.dart';

/// Dialog لإنشاء حساب مشرف جديد — يظهر من شاشة الإمام
class CreateSupervisorDialog extends StatefulWidget {
  final String mosqueId;
  final String mosqueName;

  const CreateSupervisorDialog({
    super.key,
    required this.mosqueId,
    required this.mosqueName,
  });

  @override
  State<CreateSupervisorDialog> createState() => _CreateSupervisorDialogState();
}

class _CreateSupervisorDialogState extends State<CreateSupervisorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _passCtrl.text = PasswordGenerator.generateSupervisorPassword();
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
      _passCtrl.text = PasswordGenerator.generateSupervisorPassword();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      await sl<ImamRepository>().createSupervisorAccount(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        tempPassword: _passCtrl.text.trim(),
        mosqueId: widget.mosqueId,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // true = تم الإنشاء بنجاح
        _showSuccessDialog(
          context,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim().toLowerCase(),
          password: _passCtrl.text.trim(),
          mosqueName: widget.mosqueName,
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
          Icon(Icons.supervisor_account, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text('إضافة مشرف جديد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mosque, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.mosqueName,
                          style: GoogleFonts.cairo(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المشرف',
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
          label: Text(_loading ? 'جارٍ الإنشاء...' : 'إضافة المشرف'),
        ),
      ],
    );
  }

  static void _showSuccessDialog(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
    required String mosqueName,
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
            Expanded(
              child: Text('تم إضافة المشرف',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
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
                '⚠ شارك هذه البيانات مع المشرف فوراً. لن تظهر مرة أخرى.',
                style: GoogleFonts.cairo(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              final msg = ShareCredentials.buildSupervisorMessage(
                name: name,
                email: email,
                password: password,
                mosqueName: mosqueName,
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
              final msg = ShareCredentials.buildSupervisorMessage(
                name: name,
                email: email,
                password: password,
                mosqueName: mosqueName,
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
