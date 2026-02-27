import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../injection_container.dart';
import '../../../../models/child_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/presentation/widgets/profile_widgets.dart';
import '../../data/repositories/child_repository.dart';

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
                      role: UserRole.parent,
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
                          const SizedBox(height: 16),
                          _AccountHealthSection(user: user),
                          const SizedBox(height: 16),
                          const ProfileLogoutButton(),
                          const SizedBox(height: 12),
                          const ProfileDeleteAccountButton(),
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
/// قسم أبناء ولي الأمر
// ═══════════════════════════════════════════════════════════════════
class _ChildrenSection extends StatelessWidget {
  const _ChildrenSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChildModel>>(
      future: sl<ChildRepository>().getMyChildren(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final children = snapshot.data!;

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
                      color: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: Color(0xFF5C6BC0),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'أبنائي (${children.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...children.map((c) => _buildChildTile(context, c)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildTile(BuildContext context, ChildModel c) {
    return GestureDetector(
      onTap: () => context.push('/parent/children/${c.id}/card'),
      child: Container(
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
                color: const Color(0xFF5C6BC0).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  c.name.isNotEmpty ? c.name[0] : '؟',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5C6BC0),
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
                    c.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                  Text(
                    '${c.age} سنة · ${c.totalPoints} نقطة',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // streak badge
            if (c.currentStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF7043),
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${c.currentStreak}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF7043),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
/// قسم صحة الحساب لولي الأمر
// ═══════════════════════════════════════════════════════════════════
class _AccountHealthSection extends StatefulWidget {
  final dynamic user;
  const _AccountHealthSection({required this.user});
  @override
  State<_AccountHealthSection> createState() => _AccountHealthSectionState();
}

class _AccountHealthSectionState extends State<_AccountHealthSection> {
  List<_HealthItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  Future<void> _evaluate() async {
    final user = widget.user;
    final items = <_HealthItem>[];

    // 1. الاسم
    final hasName = user.name.isNotEmpty && user.name != 'مستخدم جديد';
    items.add(
      _HealthItem(
        label: 'الاسم',
        icon: Icons.person_rounded,
        ok: hasName,
        hint: hasName ? user.name : 'لم يُحدد بعد',
      ),
    );

    // 2. البريد المفعّل
    final authUser = Supabase.instance.client.auth.currentUser;
    final emailConfirmed = authUser?.emailConfirmedAt != null;
    items.add(
      _HealthItem(
        label: 'البريد المفعّل',
        icon: Icons.email_rounded,
        ok: emailConfirmed,
        hint: emailConfirmed ? 'مفعّل ✓' : 'لم يتم التأكيد',
      ),
    );

    // 3. الهاتف
    final hasPhone = user.phone != null && (user.phone as String).isNotEmpty;
    items.add(
      _HealthItem(
        label: 'الهاتف',
        icon: Icons.phone_rounded,
        ok: hasPhone,
        hint: hasPhone ? user.phone : 'غير محدد',
      ),
    );

    // 4. أبناء
    try {
      final children = await sl<ChildRepository>().getMyChildren();
      final hasChildren = children.isNotEmpty;
      items.add(
        _HealthItem(
          label: 'الأبناء',
          icon: Icons.child_care_rounded,
          ok: hasChildren,
          hint: hasChildren ? '${children.length} أبناء' : 'لا يوجد أبناء',
          route: hasChildren ? null : '/parent/children/add',
        ),
      );

      // 5. كل ابن مرتبط بمسجد
      if (hasChildren) {
        final childIds = children.map((c) => c.id).toList();
        final linkedIds = await sl<ChildRepository>().getLinkedChildIds(
          childIds,
        );
        final linked = linkedIds.length;
        final allLinked = linked == children.length;
        items.add(
          _HealthItem(
            label: 'ربط بمسجد',
            icon: Icons.mosque_rounded,
            ok: allLinked,
            hint: allLinked
                ? 'كل الأبناء مرتبطون'
                : '$linked/${children.length} مرتبطون',
            route: allLinked ? null : '/parent/children',
          ),
        );
      }
    } catch (_) {
      items.add(
        _HealthItem(
          label: 'الأبناء',
          icon: Icons.child_care_rounded,
          ok: false,
          hint: 'خطأ في الجلب',
        ),
      );
    }

    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final doneCount = _items.where((i) => i.ok).length;
    final total = _items.length;
    final progress = total > 0 ? doneCount / total : 0.0;
    final allDone = doneCount == total;
    final progressColor = allDone
        ? const Color(0xFF4CAF50)
        : doneCount >= total - 1
        ? const Color(0xFFFFB300)
        : const Color(0xFFFF7043);

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
          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: progressColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'صحة الحساب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                    Text(
                      '$doneCount/$total مكتمل',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Circular progress
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                      strokeWidth: 4,
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 14),
          // Items
          ..._items.map(
            (item) => GestureDetector(
              onTap: item.route != null
                  ? () => context.push(item.route!)
                  : null,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:
                            (item.ok
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFF7043))
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.ok ? Icons.check_rounded : Icons.close_rounded,
                        size: 16,
                        color: item.ok
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF7043),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(item.icon, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2B3C),
                        ),
                      ),
                    ),
                    Text(
                      item.hint,
                      style: TextStyle(
                        fontSize: 11,
                        color: item.ok
                            ? Colors.grey.shade500
                            : const Color(0xFFFF7043),
                        fontWeight: item.ok ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                    if (item.route != null) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_left,
                        size: 16,
                        color: Color(0xFFFF7043),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthItem {
  final String label;
  final IconData icon;
  final bool ok;
  final String hint;
  final String? route;
  const _HealthItem({
    required this.label,
    required this.icon,
    required this.ok,
    required this.hint,
    this.route,
  });
}
