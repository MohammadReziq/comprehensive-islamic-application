import 'package:equatable/equatable.dart';

/// أحداث المصادقة
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// فحص حالة Auth عند بدء التطبيق
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// تسجيل دخول بالإيميل
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// إنشاء حساب جديد
class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'parent',
  });

  @override
  List<Object?> get props => [name, email, password, role];
}

/// تسجيل خروج
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// تسجيل دخول بحساب Google
class AuthLoginWithGoogleRequested extends AuthEvent {
  const AuthLoginWithGoogleRequested();
}

/// طلب إرسال رمز استعادة كلمة المرور إلى البريد
class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// التحقق من رمز OTP المُرسل إلى البريد
class AuthVerifyResetOtpRequested extends AuthEvent {
  final String email;
  final String token;

  const AuthVerifyResetOtpRequested({
    required this.email,
    required this.token,
  });

  @override
  List<Object?> get props => [email, token];
}

/// تعيين كلمة المرور الجديدة بعد التحقق من OTP
class AuthSetNewPasswordRequested extends AuthEvent {
  final String newPassword;

  const AuthSetNewPasswordRequested({required this.newPassword});

  @override
  List<Object?> get props => [newPassword];
}

/// إنهاء تدفق نسيت كلمة المرور (بعد النجاح) للعودة لحالة غير مصادق
class AuthResetPasswordFlowFinished extends AuthEvent {
  const AuthResetPasswordFlowFinished();
}

/// تغيير كلمة المرور من الملف الشخصي (المستخدم مسجّل دخول — بدون تسجيل خروج)
class AuthChangePasswordFromProfileRequested extends AuthEvent {
  final String newPassword;

  const AuthChangePasswordFromProfileRequested({required this.newPassword});

  @override
  List<Object?> get props => [newPassword];
}

/// التحقق من رمز تفعيل البريد (بعد التسجيل)
class AuthVerifySignupCodeRequested extends AuthEvent {
  final String code;

  const AuthVerifySignupCodeRequested(this.code);

  @override
  List<Object?> get props => [code];
}

/// إعادة إرسال رمز تفعيل البريد
class AuthResendSignupCodeRequested extends AuthEvent {
  const AuthResendSignupCodeRequested();
}
