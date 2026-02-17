import 'package:equatable/equatable.dart';
import '../../../../models/user_model.dart';

/// حالات المصادقة
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// الحالة الابتدائية
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// جاري التحميل
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// مصادق - مسجّل دخول
class AuthAuthenticated extends AuthState {
  final UserModel? userProfile;

  const AuthAuthenticated({this.userProfile});

  @override
  List<Object?> get props => [userProfile];
}

/// غير مصادق - غير مسجّل دخول
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// حدث خطأ
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// تم إرسال رمز استعادة كلمة المرور إلى البريد
class AuthResetPasswordSent extends AuthState {
  const AuthResetPasswordSent();
}

/// تم التحقق من الرمز بنجاح — يمكن إدخال كلمة المرور الجديدة
class AuthResetOtpVerified extends AuthState {
  const AuthResetOtpVerified();
}

/// تم تغيير كلمة المرور بنجاح (يُعرض ثم نعود لـ Unauthenticated)
class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess();
}
