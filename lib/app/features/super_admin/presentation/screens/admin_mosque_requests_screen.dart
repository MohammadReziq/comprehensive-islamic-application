import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../mosque/presentation/bloc/mosque_bloc.dart';
import '../../../mosque/presentation/bloc/mosque_event.dart';
import '../../../mosque/presentation/bloc/mosque_state.dart';
import '../../../../models/mosque_model.dart';

/// شاشة طلبات المساجد للسوبر أدمن: قائمة طلبات قيد المراجعة + موافقة/رفض
class AdminMosqueRequestsScreen extends StatefulWidget {
  const AdminMosqueRequestsScreen({super.key});

  @override
  State<AdminMosqueRequestsScreen> createState() => _AdminMosqueRequestsScreenState();
}

class _AdminMosqueRequestsScreenState extends State<AdminMosqueRequestsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MosqueBloc>().add(const MosqueLoadPendingForAdmin());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(
          title: 'طلبات المساجد',
          subtitle: 'سوبر أدمن',
          items: [
            AppDrawerItem(
              title: 'طلبات المساجد',
              icon: Icons.mosque,
              onTap: () => context.go('/admin'),
            ),
          ],
          onLogout: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
        ),
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
                  return _buildList(context, state.mosques);
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
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'القائمة',
          ),
          const Text(
            'طلبات المساجد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.paddingXXL),
          const Text('🕌', style: TextStyle(fontSize: 56)),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            AppStrings.adminMosqueRequests,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Text(
            AppStrings.adminMosqueRequestsDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXXL),
          Text(
            AppStrings.noData,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<MosqueModel> mosques) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.paddingMD),
                const Text('🕌', style: TextStyle(fontSize: 48)),
                const SizedBox(height: AppDimensions.spacingSM),
                Text(
                  AppStrings.adminMosqueRequests,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  AppStrings.adminMosqueRequestsDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLG),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final m = mosques[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (m.address != null && m.address!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              m.address!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        const SizedBox(height: AppDimensions.paddingSM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                context.read<MosqueBloc>().add(MosqueRejectRequest(m.id));
                              },
                              icon: const Icon(Icons.close, size: 20, color: AppColors.error),
                              label: Text(
                                AppStrings.reject,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () {
                                context.read<MosqueBloc>().add(MosqueApproveRequest(m.id));
                              },
                              icon: const Icon(Icons.check, size: 20),
                              label: Text(AppStrings.approve),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: mosques.length,
            ),
          ),
        ),
      ],
    );
  }
}
