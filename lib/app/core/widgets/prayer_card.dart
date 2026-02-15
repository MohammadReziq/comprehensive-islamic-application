import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salati_hayati/app/core/constants/app_colors.dart';
import 'package:salati_hayati/app/core/constants/app_dimensions.dart';
import 'package:salati_hayati/app/core/constants/app_enums.dart';

/// بطاقة الصلاة (تظهر في الداشبورد + شاشة الحضور)
class PrayerCard extends StatelessWidget {
  final Prayer prayer;
  final String? time;
  final bool isCompleted;
  final bool isCurrent;
  final LocationType? locationType;
  final int? points;
  final VoidCallback? onTap;

  const PrayerCard({
    super.key,
    required this.prayer,
    this.time,
    this.isCompleted = false,
    this.isCurrent = false,
    this.locationType,
    this.points,
    this.onTap,
  });

  Color get _prayerColor {
    switch (prayer) {
      case Prayer.fajr:
        return AppColors.fajr;
      case Prayer.dhuhr:
        return AppColors.dhuhr;
      case Prayer.asr:
        return AppColors.asr;
      case Prayer.maghrib:
        return AppColors.maghrib;
      case Prayer.isha:
        return AppColors.isha;
    }
  }

  IconData get _prayerIcon {
    switch (prayer) {
      case Prayer.fajr:
        return Icons.nightlight_round;
      case Prayer.dhuhr:
        return Icons.wb_sunny;
      case Prayer.asr:
        return Icons.wb_twilight;
      case Prayer.maghrib:
        return Icons.nights_stay;
      case Prayer.isha:
        return Icons.dark_mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMD,
            vertical: AppDimensions.paddingSM + 4,
          ),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.successLight
                : isCurrent
                ? _prayerColor.withAlpha(15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            border: Border.all(
              color: isCurrent
                  ? _prayerColor.withAlpha(100)
                  : isCompleted
                  ? AppColors.success.withAlpha(50)
                  : AppColors.border,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // أيقونة الصلاة
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _prayerColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Icon(_prayerIcon, color: _prayerColor, size: 22),
              ),

              const SizedBox(width: AppDimensions.spacingMD),

              // اسم الصلاة + الوقت
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.nameAr,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (time != null)
                      Text(
                        time!,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              // حالة + نقاط
              if (isCompleted) ...[
                if (locationType != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: locationType == LocationType.mosque
                          ? AppColors.primarySurface
                          : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusRound,
                      ),
                    ),
                    child: Text(
                      locationType == LocationType.mosque ? '🕌' : '🏠',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                if (points != null)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withAlpha(30),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusRound,
                      ),
                    ),
                    child: Text(
                      '+$points',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
                ),
              ] else if (isCurrent) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _prayerColor,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusRound,
                    ),
                  ),
                  child: Text(
                    'الحالية',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
