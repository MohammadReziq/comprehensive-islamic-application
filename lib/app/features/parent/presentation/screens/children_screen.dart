import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';
import '../../../../models/child_model.dart';
import '../widgets/child_list_card.dart';
import '../widgets/feature_gradient_header.dart';
import '../widgets/children_empty_state.dart';

/// شاشة قائمة الأبناء
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
            final linkedIds = state is ChildrenLoaded
                ? state.linkedChildIds
                : state is ChildrenLoadedWithCredentials
                    ? state.linkedChildIds
                    : <String>{};
            final isLoading = state is ChildrenLoading || state is ChildrenInitial;
            final hasUnlinked = linkedIds.isNotEmpty
                ? children.any((c) => !linkedIds.contains(c.id))
                : children.isNotEmpty && linkedIds.isEmpty
                    ? false // لم يُجلب بعد
                    : false;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ChildrenBloc>().add(const ChildrenLoad());
              },
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: FeatureGradientHeader(title: 'أبنائي'),
                  ),
                  if (hasUnlinked)
                    SliverToBoxAdapter(child: _buildUnlinkedBanner()),
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
                              onPressed: () => context.read<ChildrenBloc>().add(const ChildrenLoad()),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (children.isEmpty)
                    const SliverFillRemaining(child: ChildrenEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => ChildListCard(
                            child: children[i],
                            isLinked: linkedIds.contains(children[i].id),
                          ),
                          childCount: children.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/parent/children/add');
            if (!context.mounted) return;
            context.read<ChildrenBloc>().add(const ChildrenLoad());
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'إضافة ابن',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlinkedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: const Row(
        children: [
          Icon(Icons.mosque_rounded, color: Color(0xFFF57C00), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'بعض أبنائك لم يُربطوا بمسجد بعد — اضغط على بطاقة الابن لربطه',
              style: TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
