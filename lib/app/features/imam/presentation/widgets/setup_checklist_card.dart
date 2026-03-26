import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// بطاقة إعداد المسجد — تظهر على dashboard الإمام
/// حتى يُكمل الخطوتين: إضافة مشرف + إطلاق مسابقة
class SetupChecklistCard extends StatelessWidget {
  final bool hasAddedSupervisor;
  final bool hasCreatedCompetition;
  final VoidCallback onAddSupervisor;
  final VoidCallback onCreateCompetition;

  const SetupChecklistCard({
    super.key,
    required this.hasAddedSupervisor,
    required this.hasCreatedCompetition,
    required this.onAddSupervisor,
    required this.onCreateCompetition,
  });

  bool get _allDone => hasAddedSupervisor && hasCreatedCompetition;

  int get _completedCount {
    int c = 1; // المسجد دائماً مكتمل
    if (hasAddedSupervisor) c++;
    if (hasCreatedCompetition) c++;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    if (_allDone) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                Icon(Icons.construction, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Text(
                  'إعداد مسجدك',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_completedCount/3',
                  style: GoogleFonts.cairo(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // خطوة 1: المسجد (دائماً مكتملة)
            _CheckTile(
              title: 'إنشاء المسجد',
              subtitle: 'تم بنجاح! 🎉',
              isCompleted: true,
            ),

            // خطوة 2: المشرف
            _CheckTile(
              title: 'إضافة مشرف',
              subtitle: 'المشرف يسجّل حضور الأطفال',
              isCompleted: hasAddedSupervisor,
              actionLabel: hasAddedSupervisor ? null : 'إضافة الآن',
              onAction: hasAddedSupervisor ? null : onAddSupervisor,
            ),

            // خطوة 3: المسابقة
            _CheckTile(
              title: 'إطلاق مسابقة',
              subtitle: 'حفّز الأطفال على المحافظة على الصلاة',
              isCompleted: hasCreatedCompetition,
              actionLabel: hasCreatedCompetition ? null : 'إطلاق الآن',
              onAction: hasCreatedCompetition ? null : onCreateCompetition,
            ),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _completedCount / 3,
                minHeight: 8,
                backgroundColor: AppColors.backgroundMuted,
                valueColor: const AlwaysStoppedAnimation(AppColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CheckTile({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? AppColors.success : AppColors.textHint,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: GoogleFonts.cairo(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
