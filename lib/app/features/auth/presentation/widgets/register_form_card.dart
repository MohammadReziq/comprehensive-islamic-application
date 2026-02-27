import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_responsive.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'role_card.dart';

/// بطاقة نموذج التسجيل: الاسم، البريد، كلمة المرور، التأكيد، اختيار الدور، زر التسجيل.
class RegisterFormCard extends StatelessWidget {
  const RegisterFormCard({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.confirmFocus,
    required this.obscureConfirm,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onObscureConfirmToggle,
    required this.onRegister,
    required this.r,
    this.fieldFill = Colors.transparent,
    required this.fieldBorder,
    required this.fieldIcon,
    required this.fieldHint,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final FocusNode confirmFocus;
  final bool obscureConfirm;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onObscureConfirmToggle;
  final VoidCallback onRegister;
  final AppResponsive r;
  final Color fieldFill;
  final Color fieldBorder;
  final Color fieldIcon;
  final Color fieldHint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(r.radiusXL),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: r.md),
          padding: EdgeInsets.symmetric(horizontal: r.lg, vertical: r.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(r.radiusXL),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: nameCtrl,
                  label: AppStrings.name,
                  hint: 'أدخل اسمك الكامل',
                  prefixIcon: Icons.person_outline,
                  fillColor: fieldFill,
                  labelColor: Colors.white,
                  textColor: Colors.white,
                  borderColor: fieldBorder,
                  iconColor: fieldIcon,
                  hintColor: fieldHint,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppStrings.errorFieldRequired;
                    }
                    if (v.length < 3) {
                      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                SizedBox(height: r.sm),
                AppTextField(
                  controller: emailCtrl,
                  label: AppStrings.email,
                  hint: 'example@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  fillColor: fieldFill,
                  labelColor: Colors.white,
                  textColor: Colors.white,
                  borderColor: fieldBorder,
                  iconColor: fieldIcon,
                  hintColor: fieldHint,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppStrings.errorFieldRequired;
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return AppStrings.errorInvalidEmail;
                    }
                    return null;
                  },
                ),
                SizedBox(height: r.sm),
                AppTextField.password(
                  controller: passCtrl,
                  fillColor: fieldFill,
                  labelColor: Colors.white,
                  textColor: Colors.white,
                  borderColor: fieldBorder,
                  iconColor: fieldIcon,
                  hintColor: fieldHint,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppStrings.errorFieldRequired;
                    }
                    if (v.length < 6) {
                      return AppStrings.errorWeakPassword;
                    }
                    return null;
                  },
                ),
                SizedBox(height: r.sm),
                AppTextField(
                  controller: confirmCtrl,
                  focusNode: confirmFocus,
                  label: AppStrings.confirmPassword,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: obscureConfirm,
                  textDirection: TextDirection.ltr,
                  fillColor: fieldFill,
                  labelColor: Colors.white,
                  textColor: Colors.white,
                  borderColor: fieldBorder,
                  iconColor: fieldIcon,
                  hintColor: fieldHint,
                  suffix: IconButton(
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: fieldIcon,
                    ),
                    onPressed: onObscureConfirmToggle,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppStrings.errorFieldRequired;
                    }
                    if (v != passCtrl.text) {
                      return AppStrings.errorPasswordMismatch;
                    }
                    return null;
                  },
                ),
                SizedBox(height: r.sm),
                Text(
                  AppStrings.chooseRole,
                  style: TextStyle(
                    fontSize: r.textSM,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: r.sm),
                Row(
                  children: [
                    Expanded(
                      child: RoleCard(
                        emoji: Icon(
                          Icons.family_restroom_outlined,
                          color: Colors.white,
                        ),
                        title: AppStrings.roleParent,
                        isSelected: selectedRole == 'parent',
                        onTap: () => onRoleChanged('parent'),
                        r: r,
                      ),
                    ),
                    SizedBox(width: r.sm),
                    Expanded(
                      child: RoleCard(
                        emoji: Icon(
                          Icons.mosque_outlined,
                          color: Colors.white,
                        ),
                        title: AppStrings.roleImam,
                        isSelected: selectedRole == 'imam',
                        onTap: () => onRoleChanged('imam'),
                        r: r,
                      ),
                    ),
                    SizedBox(width: r.sm),
                  ],
                ),
                SizedBox(height: r.lg),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return SizedBox(
                      height: r.buttonHeight,
                      child: AppButton(
                        text: AppStrings.register,
                        onPressed: isLoading ? null : onRegister,
                        isLoading: isLoading,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.1, curve: Curves.easeOut);
  }
}
