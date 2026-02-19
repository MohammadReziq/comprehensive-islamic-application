import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// ويدجت عرض مسابقة واحدة
class CompetitionCard extends StatelessWidget {
  const CompetitionCard({
    super.key,
    required this.competition,
    required this.isLoading,
    this.onActivate,
    this.onDeactivate,
    this.onViewLeaderboard,
  });

  /// الحقول: id, name_ar, start_date, end_date, is_active
  final Map<String, dynamic> competition;
  final bool isLoading;
  final VoidCallback? onActivate;
  final VoidCallback? onDeactivate;
  final VoidCallback? onViewLeaderboard;

  bool get _isActive => competition['is_active'] as bool? ?? false;
  String get _name => competition['name_ar'] as String? ?? '';
  String get _startDate => competition['start_date'] as String? ?? '';
  String get _endDate => competition['end_date'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        side: BorderSide(
          color: _isActive
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border,
          width: _isActive ? 1.5 : 1,
        ),
      ),
      elevation: _isActive ? 2 : 0,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // أيقونة
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    size: 20,
                    color: _isActive ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMD),
                // الاسم والتواريخ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _name,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (_isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusRound,
                                ),
                                border: Border.all(
                                  color: AppColors.success.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                'نشطة',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_startDate  ←  $_endDate',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.spacingSM),
            // الأزرار
            Row(
              children: [
                // زر الترتيب
                TextButton.icon(
                  onPressed: onViewLeaderboard,
                  icon: const Icon(Icons.leaderboard_outlined, size: 16),
                  label: Text(
                    'الترتيب',
                    style: GoogleFonts.cairo(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const Spacer(),
                // زر تفعيل / إيقاف
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_isActive)
                  TextButton.icon(
                    onPressed: onDeactivate,
                    icon: const Icon(Icons.pause_circle_outline, size: 16),
                    label: Text(
                      'إيقاف',
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.warning,
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: onActivate,
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: Text(
                      'تفعيل',
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
