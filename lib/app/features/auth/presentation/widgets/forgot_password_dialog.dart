import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// حوار نسيت كلمة المرور (3 خطوات: إرسال رمز → إدخال رمز → كلمة مرور جديدة).
class ForgotPasswordDialogContent extends StatefulWidget {
  const ForgotPasswordDialogContent({
    super.key,
    required this.initialEmail,
    required this.onClose,
  });

  final String initialEmail;
  final VoidCallback onClose;

  @override
  State<ForgotPasswordDialogContent> createState() =>
      _ForgotPasswordDialogContentState();
}

class _ForgotPasswordDialogContentState extends State<ForgotPasswordDialogContent> {
  int _step = 1;
  String _email = '';
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _emailCtrl,
              label: AppStrings.email,
              hint: 'example@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (ctx, state) => FilledButton(
                onPressed: state is AuthLoading
                    ? null
                    : () {
                        final e = _emailCtrl.text.trim();
                        if (e.isEmpty) return;
                        setState(() => _email = e);
                        ctx.read<AuthBloc>().add(
                              AuthResetPasswordRequested(email: e),
                            );
                      },
                child: state is AuthLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إرسال الرمز'),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدخل الرمز المُرسل إلى $_email',
              style: const TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _otpCtrl,
              label: 'الرمز',
              hint: '123456',
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (ctx, state) => FilledButton(
                onPressed: state is AuthLoading
                    ? null
                    : () {
                        final t = _otpCtrl.text.trim();
                        if (t.length < 6) return;
                        ctx.read<AuthBloc>().add(
                              AuthVerifyResetOtpRequested(email: _email, token: t),
                            );
                      },
                child: state is AuthLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('تحقق'),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _newPassCtrl,
              label: 'كلمة المرور الجديدة',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirmCtrl,
              label: 'تأكيد كلمة المرور',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (ctx, state) => FilledButton(
                onPressed: state is AuthLoading
                    ? null
                    : () {
                        final p = _newPassCtrl.text;
                        final c = _confirmCtrl.text;
                        if (p.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('كلمة المرور 6 أحرف على الأقل'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        if (p != c) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('كلمتا المرور غير متطابقتين'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        ctx.read<AuthBloc>().add(
                              AuthSetNewPasswordRequested(newPassword: p),
                            );
                      },
                child: state is AuthLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('حفظ كلمة المرور'),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthResetPasswordSent) setState(() => _step = 2);
        if (state is AuthResetOtpVerified) setState(() => _step = 3);
        if (state is AuthPasswordResetSuccess) widget.onClose();
        if (state is AuthError && _step > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AlertDialog(
        title: Text(
          _step == 1
              ? AppStrings.resetPassword
              : _step == 2
                  ? 'أدخل الرمز'
                  : 'كلمة المرور الجديدة',
        ),
        content: SingleChildScrollView(child: _buildStep(context)),
        actions: [
          TextButton(onPressed: widget.onClose, child: const Text('إلغاء')),
        ],
      ),
    );
  }
}
