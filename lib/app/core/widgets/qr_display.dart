import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:salati_hayati/app/core/constants/app_colors.dart';
import 'package:salati_hayati/app/core/constants/app_dimensions.dart';

/// عرض QR Code
class QrDisplay extends StatelessWidget {
  final String data;
  final double size;
  final String? childName;
  final String? mosqueId;
  final bool showDecorations;

  const QrDisplay({
    super.key,
    required this.data,
    this.size = AppDimensions.qrCodeMD,
    this.childName,
    this.mosqueId,
    this.showDecorations = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // بطاقة QR
        Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(20),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: showDecorations
                    ? Border.all(
                        color: AppColors.primaryLight.withAlpha(50),
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                children: [
                  if (showDecorations) ...[
                    // زخرفة فوقية
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                      ),
                      child: Text(
                        '🕌 صلاتي حياتي',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMD),
                  ],

                  // QR الفعلي
                  QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: size,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.primaryDark,
                    ),
                  ),

                  if (childName != null) ...[
                    const SizedBox(height: AppDimensions.spacingMD),
                    Text(
                      childName!,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: 400.ms,
            ),
      ],
    );
  }
}
