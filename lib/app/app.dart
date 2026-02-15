import 'package:flutter/material.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';

/// نقطة بداية التطبيق
class SalatiHayatiApp extends StatelessWidget {
  const SalatiHayatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // ─── الثيم ───
      theme: AppTheme.lightTheme,

      // ─── الاتجاه: عربي (RTL) ───
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],

      // ─── الصفحة المؤقتة (ستُستبدل بـ GoRouter) ───
      home: const _TempHomePage(),
    );
  }
}

/// صفحة مؤقتة للاختبار - ستُحذف لاحقاً
class _TempHomePage extends StatelessWidget {
  const _TempHomePage();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.appName),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🕌',
                style: TextStyle(fontSize: 64),
              ),
              SizedBox(height: 16),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                AppStrings.appTagline,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
