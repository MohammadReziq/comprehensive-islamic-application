import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/supabase_client.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';
import '../bloc/children_state.dart';
import '../../../../models/child_model.dart';

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
                          (context, i) =>
                              _buildChildCard(context, children[i]),
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

  Widget _buildChildCard(BuildContext context, ChildModel child) {
    final isLinked = _linkedMap[child.id];

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                child.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2B3C),
                ),
              ),
            ),
            if (isLinked != null) ...[
              const SizedBox(width: 6),
              _buildLinkBadge(isLinked),
            ],
          ],
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
              onTap: () =>
                  context.push('/parent/children/${child.id}/card'),
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

  Widget _buildLinkBadge(bool isLinked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isLinked
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLinked
                ? Icons.check_circle_rounded
                : Icons.link_off_rounded,
            size: 11,
            color: isLinked
                ? const Color(0xFF388E3C)
                : const Color(0xFFF57C00),
          ),
          const SizedBox(width: 3),
          Text(
            isLinked ? 'مرتبط' : 'غير مرتبط',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isLinked
                  ? const Color(0xFF388E3C)
                  : const Color(0xFFF57C00),
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
