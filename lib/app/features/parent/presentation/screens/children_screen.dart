import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';
import '../../../../models/child_model.dart';

/// 📁 lib/app/features/parent/presentation/screens/children_screen.dart
class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: BlocBuilder<ChildrenBloc, ChildrenState>(
          builder: (context, state) {
            final children = state is ChildrenLoaded
                ? state.children
                : state is ChildrenLoadedWithCredentials
                ? state.children
                : <ChildModel>[];
            final isLoading =
                state is ChildrenLoading || state is ChildrenInitial;

            return CustomScrollView(
              slivers: [
                // ─── Header ───
                SliverToBoxAdapter(child: _buildHeader(context)),

                // ─── Content ───
                if (isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is ChildrenError)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<ChildrenBloc>().add(
                              const ChildrenLoad(),
                            ),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (children.isEmpty)
                  SliverFillRemaining(child: _buildEmpty(context))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _buildChildCard(context, children[i]),
                        childCount: children.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/parent/children/add').then((_) {
            context.read<ChildrenBloc>().add(const ChildrenLoad());
          }),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'إضافة طفل',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1B5E8A), Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'أطفالي',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildModel child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              child.name.isNotEmpty ? child.name[0] : '؟',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: Text(
          child.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A2B3C),
          ),
        ),
        subtitle: Text(
          '${child.age} سنة · ${child.totalPoints} نقطة',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر البطاقة
            GestureDetector(
              onTap: () => context.push('/parent/children/${child.id}/card'),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C8BFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_rounded,
                  color: Color(0xFF5C8BFF),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_left_rounded,
              color: Colors.grey,
              size: 22,
            ),
          ],
        ),
        onTap: () => context.push('/parent/children/${child.id}/card'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.child_care_rounded,
                color: Color(0xFF4CAF50),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'لا يوجد أطفال بعد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2B3C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على "إضافة طفل" لإضافة طفلك الأول',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
