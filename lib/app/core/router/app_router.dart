import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:salati_hayati/app/features/super_admin/presentation/screens/admin_screen.dart';
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
import '../../features/parent/presentation/screens/child_view_screen.dart';
import '../../features/mosque/presentation/screens/mosque_gate_screen.dart';
import '../../features/mosque/presentation/screens/create_mosque_screen.dart';
import '../../features/mosque/presentation/screens/join_mosque_screen.dart';
import '../../features/imam/presentation/screens/imam_dashboard_screen.dart';
import '../../features/imam/presentation/screens/imam_corrections_screen.dart';
import '../../features/imam/presentation/screens/imam_competitions_screen.dart';
import '../../features/imam/presentation/screens/imam_mosque_settings_screen.dart';
import '../../features/imam/presentation/screens/imam_attendance_report_screen.dart';
import '../../features/imam/presentation/screens/imam_supervisors_performance_screen.dart';
import '../../features/imam/presentation/screens/prayer_points_settings_screen.dart';
import '../../features/imam/presentation/bloc/imam_bloc.dart';
import '../../models/mosque_model.dart';
import '../../features/supervisor/presentation/screens/supervisor_dashboard_screen.dart';
import '../../features/supervisor/presentation/screens/supervisor_placeholder_screen.dart';
import '../../features/supervisor/presentation/screens/students_screen.dart';
import '../../features/corrections/presentation/screens/corrections_list_screen.dart';
import '../../features/corrections/presentation/screens/request_correction_screen.dart';
import '../../features/corrections/presentation/screens/my_corrections_screen.dart';
import '../../features/notes/presentation/screens/notes_inbox_screen.dart';
import '../../features/notes/presentation/screens/send_note_screen.dart';
import '../../features/competitions/presentation/screens/manage_competition_screen.dart';
import '../../features/supervisor/data/repositories/supervisor_repository.dart';
import '../../features/supervisor/data/models/mosque_student_model.dart';
import '../../features/parent/data/repositories/child_repository.dart';
import '../../features/supervisor/presentation/screens/child_profile_screen.dart';
import '../../features/supervisor/presentation/screens/scanner_screen.dart';
import '../../features/supervisor/presentation/bloc/scanner_bloc.dart';
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
      final isOnAuth =
          state.matchedLocation == '/login' ||
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
          if (role == UserRole.child) return '/child-view';
          if (role == UserRole.imam || role == UserRole.supervisor)
            return '/mosque';
          return '/home';
        }
        return '/login'; // غير مسجّل → تسجيل الدخول
      }

      // إذا حاول الدخول لصفحة محمية وهو غير مسجل
      if (isUnauthenticated && !isOnAuth) return '/login';

      // إذا كان مسجلاً
      if (authState is AuthAuthenticated) {
        final profile = authState.userProfile;
        final isOnImamOrSupervisorDashboard =
            state.matchedLocation.startsWith('/imam') ||
            state.matchedLocation.startsWith('/supervisor');

        // إذا لم تكتمل البيانات بعد، ننتقل للـ Splash — إلا إذا كنا على لوحة الإمام/المشرف (تفادي وميض ثم redirect)
        if (profile == null) {
          if (isOnSplash) return null;
          if (isOnImamOrSupervisorDashboard) return null;
          return '/splash';
        }

        final role = profile.role;
        final isSuperAdmin = role == UserRole.superAdmin;
        final isChild = role == UserRole.child;
        final isImamOrSupervisor =
            role == UserRole.imam || role == UserRole.supervisor;
        final isOnAdmin = state.matchedLocation.startsWith('/admin');
        final isOnChildView = state.matchedLocation == '/child-view';
        final isOnMosque =
            state.matchedLocation.startsWith('/mosque') ||
            state.matchedLocation.startsWith('/supervisor') ||
            state.matchedLocation.startsWith('/imam');
        final isOnHome = state.matchedLocation == '/home';

        // منع غير السوبر أدمن من الوصول لـ /admin — توجيهه حسب دوره
        if (isOnAdmin && !isSuperAdmin) {
          if (isChild) return '/child-view';
          if (isImamOrSupervisor) return '/mosque';
          return '/home';
        }
        // السوبر أدمن → صفحة إدارة طلبات المساجد فقط
        if (isSuperAdmin && !isOnAdmin) return '/admin';
        // الابن → شاشة عرض الابن فقط
        if (isChild && !isOnChildView) return '/child-view';
        // الإمام أو المشرف → بوابة المسجد / لوحة الإمام / لوحة المشرف
        if (isImamOrSupervisor && !isOnMosque) return '/mosque';
        // توجيه الأهل إذا لم يكونوا في صفحتهم
        if (!isSuperAdmin &&
            !isImamOrSupervisor &&
            !isChild &&
            (isOnAuth || isOnSplash))
          return '/home';
        // منع الأهل من دخول صفحات المسجد والإدارة وواجهة الابن
        if (!isSuperAdmin &&
            !isImamOrSupervisor &&
            !isChild &&
            (isOnMosque || isOnAdmin || isOnChildView) &&
            !isOnHome)
          return '/home';
        // منع الابن من دخول صفحات ولي الأمر/المسجد/الإدارة
        if (isChild && (isOnMosque || isOnAdmin || isOnHome))
          return '/child-view';
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
        path: '/child-view',
        name: 'childView',
        builder: (context, state) => const ChildViewScreen(),
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
        builder: (context, state) =>
            ChildCardScreen(childId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/parent/children/:id/request-correction',
        name: 'parentRequestCorrection',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final childName = state.extra as String?;
          return RequestCorrectionScreen(childId: id, childName: childName);
        },
      ),
      GoRoute(
        path: '/parent/corrections',
        name: 'parentMyCorrections',
        builder: (context, state) => const MyCorrectionsScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminScreen(),
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
        path: '/imam/dashboard',
        name: 'imamDashboard',
        builder: (context, state) => const ImamDashboardScreen(),
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
        path: '/supervisor/child/:id',
        name: 'supervisorChildProfile',
        builder: (context, state) =>
            ChildProfileScreen(childId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/supervisor/corrections',
        redirect: (_, __) => '/supervisor/dashboard',
      ),
      GoRoute(
        path: '/supervisor/corrections/:mosqueId',
        name: 'supervisorCorrections',
        builder: (context, state) {
          final mosqueId = state.pathParameters['mosqueId']!;
          return CorrectionsListScreen(mosqueId: mosqueId);
        },
      ),
      GoRoute(
        path: '/imam/corrections/:mosqueId',
        name: 'imamCorrections',
        builder: (context, state) => ImamCorrectionsScreen(
          mosqueId: state.pathParameters['mosqueId']!,
        ),
      ),
      GoRoute(
        path: '/supervisor/notes/send/:mosqueId',
        name: 'supervisorNotesSend',
        builder: (context, state) {
          final mosqueId = state.pathParameters['mosqueId']!;
          return FutureBuilder<List<MosqueStudentModel>>(
            future: sl<SupervisorRepository>().getMosqueStudents(mosqueId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final children = snapshot.data!.map((s) => s.child).toList();
              return SendNoteScreen(children: children, mosqueId: mosqueId);
            },
          );
        },
      ),
      GoRoute(
        path: '/supervisor/notes',
        name: 'supervisorNotes',
        builder: (context, state) =>
            const SupervisorPlaceholderScreen(title: 'الملاحظات'),
      ),
      GoRoute(
        path: '/imam/competitions/:mosqueId',
        name: 'imamCompetitions',
        builder: (context, state) => ImamCompetitionsScreen(
          mosqueId: state.pathParameters['mosqueId']!,
        ),
      ),
      GoRoute(
        path: '/imam/mosque/:mosqueId/prayer-points',
        name: 'imamPrayerPoints',
        builder: (context, state) {
          final mosqueId = state.pathParameters['mosqueId']!;
          final mosqueName = state.extra as String?;
          return BlocProvider(
            create: (_) => sl<ImamBloc>(),
            child: PrayerPointsSettingsScreen(
              mosqueId: mosqueId,
              mosqueName: mosqueName is String ? mosqueName : null,
            ),
          );
        },
      ),
      GoRoute(
        path: '/imam/mosque/:mosqueId/settings',
        name: 'imamMosqueSettings',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ImamBloc>(),
          child: ImamMosqueSettingsScreen(
            mosqueId: state.pathParameters['mosqueId']!,
            mosque: state.extra as MosqueModel,
          ),
        ),
      ),
      GoRoute(
        path: '/imam/mosque/:mosqueId/attendance-report',
        name: 'imamAttendanceReport',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ImamBloc>(),
          child: ImamAttendanceReportScreen(
            mosqueId: state.pathParameters['mosqueId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/imam/mosque/:mosqueId/supervisors-performance',
        name: 'imamSupervisorsPerformance',
        builder: (context, state) => ImamSupervisorsPerformanceScreen(
          mosqueId: state.pathParameters['mosqueId']!,
        ),
      ),
      GoRoute(
        path: '/supervisor/competitions/:mosqueId',
        name: 'supervisorCompetitions',
        builder: (context, state) {
          final mosqueId = state.pathParameters['mosqueId']!;
          return ManageCompetitionScreen(mosqueId: mosqueId);
        },
      ),
      GoRoute(
        path: '/parent/notes',
        name: 'parentNotes',
        builder: (context, state) {
          return FutureBuilder(
            future: sl<ChildRepository>().getMyChildren(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final childIds = snapshot.data!.map((c) => c.id).toList();
              if (childIds.isEmpty) {
                return const Scaffold(
                  body: Center(child: Text('أضف أطفالاً أولاً')),
                );
              }
              return NotesInboxScreen(childIds: childIds);
            },
          );
        },
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
