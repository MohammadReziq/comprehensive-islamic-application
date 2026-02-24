import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// شاشة إدخال رمز تفعيل البريد (بعد إنشاء الحساب)
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _resendCooldown = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onVerify() {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل الرمز المكوّن من 6 أرقام'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthVerifySignupCodeRequested(code));
  }

  void _onResend() {
    if (_resendCooldown) return;
    setState(() => _resendCooldown = true);
    context.read<AuthBloc>().add(const AuthResendSignupCodeRequested());
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) setState(() => _resendCooldown = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال رمز جديد إلى بريدك'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D2137),
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              final awaiting = state is AuthAwaitingEmailVerification;
              final email = awaiting ? state.email : '';
              final name = awaiting ? state.name : '';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      Icon(
                        Icons.mark_email_read_rounded,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'تفعيل حسابك',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name.isNotEmpty
                            ? 'أهلاً $name، أرسلنا رمزاً إلى $email'
                            : 'أرسلنا رمزاً إلى $email',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        controller: _codeCtrl,
                        label: 'رمز التفعيل (6 أرقام)',
                        hint: '••••••',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: state is AuthLoading ? 'جاري التحقق...' : 'تحقق',
                        onPressed: (state is AuthLoading) ? null : _onVerify,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _resendCooldown ? null : _onResend,
                        child: Text(
                          _resendCooldown
                              ? 'انتظر دقيقة قبل إعادة الإرسال'
                              : 'إعادة إرسال الرمز',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
