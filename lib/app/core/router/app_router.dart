import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_enums.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/parent/presentation/screens/home_screen.dart';
import '../../features/mosque/presentation/screens/mosque_gate_screen.dart';
import '../../features/mosque/presentation/screens/create_mosque_screen.dart';
import '../../features/mosque/presentation/screens/join_mosque_screen.dart';

/// إعداد التنقل في التطبيق
class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    // ─── Redirect حسب حالة Auth ───
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnSplash = state.matchedLocation == '/splash';

      // في الـ Splash: ننتظر انتهاء الفحص ثم نوجّه
      if (isOnSplash) {
        if (authState is AuthLoading || authState is AuthInitial) {
          return null; // نبقى على الـ Splash حتى ينتهي الفحص
        }
        if (authState is AuthAuthenticated) {
          if (authState.userProfile?.role == UserRole.imam) return '/mosque';
          return '/home';
        }
        return '/login'; // غير مسجّل → تسجيل الدخول
      }

      // مو مسجّل + مو في صفحة Auth → يروح Login
      if (!isAuthenticated && !isOnAuth) return '/login';

      // مسجّل + في صفحة Auth → توجيه حسب الدور
      if (authState is AuthAuthenticated) {
        if (authState.userProfile?.role == UserRole.imam) return '/mosque';
        return '/home';
      }

      return null;
    },

    // ─── إعادة تقييم التنقل عند تغيّر Auth state ───
    refreshListenable: GoRouterRefreshStream(authBloc.stream),

    // ─── Routes ───
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/mosque',
        name: 'mosque',
        builder: (context, state) => const MosqueGateScreen(),
      ),
      GoRoute(
        path: '/mosque/create',
        name: 'mosqueCreate',
        builder: (context, state) => const CreateMosqueScreen(),
      ),
      GoRoute(
        path: '/mosque/join',
        name: 'mosqueJoin',
        builder: (context, state) => const JoinMosqueScreen(),
      ),
    ],
  );
}

/// Helper: يحوّل Stream لـ Listenable حتى GoRouter يسمع التغييرات
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
