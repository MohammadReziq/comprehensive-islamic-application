import 'package:get_it/get_it.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/prayer_times_service.dart';
import 'core/services/points_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

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

  // ─── تهيئة الخدمات الأساسية ───
  await sl<ConnectivityService>().init();

  // ─── Repositories ───
  sl.registerLazySingleton(() => AuthRepository());
  // TODO: sl.registerLazySingleton(() => MosqueRepository());
  // TODO: sl.registerLazySingleton(() => ChildRepository());
  // TODO: sl.registerLazySingleton(() => AttendanceRepository());
  // TODO: sl.registerLazySingleton(() => CorrectionRepository());
  // TODO: sl.registerLazySingleton(() => NoteRepository());
  // TODO: sl.registerLazySingleton(() => RewardRepository());
  // TODO: sl.registerLazySingleton(() => BadgeRepository());
  // TODO: sl.registerLazySingleton(() => LeaderboardRepository());
  // TODO: sl.registerLazySingleton(() => ReportRepository());

  // ─── BLoCs / Cubits ───
  sl.registerFactory(() => AuthBloc(sl<AuthRepository>()));
  // TODO: sl.registerFactory(() => ScannerCubit(sl()));
  // TODO: sl.registerFactory(() => ParentDashboardCubit(sl()));
  // TODO: sl.registerFactory(() => SupervisorDashboardCubit(sl()));
  // TODO: sl.registerFactory(() => LeaderboardCubit(sl()));
  // TODO: sl.registerFactory(() => ReportsCubit(sl()));
  // TODO: sl.registerFactory(() => RewardsCubit(sl()));
}
