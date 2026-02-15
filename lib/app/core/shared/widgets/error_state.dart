import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salati_hayati/app/core/constants/app_colors.dart';
import 'package:salati_hayati/app/core/constants/app_dimensions.dart';
import 'package:salati_hayati/app/core/constants/app_strings.dart';

/// حالة خطأ (Error State)
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  /// خطأ عام
  const ErrorStateWidget.general({super.key, this.onRetry})
    : title = 'حدث خطأ',
      message = AppStrings.errorGeneral,
      icon = Icons.error_outline_rounded;

  /// خطأ إنترنت
  const ErrorStateWidget.noInternet({super.key, this.onRetry})
    : title = 'لا يوجد اتصال',
      message = AppStrings.errorNoInternet,
      icon = Icons.wifi_off_rounded;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            Text(
              title ?? 'حدث خطأ',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              message ?? AppStrings.errorGeneral,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spacingXL),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
