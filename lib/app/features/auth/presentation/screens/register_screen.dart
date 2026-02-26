import 'dart:async';
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
  bool _obscureConfirm = true;
  String _selectedRole = 'parent';

  // ─── Video via shared manager ────────────────────────────
  final _mgr = AuthVideoManager();
  bool _videoReady = false;
  double _videoOpacity = 0.0;

  // ─── Scroll + confirm-field focus ────────────────────────
  final _scrollCtrl = ScrollController();
  final _confirmFocus = FocusNode();
  double _lastKeyboardHeight = 0;
  Timer? _scrollDebounce;

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
    // Video was already loaded by LoginScreen — show instantly, no flash
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

  /// Called every build when MediaQuery changes (keyboard open/close).
  /// Scrolls confirm field into view 120 ms after keyboard settles.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final kh = MediaQuery.of(context).viewInsets.bottom;
    if (_confirmFocus.hasFocus && kh != _lastKeyboardHeight) {
      _scrollDebounce?.cancel();
      if (kh > 0) {
        _scrollDebounce = Timer(const Duration(milliseconds: 120), () {
          if (mounted && _scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
    _lastKeyboardHeight = kh;
  }

  @override
  void dispose() {
    _mgr.removeListener(_onManagerChanged);
    _scrollDebounce?.cancel();
    _scrollCtrl.dispose();
    _confirmFocus.dispose();
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

    // Glass field styling — matches login screen
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
            if (state is AuthAwaitingEmailVerification) {
              context.go('/verify-email');
              return;
            }
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
            }
          },
          child: Stack(
            children: [
              // ─── Layer 1: Gradient fallback ───
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
              // Instant switch only; incoming has first frame before we show it.
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
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.75),
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
                    controller: _scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: r.sm),

                        Text(
                          AppStrings.register,
                          style: TextStyle(
                            fontSize: r.textXXL,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnDark,
                          ),
                        ).animate(),

                        SizedBox(height: r.isShortPhone ? r.vsm : r.vmd),

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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: r.lg,
                                    vertical: r.md,
                                  ),
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
                                          controller: _nameCtrl,
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
                                              return AppStrings
                                                  .errorFieldRequired;
                                            }
                                            if (v.length < 3) {
                                              return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                                            }
                                            return null;
                                          },
                                        ),

                                        SizedBox(height: r.sm),

                                        AppTextField(
                                          controller: _emailCtrl,
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
                                            if (!v.contains('@') ||
                                                !v.contains('.')) {
                                              return AppStrings
                                                  .errorInvalidEmail;
                                            }
                                            return null;
                                          },
                                        ),

                                        SizedBox(height: r.sm),

                                        AppTextField.password(
                                          controller: _passCtrl,
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

                                        SizedBox(height: r.sm),

                                        AppTextField(
                                          controller: _confirmCtrl,
                                          focusNode: _confirmFocus,
                                          label: AppStrings.confirmPassword,
                                          hint: '••••••••',
                                          prefixIcon: Icons.lock_outline,
                                          obscureText: _obscureConfirm,
                                          textDirection: TextDirection.ltr,
                                          fillColor: fieldFill,
                                          labelColor: Colors.white,
                                          textColor: Colors.white,
                                          borderColor: fieldBorder,
                                          iconColor: fieldIcon,
                                          hintColor: fieldHint,
                                          suffix: IconButton(
                                            icon: Icon(
                                              _obscureConfirm
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: fieldIcon,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureConfirm =
                                                  !_obscureConfirm,
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return AppStrings
                                                  .errorFieldRequired;
                                            }
                                            if (v != _passCtrl.text) {
                                              return AppStrings
                                                  .errorPasswordMismatch;
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

                                        // ─── Role cards ───
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _RoleCard(
                                                emoji: Icon(
                                                  Icons
                                                      .family_restroom_outlined,
                                                  color: Colors.white,
                                                ),
                                                title: AppStrings.roleParent,
                                                isSelected:
                                                    _selectedRole == 'parent',
                                                onTap: () => setState(
                                                  () =>
                                                      _selectedRole = 'parent',
                                                ),
                                                r: r,
                                              ),
                                            ),
                                            SizedBox(width: r.sm),
                                            Expanded(
                                              child: _RoleCard(
                                                emoji: Icon(
                                                  Icons.mosque_outlined,
                                                  color: Colors.white,
                                                ),
                                                title: AppStrings.roleImam,
                                                isSelected:
                                                    _selectedRole == 'imam',
                                                onTap: () => setState(
                                                  () => _selectedRole = 'imam',
                                                ),
                                                r: r,
                                              ),
                                            ),
                                            SizedBox(width: r.sm),
                                          ],
                                        ),

                                        SizedBox(height: r.lg),

                                        BlocBuilder<AuthBloc, AuthState>(
                                          builder: (context, state) {
                                            final isLoading =
                                                state is AuthLoading;
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
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOut),

                        SizedBox(height: r.sm),

                        // ─── Login link ───
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.alreadyHaveAccount,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: r.textSM,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/login'),
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

                        SizedBox(height: r.sm),
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

class _RoleCard extends StatelessWidget {
  final Icon emoji;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final AppResponsive r;

  const _RoleCard({
    required this.emoji,
    required this.title,
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
        padding: EdgeInsets.all(r.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(r.radiusMD),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.18),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            emoji,
            SizedBox(height: r.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: r.textSM,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
