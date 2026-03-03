import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/supabase_client.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';
import '../../../../models/child_model.dart';
import '../widgets/child_list_card.dart';

/// 📁 lib/app/features/parent/presentation/screens/children_screen.dart
class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  /// childId → مرتبط بمسجد؟
  Map<String, bool> _linkedMap = {};

  /// جلب حالة الربط لكل الأبناء دفعة واحدة (query واحد)
  Future<void> _fetchLinkStatus(List<ChildModel> children) async {
    if (children.isEmpty) return;
    final childIds = children.map((c) => c.id).toList();
    try {
      final res = await supabase
          .from('mosque_children')
          .select('child_id')
          .inFilter('child_id', childIds)
          .eq('is_active', true);
      final linkedIds = {
        for (final row in (res as List)) row['child_id'] as String,
      };
      if (mounted) {
        setState(() {
          _linkedMap = {
            for (final c in children) c.id: linkedIds.contains(c.id),
          };
        });
      }
    } catch (_) {
      // silent — الحالة ستُعاد عند pull-to-refresh
    }
  }

  Future<void> _refresh() async {
    context.read<ChildrenBloc>().add(const ChildrenLoad());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: BlocConsumer<ChildrenBloc, ChildrenState>(
          listener: (context, state) {
            if (state is ChildrenLoaded) {
              _fetchLinkStatus(state.children);
            } else if (state is ChildrenLoadedWithCredentials) {
              _fetchLinkStatus(state.children);
            }
          },
          builder: (context, state) {
            final children = state is ChildrenLoaded
                ? state.children
                : state is ChildrenLoadedWithCredentials
                    ? state.children
                    : <ChildModel>[];
            final isLoading =
                state is ChildrenLoading || state is ChildrenInitial;
            final hasUnlinked = _linkedMap.isNotEmpty &&
                _linkedMap.values.any((linked) => !linked);

            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: CustomScrollView(
                // ضروري لتفعيل pull-to-refresh حتى عندما المحتوى أقل من الشاشة
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ─── Header ───
                  SliverToBoxAdapter(child: _buildHeader(context)),

                  // ─── إرشاد: أبناء غير مرتبطين ───
                  if (hasUnlinked)
                    SliverToBoxAdapter(child: _buildUnlinkedBanner()),

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
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<ChildrenBloc>()
                                  .add(const ChildrenLoad()),
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
                          (context, i) => ChildListCard(
                            child: children[i],
                            isLinked: _linkedMap[children[i].id],
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
                'أبنائي',
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
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFE65100),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
              'لا يوجد أبناء بعد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2B3C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على "إضافة ابن" لإضافة ابنك الأول',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
