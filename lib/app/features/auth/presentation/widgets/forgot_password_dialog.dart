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

class _ForgotPasswordDialogContentState
    extends State<ForgotPasswordDialogContent> {
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

  String get _dialogTitle {
    switch (_step) {
      case 2:
        return 'أدخل الرمز';
      case 3:
        return 'كلمة المرور الجديدة';
      default:
        return AppStrings.resetPassword;
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
        title: Text(_dialogTitle),
        content: SingleChildScrollView(
          child: _buildCurrentStep(context),
        ),
        actions: [
          TextButton(onPressed: widget.onClose, child: const Text('إلغاء')),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_step) {
      case 1:
        return _ForgotStepEmail(
          emailCtrl: _emailCtrl,
          onEmailSent: (email) => setState(() => _email = email),
        );
      case 2:
        return _ForgotStepOtp(otpCtrl: _otpCtrl, email: _email);
      case 3:
        return _ForgotStepNewPassword(
          newPassCtrl: _newPassCtrl,
          confirmCtrl: _confirmCtrl,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ══════════════════════════════════════════════════════════════
// الخطوة 1 — إدخال البريد وإرسال الرمز
// ══════════════════════════════════════════════════════════════

class _ForgotStepEmail extends StatelessWidget {
  const _ForgotStepEmail({
    required this.emailCtrl,
    required this.onEmailSent,
  });

  final TextEditingController emailCtrl;
  final ValueChanged<String> onEmailSent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: emailCtrl,
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
                    final e = emailCtrl.text.trim();
                    if (e.isEmpty) return;
                    onEmailSent(e);
                    ctx.read<AuthBloc>().add(AuthResetPasswordRequested(email: e));
                  },
            child: state is AuthLoading
                ? const _LoadingIndicator()
                : const Text('إرسال الرمز'),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// الخطوة 2 — إدخال رمز OTP
// ══════════════════════════════════════════════════════════════

class _ForgotStepOtp extends StatelessWidget {
  const _ForgotStepOtp({required this.otpCtrl, required this.email});

  final TextEditingController otpCtrl;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'أدخل الرمز المُرسل إلى $email',
          style: const TextStyle(fontSize: 13, color: AppColors.textHint),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: otpCtrl,
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
                    final t = otpCtrl.text.trim();
                    if (t.length < 6) return;
                    ctx.read<AuthBloc>().add(
                          AuthVerifyResetOtpRequested(email: email, token: t),
                        );
                  },
            child: state is AuthLoading
                ? const _LoadingIndicator()
                : const Text('تحقق'),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// الخطوة 3 — إدخال كلمة المرور الجديدة
// ══════════════════════════════════════════════════════════════

class _ForgotStepNewPassword extends StatelessWidget {
  const _ForgotStepNewPassword({
    required this.newPassCtrl,
    required this.confirmCtrl,
  });

  final TextEditingController newPassCtrl;
  final TextEditingController confirmCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: newPassCtrl,
          label: 'كلمة المرور الجديدة',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: confirmCtrl,
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
                    final p = newPassCtrl.text;
                    final c = confirmCtrl.text;
                    final messenger = ScaffoldMessenger.of(context);
                    if (p.length < 6) {
                      messenger.showSnackBar(const SnackBar(
                        content: Text('كلمة المرور 6 أحرف على الأقل'),
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    if (p != c) {
                      messenger.showSnackBar(const SnackBar(
                        content: Text('كلمتا المرور غير متطابقتين'),
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    ctx.read<AuthBloc>().add(
                          AuthSetNewPasswordRequested(newPassword: p),
                        );
                  },
            child: state is AuthLoading
                ? const _LoadingIndicator()
                : const Text('حفظ كلمة المرور'),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// مؤشر تحميل مشترك
// ══════════════════════════════════════════════════════════════

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
