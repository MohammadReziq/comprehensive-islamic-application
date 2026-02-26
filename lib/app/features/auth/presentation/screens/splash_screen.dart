import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_storage_keys.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

/// شاشة البداية — تفحص حالة المصادقة وتوجّه المستخدم فوراً.
/// لا فيديو هنا؛ الفيديو رح يكون خلفية لشاشة تسجيل الدخول.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // guard — يمنع التوجيه مرتين
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCurrentAuth());
  }

  void _checkCurrentAuth() {
    if (!mounted) return;
    final state = context.read<AuthBloc>().state;
    _handleAuthState(state);
  }

  Future<void> _handleAuthState(AuthState state) async {
    if (_navigated) return; // ← يمنع التكرار
    if (state is AuthAuthenticated) {
      if (!mounted) return;
      _navigated = true;
      context.go('/home');
    } else if (state is AuthUnauthenticated || state is AuthError) {
      await _resolveUnauthenticated();
    }
    // AuthInitial / AuthLoading → ننتظر BlocListener
  }

  Future<void> _resolveUnauthenticated() async {
    if (_navigated) return; // ← يمنع التكرار
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(AppStorageKeys.onboardingSeen) ?? false;
    if (!mounted) return;
    _navigated = true;
    context.go(seen ? '/login' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleAuthState(state),
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}
