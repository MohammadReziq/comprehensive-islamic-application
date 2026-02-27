import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_responsive.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/auth_video_manager.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_video_background.dart';
import '../widgets/forgot_password_dialog.dart';
import '../widgets/login_form_card.dart';

/// شاشة تسجيل الدخول — فيديو خلفية + بطاقة Google / بريد.
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

  bool _showEmailLogin = false;

  final _mgr = AuthVideoManager();
  bool _videoReady = false;
  double _videoOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _mgr.addListener(_onManagerChanged);
    _initVideo();
  }

  void _onManagerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initVideo() async {
    if (_mgr.isReady) {
      if (mounted) {
        setState(() {
          _videoReady = true;
          _videoOpacity = 1.0;
        });
      }
      return;
    }
    final ok = await _mgr.ensureReady();
    if (!mounted || !ok) return;
    setState(() {
      _videoReady = true;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _videoOpacity = 1.0);
    });
  }

  @override
  void dispose() {
    _mgr.removeListener(_onManagerChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    _forgotEmailController.text = _emailController.text.trim();
    showDialog(
      context: context,
      builder: (ctx) => ForgotPasswordDialogContent(
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
    const fieldFill = Colors.transparent;
    final fieldBorder = Colors.white.withValues(alpha: 0.35);
    final fieldIcon = Colors.white.withValues(alpha: 0.65);
    final fieldHint = Colors.white.withValues(alpha: 0.4);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              final role = state.userProfile?.role;
              if (role == null) return;
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
          child: AuthVideoBackground(
            manager: _mgr,
            videoReady: _videoReady,
            videoOpacity: _videoOpacity,
            child: AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              top: 0,
              left: 0,
              right: 0,
              bottom: keyboardHeight,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'مرحباً بعودتك',
                                style: TextStyle(
                                  fontSize: r.textXXL,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 700.ms)
                                  .slideY(begin: -0.3, curve: Curves.easeOut),
                              const SizedBox(height: 8),
                              Text(
                                'تابع صلاة أبنائك بكل يسر',
                                style: TextStyle(
                                  fontSize: r.textSM,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ).animate().fadeIn(
                                    delay: 200.ms,
                                    duration: 600.ms,
                                  ),
                              SizedBox(
                                height: r.isShortPhone ? r.vmd : r.vxl,
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(r.radiusXL),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                  child: Container(
                                    width: double.infinity,
                                    margin: EdgeInsets.symmetric(horizontal: r.md),
                                    padding: EdgeInsets.all(r.lg),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(r.radiusXL),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: LoginFormCard(
                                      formKey: _formKey,
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      showEmailLogin: _showEmailLogin,
                                      onShowEmailLoginChanged: (v) =>
                                          setState(() => _showEmailLogin = v),
                                      onLogin: _onLogin,
                                      onForgotPassword: _showForgotPasswordDialog,
                                      r: r,
                                      fieldFill: fieldFill,
                                      fieldBorder: fieldBorder,
                                      fieldIcon: fieldIcon,
                                      fieldHint: fieldHint,
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 400.ms, duration: 600.ms)
                                  .slideY(begin: 0.1, curve: Curves.easeOut),
                              SizedBox(height: r.vmd),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
