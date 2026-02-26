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

  /// true = نعرض نموذج البريد/كلمة المرور، false = الخيار الأساسي (Google فقط)
  bool _showEmailLogin = false;

  // ─── Video via shared manager ────────────────────────────
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
    // If video was already loaded (coming from RegisterScreen), show instantly
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

  /// الخيار الأساسي: Google فقط + رابط لتسجيل الدخول بالبريد
  Widget _buildGooglePrimary(AppResponsive r) {
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
                color: Colors.white,
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
        SizedBox(height: r.vlg),
        TextButton(
          onPressed: () => setState(() => _showEmailLogin = true),
          child: Text(
            'تسجيل الدخول بالبريد الإلكتروني',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: r.textSM,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  /// نموذج تسجيل الدخول بالبريد وكلمة المرور (يظهر بعد الضغط على الرابط)
  Widget _buildEmailLoginForm(
    AppResponsive r,
    Color fieldFill,
    Color fieldBorder,
    Color fieldIcon,
    Color fieldHint,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _showEmailLogin = false),
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
            controller: _emailController,
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
            controller: _passwordController,
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
              onPressed: _showForgotPasswordDialog,
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
                  onPressed: isLoading ? null : _onLogin,
                  isLoading: isLoading,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLayer(VideoPlayerController ctrl) => SizedBox.expand(
    child: FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: ctrl.value.size.width,
        height: ctrl.value.size.height,
        child: VideoPlayer(ctrl),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Field styling for glass look
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

              // ─── Layer 2: Video ping-pong (both textures always hot) ───
              // Instant opacity switch only — no animation. Both clips match at
              // transition, and we only flip after incoming has drawn first frame,
              // so the user doesn't notice the switch.
              if (_videoReady)
                AnimatedOpacity(
                  opacity: _videoOpacity,
                  duration: const Duration(milliseconds: 500),
                  child: Stack(
                    children: [
                      if (_mgr.forwardController != null)
                        Opacity(
                          opacity: _mgr.isForward ? 1.0 : 0.001,
                          child: _buildVideoLayer(_mgr.forwardController!),
                        ),
                      if (_mgr.reverseController != null)
                        Opacity(
                          opacity: _mgr.isForward ? 0.001 : 1.0,
                          child: _buildVideoLayer(_mgr.reverseController!),
                        ),
                    ],
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
                        SizedBox(height: r.isShortPhone ? r.vsm : r.vmd),

                        // ─── Header ───
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
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

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
                                  child: _showEmailLogin
                                      ? _buildEmailLoginForm(
                                          r,
                                          fieldFill,
                                          fieldBorder,
                                          fieldIcon,
                                          fieldHint,
                                        )
                                      : _buildGooglePrimary(r),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOut),

                        SizedBox(height: r.vmd),

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
