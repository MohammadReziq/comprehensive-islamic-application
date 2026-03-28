import 'package:flutter/material.dart';

/// نموذج ربط الابن بمسجد (يظهر عند عدم وجود مسجد مرتبط أو كـ BottomSheet)
class ChildLinkMosqueCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isLinking;
  final VoidCallback onLink;

  const ChildLinkMosqueCard({
    super.key,
    required this.controller,
    required this.isLinking,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mosque_rounded, color: Color(0xFFFF9800), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ربط بمسجد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
                    Text('الابن غير مرتبط بأي مسجد بعد', style: TextStyle(fontSize: 12, color: Color(0xFFFF9800), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('أدخل كود المسجد الذي أعطاك إياه الإمام', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 14),
          _buildCodeInput(),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'كود المسجد',
              prefixIcon: const Icon(Icons.tag_rounded, size: 20),
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: isLinking ? null : onLink,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLinking
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('ربط', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  /// BottomSheet لإضافة مسجد إضافي
  static void showAddMosqueSheet({
    required BuildContext context,
    required TextEditingController controller,
    required bool isLinking,
    required Future<void> Function() onLink,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24, left: 20, right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ربط بمسجد إضافي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('أدخل كود المسجد الذي أعطاك إياه الإمام', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'كود المسجد',
                        prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: isLinking
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await onLink();
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: const Color(0xFF2E8B57), borderRadius: BorderRadius.circular(12)),
                      child: isLinking
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ربط', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
