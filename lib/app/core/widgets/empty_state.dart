import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salati_hayati/app/core/constants/app_colors.dart';
import 'package:salati_hayati/app/core/constants/app_dimensions.dart';

/// حالة فارغة (Empty State)
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionText,
    this.onAction,
  });

  /// فارغ - لا يوجد طلاب
  const EmptyStateWidget.noStudents({super.key, this.actionText, this.onAction})
    : title = 'لا يوجد طلاب مسجلين',
      description = 'أضف طلاباً للبدء في تسجيل الحضور',
      icon = Icons.people_outline;

  /// فارغ - لا يوجد حضور
  const EmptyStateWidget.noAttendance({
    super.key,
    this.actionText,
    this.onAction,
  }) : title = 'لا يوجد حضور اليوم',
       description = 'لم يتم تسجيل أي حضور بعد',
       icon = Icons.event_available_outlined;

  /// فارغ - لا يوجد إشعارات
  const EmptyStateWidget.noNotifications({
    super.key,
    this.actionText,
    this.onAction,
  }) : title = 'لا توجد إشعارات',
       description = 'ستظهر الإشعارات الجديدة هنا',
       icon = Icons.notifications_none_outlined;

  /// فارغ - لا يوجد شارات
  const EmptyStateWidget.noBadges({super.key, this.actionText, this.onAction})
    : title = 'لا توجد شارات بعد',
      description = 'حافظ على الصلاة لتحصل على شارات 🏅',
      icon = Icons.military_tech_outlined;

  /// فارغ - لا يوجد مسابقات
  const EmptyStateWidget.noCompetitions({
    super.key, this.actionText = 'إطلاق مسابقة', this.onAction,
  }) : title = 'لا توجد مسابقات',
       description = 'أطلق مسابقة لتحفيز الأطفال على صلاة الجماعة',
       icon = Icons.emoji_events_outlined;

  /// فارغ - لا طلاب في المسجد
  const EmptyStateWidget.noStudentsInMosque({
    super.key, this.actionText, this.onAction,
  }) : title = 'لا يوجد طلاب مسجلين في المسجد',
       description = 'شارك كود المسجد مع أولياء الأمور لتسجيل أطفالهم',
       icon = Icons.people_outline;

  /// فارغ - لا طلبات انضمام
  const EmptyStateWidget.noMosqueRequests({
    super.key, this.actionText, this.onAction,
  }) : title = 'لا توجد طلبات انضمام',
       description = 'ستظهر هنا طلبات انضمام المساجد الجديدة',
       icon = Icons.inbox_outlined;

  /// فارغ - لا طلبات تصحيح
  const EmptyStateWidget.noCorrections({
    super.key, this.actionText, this.onAction,
  }) : title = 'لا توجد طلبات تصحيح',
       description = 'ستظهر طلبات التصحيح من أولياء الأمور هنا',
       icon = Icons.fact_check_outlined;

  /// فارغ - لا ملاحظات
  const EmptyStateWidget.noNotes({
    super.key, this.actionText, this.onAction,
  }) : title = 'لا توجد ملاحظات',
       description = 'ستظهر الملاحظات من المشرفين هنا',
       icon = Icons.note_alt_outlined;

  /// فارغ - ولي أمر لا أطفال
  const EmptyStateWidget.noChildren({
    super.key, this.actionText = 'إضافة طفل', this.onAction,
  }) : title = 'لم تُضف أطفالاً بعد',
       description = 'أضف أطفالك لتتابع حضورهم وتفاعلهم',
       icon = Icons.child_care;

  /// فارغ - طفل غير مربوط بمسجد
  const EmptyStateWidget.childNotLinked({
    super.key, this.actionText = 'ربط بمسجد', this.onAction,
  }) : title = 'طفلك غير مربوط بمسجد',
       description = 'اطلب كود المسجد من الإمام واربط طفلك لتفعيل المتابعة',
       icon = Icons.link_off;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primaryLight),
            ).animate().scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.elasticOut,
            ),

            const SizedBox(height: AppDimensions.spacingXL),

            // العنوان
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            if (description != null) ...[
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                description!,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.spacingXL),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
