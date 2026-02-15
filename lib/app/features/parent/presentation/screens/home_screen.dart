import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// الشاشة الرئيسية المؤقتة - ستُستبدل لاحقاً بـ Dashboard كامل
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topCenter,
              end: Alignment.center,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.paddingXL),

                // ─── ترحيب ───
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    String userName = 'مستخدم';
                    String userRole = '';
                    if (state is AuthAuthenticated && state.userProfile != null) {
                      userName = state.userProfile!.name;
                      userRole = state.userProfile!.role.nameAr;
                    }
                    return Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('👋', style: TextStyle(fontSize: 40)),
                          ),
                        ).animate().scale(
                              begin: const Offset(0.5, 0.5),
                              curve: Curves.elasticOut,
                              duration: 800.ms,
                            ),

                        const SizedBox(height: AppDimensions.spacingLG),

                        Text(
                          'مرحباً $userName',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnDark,
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                        if (userRole.isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.spacingXS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingMD,
                              vertical: AppDimensions.paddingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                            ),
                            child: Text(
                              userRole,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ).animate().fadeIn(delay: 500.ms),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppDimensions.paddingXL),

                // ─── بطاقة النجاح ───
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMD,
                    ),
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppDimensions.radiusXL),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('✅', style: TextStyle(fontSize: 48)),
                          ),
                        ).animate().fadeIn(delay: 600.ms).scale(
                              begin: const Offset(0.5, 0.5),
                              curve: Curves.elasticOut,
                              duration: 800.ms,
                            ),

                        const SizedBox(height: AppDimensions.spacingXL),

                        const Text(
                          'تم الربط مع Supabase بنجاح! 🎉',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 800.ms),

                        const SizedBox(height: AppDimensions.spacingMD),

                        Text(
                          'التطبيق جاهز للبناء عليه.\nالخطوة القادمة: بناء Dashboard كامل.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 1000.ms),

                        const Spacer(),

                        // ─── زر تسجيل الخروج ───
                        SizedBox(
                          width: double.infinity,
                          height: AppDimensions.buttonHeight,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                    const AuthLogoutRequested(),
                                  );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMD,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              AppStrings.logout,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 1200.ms),

                        const SizedBox(height: AppDimensions.paddingLG),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
