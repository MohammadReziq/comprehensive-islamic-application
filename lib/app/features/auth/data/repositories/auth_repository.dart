import 'package:google_sign_in/google_sign_in.dart';
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

  /// تيار أحداث تغيير الجلسة (للاستماع بعد عودة المستخدم من تسجيل الدخول بـ Google)
  Stream get authChangeStream => supabase.auth.onAuthStateChange;

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

  /// تسجيل دخول بـ Google.
  /// إذا [SupabaseConfig.googleWebClientId] معرّف: يظهر اختيار الحساب داخل التطبيق (بدون متصفح).
  /// وإلا: يفتح المتصفح ثم يعود للتطبيق عبر deep link.
  /// نفس الإيميل مسجّل مسبقاً يُربط تلقائياً عبر link_user_profile_to_auth.
  Future<void> signInWithGoogle() async {
    final webClientId = SupabaseConfig.googleWebClientId.trim();
    if (webClientId.isNotEmpty) {
      await _signInWithGoogleNative(webClientId: webClientId);
      return;
    }
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  /// تسجيل دخول بـ Google داخل التطبيق (قائمة الحسابات — بدون متصفح).
  Future<void> _signInWithGoogleNative({required String webClientId}) async {
    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      clientId: SupabaseConfig.googleIosClientId.trim().isEmpty
          ? null
          : SupabaseConfig.googleIosClientId.trim(),
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw GoogleSignInCancelledException();
    }
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    if (idToken == null) {
      throw Exception('لم يتم الحصول على رمز Google');
    }
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// إرسال إيميل استعادة كلمة المرور (يحتوي على رمز OTP إذا عدّلت القالب في Supabase ليعرض {{ .Token }}).
  Future<void> resetPasswordForEmail(String email) async {
    await supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: SupabaseConfig.passwordResetRedirectUrl,
    );
  }

  /// التحقق من رمز OTP المُرسل إلى البريد (بعد طلب استعادة كلمة المرور).
  /// عند النجاح تُنشأ جلسة مؤقتة يمكن بعدها استدعاء [updatePassword].
  Future<void> verifyOtpForRecovery({
    required String email,
    required String token,
  }) async {
    await supabase.auth.verifyOTP(
      type: OtpType.recovery,
      token: token.trim(),
      email: email.trim(),
    );
  }

  /// تعيين كلمة المرور الجديدة للمستخدم الحالي (يُستدعى بعد [verifyOtpForRecovery]).
  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ─── تسجيل خروج ───

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // ─── بيانات المستخدم من جدول users ───

  /// جلب بيانات المستخدم الحالي من جدول users
  /// إذا لم يُعثر: يربط سجل بنفس الإيميل (RPC) أو ينشئ سجل من بيانات الدخول
  Future<UserModel?> getCurrentUserProfile() async {
    final authUser = currentAuthUser;
    if (authUser == null) return null;

    // 1) جلب بالـ auth_id
    var data = await supabase
        .from('users')
        .select()
        .eq('auth_id', authUser.id)
        .maybeSingle();

    if (data != null) return UserModel.fromJson(data);

    // 2) ربط سجل موجود بنفس الإيميل (يحتاج تشغيل 003 في Supabase)
    try {
      await supabase.rpc('link_user_profile_to_auth');
      data = await supabase
          .from('users')
          .select()
          .eq('auth_id', authUser.id)
          .maybeSingle();
      if (data != null) return UserModel.fromJson(data);
    } catch (_) {
      // الدالة قد تكون غير موجودة أو فشل الربط
    }

    // 3) إنشاء سجل جديد من بيانات المصادقة (لو ما في سجل أصلاً)
    try {
      await ensureProfileFromAuthSession();
      data = await supabase
          .from('users')
          .select()
          .eq('auth_id', authUser.id)
          .maybeSingle();
      if (data != null) return UserModel.fromJson(data);
    } catch (_) {
      // قد يفشل لو الإيميل مكرر لسجل آخر
    }

    return null;
  }

  /// إنشاء/تحديث سجل في users من بيانات جلسة المصادقة الحالية
  Future<void> ensureProfileFromAuthSession() async {
    final u = currentAuthUser;
    if (u == null) return;
    final email = u.email?.trim();
    final name = (u.userMetadata?['name'] ?? u.userMetadata?['full_name'] ?? email ?? 'مستخدم جديد').toString().trim();
    if (name.isEmpty) return;
    await supabase.from('users').upsert(
      {
        'auth_id': u.id,
        'name': name.isEmpty ? 'مستخدم جديد' : name,
        'email': email?.isEmpty == true ? null : email,
        'role': 'parent',
      },
      onConflict: 'auth_id',
    );
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

  /// إنشاء أو تحديث سجل المستخدم في جدول users بعد التسجيل (من التطبيق مباشرة)
  /// لو الـ Trigger ما نفّذ أو تأخر، التطبيق يضمن وجود السجل بدون اعتماد على توقيت الـ DB
  Future<void> ensureProfileAfterSignUp({
    required String authId,
    required String name,
    required String email,
    String role = 'parent',
  }) async {
    await supabase.from('users').upsert(
      {
        'auth_id': authId,
        'name': name.trim().isEmpty ? 'مستخدم جديد' : name.trim(),
        'email': email.trim().isEmpty ? null : email.trim(),
        'role': role,
      },
      onConflict: 'auth_id',
    );
  }
}

/// يُرمى عند إلغاء المستخدم لاختيار حساب Google (لا نعرض خطأ للمستخدم).
class GoogleSignInCancelledException implements Exception {}
