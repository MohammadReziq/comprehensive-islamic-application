import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC المصادقة - يدير حالة تسجيل الدخول/الخروج
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  /// فحص حالة Auth عند بدء التطبيق
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      if (_authRepository.isLoggedIn) {
        final profile = await _authRepository.getCurrentUserProfile();
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

      final profile = await _authRepository.getCurrentUserProfile();
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

      final profile = await _authRepository.getCurrentUserProfile();
      emit(AuthAuthenticated(userProfile: profile));
    } on AuthException catch (e) {
      emit(AuthError(_mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
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
