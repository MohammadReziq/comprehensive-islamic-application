import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_responsive.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// محتوى بطاقة تسجيل الدخول: Google أساسي أو نموذج بريد/كلمة مرور.
class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.showEmailLogin,
    required this.onShowEmailLoginChanged,
    required this.onLogin,
    required this.onForgotPassword,
    required this.r,
    this.fieldFill = Colors.transparent,
    required this.fieldBorder,
    required this.fieldIcon,
    required this.fieldHint,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showEmailLogin;
  final ValueChanged<bool> onShowEmailLoginChanged;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final AppResponsive r;
  final Color fieldFill;
  final Color fieldBorder;
  final Color fieldIcon;
  final Color fieldHint;

  /// الخيار الأساسي: Google فقط
  Widget _buildGooglePrimary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: r.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: () => context.read<AuthBloc>().add(
                  const AuthLoginWithGoogleRequested(),
                ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r.radiusMD),
              ),
            ),
            icon: Text(
              'G',
              style: TextStyle(
                fontSize: r.textLG,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            label: Text(
              AppStrings.loginWithGoogle,
              style: TextStyle(
                color: Colors.white,
                fontSize: r.textMD,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// نموذج تسجيل الدخول بالبريد وكلمة المرور
  Widget _buildEmailLoginForm(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onShowEmailLoginChanged(false),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              label: Text(
                'العودة',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: r.textSM,
                ),
              ),
            ),
          ),
          AppTextField(
            controller: emailController,
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
              if (v == null || v.isEmpty) return AppStrings.errorFieldRequired;
              if (!v.contains('@')) return AppStrings.errorInvalidEmail;
              return null;
            },
          ),
          SizedBox(height: r.vmd),
          AppTextField.password(
            controller: passwordController,
            fillColor: fieldFill,
            labelColor: Colors.white,
            textColor: Colors.white,
            borderColor: fieldBorder,
            iconColor: fieldIcon,
            hintColor: fieldHint,
            validator: (v) {
              if (v == null || v.isEmpty) return AppStrings.errorFieldRequired;
              if (v.length < 6) return AppStrings.errorWeakPassword;
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onForgotPassword,
              child: Text(
                AppStrings.forgotPassword,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: r.textSM,
                ),
              ),
            ),
          ),
          SizedBox(height: r.vsm),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return SizedBox(
                height: r.buttonHeight,
                child: AppButton(
                  text: AppStrings.login,
                  onPressed: isLoading ? null : onLogin,
                  isLoading: isLoading,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return showEmailLogin
        ? _buildEmailLoginForm(context)
        : _buildGooglePrimary(context);
  }
}
