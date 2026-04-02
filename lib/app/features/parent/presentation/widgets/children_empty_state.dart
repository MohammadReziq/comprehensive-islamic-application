import 'package:flutter/material.dart';

/// حالة الفراغ لشاشة الأبناء
class ChildrenEmptyState extends StatelessWidget {
  const ChildrenEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.child_care_rounded, color: Color(0xFF4CAF50), size: 42),
            ),
            const SizedBox(height: 18),
            const Text(
              'لا يوجد أبناء بعد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C)),
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
