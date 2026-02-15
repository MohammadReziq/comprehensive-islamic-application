import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/user_model.dart';
import '../../../../core/network/supabase_client.dart';

/// مستودع المصادقة - يتعامل مع Supabase Auth
class AuthRepository {
  // ─── Auth Getters ───

  /// المستخدم الحالي من Supabase Auth
  User? get currentAuthUser => supabase.auth.currentUser;

  /// هل المستخدم مسجّل دخول؟
  bool get isLoggedIn => currentAuthUser != null;

  /// Stream لمتابعة تغييرات حالة Auth
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // ─── تسجيل حساب جديد ───

  /// إنشاء حساب جديد بالإيميل وكلمة السر
  /// يُنشئ record تلقائياً في جدول users عبر الـ trigger
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String role = 'parent',
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role,
      },
    );
    return response;
  }

  // ─── تسجيل دخول ───

  /// تسجيل دخول بالإيميل وكلمة السر
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // ─── تسجيل خروج ───

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // ─── بيانات المستخدم من جدول users ───

  /// جلب بيانات المستخدم الحالي من جدول users
  Future<UserModel?> getCurrentUserProfile() async {
    final authUser = currentAuthUser;
    if (authUser == null) return null;

    try {
      final data = await supabase
          .from('users')
          .select()
          .eq('auth_id', authUser.id)
          .maybeSingle();

      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// تحديث بيانات المستخدم
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
    String? fcmToken,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (fcmToken != null) updates['fcm_token'] = fcmToken;

    if (updates.isNotEmpty) {
      await supabase.from('users').update(updates).eq('id', userId);
    }
  }

  /// تحديث دور المستخدم
  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await supabase.from('users').update({'role': role}).eq('id', userId);
  }
}
