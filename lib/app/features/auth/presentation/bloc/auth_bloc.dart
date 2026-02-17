import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC المصادقة - يدير حالة تسجيل الدخول/الخروج
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLoginWithGoogleRequested>(_onLoginWithGoogleRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthVerifyResetOtpRequested>(_onVerifyResetOtpRequested);
    on<AuthSetNewPasswordRequested>(_onSetNewPasswordRequested);
    on<AuthResetPasswordFlowFinished>(_onResetPasswordFlowFinished);

    _authSubscription = _authRepository.authChangeStream.listen((data) {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        add(const AuthCheckRequested());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  /// فحص حالة Auth عند بدء التطبيق
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      if (_authRepository.isLoggedIn) {
        final profile = await _authRepository.getCurrentUserProfile().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Timeout fetching profile'),
        );

        if (profile == null) {
          emit(
            const AuthError(
              'لم يتم العثور على بيانات المستخدم في النظام. يرجى التواصل مع المسؤول.',
            ),
          );
          return;
        }

        emit(AuthAuthenticated(userProfile: profile));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  /// تسجيل دخول
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.signInWithEmail(
        email: event.email,
        password: event.password,
      );

      final profile = await _authRepository.getCurrentUserProfile().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout fetching profile'),
      );

      if (profile == null) {
        emit(
          const AuthError(
            'لم يتم العثور على بياناتك. في Supabase: شغّل ملف 003_link_user_profile_to_auth في SQL Editor ثم جرّب مرة أخرى.',
          ),
        );
        return;
      }

      emit(AuthAuthenticated(userProfile: profile));
    } on AuthException catch (e) {
      emit(AuthError(_mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  /// إنشاء حساب جديد
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.signUpWithEmail(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
      );

      final authUser = _authRepository.currentAuthUser;
      if (authUser != null) {
        await _authRepository.ensureProfileAfterSignUp(
          authId: authUser.id,
          name: event.name,
          email: event.email,
          role: event.role.isNotEmpty ? event.role : 'parent',
        );
      }

      var profile = await _authRepository.getCurrentUserProfile();
      if (profile == null) {
        emit(const AuthError('فشل جلب بيانات المستخدم بعد التسجيل.'));
        return;
      }

      emit(AuthAuthenticated(userProfile: profile));
    } on AuthException catch (e) {
      emit(AuthError(_mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  /// تسجيل دخول بـ Google (داخل التطبيق إن وُجد Web Client ID، وإلا عبر المتصفح)
  Future<void> _onLoginWithGoogleRequested(
    AuthLoginWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signInWithGoogle();
      // النجاح: onAuthStateChange يطلق signedIn ثم AuthCheckRequested
    } on AuthException catch (e) {
      emit(AuthError(_mapAuthError(e.message)));
    } on GoogleSignInCancelledException {
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('حدث خطأ أثناء تسجيل الدخول بـ Google: ${e.toString()}'));
    }
  }

  /// إرسال رمز استعادة كلمة المرور إلى البريد
  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.resetPasswordForEmail(event.email);
      emit(const AuthResetPasswordSent());
    } on AuthException catch (e) {
      emit(AuthError(_mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError('حدث خطأ أثناء إرسال الرمز: ${e.toString()}'));
    }
  }

  /// التحقق من رمز OTP
  Future<void> _onVerifyResetOtpRequested(
    AuthVerifyResetOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.verifyOtpForRecovery(
        email: event.email,
        token: event.token,
      );
      emit(const AuthResetOtpVerified());
    } on AuthException catch (e) {
      emit(AuthError(_mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError('رمز غير صحيح أو منتهي. جرّب إعادة الطلب.'));
    }
  }

  /// تعيين كلمة المرور الجديدة ثم تسجيل خروج
  Future<void> _onSetNewPasswordRequested(
    AuthSetNewPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.updatePassword(event.newPassword);
      await _authRepository.signOut();
      emit(const AuthPasswordResetSuccess());
    } on AuthException catch (e) {
      emit(AuthError(_mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError('حدث خطأ أثناء تغيير كلمة المرور.'));
    }
  }

  void _onResetPasswordFlowFinished(
    AuthResetPasswordFlowFinished event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthUnauthenticated());
  }

  /// تسجيل خروج
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('حدث خطأ أثناء تسجيل الخروج'));
    }
  }

  /// ترجمة رسائل خطأ Supabase للعربية
  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (message.contains('Email not confirmed')) {
      return 'يرجى تأكيد بريدك الإلكتروني أولاً';
    }
    if (message.contains('User already registered')) {
      return 'هذا البريد الإلكتروني مسجّل مسبقاً';
    }
    if (message.contains('Password should be at least')) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    if (message.contains('Unable to validate email')) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return 'حدث خطأ: $message';
  }
}
