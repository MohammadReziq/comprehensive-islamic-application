import 'package:flutter/material.dart';
import 'package:salati_hayati/app/models/announcement_model.dart';

/// BottomSheet لعرض تفاصيل الإعلان — مشترك بين الإمام والأب.
///
/// استخدام:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => AnnouncementDetailSheet(
///     announcement: a,
///     showDeleteButton: true,           // للإمام فقط
///     onDelete: () { ... },
///   ),
/// );
/// ```
class AnnouncementDetailSheet extends StatelessWidget {
  const AnnouncementDetailSheet({
    super.key,
    required this.announcement,
    this.showDeleteButton = false,
    this.onDelete,
  });

  final AnnouncementModel announcement;
  final bool showDeleteButton;
  final VoidCallback? onDelete;

  /// دالة مساعدة لتنسيق التاريخ.
  static String formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${d.year}/${d.month}/${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── العنوان + زر الإغلاق ───
            Row(
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ─── النص ───
            Text(
              announcement.body,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            // ─── التاريخ ───
            Text(
              formatDate(announcement.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            // ─── زر الحذف (للإمام فقط) ───
            if (showDeleteButton && onDelete != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                label: const Text(
                  'حذف الإعلان',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
