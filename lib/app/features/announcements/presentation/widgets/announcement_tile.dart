import 'package:flutter/material.dart';
import 'package:salati_hayati/app/models/announcement_model.dart';
import '../../../../core/constants/app_colors.dart';

/// بطاقة إعلان — مشتركة بين شاشة الإمام وشاشة الأب.
///
/// [isRead] تُستخدم في شاشة الأب فقط (لتغيير التصميم).
/// [isPinned] تُستخدم في شاشة الإمام فقط (لتغيير الأيقونة).
class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({
    super.key,
    required this.announcement,
    required this.onTap,
    this.isRead = false,
    this.isPinned = false,
    this.showReadDot = false,
  });

  final AnnouncementModel announcement;
  final VoidCallback onTap;
  final bool isRead;
  final bool isPinned;
  final bool showReadDot;

  @override
  Widget build(BuildContext context) {
    final iconColor = isRead ? Colors.grey : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: (showReadDot && !isRead)
            ? BorderSide(color: AppColors.primary.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── أيقونة ───
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.campaign_rounded,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // ─── النص ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                        color: isRead ? Colors.grey.shade700 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // ─── نقطة غير مقروء ───
              if (showReadDot && !isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
