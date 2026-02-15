import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salati_hayati/app/core/constants/app_colors.dart';

/// إشعارات أنيقة داخل التطبيق (Toast-style)
class AppToast {
  AppToast._();

  /// إشعار نجاح ✅
  static void success(
    BuildContext context, {
    required String title,
    required String description,
    Duration? duration,
  }) {
    ElegantNotification.success(
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      description: Text(
        description,
        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
      ),
      toastDuration: duration ?? const Duration(seconds: 3),
      showProgressIndicator: true,
    ).show(context);
  }

  /// إشعار خطأ ❌
  static void error(
    BuildContext context, {
    required String title,
    required String description,
    Duration? duration,
  }) {
    ElegantNotification.error(
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      description: Text(
        description,
        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
      ),
      toastDuration: duration ?? const Duration(seconds: 4),
      showProgressIndicator: true,
    ).show(context);
  }

  /// إشعار معلومات ℹ️
  static void info(
    BuildContext context, {
    required String title,
    required String description,
    Duration? duration,
  }) {
    ElegantNotification.info(
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      description: Text(
        description,
        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
      ),
      toastDuration: duration ?? const Duration(seconds: 3),
      showProgressIndicator: true,
    ).show(context);
  }

  /// إشعار حضور تسجيل ✅ (مخصص للحضور)
  static void attendanceRecorded(
    BuildContext context, {
    required String childName,
    required String prayerName,
  }) {
    success(
      context,
      title: 'تم تسجيل الحضور ✅',
      description: '$childName - $prayerName',
      duration: const Duration(seconds: 2),
    );
  }

  /// إشعار شارة جديدة 🏅
  static void newBadge(
    BuildContext context, {
    required String badgeName,
    required String emoji,
  }) {
    success(
      context,
      title: '$emoji شارة جديدة!',
      description: 'حصلت على شارة "$badgeName"',
      duration: const Duration(seconds: 4),
    );
  }
}
