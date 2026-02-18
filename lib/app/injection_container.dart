import 'package:get_it/get_it.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/prayer_times_service.dart';
import 'core/services/points_service.dart';
import 'core/services/realtime_service.dart';
import 'core/services/attendance_validation_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/mosque/data/repositories/mosque_repository.dart';
import 'features/mosque/presentation/bloc/mosque_bloc.dart';
import 'features/parent/data/repositories/child_repository.dart';
import 'features/parent/presentation/bloc/children_bloc.dart';
import 'features/supervisor/data/repositories/supervisor_repository.dart';
import 'features/supervisor/presentation/bloc/scanner_bloc.dart';
import 'features/corrections/data/repositories/correction_repository.dart';
import 'features/corrections/presentation/bloc/correction_bloc.dart';
import 'features/notes/data/repositories/notes_repository.dart';
import 'features/notes/presentation/bloc/notes_bloc.dart';
import 'features/competitions/data/repositories/competition_repository.dart';
import 'features/competitions/presentation/bloc/competition_bloc.dart';
import 'features/imam/data/repositories/imam_repository.dart';
import 'features/imam/presentation/bloc/imam_bloc.dart';
import 'features/super_admin/data/repositories/admin_repository.dart';
import 'features/super_admin/presentation/bloc/admin_bloc.dart';
import 'features/announcements/data/repositories/announcement_repository.dart';
import 'features/announcements/presentation/bloc/announcement_bloc.dart';
import 'package:salati_hayati/app/core/router/app_router.dart';

/// حاوية حقن التبعيات
final sl = GetIt.instance;

/// تهيئة كل التبعيات
Future<void> initDependencies() async {
  // ─── Core Services ───
  sl.registerLazySingleton(() => ConnectivityService());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => OfflineSyncService(sl<ConnectivityService>()));
  sl.registerLazySingleton(() => PrayerTimesService());
  sl.registerLazySingleton(() => PointsService());
  sl.registerLazySingleton(() => RealtimeService());
  sl.registerLazySingleton(
      () => AttendanceValidationService(sl<PrayerTimesService>()));

  // ─── تهيئة الخدمات الأساسية ───
  await sl<ConnectivityService>().init();

  // ─── Repositories ───
  sl.registerLazySingleton(() => AuthRepository());
  sl.registerLazySingleton(() => MosqueRepository(sl<AuthRepository>()));
  sl.registerLazySingleton(
      () => ChildRepository(sl<AuthRepository>(), sl<MosqueRepository>()));
  sl.registerLazySingleton(() => SupervisorRepository(sl<AuthRepository>()));
  sl.registerLazySingleton(() => CorrectionRepository(sl<AuthRepository>()));
  sl.registerLazySingleton(() => NotesRepository(sl<AuthRepository>()));
  sl.registerLazySingleton(
      () => CompetitionRepository(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ImamRepository(sl<AuthRepository>()));
  sl.registerLazySingleton(() => AdminRepository(sl<AuthRepository>()));
  sl.registerLazySingleton(
      () => AnnouncementRepository(sl<AuthRepository>()));

  // ─── BLoCs / Cubits ───
  sl.registerLazySingleton(() => AuthBloc(sl<AuthRepository>()));
  sl.registerLazySingleton(() => MosqueBloc(sl<MosqueRepository>()));
  sl.registerFactory(() => ChildrenBloc(sl<ChildRepository>()));
  sl.registerFactory(() => ScannerBloc(sl<SupervisorRepository>()));
  sl.registerFactory(() => CorrectionBloc(sl<CorrectionRepository>()));
  sl.registerFactory(() => NotesBloc(sl<NotesRepository>()));
  sl.registerFactory(() => CompetitionBloc(sl<CompetitionRepository>()));
  sl.registerFactory(() => ImamBloc(sl<ImamRepository>()));
  sl.registerFactory(() => AdminBloc(sl<AdminRepository>()));
  sl.registerFactory(
      () => AnnouncementBloc(sl<AnnouncementRepository>()));

  // ─── Router ───
  sl.registerLazySingleton(() => AppRouter(authBloc: sl<AuthBloc>()));
}

