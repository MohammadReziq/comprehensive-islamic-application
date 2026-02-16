import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_enums.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/parent/presentation/screens/home_screen.dart';
import '../../features/parent/presentation/screens/children_screen.dart';
import '../../features/parent/presentation/screens/add_child_screen.dart';
import '../../features/parent/presentation/screens/child_card_screen.dart';
import '../../features/mosque/presentation/screens/mosque_gate_screen.dart';
import '../../features/mosque/presentation/screens/create_mosque_screen.dart';
import '../../features/mosque/presentation/screens/join_mosque_screen.dart';
import '../../features/supervisor/presentation/screens/supervisor_dashboard_screen.dart';
import '../../features/supervisor/presentation/screens/supervisor_placeholder_screen.dart';
import '../../features/supervisor/presentation/screens/students_screen.dart';
import '../../features/supervisor/presentation/screens/scanner_screen.dart';
import '../../features/supervisor/presentation/bloc/scanner_bloc.dart';
import '../../features/admin/presentation/screens/admin_mosque_requests_screen.dart';
import '../../injection_container.dart';

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
      final isUnauthenticated = authState is AuthUnauthenticated;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnSplash = state.matchedLocation == '/splash';

      // في الـ Splash: لا نوجّه إلا بعد اكتمال جلب الـ profile (تفادي حلقة التوجيه)
      if (isOnSplash) {
        if (authState is AuthLoading || authState is AuthInitial) {
          return null; // نبقى على الـ Splash حتى ينتهي الفحص
        }
        if (authState is AuthAuthenticated) {
          final profile = authState.userProfile;
          // عدم التوجيه قبل جلب الـ profile — وإلا نُرسل لـ /home ثم يُعاد لـ /splash فحلقة
          if (profile == null) return null;
          final role = profile.role;
          if (role == UserRole.superAdmin) return '/admin';
          if (role == UserRole.imam) return '/mosque';
          return '/home';
        }
        return '/login'; // غير مسجّل → تسجيل الدخول
      }

      // إذا حاول الدخول لصفحة محمية وهو غير مسجل
      if (isUnauthenticated && !isOnAuth) return '/login';

      // إذا كان مسجلاً
      if (authState is AuthAuthenticated) {
        final profile = authState.userProfile;
        
        // إذا لم تكتمل البيانات بعد، ننتقل للـ Splash وننتظر
        if (profile == null) {
          if (isOnSplash) return null;
          return '/splash';
        }

        final role = profile.role;
        final isSuperAdmin = role == UserRole.superAdmin;
        final isImam = role == UserRole.imam;
        final isOnAdmin = state.matchedLocation.startsWith('/admin');
        final isOnMosque = state.matchedLocation.startsWith('/mosque') ||
                          state.matchedLocation.startsWith('/supervisor');
        final isOnHome = state.matchedLocation == '/home';

        // السوبر أدمن → صفحة إدارة طلبات المساجد فقط
        if (isSuperAdmin && !isOnAdmin) return '/admin';
        // الإمام → بوابة المسجد / لوحة المشرف
        if (isImam && !isOnMosque) return '/mosque';
        // توجيه الأهل إذا لم يكونوا في صفحتهم
        if (!isSuperAdmin && !isImam && (isOnAuth || isOnSplash)) return '/home';
        // منع الأهل من دخول صفحات المسجد والإدارة
        if (!isSuperAdmin && !isImam && (isOnMosque || isOnAdmin) && !isOnHome) return '/home';
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
        path: '/parent/children',
        name: 'parentChildren',
        builder: (context, state) => const ChildrenScreen(),
      ),
      GoRoute(
        path: '/parent/children/add',
        name: 'parentAddChild',
        builder: (context, state) => const AddChildScreen(),
      ),
      GoRoute(
        path: '/parent/children/:id/card',
        name: 'parentChildCard',
        builder: (context, state) => ChildCardScreen(
          childId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminMosqueRequestsScreen(),
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
      GoRoute(
        path: '/supervisor/dashboard',
        name: 'supervisorDashboard',
        builder: (context, state) => const SupervisorDashboardScreen(),
      ),
      GoRoute(
        path: '/supervisor/scan',
        name: 'supervisorScan',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ScannerBloc>(),
          child: const ScannerScreen(),
        ),
      ),
      GoRoute(
        path: '/supervisor/students',
        name: 'supervisorStudents',
        builder: (context, state) => const StudentsScreen(),
      ),
      GoRoute(
        path: '/supervisor/corrections',
        name: 'supervisorCorrections',
        builder: (context, state) => const SupervisorPlaceholderScreen(title: 'طلبات التصحيح'),
      ),
      GoRoute(
        path: '/supervisor/notes',
        name: 'supervisorNotes',
        builder: (context, state) => const SupervisorPlaceholderScreen(title: 'الملاحظات'),
      ),
    ],
  );
}

/// Helper: يحوّل Stream لـ Listenable حتى GoRouter يسمع التغييرات
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
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
