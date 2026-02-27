import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_responsive.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/auth_video_manager.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_video_background.dart';
import '../widgets/register_form_card.dart';

/// شاشة إنشاء حساب جديد — فيديو خلفية + نموذج التسجيل.
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

  final _mgr = AuthVideoManager();
  bool _videoReady = false;
  double _videoOpacity = 0.0;

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
                      RegisterFormCard(
                        formKey: _formKey,
                        nameCtrl: _nameCtrl,
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        confirmCtrl: _confirmCtrl,
                        confirmFocus: _confirmFocus,
                        obscureConfirm: _obscureConfirm,
                        selectedRole: _selectedRole,
                        onRoleChanged: (v) => setState(() => _selectedRole = v),
                        onObscureConfirmToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        onRegister: _onRegister,
                        r: r,
                        fieldFill: fieldFill,
                        fieldBorder: fieldBorder,
                        fieldIcon: fieldIcon,
                        fieldHint: fieldHint,
                      ),
                      SizedBox(height: r.sm),
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
          ),
        ),
      ),
    );
  }
}
