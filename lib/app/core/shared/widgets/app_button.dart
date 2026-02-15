import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salati_hayati/app/core/constants/app_colors.dart';
import 'package:salati_hayati/app/core/constants/app_dimensions.dart';

/// زر التطبيق الموحد
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isSmall;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isSmall = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
  });

  /// زر أساسي (Filled)
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : isOutlined = false,
       isSmall = false,
       backgroundColor = null,
       textColor = null;

  /// زر ثانوي (Outlined)
  const AppButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : isOutlined = true,
       isSmall = false,
       backgroundColor = null,
       textColor = null;

  /// زر صغير
  const AppButton.small({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
  }) : isOutlined = false,
       isSmall = true;

  /// زر نجاح (أخضر)
  const AppButton.success({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : isOutlined = false,
       isSmall = false,
       backgroundColor = AppColors.success,
       textColor = AppColors.textOnPrimary;

  /// زر خطر (أحمر)
  const AppButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : isOutlined = false,
       isSmall = false,
       backgroundColor = AppColors.error,
       textColor = AppColors.textOnPrimary;

  @override
  Widget build(BuildContext context) {
    final height = isSmall
        ? AppDimensions.buttonHeightSM
        : AppDimensions.buttonHeight;

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: (backgroundColor != null || textColor != null)
            ? ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: textColor,
              )
            : null,
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: isOutlined ? AppColors.primary : AppColors.textOnPrimary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 18 : 20),
          const SizedBox(width: AppDimensions.spacingSM),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: isSmall ? 13 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: isSmall ? 13 : 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
