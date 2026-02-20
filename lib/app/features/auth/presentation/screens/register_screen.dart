import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_responsive.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/constants/app_enums.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// 📁 lib/app/features/auth/presentation/screens/register_screen.dart
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'parent';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          role: _selectedRole,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              final role = state.userProfile?.role;
              if (role == null) return;
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
                    borderRadius: BorderRadius.circular(r.radiusMD),
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
                padding: EdgeInsets.only(bottom: r.vlg),
                child: Column(
                  children: [
                    SizedBox(height: r.isShortPhone ? r.vsm : r.vlg),

                    // أيقونة
                    Text(
                      '🕌',
                      style: TextStyle(fontSize: r.isShortPhone ? 36 : 48),
                    ).animate().fadeIn(duration: 600.ms),

                    SizedBox(height: r.vxs),

                    Text(
                      AppStrings.register,
                      style: TextStyle(
                        fontSize: r.textXXL,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    Text(
                      AppStrings.welcomeMessage,
                      style: TextStyle(
                        fontSize: r.textSM,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    SizedBox(height: r.isShortPhone ? r.vmd : r.vlg),

                    // Form Card
                    Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: r.md),
                          padding: EdgeInsets.all(r.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(r.radiusXL),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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
                                // الاسم
                                AppTextField(
                                  controller: _nameCtrl,
                                  label: AppStrings.name,
                                  hint: 'أدخل اسمك الكامل',
                                  prefixIcon: Icons.person_outline,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return AppStrings.errorFieldRequired;
                                    if (v.length < 3)
                                      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                                    return null;
                                  },
                                ),

                                SizedBox(height: r.vmd),

                                // الإيميل
                                AppTextField(
                                  controller: _emailCtrl,
                                  label: AppStrings.email,
                                  hint: 'example@email.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textDirection: TextDirection.ltr,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return AppStrings.errorFieldRequired;
                                    if (!v.contains('@') || !v.contains('.'))
                                      return AppStrings.errorInvalidEmail;
                                    return null;
                                  },
                                ),

                                SizedBox(height: r.vmd),

                                // كلمة المرور
                                AppTextField(
                                  controller: _passCtrl,
                                  label: AppStrings.password,
                                  hint: '6 أحرف على الأقل',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscurePass,
                                  textDirection: TextDirection.ltr,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textHint,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return AppStrings.errorFieldRequired;
                                    if (v.length < 6)
                                      return AppStrings.errorWeakPassword;
                                    return null;
                                  },
                                ),

                                SizedBox(height: r.vmd),

                                // تأكيد كلمة المرور
                                AppTextField(
                                  controller: _confirmCtrl,
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
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return AppStrings.errorFieldRequired;
                                    if (v != _passCtrl.text)
                                      return AppStrings.errorPasswordMismatch;
                                    return null;
                                  },
                                ),

                                SizedBox(height: r.vlg),

                                // اختيار الدور
                                Text(
                                  AppStrings.chooseRole,
                                  style: TextStyle(
                                    fontSize: r.textMD,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),

                                SizedBox(height: r.vsm),

                                // بطاقات الأدوار
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
                                        r: r,
                                      ),
                                    ),
                                    SizedBox(width: r.sm),
                                    Expanded(
                                      child: _RoleCard(
                                        emoji: '🕌',
                                        title: AppStrings.roleImam,
                                        subtitle: AppStrings.roleImamDesc,
                                        isSelected: _selectedRole == 'imam',
                                        onTap: () => setState(
                                          () => _selectedRole = 'imam',
                                        ),
                                        r: r,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: r.vsm),

                                _RoleCard(
                                  emoji: '📋',
                                  title: AppStrings.roleSupervisor,
                                  subtitle: AppStrings.roleSupervisorDesc,
                                  isSelected: _selectedRole == 'supervisor',
                                  onTap: () => setState(
                                    () => _selectedRole = 'supervisor',
                                  ),
                                  r: r,
                                ),

                                SizedBox(height: r.vlg),

                                // زر إنشاء الحساب
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isLoading = state is AuthLoading;
                                    return SizedBox(
                                      height: r.buttonHeight,
                                      child: AppButton(
                                        text: AppStrings.register,
                                        onPressed: isLoading
                                            ? null
                                            : _onRegister,
                                        isLoading: isLoading,
                                      ),
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

                    SizedBox(height: r.vlg),

                    // رابط تسجيل الدخول
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.alreadyHaveAccount,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: r.textSM,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            AppStrings.login,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: r.textSM,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms),
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

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final AppResponsive r;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(r.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySurface
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(r.radiusMD),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: r.isShortPhone ? 24 : 30)),
            SizedBox(height: r.vxs),
            Text(
              title,
              style: TextStyle(
                fontSize: r.textSM,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.textXS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
