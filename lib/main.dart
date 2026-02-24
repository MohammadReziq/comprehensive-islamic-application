import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/core/network/supabase_client.dart';
import 'app/core/services/notification_service.dart';
import 'app/core/services/offline_sync_service.dart';
import 'app/injection_container.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── إعدادات النظام ───
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // شريط الحالة شفاف
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ─── إعداد Supabase ───
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // ─── إعداد Firebase (FCM فقط) ───
  await Firebase.initializeApp();

  // ─── إعداد DI ───
  await initDependencies();

  // ─── إعداد Offline Sync ───
  await sl<OfflineSyncService>().init();

  // ─── إعداد الإشعارات ───
  await sl<NotificationService>().init();

  runApp(const SalatiHayatiApp());
}
