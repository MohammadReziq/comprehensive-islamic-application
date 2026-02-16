/// دوال التحقق من المدخلات
class Validators {
  Validators._();

  /// تحقق من البريد الإلكتروني
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  /// تحقق من كلمة المرور
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  /// تحقق من تأكيد كلمة المرور
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != password) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  /// تحقق من الاسم
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.trim().length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }
    return null;
  }

  /// تحقق من رقم الهاتف
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // اختياري
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  /// تحقق من حقل مطلوب
  static String? validateRequired(String? value, [String fieldName = 'هذا الحقل']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  /// تحقق من العمر
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'العمر مطلوب';
    }
    final age = int.tryParse(value);
    if (age == null || age < 3 || age > 18) {
      return 'العمر يجب أن يكون بين 3 و 18';
    }
    return null;
  }

  /// تحقق من كود المسجد (6 أحرف)
  static String? validateMosqueCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'كود المسجد مطلوب';
    }
    if (value.trim().length != 6) {
      return 'كود المسجد يجب أن يكون 6 أحرف';
    }
    return null;
  }

  /// تحقق من النقاط المطلوبة
  static String? validateTargetPoints(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'النقاط المطلوبة مطلوبة';
    }
    final points = int.tryParse(value);
    if (points == null || points < 10) {
      return 'النقاط يجب أن تكون 10 على الأقل';
    }
    return null;
  }
}
