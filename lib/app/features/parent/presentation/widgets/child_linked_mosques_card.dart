import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';
import 'child_qr_card.dart';

/// بطاقة المساجد المرتبطة بالابن + زر إضافة مسجد
class ChildLinkedMosquesCard extends StatelessWidget {
  final List<MosqueLink> linkedMosques;
  final VoidCallback onAddMosque;

  const ChildLinkedMosquesCard({
    super.key,
    required this.linkedMosques,
    required this.onAddMosque,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mosque_rounded, color: Color(0xFF2E8B57), size: 22),
              SizedBox(width: 8),
              Text('المساجد المرتبطة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
            ],
          ),
          const SizedBox(height: 14),
          ...linkedMosques.map(_mosqueRow),
          const Divider(height: 20),
          GestureDetector(
            onTap: onAddMosque,
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B57).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded, color: Color(0xFF2E8B57), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('ربط بمسجد إضافي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2E8B57))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mosqueRow(MosqueLink m) {
    final isPrimary = m.type == MosqueType.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                m.mosqueName.isNotEmpty ? m.mosqueName[0] : 'م',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2E8B57)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.mosqueName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2B3C))),
                Text('رقم ${m.localNumber.toString().padLeft(3, '0')}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFF2E8B57).withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPrimary ? 'أساسي' : 'إضافي',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPrimary ? const Color(0xFF2E8B57) : Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
