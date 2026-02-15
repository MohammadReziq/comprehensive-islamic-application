import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';

void main() async {
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

  // TODO: إعداد Firebase
  // await Firebase.initializeApp();

  // TODO: إعداد Supabase
  // await Supabase.initialize(url: '', anonKey: '');

  // TODO: إعداد DI
  // await initDependencies();

  runApp(const SalatiHayatiApp());
}
