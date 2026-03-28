import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/presentation/widgets/profile_widgets.dart';
import '../widgets/parent_account_health_section.dart';

/// 📁 بروفايل ولي الأمر — منفصل عن باقي الأدوار
class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is AuthPasswordChangeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح'), behavior: SnackBarBehavior.floating, backgroundColor: Color(0xFF2E8B57)),
            );
          }
          if (authState is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authState.message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated || authState.userProfile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = authState.userProfile!;

            return Scaffold(
              backgroundColor: const Color(0xFFF5F6FA),
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ProfileHeroSection(name: user.name, avatarUrl: user.avatarUrl, role: UserRole.parent),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          ProfileInfoCard(userId: user.id, name: user.name, email: user.email, phone: user.phone),
                          const SizedBox(height: 16),
                          const SizedBox(height: 16),
                          ParentAccountHealthSection(user: user),
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
