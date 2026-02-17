import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/mosque_bloc.dart';
import '../bloc/mosque_event.dart';
import '../bloc/mosque_state.dart';

/// بوابة المسجد: إنشاء / انضمام / بانتظار الموافقة
class MosqueGateScreen extends StatefulWidget {
  const MosqueGateScreen({super.key});

  @override
  State<MosqueGateScreen> createState() => _MosqueGateScreenState();
}

class _MosqueGateScreenState extends State<MosqueGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MosqueBloc>().add(const MosqueLoadMyMosques());
      sl<RealtimeService>().subscribeMosques((_) {
        if (mounted) {
          context.read<MosqueBloc>().add(const MosqueLoadMyMosques());
        }
      });
    });
  }

  @override
  void dispose() {
    sl<RealtimeService>().unsubscribeMosques();
    super.dispose();
  }

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
                _buildTopBar(context),
                Expanded(
                  child: BlocConsumer<MosqueBloc, MosqueState>(
              listener: (context, state) {
                if (state is MosqueError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is MosqueLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                if (state is MosqueLoaded) {
                  if (state.mosques.isEmpty) {
                    return _buildEmpty(context);
                  }
                  if (state.hasApproved) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!context.mounted) return;
                      final authState = context.read<AuthBloc>().state;
                      final userId = authState is AuthAuthenticated
                          ? authState.userProfile?.id
                          : null;
                      final isOwner = userId != null &&
                          state.mosques.any((m) =>
                              m.status == MosqueStatus.approved && m.ownerId == userId);
                      context.go(isOwner ? '/imam/dashboard' : '/supervisor/dashboard');
                    });
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  return _buildPending(context, state);
                }
                return _buildEmpty(context);
              },
            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSM,
        vertical: AppDimensions.paddingXS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
            tooltip: AppStrings.logout,
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isSupervisor = authState is AuthAuthenticated &&
        authState.userProfile?.role == UserRole.supervisor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.paddingXXL),
          const Text('🕌', style: TextStyle(fontSize: 56)),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            AppStrings.mosque,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Text(
            isSupervisor
                ? 'ادخل كود الدعوة الذي أعطاك إياه مدير المسجد لتنضم وتُسجّل الحضور'
                : AppStrings.imamGateSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXXL),
          if (!isSupervisor) ...[
            AppButton(
              text: AppStrings.createMosque,
              onPressed: () => context.push('/mosque/create'),
              icon: Icons.add_circle_outline,
            ),
            const SizedBox(height: AppDimensions.paddingMD),
          ],
          AppButton.outlined(
            text: AppStrings.joinMosque,
            onPressed: () => context.push('/mosque/join'),
            icon: Icons.group_add,
          ),
        ],
      ),
    );
  }

  Widget _buildPending(BuildContext context, MosqueLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.paddingXL),
          const Text('⏳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            AppStrings.pendingApproval,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Text(
            AppStrings.pendingApprovalDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            AppStrings.pendingApprovalByAdmin,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          ...state.mosques.map((m) => Card(
                margin: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: ListTile(
                  title: Text(m.name),
                  subtitle: Text(m.status.nameAr),
                  trailing: Icon(
                    m.status == MosqueStatus.rejected
                        ? Icons.cancel
                        : Icons.schedule,
                    color: m.status == MosqueStatus.rejected
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
              )),
        ],
      ),
    );
  }

}
