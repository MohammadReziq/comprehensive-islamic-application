import 'package:get_it/get_it.dart';

/// حاوية حقن التبعيات
final sl = GetIt.instance;

/// تهيئة كل التبعيات
Future<void> initDependencies() async {
  // ─── Core Services ───
  // TODO: sl.registerLazySingleton(() => ConnectivityService());
  // TODO: sl.registerLazySingleton(() => NotificationService());
  // TODO: sl.registerLazySingleton(() => OfflineSyncService());
  // TODO: sl.registerLazySingleton(() => PrayerTimesService());
  // TODO: sl.registerLazySingleton(() => PointsService());

  // ─── Repositories ───
  // TODO: sl.registerLazySingleton(() => AuthRepository());
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
  // TODO: sl.registerFactory(() => AuthBloc(sl()));
  // TODO: sl.registerFactory(() => ScannerCubit(sl()));
  // TODO: sl.registerFactory(() => ParentDashboardCubit(sl()));
  // TODO: sl.registerFactory(() => SupervisorDashboardCubit(sl()));
  // TODO: sl.registerFactory(() => LeaderboardCubit(sl()));
  // TODO: sl.registerFactory(() => ReportsCubit(sl()));
  // TODO: sl.registerFactory(() => RewardsCubit(sl()));
}
