import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/children_bloc.dart';
import '../bloc/children_event.dart';

/// بطاقة "أضف ابنك الأول" عند عدم وجود أبناء
class HomeEmptyChildren extends StatelessWidget {
  const HomeEmptyChildren({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.push('/parent/children/add');
        if (context.mounted) {
          context.read<ChildrenBloc>().add(const ChildrenLoad());
        }
      },
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.child_care_rounded, color: Color(0xFF4CAF50), size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'أضف ابنك الأول',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C)),
            ),
            const SizedBox(height: 6),
            Text(
              'اضغط لإضافة ابن وربطه بمسجد',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'إضافة ابن',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
