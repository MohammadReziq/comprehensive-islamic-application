import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// شاشة إنشاء حساب جديد
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'parent';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
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
              context.go(_selectedRole == 'imam' ? '/mosque' : '/home');
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
                    const SizedBox(height: AppDimensions.paddingLG),

                    // ─── Header ───
                    const Text(
                      '🕌',
                      style: TextStyle(fontSize: 48),
                    ).animate().fadeIn(duration: 600.ms),

                    const SizedBox(height: AppDimensions.spacingSM),

                    Text(
                      AppStrings.register,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    Text(
                      AppStrings.welcomeMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: AppDimensions.paddingLG),

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
                                // ─── الاسم ───
                                AppTextField(
                                  controller: _nameController,
                                  label: AppStrings.name,
                                  hint: 'أدخل اسمك الكامل',
                                  prefixIcon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppStrings.errorFieldRequired;
                                    }
                                    if (value.length < 3) {
                                      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: AppDimensions.spacingLG),

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
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
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
                                  hint: '6 أحرف على الأقل',
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
                                      setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      );
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

                                const SizedBox(height: AppDimensions.spacingLG),

                                // ─── تأكيد كلمة المرور ───
                                AppTextField(
                                  controller: _confirmPasswordController,
                                  label: AppStrings.confirmPassword,
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscureConfirm,
                                  textDirection: TextDirection.ltr,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textHint,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      );
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppStrings.errorFieldRequired;
                                    }
                                    if (value != _passwordController.text) {
                                      return AppStrings.errorPasswordMismatch;
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: AppDimensions.spacingXL),

                                // ─── اختيار الدور ───
                                const Text(
                                  AppStrings.chooseRole,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),

                                const SizedBox(height: AppDimensions.spacingMD),

                                // ─── بطاقات الأدوار ───
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RoleCard(
                                        emoji: '👨‍👩‍👧',
                                        title: AppStrings.roleParent,
                                        subtitle: AppStrings.roleParentDesc,
                                        isSelected: _selectedRole == 'parent',
                                        onTap: () => setState(
                                          () => _selectedRole = 'parent',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppDimensions.spacingMD,
                                    ),
                                    Expanded(
                                      child: _RoleCard(
                                        emoji: '🕌',
                                        title: AppStrings.roleImam,
                                        subtitle: AppStrings.roleImamDesc,
                                        isSelected: _selectedRole == 'imam',
                                        onTap: () => setState(
                                          () => _selectedRole = 'imam',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: AppDimensions.spacingXL),

                                // ─── زر إنشاء الحساب ───
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isLoading = state is AuthLoading;
                                    return AppButton(
                                      text: AppStrings.register,
                                      onPressed: isLoading ? null : _onRegister,
                                      isLoading: isLoading,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOut),

                    const SizedBox(height: AppDimensions.spacingLG),

                    // ─── رابط تسجيل الدخول ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.alreadyHaveAccount,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text(
                            AppStrings.login,
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

/// بطاقة اختيار الدور
class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySurface
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
