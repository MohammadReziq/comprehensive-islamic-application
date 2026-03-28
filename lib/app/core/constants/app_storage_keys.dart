/// مفاتيح التخزين المحلي
class AppStorageKeys {
  AppStorageKeys._();

  /// هل شاف المستخدم الـ onboarding التعريفي (قبل تسجيل الدخول)
  static const String onboardingSeen = 'onboarding_seen';

  /// هل شاف الإمام الـ onboarding الخاص به (بعد أول تسجيل دخول)
  static const String imamOnboardingSeen = 'imam_onboarding_seen';

  /// هل شاف المشرف الـ onboarding الخاص به (بعد أول تسجيل دخول)
  static const String supervisorOnboardingSeen = 'supervisor_onboarding_seen';

  /// هل شاف ولي الأمر الـ onboarding الخاص به (بعد أول تسجيل دخول)
  static const String parentOnboardingSeen = 'parent_onboarding_seen';

  /// المسجد المختار حالياً للمشرف (لدعم تعدد المساجد)
  static const String supervisorSelectedMosqueId = 'supervisor_selected_mosque_id';
}
