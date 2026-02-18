import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../../models/mosque_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';
import '../../../parent/data/repositories/child_repository.dart';

/// شاشة الملف الشخصي — واحدة لكل الأدوار (تُعرض محتوى مختلف حسب الدور)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated ||
              authState.userProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = authState.userProfile!;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimensions.paddingXL),
                  _buildAvatar(user.name),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Text(
                    user.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMD,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusRound,
                      ),
                    ),
                    child: Text(
                      user.role.nameAr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  if (user.email != null && user.email!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      user.email!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.phone!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.paddingXL),
                  if (user.role == UserRole.imam ||
                      user.role == UserRole.supervisor)
                    _MosqueSection(),
                  if (user.role == UserRole.parent) _ChildrenSection(),
                  const SizedBox(height: AppDimensions.paddingXL),
                  OutlinedButton.icon(
                    onPressed: () => context.read<AuthBloc>().add(
                      const AuthLogoutRequested(),
                    ),
                    icon: const Icon(
                      Icons.logout,
                      size: 20,
                      color: Colors.white70,
                    ),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: Colors.white70),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0] : '?';
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _MosqueSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MosqueBloc, MosqueState>(
      builder: (context, state) {
        if (state is! MosqueLoaded || state.mosques.isEmpty) {
          return const SizedBox.shrink();
        }
        final approved = state.mosques
            .where((m) => m.status == MosqueStatus.approved)
            .toList();
        if (approved.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mosque,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'مسجدي',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...approved.map((m) => _MosqueTile(m)),
            ],
          ),
        );
      },
    );
  }
}

Widget _MosqueTile(MosqueModel m) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      m.name,
      style: TextStyle(
        fontSize: 15,
        color: Colors.white.withValues(alpha: 0.95),
      ),
    ),
  );
}

class _ChildrenSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChildModel>>(
      future: sl<ChildRepository>().getMyChildren(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final children = snapshot.data!;
        if (children.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'أطفالي',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...children.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.accent.withValues(
                          alpha: 0.3,
                        ),
                        child: Text(
                          c.name.isNotEmpty ? c.name[0] : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${c.name} · ${c.age} سنة',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
