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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              } else if (role == UserRole.imam) {
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
                                    onPressed: () {
                                      // TODO: شاشة نسيت كلمة المرور
                                    },
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
                                    // TODO: Google Sign-In لاحقاً
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
