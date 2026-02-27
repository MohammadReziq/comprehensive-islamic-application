import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../injection_container.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// ═══════════════════════════════════════════════════════════════════
/// مكونات مشتركة للبروفايل — تُستخدم في كل البروفايلات المفصولة
/// ═══════════════════════════════════════════════════════════════════

// ─── ألوان كل دور ───
const _roleColors = <UserRole, Color>{
  UserRole.parent: Color(0xFF5C6BC0),
  UserRole.imam: Color(0xFF2E8B57),
  UserRole.supervisor: Color(0xFF1B5E8A),
  UserRole.superAdmin: Color(0xFF6A1B9A),
  UserRole.child: Color(0xFF00897B),
};

// ═══════════════════════════════════════════════════════════════════
/// Hero Section — Avatar + اسم + دور
// ═══════════════════════════════════════════════════════════════════
class ProfileHeroSection extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final UserRole role;

  const ProfileHeroSection({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = _roleColors[role] ?? const Color(0xFF2E8B57);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D2137),
            const Color(0xFF1B5E8A),
            accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : '؟',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  role.nameAr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          // الاسم
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
          // الإيميل — عرض فقط
          _buildInfoRow(
            icon: Icons.email_rounded,
            label: 'الإيميل',
            value: widget.email ?? '—',
          ),
          const Divider(height: 24),
          // الهاتف
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
          // تغيير كلمة المرور
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
                      Text(
                        'كلمة المرور',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
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
          // زر حفظ
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'حفظ التعديلات',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
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
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2B3C),
                ),
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
                    Text(
                      label,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2B3C),
                      ),
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
/// زر تسجيل الخروج
// ═══════════════════════════════════════════════════════════════════
class ProfileLogoutButton extends StatelessWidget {
  const ProfileLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 8),
            Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
/// زر حذف الحساب مع dialog التأكيد
// ═══════════════════════════════════════════════════════════════════
class ProfileDeleteAccountButton extends StatelessWidget {
  const ProfileDeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDeleteDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever_rounded,
                color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'حذف الحساب نهائياً',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final confirmCtrl = TextEditingController();
    bool deleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Icon(Icons.warning_rounded,
                    color: Colors.red.shade700, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'حذف الحساب نهائياً',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Text(
                    'سيُحذف حسابك وبيانات أبنائك وسجلات الحضور نهائياً.\nهذا الإجراء لا يمكن التراجع عنه.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'اكتب "حذف حسابي" للتأكيد:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  onChanged: (_) => setDlg(() {}),
                  decoration: InputDecoration(
                    hintText: 'حذف حسابي',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                onPressed:
                    (deleting || confirmCtrl.text.trim() != 'حذف حسابي')
                        ? null
                        : () async {
                            setDlg(() => deleting = true);
                            try {
                              await sl<AuthRepository>().deleteMyAccount();
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                context
                                    .read<AuthBloc>()
                                    .add(const AuthLogoutRequested());
                              }
                            } catch (e) {
                              setDlg(() => deleting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(e
                                        .toString()
                                        .replaceFirst('Exception: ', '')),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                child: deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('احذف حسابي'),
              ),
            ],
          ),
        ),
      ),
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
          if (state is AuthPasswordChangeSuccess) {
            widget.onSuccess();
          }
          if (state is AuthError) {
            setState(() => _loading = false);
          }
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
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
