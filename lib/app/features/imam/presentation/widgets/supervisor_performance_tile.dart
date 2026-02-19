import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// ويدجت أداء مشرف واحد مع progress indicator
class SupervisorPerformanceTile extends StatelessWidget {
  const SupervisorPerformanceTile({
    super.key,
    required this.name,
    this.email,
    required this.todayRecords,
    required this.totalStudents,
  });

  final String name;
  final String? email;
  final int todayRecords;
  final int totalStudents;

  double get _progress =>
      totalStudents > 0 ? (todayRecords / totalStudents).clamp(0.0, 1.0) : 0.0;

  String get _percentageStr => '${(_progress * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // أفاتار
          Container(
            width: AppDimensions.avatarMD,
            height: AppDimensions.avatarMD,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMD),
          // الاسم والتفاصيل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (email != null && email!.isNotEmpty)
                  Text(
                    email!,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusRound,
                        ),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _progress >= 0.8
                                ? AppColors.success
                                : _progress >= 0.5
                                ? AppColors.primary
                                : AppColors.warning,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _percentageStr,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMD),
          // عدد التسجيلات
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$todayRecords',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'حضور',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
