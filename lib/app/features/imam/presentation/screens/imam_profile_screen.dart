import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../models/mosque_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';
import '../../../profile/presentation/widgets/profile_widgets.dart';

/// 📁 بروفايل الإمام — منفصل عن باقي الأدوار
class ImamProfileScreen extends StatelessWidget {
  const ImamProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is AuthPasswordChangeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تغيير كلمة المرور بنجاح'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xFF2E8B57),
              ),
            );
          }
          if (authState is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authState.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated ||
                authState.userProfile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = authState.userProfile!;

            return Scaffold(
              backgroundColor: const Color(0xFFF5F6FA),
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ProfileHeroSection(
                      name: user.name,
                      avatarUrl: user.avatarUrl,
                      role: UserRole.imam,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          ProfileInfoCard(
                            userId: user.id,
                            name: user.name,
                            email: user.email,
                            phone: user.phone,
                          ),
                          const SizedBox(height: 16),
                          const _MosqueSection(),
                          const SizedBox(height: 16),
                          const ProfileLogoutButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
/// قسم مساجد الإمام
// ═══════════════════════════════════════════════════════════════════
class _MosqueSection extends StatelessWidget {
  const _MosqueSection();

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
        if (approved.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E8B57).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: Color(0xFF2E8B57),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'مسجدي',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...approved.map((m) => _buildMosqueTile(m)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMosqueTile(MosqueModel m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                m.name.isNotEmpty ? m.name[0] : '؟',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E8B57),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                if (m.code.isNotEmpty)
                  Text(
                    'كود: ${m.code}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
