import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/mosque/presentation/bloc/mosque_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'injection_container.dart';

/// نقطة بداية التطبيق
class SalatiHayatiApp extends StatelessWidget {
  const SalatiHayatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider<MosqueBloc>(create: (_) => sl<MosqueBloc>()),
      ],
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final appRouter = AppRouter(authBloc: authBloc);

          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,

            // ─── الثيم ───
            theme: AppTheme.lightTheme,

            // ─── الاتجاه: عربي (RTL) ───
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [Locale('ar', 'SA')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // ─── GoRouter ───
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
