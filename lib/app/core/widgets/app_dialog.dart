import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salati_hayati/app/core/constants/app_colors.dart';

/// Wrapper لـ Awesome Dialog - لعرض حوارات بتصميم موحد
class AppDialog {
  AppDialog._();

  /// حوار نجاح ✅
  static void success(
    BuildContext context, {
    required String title,
    required String description,
    String? btnOkText,
    VoidCallback? onOk,
  }) {
    _show(
      context,
      dialogType: DialogType.success,
      title: title,
      desc: description,
      btnOkText: btnOkText ?? 'تم',
      btnOkOnPress: onOk ?? () {},
    );
  }

  /// حوار خطأ ❌
  static void error(
    BuildContext context, {
    required String title,
    required String description,
    String? btnOkText,
    VoidCallback? onOk,
  }) {
    _show(
      context,
      dialogType: DialogType.error,
      title: title,
      desc: description,
      btnOkText: btnOkText ?? 'حسناً',
      btnOkOnPress: onOk ?? () {},
    );
  }

  /// حوار تحذير ⚠️
  static void warning(
    BuildContext context, {
    required String title,
    required String description,
    String? btnOkText,
    VoidCallback? onOk,
  }) {
    _show(
      context,
      dialogType: DialogType.warning,
      title: title,
      desc: description,
      btnOkText: btnOkText ?? 'حسناً',
      btnOkOnPress: onOk ?? () {},
    );
  }

  /// حوار تأكيد (نعم/لا)
  static void confirm(
    BuildContext context, {
    required String title,
    required String description,
    String? btnOkText,
    String? btnCancelText,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    _show(
      context,
      dialogType: DialogType.question,
      title: title,
      desc: description,
      btnOkText: btnOkText ?? 'نعم',
      btnCancelText: btnCancelText ?? 'لا',
      btnOkOnPress: onConfirm,
      btnCancelOnPress: onCancel ?? () {},
    );
  }

  /// حوار احتفال 🎉
  static void celebration(
    BuildContext context, {
    required String title,
    required String description,
    String? btnOkText,
    VoidCallback? onOk,
  }) {
    _show(
      context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: title,
      desc: description,
      btnOkText: btnOkText ?? 'ماشاء الله! 🎉',
      btnOkOnPress: onOk ?? () {},
      headerAnimationLoop: true,
    );
  }

  /// الدالة الأساسية
  static void _show(
    BuildContext context, {
    required DialogType dialogType,
    required String title,
    required String desc,
    String? btnOkText,
    String? btnCancelText,
    VoidCallback? btnOkOnPress,
    VoidCallback? btnCancelOnPress,
    AnimType animType = AnimType.bottomSlide,
    bool headerAnimationLoop = false,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: dialogType,
      animType: animType,
      headerAnimationLoop: headerAnimationLoop,
      title: title,
      desc: desc,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      descTextStyle: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      btnOkText: btnOkText,
      btnCancelText: btnCancelText,
      btnOkOnPress: btnOkOnPress,
      btnCancelOnPress: btnCancelOnPress,
      btnOkColor: AppColors.primary,
      btnCancelColor: AppColors.textSecondary,
      borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      buttonsBorderRadius: BorderRadius.circular(12),
      dialogBorderRadius: BorderRadius.circular(20),
      useRootNavigator: true,
    ).show();
  }
}
