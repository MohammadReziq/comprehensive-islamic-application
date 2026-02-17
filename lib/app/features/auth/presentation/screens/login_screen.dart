import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// شاشة تسجيل الدخول
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    _forgotEmailController.text = _emailController.text.trim();
    showDialog(
      context: context,
      builder: (ctx) => _ForgotPasswordDialogContent(
        initialEmail: _forgotEmailController.text.trim(),
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              final role = state.userProfile?.role;
              if (role == null) return; // منع التوجيه إذا لم تكتمل البيانات

              if (role == UserRole.superAdmin) {
                context.go('/admin');
              } else if (role == UserRole.imam || role == UserRole.supervisor) {
                context.go('/mosque');
              } else {
                context.go('/home');
              }
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
              );
            } else if (state is AuthResetPasswordSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'تم إرسال رمز إلى بريدك. أدخل الرمز في النافذة.',
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
              );
            } else if (state is AuthPasswordResetSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'تم تغيير كلمة المرور بنجاح. سجّل دخولك بكلمة السر الجديدة.',
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
              );
              context.read<AuthBloc>().add(const AuthResetPasswordFlowFinished());
            }
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.paddingXXL),

                    // ─── Header ───
                    const Text('🕌', style: TextStyle(fontSize: 56))
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          curve: Curves.elasticOut,
                          duration: 800.ms,
                        ),

                    const SizedBox(height: AppDimensions.spacingMD),

                    Text(
                      AppStrings.appName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: AppDimensions.spacingSM),

                    Text(
                      AppStrings.login,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: AppDimensions.paddingXL),

                    // ─── Form Card ───
                    Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingMD,
                          ),
                          padding: const EdgeInsets.all(
                            AppDimensions.paddingLG,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusXL,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ─── البريد الإلكتروني ───
                                AppTextField(
                                  controller: _emailController,
                                  label: AppStrings.email,
                                  hint: 'example@email.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textDirection: TextDirection.ltr,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppStrings.errorFieldRequired;
                                    }
                                    if (!value.contains('@')) {
                                      return AppStrings.errorInvalidEmail;
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: AppDimensions.spacingLG),

                                // ─── كلمة المرور ───
                                AppTextField(
                                  controller: _passwordController,
                                  label: AppStrings.password,
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  textDirection: TextDirection.ltr,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textHint,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppStrings.errorFieldRequired;
                                    }
                                    if (value.length < 6) {
                                      return AppStrings.errorWeakPassword;
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: AppDimensions.spacingSM),

                                // ─── نسيت كلمة المرور ───
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    child: const Text(
                                      AppStrings.forgotPassword,
                                      style: TextStyle(
                                        color: AppColors.primaryLight,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: AppDimensions.spacingLG),

                                // ─── زر تسجيل الدخول ───
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isLoading = state is AuthLoading;
                                    return AppButton(
                                      text: AppStrings.login,
                                      onPressed: isLoading ? null : _onLogin,
                                      isLoading: isLoading,
                                    );
                                  },
                                ),

                                const SizedBox(height: AppDimensions.spacingLG),

                                // ─── خط فاصل ───
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(color: AppColors.border),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.paddingMD,
                                      ),
                                      child: Text(
                                        AppStrings.orLoginWith,
                                        style: TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(color: AppColors.border),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: AppDimensions.spacingLG),

                                // ─── زر Google ───
                                OutlinedButton.icon(
                                  onPressed: () {
                                    context.read<AuthBloc>().add(const AuthLoginWithGoogleRequested());
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppDimensions.paddingMD,
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusMD,
                                      ),
                                    ),
                                  ),
                                  icon: const Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  label: const Text(
                                    AppStrings.loginWithGoogle,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOut),

                    const SizedBox(height: AppDimensions.spacingXL),

                    // ─── رابط إنشاء حساب ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.dontHaveAccount,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text(
                            AppStrings.register,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: AppDimensions.paddingLG),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// حوار نسيت كلمة المرور — خطوات: إيميل → رمز OTP → كلمة سر جديدة
class _ForgotPasswordDialogContent extends StatefulWidget {
  final String initialEmail;
  final VoidCallback onClose;

  const _ForgotPasswordDialogContent({
    required this.initialEmail,
    required this.onClose,
  });

  @override
  State<_ForgotPasswordDialogContent> createState() => _ForgotPasswordDialogContentState();
}

class _ForgotPasswordDialogContentState extends State<_ForgotPasswordDialogContent> {
  int _step = 1;
  String _email = '';
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildContent(BuildContext context) {
    switch (_step) {
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailController,
              label: AppStrings.email,
              hint: 'example@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (a, b) => a is AuthLoading || b is AuthLoading,
              builder: (context, state) {
                return FilledButton(
                  onPressed: state is AuthLoading
                      ? null
                      : () {
                          final email = _emailController.text.trim();
                          if (email.isEmpty) return;
                          setState(() => _email = email);
                          context.read<AuthBloc>().add(AuthResetPasswordRequested(email: email));
                        },
                  child: state is AuthLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إرسال الرمز'),
                );
              },
            ),
          ],
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'أدخل الرمز المُرسل إلى $_email',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            AppTextField(
              controller: _otpController,
              label: 'الرمز',
              hint: '123456',
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (a, b) => a is AuthLoading || b is AuthLoading,
              builder: (context, state) {
                return FilledButton(
                  onPressed: state is AuthLoading
                      ? null
                      : () {
                          final token = _otpController.text.trim();
                          if (token.length < 6) return;
                          context.read<AuthBloc>().add(
                                AuthVerifyResetOtpRequested(email: _email, token: token),
                              );
                        },
                  child: state is AuthLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('تحقق'),
                );
              },
            ),
          ],
        );
      case 3:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _newPasswordController,
              label: 'كلمة المرور الجديدة',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            AppTextField(
              controller: _confirmPasswordController,
              label: 'تأكيد كلمة المرور',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (a, b) => a is AuthLoading || b is AuthLoading,
              builder: (context, state) {
                return FilledButton(
                  onPressed: state is AuthLoading
                      ? null
                      : () {
                          final pass = _newPasswordController.text;
                          final confirm = _confirmPasswordController.text;
                          if (pass.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('كلمة المرور 6 أحرف على الأقل'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          if (pass != confirm) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('كلمتا المرور غير متطابقتين'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          context.read<AuthBloc>().add(AuthSetNewPasswordRequested(newPassword: pass));
                        },
                  child: state is AuthLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ كلمة المرور'),
                );
              },
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
      listener: (context, state) {
        if (state is AuthResetPasswordSent) {
          setState(() => _step = 2);
        } else if (state is AuthResetOtpVerified) {
          setState(() => _step = 3);
        } else if (state is AuthPasswordResetSuccess) {
          widget.onClose();
        } else if (state is AuthError && _step > 0) {
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
        content: SingleChildScrollView(child: _buildContent(context)),
        actions: [
          TextButton(
            onPressed: widget.onClose,
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}
