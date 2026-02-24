import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_responsive.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/auth_video_manager.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// 📁 lib/app/features/auth/presentation/screens/login_screen.dart
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

  // ─── Video via shared manager ────────────────────────────
  final _mgr = AuthVideoManager();
  bool _videoReady = false;
  double _videoOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    // If video was already loaded (coming from RegisterScreen), show instantly
    if (_mgr.isReady) {
      if (mounted) setState(() { _videoReady = true; _videoOpacity = 1.0; });
      return;
    }
    final ok = await _mgr.ensureReady();
    if (!mounted || !ok) return;
    setState(() { _videoReady = true; });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _videoOpacity = 1.0);
    });
  }

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
    final r = AppResponsive(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Field styling for glass look
    const fieldFill = Colors.transparent;
    final fieldBorder = Colors.white.withValues(alpha: 0.35);
    final fieldIcon = Colors.white.withValues(alpha: 0.65);
    final fieldHint = Colors.white.withValues(alpha: 0.4);

    final ctrl = _mgr.controller;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              final role = state.userProfile?.role;
              if (role == null) return;
              // Release the shared video when leaving auth flow
              _mgr.release();
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
            } else if (state is AuthResetPasswordSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تم إرسال رمز إلى بريدك. أدخل الرمز في النافذة.',
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is AuthPasswordResetSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تغيير كلمة المرور بنجاح.'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<AuthBloc>().add(
                const AuthResetPasswordFlowFinished(),
              );
            }
          },
          child: Stack(
            children: [
              // ─── Layer 1: Gradient fallback (always visible) ───
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // ─── Layer 2: Video (fades in when ready) ───
              if (_videoReady && ctrl != null)
                AnimatedOpacity(
                  opacity: _videoOpacity,
                  duration: const Duration(milliseconds: 500),
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: ctrl.value.size.width,
                        height: ctrl.value.size.height,
                        child: VideoPlayer(ctrl),
                      ),
                    ),
                  ),
                ),

              // ─── Layer 3: Gradient overlay ───
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // ─── Layer 4: Content — slides up with keyboard smoothly ───
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                top: 0,
                left: 0,
                right: 0,
                bottom: keyboardHeight,
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: r.isShortPhone ? r.vmd : r.vxl),

                        // ─── Logo ───
                        SizedBox(height: r.vxxl + 90),

                        SizedBox(height: r.isShortPhone ? r.vmd : r.vxl),

                        // ─── Form card ───
                        ClipRRect(
                              borderRadius: BorderRadius.circular(r.radiusXL),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 20,
                                  sigmaY: 20,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: r.md,
                                  ),
                                  padding: EdgeInsets.all(r.lg),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(
                                      r.radiusXL,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        AppTextField(
                                          controller: _emailController,
                                          label: AppStrings.email,
                                          hint: 'example@email.com',
                                          prefixIcon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textDirection: TextDirection.ltr,
                                          fillColor: fieldFill,
                                          labelColor: Colors.white,
                                          textColor: Colors.white,
                                          borderColor: fieldBorder,
                                          iconColor: fieldIcon,
                                          hintColor: fieldHint,
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return AppStrings
                                                  .errorFieldRequired;
                                            }
                                            if (!v.contains('@')) {
                                              return AppStrings
                                                  .errorInvalidEmail;
                                            }
                                            return null;
                                          },
                                        ),

                                        SizedBox(height: r.vmd),

                                        AppTextField.password(
                                          controller: _passwordController,
                                          fillColor: fieldFill,
                                          labelColor: Colors.white,
                                          textColor: Colors.white,
                                          borderColor: fieldBorder,
                                          iconColor: fieldIcon,
                                          hintColor: fieldHint,
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return AppStrings
                                                  .errorFieldRequired;
                                            }
                                            if (v.length < 6) {
                                              return AppStrings
                                                  .errorWeakPassword;
                                            }
                                            return null;
                                          },
                                        ),

                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed:
                                                _showForgotPasswordDialog,
                                            child: Text(
                                              AppStrings.forgotPassword,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.7,
                                                ),
                                                fontSize: r.textSM,
                                              ),
                                            ),
                                          ),
                                        ),

                                        SizedBox(height: r.vsm),

                                        BlocBuilder<AuthBloc, AuthState>(
                                          builder: (context, state) {
                                            final isLoading =
                                                state is AuthLoading;
                                            return SizedBox(
                                              height: r.buttonHeight,
                                              child: AppButton(
                                                text: AppStrings.login,
                                                onPressed: isLoading
                                                    ? null
                                                    : _onLogin,
                                                isLoading: isLoading,
                                              ),
                                            );
                                          },
                                        ),

                                        SizedBox(height: r.vmd),

                                        Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                color: Colors.white.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: r.md,
                                              ),
                                              child: Text(
                                                AppStrings.orLoginWith,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                  fontSize: r.textSM,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                color: Colors.white.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: r.vmd),

                                        SizedBox(
                                          height: r.buttonHeight,
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                context.read<AuthBloc>().add(
                                                  const AuthLoginWithGoogleRequested(),
                                                ),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.05),
                                              side: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.22,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      r.radiusMD,
                                                    ),
                                              ),
                                            ),
                                            icon: Text(
                                              'G',
                                              style: TextStyle(
                                                fontSize: r.textLG,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            label: Text(
                                              AppStrings.loginWithGoogle,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: r.textMD,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOut),

                        SizedBox(height: r.vmd),

                        // ─── Register link ───
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.dontHaveAccount,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: r.textSM,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/register'),
                              child: Text(
                                AppStrings.register,
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: r.textSM,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms),

                        SizedBox(height: r.vsm),
                      ],
                    ),
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

// ════════════════════════════════════════════════════════════
/// حوار نسيت كلمة المرور
// ════════════════════════════════════════════════════════════
class _ForgotPasswordDialogContent extends StatefulWidget {
  final String initialEmail;
  final VoidCallback onClose;

  const _ForgotPasswordDialogContent({
    required this.initialEmail,
    required this.onClose,
  });

  @override
  State<_ForgotPasswordDialogContent> createState() =>
      _ForgotPasswordDialogContentState();
}

class _ForgotPasswordDialogContentState
    extends State<_ForgotPasswordDialogContent> {
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
