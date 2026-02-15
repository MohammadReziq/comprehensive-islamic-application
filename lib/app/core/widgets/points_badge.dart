import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salati_hayati/app/core/constants/app_colors.dart';
import 'package:salati_hayati/app/core/constants/app_dimensions.dart';

/// شارة النقاط (تظهر جانب الاسم أو في الكارد)
class PointsBadge extends StatelessWidget {
  final int points;
  final bool isLarge;
  final bool showAnimation;

  const PointsBadge({
    super.key,
    required this.points,
    this.isLarge = false,
    this.showAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 10,
        vertical: isLarge ? 8 : 4,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⭐', style: TextStyle(fontSize: isLarge ? 18 : 12)),
          const SizedBox(width: 4),
          Text(
            '$points',
            style: GoogleFonts.cairo(
              fontSize: isLarge ? 20 : 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (showAnimation) {
      return widget.animate().scale(
        begin: const Offset(0, 0),
        end: const Offset(1, 1),
        duration: 500.ms,
        curve: Curves.elasticOut,
      );
    }

    return widget;
  }
}

/// عداد السلسلة 🔥
class StreakWidget extends StatelessWidget {
  final int days;
  final bool isLarge;
  final bool showAnimation;

  const StreakWidget({
    super.key,
    required this.days,
    this.isLarge = false,
    this.showAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 10,
        vertical: isLarge ? 8 : 4,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.streakGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        boxShadow: [
          BoxShadow(
            color: AppColors.streak.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: TextStyle(fontSize: isLarge ? 18 : 12)),
          const SizedBox(width: 4),
          Text(
            '$days يوم',
            style: GoogleFonts.cairo(
              fontSize: isLarge ? 18 : 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (showAnimation) {
      return widget.animate().scale(
        begin: const Offset(0, 0),
        end: const Offset(1, 1),
        duration: 600.ms,
        curve: Curves.elasticOut,
      );
    }

    return widget;
  }
}
