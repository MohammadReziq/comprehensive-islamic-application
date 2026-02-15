import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salati_hayati/app/core/constants/app_colors.dart';
import 'package:salati_hayati/app/core/constants/app_dimensions.dart';

/// شريط "وضع عدم الاتصال" - يظهر في أعلى الشاشة
class OfflineBanner extends StatelessWidget {
  final bool isOffline;

  const OfflineBanner({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      decoration: const BoxDecoration(color: AppColors.warning),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: AppColors.textOnPrimary,
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          Text(
            '⚡ وضع عدم الاتصال - البيانات ستُزامن لاحقاً',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -1, end: 0, duration: 300.ms);
  }
}
