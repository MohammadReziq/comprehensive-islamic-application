import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/child_model.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';

/// بطاقة ابن واحد في قائمة أبنائي
class ChildListCard extends StatelessWidget {
  const ChildListCard({
    super.key,
    required this.child,
    required this.isLinked,
  });

  final ChildModel child;

  /// null = لم يُجلب الوضع بعد، true = مرتبط، false = غير مرتبط
  final bool? isLinked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
            color: AppColors.primary.withValues(alpha: 0.1),
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
              _LinkBadge(isLinked: isLinked!),
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
            GestureDetector(
              onTap: () async {
                await context.push('/parent/children/${child.id}/card');
                if (context.mounted) {
                  context.read<ChildrenBloc>().add(const ChildrenLoad());
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C8BFF).withValues(alpha: 0.1),
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
            const Icon(Icons.chevron_left_rounded, color: Colors.grey, size: 22),
          ],
        ),
        onTap: () async {
          await context.push('/parent/children/${child.id}/card');
          if (context.mounted) {
            context.read<ChildrenBloc>().add(const ChildrenLoad());
          }
        },
      ),
    );
  }
}

class _LinkBadge extends StatelessWidget {
  const _LinkBadge({required this.isLinked});

  final bool isLinked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isLinked ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLinked ? Icons.check_circle_rounded : Icons.link_off_rounded,
            size: 11,
            color: isLinked ? const Color(0xFF388E3C) : const Color(0xFFF57C00),
          ),
          const SizedBox(width: 3),
          Text(
            isLinked ? 'مرتبط' : 'غير مرتبط',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isLinked ? const Color(0xFF388E3C) : const Color(0xFFF57C00),
            ),
          ),
        ],
      ),
    );
  }
}
