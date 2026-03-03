// مكونات مشتركة للبروفايل — barrel + ProfileInfoCard + ChangePasswordDialog

export 'profile_hero_section.dart';
export 'profile_action_buttons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

// ═══════════════════════════════════════════════════════════════════
/// بطاقة المعلومات — اسم + إيميل + هاتف + تغيير كلمة المرور
// ═══════════════════════════════════════════════════════════════════
class ProfileInfoCard extends StatefulWidget {
  final String userId;
  final String name;
  final String? email;
  final String? phone;

  const ProfileInfoCard({
    super.key,
    required this.userId,
    required this.name,
    this.email,
    this.phone,
  });

  @override
  State<ProfileInfoCard> createState() => _ProfileInfoCardState();
}

class _ProfileInfoCardState extends State<ProfileInfoCard> {
  bool _editingName = false;
  bool _editingPhone = false;
  bool _saving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _phoneCtrl = TextEditingController(text: widget.phone ?? '');
  }

  @override
  void didUpdateWidget(covariant ProfileInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editingName && oldWidget.name != widget.name) {
      _nameCtrl.text = widget.name;
    }
    if (!_editingPhone && oldWidget.phone != widget.phone) {
      _phoneCtrl.text = widget.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await sl<AuthRepository>().updateUserProfile(
        userId: widget.userId,
        name: _editingName ? _nameCtrl.text.trim() : null,
        phone: _editingPhone ? _phoneCtrl.text.trim() : null,
      );
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthCheckRequested());
      setState(() {
        _editingName = false;
        _editingPhone = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث البيانات'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ChangePasswordDialog(
        onSuccess: () => Navigator.pop(ctx),
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEditRow(
            icon: Icons.person_rounded,
            label: 'الاسم',
            value: widget.name,
            isEditing: _editingName,
            controller: _nameCtrl,
            onEdit: () => setState(() {
              _editingName = true;
              _nameCtrl.text = widget.name;
            }),
            onCancel: () => setState(() {
              _editingName = false;
              _nameCtrl.text = widget.name;
            }),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.email_rounded,
            label: 'الإيميل',
            value: widget.email ?? '—',
          ),
          const Divider(height: 24),
          _buildEditRow(
            icon: Icons.phone_rounded,
            label: 'الهاتف',
            value: widget.phone?.isNotEmpty == true ? widget.phone! : 'غير محدد',
            isEditing: _editingPhone,
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            onEdit: () => setState(() {
              _editingPhone = true;
              _phoneCtrl.text = widget.phone ?? '';
            }),
            onCancel: () => setState(() {
              _editingPhone = false;
              _phoneCtrl.text = widget.phone ?? '';
            }),
          ),
          const Divider(height: 24),
          GestureDetector(
            onTap: _showChangePasswordDialog,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('كلمة المرور',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        'تغيير كلمة المرور',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2B3C),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
          if (_editingName || _editingPhone) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'حفظ التعديلات',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2B3C)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController controller,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: label,
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    Text(
                      value,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2B3C)),
                    ),
                  ],
                ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isEditing ? onCancel : onEdit,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isEditing
                  ? Colors.red.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isEditing ? Icons.close_rounded : Icons.edit_rounded,
              size: 16,
              color: isEditing ? Colors.red : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
/// حوار تغيير كلمة المرور
// ═══════════════════════════════════════════════════════════════════
class ChangePasswordDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const ChangePasswordDialog({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final newPass = _newPassCtrl.text;
    final confirm = _confirmCtrl.text;
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور الجديدة 6 أحرف على الأقل'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمتا المرور غير متطابقتين'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    context.read<AuthBloc>().add(
          AuthChangePasswordFromProfileRequested(newPassword: newPass),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordChangeSuccess) widget.onSuccess();
          if (state is AuthError) setState(() => _loading = false);
        },
        child: AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newPassCtrl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _loading ? null : widget.onCancel,
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
